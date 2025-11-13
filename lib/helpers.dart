import 'package:chat_app/group/group_chat/controller/group_chat_controller.dart';
import 'package:flutter/material.dart';
import 'chat/controller/chat_controller.dart';
import 'chat/helpers/encryption_helper.dart';

void showReactionOverlay({
  required BuildContext context,
  required Offset position,
  required String messageId,
  required ChatController chatController,
  required bool isMine,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => Stack(
      children: [
        Positioned(
          left: isMine ? null : position.dx,
          right: isMine ? MediaQuery.of(context).size.width - position.dx : null,
          top: position.dy - 50,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: ["❤️", "👍", "😂", "😮", "👎", "+"].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      if (emoji == "+") {
                        chatController.showEmojiPicker.value = true;
                        chatController.removeReactionOverlay();
                      } else {
                        final conversation = chatController
                            .conversations[chatController.chatIndex.value];

                        if (conversation.isReacted == false) {
                          final encryptedText=EncryptionHelper.encryptText(emoji);
                          chatController.chatWebSocket.sendReaction(
                            messageId,
                            encryptedText,
                            int.parse(chatController.conversationId),
                          );
                          conversation.reactions?.add(emoji);
                          conversation.isReacted = true;
                          conversation.reaction = emoji;
                        } else {
                          conversation.reactions?.remove(EncryptionHelper.decryptText(conversation.reaction??""));
                          conversation.reactions?.add(emoji);
                          conversation.isReacted=true;
                          conversation.reaction = emoji;
                           final encryptedText=EncryptionHelper.encryptText(emoji);
                          chatController.chatWebSocket.sendReaction(
                            messageId,
                            encryptedText,
                            int.parse(chatController.conversationId),
                          );
                        }
                        chatController.conversations.refresh();
                        chatController.removeReactionOverlay();
                        chatController.chatIndex.value = -1;
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(emoji,
                          style: const TextStyle(fontSize: 28)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  chatController.showReactionOverlayEntry(entry);
  overlay.insert(entry);
}


void showReactionOverlayForGroup({
  required BuildContext context,
  required Offset position,
  required String messageId,
  required GroupChatController chatController,
  required bool isMine,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => Stack(
      children: [
        Positioned(
          left: isMine ? null : position.dx,
          right: isMine ? MediaQuery.of(context).size.width - position.dx : null,
          top: position.dy - 50,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: ["❤️", "👍", "😂", "😮", "👎", "+"].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      if (emoji == "+") {
                        chatController.showEmojiPicker.value = true;
                        chatController.removeReactionOverlay();
                      } else {
                        final conversation = chatController
                            .conversations[chatController.chatIndex.value];

                        if (conversation.isReacted == false) {
                          final encryptedText=EncryptionHelper.encryptText(emoji);
                          chatController.chatWebSocket.sendReaction(
                            messageId,
                            encryptedText,
                            int.parse(chatController.conversationId),
                          );
                          conversation.reactions?.add(emoji);
                          conversation.isReacted = true;
                          conversation.reaction = emoji;
                        } else {
                          conversation.reactions?.remove(EncryptionHelper.decryptText(conversation.reaction??""));
                          conversation.reactions?.add(emoji);
                          conversation.reaction = emoji;
                           final encryptedText=EncryptionHelper.encryptText(emoji);
                          chatController.chatWebSocket.sendReaction(
                            messageId,
                            encryptedText,
                            int.parse(chatController.conversationId),
                          );
                        }
                        chatController.conversations.refresh();
                        chatController.removeReactionOverlay();
                        chatController.chatIndex.value = -1;
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(emoji,
                          style: const TextStyle(fontSize: 28)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  chatController.showReactionOverlayEntry(entry);
  overlay.insert(entry);
}