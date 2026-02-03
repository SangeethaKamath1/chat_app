import 'package:chat_app/group/group_chat/controller/group_chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'chat/controller/chat_controller.dart';
import 'chat/helpers/encryption_helper.dart';
import 'model/conversation_list.dart';
import 'routes/chat_app_routes.dart';

void showReactionOverlay({
  required BuildContext context,
  required Offset position,
  required GlobalKey bubbleKey,
  required Conversations message, // ✅ NEW
  required String messageId,
  required ChatController chatController,
  required bool isMine,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  final RenderBox renderBox =
      bubbleKey.currentContext!.findRenderObject() as RenderBox;
  final bubbleOffset = renderBox.localToGlobal(Offset.zero);
  final bubbleSize = renderBox.size;

  final centerX = bubbleOffset.dx + bubbleSize.width / 2;
  final centerY = bubbleOffset.dy - 56;

  entry = OverlayEntry(
    builder: (_) => Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              chatController.removeReactionOverlay();
              chatController.showEmojiPicker.value = false;
            },
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          left: centerX - 170,
          top: centerY,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(blurRadius: 6, color: Colors.black26),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...["❤️", "👍", "😂", "😮", "👎", "+"].map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        if (emoji == "+") {
                          chatController.showEmojiPicker.value = true;
                          chatController.removeReactionOverlay();
                          return;
                        }

                        final conversation = chatController
                            .conversations[chatController.chatIndex.value];

                        if (conversation.isReacted == false) {
                          final encryptedText =
                              EncryptionHelper.encryptText(emoji);
                          chatController.chatWebSocket.sendReaction(
                            messageId,
                            encryptedText,
                            int.parse(chatController.conversationId),
                          );
                          conversation.reactions?.add(emoji);
                          conversation.isReacted = true;
                          conversation.reaction = emoji;
                        } else {
                          conversation.reactions?.remove(
                            EncryptionHelper.decryptText(
                                conversation.reaction ?? ""),
                          );
                          conversation.reactions?.add(emoji);
                          conversation.isReacted = true;
                          conversation.reaction = emoji;

                          final encryptedText =
                              EncryptionHelper.encryptText(emoji);
                          chatController.chatWebSocket.sendReaction(
                            messageId,
                            encryptedText,
                            int.parse(chatController.conversationId),
                          );
                        }

                        chatController.conversations.refresh();
                        chatController.removeReactionOverlay();
                        chatController.chatIndex.value = -1;
                        chatController.messageId.value = "";
                        chatController.showEmojiPicker.value = false;
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(emoji, style: const TextStyle(fontSize: 28)),
                      ),
                    );
                  }).toList(),

                  const SizedBox(width: 8),

                  // ✅ Forward
                  GestureDetector(
                    onTap: () {
                      chatController.setForwardMessage(message);

                      chatController.removeReactionOverlay();
                      chatController.chatIndex.value = -1;
                      chatController.messageId.value = "";

                      // ✅ go to recent conversations in forward mode
                      Get.toNamed(
                        ChatAppRoutes.recentConversation, // adjust route name
                        arguments: {"mode": "forward","from":"private"},
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.forward, size: 22),
                    ),
                  ),
                ],
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

  // ✅ NEW (for Forward)
  required Conversations message,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  // Get bubble position
  final RenderBox renderBox =
      bubbleKey.currentContext!.findRenderObject() as RenderBox;
  final bubbleOffset = renderBox.localToGlobal(Offset.zero);
  final bubbleSize = renderBox.size;

  // Calculate bubble center
  final centerX = bubbleOffset.dx + bubbleSize.width / 2;
  final centerY = bubbleOffset.dy - 56; // match private overlay feel

  entry = OverlayEntry(
    builder: (_) => Stack(
      children: [
        // ✅ Tap outside to dismiss (same as private)
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              chatController.removeReactionOverlay();
              chatController.showEmojiPicker.value = false;
            },
            child: Container(color: Colors.transparent),
          ),
        ),

        Positioned(
          left: centerX - 170, // same width alignment as private
          top: centerY,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(blurRadius: 6, color: Colors.black26),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...["❤️", "👍", "😂", "😮", "👎", "+"].map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        if (emoji == "+") {
                          chatController.showEmojiPicker.value = true;
                          chatController.removeReactionOverlay();
                          return;
                        }

                        final conversation = chatController
                            .conversations[chatController.chatIndex.value];

                        final encryptedText =
                            EncryptionHelper.encryptText(emoji);

                        if (conversation.isReacted == false) {
                          chatController.chatWebSocket!.sendReaction(
                            messageId,
                            encryptedText,
                            int.parse(chatController.conversationId),
                          );
                          conversation.reactions?.add(emoji);
                          conversation.isReacted = true;
                          conversation.reaction = emoji;
                        } else {
                          // remove previous reaction (stored encrypted)
                          conversation.reactions?.remove(
                            EncryptionHelper.decryptText(
                              conversation.reaction ?? "",
                            ),
                          );
                          conversation.reactions?.add(emoji);
                          conversation.isReacted = true;
                          conversation.reaction = emoji;

                          chatController.chatWebSocket!.sendReaction(
                            messageId,
                            encryptedText,
                            int.parse(chatController.conversationId),
                          );
                        }

                        chatController.conversations.refresh();
                        chatController.removeReactionOverlay();
                        chatController.chatIndex.value = -1;
                        chatController.showEmojiPicker.value = false;
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(emoji, style: const TextStyle(fontSize: 28)),
                      ),
                    );
                  }).toList(),

                  const SizedBox(width: 8),

                  // ✅ Forward (added like private)
                  GestureDetector(
                    onTap: () {
                      // if you already have same method in GroupChatController
                      // use it. Otherwise, implement similarly to private.
                      chatController.setForwardMessage(message);

                      chatController.removeReactionOverlay();
                      chatController.chatIndex.value = -1;

                      Get.toNamed(
                        ChatAppRoutes.recentConversation,
                        arguments: {"mode": "forward","from":"group"},
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.forward, size: 22),
                    ),
                  ),
                ],
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
    debugPrint("created at inside helpers:${createdAt}");
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
