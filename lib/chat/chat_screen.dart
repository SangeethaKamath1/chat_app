import 'package:chat_app/chat/chat_websocket/chat_web_socket_service.dart';
import 'package:chat_app/constants/app_constant.dart';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../audio_call/screens/call_screen.dart';
import '../audio_call/controller/jitsi_call_controller.dart';

import '../audio_call/service/webrtc_service.dart';
import '../routes/app_routes.dart';
import '../src/theme/controller/chat_theme_controller.dart';
import 'components/chat_message_bubble.dart';
import 'controller/chat_controller.dart';
import 'helpers/encryption_helper.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // const String roomId = "test_room_123";
    final ChatController chatController = Get.find<ChatController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(chatController.name),
        backgroundColor: chatConfigController.config.primaryColor,
        actions: [
          InkWell(
            onTap: () async {
              try {
                // 1. Request microphone permission
                final micStatus = await Permission.microphone.request();
                if (micStatus.isDenied) {
                  Get.snackbar(
                      "Permission Required", "Allow microphone access");
                  return;
                }

                // 2. Generate room ID
                chatController.roomId =
                    "${chatController.conversationId}_${chatController.uuid.v4()}";

                // 3. Send call initiation message via WebSocket
                chatController.chatWebSocket
                    .initiatingCall(chatController.roomId);

                debugPrint("Starting call with room: ${chatController.roomId}");

                // 4. Navigate to call screen as CALLER
                Get.toNamed(AppRoutes.callScreen,
                    arguments: {'isCaller': true});

                // 5. DO NOT call _initializeCall() here - it will be called in VoiceCallScreen
              } catch (e) {
                debugPrint("Error starting call: $e");
                Get.snackbar("Call Failed", "Could not start call");
              }
            },
            child: const Icon(Icons.call),
          ),
          const SizedBox(width: 16),
          Obx(() => chatController.messageId.isNotEmpty &&
                  chatConfigController.config.prefs.getString(chatConfigController.config.userId) ==
                      chatController
                          .conversations[chatController.chatIndex.value]
                          .senderUUID
              ? IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    chatController.removeReactionOverlay();
                    chatController.chatWebSocket
                        .deleteMessage(chatController.messageId.value);
                  },
                )
              : const SizedBox.shrink()),
        ],
      ),

      // MAIN BODY
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels ==
              notification.metrics.maxScrollExtent) {
            if (!chatController.isLoading) {
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
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    // clear highlight when tapping outside
                    chatController.chatIndex.value = -1;
                    chatController.removeReactionOverlay();
                    chatController.messageId.value = "";
                  },
                  child: ListView.builder(
                    reverse: true,
                    controller: chatController.scrollController,
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: chatController.conversations.length,
                    itemBuilder: (context, index) {
                      final message = chatController.conversations[index];
                      final isMine = message.senderUsername ==
                          chatConfigController.config.prefs.getString(chatConfigController.config.username);

                      return ChatMessageBubble(
                        message: message,
                        index: index,
                        isMine: isMine,
                        chatController: chatController,
                      );
                    },
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
                            textAlign: TextAlign.left,
                          )),
                    )
                  : const SizedBox.shrink();
            }),
            // 🧭 Reply Bar + Input Field
            _buildMessageInputArea(context, chatController),

            // 😀 Emoji Picker
            Obx(() {
              return chatController.showEmojiPicker.value
                  ? SizedBox(
                      height: 250,
                      child: EmojiPicker(
                        onEmojiSelected: (category, emoji) {
                          if (chatController.messageId.value.isNotEmpty) {
                            final conversation = chatController
                                .conversations[chatController.chatIndex.value];

                            if (conversation.isReacted == false) {
                              final encryptedText =
                                  EncryptionHelper.encryptText(emoji.emoji);
                              chatController.chatWebSocket.sendReaction(
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
                              chatController.chatWebSocket.sendReaction(
                                chatController.messageId.value,
                                encryptedText,
                                int.parse(chatController.conversationId),
                              );
                            }

                            chatController.conversations.refresh();
                            chatController.messageController.clear();
                            chatController.chatIndex.value = -1;
                            chatController.messageId.value = "";
                            chatController.showEmojiPicker.value = false;
                          } else {
                            chatController.messageController.text +=
                                emoji.emoji;
                          }
                        },
                      ),
                    )
                  : const SizedBox.shrink();
            }),
          ],
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
                  decoration: const InputDecoration(
                    hintText: "Type a message...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  onChanged: chatController.onTextChanged,
                ),
              ),
              IconButton(
                icon:  Icon(Icons.send, color: chatConfigController.config.primaryColor),
                onPressed: () => _handleSend(chatController),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🧱 Reply Preview Bar
  Widget _buildReplyPreview(ChatController chatController, replyMsg) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 40, color: chatConfigController.config.primaryColor),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  replyMsg.senderUsername ?? "Unknown",
                  style:  TextStyle(
                    fontWeight: FontWeight.bold,
                    color: chatConfigController.config.primaryColor,
                  ),
                ),
                Text(
                  replyMsg.message ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

        chatController.chatWebSocket.sendReaction(
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
        chatController.chatWebSocket.sendReaction(
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
