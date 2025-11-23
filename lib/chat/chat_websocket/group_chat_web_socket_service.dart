import 'dart:convert';

import 'package:chat_module/group/group_chat/controller/group_chat_controller.dart';
import 'package:chat_module/service/shared_preference.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:web_socket_channel/io.dart';

import '../../constants/api_constants.dart';
import '../../constants/app_constant.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../model/conversation_list.dart';
import '../controller/chat_controller.dart';
import '../helpers/encryption_helper.dart';

class GroupChatWebSocketService extends GetxService{
  IOWebSocketChannel? channel;
  final GroupChatController chatController;
   GroupChatWebSocketService(this.chatController);

  
   @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
   
    //chatController =Get.find<ChatController>();

  }
  void connect(int conversationId){

    
    channel = IOWebSocketChannel.connect(Uri.parse("${ApiConstants.groupChatWebsocketUrl}?token=${SharedPreference().getString(AppConstant.token)}&conversationId=$conversationId"));
        debugPrint("✅ [${hashCode}] group WebSocket connected");
    channel?.stream.listen((event){
       final data = jsonDecode(event);
       debugPrint("chat connection is done:$data");
      if(data["type"] == "msg"){
         final decryptedMsg = EncryptionHelper.decryptText(data['msg']);
         var replyTo;
if(data["replyTo"]!=null){
   replyTo=Conversations(id:data["replyTo"]??"",senderUUID: data["receiver"]??"",senderUsername: data["senderUsername"]??"",message: data["reply"]??"");
}else{
  replyTo=null;
}

          chatController.conversations.insert(0, Conversations(id:data["messageId"]??"",senderUUID: data["sender"]??"",message: decryptedMsg,replayTo:replyTo ));
      }
      else if(data["type"]=="typing"){
        chatController.isTyping.value=data["isTyping"] == "true"?true:false;
        chatController.typingUser.value=data["senderUsername"]??"";
      }
     else if(data["type"] == "reload") {
      if(data["status"]=="DELIVERED"){
        chatController.updateMessageStatusToDelivered();
      }else{
      chatController.updateMessageStatusToSeen();
      }
      chatController.conversations.refresh();
    }
      else if(data["status"]=="DELIVERED"){
       Future.delayed(const Duration(milliseconds: 300), () {
        debugPrint("delivered message id:${data["messageId"]}");
  chatController.updateMessageStatusById(data["messageId"],data["status"]);
});
       // chatController.conversations.refresh();
      }
      else if(data["status"]=="SEEN"){
        chatController.updateMessageStatusToSeen();
       chatController.conversations.refresh();
      }
      else if(data["type"]=="REACTION"){
       
        chatController.updateReaction(data["messageId"],data["reaction"], data["oldReaction"]);
       chatController.conversations.refresh();
      }


      
    

    },
  onDone: (){
      debugPrint("✅ chat WebSocket connection closed");
  },onError: (e){
   debugPrint("✅ chat WebSocket connection closed");
  });
  }
    void disconnect() {
    channel?.sink.close(status.normalClosure);
  }

  @override
  void onClose() {
    Get.delete<GroupChatWebSocketService>();
    Get.delete<ChatController>();
    debugPrint("onclose called");
   channel?.sink.close(status.normalClosure);
    super.onClose();
    
    
  }


  void onChanged(bool isTyping){
    final payload = {
       "type": "typing",
      "isTyping": isTyping.toString(),
      "senderUsername":SharedPreference().getString(
        AppConstant.username
      )??""
      
    };
    channel?.sink.add(jsonEncode(payload));
      if (kDebugMode) {
        print("📤 Sent typing: $payload");
      }
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