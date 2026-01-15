import 'package:amu_alumni/amu_alumni.dart';
import 'package:chat_app/audio_call/controller/call_session_controller.dart';
import 'package:chat_app/chat_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

import '../../audio_call/service/webrtc_service.dart';

import '../../routes/chat_app_routes.dart';


class CallIntentHandler {
  static const _channel = MethodChannel('call_intent');

  /// callId format: "{conversationId}_{uuid}"
  static int _extractConversationIdFromCallId(String callId) {
    final first = callId.split("_").first;
    return int.tryParse(first) ?? 0;
  }

  static Future<void> checkInitialCall() async {
    debugPrint("📡 checkInitialCall() called");

    final data = await _channel.invokeMethod<Map>('getCallIntent');
    debugPrint("📥 Call intent data: $data");

    if (data == null) {
      debugPrint("ℹ️ No pending call intent");
      return;
    }

    final action = data['action']?.toString() ?? "";
    final callId = data['call_id']?.toString() ?? "";
    final callerName = data['caller_name']?.toString() ?? "";
    final callerId = data['caller_id']?.toString() ?? "";
    final sdp = data['sdp']?.toString() ?? "";
    final offerType = data['offer_type']?.toString() ?? "offer";
    final isVideo = data['isVideo']?.toString()??"false";

    debugPrint("➡️ action=$action callId=$callId caller=$callerName($callerId) offerType=$offerType isVideo=$isVideo");

    if (callId.isEmpty) {
      debugPrint("❌ callId empty, abort");
      return;
    }

    if (action == 'accept') {
      await _onAccept(callId, callerName, callerId, sdp, offerType, isVideo);
    } else if (action == 'reject') {
      await _onReject(callId);
    } else if (action == 'open') {
      await _onOpen(callId, callerName, callerId, sdp, offerType,isVideo);
    } else if (action == 'cancel') {
      await _onCallerCancelled(callId, callerId, callerName, sdp, offerType);
    }
  }

  static Future<void> _ensureSignalingConnected(String callId) async {
    final signaling = Get.isRegistered<ChatWebSocketService>()
        ? Get.find<ChatWebSocketService>()
        : Get.put(ChatWebSocketService(), permanent: true);

    signaling.setRoom(callId);

    final conversationId = _extractConversationIdFromCallId(callId);
    debugPrint("🧩 conversationId(from callId)=$conversationId");

    if (conversationId == 0) {
      debugPrint("⚠️ conversationId=0, signaling connect skipped");
      return;
    }

    signaling.connect(conversationId);
  }

  static Future<void> _onCallerCancelled(
    String callId,
    String callerId,
    String callerName,
    String sdp,
    String offerType,
  ) async {
    debugPrint("☎️ Caller cancelled | $callId | $callerName");

    // Close Incoming Call screen if open
    if (Get.currentRoute.contains('incomingCall')) {
      Get.offNamed(AppRoutes.home);
    }

    // Stop webrtc if any
    final webrtc = Get.isRegistered<WebRTCService>()
        ? Get.find<WebRTCService>()
        : Get.put(WebRTCService(), permanent: true);

    webrtc.speakerphoneService.stopRingtone();
    await webrtc.endCall();
  }

  static Future<void> _onAccept(
    String callId,
    String callerName,
    String callerId,
    String sdp,
    String offerType,
    String isVideo
  ) async {
    debugPrint("📞 ACCEPT handled | callId=$callId isVideo =$isVideo");

    // 1) Ensure signaling socket is connected first
    await _ensureSignalingConnected(callId);

    final signaling = Get.find<ChatWebSocketService>();

    // 2) Ensure WebRTC exists
    final webrtc = Get.isRegistered<WebRTCService>()
        ? Get.find<WebRTCService>()
        : Get.put(WebRTCService(), permanent: true);

    webrtc.speakerphoneService.stopRingtone();
   final session=  Get.isRegistered<CallSessionController>()
        ? Get.find<CallSessionController>()
        : Get.put(CallSessionController(), permanent: true);
// session.reset();
session.isVideo.value =isVideo ==  "true"?true:false;
    // 3) Apply offer -> WebRTCService will create local answer
    // and CallSignalingService will send it (via your wiring)
    if (sdp.isNotEmpty) {
      await webrtc.handleOffer(RTCSessionDescription(sdp, offerType));
    } else {
      debugPrint("⚠️ SDP empty in intent accept — cannot handleOffer");
    }

    // 4) Notify caller that we accepted
    //signaling.callAccepted(callId);

    // 5) Navigate to call screen (keep your old behavior)
    Get.offNamed(
      ChatAppRoutes.callScreen,
      arguments: {
        "fromNotification": true,
        "isCaller": false,
        "callId": callId,
        "callerId": callerId,
        "callerName": callerName,
        'isVideo':session.isVideo.value
      },
    );
  }

  static Future<void> _onReject(String callId) async {
    debugPrint("📞 REJECT handled | callId=$callId");

    await _ensureSignalingConnected(callId);
    final signaling = Get.find<ChatWebSocketService>();

    final webrtc = Get.isRegistered<WebRTCService>()
        ? Get.find<WebRTCService>()
        : Get.put(WebRTCService(), permanent: true);

    webrtc.speakerphoneService.stopRingtone();
    await webrtc.endCall();
 final session=  Get.isRegistered<CallSessionController>()
        ? Get.find<CallSessionController>()
        : Get.put(CallSessionController(), permanent: true);
// session.reset();
    // notify caller
    signaling.callRejected(callId);

    if (Get.currentRoute.contains('incomingCall')) {
      Get.back();
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  static Future<void> _onOpen(
    String callId,
    String callerName,
    String callerId,
    String sdp,
    String offerType,
    String isVideo
  ) async {
    debugPrint("📞 OPEN incoming call screen | callId=$callId isVideo=$isVideo");
 final session=  Get.isRegistered<CallSessionController>()
        ? Get.find<CallSessionController>()
        : Get.put(CallSessionController(), permanent: true);
// session.reset();
session.isVideo.value = isVideo == "true"?true:false;
    // Ensure signaling is ready even when user just opens screen
    await _ensureSignalingConnected(callId);

    Get.offNamed(
      ChatAppRoutes.incomingCallScreen,
      arguments: {
        "roomId": callId,
        "callerName": callerName,
        "fromNotification": true,
        "callerId": callerId,
        "sdp": sdp,
        "offerType": offerType,
        "isVideo":session.isVideo.value
      },
    );
  }
}
