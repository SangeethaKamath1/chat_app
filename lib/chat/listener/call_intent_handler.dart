import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

import '../../chat_app.dart';
import '../chat_websocket/ping_web_socket.dart';
import '../controller/chat_controller.dart';

class CallIntentHandler {
  static const _channel = MethodChannel('call_intent');

  static Future<void> checkInitialCall() async {
    debugPrint("📡 checkInitialCall() called");

    final data = await _channel.invokeMethod<Map>('getCallIntent');

    debugPrint("📥 Call intent data: $data");

    if (data == null) {
      debugPrint("ℹ️ No pending call intent");
      return;
    }

    final action = data['action'];
    final callId = data['call_id'];
    final callerName=data['caller_name'];
    final callerId = data["caller_id"];
    final sdp=data["sdp"];
    final offerType=data["offer_type"];

    debugPrint("➡️ Action = $action | CallId = $callId | sdp=$sdp |offerType=$offerType");

    if (action == 'accept') {
      _onAccept(callId,callerName,callerId,sdp,offerType);
    } else if (action == 'reject') {
      _onReject(callId);
    }
  }

static Future<void> _onAccept(
  String callId,
  String callerName,
  String callerId,
  String sdp,
  String offerType,
) async {
  debugPrint("📞 ACCEPT handled | CallId = $callId");

  final chatController = Get.isRegistered<ChatController>()
      ? Get.find<ChatController>()
      : Get.put(ChatController());
      

  // ✅ 1️⃣ Set caller
  chatController.userId = callerId;

  // ✅ 2️⃣ WAIT for conversation + WebSocket
  await chatController.createConversation();

  if (chatController.chatWebSocket == null ||
      chatController.chatWebSocket!.channel == null) {
    debugPrint("❌ WebSocket not ready — aborting accept");
    return;
  }

  // ✅ 3️⃣ Init WebRTC AFTER signaling is ready
  final webRTCService = Get.isRegistered<WebRTCService>()
      ? Get.find<WebRTCService>()
      : Get.put(WebRTCService());

  // ✅ 4️⃣ Now it is SAFE to handle offer
  await webRTCService.handleOffer(
    RTCSessionDescription(sdp, offerType),
  );

  // UI + state
  webRTCService.speakerphoneService.stopRingtone();

  chatController.roomId = callId;
  chatController.name = callerName;
  chatController.callStatus.value = "Connecting...";

  chatController.chatWebSocket!.callAccepted(callId);

  Get.offNamed(ChatAppRoutes.callScreen,arguments:{"fromNotification":true});
}

  static void _onReject(String callId) {
    debugPrint("❌ REJECT handled in Flutter | CallId = $callId");
    // Optional backend notify
  }
}


// class CallIntentHandler {
//   static const _channel = MethodChannel('call_intent');

//   static Future<void> checkInitialCall() async {
//     debugPrint("📡 checkInitialCall() called");

//     final data = await _channel.invokeMethod<Map>('getCallIntent');

//     debugPrint("📥 Call intent data: $data");

//     if (data == null) return;

//     PendingCallIntent.action = data['action'];
//     PendingCallIntent.callId = data['call_id'];

//     debugPrint("🧠 Call intent stored");
//   }
// }
