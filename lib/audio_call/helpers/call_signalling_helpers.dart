// import 'package:flutter/material.dart';

// import '../service/call_signaling_service.dart';

// extension CallSignalingHelpers on CallSignalingService {
//   void setRoom(String id) => roomId = id;

//   int _extractConversationIdFromRoomId(String roomId) {
//     final first = roomId.split("_").first;
//     return int.tryParse(first) ?? 0;
//   }

//   void ensureConnectedFromRoomId(String roomId) {
//     final cid = _extractConversationIdFromRoomId(roomId);
//     if (cid == 0) {
//       debugPrint("❌ ensureConnectedFromRoomId: invalid conversationId for roomId=$roomId");
//       return;
//     }
//     connect(conversationId: cid);
//   }
// }