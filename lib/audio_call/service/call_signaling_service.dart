// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
// import 'package:amu_alumni/amu_alumni.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:get/get.dart';
// import 'package:web_socket_channel/io.dart';
// import 'package:web_socket_channel/status.dart' as status;

// import '../../constants/api_constants.dart';
// import '../../chat_app.dart';
// import '../../audio_call/service/webrtc_service.dart';

// class CallSignalingService extends GetxService {
//   IOWebSocketChannel? channel;

//   WebRTCService get webRTCService => Get.find<WebRTCService>();

//   /// current call id / room id
//   String roomId = "";

//   /// track which conversationId this signaling socket is connected to
//   int _connectedConversationId = 0;

//   /// avoid multiple connects at same time
//   bool _isConnecting = false;

//   /// ✅ set roomId from anywhere (CallKitEvents / IncomingCallScreen / Caller)
//   void setRoom(String callId) {
//     roomId = callId;
//     debugPrint("🧩 CallSignalingService roomId set: $roomId");
//   }

//   /// ⚠️ "channel != null" is not a true connected check, but we keep it as a quick guard.
//   bool get isConnected => channel != null;

//   // ============================================================
//   // ConversationId from roomId: "{conversationId}_{uuid}"
//   // ============================================================
//   int _extractConversationIdFromRoomId(String callId) {
//     if (callId.isEmpty) return 0;
//     final first = callId.split("_").first;
//     return int.tryParse(first) ?? 0;
//   }

//   /// ✅ Call this from IncomingCallScreen / CallKitEvents / VoiceCallScreen
//   /// It will extract conversationId from roomId and connect/reconnect.
//   void ensureConnectedFromRoomId(String callId) {
//     final cid = _extractConversationIdFromRoomId(callId);
//     if (cid == 0) {
//       debugPrint("❌ ensureConnectedFromRoomId: invalid conversationId for callId=$callId");
//       return;
//     }
//     connect(conversationId: cid);
//   }

//   // ============================================================
//   // CONNECT / RECONNECT
//   // ============================================================
//   void connect({required int conversationId}) {
//     // Prevent re-entrant connects
//     if (_isConnecting) {
//       debugPrint("⏸️ CallSignalingService connect skipped (already connecting)");
//       return;
//     }

//     // If we already have a channel and it's for same conversation, keep it.
//     // But if you ever get a stale socket, you MUST reconnect.
//     // We handle that by reconnecting on onDone/onError (channel=null there).
//     if (channel != null && _connectedConversationId == conversationId) {
//       debugPrint("⏸️ CallSignalingService already connected (conv=$conversationId)");
//       return;
//     }

//     // If switching conversationId, close old channel first.
//     if (channel != null && _connectedConversationId != conversationId) {
//       debugPrint("🔁 Switching signaling conversation: $_connectedConversationId -> $conversationId");
//       disconnect();
//     }

//     _isConnecting = true;
//     _connectedConversationId = conversationId;

//     channel = IOWebSocketChannel.connect(
//       Uri.parse(
//         "${ApiConstants.chatWebSocketService}"
//         "?token=${chatConfigController.config.prefs.getString(chatConfigController.config.token)}"
//         "&conversationId=$conversationId",
//       ),
//     );

//     debugPrint("✅ [${hashCode}] CallSignaling WebSocket connected (conv=$conversationId)");

//     channel?.stream.listen(
//       (event) async {
//         final data = jsonDecode(event);
//         log("📡 CallSignaling event: $data");

//         // ✅ IMPORTANT:
//         // CallKit flow fetches SDP from API and calls webrtc.handleOffer() already.
//         // So we DO NOT handle "call" offer here to avoid double-offer / state issues.

//         if (data["type"] == "answer") {
//           final answerData = data["answer"];
//           final callId = data["callID"]?.toString() ?? "";
//           debugPrint("📥 Received ANSWER for call: $callId");
//         webRTCService.isCallAccepted.value=true;
//         webRTCService.speakerphoneService.stopRingtone();
//           await webRTCService.handleAnswer(
//             RTCSessionDescription(answerData['sdp'], answerData['type']),
//           );
//         } else if (data["type"] == "candidate") {
//           final candidateData = data["candidate"];
//           final callId = data["callID"]?.toString() ?? "";
//           debugPrint("❄️ Received ICE candidate for call: $callId");

//           await webRTCService.addIceCandidate(
//             RTCIceCandidate(
//               candidateData['candidate'],
//               candidateData['sdpMid'] ?? '0',
//               candidateData['sdpMLineIndex'] is int
//                   ? candidateData['sdpMLineIndex']
//                   : int.tryParse(candidateData['sdpMLineIndex']?.toString() ?? '0') ?? 0,
//             ),
//           );
//         } else if (data["type"] == "call_ended") {
//           final callId = data["callID"]?.toString() ?? "";
//           debugPrint("📞 Call ended - callId=$callId");
//   Platform.isIOS? CallKitBridge.dismissIncoming(roomId):null;
//           webRTCService.speakerphoneService.stopRingtone();
//           await webRTCService.endCall();

//          final nav = Get.key.currentState; // GetMaterialApp navigatorKey
//   final canGoBack = nav?.canPop() ?? false;

//   if (canGoBack) {
//     Get.back();
//   } else {
//     Get.offAllNamed(AppRoutes.home);
//   }
//         } else if (data["type"] == "call_cancelled") {
//           final callId = data["callID"]?.toString() ?? "";
//           debugPrint("📞 Call cancelled - callId=$callId");
//           await CallKitBridge.dismissIncoming(roomId);
//           webRTCService.speakerphoneService.stopRingtone();
//           await webRTCService.endCall();

//           if (Get.currentRoute.contains('incomingCall')) {
//             Get.back();
//           } else {
//             Get.offAllNamed(AppRoutes.home);
//           }
//         } else if (data["type"] == "call_rejected") {
//           final callId = data["callID"]?.toString() ?? "";
//           final callerName = data["senderUsername"] ?? "Unknown";
//           debugPrint("📞 Call rejected by $callerName - callId=$callId");
//            Platform.isIOS ? CallKitBridge.dismissIncoming(callId) : null;
//           webRTCService.speakerphoneService.stopRingtone();
//           await webRTCService.endCall();

//           if (Get.currentRoute.contains('call')) {
//             Get.back();
//           }
//         } else if (data["type"] == "call_accepted") {
//           final callId = data["callID"]?.toString() ?? "";
//           final username = data["senderUsername"] ?? "Unknown";
//           debugPrint("✅ Call accepted by $username - callId=$callId");

//           webRTCService.speakerphoneService.stopRingtone();
//         }
//       },
//       onDone: () {
//         debugPrint("🔴 CallSignaling WebSocket connection closed");
//         channel = null;
//         _isConnecting = false;
//       },
//       onError: (e) {
//         debugPrint("🔴 CallSignaling WebSocket error: $e");
//         channel = null;
//         _isConnecting = false;
//       },
//     );

//     _isConnecting = false;
//   }

//   // ============================
//   // OUTGOING SIGNALING MESSAGES
//   // ============================

//   void sendOffer(RTCSessionDescription offer,bool isVideo) {
//     if (channel == null) {
//       debugPrint("❌ sendOffer: channel is null");
//       return;
//     }
//     final payload = {
//       "type": "call",
//       "offer": {"sdp": offer.sdp, "type": offer.type},
//       "callID": roomId,
//       "isVideo":isVideo
//     };
//     send(payload);
//     log("📤 OFFER SENT: $payload");
//   }

//   void sendAnswer(RTCSessionDescription answer) {
//     if (channel == null) {
//       debugPrint("❌ sendAnswer: channel is null");
//       return;
//     }
//     final payload = {
//       "type": "answer",
//       "answer": {"sdp": answer.sdp, "type": answer.type},
//       "callID": roomId,
//     };
//     send(payload);
//     log("📤 ANSWER SENT: $payload");
//   }

//   void sendIceCandidate(RTCIceCandidate candidate) {
//     if (channel == null) {
//       // candidates can come early; don't crash
//       return;
//     }
//     final payload = {
//       "type": "candidate",
//       "candidate": {
//         "candidate": candidate.candidate,
//         "sdpMid": candidate.sdpMid ?? "0",
//         "sdpMLineIndex": candidate.sdpMLineIndex ?? 0,
//       },
//       "callID": roomId,
//     };
//     send(payload);
//   }

//   // ============================
//   // CALL STATE NOTIFY METHODS
//   // ============================

//   void callAccepted(String callId) {
//     setRoom(callId);
//     send({"type": "call_accepted", "callID": callId});
//   }

//   void callRejected(String callId) {
//     setRoom(callId);
//     send({"type": "call_rejected", "callID": callId});
//   }

//   void callEnded(String callId) {
//     setRoom(callId);
//     send({"type": "call_ended", "callID": callId});
//   }

//   void callCancelled(String callId, {int? conversationId}) {
//     setRoom(callId);

//     // ✅ you said conversationId should come from callId/roomId
//     final derivedCid = _extractConversationIdFromRoomId(callId);

//     send({
//       "type": "call_cancelled",
//       "callID": callId,
//       "conversationId": conversationId ??
//           (derivedCid != 0 ? derivedCid : chatConfigController.config.prefs.getInt(chatConfigController.config.conversationId)),
//     });
//   }

//   void send(Map<String, dynamic> payload) {
//     try {
//       channel?.sink.add(jsonEncode(payload));
//       log("send signaling:${jsonEncode(payload)}");
//     } catch (e) {
//       debugPrint("❌ CallSignaling send failed: $e");
//     }
//   }

//   void disconnect() {
//     try {
//       channel?.sink.close(status.normalClosure);
//     } catch (_) {}
//     channel = null;
//     _isConnecting = false;
//     _connectedConversationId = 0;
//   }

//   @override
//   void onClose() {
//     disconnect();
//     super.onClose();
//   }
// }
