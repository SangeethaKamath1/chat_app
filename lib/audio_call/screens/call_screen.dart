import 'dart:async';
import 'dart:io';

import 'package:amu_alumni/amu_alumni.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../chat_app.dart';
import '../controller/call_session_controller.dart';
import '../service/speakerphone_service.dart';
import '../../chat/chat_websocket/chat_web_socket_service.dart';
import '../service/livekit_one_to_one_call_service.dart';

class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  final CallSessionController session = Get.find();
  final LiveKitOneToOneCallService livekit = Get.find();
  final SpeakerphoneService speakerSvc = Get.find();
  final ChatWebSocketService signaling = Get.find();

  bool _initialized = false;

  Timer? _callTimeoutTimer;
  static const Duration _callTimeoutDuration = Duration(seconds: 30);
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();

    final args = (Get.arguments ?? {}) as Map;

    session.hydrate(
      roomId: (args["roomId"] ?? args["callId"] ?? "").toString(),
      isCaller: (args["isCaller"] ?? false) as bool,
      fromNotification: (args["fromNotification"] ?? false) as bool,
      peerId: (args["peerId"] ?? "").toString(),
      peerName: (args["peerName"] ?? "").toString(),
      isVideo: args.containsKey("isVideo") ? args["isVideo"] as bool : true,
    );
    
    debugPrint("📱 VoiceCallScreen init - isCaller: ${session.isCaller.value}, isVideo: ${session.isVideo.value}, roomId: ${session.roomId.value}");
    
    livekit.setRole(isCaller: session.isCaller.value);
    livekit.setCallType(isVideo: session.isVideo.value);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCall();
    });
  }

  @override
  void dispose() {
    _cancelCallTimeout();
    super.dispose();
  }

  Future<void> _initializeCall() async {
    if (_initialized) return;

    debugPrint("🔗 Initializing call - isVideo: ${session.isVideo.value}, isCaller: ${session.isCaller.value}");

    if (session.isCaller.value) {
      speakerSvc.startRingtone(isIncoming: false);
      _startCallTimeout();
    }
    
    debugPrint("🔗 Joining room: ${session.roomId.value}");
    await livekit.joinCall(session.roomId.value);

    _initialized = true;
  }

  void _startCallTimeout() {
    _callTimeoutTimer?.cancel();
    _timedOut = false;

    _callTimeoutTimer = Timer(_callTimeoutDuration, () async {
      if (!mounted) return;

      if (livekit.isConnected.value || livekit.remoteParticipant.value != null) {
        debugPrint("⏰ Timeout cancelled - call established");
        return;
      }

      _timedOut = true;

      final callId = session.roomId.value;
      signaling.callCancelled(callId);
      speakerSvc.stopRingtone();

      debugPrint("⏰ Call timed out");
      Get.snackbar("No Answer", "Call timed out");

      session.fromNotification.value
          ? Get.offAllNamed(AppRoutes.home)
          : Get.back();
    });
  }

  void _cancelCallTimeout() {
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if ((livekit.isConnected.value || livekit.remoteParticipant.value != null) && !_timedOut) {
          _cancelCallTimeout();
          speakerSvc.stopRingtone();
        }

        session.isMuted.value = livekit.isMicMuted.value;
        session.isSpeakerOn.value = livekit.isSpeakerOn.value;
        session.isVideoMuted.value = livekit.isCameraOff.value;

        return Stack(
          children: [
            // REMOTE VIDEO
            if (session.isVideo.value)
              Positioned.fill(
                child: _buildRemoteVideo(),
              )
            else
              const Positioned.fill(
                child: ColoredBox(color: Colors.black),
              ),

            // TOP INFO
            Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    session.peerName.value.isEmpty ? "Call" : session.peerName.value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getCallStatus(),
                    style: TextStyle(color: _getStatusColor()),
                  ),
                ],
              ),
            ),

            // LOCAL PREVIEW
            if (session.isVideo.value)
              Positioned(
                right: 14,
                top: 120,
                child: SizedBox(
                  width: 110,
                  height: 160,
                  child: _buildLocalVideo(),
                ),
              ),

            // CONTROLS
            Positioned(
              left: 0,
              right: 0,
              bottom: 90,
              child: _buildControls(),
            ),
          ],
        );
      }),
    );
  }

  // ✅ NEW: Simplified using track observables
  Widget _buildRemoteVideo() {
    final remote = livekit.remoteParticipant.value;
    
    if (remote == null) {
      debugPrint("🎥 [UI] No remote participant yet");
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Icon(Icons.account_circle, size: 100, color: Colors.white54),
        ),
      );
    }

    // ✅ Use the observable instead of querying publications
    final remoteTrack = livekit.remoteVideoTrack.value;
    final isRemoteMuted = livekit.isRemoteVideoMuted.value;

    debugPrint("🎥 [UI] Remote track: ${remoteTrack?.runtimeType}, muted: $isRemoteMuted");

    if (remoteTrack == null || isRemoteMuted) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Icon(
            isRemoteMuted ? Icons.videocam_off : Icons.account_circle,
            size: 100,
            color: Colors.white54,
          ),
        ),
      );
    }

    debugPrint("🎥 [UI] Rendering remote video track");
    return VideoTrackRenderer(
      remoteTrack,
      fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    );
  }

  // ✅ NEW: Simplified using track observables
  Widget _buildLocalVideo() {
    // ✅ Use the observable instead of querying publications
    final localTrack = livekit.localVideoTrack.value;

    debugPrint("🎥 [UI] Local track: ${localTrack?.runtimeType}");

    if (localTrack == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.videocam_off, color: Colors.white54),
        ),
      );
    }

    debugPrint("🎥 [UI] Rendering local video track");
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: VideoTrackRenderer(
        localTrack,
        mirrorMode: VideoViewMirrorMode.auto,
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _btn(
          icon: session.isMuted.value ? Icons.mic_off : Icons.mic,
          onTap: () {
            livekit.toggleMute();
          },
        ),
        if (session.isVideo.value)
          _btn(
            icon: session.isVideoMuted.value ? Icons.videocam_off : Icons.videocam,
            onTap: livekit.toggleCamera,
          ),
        if (session.isVideo.value)
          _btn(
            icon: Icons.cameraswitch,
            onTap: livekit.switchCamera,
          ),
        _btn(
          icon: Icons.call_end,
          color: Colors.red,
          onTap: () async {
            final callId = session.roomId.value;

            if (livekit.remoteParticipant.value == null) {
              signaling.callCancelled(callId);
            } else {
              signaling.callEnded(callId);
            }

            speakerSvc.stopRingtone();
            await livekit.leaveCall();

            session.fromNotification.value
                ? Get.offAllNamed(AppRoutes.home)
                : Get.back();
          },
        ),
      ],
    );
  }

  Widget _btn({
    required IconData icon,
    Color color = Colors.white,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        height: 64,
        width: 64,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black54,
        ),
        child: Icon(icon, color: color),
      ),
    );
  }

  String _getCallStatus() {
    if (livekit.isConnected.value && livekit.remoteParticipant.value != null) {
      return "Connected";
    }

    if (livekit.isConnected.value && livekit.remoteParticipant.value == null) {
      return session.isCaller.value ? "Waiting for answer…" : "Connecting…";
    }

    if (session.isCaller.value && !livekit.isConnected.value) {
      return "Calling…";
    }

    if (!session.isCaller.value && !livekit.isConnected.value) {
      return "Joining…";
    }

    return "Connecting…";
  }

  Color _getStatusColor() {
    if (livekit.isConnected.value && livekit.remoteParticipant.value != null) {
      return Colors.green;
    }
    return Colors.grey;
  }
}