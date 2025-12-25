import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/io.dart';
import '../../audio_call/screens/incoming_call_screen.dart';
import '../../audio_call/service/webrtc_service.dart';
import '../../chat_app.dart';
import '../../constants/api_constants.dart';
import '../../constants/app_constant.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../model/conversation_list.dart';
import '../controller/chat_controller.dart';
import '../helpers/encryption_helper.dart';

class ChatWebSocketService extends GetxService{
  IOWebSocketChannel? channel;
  final ChatController chatController;
   ChatWebSocketService(this.chatController);

  final webRTCService = Get.find<WebRTCService>();
   @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
   }

  
  void connect(int conversationId) {
  channel = IOWebSocketChannel.connect(Uri.parse("${ApiConstants.chatWebSocketService}?token=${chatConfigController.config.prefs.getString(chatConfigController.config.token)}&conversationId=$conversationId"));
  debugPrint("✅ [${hashCode}] WebSocket connected");
  
  channel?.stream.listen((event) async {
    final data = jsonDecode(event);
    debugPrint("📡 WebSocket event: ${data["type"]}");
    
    if(data["type"] == "msg") {
      final decryptedMsg = EncryptionHelper.decryptText(data['msg']);
      var replyTo;
      if(data["replyTo"] != null) {
        replyTo = Conversations(
          id: data["replyTo"] ?? "",
          senderUUID: data["receiver"] ?? "",
          senderUsername: data["receiverUsername"] ?? "",
          message: EncryptionHelper.decryptText(data["reply"] ?? "")
        );
      } else {
        replyTo = null;
      }
      chatController.conversations.insert(0, Conversations(
        id: data["messageId"] ?? "",
        senderUUID: data["sender"] ?? "",
        senderUsername: data['senderUsername']??"",
        message: decryptedMsg,
        replayTo: replyTo
      ));
    }
    // else if (data["type"] == "call") {
    //   final roomId = data["callID"];
    //   final callerName = data["senderUsername"] ?? "Unknown";
    //   debugPrint("📞 Incoming call from $callerName - Room: $roomId");
       
    //    webRTCService.speakerphoneService.stopRingtone();
    //   Get.to(() => IncomingCallScreen(
    //     roomId: roomId,
    //     callerName: callerName,
    //   ));
    // }
    else if(data["type"] == "call") {
      // ✅ Handle WebRTC offer from caller
      final offerData = data["offer"];
      final roomId = data["callID"];
       await webRTCService.handleOffer(RTCSessionDescription(offerData['sdp'], offerData['type']));
      debugPrint("📥 Received WebRTC offer for room: $roomId");
       final callerName = data["senderUsername"] ?? "Unknown";
      debugPrint("📞 Incoming call from $callerName - Room: $roomId");
     
       
       webRTCService.speakerphoneService.stopRingtone();
      Get.to(() => IncomingCallScreen(
        roomId: roomId,
        callerName: callerName,
      ));
      
     
      
    }
    else if(data["type"] == "answer") {
      // ✅ Handle WebRTC answer from callee  
      final answerData = data["answer"];
      final roomId = data["callID"];
      debugPrint("📥 Received WebRTC answer for room: $roomId");
      
    
      await webRTCService.handleAnswer(RTCSessionDescription(answerData['sdp'], answerData['type']));
    }
    else if(data["type"] == "candidate") {
      // ✅ Handle ICE candidate
      final candidateData = data["candidate"];
      final roomId = data["callID"];
      debugPrint("❄️ Received ICE candidate for room: $roomId");
      
    
      await webRTCService.addIceCandidate(RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'] ?? '0',
        candidateData['sdpMLineIndex'] is int 
            ? candidateData['sdpMLineIndex'] 
            : int.tryParse(candidateData['sdpMLineIndex']?.toString() ?? '0') ?? 0,
      ));
    }
    else if(data["type"] == "call_ended") {
      
      final roomId = data["callID"];
      debugPrint("📞 Call ended - Room: $roomId");
      
      
       webRTCService.speakerphoneService.stopRingtone();
      await webRTCService.endCall();
      
      // Navigate back only if we're on a call screen
     // if (Get.currentRoute.contains('call')) {
        Get.back();
     // }
    }
    else if(data["type"] == "call_rejected") {
      final roomId = data["callID"];
      final callerName = data["senderUsername"] ?? "Unknown";
      debugPrint("📞 Call rejected by $callerName - Room: $roomId");
      
     webRTCService.speakerphoneService.stopRingtone();
      await webRTCService.endCall();
      
      // Navigate back only if we're on a call screen
      if (Get.currentRoute.contains('call')) {
        Get.back();
      }
    }
    else if(data["type"] == "call_accepted") {
      // ✅ Handle call accepted notification
      final roomId = data["callID"];
      final username = data["senderUsername"] ?? "Unknown";
      debugPrint("✅ Call accepted by $username - Room: $roomId");
      webRTCService.speakerphoneService.stopRingtone();
      
      // Update UI status if needed
      chatController.callStatus.value = "Call accepted, connecting...";
    }
    else if(data["type"] == "typing") {
      chatController.isTyping.value = data["isTyping"] == "true" ? true : false;
    }
    else if(data["type"] == "reload") {
      if(data["status"]=="DELIVERED"){
        chatController.updateMessageStatusToDelivered();
      }else{
      chatController.updateMessageStatusToSeen();
      }
      chatController.conversations.refresh();
    }else if(data['type']=="delete"){
      chatController.conversations.removeWhere((ele)=>ele.id == data['messageId']);
      chatController.conversations.refresh();
    }
    else if(data["status"] == "DELIVERED") {
      Future.delayed(const Duration(milliseconds: 300), () {
        debugPrint("delivered message id:${data["messageId"]}");
        chatController.updateMessageStatusById(data["messageId"], data["status"]);
      });
    }
    else if(data["status"] == "SEEN") {
      chatController.updateMessageStatusToSeen();
    }
    else if(data["type"] == "REACTION") {
      chatController.updateReaction(data["messageId"], data["reaction"], data["oldReaction"]);
    }
  },
  onDone: () {
    debugPrint("🔴 WebSocket connection closed");
  },
  onError: (e) {
    debugPrint("🔴 WebSocket connection error: $e");
  });
}
    void disconnect() {
    channel?.sink.close(status.normalClosure);
  }

  @override
  void onClose() {
    Get.delete<ChatWebSocketService>();
    Get.delete<ChatController>();
    debugPrint("onclose called");
   channel?.sink.close(status.normalClosure);
    super.onClose();
    
    
  }


  void onChanged(bool isTyping){
    final payload = {
       "type": "typing",
      "isTyping": isTyping.toString()
    };
    channel?.sink.add(jsonEncode(payload));
      if (kDebugMode) {
        print("📤 Sent typing: $payload");
      }
    }

// void  initiatingCall(String roomId){
//   debugPrint("fcm token while initiating a call:${chatConfigController.config.prefs.getString(chatConfigController.config.fcmToken)??""}");
//     final payload={
//       "type":"call",
//       "offer":{"sdp": "", "type": "",},
//       "callID":roomId,
     

//     };
//     channel?.sink.add(jsonEncode(payload));
//      print("initiating call : $payload");
//   }

  void  callAccepted(String roomId){
    final payload={
      "type":"call_accepted",
      "callID":roomId

    };
    channel?.sink.add(jsonEncode(payload));
     print("accepting a  call : $payload");
  }
  void callRejected(String roomId){
    final payload={
      "type":"call_rejected",
      "callID":roomId
    };
    channel?.sink.add(jsonEncode(payload));
     print("rejecting call : $payload");
  }



  void callEnded(String roomId){
    final payload={
      "type":"call_ended",
      "callID":roomId
    };
    channel?.sink.add(jsonEncode(payload));
     print("ending call : $payload");
  }

    void sendMessage(String messageId,String message, int conversationId){
      final payload={
        "type":"msg",
        "messageId":messageId,
        "msg":message
      };
      channel?.sink.add(jsonEncode(payload));
      print("📤message : $payload");
    }

    void deleteMessage(String messageId){
      final payload = {
        "type":"delete",
        "messageId":messageId
      };
        channel?.sink.add(jsonEncode(payload));
      
         debugPrint("message id jdnjsdn :${messageId}");
        chatController.conversations.removeAt(chatController.chatIndex.value);
        chatController.conversations.refresh();
        chatController.messageId.value="";
        chatController.chatIndex.value=-1;
         chatController.showEmojiPicker.value=false;

    }



void sendMessageWithReply({required String replyTo,required String receiver,required receiverUsername,required String reply,required String messageId,required String message}){
      final payload={
        "type":"msg",
        "replyTo":replyTo,
        "receiver":receiver,
        "receiverUsername":receiverUsername,
  "reply":reply,
  "messageId":messageId,
  "msg": message
      };
      channel?.sink.add(jsonEncode(payload));
      if (kDebugMode) {
        print("📤message : $payload");
      }
    }
    void sendReaction(String messageId,String reaction, int conversationId){
      final payload={
        "type":"reaction",
        "messageId":messageId,
        "msg":reaction
      };
      channel?.sink.add(jsonEncode(payload));
      if (kDebugMode) {
        print("📤message : $payload");
      }
      chatController.messageId.value="";
      chatController.messageController.text="";
      chatController.chatIndex.value=-1;
      chatController.showEmojiPicker.value=false;
    }





}