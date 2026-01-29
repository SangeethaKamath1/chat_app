import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:amu_alumni/routes/app_routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../chat_app.dart';
import '../../constants/api_constants.dart';
import '../../model/conversation_list.dart';
import '../components/user_status_event.dart';
import '../controller/chat_controller.dart';
import '../helpers/encryption_helper.dart';

class ChatWebSocketService extends GetxService {
  IOWebSocketChannel? channel;

  int _connectedConversationId = 0;
  Timer? _pingTimer;
  Timer? _pongTimer;
  int _lastConversationId = 0;
  bool _waitingForPong = false;
StreamSubscription<UserStatusEvent>? _statusSub;
  void _startHeartbeat() {
    _stopHeartBeat();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (t) {
      _sendPingAndWatchPong();
    });
  }

  void attachPresenceListener({
  required int conversationId,
  required int peerUserId,
}) {
  _statusSub?.cancel();

  final sub = Get.find<SubscribeWebSocketService>();
  _statusSub = sub.statusStream.listen((evt) {
    if (evt.conversationId != conversationId) return;
    if (evt.userId != peerUserId) return;

    if (evt.online) {
      debugPrint("is online from chat web socket:${evt.online}");
      final chatController = Get.find<ChatController>();

      // ✅ Mark pending outgoing messages as delivered (local UI)
      chatController.updateMessageStatusToDelivered();

      // ✅ If your backend requires an ACK, send it here (depends on your protocol)
      // send({"type": "delivered_ack", "conversationId": conversationId});
    }
  });
}

  void _sendPingAndWatchPong() {
    try {
      if (_waitingForPong) {
        return;
      }
      final payload = {"type": "ping"};
      channel?.sink.add(jsonEncode(payload));
      _waitingForPong = true;
      _pongTimer?.cancel();
      _pongTimer = Timer(const Duration(seconds: 30), () {
        if (_waitingForPong) {
          debugPrint("conversation id chat socket:${_connectedConversationId}");
          disconnect();
          connect(_lastConversationId);
        }
      });
    } catch (e) {
    debugPrint("conversation id chat socket:${_connectedConversationId}");
    disconnect();
          connect(_lastConversationId);
    }
  }
  void _onPongReceived() {
    debugPrint("📥 Received pong");
    _waitingForPong = false;
    _pongTimer?.cancel();
    _pongTimer = null;
  }

  void _stopHeartBeat() {
    _waitingForPong = false;
    _pingTimer?.cancel();
    _pongTimer?.cancel();
    _pingTimer = null;
    _pongTimer = null;
  }

  String roomId = "";
  int _retryCount = 0;
  bool _isReconnecting = false;
  static const int _maxRetries = 5;

  /// avoid multiple connects at same time
  bool _isConnecting = false;

  WebRTCService get webRTCService => Get.find<WebRTCService>();

  void setRoom(String callId) {
    roomId = callId;
    debugPrint("🧩 CallSignalingService roomId set: $roomId");
  }

  static int _extractConversationIdFromCallId(String callId) {
    final first = callId.split("_").first;
    return int.tryParse(first) ?? 0;
  }

  void ensureConnectedFromRoomId(String callId) async {
    final cid = _extractConversationIdFromCallId(callId);
    if (cid == 0) {
      debugPrint(
          "❌ ensureConnectedFromRoomId: invalid conversationId for callId=$callId");
      return;
    }
    connect(cid);
  }

  void connect(int conversationId) {
    debugPrint("conversation id inside connect:${conversationId}");
    if (_isConnecting) {
      debugPrint(
          "⏸️ CallSignalingService connect skipped (already connecting)");
      return;
    }

    // If we already have a channel and it's for same conversation, keep it.
    // But if you ever get a stale socket, you MUST reconnect.
    // We handle that by reconnecting on onDone/onError (channel=null there).
    if (channel != null && _connectedConversationId == conversationId) {
      debugPrint(
          "⏸️ CallSignalingService already connected (conv=$conversationId)");
      return;
    }

    // If switching conversationId, close old channel first.
    if (channel != null && _connectedConversationId != conversationId) {
      debugPrint(
          "🔁 Switching signaling conversation: $_connectedConversationId -> $conversationId");
      disconnect();
    }
    _isConnecting = true;
    try {
      _connectedConversationId = conversationId;
      _lastConversationId = conversationId;
      debugPrint("connected conversation id:${_connectedConversationId}");
      channel = IOWebSocketChannel.connect(
        Uri.parse(
          "${ApiConstants.chatWebSocketService}"
          "?token=${chatConfigController.config.prefs.getString(chatConfigController.config.token)}"
          "&conversationId=$conversationId",
        ),
      );

      debugPrint("✅ [${hashCode}] CHAT WebSocket connected");
      _startHeartbeat();
      _retryCount = 0;
      channel?.stream.listen((event) async {
        final data = jsonDecode(event);
        log("📡 CHAT WS event: $data");
        if(data["type"]=="PONG"){
            _onPongReceived();
        }

       else if (data["type"] == "msg") {
          final chatController = Get.find<ChatController>();
          final decryptedMsg = EncryptionHelper.decryptText(data['msg']);

          Conversations? replyTo;
          if (data["replyTo"] != null) {
            replyTo = Conversations(
              id: data["replyTo"] ?? "",
              senderUUID: data["receiver"] ?? "",
              senderUsername: data["receiverUsername"] ?? "",
              message: data["reply"] ?? "",
              medias: data["urls"],
            );
          }

          chatController?.conversations.insert(
            0,
            Conversations(
              id: data["messageId"] ?? "",
              senderUUID: data["sender"] ?? "",
              senderUsername: data['senderUsername'] ?? "",
              message: decryptedMsg,
              replayTo: replyTo,
            ),
          );

          chatController?.conversations.refresh();
        } else if (data["type"] == "media") {
          final chatController = Get.find<ChatController>();
          final List<dynamic> mediaUrls = [];

          if (data["mediaUploadResponse"] != null) {
            for (final item in data["mediaUploadResponse"]) {
              if (item["success"] == true && item["url"] != null) {
                mediaUrls.add(item["url"]);
              }
            }
          }

          Conversations? replyTo;
          if (data["replyTo"] != null) {
            replyTo = Conversations(
              id: data["replyTo"] ?? "",
              senderUUID: data["receiver"] ?? "",
              senderUsername: data["receiverUsername"] ?? "",
              message: data["reply"] ?? "",
              medias: data["urls"],
            );
          }

          chatController?.conversations.insert(
            0,
            Conversations(
              id: data["mediaUploadResponse"][0]["messageId"] ?? "",
              senderUUID: data["sender"] ?? "",
              senderUsername: data['senderUsername'] ?? "",
              medias: mediaUrls,
              replayTo: replyTo,
            ),
          );

          chatController.conversations.refresh();
        } else if (data["type"] == "typing") {
          final chatController = Get.find<ChatController>();
          chatController.isTyping.value = data["isTyping"] == "true";
        } else if (data["type"] == "reload") {
          final chatController = Get.find<ChatController>();
          if (data["status"] == "DELIVERED") {
            chatController.updateMessageStatusToDelivered();
          } else {
            chatController.updateMessageStatusToSeen();
          }
          chatController.conversations.refresh();
        } else if (data['type'] == "delete") {
          final chatController = Get.find<ChatController>();
          chatController.conversations.removeWhere(
            (ele) => ele.id.toString() == data['messageId'].toString(),
          );
          chatController.conversations.refresh();
        } else if (data["status"] == "DELIVERED") {
          final chatController = Get.find<ChatController>();
          Future.delayed(const Duration(milliseconds: 300), () {
            chatController.updateMessageStatusById(
              data["messageId"],
              data["status"],
            );
          });
        } else if (data["status"] == "SEEN") {
          final chatController = Get.find<ChatController>();
          chatController.updateMessageStatusToSeen();
        } else if (data["type"] == "REACTION" || data["type"] == "reaction") {
          final chatController = Get.find<ChatController>();
          chatController.updateReaction(
            data["messageId"],
            data["reaction"],
            data["oldReaction"],
          );
        } else if (data["type"] == "call") {
          //ensureConnectedFromRoomId(data["callID"]);
          final roomId = data["callID"];
          final callerName = data["senderUsername"] ?? "Unknown";
          final offerData = data["offer"];
          final isVideo = data['isVideo'];
          debugPrint("📞 Incoming call from $callerName - Room: $roomId");

          Get.toNamed(ChatAppRoutes.incomingCallScreen, arguments: {
            "roomId": roomId,
            "callerName": callerName,
            "sdp": offerData['sdp'],
            "offerType": offerData['type'],
            "fromNotification": false,
            "isVideo": isVideo
          });
        } else if (data["type"] == "answer") {
          final answerData = data["answer"];
          final callId = data["callID"]?.toString() ?? "";
          debugPrint("📥 Received ANSWER for call: $callId");
          webRTCService.isCallAccepted.value = true;
          webRTCService.speakerphoneService.stopRingtone();
          await webRTCService.handleAnswer(
            RTCSessionDescription(answerData['sdp'], answerData['type']),
          );
        } else if (data["type"] == "candidate") {
          final candidateData = data["candidate"];
          final callId = data["callID"]?.toString() ?? "";
          debugPrint("❄️ Received ICE candidate for call: $callId");

          await webRTCService.addIceCandidate(
            RTCIceCandidate(
              candidateData['candidate'],
              candidateData['sdpMid'] ?? '0',
              candidateData['sdpMLineIndex'] is int
                  ? candidateData['sdpMLineIndex']
                  : int.tryParse(
                          candidateData['sdpMLineIndex']?.toString() ?? '0') ??
                      0,
            ),
          );
        }
         else if (data["type"] == "call_ended") {
          final roomId = data["callID"]?.toString() ?? "";
          debugPrint("📞 Call ended - callId=$roomId");
          Platform.isIOS ? CallKitBridge.dismissIncoming(roomId) : null;
          webRTCService.speakerphoneService.stopRingtone();
          await webRTCService.endCall();

          final nav = Get.key.currentState; // GetMaterialApp navigatorKey
          final canGoBack = nav?.canPop() ?? false;
          debugPrint("can go back:${canGoBack}");

          if (canGoBack) {
            Get.back();
          } else {
            Get.offAllNamed(AppRoutes.home);
          }
        } else if (data["type"] == "call_cancelled") {
          final roomId = data["callID"]?.toString() ?? "";
          debugPrint("📞 Call cancelled - callId=$roomId");
          await CallKitBridge.dismissIncoming(roomId);
          webRTCService.speakerphoneService.stopRingtone();
          await webRTCService.endCall();

          if (Get.currentRoute.contains('incomingCall')) {
            Get.back();
          } else {
            Get.offAllNamed(AppRoutes.home);
          }
        } else if (data["type"] == "call_accepted") {
          final callId = data["callID"]?.toString() ?? "";
          final username = data["senderUsername"] ?? "Unknown";
          debugPrint("✅ Call accepted by $username - callId=$callId");

          webRTCService.speakerphoneService.stopRingtone();
        } else if (data["type"] == "call_rejected") {
          final callId = data["callID"]?.toString() ?? "";
          final callerName = data["senderUsername"] ?? "Unknown";
          debugPrint("📞 Call rejected by $callerName - callId=$callId");
          Platform.isIOS ? CallKitBridge.dismissIncoming(callId) : null;
          webRTCService.speakerphoneService.stopRingtone();
          await webRTCService.endCall();

          if (Get.currentRoute.contains('call')) {
            Get.back();
          }
        }

        // ✅ CALL EVENTS REMOVED FROM HERE
        // answer/candidate/call_ended/call_cancelled/call_rejected/call_accepted handled in CallSignalingService
      }, onDone: () {
        debugPrint("🔴 CHAT WS done");
        _isConnecting = false;
        channel = null;
      }, onError: (e) {
        debugPrint("🔴 CHAT WS error: $e");
        _isConnecting = false;
        channel = null;
        _stopHeartBeat();
        // keep your reconnect logic if you already had it
        _handleRetry();
      });
    } catch (e) {
      _stopHeartBeat();
      debugPrint("❌ CHAT WS connect exception: $e");
      _handleRetry();
    }
  }

  void sendOffer(RTCSessionDescription offer, bool isVideo) {
    if (channel == null) {
      debugPrint("❌ sendOffer: channel is null");
      return;
    }
    final payload = {
      "type": "call",
      "offer": {"sdp": offer.sdp, "type": offer.type},
      "callID": roomId,
      "isVideo": isVideo
    };
    send(payload);
    log("📤 OFFER SENT: $payload");
  }

  void sendAnswer(RTCSessionDescription answer) {
    if (channel == null) {
      debugPrint("❌ sendAnswer: channel is null");
      return;
    }
    final payload = {
      "type": "answer",
      "answer": {"sdp": answer.sdp, "type": answer.type},
      "callID": roomId,
    };
    send(payload);
    log("📤 ANSWER SENT: $payload");
  }

  void sendIceCandidate(RTCIceCandidate candidate) {
    if (channel == null) {
      // candidates can come early; don't crash
      return;
    }
    final payload = {
      "type": "candidate",
      "candidate": {
        "candidate": candidate.candidate,
        "sdpMid": candidate.sdpMid ?? "0",
        "sdpMLineIndex": candidate.sdpMLineIndex ?? 0,
      },
      "callID": roomId,
    };
    send(payload);
  }

  // ============================
  // CALL STATE NOTIFY METHODS
  // ============================

  void callAccepted(String callId) {
    setRoom(callId);
    send({"type": "call_accepted", "callID": callId});
  }

  void callRejected(String callId) {
    setRoom(callId);
    send({"type": "call_rejected", "callID": callId});
  }

  void callEnded(String callId) {
    setRoom(callId);
    send({"type": "call_ended", "callID": callId});
  }

  void callCancelled(String callId, {int? conversationId}) {
    setRoom(callId);

    // ✅ you said conversationId should come from callId/roomId
    final derivedCid = _extractConversationIdFromCallId(callId);

    send({
      "type": "call_cancelled",
      "callID": callId,
      "conversationId": conversationId ??
          (derivedCid != 0
              ? derivedCid
              : chatConfigController.config.prefs
                  .getInt(chatConfigController.config.conversationId)),
    });
  }

  void send(Map<String, dynamic> payload) {
    try {
      channel?.sink.add(jsonEncode(payload));
      log("send signaling:${jsonEncode(payload)}");
    } catch (e) {
      debugPrint("❌ CallSignaling send failed: $e");
    }
  }

  void disconnect() {
    _statusSub?.cancel();
  _statusSub = null;
  _stopHeartBeat();
    try {
      channel?.sink.close(status.normalClosure);
    } catch (_) {}
    channel = null;
    _isConnecting = false;
    _connectedConversationId = 0;
  }

  @override
  void onClose() {
    // disconnect();
    super.onClose();
  }

  void onChanged(bool isTyping) {
    final payload = {"type": "typing", "isTyping": isTyping.toString()};
    channel?.sink.add(jsonEncode(payload));
    if (kDebugMode) debugPrint("📤 Sent typing: $payload");
  }

  void sendMessage(String messageId, String message, int conversationId) {
    final payload = {"type": "msg", "messageId": messageId, "msg": message};
    channel?.sink.add(jsonEncode(payload));
    if (kDebugMode) debugPrint("📤 message: $payload");
  }

  void deleteMessage(String messageId, int index) {
    final chatController = Get.find<ChatController>();
    final payload = {"type": "delete", "messageId": messageId};
    channel?.sink.add(jsonEncode(payload));

    if (index >= 0 && index < chatController.conversations.length) {
      chatController.conversations.removeAt(index);
      chatController.conversations.refresh();
    }

    chatController.messageId.value = "";
    chatController.chatIndex.value = -1;
    chatController.showEmojiPicker.value = false;
  }

  Future<void> _handleRetry() async {
    if (_isReconnecting) return;
    if (_retryCount >= _maxRetries) {
      debugPrint("❌ CHAT WS max retry reached");
      return;
    }

    _isReconnecting = true;
    _retryCount++;

    final delay = Duration(seconds: 2 * _retryCount);
    debugPrint("🔄 CHAT WS retry $_retryCount after ${delay.inSeconds}s");

    await Future.delayed(delay);

    disconnect();
    connect(_connectedConversationId);

    _isReconnecting = false;
  }

  void sendMessageWithReply({
    required String replyTo,
    required String receiver,
    required receiverUsername,
    required String reply,
    required String messageId,
    required String message,
    dynamic urls,
  }) {
    final payload = (urls != null)
        ? {
            "type": "msg",
            "replyTo": replyTo,
            "receiver": receiver,
            "receiverUsername": receiverUsername,
            "messageId": messageId,
            "msg": message,
            "urls": urls
          }
        : {
            "type": "msg",
            "replyTo": replyTo,
            "receiver": receiver,
            "receiverUsername": receiverUsername,
            "reply": reply,
            "messageId": messageId,
            "msg": message,
          };

    channel?.sink.add(jsonEncode(payload));
    if (kDebugMode) debugPrint("📤 reply msg: $payload");
  }

  void sendReaction(String messageId, String reaction, int conversationId) {
    final chatController = Get.find<ChatController>();
    final payload = {
      "type": "reaction",
      "messageId": messageId,
      "msg": reaction
    };
    channel?.sink.add(jsonEncode(payload));

    chatController.messageId.value = "";
    chatController.messageController.text = "";
    chatController.chatIndex.value = -1;
    chatController.showEmojiPicker.value = false;
  }
}
