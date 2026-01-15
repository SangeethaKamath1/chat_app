import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'helpers.dart';

class FullScreenSingleMediaViewer extends StatefulWidget {
  final String media;

  const FullScreenSingleMediaViewer({
    super.key,
    required this.media,
  });

  @override
  State<FullScreenSingleMediaViewer> createState() =>
      _FullScreenSingleMediaViewerState();
}

class _FullScreenSingleMediaViewerState
    extends State<FullScreenSingleMediaViewer> {
  VideoPlayerController? _videoController;

  bool get _isRemote => widget.media.startsWith('http');

  @override
  void initState() {
    super.initState();
    _initMedia();
  }

  void _initMedia() {
    if (isVideo(widget.media)) {
      _videoController = _isRemote
          ? VideoPlayerController.networkUrl(
              Uri.parse(widget.media),
            )
          : VideoPlayerController.file(
              File(widget.media),
            )
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() {});
          _videoController?.play();
        });
    }
  }

  @override
  void dispose() {
    _videoController?.pause();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: isVideo(widget.media)
              ? _buildVideo()
              : _buildImage(),
        ),
      ),
    );
  }

  // ---------- VIDEO ----------
  Widget _buildVideo() {
    if (_videoController == null ||
        !_videoController!.value.isInitialized) {
      return const CircularProgressIndicator(
        color: Colors.white,
      );
    }

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: VideoPlayer(_videoController!),
    );
  }

  // ---------- IMAGE ----------
  Widget _buildImage() {
    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: _isRemote
          ? Image.network(
              widget.media,
              fit: BoxFit.contain,
            )
          : Image.file(
              File(widget.media),
              fit: BoxFit.contain,
            ),
    );
  }
}
