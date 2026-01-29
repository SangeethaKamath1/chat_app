import 'dart:io';

import 'package:amu_alumni/utils/reusables/sized_box.dart';
import 'package:chat_app/constants/app_constant.dart';
import 'package:chat_app/group/group_chat/components/attachment_bottom_sheet.dart';
import 'package:chat_app/group/group_chat/controller/group_chat_controller.dart';
import 'package:chat_app/group/group_chat/group-message-info.dart';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../audio_call/controller/call_session_controller.dart';
import '../../chat/helpers/encryption_helper.dart';
import '../../group_audio_video_call/service/livekit_group_audio_service.dart';
import '../../routes/chat_app_routes.dart';
import '../../src/theme/controller/chat_theme_controller.dart';
import 'components/chat_message_bubble.dart';
import 'components/ongoing_call_banner.dart';

class GroupChatScreen extends StatelessWidget {
  const GroupChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final GroupChatController chatController = Get.find<GroupChatController>();

void _showClearChatDialog(
  BuildContext context,

) {
  Get.dialog(
    AlertDialog(
      title: const Text("Clear chat?"),
      content: const Text(
        "This will remove all messages from this chat.",
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () async {
            Get.back();

            try {
              await chatController.clearChat();

              /// 🔥 CLEAR LOCAL CHAT STATE
              chatController.conversations.clear();
              chatController.conversations.refresh();

              chatController.page = 0;
              chatController.isLastPage = false;

            } catch (e) {
              Get.snackbar("Error", "Failed to clear chat");
            }
          },
          child: const Text(
            "Clear",
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
}
    

    Widget groupUserAvatar(String? profileUrl) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: (profileUrl != null && profileUrl.isNotEmpty)
              ? Image.network(
                  profileUrl,
                  fit: BoxFit.cover,
                  width: 36,
                  height: 36,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.group,
                      size: 36,
                      color: Colors.grey,
                    );
                  },
                )
              : const Icon(
                  Icons.group,
                  size: 36,
                  color: Colors.grey,
                ),
        ),
      );
    }

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
          title: Obx(() {
            return Row(
              children: [
                groupUserAvatar(chatController.groupIcon.value),
                const SizedBox(width: 12),
                Text(chatController.name.value,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
              ],
            );
          }),
          backgroundColor: chatConfigController.config.primaryColor,
          actions: [
            InkWell(
              onTap: () async {
                try {
                  // 1️⃣ Mic permission
                  final micStatus = await Permission.microphone.request();
                  if (!micStatus.isGranted) {
                    Get.snackbar(
                      "Permission required",
                      "Microphone permission is needed for calls",
                    );
                    return;
                  }

                  // 2️⃣ Generate GROUP roomId
                  final callId =
                      "${chatController.conversationId}_${chatController.uuid.v4()}";

                  chatController.chatWebSocket.callID.value = callId;
                 
debugPrint("Call id inside group chat screen:${callId}");
                  // 5️⃣ Navigate to Group Call Screen
                  Get.toNamed(
                    ChatAppRoutes.groupCallScreen,
                    arguments: {
                      "callID": chatController.chatWebSocket.callID.value,
                      "isCaller": true,
                      "isVideo": false,
                      "fromNotification":false
                    },
                  );
                } catch (e) {
                  debugPrint("❌ Failed to start group call: $e");
                  Get.snackbar("Call Failed", "Unable to start group call");
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

                  final callId =
                      "${chatController.conversationId}_${chatController.uuid.v4()}";

                  chatController.chatWebSocket.callID.value = callId;
              

                  Get.toNamed(
                    ChatAppRoutes.groupCallScreen,
                    arguments: {
                      "callID": callId,
                      "isCaller": true,
                      "isVideo": true,
                       "fromNotification":false
                    },
                  );
                } catch (e) {
                  debugPrint("Error starting call: $e");
                  Get.snackbar("Call Failed", "Could not start call");
                }
              },
              child: const Icon(Icons.video_call),
            ),
            Obx(() {
              int index = chatController.chatIndex.value;
              return chatController.messageId.isNotEmpty &&
                      chatController.chatIndex.value != -1 &&
                      (chatConfigController.config.prefs
                                  .getInt(chatConfigController.config.id)
                                  .toString() ==
                              chatController.conversations[index].senderUUID ||
                          chatController.currentGroupDetails.value.isAdmin ==
                              true ||
                          chatController.currentGroupDetails.value.isOwner ==
                              true)
                  ? IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        chatController.removeReactionOverlay();
                        debugPrint(
                            "message id on delete:${chatController.messageId.value}");
                        chatController.chatWebSocket!.deleteMessage(
                            chatController.messageId.value,
                            chatController.chatIndex.value);
                      },
                    )
                  : const SizedBox.shrink();
            }),
            PopupMenuButton<String>(
             
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: "info",
                  textStyle:
                      TextStyle(color: isDark ? Colors.white : Colors.black),
                  child: Text("info"),
                  onTap: () async {
                    chatController.removeReactionOverlay();

                    int index = chatController.chatIndex.value;

                    chatController.messageId.value.isNotEmpty &&
                            chatController.chatIndex.value != -1
                        ? await chatController
                            .fetchMessageStatus(chatController.messageId.value)
                            .then((_) {
                            Get.to(
                              () => GroupMessageInfoScreen(
                                messageId: chatController.messageId.value,
                                messageText: chatController
                                        .conversations[index].message ??
                                    "",
                                senderName: chatController
                                        .conversations[index].senderUsername ??
                                    'Unknown',
                                chatController: chatController,
                              ),
                            );
                          })
                        :
                        // chatConfigController.config.prefs.setInt(constant.conversationId, int.parse(chatController.conversationId));
                        Get.toNamed(ChatAppRoutes.groupDetail, arguments: {
                            "groupName": chatController.name.value,
                            'description': chatController.description.value,
                            'icon': chatController.groupIcon.value
                            // "descritpion":chatController.description
                          })?.then((_) {
                            chatController.getCurrentGroupDetails();
                          });
                    chatController.chatIndex.value = -1;
                    debugPrint("chat controller -1 inside group tap");
                  },
                ),

                   
    PopupMenuItem(
      value: 'clear_chat',
      onTap: (){
        
                                _showClearChatDialog(
                                  context);
                              
      },
      child: Text("Clear Chat",style: TextStyle(color:MediaQuery.platformBrightnessOf(context)==Brightness.dark?Colors.white:Colors.black,),),
    ),
  
                //  PopupMenuItem(value: "Delete",
                //  textStyle: TextStyle(color:isDark?Colors.white:Colors.black),
                // child: Text("Delete")),
              ],
              icon: const Icon(Icons.more_vert),
            )
         
         
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
          //  chatController.chatWebSocket.hasOngoingCall.value?  OngoingCallBanner(chatController: chatController):const SizedBox.shrink(),
              // 🧱 Message List
              Expanded(
                child: Obx(() {
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      // clear highlight when tapping outside
                      chatController.chatIndex.value = -1;
                      debugPrint(
                          "chat controller -1 inside global tap group chat");
                      chatController.removeReactionOverlay();
                      chatController.messageId.value = "";
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40.0),
                      child: ListView.builder(
                        reverse: true,
                        controller: chatController.scrollController,
                        clipBehavior: Clip.none,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: chatController.conversations.length,
                        itemBuilder: (context, index) {
                          final message = chatController.conversations[index];
                          final isMine = message.senderUsername ==
                              chatConfigController.config.prefs.getString(
                                  chatConfigController.config.username);

                          return Column(
                            children: [
                              ChatMessageBubble(
                                message: message,
                                index: index,
                                isMine: isMine,
                                chatController: chatController,
                              ),
                            ],
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
                              chatConfigController.config.prefs.getString(
                                          chatConfigController
                                              .config.username) ==
                                      chatController.typingUser.value
                                  ? "You typing...."
                                  : "${chatController.typingUser.value} typing...",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  color: MediaQuery.platformBrightnessOf(
                                              context) ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black),
                            )),
                      )
                    : const SizedBox.shrink();
              }),
              // 🧭 Reply Bar + Input Field
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                color:
                    MediaQuery.platformBrightnessOf(context) == Brightness.dark
                        ? Colors.black
                        : Colors.white,
                child: _buildMessageInputArea(context, chatController),
              ),

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
      BuildContext context, GroupChatController chatController) {
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
                        ? Colors.black.withOpacity(0.15)
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
  Widget _buildReplyPreview(GroupChatController chatController, replyMsg) {
    final bool hasText =
        replyMsg.message != null && replyMsg.message!.trim().isNotEmpty;

    final List<dynamic> medias = replyMsg.medias ?? [];
    final bool hasSingleMedia = medias.length == 1;
    final bool hasMultipleMedia = medias.length > 1;

    Widget _buildMediaThumb(String path) {
      if (path.startsWith('http')) {
        return Image.network(
          path,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        );
      }
      return Image.file(
        File(path),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

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

          /// ✅ CASE 2: Single media → show thumbnail
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

                /// ✅ CASE 3: Multiple media
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

                /// ✅ CASE 1: Text message (1 line only)
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

                /// Fallback (single media label)
                else
                  const Text(
                    "📷 Photo",
                    style: TextStyle(
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
  void _handleSend(GroupChatController chatController) {
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
