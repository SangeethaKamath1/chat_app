import 'package:livekit_client/livekit_client.dart';

class LKUiParticipant {
  final String sid;
  final String name;
  final bool isLocal;
  final bool isSpeaking;
  final VideoTrack? videoTrack;

  final bool isVideoMuted; // ✅ NEW
  final bool hasVideoPub;  // ✅ NEW (track published exists)

  LKUiParticipant({
    required this.sid,
    required this.name,
    required this.isLocal,
    required this.isSpeaking,
    required this.videoTrack,
    required this.isVideoMuted,
    required this.hasVideoPub,
  });
}

