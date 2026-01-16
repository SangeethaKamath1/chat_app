// import 'package:chat_app/chat_app.dart';
// import 'package:chat_app/group/group_chat/controller/group_chat_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:permission_handler/permission_handler.dart';

// class OngoingCallBanner extends StatelessWidget {
//   final GroupChatController chatController;
//   const OngoingCallBanner({super.key, required this.chatController});

//   Future<void> _joinOngoingGroupCall({
//     required String callId,
//     required bool isVideo,
//   }) async {
//     try {
//       final mic = await Permission.microphone.request();
//       if (!mic.isGranted) {
//         Get.snackbar("Permission required", "Microphone permission is needed");
//         return;
//       }

//       if (isVideo) {
//         final cam = await Permission.camera.request();
//         if (!cam.isGranted) {
//           Get.snackbar("Permission required", "Camera permission is needed");
//           return;
//         }
//       }

//       // keep roomId synced
//       chatController.chatWebSocket.callID.value = callId;

//       // optional: notify backend you joined
//       chatController.chatWebSocket.emitGroupCallAccepted(callId: callId);

//       Get.toNamed(
//         ChatAppRoutes.groupCallScreen,
//         arguments: {
//           "callId": callId,
//           "isCaller": false,
//           "fromNotification": false,
//           "isVideo": isVideo,
//         },
//       );
//     } catch (e) {
//       debugPrint("❌ Join ongoing call failed: $e");
//       Get.snackbar("Join Failed", "Unable to join group call");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final socket = chatController.chatWebSocket;

//     return Obx(() {
//       if (socket.hasOngoingCall.value == false) {
//         return const SizedBox.shrink();
//       }

//       final callId = socket.ongoingCallId.value;
//       final isVideo = socket.ongoingIsVideo.value;

//       // you should maintain this count from backend/socket
//       final count = socket.ongoingParticipantsCount.value; // <-- add this RxInt

//       final title = isVideo ? "Ongoing group video call" : "Ongoing group audio call";

//       return Container(
//         margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//         decoration: BoxDecoration(
//           color: Colors.green.shade700,
//           borderRadius: BorderRadius.circular(14),
//         ),
//         child: Row(
//           children: [
//             Icon(isVideo ? Icons.videocam : Icons.call, color: Colors.white),
//             const SizedBox(width: 10),

//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.w700,
//                       fontSize: 14,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     "$count participants",
//                     style: const TextStyle(
//                       color: Colors.white70,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(width: 10),

//             InkWell(
//               onTap: () async {
//                 await _joinOngoingGroupCall(callId: callId, isVideo: isVideo);
//               },
//               borderRadius: BorderRadius.circular(18),
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(18),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(
//                       isVideo ? Icons.videocam : Icons.call,
//                       size: 18,
//                       color: Colors.green.shade800,
//                     ),
//                     const SizedBox(width: 6),
//                     Text(
//                       "Join",
//                       style: TextStyle(
//                         color: Colors.green.shade800,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     });
//   }
// }
