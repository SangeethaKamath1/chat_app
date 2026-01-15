import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'helpers.dart';

class FullScreenMediaViewer extends StatefulWidget {
  final List<dynamic> medias;
  final int initialIndex;

  const FullScreenMediaViewer({
    super.key,
    required this.medias,
    required this.initialIndex,
  });

  @override
  State<FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<FullScreenMediaViewer> {
  late final PageController _pageController;

  VideoPlayerController? _videoController;
  int? _activeVideoIndex;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _initVideo(widget.initialIndex);
  }

  void _initVideo(int index) {
    final media = widget.medias[index];

    // Dispose previous controller
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    _activeVideoIndex = null;

    if (isVideo(media)) {
      _activeVideoIndex = index;

      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(media),
      )..initialize().then((_) {
          if (!mounted) return;
          setState(() {});
          _videoController?.play();
        });
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.medias.length,
          onPageChanged: _initVideo,
          itemBuilder: (context, index) {
            final media = widget.medias[index];
            final bool isRemote = media.startsWith('http');

            // ---------- VIDEO ----------
            if (isVideo(media) && _activeVideoIndex == index) {
              return Center(
                child: _videoController != null &&
                        _videoController!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio:
                            _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                    : const CircularProgressIndicator(
                        color: Colors.white,
                      ),
              );
            }

            // ---------- IMAGE ----------
            return Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: isRemote
                    ? Image.network(
                        media,
                        fit: BoxFit.contain,
                      )
                    : Image.file(
                        File(media),
                        fit: BoxFit.contain,
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
