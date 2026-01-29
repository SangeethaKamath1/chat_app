// import 'package:flutter/material.dart';
// import 'package:livekit_client/livekit_client.dart';

// /// Widget to render a LiveKit VideoTrack
// class LiveKitVideoTrackWidget extends StatelessWidget {
//   final VideoTrack track;

//   const LiveKitVideoTrackWidget({super.key, required this.track});

//   @override
//   Widget build(BuildContext context) {
//     // When muted or no track, show a placeholder
//     if (track.muted) {
//       return Container(
//         color: Colors.grey.shade900,
//         child: const Center(
//           child: Icon(Icons.videocam_off, color: Colors.white70, size: 40),
//         ),
//       );
//     }

//     return VideoTrackRenderer(
//       track,
//       mirrorMode: VideoViewMirrorMode.auto,
//     );
//   }
// }
