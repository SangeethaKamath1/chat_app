import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chat_app/chat/chat_websocket/chat_web_socket_service.dart';
import 'package:chat_app/constants/app_constant.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../chat_app.dart';
import '../../model/conversation_list.dart';
import '../../model/reaction_list_response.dart';
import '../helpers/encryption_helper.dart';
import '../repository/chat_repository.dart';

class ChatController extends GetxController {
  // ✅ CHAT IDENTIFIERS
  String userId = "";
  String name = "";
  String icon = "";
  

  String conversationId = "";

  // ✅ UI + STATE
  final ImagePicker _picker = ImagePicker();
  final ScrollController scrollController = ScrollController();
  final ScrollController textFieldScrollController = ScrollController();

  final TextEditingController messageController = TextEditingController();

  final RxInt chatIndex = (-1).obs;
  final RxString status = "".obs;
  final RxBool isFetching = false.obs;
  final RxBool isTyping = false.obs;
  final RxString messageId = "".obs;

  final RxBool isLoading = false.obs; // conversation list loading (page==0)
  final RxBool isCreateConversationLoading = false.obs;

  Timer? typingTimer;

  int page = 0;
  bool isLastPage = false;

  int reactionsPageNumber = 0;
  RxList<Reaction> reactions = <Reaction>[].obs;
  bool isReactionLastPage = false;
  bool isReactionLoading = false;

  final Uuid uuid = const Uuid();

  // ✅ Messages list
  RxList<Conversations> conversations = <Conversations>[].obs;

  // ✅ Reply support
  var replyMessage = Rxn<Conversations>();

  void setReply(Conversations? message) => replyMessage.value = message;
  void clearReply() => replyMessage.value = null;

  // ✅ Emoji picker
  var showEmojiPicker = false.obs;

  // ✅ Websocket
  ChatWebSocketService  chatWebSocket = Get.find<ChatWebSocketService>();

  // ✅ Overlay reaction picker
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

    final args = Get.arguments as Map<String, dynamic>?;

    // ✅ Safe reads
    final argUserId = args?['id']?.toString();
    final argName = args?['name']?.toString();
    final argIcon = args?['icon']?.toString();
    final argConversationId = args?['conversationId']?.toString();

    if (argUserId != null && argUserId.isNotEmpty) userId = argUserId;
    if (argName != null && argName.isNotEmpty) name = argName;
    if (argIcon != null) icon = argIcon;
    if (argConversationId != null && argConversationId.isNotEmpty) {
      conversationId = argConversationId;
    }

    // ✅ Resolve websocket service safely
    

    // ✅ If conversationId already known, connect + load
    if (conversationId.isNotEmpty) {
      chatWebSocket.connect(int.parse(conversationId));
      getConversationsList();
      return;
    }

    // ✅ If conversationId not known, only createConversation if we have userId
    if (userId.isNotEmpty) {
      createConversation();
    } else {
      debugPrint(
        "⚠️ ChatController.onInit: No args and userId empty. "
        "Waiting for caller to set userId then call createConversation().",
      );
    }
  }

  // ✅ Typing
  void onTextChanged(String value) {
    if (value.isNotEmpty) {
      if (chatWebSocket.channel != null) {
        chatWebSocket.onChanged(true);
      }
      typingTimer?.cancel();
      typingTimer = Timer(const Duration(seconds: 2), () {
        if (chatWebSocket.channel != null) {
          chatWebSocket.onChanged(false);
        }
      });
    }
  }

  // ✅ Create conversation
  Future<void> createConversation() async {
    try {
      isCreateConversationLoading.value = true;

      final response = await ChatRepository.createConversation(userId.toString());

      if (response.conversationId != null) {
        conversationId = response.conversationId.toString();
        chatConfigController.config.prefs.setInt(
          chatConfigController.config.conversationId,
          int.parse(conversationId),
        );

        chatWebSocket.connect(int.parse(conversationId));
        debugPrint("✅ Conversation created and WebSocket connected: $conversationId");

        getConversationsList();
      } else {
        debugPrint("❌ Failed to create conversation — missing conversationId");
      }
    } catch (e) {
      debugPrint("❌ createConversation() error: $e");
    } finally {
      isCreateConversationLoading.value = false;
    }
  }

  // ✅ Send message (with ensure conversationId)
  Future<void> sendMessage() async {
    if (conversationId.isEmpty) {
      await createConversation();
    }

    if (conversationId.isEmpty) {
      debugPrint("❌ Conversation ID is still empty — cannot send message");
      return;
    }

    final text = messageController.text.trim();
    if (text.isEmpty) return;

    final String msgId = "${conversationId}_${uuid.v4()}";

    conversations.insert(
      0,
      Conversations(
        id: msgId,
        senderUUID: chatConfigController.config.prefs
            .getInt(chatConfigController.config.id)
            .toString(),
        senderUsername: chatConfigController.config.prefs
            .getString(chatConfigController.config.username),
        message: text,
        status: "SEND",
      ),
    );
    conversations.refresh();

    final encryptedText = EncryptionHelper.encryptText(text);
    chatWebSocket.sendMessage(msgId, encryptedText, int.parse(conversationId));

    messageController.clear();
  }

  // ✅ Send message with reply
  void sendMessageWithReply() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    final replyTo = replyMessage.value;

    final encryptedText = EncryptionHelper.encryptText(text);
    final String msgId = "${conversationId}_${uuid.v4()}";

    conversations.insert(
      0,
      Conversations(
        id: msgId,
        message: text,
        senderUUID: chatConfigController.config.prefs
            .getInt(chatConfigController.config.id)
            .toString(),
        senderUsername: chatConfigController.config.prefs
            .getString(chatConfigController.config.username),
        replayTo: replyTo,
        status: "SEND",
      ),
    );
    conversations.refresh();

    chatWebSocket.sendMessageWithReply(
      replyTo: replyTo?.id ?? "",
      receiver: replyTo?.senderUUID ?? "",
      receiverUsername: replyTo?.senderUsername ?? "",
      reply: replyTo?.message ?? "",
      urls: replyTo?.medias,
      messageId: msgId,
      message: encryptedText,
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    messageController.clear();
    clearReply();
  }

  // ✅ Attachments: pick from gallery
  Future<void> pickMediaFromGallery({required bool isCamera}) async {
    final List<XFile> files = await _picker.pickMultipleMedia(limit: 5);
    if (files.isEmpty) return;

    final selectedFiles = files.take(5).toList();
    final List<dynamic> mediaPaths = selectedFiles.map((x) => x.path).toList();

    final String msgId = "${conversationId}_${uuid.v4()}";

    final Map<String, dynamic> requestData = {
      "conversationId": conversationId,
      "messageId": msgId,
      "replyTo": replyMessage.value != null ? (replyMessage.value?.id ?? "") : null,
      "receiver": replyMessage.value != null ? (replyMessage.value?.senderUUID ?? "") : null,
      "receiverUsername": replyMessage.value != null ? (replyMessage.value?.senderUsername ?? "") : null,
      "urls": replyMessage.value != null ? replyMessage.value?.medias : null,
    };

    conversations.insert(
      0,
      Conversations(
        id: msgId,
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
      messageId: msgId,
    );
  }

  // ✅ Camera helpers (same as you had)
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
                title: Text(
                  "Take Photo",
                  style: TextStyle(
                    color: MediaQuery.platformBrightnessOf(context) == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                onTap: () {
                  pickCameraPhoto();
                  Future.delayed(const Duration(seconds: 2), () {
                    Navigator.pop(Get.context!);
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: Text(
                  "Record Video",
                  style: TextStyle(
                    color: MediaQuery.platformBrightnessOf(context) == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                onTap: () {
                  pickCameraVideo();
                  Future.delayed(const Duration(seconds: 2), () {
                    Navigator.pop(Get.context!);
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> pickCameraPhoto() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 100);
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

    final String msgId = "${conversationId}_${uuid.v4()}";

    final Map<String, dynamic> requestData = {
      "conversationId": conversationId,
      "messageId": msgId,
      "replyTo": replyMessage.value?.id,
      "receiver": replyMessage.value?.senderUUID,
      "receiverUsername": replyMessage.value?.senderUsername,
      "urls": replyMessage.value?.medias,
    };

    conversations.insert(
      0,
      Conversations(
        id: msgId,
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
      messageId: msgId,
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
          final index = conversations.indexWhere((m) => m.id == messageId);
          if (index != -1) {
            conversations[index].uploadProgress?.value = progress;
            conversations.refresh();
          }
        },
      );

      if (response.files != null && response.files!.isNotEmpty) {
        final index = conversations.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          final List<String> urls = response.files!
              .where((file) => file.url != null && file.success == true)
              .map((file) => file.url!)
              .toList();

          conversations[index].medias = urls;
          conversations[index].isUploading?.value = false;
          conversations[index].uploadProgress = null;
          conversations[index].status = "DELIVERED";
          conversations.refresh();
        }
      }
    } catch (e) {
      final index = conversations.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        conversations[index].isUploading?.value = false;
        conversations[index].uploadProgress = null;
        conversations[index].status = "FAILED";
        conversations.refresh();
      }
    }
  }

  // ✅ Conversation list API (kept same)
  Future<void> getConversationsList() async {
    debugPrint("conversation list api called: isLastPage=$isLastPage isLoading=${isLoading.value}");

    try {
      if (isLastPage || isLoading.value) return;

      page == 0 ? isLoading.value = true : isFetching.value = true;

      final response = await ChatRepository.getConversationsList(conversationId, page);

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
            for (final r in ele.reactions) {
              try {
                decryptedReactions.add(EncryptionHelper.decryptText(r));
              } catch (e) {
                debugPrint("Reaction decrypt failed for ${ele.id}: $e");
              }
            }
            ele.reactions.value = decryptedReactions;
          }

          if (ele.replayTo != null) {
            final replyMsg = ele.replayTo.message;
            if (replyMsg != null && replyMsg.isNotEmpty) {
              try {
                ele.replayTo.message = EncryptionHelper.decryptText(replyMsg);
              } catch (e) {
                debugPrint("Reply decrypt failed for ${ele.id}: $e");
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
        } else {
          page++;
        }
      }
    } catch (e) {
      debugPrint("getConversationsList error: $e");
    } finally {
      isLoading.value = false;
      isFetching.value = false;
    }
  }

  // ✅ Status updates
  void updateMessageStatusToSeen() {
    for (final ele in conversations) {
      ele.status = "SEEN";
    }
    conversations.refresh();
  }

  void updateMessageStatusToDelivered() {
    for (final ele in conversations) {
      if (ele.status == "SEND") {
        ele.status = "DELIVERED";
      }
    }
    conversations.refresh();
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

  // ✅ Reactions API
  Future<void> getReactions(String messageId) async {
    if (isReactionLastPage || isReactionLoading) return;

    try {
      if (reactionsPageNumber == 0) reactions.clear();

      isReactionLoading = true;

      final response = await ChatRepository.getReactions(messageId, reactionsPageNumber);

      if (reactionsPageNumber == 0) {
        for (final ele in response.items ?? []) {
          ele.reaction = EncryptionHelper.decryptText(ele.reaction);
        }
        reactions.assignAll(response.items ?? []);
        reactions.refresh();
      } else {
        reactions.addAll(response.items ?? []);
        reactions.refresh();
      }

      if (response.isLastPage == true) {
        isReactionLastPage = true;
      } else {
        reactionsPageNumber++;
      }
    } catch (e) {
      debugPrint("getReactions error: $e");
    } finally {
      isReactionLoading = false;
    }
  }

  void updateReaction(messageId, reaction, oldReaction) {
    for (final ele in conversations) {
      if (ele.id.toString() == messageId && oldReaction != null) {
        ele.reactions?.removeWhere(
          (x) => x == EncryptionHelper.decryptText(oldReaction),
        );
        ele.reactions?.add(EncryptionHelper.decryptText(reaction));
      } else if (ele.id.toString() == messageId && oldReaction == null) {
        ele.reactions?.add(EncryptionHelper.decryptText(reaction));
      }
    }
    conversations.refresh();
  }

  // ✅ Cleanup
  // Future<void> disposeChat() async {
  //   chatWebSocket?.disconnect();
  // }

  @override
  void onClose() {
    // Don't force-disconnect here unless you really want
    // chatWebSocket?.disconnect();
    debugPrint("chat controller onClose()");
    super.onClose();
  }
}
