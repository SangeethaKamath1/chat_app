import 'dart:convert';
import 'dart:io';

import 'package:chat_app/chat/components/full_screen_image_viewer.dart';
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
debugPrint("delete indeex:${chatController.chatIndex.value}");
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
                       if (message.medias != null && message.medias!.isNotEmpty)
  _buildImageMessage(context, message, isMine)
else
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


Widget _buildImageMessage(
  BuildContext context,
  Conversations message,
  bool isMine,
) {
  if (message.medias == null || message.medias!.isEmpty) {
    return const SizedBox();
  }

  final String mediaPath = message.medias!.first;
  final bool isNetwork = mediaPath.startsWith('http');

  Widget mediaWidget = isNetwork
      ? Image.network(
          mediaPath,
          width: 220,
          height: 220,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _mediaLoader();
          },
          errorBuilder: (_, __, ___) => _mediaError(),
        )
      : Image.file(
          File(mediaPath),
          width: 220,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _mediaError(),
        );

  return GestureDetector(
    onTap: () {
      chatController.removeReactionOverlay();
      Navigator.push(
        context,
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) =>
              FullScreenImageViewer(imageUrl: mediaPath),
        ),
      );
    },
    child: Stack(
      alignment: Alignment.bottomRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: mediaWidget,
        ),

        if (isMine)
          Padding(
            padding: const EdgeInsets.all(6),
            child: _buildStatusIcon(message.status),
          ),
      ],
    ),
  );
}

Widget _mediaLoader() {
  return Container(
    width: 220,
    height: 220,
    color: Colors.black12,
    child: const Center(
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );
}

Widget _mediaError() {
  return Container(
    width: 220,
    height: 220,
    color: Colors.black12,
    child: const Icon(Icons.broken_image, size: 40),
  );
}
Widget _buildMediaCollage(List<String> medias) {
  final display = medias.take(4).toList();
  final extraCount = medias.length - display.length;

  return SizedBox(
    width: 44,
    height: 44,
    child: Stack(
      children: [
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: display.length,
          itemBuilder: (_, i) {
            final path = display[i];
            final isNetwork = path.startsWith('http');

            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: isNetwork
                  ? Image.network(path, fit: BoxFit.cover)
                  : Image.file(File(path), fit: BoxFit.cover),
            );
          },
        ),

        /// +N overlay when more than 4 (only possible when length == 5)
        if (extraCount > 0)
          Positioned.fill(
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "+$extraCount",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}


  Widget _buildReplyPreview(
  Conversations message,
  bool isMine,
  bool isDark,
) {
  final reply = message.replayTo!;
  final medias = reply.medias ?? [];
  final bool hasSingleMedia = medias.length == 1;
  final bool hasMultipleMedia = medias.length > 1;
  final bool hasText =
      reply.message != null && reply.message!.trim().isNotEmpty;

  final senderName =
      reply.senderUsername ==
              chatConfigController.config.prefs
                  .getString(chatConfigController.config.username)
          ? "You"
          : (reply.senderUsername ?? "Unknown");

  return Container(
    width: 250,
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
    child: Row(
      children: [
        /// Media Preview
        if (hasSingleMedia)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: medias.first.startsWith('http')
                ? Image.network(medias.first,
                    width: 40, height: 40, fit: BoxFit.cover)
                : Image.file(File(medias.first),
                    width: 40, height: 40, fit: BoxFit.cover),
          )
        else if (hasMultipleMedia)
          _buildMediaCollage(medias),

        if (medias.isNotEmpty) const SizedBox(width: 8),

        /// Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                senderName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isMine
                      ? Colors.white
                      : isDark
                          ? Colors.white
                          : Colors.black87,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                hasMultipleMedia
                    ? "📷 ${medias.length} Photos"
                    : hasSingleMedia
                        ? "📷 Photo"
                        : hasText
                            ? reply.message!
                            : "Message",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isMine
                      ? Colors.white70
                      : isDark
                          ? Colors.white70
                          : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
String _mediaPreviewText(int count) {
  if (count == 1) return "📷 Photo";
  return "📷 $count Photos";
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
