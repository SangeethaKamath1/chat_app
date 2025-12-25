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
import '../routes/chat_app_routes.dart';
import '../src/theme/controller/chat_theme_controller.dart';
import 'components/chat_message_bubble.dart';
import 'components/chat_shimmer.dart';
import 'controller/chat_controller.dart';
import 'helpers/encryption_helper.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatController chatController = Get.isRegistered<ChatController>()?
        Get.find<ChatController>():Get.put(ChatController());

    return WillPopScope(
      onWillPop: () async {
        Get.back();
        chatController.removeReactionOverlay();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
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
      
                
      
                  debugPrint("Starting call with room: ${chatController.roomId}");
      
                  // 4. Navigate to call screen as CALLER
                  Get.toNamed(ChatAppRoutes.callScreen,
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
                        chatController.chatWebSocket!
                            .deleteMessage(chatController.messageId.value);
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
              if (!chatController.isLoading.value && !chatController.isFetching.value) {
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
                  if (chatController.isLoading.value ||chatController.isCreateConversationLoading.value) {
      return const ChatShimmer();     // 👈 show shimmer here
          }
      
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      // clear highlight when tapping outside
                      chatController.chatIndex.value = -1;
                      chatController.removeReactionOverlay();
                      chatController.messageId.value = "";
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 0.0),
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
                              style:TextStyle(color:MediaQuery.platformBrightnessOf(context)==Brightness.dark?Colors.white:Colors.black),
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
          chatController.textFieldScrollController.animateTo(
      chatController.textFieldScrollController.position.maxScrollExtent,
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
          Container(
              width: 4,
              height: 40,
              color: chatConfigController.config.primaryColor),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  replyMsg.senderUsername ?? "Unknown",
                  style: TextStyle(
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
