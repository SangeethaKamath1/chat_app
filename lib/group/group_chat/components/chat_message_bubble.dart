import 'dart:io';
import 'package:chat_app/helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../chat/components/full_screen_image_viewer.dart';
import '../../../chat/components/full_screen_single_media_viewer.dart';
import '../../../chat/components/helpers.dart';
import '../../../chat/components/video_cache.dart';

import '../../../src/theme/controller/chat_theme_controller.dart';
import '../controller/group_chat_controller.dart';
import 'reaction_list_bottom_sheet.dart';

class ChatMessageBubble extends StatelessWidget {
  final dynamic message;
  final int index;
  final bool isMine;
  final bool isForwarded;
  final GroupChatController chatController;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.index,
     required this.isForwarded,
    required this.isMine,
    required this.chatController,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleKey = GlobalKey();
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    return Obx(() {
      return Column(
        crossAxisAlignment: isMine?CrossAxisAlignment.end:CrossAxisAlignment.start,
        children: [
            isForwarded==true?
                            Text(isMine?"You Forwarded a message":"Forwared message",textAlign: TextAlign.right,):const SizedBox.shrink(),
          Container(
            key: bubbleKey,
            color: chatController.chatIndex.value == index
                ? Colors.lightBlueAccent.withOpacity(0.15)
                : Colors.transparent,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity != null &&
                        details.primaryVelocity! > 0) {
                      chatController.setReply(message);
                    }
                  },
                  onLongPressStart: (details) {
                    chatController.chatIndex.value = index;
                    chatController.messageId.value = message.id ?? "";
                    final Offset position = details.globalPosition;
          
                    showReactionOverlayForGroup(
                      context: context,
                      position: position,
                      bubbleKey: bubbleKey,
                      messageId: message.id ?? "",
                      chatController: chatController,
                      isMine: isMine, message: message,
                    );
                  },
                  child: Align(
                    alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
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
                            : (isDark ? Colors.grey[800] : Colors.grey[300]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Sender name (if not mine)
                          if (!isMine)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                message.senderUsername ?? "Unknown",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
          
                          /// Reply preview
                          if (message.replayTo != null)
                            _buildReplyPreview(message, isMine, isDark),
          
                          /// Message content (media or text)
                          if (message.medias != null && message.medias!.isNotEmpty)
                            _buildMediaMessage(context, message, isMine)
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
                                          : (isDark
                                              ? Colors.white
                                              : Colors.black54),
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
          
                /// Reaction bubble
                if (message.reactions?.isNotEmpty == true)
                  _buildReactionBubble(context, message, isMine),
              ],
            ),
          ),
        ],
      );
    });
  }

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

  Widget _buildMediaStatusIcon(dynamic message) {
  return Positioned(
    bottom: 6,
    right: 6,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10),
      ),
      child: _buildStatusIcon(message.status),
    ),
  );
}

  // ===========================================================================
  // MEDIA MESSAGE BUILDER
  // ===========================================================================
  Widget _buildMediaMessage(
    BuildContext context,
    dynamic message,
    bool isMine,
  ) {
    final medias = (message.medias ?? []).cast<String>();
    if (medias.isEmpty) return const SizedBox();

    // uploading if sender has local paths
    final bool isUploading =
        isMine && medias.any((m) => !m.toString().startsWith('http'));

    // Optional: prefetch any remote video once bubble builds
    for (final m in medias) {
      if (m.startsWith('http') && isVideo(m)) {
        // Fire-and-forget
        VideoCache.prefetch(m);
      }
    }

    /// SINGLE MEDIA
    if (medias.length == 1) {
      final mediaPath = medias.first;
      final isNetwork = mediaPath.startsWith('http');
      final isVideoFile = isVideo(mediaPath);

      return GestureDetector(
        onTap: isUploading
            ? null
            : () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    opaque: false,
                    pageBuilder: (_, __, ___) => FullScreenSingleMediaViewer(
                      media: mediaPath,
                    ),
                  ),
                );
              },
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildSingleMediaTile(
                path: mediaPath,
                isNetwork: isNetwork,
                isVideoFile: isVideoFile,
                isUploading: isUploading,
              ),
            ),
            if (isUploading)
              _buildProgressOverlay(
                isUploading: true,
                uploadProgress: message.uploadProgress?.value ?? 0.0,
                downloadProgress: 0.0,
              ),
               if (isMine && !isUploading)
        _buildMediaStatusIcon(message),
          ],
        ),
      );
    }

    /// MULTIPLE MEDIA
    return GestureDetector(
      onTap: isUploading
          ? null
          : () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (_, __, ___) => FullScreenMediaViewer(
                    medias: medias,
                    initialIndex: 0,
                  ),
                ),
              );
            },
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                _buildMediaCollage(medias),
                if (isUploading)
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
              ],
            ),
          ),
          if (isUploading)
            _buildProgressOverlay(
              isUploading: true,
              uploadProgress: message.uploadProgress?.value ?? 0.0,
              downloadProgress: 0.0,
            ),
             if (isMine && !isUploading)
        _buildMediaStatusIcon(message),
        ],
      ),
    );
  }

  // ===========================================================================
  // SINGLE MEDIA TILE (IMAGE/VIDEO THUMB) - VIDEO THUMB FROM CACHE
  // ===========================================================================
  Widget _buildSingleMediaTile({
    required String path,
    required bool isNetwork,
    required bool isVideoFile,
    required bool isUploading,
  }) {
    if (isVideoFile) {
      return FutureBuilder<String?>(
        future: () async {
          final file = isNetwork ? await VideoCache.get(path) : File(path);
          return VideoThumbnail.thumbnailFile(
            video: file.path,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 220,
            quality: 75,
          );
        }(),
        builder: (context, snapshot) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 220,
                height: 220,
                color: Colors.black87,
                child: snapshot.hasData && snapshot.data != null
                    ? Image.file(
                        File(snapshot.data!),
                        width: 220,
                        height: 220,
                        fit: BoxFit.cover,
                      )
                    : const Icon(
                        Icons.videocam,
                        size: 64,
                        color: Colors.white54,
                      ),
              ),
              if (!isUploading)
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
            ],
          );
        },
      );
    }

    // image
    if (isNetwork) {
      return Image.network(
        path,
        width: 220,
        height: 220,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _mediaLoader();
        },
        errorBuilder: (_, __, ___) => _mediaError(),
      );
    } else {
      return Image.file(
        File(path),
        width: 220,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _mediaError(),
      );
    }
  }

  // ===========================================================================
  // COLLAGE (2-4) - VIDEO THUMBS FROM CACHE
  // ===========================================================================
  Widget _buildMediaCollage(List<String> medias) {
    final display = medias.take(4).toList();
    final count = display.length;
    if (count == 0) return const SizedBox();

    Widget tile(String path, int idx) {
      final isNetwork = path.startsWith('http');
      final isVideoFile = isVideo(path);

      return InkWell(
        onTap: () {
          Navigator.push(
            Get.context!,
            PageRouteBuilder(
              opaque: false,
              pageBuilder: (_, __, ___) => FullScreenMediaViewer(
                medias: medias,
                initialIndex: idx,
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: isVideoFile
              ? FutureBuilder<String?>(
                  future: () async {
                    final file =
                        isNetwork ? await VideoCache.get(path) : File(path);
                    return VideoThumbnail.thumbnailFile(
                      video: file.path,
                      imageFormat: ImageFormat.JPEG,
                      maxHeight: 220,
                      quality: 60,
                    );
                  }(),
                  builder: (context, snapshot) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        if (snapshot.hasData && snapshot.data != null)
                          Image.file(File(snapshot.data!), fit: BoxFit.cover)
                        else
                          Container(
                            color: Colors.black87,
                            child: const Center(
                              child: Icon(
                                Icons.videocam,
                                size: 32,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                )
              : isNetwork
                  ? Image.network(path, fit: BoxFit.cover)
                  : Image.file(File(path), fit: BoxFit.cover),
        ),
      );
    }

    if (count == 1) return tile(display[0], 0);

    if (count == 2) {
      return SizedBox(
        width: 220,
        height: 220,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 1),
                child: tile(display[0], 0),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 1),
                child: tile(display[1], 1),
              ),
            ),
          ],
        ),
      );
    }

    if (count == 3) {
      return SizedBox(
        width: 220,
        height: 220,
        child: Column(
          children: [
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: tile(display[0], 0),
              ),
            ),
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 1, top: 1),
                      child: tile(display[1], 1),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 1, top: 1),
                      child: tile(display[2], 2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // count == 4
    return SizedBox(
      width: 220,
      height: 220,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 1, bottom: 1),
                    child: tile(display[0], 0),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 1, bottom: 1),
                    child: tile(display[1], 1),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 1, top: 1),
                    child: tile(display[2], 2),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 1, top: 1),
                    child: Stack(
                      children: [
                        tile(display[3], 3),
                        if (medias.length > 4)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  "+${medias.length - 4}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // REPLY PREVIEW
  // ===========================================================================
  Widget _buildReplyPreview(dynamic msg, bool isMine, bool isDark) {
    final reply = msg.replayTo!;
    final medias = (reply.medias ?? []).cast<String>();
    final bool hasMedia = medias.isNotEmpty;
    final bool hasText =
        reply.message != null && reply.message!.trim().isNotEmpty;

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
          color: isMine ? Colors.white38 : Colors.black12,
        ),
      ),
      child: Row(
        children: [
          if (hasMedia) ...[
            _buildReplyMediaThumb(medias.first),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reply.senderUsername ==
                          chatConfigController.config.prefs.getString(
                              chatConfigController.config.username)
                      ? "You"
                      : (reply.senderUsername ?? "Unknown"),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        isMine ? Colors.white : (isDark ? Colors.white : Colors.black87),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  hasMedia
                      ? (medias.length > 1
                          ? "📷 ${medias.length} Media"
                          : isVideo(medias.first)
                              ? "🎥 Video"
                              : "📷 Photo")
                      : hasText
                          ? reply.message!
                          : "Message",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isMine
                        ? Colors.white70
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyMediaThumb(String path) {
    final isVideoFile = isVideo(path);
    final isNetwork = path.startsWith('http');

    if (!isVideoFile) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: isNetwork
            ? Image.network(path, width: 40, height: 40, fit: BoxFit.cover)
            : Image.file(File(path), width: 40, height: 40, fit: BoxFit.cover),
      );
    }

    return FutureBuilder<String?>(
      future: () async {
        final file = isNetwork ? await VideoCache.get(path) : File(path);
        return VideoThumbnail.thumbnailFile(
          video: file.path,
          imageFormat: ImageFormat.JPEG,
          maxHeight: 40,
          quality: 50,
        );
      }(),
      builder: (context, snapshot) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (snapshot.hasData && snapshot.data != null)
                  Image.file(File(snapshot.data!), fit: BoxFit.cover)
                else
                  Container(
                    color: Colors.black87,
                    child: const Icon(
                      Icons.videocam,
                      size: 16,
                      color: Colors.white54,
                    ),
                  ),
                Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    size: 20,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // OVERLAYS / HELPERS
  // ===========================================================================
  Widget _buildProgressOverlay({
    required bool isUploading,
    required double uploadProgress,
    required double downloadProgress,
  }) {
    final progress = isUploading ? uploadProgress : downloadProgress;
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: progress > 0 ? progress : null,
                  strokeWidth: 3,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  backgroundColor: Colors.white24,
                ),
              ),
              Icon(
                isUploading ? Icons.upload_rounded : Icons.download_rounded,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isUploading
                ? (progress > 0 ? '${(progress * 100).toInt()}%' : 'Uploading...')
                : (progress > 0
                    ? '${(progress * 100).toInt()}%'
                    : 'Downloading...'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
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
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text('Failed to load', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  // ===========================================================================
  // REACTION BUBBLE
  // ===========================================================================
  Widget _buildReactionBubble(BuildContext context, dynamic msg, bool isMine) {
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
              messageId: msg.id ?? "",
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(blurRadius: 2, color: Colors.black26),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: (msg.reactions ?? [])
                .map<Widget>(
                  (emoji) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text('$emoji', style: const TextStyle(fontSize: 14)),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
