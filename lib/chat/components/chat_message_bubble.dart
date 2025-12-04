import 'package:chat_app/chat/components/reaction_list_bottom_sheet.dart';
import 'package:chat_app/model/conversation_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_constant.dart';
import '../../helpers.dart';
import '../../src/theme/controller/chat_theme_controller.dart';
import '../controller/chat_controller.dart';

class ChatMessageBubble extends StatelessWidget {
  final Conversations message;
  final int index;
  final bool isMine;
  final ChatController chatController;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.index,
    required this.isMine,
    required this.chatController,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleKey = GlobalKey();
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    return Obx(() {
      return Container(
        key: bubbleKey,
        color: chatController.chatIndex.value == index
            ? Colors.lightBlueAccent.withOpacity(0.2)
            : Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              /// Swipe right to reply
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! > 0) {
                  chatController.setReply(message);
                }
              },

              /// Long press → show reaction overlay
              onLongPressStart: (details) {
                chatController.chatIndex.value = index;
                chatController.messageId.value = message.id ?? "";

                final Offset position = details.globalPosition;
                chatController.removeReactionOverlay();

                showReactionOverlay(
                  context: context,
                  position: position,
                  bubbleKey: bubbleKey,
                  messageId: message.id ?? "",
                  chatController: chatController,
                  isMine: isMine,
                );
              },

              child: Align(
                alignment:
                    isMine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: EdgeInsets.only(
                    top: 4,
                    bottom: message.reactions?.isNotEmpty == true ? 22 : 4,
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: isMine
                        ? chatConfigController.config.primaryColor
                        : (isDark ? Colors.grey[700] : Colors.grey[300]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Reply preview
                      if (message.replayTo != null)
                        _buildReplyPreview(message, isMine, isDark),

                      /// Message text + status tick
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              message.message ?? "",
                              style: TextStyle(
                                fontSize: 15,
                                color: isMine
                                    ? Colors.white
                                    : (isDark ? Colors.white : Colors.black),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (isMine) _buildStatusIcon(message.status),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            /// Reaction bubble underneath message
            if (message.reactions?.isNotEmpty == true)
              _buildReactionBubble(context, message, isMine),
          ],
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Reply Preview
  // ---------------------------------------------------------------------------

  Widget _buildReplyPreview(message, bool isMine, bool isDark) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(6),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isMine
            ? Colors.white24
            : (isDark ? Colors.black26 : Colors.grey[200]),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMine ? Colors.white54 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replayTo!.senderUsername ?? "Unknown",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isMine ? Colors.white : isDark?Colors.white: Colors.black87,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            message.replayTo!.message ?? "",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isMine ? Colors.white70 : isDark?Colors.white70:Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Message Sent / Delivered / Seen Icon
  // ---------------------------------------------------------------------------

  Widget _buildStatusIcon(String? status) {
    switch (status) {
      case "SEND":
        return const Icon(Icons.check, size: 18, color: Colors.white70);
      case "DELIVERED":
        return const Icon(Icons.done_all, size: 18, color: Colors.white70);
      case "SEEN":
        return const Icon(Icons.done_all, size: 18, color: Colors.lightBlue);
      default:
        return const Icon(Icons.check, size: 18, color: Colors.white70);
    }
  }

  // ---------------------------------------------------------------------------
  // Reaction Bubble
  // ---------------------------------------------------------------------------

  Widget _buildReactionBubble(BuildContext context, message, bool isMine) {
    return Positioned(
      bottom: 10,
      right: isMine ? 12 : null,
      left: isMine ? null : 12,
      child: InkWell(
        onTap: () {
          chatController.isReactionLastPage = false;
          chatController.chatIndex.value = index;
          chatController.reactions.clear();

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => ReactionListBottomSheet(
              chatController: chatController,
              messageId: message.id ?? "",
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                blurRadius: 2,
                color: Colors.black26,
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: message.reactions!
                .map<Widget>(
                  (emoji) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
