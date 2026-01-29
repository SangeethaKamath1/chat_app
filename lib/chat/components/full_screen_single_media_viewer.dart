import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'helpers.dart';
import 'video_cache.dart';

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
  VideoPlayerController? _controller;

  bool _loading = false;
  bool _readyToShowVideo = false;

  final double bufferThresholdPercent = 5.0;

  bool get _isRemote => widget.media.startsWith('http');

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (!isVideo(widget.media)) return;

    setState(() => _loading = true);

    try {
      late final VideoPlayerController c;

      if (_isRemote) {
        final file = await VideoCache.get(widget.media); // ✅ cached
        c = VideoPlayerController.file(file);
      } else {
        c = VideoPlayerController.file(File(widget.media));
      }

      _controller = c;
      await c.initialize();
      if (!mounted) return;

      c.setLooping(false); // change to true if you want loop
      c.play();
      c.addListener(_onTick);

      setState(() {
        _loading = false;
        _readyToShowVideo = !_isRemote; // local shows immediately
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _readyToShowVideo = false;
      });
    }
  }

  void _onTick() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (_readyToShowVideo) return;

    final buffered = c.value.buffered;
    final totalMs = c.value.duration.inMilliseconds.toDouble();
    if (buffered.isEmpty || totalMs <= 0) return;

    final bufferedEndMs = buffered.last.end.inMilliseconds.toDouble();
    final percent = (bufferedEndMs / totalMs) * 100.0;

    if (percent >= bufferThresholdPercent && mounted) {
      setState(() => _readyToShowVideo = true);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: isVideo(widget.media) ? _buildVideo() : _buildImage(),
        ),
      ),
    );
  }

  Widget _buildVideo() {
    final c = _controller;

    if (_loading || c == null || !c.value.isInitialized) {
      return const CircularProgressIndicator(color: Colors.white);
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: c.value.aspectRatio,
          child: VideoPlayer(c),
        ),

        if (!_readyToShowVideo || c.value.isBuffering)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildImage() {
    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: _isRemote
          ? Image.network(widget.media, fit: BoxFit.contain)
          : Image.file(File(widget.media), fit: BoxFit.contain),
    );
  }
}
