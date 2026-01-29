import 'dart:convert';

import 'package:chat_app/constants/api_constants.dart';
import 'package:chat_app/constants/app_constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/io.dart';
import '../../chat_app.dart';
import '../../model/recent_conversation.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:async';

import '../components/user_status_event.dart';

class SubscribeWebSocketService extends GetxService {
//  final RecentConversationController controller;

  SubscribeWebSocketService();
final _statusController = StreamController<UserStatusEvent>.broadcast();
  Stream<UserStatusEvent> get statusStream => _statusController.stream;
  final Map<int, IOWebSocketChannel> _sockets = {};
  final Map<int, String> userStatus = {};

  // 🔁 retry state
  final Map<int, int> _retryCount = {};
  final Map<int, bool> _isReconnecting = {};
   final Map<int, Timer> _pingTimers = {};
   final Map<int, int> _conversationIds = {};
  final Map<int, Item> _items = {};
  final Map<int, Timer> _pongTimeoutTimers = {};
  final Map<int, bool> _waitingForPong = {};
  static const int _maxRetries = 5;

  void _sendPing(int userId) {
    final socket = _sockets[userId];
    if (socket == null) return;

    // If we already pinged and didn't get pong yet, let timeout handle it
    if (_waitingForPong[userId] == true) return;

    try {
      socket.sink.add(jsonEncode({"type": "ping"}));
      debugPrint("📤 [subscribe:$userId] ping sent");

      _waitingForPong[userId] = true;

      _pongTimeoutTimers[userId]?.cancel();
      _pongTimeoutTimers[userId] = Timer(const Duration(seconds: 30), () {
        if (_waitingForPong[userId] == true) {

          debugPrint("❌ [subscribe:$userId] pong not received in 30s → reconnect");
           try {
            _sockets.remove(userId);
            _stopHeartbeat(userId);
            _sockets[userId]?.sink.close();
          } catch (_) {}

          subscribe(_conversationIds[userId]??0, userId, _items[userId]??Item());
          // We don’t have convoId/item here, so caller handles on timeout via retry.
          // We'll just close socket to trigger onError/onDone flow OR call retry directly if you prefer.
         
        }
      });
    } catch (e) {
      debugPrint("❌ [subscribe:$userId] ping send failed: $e");
      try {
         
        _sockets[userId]?.sink.close();
      } catch (_) {}
    }
  }
  @override
  void onClose() {
    _statusController.close();
    super.onClose();
  }
  void _stopHeartbeat(int userId) {
    _pingTimers[userId]?.cancel();
    _pingTimers.remove(userId);

    _pongTimeoutTimers[userId]?.cancel();
    _pongTimeoutTimers.remove(userId);

    _waitingForPong.remove(userId);
  }
  void _startHeartbeat(int userId) {
    _stopHeartbeat(userId);

    _waitingForPong[userId] = false;

    // send ping every 30 seconds
    _pingTimers[userId] = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendPing(userId);
    });
  }

   void _onPong(int userId) {
    debugPrint("📥 [subscribe:$userId] pong received");
    _waitingForPong[userId] = false;
    _pongTimeoutTimers[userId]?.cancel();
    _pongTimeoutTimers.remove(userId);
  }

  void subscribe(int conversationId, int userId, Item item) {
    debugPrint("subscribe socket:${_sockets[userId]?.protocol}");

    if (_sockets.containsKey(userId)) {
      debugPrint("⚠️ Socket already exists for user $userId");
      return;
    }

    try {
      final subscribeChannel = IOWebSocketChannel.connect(
        Uri.parse(
          "${ApiConstants.subscriptionWebsocketUrl}"
          "?token=${chatConfigController.config.prefs.getString(chatConfigController.config.token) ?? ""}"
          "&type=subscribe"
          "&target=${userId.toString()}"
          "&convoId=${conversationId.toString()}",
        ),
      );

      _sockets[userId] = subscribeChannel;
      _conversationIds[userId]=conversationId;
      _items[userId]=item;
      _retryCount[userId] = 0;
      _isReconnecting[userId] = false;
       _startHeartbeat(userId);
      debugPrint("✅ subscribe WebSocket connected for user $userId");

      subscribeChannel.stream.listen(
        (event) {
          _retryCount[userId] = 0; // reset retry on valid data

          try {
            final data = jsonDecode(event);
            debugPrint("📡 subscribe data: $data");

            if (data["type"] == "status") {
              final isOnline = data["online"] == true;
              item.status.value = isOnline ? "online" : "offline";
              userStatus[userId] = item.status.value;
_statusController.add(
    UserStatusEvent(conversationId: conversationId, userId: userId, online: isOnline),);
              debugPrint(
                  "📡 [Convo $conversationId] User $userId is ${item.status.value}");
            }
             if (data["type"] == "pong") {
              debugPrint("subscribe pong received");

              _onPong(userId);
              return;
            }

            if (data["type"] == "typing") {
              item.isTyping.value = data["isTyping"] == "true";
            }

            if (data["type"] == "MESSAGE") {
             
              item.unreadCount.value = int.tryParse("${data['unreadCount']}") ?? 0;

              // final index = controller.results.indexWhere(
              //   (ele) => ele.id.toString() == data['conversationId'],
              // );

              // if (index != -1) {
              //   controller.results[index].unreadCount.value =
              //       data['unreadCount'];
              //   controller.results.refresh();
              // }
            }
          } catch (e) {
            debugPrint("❌ subscribe parse error: $e");
          }
        },
        onError: (e) {
           _stopHeartbeat(userId);
          debugPrint(
              "❌ subscribe WebSocket error for user $userId: $e");
          _retrySubscribe(conversationId, userId, item);
        },
        onDone: () {
          debugPrint(
              "⚠️ subscribe WebSocket closed for user $userId");
          // _retrySubscribe(conversationId, userId, item);
        },
        cancelOnError: false,
      );
    } catch (e) {
       _stopHeartbeat(userId);
      debugPrint("❌ Failed to subscribe to convo $conversationId: $e");
      _retrySubscribe(conversationId, userId, item);
    }
  }

  // 🔁 retry helper
  Future<void> _retrySubscribe(
    int conversationId,
    int userId,
    Item item,
  ) async {
    if (_isReconnecting[userId] == true) return;

    final retry = _retryCount[userId] ?? 0;
    if (retry >= _maxRetries) {
      debugPrint("❌ Max retry reached for user $userId");
      return;
    }

    _isReconnecting[userId] = true;
    _retryCount[userId] = retry + 1;

    final delay = Duration(seconds: 2 * _retryCount[userId]!);
    debugPrint(
        "🔄 retry subscribe user $userId attempt ${_retryCount[userId]} after ${delay.inSeconds}s");

    await Future.delayed(delay);

    try {
      _stopHeartbeat(userId);
      _sockets[userId]?.sink.close();
      _sockets.remove(userId);
    } catch (_) {}

    subscribe(conversationId, userId, item);
    _isReconnecting[userId] = false;
  }

void unsubscribeAll() {
    for (final id in _sockets.keys.toList()) {
      _stopHeartbeat(id);
      _sockets[id]?.sink.close(status.normalClosure);
      _sockets.remove(id);
      _retryCount.remove(id);
      _isReconnecting.remove(id);
    }
    _sockets.clear();
  }
}
