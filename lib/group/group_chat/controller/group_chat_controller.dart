import 'dart:async';
import 'dart:convert';
import 'package:chat_app/chat/chat_websocket/group_chat_web_socket_service.dart';
import 'package:chat_app/group/group_detail/repository/group_detail_repository.dart';
import 'package:chat_app/group/repository/group_chat_repository.dart';
import 'package:chat_app/model/group_message_status.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../chat/helpers/encryption_helper.dart';
import '../../../chat/repository/chat_repository.dart';
import '../../../chat_app.dart';
import '../../../model/conversation_list.dart';
import '../../../model/reaction_list_response.dart';
import '../../../model/user.dart';

class GroupChatController extends GetxController {
  String userId = "";
  RxString name = "".obs;
  RxString groupIcon = "".obs;
  RxString typingUser="".obs;
  String roomId="";
  RxString description = "".obs;
   RxInt chatIndex = (-1).obs;
   final RxBool isFetching = false.obs;
  RxString status = "".obs;
  Rx<User> currentGroupDetails= User().obs;
  int page = 0;
  RxList<UserStatus> sentList=<UserStatus>[].obs;
  RxList<UserStatus> deliveredList=<UserStatus>[].obs;
  RxList<UserStatus> seen=<UserStatus>[].obs;
  final ImagePicker _picker = ImagePicker();
  int reactionsPageNumber = 0;
  RxList<Reaction> reactions = <Reaction>[].obs;
  bool isReactionLastPage = false;
  bool isReactionLoading = false;
  String conversationId = "";
  RxBool isTyping = false.obs;
  RxString messageId = "".obs;
  final RxBool isLoading = false.obs;
  Timer? typingTimer;
  bool isLastPage = false;
  final ScrollController scrollController = ScrollController();
  final Uuid uuid = Uuid();
  var selectedMessageIndex = (-1).obs;
   final ScrollController textFieldScrollController = ScrollController();
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
  GroupChatWebSocketService chatWebSocket =Get.isRegistered<GroupChatWebSocketService>()
      ? Get.find<GroupChatWebSocketService>()
      : Get.put(GroupChatWebSocketService());
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
    groupIcon.value =Get.arguments['icon'].toString();
    //  if(conversationId.isEmpty){
    //   createConversation();
    //   }else{
     

    if (conversationId.isNotEmpty) {
      getCurrentGroupDetails();
    getConversationsList();
      
      chatWebSocket!.connect(int.parse(conversationId));

      // //  chatWebSocket = Get.put(ChatWebSocketService(this));

      // }
    
    }
  }

  void onTextChanged(String value) {
    if (value.isNotEmpty) {
      chatWebSocket!.onChanged(true);
      typingTimer?.cancel();
      typingTimer = Timer(const Duration(seconds: 2), () {
        chatWebSocket!.onChanged(false);
      });
    }
  }

  Future<void> pickMediaFromGallery({required bool isCamera}) async {
  final List<XFile> files = await _picker.pickMultipleMedia(
    limit: 5,);
if (files.isEmpty) return;
final selectedFiles = files.take(5).toList();

final List<dynamic> mediaPaths =
    selectedFiles.map((x) => x.path).toList();
 final messageId = "${conversationId}_${uuid.v4()}";

//  final payload = {
//         "type": "msg",
//         "replyTo": replyTo,
//         "receiver": receiver,
//         "receiverUsername": receiverUsername,
//         "messageId": messageId,
//         "msg": message,
//         "urls": urls
//       };


//  chatWebSocket!.sendMessageWithReply(
//      replyTo: replyTo?.id??"",
//      receiver:replyTo?.senderUUID??"",
//      receiverUsername: replyTo?.senderUsername??"",
//      reply:replyTo?.message != null ?replyTo!.message??"":"",
//      urls:replyTo?.medias,
//     //   replyTo?.medias != null
//     // ? (replyTo!.medias ?? <dynamic>[])
//     // : (replyTo?.message != null ? [replyTo!.message!] : <dynamic>[]),
//       messageId:messageId, 
//      message:  encryptedText,
//     );

 final Map<String, dynamic> requestData={
  "conversationId":conversationId,
  "messageId":messageId,
  "replyTo":replyMessage.value!=null?replyMessage.value?.id??"":null,
  "receiver":replyMessage.value!=null?replyMessage.value?.senderUUID??"":null,
  "receiverUsername":replyMessage.value!=null?replyMessage.value?.senderUsername??"":null,
  "urls":replyMessage.value!=null &&replyMessage.value?.medias!=null?replyMessage.value?.medias:null

  //"reply":
 };
 debugPrint("media paths:${mediaPaths},${requestData["replyTo"]}");
 conversations.insert(
    0,
    Conversations(
      id: messageId,
      senderUUID: chatConfigController.config.prefs.getInt(chatConfigController.config.id).toString(),
      medias: mediaPaths,
      senderUsername: chatConfigController.config.prefs.getString(chatConfigController.config.username),
     replayTo:replyMessage.value,
      status: "SEND",
        uploadProgress: 0.0.obs, // Initialize upload progress
    isUploading: true.obs, 
    ),
  );
    conversations.refresh();

//   await Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (_) => MediaPreviewScreen(
//       files: selectedFiles,
//       onSend: () {
//         chatController.sendImages(selectedFiles);
//       },
//     ),
//   ),
// );
replyMessage.value=null;

  await sendAttachmentWithProgress(
    requestData: requestData,
    files: selectedFiles,
    messageId: messageId,
  );

   
   
}

Future<void> sendAttachmentWithProgress({
  required Map<String, dynamic> requestData,
  required List<XFile> files,
  required String messageId,
}) async {
  try {
    final response = await ChatRepository.sendMediaWithProgress(
      files,
      requestData,
      onProgress: (progress) {
        // ✅ Update upload progress in real-time
        final index = conversations.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          conversations[index].uploadProgress?.value = progress;
          conversations.refresh();
          debugPrint('Message $messageId upload: ${(progress * 100).toInt()}%');
        }
      },
    );

    // ✅ Upload successful - extract ONLY URLs from response
    if (response.files != null && response.files!.isNotEmpty) {
      final index = conversations.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        // Extract only the URL strings from MediaFile objects
        final List<String> urls = response.files!
            .where((file) => file.url != null && file.success == true)
            .map((file) => file.url!)
            .toList();
        
        debugPrint('✅ Upload complete. URLs: $urls');
        
        // Replace local paths with network URLs
        conversations[index].medias = urls; // List<String> of URLs
        conversations[index].isUploading?.value = false;
        conversations[index].uploadProgress = null;
        conversations[index].status = "DELIVERED";
        // conversations[index].id = response?.messageId;
        conversations.refresh();
      }
       debugPrint("conversation after upload:${jsonEncode(conversations.first)}");
    }
  } catch (e) {
    debugPrint("❌ Upload error: $e");
    
    // ✅ Mark upload as failed
    final index = conversations.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      conversations[index].isUploading?.value = false;
      conversations[index].uploadProgress = null;
      conversations[index].status = "FAILED";
      conversations.refresh();
    }
  }
}

void openCameraPicker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (_) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title:  Text("Take Photo",style: TextStyle(
                    color: MediaQuery.platformBrightnessOf(context) == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),),
              onTap: () {
                //Navigator.pop(context);
                pickCameraPhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title:  Text("Record Video",style: TextStyle(
                    color: MediaQuery.platformBrightnessOf(context) == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),),
              onTap: () {
                //Navigator.pop(context);
                pickCameraVideo();
              },
            ),
          ],
        ),
      );
    },
  );
}
Future<void> pickCameraPhoto() async {
  final XFile? file = await _picker.pickImage(
    source: ImageSource.camera,
    imageQuality: 100,
  );

  if (file == null) return;

  await _handleCameraMedia(file);
}
Future<void> pickCameraVideo() async {
  final XFile? file = await _picker.pickVideo(
    source: ImageSource.camera,
    maxDuration: const Duration(minutes: 2),
  );

  if (file == null) return;

  await _handleCameraMedia(file);
}

Future<void> _handleCameraMedia(XFile file) async {
  final List<XFile> selectedFiles = [file];
  final List<dynamic> mediaPaths = [file.path];

  final messageId = "${conversationId}_${uuid.v4()}";

  final Map<String, dynamic> requestData = {
    "conversationId": conversationId,
    "messageId": messageId,
    "replyTo": replyMessage.value?.id,
    "receiver": replyMessage.value?.senderUUID,
    "receiverUsername": replyMessage.value?.senderUsername,
    "urls": replyMessage.value?.medias,
  };

  conversations.insert(
    0,
    Conversations(
      id: messageId,
      senderUUID: chatConfigController.config.prefs
          .getInt(chatConfigController.config.id)
          .toString(),
      senderUsername: chatConfigController.config.prefs
          .getString(chatConfigController.config.username),
      medias: mediaPaths,
      replayTo: replyMessage.value,
      status: "SEND",
      uploadProgress: 0.0.obs,
      isUploading: true.obs,
    ),
  );

  conversations.refresh();
  replyMessage.value = null;

  await sendAttachmentWithProgress(
    requestData: requestData,
    files: selectedFiles,
    messageId: messageId,
  );
}


  Future<void> pickMediaFromCamera({required bool isCamera}) async {
  final XFile? file = await _picker.pickImage(
   source: ImageSource.camera);
if (file==null) return;
//final selectedFiles = files.take(5).toList();
//   await Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (_) => MediaPreviewScreen(
//       files: selectedFiles,
//       onSend: () {
//         chatController.sendImages(selectedFiles);
//       },
//     ),
//   ),
// );

  // await sendAttachment(
  //   filePath: file.path,
  //   type: "IMAGE",
  //   replyToMessageId: replyMessage.value!=null?replyMessage.value?.id??"":null,
  //   reply: replyMessage.value!=null?replyMessage.value?.url!=null?replyMessage.value?.url??"":replyMessage.value?.message??"":null
  // );
   
  // replyMessage.value=null;
}

  Future<void> getCurrentGroupDetails()async{
    await GroupDetailRepository.groupDetails(chatConfigController.config.prefs.getInt(chatConfigController.config.conversationId)??0).then((response){
currentGroupDetails.value = response.currentUser??User();
name.value = response.groupName??"";
description.value=response.description??'';
groupIcon.value = response.icon??"";


    });
  }

void sendMessageWithReply() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    final replyTo = replyMessage.value;
    debugPrint("what is in reply2:${jsonEncode(replyTo)}");
    final encryptedText = EncryptionHelper.encryptText(text);
    final String messageId ="${conversationId}_${uuid.v4()}";
    conversations.insert(
        0,
        Conversations(
          id: messageId,
          message: text,
           senderUUID: chatConfigController.config.prefs.getInt(chatConfigController.config.id).toString(),
          senderUsername: chatConfigController.config.prefs.getString(chatConfigController.config.username),
          replayTo: replyTo, // <-- custom field
        ));
        conversations.refresh();
    // Add your API/WebSocket call here with replyId
    chatWebSocket!.sendMessageWithReply(
     replyTo: replyTo?.id??"",
     receiver:replyTo?.senderUUID??"",
     receiverUsername: replyTo?.senderUsername??"",
     reply:replyTo?.message != null ?replyTo!.message??"":"",
     urls:replyTo?.medias,
    //   replyTo?.medias != null
    // ? (replyTo!.medias ?? <dynamic>[])
    // : (replyTo?.message != null ? [replyTo!.message!] : <dynamic>[]),
      messageId:messageId, 
     message:  encryptedText,
    );

    // Update UI
    

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
  debugPrint("sender user name:${chatConfigController.config.prefs.getString(chatConfigController.config.username)}");
conversations.insert(
    0,
    Conversations(
      id: messageId,
      message: text,
      senderUUID: chatConfigController.config.prefs.getInt(chatConfigController.config.id).toString(),
      senderUsername: chatConfigController.config.prefs.getString(chatConfigController.config.username),
      status: "SEND",
    ),
  );
    conversations.refresh();
  
  // ✅ Step 3: Send only if message text is not empty
  

  // Encrypt text
  final encryptedText = EncryptionHelper.encryptText(text);
  

  // Send message over WebSocket
  chatWebSocket!.sendMessage(messageId, encryptedText, int.parse(conversationId));

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
      chatWebSocket!.sendMessage("${conversationId}_${uuid.v4()}",
          encryptedText, int.parse(conversationId));
      conversations.insert(
          0,
          Conversations(
              id: "${conversationId}_${uuid.v4()}",
              message: messageController.text,
               senderUUID: chatConfigController.config.prefs.getInt(chatConfigController.config.id).toString(),
              senderUsername:
                  chatConfigController.config.prefs.getString(chatConfigController.config.username),
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

       

        chatWebSocket!.connect(int.parse(conversationId));
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
      if (isLastPage || isLoading.value) {
        return;
      }
   page ==0 ?   isLoading.value= true:isFetching.value=false;
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
            debugPrint("group conversation list api called:${conversations.length}");
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
      isLoading.value = false;
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
  Future<void> disposeChat() async {
   chatWebSocket!.disconnect();
}

  @override
  onClose() {
    
    
 
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
