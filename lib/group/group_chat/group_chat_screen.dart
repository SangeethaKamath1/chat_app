import 'package:chat_app/constants/app_constant.dart';
import 'package:chat_app/group/group_chat/controller/group_chat_controller.dart';
import 'package:chat_app/group/group_chat/group-message-info.dart';
import 'package:chat_app/service/shared_preference.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../chat/helpers/encryption_helper.dart';
import '../../routes/app_routes.dart';
import 'components/chat_message_bubble.dart';

class GroupChatScreen extends StatelessWidget {
  const GroupChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final GroupChatController chatController = Get.find<GroupChatController>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () {
            return Text(chatController.name.value);
          }
        ),
        backgroundColor: Colors.blue,
        actions: [
          Obx(() { 
            int index = chatController.chatIndex.value;
            return chatController.messageId.isNotEmpty &&chatController.chatIndex.value!=-1&&
                (SharedPreference().getString(AppConstant.userId) ==
                          chatController
                              .conversations[index]
                              .senderUUID ||
                      chatController.currentGroupDetails.value.isAdmin == true ||
                      chatController.currentGroupDetails.value.isOwner == true)
              ? IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    chatController.removeReactionOverlay();
                    chatController.chatWebSocket
                        .deleteMessage(chatController.messageId.value);
                  },
                )
              : const SizedBox.shrink();}),
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: "info",
                child: Text("info"),
                onTap: () async{
                  chatController.removeReactionOverlay();
                  
                  int index = chatController.chatIndex.value;
                  
                 
                      chatController.messageId.value.isNotEmpty &&chatController.chatIndex.value!=-1?
                          await chatController.fetchMessageStatus(chatController.messageId.value).then((_) {
                  Get.to(
                    ()  =>  GroupMessageInfoScreen(
                      messageId: chatController.messageId.value,
                      messageText: chatController.conversations[index].message??"",
                      senderName: chatController.conversations[index].senderUsername ?? 'Unknown',
                      chatController: chatController,
                    ),
                  );
                }):
                  // SharedPreference().setInt(AppConstant.conversationId, int.parse(chatController.conversationId));
                  Get.toNamed(AppRoutes.groupDetail, arguments: {
                    "groupName": chatController.name.value,
                    'description':chatController.description.value
                    // "descritpion":chatController.description
                  })?.then((_) {
                    chatController.getCurrentGroupDetails();
                     
                  });
  chatController.chatIndex.value=-1;
                 
                },
               
              ),
              const PopupMenuItem(value: "Delete", child: Text("Delete")),
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
            if (!chatController.isLoading) {
              //chatController.getConversationsList();
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
                          SharedPreference().getString(AppConstant.username);

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
                            SharedPreference().getString(AppConstant.username)==chatController.typingUser.value?
                            "You typing....":
                            "${chatController.typingUser.value} typing...",
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
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: () => _handleSend(chatController),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🧱 Reply Preview Bar
  Widget _buildReplyPreview(GroupChatController chatController, replyMsg) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 40, color: Colors.blue),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  replyMsg.senderUsername ?? "Unknown",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
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
