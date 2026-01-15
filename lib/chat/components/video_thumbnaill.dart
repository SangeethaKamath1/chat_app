import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoThumbnail extends StatefulWidget {
  final String path;
  final double borderRadius;

  const VideoThumbnail({
    super.key,
    required this.path,
    this.borderRadius = 4,
  });

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();

    _controller = widget.path.startsWith('http')
        ? VideoPlayerController.network(widget.path)
        : VideoPlayerController.file(File(widget.path));

    _controller!.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _controller != null && _controller!.value.isInitialized
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                )
              : Container(color: Colors.black12),

          /// Play icon overlay
          const Center(
            child: Icon(
              Icons.play_circle_fill,
              size: 42,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
