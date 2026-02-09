import 'dart:io';

import 'package:chat_app/chat/components/full_screen_image_viewer.dart';
import 'package:chat_app/chat/components/reaction_list_bottom_sheet.dart';
import 'package:chat_app/helpers.dart';
import 'package:chat_app/model/conversation_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../src/theme/controller/chat_theme_controller.dart';
import '../controller/chat_controller.dart';
import 'full_screen_single_media_viewer.dart';
import 'helpers.dart';
import 'video_cache.dart';

class ChatMessageBubble extends StatelessWidget {
  final Conversations message;
  final int index;
  final bool isMine;
  final bool isForwarded;
  final ChatController chatController;

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
                      message: message, // ✅ NEW
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
          
                          /// Message text OR media
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
          ),
        ],
      );
    });
  }

  // ===========================================================================
  // MEDIA MESSAGE
  // ===========================================================================
  Widget _buildMediaMessage(
    BuildContext context,
    Conversations message,
    bool isMine,
  ) {
    final medias = (message.medias ?? []).cast<String>();
    if (medias.isEmpty) return const SizedBox();

    /// local path while uploading for sender
    final bool isUploading =
        isMine && medias.any((m) => !m.toString().startsWith('http'));

    /// receiver side (if you support actual download progress)
    final bool needsDownload =
        !isMine && medias.any((m) => m.toString().startsWith('http'));

    /// ✅ Prefetch remote videos (fire-and-forget)
    for (final m in medias) {
      if (m.startsWith('http') && isVideo(m)) {
        VideoCache.prefetch(m);
      }
    }

    /// SINGLE MEDIA (Image or Video)
    if (medias.length == 1) {
      final mediaPath = medias.first;
      final isNetwork = mediaPath.startsWith('http');
      final isVideoFile = isVideo(mediaPath);

      return GestureDetector(
        onTap: isUploading
            ? null
            : () {
                chatController.removeReactionOverlay();
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

            /// Upload/Download progress overlay
            if (isUploading ||
                (needsDownload && message.downloadProgress != null))
              _buildProgressOverlay(
                isUploading: isUploading,
                uploadProgress: message.uploadProgress?.value ?? 0.0,
                downloadProgress: message.downloadProgress?.value ?? 0.0,
              ),

            /// Status icon (bottom-right) - only show when not uploading
             if (isMine && !isUploading)
        _buildMediaStatusIcon(message),
          ],
        ),
      );
    }

    /// MULTIPLE MEDIA (2-4 items)
    return GestureDetector(
      onTap: isUploading
          ? null
          : () {
              chatController.removeReactionOverlay();
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
  // SINGLE TILE (VIDEO THUMB FROM CACHE)
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

    // Image handling
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
  // COLLAGE (VIDEO THUMB FROM CACHE)
  // ===========================================================================
  Widget _buildMediaCollage(List<String> medias) {
    final display = medias.take(4).toList();
    final count = display.length;
    if (count == 0) return const SizedBox();

    Widget buildItem(String path, int idx) {
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

    if (count == 1) return buildItem(display[0], 0);

    if (count == 2) {
      return SizedBox(
        width: 220,
        height: 220,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 1),
                child: buildItem(display[0], 0),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 1),
                child: buildItem(display[1], 1),
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
                child: buildItem(display[0], 0),
              ),
            ),
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 1, top: 1),
                      child: buildItem(display[1], 1),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 1, top: 1),
                      child: buildItem(display[2], 2),
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
                    child: buildItem(display[0], 0),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 1, bottom: 1),
                    child: buildItem(display[1], 1),
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
                    child: buildItem(display[2], 2),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 1, top: 1),
                    child: Stack(
                      children: [
                        buildItem(display[3], 3),
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
  // REPLY PREVIEW (FIXED: uses cached file for video thumb)
  // ===========================================================================
  Widget _buildReplyPreview(
    Conversations message,
    bool isMine,
    bool isDark,
  ) {
    final reply = message.replayTo!;
    final medias = (reply.medias ?? []).cast<String>();
    final bool hasSingleMedia = medias.length == 1;
    final bool hasMultipleMedia = medias.length > 1;
    final bool hasText =
        reply.message != null && reply.message!.trim().isNotEmpty;

    final senderName = reply.senderUsername ==
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
            Builder(
              builder: (_) {
                final path = medias.first;
                final isVideoFile = isVideo(path);
                final isNetwork = path.startsWith('http');

                if (isVideoFile) {
                  return FutureBuilder<String?>(
                    future: () async {
                      final file =
                          isNetwork ? await VideoCache.get(path) : File(path);
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
                                Image.file(File(snapshot.data!),
                                    fit: BoxFit.cover)
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

                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: isNetwork
                      ? Image.network(path,
                          width: 40, height: 40, fit: BoxFit.cover)
                      : Image.file(File(path),
                          width: 40, height: 40, fit: BoxFit.cover),
                );
              },
            )
          else if (hasMultipleMedia)
            _buildMediaCollageThumbnail(medias),

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
                      ? "📷 ${medias.length} ${_containsVideo(medias) ? 'Media' : 'Photos'}"
                      : hasSingleMedia
                          ? isVideo(medias.first)
                              ? "🎥 Video"
                              : "📷 Photo"
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

  // Reply preview: collage thumbnail (FIXED: cached for video)
  Widget _buildMediaCollageThumbnail(List<String> medias) {
    final display = medias.take(4).toList();
    final count = display.length;
    if (count == 0) return const SizedBox();

    Widget buildThumb(String path) {
      final isNetwork = path.startsWith('http');
      final isVideoFile = isVideo(path);

      if (isVideoFile) {
        return FutureBuilder<String?>(
          future: () async {
            final file = isNetwork ? await VideoCache.get(path) : File(path);
            return VideoThumbnail.thumbnailFile(
              video: file.path,
              imageFormat: ImageFormat.JPEG,
              maxHeight: 44,
              quality: 50,
            );
          }(),
          builder: (context, snapshot) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
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
            );
          },
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: isNetwork
            ? Image.network(path, fit: BoxFit.cover)
            : Image.file(File(path), fit: BoxFit.cover),
      );
    }

    // single tile for <=2
    if (count <= 2) {
      final path = display.first;
      final isNetwork = path.startsWith('http');
      final isVideoFile = isVideo(path);

      if (isVideoFile) {
        return FutureBuilder<String?>(
          future: () async {
            final file = isNetwork ? await VideoCache.get(path) : File(path);
            return VideoThumbnail.thumbnailFile(
              video: file.path,
              imageFormat: ImageFormat.JPEG,
              maxHeight: 44,
              quality: 50,
            );
          }(),
          builder: (context, snapshot) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 44,
                height: 44,
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
                          size: 20,
                          color: Colors.white54,
                        ),
                      ),
                    Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 24,
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

      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: isNetwork
            ? Image.network(path, width: 44, height: 44, fit: BoxFit.cover)
            : Image.file(File(path), width: 44, height: 44, fit: BoxFit.cover),
      );
    }

    // 2x2 mini grid
    return SizedBox(
      width: 44,
      height: 44,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: count,
        itemBuilder: (_, i) => buildThumb(display[i]),
      ),
    );
  }

  bool _containsVideo(List<String> medias) =>
      medias.any((m) => isVideo(m.toString()));

  // ===========================================================================
  // PROGRESS OVERLAY
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
                ? (progress > 0
                    ? '${(progress * 100).toInt()}%'
                    : 'Uploading...')
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
          Text(
            'Failed to load',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STATUS ICON
  // ===========================================================================
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

  // ===========================================================================
  // REACTION BUBBLE
  // ===========================================================================
  Widget _buildReactionBubble(
      BuildContext context, Conversations message, bool isMine) {
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
            children: (message.reactions ?? [])
                .map<Widget>(
                  (emoji) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      '$emoji',
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
