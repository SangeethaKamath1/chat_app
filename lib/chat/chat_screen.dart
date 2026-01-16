import 'dart:convert';
import 'dart:io';

import 'package:amu_alumni/utils/reusables/sized_box.dart';
import 'package:chat_app/chat/chat_websocket/chat_web_socket_service.dart';
import 'package:chat_app/chat_app.dart';
import 'package:chat_app/constants/app_constant.dart';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../audio_call/controller/call_session_controller.dart';
import '../audio_call/screens/call_screen.dart';

import '../audio_call/service/webrtc_service.dart';
import '../routes/chat_app_routes.dart';
import '../src/theme/controller/chat_theme_controller.dart';
import 'components/attachment_bottom_sheet.dart';
import 'components/chat_message_bubble.dart';
import 'components/chat_shimmer.dart';
import 'controller/chat_controller.dart';
import 'helpers/encryption_helper.dart';

class ChatScreen extends StatelessWidget {
  ChatScreen({super.key});

@override
  Widget build(BuildContext context) {
    final ChatController chatController = Get.find<ChatController>();

   

    return WillPopScope(
      onWillPop: () async {
        Get.back();
        chatController.disposeChat();
        chatController.removeReactionOverlay();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: InkWell(
            onTap: () {
              Get.back();
             chatController.disposeChat();
              chatController.removeReactionOverlay();
            },
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: (chatController.icon).isNotEmpty
                      ? Image.network(
                          chatController.icon,
                          fit: BoxFit.cover,
                          width: 36,
                          height: 36,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.account_circle,
                              size: 36,
                              color: Colors.grey,
                            );
                          },
                        )
                      : const Icon(
                          Icons.account_circle,
                          size: 36,
                          color: Colors.grey,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Text(chatController.name,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700))
            ],
          ),
          backgroundColor: chatConfigController.config.primaryColor,
          actions: [
            InkWell(
              onTap: () async {
                try {
                  // 1) Ask microphone permission
                  final micStatus = await Permission.microphone.request();

                  if (micStatus.isDenied) {
                    Get.snackbar(
                        "Permission Required", "Allow microphone access");
                    return;
                  }

                  if (micStatus.isPermanentlyDenied) {
                    await Get.dialog(
                      AlertDialog(
                        title: const Text("Microphone Permission"),
                        content: const Text(
                          "Microphone permission is permanently denied. Please enable it from Settings to make calls.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () async {
                              Get.back();
                              await openAppSettings();
                            },
                            child: const Text("Open Settings"),
                          ),
                        ],
                      ),
                    );
                    return;
                  }


                  chatController.chatWebSocket.roomId =
                      "${chatController.conversationId}_${chatController.uuid.v4()}";

                  debugPrint("📞 Starting call with room: ${chatController.chatWebSocket.roomId}");

                  chatController.chatWebSocket.setRoom(chatController.chatWebSocket.roomId);

                  final conversationIdInt =
                      int.tryParse(chatController.conversationId) ?? 0;
                  if (conversationIdInt != 0) {
                    chatController.chatWebSocket.connect(conversationIdInt);
                  } else {
                    debugPrint(
                        "⚠️ conversationId invalid, signaling connect skipped");
                  }
                //  chatController.disposeChat();
                  final session = Get.isRegistered<CallSessionController>()
                      ? Get.find<CallSessionController>()
                      : Get.put(CallSessionController(), permanent: true);
                  // session.reset();
                  session.isVideo.value = false;
                  // 5) Navigate to call screen as CALLER
                  Get.toNamed(
                    ChatAppRoutes.callScreen,
                    arguments: {
                      'isCaller': true,
                      'callId': chatController.chatWebSocket.roomId,
                      'fromNotification': false,
                      'callerName': chatController.name,
                      'callerId': chatController.userId,
                      'isVideo': false
                    },
                  )?.then((value) {
                    chatController.chatWebSocket!.connect(
                        int.tryParse(chatController.conversationId) ?? 0);
                  });

                  // ✅ Do NOT call _initializeCall() here (kept same)
                } catch (e) {
                  debugPrint("Error starting call: $e");
                  Get.snackbar("Call Failed", "Could not start call");
                }
              },
              child: const Icon(Icons.call),
            ),
            sw10,
            InkWell(
              onTap: () async {
                try {
                  // 1) Ask microphone permission
                  final micStatus = await Permission.microphone.request();

                  if (micStatus.isDenied) {
                    Get.snackbar(
                        "Permission Required", "Allow microphone access");
                    return;
                  }

                  if (micStatus.isPermanentlyDenied) {
                    await Get.dialog(
                      AlertDialog(
                        title: const Text("Microphone Permission"),
                        content: const Text(
                          "Microphone permission is permanently denied. Please enable it from Settings to make calls.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () async {
                              Get.back();
                              await openAppSettings();
                            },
                            child: const Text("Open Settings"),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  // ✅ 2) Ask camera permission (for VIDEO CALL)
                  final camStatus = await Permission.camera.request();

                  if (camStatus.isDenied) {
                    Get.snackbar("Permission Required",
                        "Allow camera access for video calls");
                    return;
                  }

                  if (camStatus.isPermanentlyDenied) {
                    await Get.dialog(
                      AlertDialog(
                        title: const Text("Camera Permission"),
                        content: const Text(
                          "Camera permission is permanently denied. Please enable it from Settings to make video calls.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () async {
                              Get.back();
                              await openAppSettings();
                            },
                            child: const Text("Open Settings"),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                 

                  // 3) Generate room ID (same as your existing logic)
                  chatController.chatWebSocket.roomId =
                      "${chatController.conversationId}_${chatController.uuid.v4()}";

                  debugPrint("📞 Starting call with room: ${chatController.chatWebSocket.roomId}");

                  chatController.chatWebSocket.setRoom(chatController.chatWebSocket.roomId);

                  final conversationIdInt =
                      int.tryParse(chatController.conversationId) ?? 0;
                  if (conversationIdInt != 0) {
                    chatController.chatWebSocket.connect(conversationIdInt);
                  } else {
                    debugPrint(
                        "⚠️ conversationId invalid, signaling connect skipped");
                  }

                 // chatController.disposeChat();

                  final session = Get.isRegistered<CallSessionController>()
                      ? Get.find<CallSessionController>()
                      : Get.put(CallSessionController(), permanent: true);

                  // session.reset();
                  session.isVideo.value = true;

                  // 5) Navigate to call screen as CALLER
                  Get.toNamed(
                    ChatAppRoutes.callScreen,
                    arguments: {
                      'isCaller': true,
                      'callId': chatController.chatWebSocket.roomId,
                      'fromNotification': false,
                      'callerName': chatController.name,
                      'callerId': chatController.userId,
                      'isVideo': true,
                    },
                  )?.then((value) {
                    chatController.chatWebSocket!.connect(
                        int.tryParse(chatController.conversationId) ?? 0);
                  });
                } catch (e) {
                  debugPrint("Error starting call: $e");
                  Get.snackbar("Call Failed", "Could not start call");
                }
              },
              child: const Icon(Icons.video_call),
            ),
            const SizedBox(width: 16),
            Obx(() {
              return chatController.messageId.isNotEmpty &&
                      chatConfigController.config.prefs
                              .getInt(chatConfigController.config.id)
                              .toString() ==
                          chatController
                              .conversations[chatController.chatIndex.value]
                              .senderUUID
                  ? IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        chatController.removeReactionOverlay();
                        debugPrint(
                            "deleteindex:${chatController.chatIndex.value}");
                        chatController.chatWebSocket!.deleteMessage(
                            chatController.messageId.value,
                            chatController.chatIndex.value);
                      },
                    )
                  : const SizedBox.shrink();
            }),
          ],
        ),

        // MAIN BODY
        body: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.pixels ==
                notification.metrics.maxScrollExtent) {
              if (!chatController.isLoading.value &&
                  !chatController.isFetching.value) {
                chatController.getConversationsList();
              }
              return true;
            }
            return false;
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🧱 Message List
              Expanded(
                child: Obx(() {
                  if (chatController.isLoading.value ||
                      chatController.isCreateConversationLoading.value) {
                    return const ChatShimmer(); // 👈 show shimmer here
                  }

                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      // clear highlight when tapping outside
                      chatController.chatIndex.value = -1;
                      debugPrint("chat controller -1 inside global tap");
                      chatController.removeReactionOverlay();
                      chatController.messageId.value = "";
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 0.0),
                      child: ListView.builder(
                        reverse: true,
                        // key: ValueKey(DateTime.now().millisecond),
                        controller: chatController.scrollController,
                        clipBehavior: Clip.none,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: chatController.conversations.length,
                        itemBuilder: (context, index) {
                          final message = chatController.conversations[index];
                          final isMine = message.senderUsername ==
                              chatConfigController.config.prefs.getString(
                                  chatConfigController.config.username);

                          return ChatMessageBubble(
                            message: message,
                            index: index,
                            isMine: isMine,
                            chatController: chatController,
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
              Obx(() {
                return chatController.isTyping.value
                    ? Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "typing...",
                              style: TextStyle(
                                  color: MediaQuery.platformBrightnessOf(
                                              context) ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black),
                              textAlign: TextAlign.left,
                            )),
                      )
                    : const SizedBox.shrink();
              }),
              // 🧭 Reply Bar + Input Field
              Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: MediaQuery.platformBrightnessOf(context) ==
                          Brightness.dark
                      ? Colors.black
                      : Colors.white,
                  child: _buildMessageInputArea(context, chatController)),

              // 😀 Emoji Picker
              Obx(() {
                return chatController.showEmojiPicker.value
                    ? SizedBox(
                        height: 250,
                        child: EmojiPicker(
                          config: Config(
                            searchViewConfig: SearchViewConfig(
                              customSearchView: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                            bottomActionBarConfig: BottomActionBarConfig(
                              showBackspaceButton: false, // ❌ hide backspace
                              showSearchViewButton:
                                  false, // ❌ hide search button
                            ),
                          ),
                          onEmojiSelected: (category, emoji) {
                            if (chatController.messageId.value.isNotEmpty) {
                              final conversation = chatController.conversations[
                                  chatController.chatIndex.value];

                              if (conversation.isReacted == false) {
                                final encryptedText =
                                    EncryptionHelper.encryptText(emoji.emoji);
                                chatController.chatWebSocket!.sendReaction(
                                  chatController.messageId.value,
                                  encryptedText,
                                  int.parse(chatController.conversationId),
                                );
                                conversation.reactions?.add(emoji.emoji);
                                conversation.isReacted = true;
                                conversation.reaction = emoji.emoji;
                              } else {
                                conversation.reactions?.remove(
                                    EncryptionHelper.decryptText(
                                        conversation.reaction ?? ""));
                                conversation.reactions?.add(emoji.emoji);
                                conversation.reaction = emoji.emoji;
                                conversation.isReacted = true;
                                final encryptedText =
                                    EncryptionHelper.encryptText(emoji.emoji);
                                chatController.chatWebSocket!.sendReaction(
                                  chatController.messageId.value,
                                  encryptedText,
                                  int.parse(chatController.conversationId),
                                );
                              }

                              chatController.conversations.refresh();
                              chatController.messageController.clear();
                              chatController.chatIndex.value = -1;
                              debugPrint(
                                  "chat controller -1 inside emoji picker");
                              chatController.messageId.value = "";
                              chatController.showEmojiPicker.value = false;
                            } else {
                              chatController.messageController.text +=
                                  emoji.emoji;
                              chatController.messageController.selection =
                                  TextSelection.fromPosition(
                                TextPosition(
                                    offset: chatController
                                        .messageController.text.length),
                              );
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                chatController.textFieldScrollController
                                    .animateTo(
                                  chatController.textFieldScrollController
                                      .position.maxScrollExtent,
                                  duration: const Duration(milliseconds: 100),
                                  curve: Curves.easeOut,
                                );
                              });
                            }
                          },
                        ),
                      )
                    : const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }

  // 🧱 REPLY BAR + INPUT
  Widget _buildMessageInputArea(
      BuildContext context, ChatController chatController) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply preview
          Obx(() {
            final replyMsg = chatController.replyMessage.value;
            if (replyMsg == null) return const SizedBox.shrink();
            return _buildReplyPreview(chatController, replyMsg);
          }),
          // Message Input
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => AttachmentBottomSheet(
                      chatController: chatController,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.add_reaction, color: Colors.orange),
                onPressed: () {
                  chatController.showEmojiPicker.value =
                      !chatController.showEmojiPicker.value;
                  (context as Element).markNeedsBuild();
                },
              ),
              Expanded(
                child: TextField(
                  controller: chatController.messageController,
                  scrollController: chatController.textFieldScrollController,
                  cursorColor: chatConfigController.config.primaryColor,
                  style: TextStyle(
                    color: MediaQuery.platformBrightnessOf(context) ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black, // <-- message text color
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: TextStyle(
                      color: MediaQuery.platformBrightnessOf(context) ==
                              Brightness.dark
                          ? Colors.white.withOpacity(0.6)
                          : Colors.black, // <-- hint color
                    ),

                    filled: true,
                    fillColor: MediaQuery.platformBrightnessOf(context) ==
                            Brightness.dark
                        ? Colors.white.withOpacity(0.15)
                        : Colors.transparent, // <-- background color

                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(12),
                        ),
                        borderSide: BorderSide(
                          color: MediaQuery.platformBrightnessOf(context) ==
                                  Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        )),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: chatConfigController
                            .config.primaryColor, // <-- focused border
                        width: 1.5,
                      ),
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  onChanged: chatController.onTextChanged,
                ),
              ),
              IconButton(
                icon: Icon(Icons.send,
                    color: chatConfigController.config.primaryColor),
                onPressed: () => _handleSend(chatController),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: 40,
      height: 40,
      color: Colors.grey[400],
      child: const Icon(Icons.image, size: 20),
    );
  }

  // 🧱 Reply Preview Bar
  Widget _buildReplyPreview(ChatController chatController, replyMsg) {
    final bool hasText =
        replyMsg.message != null && replyMsg.message!.trim().isNotEmpty;

    final List<dynamic> medias = replyMsg.medias ?? [];
    final bool hasSingleMedia = medias.length == 1;
    final bool hasMultipleMedia = medias.length > 1;

    bool _isVideo(String path) {
      final lower = path.toLowerCase();
      return lower.endsWith('.mp4') ||
          lower.endsWith('.mov') ||
          lower.endsWith('.avi') ||
          lower.endsWith('.mkv') ||
          lower.endsWith('.webm');
    }

    Widget _fallback() {
      return Container(
        width: 40,
        height: 40,
        color: Colors.grey[400],
        child: const Icon(Icons.image, size: 20),
      );
    }

    Widget _buildMediaThumb(String path) {
      final bool isVideo = _isVideo(path);

      Widget imageWidget;
      if (path.startsWith('http')) {
        imageWidget = Image.network(
          path,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        );
      } else {
        imageWidget = Image.file(
          File(path),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        );
      }

      if (!isVideo) return imageWidget;

      /// 🎥 Video thumbnail with play icon
      return Stack(
        alignment: Alignment.center,
        children: [
          imageWidget,
          Container(
            width: 40,
            height: 40,
            color: Colors.black26,
          ),
          const Icon(
            Icons.play_circle_fill,
            color: Colors.white,
            size: 20,
          ),
        ],
      );
    }

    final bool singleIsVideo =
        hasSingleMedia && _isVideo(medias.first.toString());

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Left color bar
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: chatConfigController.config.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),

          /// ✅ Single media preview (image / video)
          if (hasSingleMedia)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: _buildMediaThumb(medias.first),
            ),

          if (hasSingleMedia) const SizedBox(width: 8),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sender name
                Text(
                  replyMsg.senderUsername ?? "Unknown",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: chatConfigController.config.primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 2),

                /// ✅ Multiple media
                if (hasMultipleMedia)
                  Text(
                    "Replying to ${replyMsg.senderUsername}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  )

                /// ✅ Text reply
                else if (hasText)
                  Text(
                    replyMsg.message!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  )

                /// ✅ Single media label
                else
                  Text(
                    singleIsVideo ? "🎥 Video" : "📷 Photo",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: chatController.clearReply,
          ),
        ],
      ),
    );
  }

  // 🧱 Handle Message Send / Reaction Send
  void _handleSend(ChatController chatController) {
    if (chatController.replyMessage.value != null) {
      chatController.sendMessageWithReply();
    } else if (chatController.showEmojiPicker.value &&
        chatController.messageId.value.isNotEmpty) {
      final conversation =
          chatController.conversations[chatController.chatIndex.value];
      final emoji = chatController.messageController.text;

      if (conversation.isReacted == false) {
        final encryptedText = EncryptionHelper.encryptText(emoji);

        chatController.chatWebSocket!.sendReaction(
          chatController.messageId.value,
          encryptedText,
          int.parse(chatController.conversationId),
        );
        conversation.reactions?.add(emoji);
        conversation.isReacted = true;
        conversation.reaction = emoji;
      } else {
        conversation.reactions
            ?.remove(EncryptionHelper.decryptText(conversation.reaction ?? ""));
        conversation.reactions?.add(emoji);
        conversation.reaction = emoji;
        conversation.isReacted = true;
        final encryptedText = EncryptionHelper.encryptText(emoji);
        chatController.chatWebSocket!.sendReaction(
          chatController.messageId.value,
          encryptedText,
          int.parse(chatController.conversationId),
        );
      }

      chatController.conversations.refresh();
      chatController.messageController.clear();
    } else {
      chatController.sendMessage();
    }
    chatController.showEmojiPicker.value = false;
  }
}
