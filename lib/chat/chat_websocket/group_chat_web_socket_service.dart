import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:amu_alumni/amu_alumni.dart';
import 'package:chat_app/group/group_chat/controller/group_chat_controller.dart';
import 'package:chat_app/group_audio_video_call/service/livekit_group_audio_service.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:web_socket_channel/io.dart';

import '../../audio_call/service/speakerphone_service.dart';
import '../../chat_app.dart';
import '../../constants/api_constants.dart';
import '../../constants/app_constant.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../../model/conversation_list.dart';
import '../controller/chat_controller.dart';
import '../helpers/encryption_helper.dart';

class GroupChatWebSocketService extends GetxService{
  IOWebSocketChannel? channel;


 
final RxString callID = "".obs;
  int _connectedConversationId = 0;
  bool _isConnecting = false;
  int _retryCount = 0;
  int _lastConversationId = 0;
  bool _isReconnecting = false;
  Timer? _pingTimer;
  Timer? _pongTimer;
  bool _waitingForPong=false;
void _startHeartBeat(){
  _stopHeartBeat();
  _pingTimer = Timer.periodic(Duration(seconds: 30),(_){
    _sendPing();
  });
}
void _stopHeartBeat(){
  _pingTimer= null;
  _pingTimer?.cancel();
  _waitingForPong=false;
  _pongTimer = null;
  _pongTimer?.cancel();

}
  void _sendPing(){
    if(_waitingForPong){
      return;
    }
   
    try{
       final payload = {"type": "ping"};
      channel?.sink.add(jsonEncode(payload));
       _waitingForPong=true;
       _pongTimer?.cancel();
      _pingTimer = Timer(const Duration(seconds: 30),(){
        if(_waitingForPong){
          debugPrint("after 30 seconds still waiting for pong so disconnect and reconnect:${_waitingForPong}");
          disconnect();
          connect(_lastConversationId);
        }
      });
    }catch(e){
 debugPrint("exception on ping:");
      _stopHeartBeat();
      disconnect();
       connect(_connectedConversationId);
          }

  }
  void _onPongReceived() {
    debugPrint("📥 xcg");
    _waitingForPong = false;
    _pongTimer?.cancel();
    _pongTimer = null;
  }
  static const int _maxRetries = 5;
  // RxBool hasOngoingCall = false.obs;
  // RxString ongoingCallId = "".obs;
  // RxBool ongoingIsVideo = false.obs;
  // RxInt ongoingParticipantsCount = 1.obs;
   final SpeakerphoneService speakerSvc = Get.find<SpeakerphoneService>();
  void setRoom(String callId) {
    callID.value= callId;
    debugPrint("🧩 CallSignalingService roomId set: ${callID.value}");
  }

static int _extractConversationIdFromCallId(String callId) {
    final first = callId.split("_").first;
    return int.tryParse(first) ?? 0;
  }

  void ensureConnectedFromRoomId(String callId) async {
    debugPrint("ensure connected from room id is called");
    final cid = _extractConversationIdFromCallId(callId);
debugPrint("ensure connected from room id is called:${cid}");
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
        _lastConversationId = conversationId;
    try {
    channel = IOWebSocketChannel.connect(Uri.parse("${ApiConstants.groupChatWebsocketUrl}?token=${chatConfigController.config.prefs.getString(chatConfigController.config.token)}&conversationId=$conversationId"));
        debugPrint("✅ [${hashCode}] group WebSocket connected");
        _startHeartBeat();
         _retryCount = 0;
    channel?.stream.listen((event){
       final data = jsonDecode(event);
       debugPrint("group chat connection is done:$data");
        if(data["type"]=="PONG"){
            _onPongReceived();
        }
  else if (data["type"] == "msg") {
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
  //     else if (data["type"] == "group_call_started") {
  // final callId = data["callID"];
  // roomId.value = callId;

  // Get.toNamed(
  //   ChatAppRoutes.groupCallScreen,
  //   arguments: {"isCaller": false},
  // );
// }
else if (data["type"] == "group_call_ended") {
  final callId = data["callID"];
  callID.value = callId??"";
  // hasOngoingCall.value=false;
  //   hasOngoingCall.value=true;
  // ongoingCallId.value ="";
  // ongoingIsVideo.value=false;
  final LiveKitGroupAudioService lg = Get.find<LiveKitGroupAudioService>();
  if(lg.isConnected.value){
    Platform.isIOS? CallKitBridge.dismissIncoming(callID.value):null;
           Get.find<LiveKitGroupAudioService>().leaveGroupAudio();
         

         final nav = Get.key.currentState; // GetMaterialApp navigatorKey
  final canGoBack = nav?.canPop() ?? false;
  debugPrint("can go back:${canGoBack}");

  if (canGoBack) {
    Get.back();
  } else {
    Get.offAllNamed(AppRoutes.home);


}}
}
// else if(data["type"]== "ongoing_group_call"){
//   hasOngoingCall.value=true;
//   ongoingCallId.value =data["callID"];
//   ongoingIsVideo.value=data["isVideo"];
// // ongoingParticipantsCount.value = data[]
  
// }
 else if (data["type"] == "group_call_accepted") {
  // final callId = data["callID"];
  // roomId.value = callId;

  //speakerSvc.stopRingtone();
}
// else if (data['type'] == 'group_answer') {
//   groupWebRTCService.handleAnswer(data['sdp']);
// }
// else if (data['type'] == 'group_candidate') {
//   groupWebRTCService.addIceCandidate(data['candidate']);
// }

      
    

    },
  onDone: (){
      debugPrint("✅ group chat WebSocket connection closed");
       _isConnecting = false;
  channel = null;
  },onError: (e){
     _isConnecting = false;
  channel = null;
  _stopHeartBeat();
   debugPrint("✅ chat WebSocket connection closed");
   _handleRetry();
  });
  } catch (e) {
    _stopHeartBeat();
      debugPrint("❌ GROUP WS connect exception: $e");
      _handleRetry();
    }
  }
    void disconnect() {
    try { channel?.sink.close(status.normalClosure); } catch (_) {}
  channel = null;
  _isConnecting = false;
  _connectedConversationId = 0;
  }

  Future<void> _handleRetry() async {
    if (_isReconnecting) return;
    if (_retryCount >= _maxRetries) {
      debugPrint("❌ GROUP WS max retry reached");
      return;
    }

    _isReconnecting = true;
    _retryCount++;

    final delay = Duration(seconds: 2 * _retryCount);
    debugPrint(
        "🔄 GROUP WS retry $_retryCount after ${delay.inSeconds}s");

    await Future.delayed(delay);

    disconnect();
    connect(_connectedConversationId);

    _isReconnecting = false;
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

  void emitGroupCallAccepted({required String callId}) {
  send({
    "type": "group_call_accepted",
    "callID": callId,
    "sender":chatConfigController.config.prefs.getInt(
        chatConfigController.config.id),
    "senderUsername":chatConfigController.config.prefs.getString(
        chatConfigController.config.username)
  });
  debugPrint("✅ [GROUP_SIGNAL] group_call_accepted sent callId=$callId");
}

void emitGroupCallLeft({required String callId}) {
  send({
    "type": "group_call_left",
    "callID": callId,
    "sender":chatConfigController.config.prefs.getInt(
        chatConfigController.config.id),
    "senderUsername":chatConfigController.config.prefs.getString(
        chatConfigController.config.username)
  });
  debugPrint("✅ [GROUP_SIGNAL] group_call_accepted sent callId=$callID");
}
void emitGroupCallCancelled({required String callId}) {
  send({
    "type": "group_call_cancelled",
    "callID": callId,
    "sender":chatConfigController.config.prefs.getInt(
        chatConfigController.config.id),
    "senderUsername":chatConfigController.config.prefs.getString(
        chatConfigController.config.username)
  });
  debugPrint("✅ [GROUP_SIGNAL] group_call_accepted sent callId=$callId");
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