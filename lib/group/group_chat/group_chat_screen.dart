import 'package:chat_app/constants/app_constant.dart';
import 'package:chat_app/group/group_chat/controller/group_chat_controller.dart';
import 'package:chat_app/group/group_chat/group-message-info.dart';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../chat/helpers/encryption_helper.dart';
import '../../routes/chat_app_routes.dart';
import '../../src/theme/controller/chat_theme_controller.dart';
import 'components/chat_message_bubble.dart';

class GroupChatScreen extends StatelessWidget {
  const GroupChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
      final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final GroupChatController chatController =Get.isRegistered<GroupChatController>()? Get.find<GroupChatController>():
    Get.put(GroupChatController());

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
      onWillPop: ()async{
        Get.back();
 chatController.removeReactionOverlay();
 return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Obx(
            () {
              return Row(
                children: [
                  groupUserAvatar(chatController.groupIcon.value),
                   const SizedBox(width: 12),
                  Text(chatController.name.value,style: TextStyle(color:Colors.white,fontSize: 18,fontWeight: FontWeight.w700)),
                ],
              );
            }
          ),
          backgroundColor: chatConfigController.config.primaryColor,
          actions: [
            Obx(() { 
              int index = chatController.chatIndex.value;
              return chatController.messageId.isNotEmpty &&chatController.chatIndex.value!=-1&&
                  (chatConfigController.config.prefs.getInt(chatConfigController.config.id).toString()==
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
                  textStyle: TextStyle(color:isDark?Colors.white:Colors.black),
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
                    // chatConfigController.config.prefs.setInt(constant.conversationId, int.parse(chatController.conversationId));
                    Get.toNamed(ChatAppRoutes.groupDetail, arguments: {
                      "groupName": chatController.name.value,
                      'description':chatController.description.value,
                      'icon':chatController.groupIcon.value
                      // "descritpion":chatController.description
                    })?.then((_) {
                      chatController.getCurrentGroupDetails();
                       
                    });
        chatController.chatIndex.value=-1;
                   
                  },
                 
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
                    child: Padding(
                      padding: const EdgeInsets.only(bottom:40.0),
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
                              chatConfigController.config.prefs.getString(chatConfigController.config.username)==chatController.typingUser.value?
                              "You typing....":
                              "${chatController.typingUser.value} typing...",
                              textAlign: TextAlign.left,
                              style:TextStyle(color:MediaQuery.platformBrightnessOf(context)==Brightness.dark?Colors.white:Colors.black),
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
                          config: Config(
                          searchViewConfig: SearchViewConfig(
  customSearchView: (_, __, ___) => const SizedBox.shrink(),
),
    bottomActionBarConfig: BottomActionBarConfig(
  showBackspaceButton: false,     // ❌ hide backspace
  showSearchViewButton: false,    // ❌ hide search button
),),
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
    

    cursorColor: chatConfigController.config.primaryColor,

    style:  TextStyle(
      color: MediaQuery.platformBrightnessOf(context)==Brightness.dark?Colors.white:Colors.black,   // <-- message text color
      fontSize: 16,
    ),

    decoration: InputDecoration(
      hintText: "Type a message...",
      hintStyle: TextStyle(
        color: MediaQuery.platformBrightnessOf(context)==Brightness.dark?
        Colors.white.withOpacity(0.6):Colors.black, // <-- hint color
      ),

      filled: true,
      fillColor: MediaQuery.platformBrightnessOf(context)==Brightness.dark?Colors.black.withOpacity(0.15):Colors.transparent, // <-- background color

     enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12),
                      ),
                      borderSide: BorderSide(color:MediaQuery.platformBrightnessOf(context)==Brightness.dark?Colors.white:Colors.black,
                    )
                    ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: chatConfigController.config.primaryColor, // <-- focused border
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
