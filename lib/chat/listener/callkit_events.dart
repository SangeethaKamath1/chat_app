import 'package:amu_alumni/utils/resources/url_resourses.dart';
import 'package:chat_app/chat_app.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

import '../../audio_call/controller/call_session_controller.dart';
import '../../audio_call/service/speakerphone_service.dart';
import '../../audio_call/service/webrtc_service.dart';

import '../../routes/chat_app_routes.dart';
import '../chat_websocket/group_chat_web_socket_service.dart'; // adjust path if needed

class CallKitEvents {
  static const MethodChannel _ch = MethodChannel('call_intent');

  static int _extractConversationIdFromCallId(String callId) {
    // callId format: "{conversationId}_{uuid}"
    final first = callId.split("_").first;
    return int.tryParse(first) ?? 0;
  }

  static Future<String> fetchsdpFromApi(String callId) async {
    debugPrint(
        "📤 getsdp API url: ${UrlResources.acceptCallFromCallkit}$callId");
    try {
      final response =
          await Dio().get("${UrlResources.acceptCallFromCallkit}$callId");
      debugPrint(
          "📡 getsdp response: ${response.statusCode} | ${response.data}");
      return response.data["offerSdp"];
    } on DioException catch (e) {
      debugPrint(
          "❌ getsdp API failed | HTTP ${e.response?.statusCode} | ${e.message}");
      if (e.response?.data != null)
        debugPrint("📡 Error body: ${e.response?.data}");
      throw Exception(
          "fetchOfferSdp failed (HTTP ${e.response?.statusCode}): ${e.message}");
    }
  }

  static void init() {
    _ch.setMethodCallHandler((call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
      final callId = args["call_id"]?.toString() ?? "";
      final callerId = args["caller_id"]?.toString() ?? "";
      final callerName = args["caller_name"]?.toString() ?? "";
      final isVideo = args['isVideo']?.toString() ?? "false";
      const offerType = "offer";
      final isGroup = args["is_group"]?.toString() ?? "false";

      // ✅ WebRTC
      final webrtc = Get.isRegistered<WebRTCService>()
          ? Get.find<WebRTCService>()
          : Get.put(WebRTCService());

      // ✅ Signaling
      final signaling = Get.isRegistered<ChatWebSocketService>()
          ? Get.find<ChatWebSocketService>()
          : Get.put(ChatWebSocketService());
      final session = Get.isRegistered<CallSessionController>()
          ? Get.find<CallSessionController>()
          : Get.put(CallSessionController(), permanent: true);
// session.reset();
      session.isVideo.value = isVideo == "true" ? true : false;

      // ✅ conversationId from callId
      final conversationId = _extractConversationIdFromCallId(callId);
      debugPrint("🧩 conversationId(from callId) = $conversationId");

      // Ensure signaling knows current room
      signaling.setRoom(callId);

      // Connect signaling if possible
      if (conversationId != 0) {
        signaling.connect(conversationId);
      } else {
        debugPrint("⚠️ conversationId is 0, signaling connect skipped");
      }

      if (call.method == "onCallAccepted") {
        if (isGroup == "true") {
          final GroupChatWebSocketService groupSocket =
              Get.isRegistered<GroupChatWebSocketService>()
                  ? Get.find<GroupChatWebSocketService>()
                  : Get.put(GroupChatWebSocketService());
          groupSocket.ensureConnectedFromRoomId(callId);
          // final SpeakerphoneService speakerSvc =
          //     Get.find<SpeakerphoneService>();
          // await speakerSvc.stopRingtone();

          // Make sure roomId is set
          groupSocket.callID.value = callId;

          // Optional: ensure socket connected
          // groupSocket.ensureConnectedFromRoomId(callId);

          // Notify caller you accepted (implement in your group socket service)
        //  groupSocket.emitGroupCallAccepted(callId: callId);

          // Now go to actual group call screen (this will join LiveKit)
          Get.offNamed(
            ChatAppRoutes.groupCallScreen,
            arguments: {
              "isCaller": false,
              "fromNotification": true,
              "callID": callId, // ✅ pass explicitly
              "isVideo": isVideo == "true"?true:false,
            },
          );
        } else {
          debugPrint("📞 [CallKit] onCallAccepted received");
          debugPrint(
              "📞 callId=$callId callerId=$callerId callerName=$callerName");

          try {
            debugPrint("🔄 Fetching SDP from backend...");
            final sdp = await fetchsdpFromApi(callId);
            debugPrint("✅ SDP fetched (len=${sdp.length})");

            webrtc.speakerphoneService.stopRingtone();

            // ✅ Apply offer -> WebRTCService will create/send answer via signaling
            await webrtc.handleOffer(RTCSessionDescription(sdp, offerType));
            //  signaling.callAccepted(callId);

            // ✅ Navigate (no ChatController here)
            Get.offNamed(
              ChatAppRoutes.callScreen,
              arguments: {
                "fromNotification": true,
                "isCaller": false,
                "callId": callId,
                "callerId": callerId,
                "callerName": callerName,
                "sdp": sdp,
                "offerType": offerType,
                'isVideo': session.isVideo.value
              },
            );
          } catch (e, st) {
            debugPrint("❌ ERROR in onCallAccepted: $e");
            debugPrint("$st");
          }
        }
      }

      if (call.method == "onCallRejected") {
        debugPrint("📞 [CallKit] onCallRejected received: callId=$callId");

        try {
          if (isGroup == "true") {
            final SpeakerphoneService speakerSvc =
                Get.find<SpeakerphoneService>();
            await speakerSvc.stopRingtone();
            if (Get.currentRoute.contains('groupIncomingCallScreen')) {
              Get.back();
            }
          } else {
            webrtc.speakerphoneService.stopRingtone();
            await webrtc.endCall();

            // ✅ notify other side
            signaling.callRejected(callId);

            if (Get.currentRoute.contains('incomingCall')) {
              Get.back();
            }
          }
        } catch (e, st) {
          debugPrint("❌ ERROR in onCallRejected: $e");
          debugPrint("$st");
        }
      }

      if (call.method == "onCallEndedFromCallKit") {
        debugPrint("📞 [CallKit] onCallEndedFromCallKit: callId=$callId");

        try {
          webrtc.speakerphoneService.stopRingtone();
          await webrtc.endCall();

          // ✅ notify other s
          signaling.callEnded(callId);
        } catch (e, st) {
          debugPrint("❌ ERROR in onCallEndedFromCallKit: $e");
          debugPrint("$st");
        }
      }
    });
  }
}
