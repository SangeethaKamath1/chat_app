import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:amu_alumni/routes/app_routes.dart';
import 'package:chat_app/constants/api_constants.dart';
import 'package:chat_app/constants/app_constant.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../audio_call/screens/incoming_call_screen.dart';
import '../../audio_call/service/speakerphone_service.dart';
import '../../chat_app.dart';
import 'group_chat_web_socket_service.dart';

class PingWebSocketService extends GetxService {
  late IOWebSocketChannel channel;
  int _retryCount = 0;
  static const int _maxRetries = 5;
  Timer? _pingTimer;
  Timer? _pongTimeoutTimer;
  bool _waitingForPong = false;
  bool _isReconnecting = false;
  // final webRTCService = Get.isRegistered<WebRTCService>()
  //     ? Get.find<WebRTCService>()
  //     : Get.put(WebRTCService());
  //  late WebSocketChannel statusCheckChannel;
  static int _extractConversationIdFromCallId(String callId) {
    final first = callId.split("_").first;
    return int.tryParse(first) ?? 0;
  }

  Future<void> _retryConnect() async {
    if (_isReconnecting) return;

    if (_retryCount >= _maxRetries) {
      debugPrint("❌ ping WebSocket max retry reached");
      return;
    }

    _isReconnecting = true;
    _retryCount++;

    final delay = Duration(seconds: 2 * _retryCount);
    debugPrint(
        "🔄 ping WebSocket retry $_retryCount after ${delay.inSeconds}s");

    await Future.delayed(delay);

    try {
      disconnect();
    } catch (_) {}

    connect();
    _isReconnecting = false;
  }

  void _startHeartbeat() {
    _stopHeartbeat();

    // First ping will fire after 30 seconds, then every 30 seconds
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendPingAndWatchPong();
    });
  }

  void _stopHeartbeat() {
    _pingTimer?.cancel();
    _pingTimer = null;

    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = null;

    _waitingForPong = false;
  }

  void _sendPingAndWatchPong() {
    try {
      if (_waitingForPong) {
        // We already sent a ping and haven't gotten pong yet.
        // Let the existing timeout handle reconnection.
        return;
      }

      final payload = {"type": "ping"};
      channel.sink.add(jsonEncode(payload));
      debugPrint("📤 Sent ping");

      _waitingForPong = true;

      _pongTimeoutTimer?.cancel();
      _pongTimeoutTimer = Timer(const Duration(seconds: 30), () {
        if (_waitingForPong) {
          debugPrint("❌ Pong not received within 30s. Reconnecting...");
          disconnect();
          connect();
        }
      });
    } catch (e) {
      debugPrint("❌ Failed to send ping: $e");
      disconnect();
      connect();
    }
  }

  void _onPongReceived() {
    debugPrint("📥 Received pong");
    _waitingForPong = false;
    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = null;
  }

  static Future<void> _ensureSignalingConnected(String callId) async {
    final signaling = Get.isRegistered<ChatWebSocketService>()
        ? Get.find<ChatWebSocketService>()
        : Get.put(ChatWebSocketService());

    signaling.setRoom(callId);

    final conversationId = _extractConversationIdFromCallId(callId);
    debugPrint("🧩 conversationId(from callId)=$conversationId");

    if (conversationId == 0) {
      debugPrint("⚠️ conversationId=0, signaling connect skipped");
      return;
    }

    signaling.connect(conversationId);
  }

  void connect() async {
    try {
      log("ping socket token:${chatConfigController.config.prefs.getString(chatConfigController.config.token) ?? ""}");
      debugPrint(
          "fff:${Uri.parse("${ApiConstants.pingWebsocketUrl}?token=${chatConfigController.config.prefs.getString(chatConfigController.config.token) ?? ""}&type=ping")}");
      channel = IOWebSocketChannel.connect(
        Uri.parse(
            "${ApiConstants.pingWebsocketUrl}?token=${chatConfigController.config.prefs.getString(chatConfigController.config.token) ?? ""}&type=ping"),
      );
      debugPrint(
          "✅ ping WebSocket connection established:${chatConfigController.config.prefs.getString(chatConfigController.config.userId)}");
      debugPrint("connection success:");
      _startHeartbeat();
      channel.stream.listen((event) async {
        final data = jsonDecode(event);
        log("ping is connected:${data}");
        if (data["type"] == "pong") {
          _onPongReceived();
          return;
        }
        if (data["connectionStatus"] == "CONNECTED") {
          debugPrint("ping is connected:${data}");
        } else if (data["type"] == "call") {
          _ensureSignalingConnected(data["callID"]);
          final roomId = data["callID"];
          final callerName = data["senderUsername"] ?? "Unknown";
          final offerData = data["offer"];
          final isVideo = data['isVideo'];
          debugPrint("📞 Incoming call from $callerName - Room: $roomId");

          Get.toNamed(ChatAppRoutes.incomingCallScreen, arguments: {
            "roomId": roomId,
            "callerName": callerName,
            "sdp": "",
            "offerType": "",
            "fromNotification": false,
            "isVideo": isVideo
          });
        } 
        // else if (data["type"] == "candidate") {
        //   final candidateData = data["candidate"];
        //   final callId = data["callID"]?.toString() ?? "";
        //   debugPrint("❄️ Received ICE candidate for call: $callId");

        //   await webRTCService.addIceCandidate(
        //     RTCIceCandidate(
        //       candidateData['candidate'],
        //       candidateData['sdpMid'] ?? '0',
        //       candidateData['sdpMLineIndex'] is int
        //           ? candidateData['sdpMLineIndex']
        //           : int.tryParse(
        //                   candidateData['sdpMLineIndex']?.toString() ?? '0') ??
        //               0,
        //     ),
        //   );
        // } 
        else if (data["type"] == "call_rejected") {
          final callId = data["callID"]?.toString() ?? "";
          final callerName = data["senderUsername"] ?? "Unknown";
          debugPrint("📞 Call rejected by $callerName - callId=$callId");
            final speakerSvc = Get.find<SpeakerphoneService>();
          speakerSvc.stopRingtone();
         
         final livekit  = Get.find<LiveKitOneToOneCallService>();
          await livekit.leaveCall();
          Platform.isIOS ? CallKitBridge.dismissIncoming(callId) : null;
          if (Get.currentRoute.contains('call')) {
            Get.back();
          }
        } else if (data["type"] == "call_cancelled") {
          final roomId = data["callID"];
          debugPrint("📞 Call ended - Room: $roomId");
            final speakerSvc = Get.find<SpeakerphoneService>();
          final livekit  = Get.find<LiveKitOneToOneCallService>();
       speakerSvc.stopRingtone();
          await livekit.leaveCall();

          // Navigate back only if we're on a call screen
          if (Get.currentRoute.contains('incomingCall')) {
            debugPrint("true");
            Get.offNamed(AppRoutes.home);
          }
        } 
        // else if (data["type"] == "answer") {
        //   final answerData = data["answer"];
        //   final callId = data["callID"]?.toString() ?? "";
        //   debugPrint("📥 Received ANSWER for call: $callId");

        //   webRTCService.isCallAccepted.value = true;
        //   webRTCService.speakerphoneService.stopRingtone();
        //   await webRTCService.handleAnswer(
        //     RTCSessionDescription(answerData['sdp'], answerData['type']),
        //   );
        // } 
        else if (data["type"] == "call_accepted") {
          final callId = data["callID"]?.toString() ?? "";
          final username = data["senderUsername"] ?? "Unknown";
          debugPrint("✅ Call accepted by $username - callId=$callId");

           final speakerSvc = Get.find<SpeakerphoneService>();
          speakerSvc.stopRingtone();
        } else if (data["type"] == "call_ended") {
          final callId = data["callID"]?.toString() ?? "";
          debugPrint("📞 Call ended - callId=$callId");
          Platform.isIOS ? CallKitBridge.dismissIncoming(callId) : null;
         final speakerSvc = Get.find<SpeakerphoneService>();
         final livekit  = Get.find<LiveKitOneToOneCallService>();
        speakerSvc.stopRingtone();
          await livekit.leaveCall();

          final nav = Get.key.currentState; // GetMaterialApp navigatorKey
          final canGoBack = nav?.canPop() ?? false;

          if (canGoBack) {
            Get.back();
          } else {
            Get.offAllNamed(AppRoutes.home);
          }
        } else if (data["type"] == "group_call_started") {
      
          final callId = data["callID"];
          debugPrint(
              "group call callid inside ping:${callId},${data["isVideo"]}");
          Get.toNamed(
            ChatAppRoutes.groupIncomingCallScreen,
            arguments: {
              "callID": callId,
              "callerId": data["callerId"], // if you send it
              "callerName": data["callerName"], // if you send it
              "isVideo": data["isVideo"] ?? false,
              "fromNotification": false,
            },
          );
        } else if (data["type"] == "group_call_cancelled") {
          final roomId = data["callID"];
          debugPrint("📞 Call ended - Room: $roomId");
          final SpeakerphoneService speakerSvc =
              Get.find<SpeakerphoneService>();
          await speakerSvc.stopRingtone();
          // final GroupChatWebSocketService chatSocket = Get.isRegistered<GroupChatWebSocketService>()?
          // Get.find<GroupChatWebSocketService>():Get.put(GroupChatWebSocketService());
          // chatSocket.hasOngoingCall=false.obs;
          // Navigate back only if we're on a call scree
          if (Get.currentRoute.contains('groupIncomingCallScreen')) {
            Get.offNamed(AppRoutes.home);
          }
        }
      }, onDone: () {
        debugPrint("✅ ping WebSocket connection closed onDone");
      }, onError: (e) {
        _stopHeartbeat();
        debugPrint("✅ ping WebSocket connection closed onError:$e");
        _retryConnect();
      });
    } catch (e) {
      _stopHeartbeat();
      _retryConnect();

      debugPrint("✅ ping WebSocket connection closed on catch");
    }
  }

  void sendFcmToken(String token) {
    debugPrint("send fcm token called");
    final payload = {"type": "fcmToken", "token": token};
    channel?.sink.add(jsonEncode(payload));
    debugPrint("fcm token payload :${payload}");
  }

  void sendVoipToken(String token) {
    debugPrint("send voip token called");
    final payload = {"type": "VoIP", "token": token};
    channel?.sink.add(jsonEncode(payload));
    debugPrint("voip token payload :${payload}");
  }

// void statusCheck(int conversationId,int userid,Item item) async{
//   try{
//     statusCheckChannel = WebSocketChannel.connect(Uri.parse("${ApiConstants.websocketUrl}?token=${chatConfigController.config.prefs.getString(constant.token)??""}&type=subscribe&target=${userid.toString()}&convoid=${conversationId.toString()}"));
//     print("✅ WebSocket connection established");
//     debugPrint("connection success:");
//     // item.status.value =
//     statusCheckChannel.stream.listen((data){
//       item.status.value=data;
//       debugPrint("connection status:${item.status.value}");
//     });
//   } catch (e) {
//     print("❌ Failed to connect: $e");
//    debugPrint("websocket connection failed");
//   }
//   }

  void sendMessage(String message) {
    channel.sink.add(message);
  }

  void disconnect() {
    debugPrint("✅ ping WebSocket connection disconnected on disconnect");
    _stopHeartbeat();
    channel.sink.close(status.normalClosure);
  }
}
