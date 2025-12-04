import 'package:chat_app/group/group_chat/controller/group_chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'chat/controller/chat_controller.dart';
import 'chat/helpers/encryption_helper.dart';

void showReactionOverlay({
  required BuildContext context,
  required Offset position,
  required GlobalKey bubbleKey,
  required String messageId,
  required ChatController chatController,
  required bool isMine,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
   // Get bubble position
  final RenderBox renderBox = bubbleKey.currentContext!.findRenderObject() as RenderBox;
  final bubbleOffset = renderBox.localToGlobal(Offset.zero);
  final bubbleSize = renderBox.size;

  // Calculate bubble center
  final centerX = bubbleOffset.dx + bubbleSize.width / 2;
  final centerY = bubbleOffset.dy - 50; // Show overlay just above message

  entry = OverlayEntry(
    builder: (_) => Stack(
      children: [
        Positioned(
         left: centerX - 120, // Half of overlay width
          top: centerY,
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
  required GlobalKey bubbleKey,
  required GroupChatController chatController,
  required bool isMine,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  // Get bubble position
  final RenderBox renderBox = bubbleKey.currentContext!.findRenderObject() as RenderBox;
  final bubbleOffset = renderBox.localToGlobal(Offset.zero);
  final bubbleSize = renderBox.size;

  // Calculate bubble center
  final centerX = bubbleOffset.dx + bubbleSize.width / 2;
  final centerY = bubbleOffset.dy - 50; // Show

  entry = OverlayEntry(
    builder: (_) => Stack(
      children: [
        Positioned(
         left: centerX - 120, // Half of overlay width
          top: centerY,
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

 String renderTime(DateTime? createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt ?? DateTime.now());

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays <= 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat("dd/MM/yyyy").format(createdAt ?? DateTime.now());
    }
  }

   String formatDate(DateTime? createdAt) {
  if (createdAt == null) return '';

  final now = DateTime.now();
  final difference = now.difference(createdAt);

  // Just now (below 1 minute)
  if (difference.inSeconds < 60) {
    return "Just now";
  }

  // Minutes
  if (difference.inMinutes < 60) {
    return "${difference.inMinutes}m";
  }

  // Hours  
  if (difference.inHours < 24) {
    return "${difference.inHours}h";
  }

  // Yesterday  
  final yesterday = now.subtract(const Duration(days: 1));
  if (createdAt.day == yesterday.day &&
      createdAt.month == yesterday.month &&
      createdAt.year == yesterday.year) {
    return "Yesterday";
  }

  // Days within a week
  if (difference.inDays <= 7) {
    return "${difference.inDays}d";
  }

  // Same year → dd/MM/yyyy
  if (createdAt.year == now.year) {
    return DateFormat("dd/MM/yyyy").format(createdAt);
  }

  // Older → Jan 5, 2024
  return DateFormat("MMM d, yyyy").format(createdAt);
}
