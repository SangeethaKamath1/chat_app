import 'dart:async';

import 'package:chat_app/chat/chat_websocket/chat_web_socket_service.dart';
import 'package:chat_app/chat/chat_websocket/group_chat_web_socket_service.dart';
import 'package:chat_app/constants/app_constant.dart';
import 'package:chat_app/group/group_detail/repository/group_detail_repository.dart';
import 'package:chat_app/group/repository/group_chat_repository.dart';
import 'package:chat_app/model/group_message_status.dart';
import 'package:chat_app/service/dio_service.dart';
import 'package:chat_app/service/shared_preference.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../chat/helpers/encryption_helper.dart';
import '../../../chat/repository/chat_repository.dart';
import '../../../model/conversation_list.dart';
import '../../../model/reaction_list_response.dart';
import '../../../model/user.dart';

class GroupChatController extends FullLifeCycleController with FullLifeCycleMixin {
  String userId = "";
  RxString name = "".obs;
  RxString typingUser="".obs;
  RxString description = "".obs;
   RxInt chatIndex = (-1).obs;
  RxString status = "".obs;
  Rx<User> currentGroupDetails= User().obs;
  int page = 0;
  RxList<UserStatus> sentList=<UserStatus>[].obs;
  RxList<UserStatus> deliveredList=<UserStatus>[].obs;
  RxList<UserStatus> seen=<UserStatus>[].obs;

  int reactionsPageNumber = 0;
  RxList<Reaction> reactions = <Reaction>[].obs;
  bool isReactionLastPage = false;
  bool isReactionLoading = false;
  String conversationId = "";
  RxBool isTyping = false.obs;
  RxString messageId = "".obs;
  bool isLoading = false;
  Timer? typingTimer;
  bool isLastPage = false;
  final ScrollController scrollController = ScrollController();
  final Uuid uuid = Uuid();
  var selectedMessageIndex = (-1).obs;
  RxList<Conversations> conversations = <Conversations>[].obs;

  final TextEditingController messageController = TextEditingController();

  var replyMessage = Rxn<Conversations>(); // the message being replied to

  void setReply(Conversations? message) {
    replyMessage.value = message;
  }

  void clearReply() {
    replyMessage.value = null;
  }

  // Messages list
// final RxList<String> messages = <String>[].obs;
  late final GroupChatWebSocketService chatWebSocket;
  var showEmojiPicker = false.obs; // <-- reactive state

  OverlayEntry? reactionOverlayEntry;

  void showReactionOverlayEntry(OverlayEntry entry) {
    reactionOverlayEntry = entry;
  }

  void removeReactionOverlay() {
    if (reactionOverlayEntry != null && reactionOverlayEntry!.mounted) {
      reactionOverlayEntry!.remove();
      reactionOverlayEntry = null;
    }
  }



  void toggleEmojiPicker() {
    showEmojiPicker.value = !showEmojiPicker.value;
  }

  @override
  void onInit() {
    super.onInit();
   
    name.value = Get.arguments['name'].toString();
    conversationId = Get.arguments['conversationId'].toString();
    status.value = Get.arguments['status'].toString();
    //  if(conversationId.isEmpty){
    //   createConversation();
    //   }else{

    if (conversationId.isNotEmpty) {
      getCurrentGroupDetails();
    
      chatWebSocket = Get.put(GroupChatWebSocketService(this));
      chatWebSocket.connect(int.parse(conversationId));

      // //  chatWebSocket = Get.put(ChatWebSocketService(this));

      // }
      if (conversations.isEmpty) {
      getConversationsList();
    }
    }
  }

  void onTextChanged(String value) {
    if (value.isNotEmpty) {
      chatWebSocket.onChanged(true);
      typingTimer?.cancel();
      typingTimer = Timer(const Duration(seconds: 2), () {
        chatWebSocket.onChanged(false);
      });
    }
  }

  Future<void> getCurrentGroupDetails()async{
    await GroupDetailRepository.groupDetails(SharedPreference().getInt(AppConstant.conversationId)??0).then((response){
currentGroupDetails.value = response.currentUser??User();
name.value = response.groupName??"";
description.value=response.description??'';


    });
  }

  void sendMessageWithReply() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    final replyTo = replyMessage.value;
    final encryptedText = EncryptionHelper.encryptText(text);
    // Add your API/WebSocket call here with replyId
    chatWebSocket.sendMessageWithReply(
     replyTo: replyTo?.id??"",
     receiver:replyTo?.senderUUID??"",
     receiverUsername: replyTo?.senderUsername??"",
     reply: replyTo?.message??"", messageId:"${conversationId}_${uuid.v4()}", message:  encryptedText,
    );


    // Update UI
    conversations.insert(
        0,
        Conversations(
          id: "${conversationId}_${uuid.v4()}",
          message: text,
          senderUsername: SharedPreference().getString(AppConstant.username),
          replayTo: replyTo, // <-- custom field
        ));
  conversations.refresh();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0.0, // top of reversed list = latest message
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    messageController.clear();
    clearReply();
  }

  // Send message
 Future<void> sendMessage() async {
  
  // ✅ Step 1: Ensure we have a valid conversation ID


  // ✅ Step 2: Double-check again after conversation creation
  if (conversationId.isEmpty) {
    debugPrint("❌ Conversation ID is still empty — cannot send message");
    return;
  }
  final text = messageController.text.trim();
  if (text.isEmpty) return;
  final messageId = "${conversationId}_${uuid.v4()}";
   debugPrint("🔍 Sending message with ID: $messageId"); // 🟢 Add this
  debugPrint("🔍 WebSocket hashCode: ${chatWebSocket.hashCode}");
  debugPrint("sender user name:${SharedPreference().getString(AppConstant.username)}");
conversations.insert(
    0,
    Conversations(
      id: messageId,
      message: text,
      senderUsername: SharedPreference().getString(AppConstant.username),
      status: "SEND",
    ),
  );
    conversations.refresh();
  
  // ✅ Step 3: Send only if message text is not empty
  

  // Encrypt text
  final encryptedText = EncryptionHelper.encryptText(text);
  

  // Send message over WebSocket
  chatWebSocket.sendMessage(messageId, encryptedText, int.parse(conversationId));

  // Locally add to UI
  

  messageController.clear();
}

 void updateReaction(messageId, reaction,oldReaction) {
    debugPrint("old reaction:${oldReaction}");
    for (var ele in conversations) {
      if (ele.id.toString() == messageId &&oldReaction!=null) {
       ele.reactions?.removeWhere((ele)=>ele ==EncryptionHelper.decryptText(oldReaction
       ));
       ele.reactions?.add(EncryptionHelper.decryptText(reaction));
        
      }else if(ele.id.toString() == messageId&& oldReaction==null){
        ele.reactions?.add(EncryptionHelper.decryptText(reaction));
      }
    }
    conversations.refresh();
  }

  Future<void> fetchMessageStatus(String messageId) async {
    try {
        GroupChatRepository.fetchMessageStatus(messageId).then((response){
          if(response.seen!=null){
            seen.value=response.seen??[];
           
          }if(response.delivered!=null){
            deliveredList.value=response.delivered??[];
          }if(response.sent!=null){
            sentList.value=response.sent??[];
          }
        });
    }catch(e){
debugPrint("something went wrong:$e");
    }
     
  }

  
  void sendReaction() {
    if (messageController.text.trim().isNotEmpty) {
      // messages.add(messageController.text.trim());
        final encryptedText = EncryptionHelper.encryptText(messageController.text);
      chatWebSocket.sendMessage("${conversationId}_${uuid.v4()}",
          encryptedText, int.parse(conversationId));
      conversations.insert(
          0,
          Conversations(
              id: "${conversationId}_${uuid.v4()}",
              message: messageController.text,
              senderUsername:
                  SharedPreference().getString(AppConstant.username),
              status: "SEND"));

      conversations.refresh();
      messageController.clear();
    }
  }

  Future<void> createConversation() async {
    try {
      final response =
          await ChatRepository.createConversation(userId.toString());

      if (response.conversationId != null) {
        conversationId = response.conversationId.toString();

        // Reinitialize ChatWebSocketService for this conversation
        if (Get.isRegistered<GroupChatWebSocketService>()) {
          Get.delete<GroupChatWebSocketService>();
        }
        chatWebSocket = Get.put(GroupChatWebSocketService(this));

        chatWebSocket.connect(int.parse(conversationId));
        debugPrint(
            "✅ Conversation created and WebSocket connected: $conversationId");
      } else {
        debugPrint("❌ Failed to create conversation — missing conversationId");
      }
    } catch (e) {
      debugPrint("❌ createConversation() error: $e");
    }
  }

  Future<void> getConversationsList() async {
    debugPrint("conversation list api called:${isLastPage},${isLoading}");
    try {
      if (isLastPage || isLoading) {
        return;
      }
      isLoading = true;
      await ChatRepository.getConversationsList(conversationId, page)
          .then((response) {
        if (response.items != null) {
          for (final ele in response.items ?? []) {
            final msg = ele.message;

            if (msg != null && msg.isNotEmpty) {
              try {
                ele.message = EncryptionHelper.decryptText(msg);
              } catch (e) {
                debugPrint("Decryption failed for ${ele.id}: $e");
              }
            }
            if (ele.reactions != null) {
              final decryptedReactions = <String>[];
              for (var ele in ele.reactions) {
                try {
                   debugPrint("before decryption:$ele");
                  decryptedReactions.add(EncryptionHelper.decryptText(ele));
                  debugPrint("after decryption:$ele");
                } catch (e) {
                  debugPrint("Decryption failed for ${ele.id}: $e");
                }
              }
              ele.reactions.value = decryptedReactions;
            }
             if (ele.replayTo != null) {
             
              
              
      final msg = ele.replayTo.message;

            if (msg != null && msg.isNotEmpty) {
              try {
                ele.replayTo.message = EncryptionHelper.decryptText(msg);
              } catch (e) {
                debugPrint("Decryption failed for ${ele.id}: $e");
              }
            }
            }
          
          

            
          }
          if (page == 0) {
            conversations.assignAll(response.items ?? []);
          } else {
            conversations.addAll(response.items ?? []);
          }
          if (response.isLastPage == true) {
            isLastPage = true;
            return;
          } else {
            page++;
          }
        }
      });
    } catch (e) {
      debugPrint("something went wrong:$e");
    } finally {
      isLoading = false;
    }
  }

  void updateMessageStatusToSeen() {
    for (var ele in conversations) {
      ele.status = "SEEN";
    }
    conversations.refresh();
  }

  Future<void> getReactions(String messageId) async {
    if (isReactionLastPage || isReactionLoading) {
      return;
    }
    try {
      if (reactionsPageNumber == 0) {
        reactions.clear();
      }
      isReactionLoading = true;
      await ChatRepository.getReactions(messageId, reactionsPageNumber)
          .then((response) {
        if (reactionsPageNumber == 0) {
        for(var ele in response.items??[]){
            
          ele.reaction=EncryptionHelper.decryptText(ele.reaction);
          reactions.assignAll(response.items??[]);
          reactions.refresh();
          }
        } else {
          reactions.addAll(response.items ?? []);
          reactions.refresh();
        }
        if (response.isLastPage == true) {
          isReactionLastPage = true;
        } else {
          reactionsPageNumber++;
        }
      });
    } catch (e) {
      debugPrint("error:$e");
    } finally {
      isReactionLoading = false;
    }
  }
  void updateMessageStatusById(String messageId, String newStatus) {
  final index = conversations.indexWhere((m) => m.id == messageId);
  if (index != -1) {
    conversations[index].status = newStatus;
    conversations.refresh();
  } else {
    debugPrint("⚠️ Message $messageId not found in list yet");
  }
}

  void updateMessageStatusToDelivered() {
    for (var ele in conversations) {
      if (ele.status == "SEND") {
        ele.status = "DELIVERED";
      }
    }
    conversations.refresh();
  }

  @override
  onClose() {
    chatWebSocket.disconnect();
    
   Get.delete<GroupChatWebSocketService>(force: true);
    Get.delete<GroupChatController>();
    debugPrint("chat WebSocket connection closed");
    //Get.delete<ChatController>();
    super.onClose();
  }

  @override
  void onDetached() {
    // TODO: implement onDetached
  }

  @override
  void onHidden() {
    // TODO: implement onHidden
  }

  @override
  void onInactive() {
    // TODO: implement onInactive
  }

  @override
  void onPaused() {
    // TODO: implement onPaused
  }

  @override
  void onResumed() {
    //chatWebSocket=Get.put(ChatWebSocketService(this));
    // chatWebSocket.connect(int.parse(conversationId));
    //getConversationsList();
    // TODO: implement onResumed
  }
}
