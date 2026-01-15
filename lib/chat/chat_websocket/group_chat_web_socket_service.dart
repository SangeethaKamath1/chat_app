import 'dart:convert';
import 'dart:developer';

import 'package:chat_app/group/group_chat/controller/group_chat_controller.dart';
import 'package:chat_app/group_audio_video_call/service/livekit_group_audio_service.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:web_socket_channel/io.dart';

import '../../chat_app.dart';
import '../../constants/api_constants.dart';
import '../../constants/app_constant.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../model/conversation_list.dart';
import '../controller/chat_controller.dart';
import '../helpers/encryption_helper.dart';

class GroupChatWebSocketService {
  IOWebSocketChannel? channel;

   GroupChatWebSocketService();
final RxString roomId = "".obs;
  int _connectedConversationId = 0;
  bool _isConnecting = false;
  void setRoom(String callId) {
    roomId.value= callId;
    debugPrint("🧩 CallSignalingService roomId set: $roomId");
  }

static int _extractConversationIdFromCallId(String callId) {
    final first = callId.split("_").first;
    return int.tryParse(first) ?? 0;
  }

  void ensureConnectedFromRoomId(String callId) async {
    final cid = _extractConversationIdFromCallId(callId);
    if (cid == 0) {
      debugPrint("❌ ensureConnectedFromRoomId: invalid conversationId for callId=$callId");
      return;
    }
    connect(cid);
  }
  void connect(int conversationId){
  if (_isConnecting) {
      debugPrint("⏸️ CallSignalingService connect skipped (already connecting)");
      return;
    }

    // If we already have a channel and it's for same conversation, keep it.
    // But if you ever get a stale socket, you MUST reconnect.
    // We handle that by reconnecting on onDone/onError (channel=null there).
    if (channel != null && _connectedConversationId == conversationId) {
      debugPrint("⏸️ CallSignalingService already connected (conv=$conversationId)");
      return;
    }

    // If switching conversationId, close old channel first.
    if (channel != null && _connectedConversationId != conversationId) {
      debugPrint("🔁 Switching signaling conversation: $_connectedConversationId -> $conversationId");
      disconnect();
    }
        _isConnecting = true;
    _connectedConversationId = conversationId;
    
    channel = IOWebSocketChannel.connect(Uri.parse("${ApiConstants.groupChatWebsocketUrl}?token=${chatConfigController.config.prefs.getString(chatConfigController.config.token)}&conversationId=$conversationId"));
        debugPrint("✅ [${hashCode}] group WebSocket connected");
    channel?.stream.listen((event){
       final data = jsonDecode(event);
       debugPrint("chat connection is done:$data");
  if (data["type"] == "msg") {
     final chatController = Get.find<GroupChatController>();
        final decryptedMsg = EncryptionHelper.decryptText(data['msg']);
        var replyTo;
        if (data["replyTo"] != null) {
          replyTo = Conversations(
              id: data["replyTo"] ?? "",
              senderUUID: data["receiver"] ?? "",
              senderUsername: data["receiverUsername"] ?? "",
              message: data["reply"] ?? "",
              medias: data["urls"]);
        } else {
          replyTo = null;
        }
        // debugPrint("json encode:${jsonEncode(replyTo)
        // }");
        chatController.conversations.insert(
            0,
            Conversations(
                id: data["messageId"] ?? "",
                senderUUID: data["sender"] ?? "",
                senderUsername: data['senderUsername'] ?? "",
                message: decryptedMsg,
                replayTo: replyTo));
        chatController.conversations.refresh();
        debugPrint(
          "🆕 Latest conversation in msg: ${jsonEncode(chatController.conversations.first)}",
        );
      }
      else if(data["type"]=="typing"){
        final chatController = Get.find<GroupChatController>();
        chatController.isTyping.value=data["isTyping"] == "true"?true:false;
        chatController.typingUser.value=data["senderUsername"]??"";
      }
     else if(data["type"] == "reload") {
     final chatController = Get.find<GroupChatController>();
      if(data["status"]=="DELIVERED"){
        
        chatController.updateMessageStatusToDelivered();
      }else{
      chatController.updateMessageStatusToSeen();
      }
      chatController.conversations.refresh();
    }
      else if(data["status"]=="DELIVERED"){
        final chatController = Get.find<GroupChatController>();
       Future.delayed(const Duration(milliseconds: 300), () {
        debugPrint("delivered message id:${data["messageId"]}");
  chatController.updateMessageStatusById(data["messageId"],data["status"]);
});
       // chatController.conversations.refresh();
      }
      else if(data['type']=="delete"){
          final chatController = Get.find<GroupChatController>();
        debugPrint("message id on type delete:${data['messageId']},${chatController.conversations.length}");
     chatController.conversations.removeWhere((ele) {
          debugPrint(
              "message delete id :${data['messageId']},${ele.id},${ele.id.toString() == data['messageId'].toString()}");
          return ele.id.toString() == data['messageId'].toString();
        });
      chatController.conversations.refresh();
    }
      else if(data["status"]=="SEEN"){
        final chatController = Get.find<GroupChatController>();
        chatController.updateMessageStatusToSeen();
       chatController.conversations.refresh();
      }
      else if(data["type"]=="REACTION"){
       final chatController = Get.find<GroupChatController>();
        chatController.updateReaction(data["messageId"],data["reaction"], data["oldReaction"]);
       chatController.conversations.refresh();
      }
      else if (data["type"] == "media") {
         final chatController = Get.find<GroupChatController>();
        /// 🔹 Extract media URLs
        final List<dynamic> mediaUrls = [];

        if (data["mediaUploadResponse"] != null) {
          for (final item in data["mediaUploadResponse"]) {
            if (item["success"] == true && item["url"] != null) {
              mediaUrls.add(item["url"]);
            }
          }
        }
        var replyTo;
        if (data["replyTo"] != null) {
         
          replyTo = Conversations(
              id: data["replyTo"] ?? "",
              senderUUID: data["receiver"] ?? "",
              senderUsername: data["receiverUsername"] ?? "",
              message: data["reply"] ?? "",
              medias: data["urls"]);
        } else {
          replyTo = null;
        }
        chatController.conversations.insert(
            0,
            Conversations(
                id:  data["mediaUploadResponse"][0]["messageId"] ?? "",
                senderUUID: data["sender"] ?? "",
                senderUsername: data['senderUsername'] ?? "",
                medias: mediaUrls,
                replayTo: replyTo));
                 chatController.conversations.refresh();
        debugPrint(
          "🆕 Latest conversation: ${jsonEncode(chatController.conversations.first)}",
        );
      }
      else if (data["type"] == "group_call_started") {
  final callId = data["callId"];
  roomId.value = callId;

  Get.toNamed(
    ChatAppRoutes.groupCallScreen,
    arguments: {"isCaller": false},
  );
}
 else if (data["type"] == "group_call_accepted") {
  final callId = data["callId"];
  roomId.value = callId;

  Get.toNamed(
    ChatAppRoutes.groupCallScreen,
    arguments: {"isCaller": false},
  );
}
// else if (data['type'] == 'group_answer') {
//   groupWebRTCService.handleAnswer(data['sdp']);
// }
// else if (data['type'] == 'group_candidate') {
//   groupWebRTCService.addIceCandidate(data['candidate']);
// }

      
    

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

    void emitGroupCallStarted({
    required String callId,
    required bool isVideo
  }) {
   

    send({
      "type": "group_call_started",
      "callID": callId,
      "isVideo":isVideo
    });

    log("📣 [GROUP_SIGNAL] group_call_started sent callId=$callId");
  }
  void send(Map<String, dynamic> payload) {
    try {
      channel?.sink.add(jsonEncode(payload));
      log("send signaling:${jsonEncode(payload)}");
    } catch (e) {
      debugPrint("❌ CallSignaling send failed: $e");
    }
  }

 


  void onChanged(bool isTyping){
    final payload = {
       "type": "typing",
      "isTyping": isTyping.toString(),
      "senderUsername":chatConfigController.config.prefs.getString(
        chatConfigController.config.username
      )??""
      
    };
    channel?.sink.add(jsonEncode(payload));
      if (kDebugMode) {
        print("📤 Sent typing: $payload");
      }
    }
void emitGroupCallAccepted({required String callId}) {
  send({
    "type": "group_call_accepted",
    "callId": callId,
  });
  debugPrint("✅ [GROUP_SIGNAL] group_call_accepted sent callId=$callId");
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

    void deleteMessage(String messageId,int index){
       final chatController = Get.find<GroupChatController>();
      debugPrint(
        "delete indeex111:${messageId},${chatController.chatIndex.value},${chatController.conversations.length}");
      final payload = {
        "type":"delete",
        "messageId":messageId
      };
        channel?.sink.add(jsonEncode(payload));
        debugPrint("delete message:${jsonEncode(payload)}");
      
         debugPrint("message id on socket :${messageId}");
          debugPrint("delete conversation:${chatController.conversations[index].message}");
       chatController.conversations.removeAt(index);
        chatController.conversations.refresh();
        chatController.messageId.value="";
        chatController.chatIndex.value=-1;
        debugPrint("chat controller -1 inside group chat web socket delete message");
         chatController.showEmojiPicker.value=false;

    }



void sendMessageWithReply({required String replyTo,required String receiver,required receiverUsername,required String reply,required String messageId,required String message,dynamic urls}){
    if (urls != null) {
      final payload = {
        "type": "msg",
        "replyTo": replyTo,
        "receiver": receiver,
        "receiverUsername": receiverUsername,
        "messageId": messageId,
        "msg": message,
        "urls": urls
      };
      channel?.sink.add(jsonEncode(payload));
      if (kDebugMode) {
        print("📤message urls.isNotEmpty: $payload");
      }
    } else {
      final payload = {
        "type": "msg",
        "replyTo": replyTo,
        "receiver": receiver,
        "receiverUsername": receiverUsername,
        "reply": reply,
        "messageId": messageId,
        "msg": message,
      };
      channel?.sink.add(jsonEncode(payload));
      if (kDebugMode) {
        print("📤message urls isempty: $payload");
      }
    }
    }
    void sendReaction(String messageId,String reaction, int conversationId){
       final chatController = Get.find<GroupChatController>();
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
      debugPrint("chat controller -1 inside group chat web socket service send reaction");
      chatController.showEmojiPicker.value=false;
    }





}