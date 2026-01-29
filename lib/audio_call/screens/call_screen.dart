import 'dart:async';
import 'dart:io';

import 'package:amu_alumni/amu_alumni.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import '../../chat_app.dart';
import '../controller/call_session_controller.dart';


class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  final CallSessionController session = Get.find<CallSessionController>();
  final WebRTCService webrtc = Get.find<WebRTCService>();
  final ChatWebSocketService signaling = Get.find<ChatWebSocketService>();

  bool _initialized = false;

  // ✅ TIMEOUT
  Timer? _callTimeoutTimer;
  static const Duration _callTimeoutDuration = Duration(seconds: 30);
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();

    final args = (Get.arguments ?? {}) as Map;
    final roomId = (args["roomId"] ?? args["callId"] ?? "").toString();
    final isCaller = (args["isCaller"] ?? false) as bool;
    final fromNotification = (args["fromNotification"] ?? false) as bool;

final blockedCall = (args["isBlocked"] ?? false) as bool;
final isBlockedBy = (args["isBlockedBy"]??false)as bool;
debugPrint("is balocked inside call screen:${blockedCall},${isBlockedBy}");
    final peerId = (args["peerId"] ?? args["callerId"] ?? "").toString();
    final peerName = (args["peerName"] ?? args["callerName"] ?? "").toString();

    // ✅ default to VIDEO if not passed
    final isVideo =
        (args.containsKey("isVideo") ? (args["isVideo"] as bool) : true);
    session.isVideo.value = isVideo;
    
    

    debugPrint(
        "inside call screen isVideo=${session.isVideo.value}, hasKey=${args.containsKey("isVideo") == true}");

    if (roomId.isNotEmpty) {
      session.hydrate(
        roomId: roomId,
        isCaller: isCaller,
        fromNotification: fromNotification,
        peerId: peerId,
        peerName: peerName,
        isVideo: isVideo,
      );
    }
   // _startCallTimeout();
    if (blockedCall || isBlockedBy) {
      webrtc.speakerphoneService.startRingtone(isIncoming: false);
  // optional: show UI briefly, then exit
  Future.delayed(const Duration(seconds: 5), () async {
    if (!mounted) return;

    try {
      await webrtc.endCall();
      
    } catch (_) {}

    webrtc.speakerphoneService.stopRingtone();

   // Get.snackbar("Call ended", ""); // or remove if you don’t want snackbar
    Get.back();
  });

  // ✅ IMPORTANT: don't initialize signaling or create offer
  return;
}

    _initializeCall();
  }

  @override
  void dispose() {
    _cancelCallTimeout();
    super.dispose();
  }

  int _extractConversationIdFromRoomId(String roomId) {
    final first = roomId.split("_").first;
    return int.tryParse(first) ?? 0;
  }

  Future<void> _ensureSignalingReady() async {
    final rid = session.roomId.value;
    if (rid.isEmpty) return;

    final conversationId = _extractConversationIdFromRoomId(rid);
    if (conversationId == 0) return;

    signaling.setRoom(rid);
    signaling.connect(conversationId);
  }

void _startCallTimeout() {
  debugPrint("⏱️ Call timeout started (${_callTimeoutDuration.inSeconds}s)");

  _callTimeoutTimer?.cancel();
  _timedOut = false;

  _callTimeoutTimer = Timer(_callTimeoutDuration, () async {
    debugPrint("⏱️ Call timeout fired");

    if (!mounted) {
      debugPrint("❌ Widget not mounted, aborting timeout");
      return;
    }

    // ✅ If already connected/accepted, do nothing
    if (webrtc.isConnected || webrtc.isCallAccepted.value) {
      debugPrint("✅ Call already connected/accepted — timeout ignored");
      return;
    }

    _timedOut = true;
    debugPrint("⛔ Call timed out (no answer)");

    final callId = session.roomId.value;
    debugPrint("📞 Timeout callId: $callId");

    if (callId.isNotEmpty) {
      try {
        debugPrint("📡 Sending callCancelled signal");
        signaling.callCancelled(callId);
      } catch (e) {
        debugPrint("❌ callCancelled failed: $e");
      }
    }

    try {
      debugPrint("🔌 Ending WebRTC call locally");
      await webrtc.endCall();
    } catch (e) {
      debugPrint("❌ endCall failed: $e");
    }

    debugPrint("🔔 Stopping ringtone");
    webrtc.speakerphoneService.stopRingtone();

    Get.snackbar("No Answer", "Call timed out");

    if (session.fromNotification.value) {
      debugPrint("🏠 Navigating to home (from notification)");
      Get.offAllNamed(AppRoutes.home);
    } else {
      debugPrint("⬅️ Closing call screen");
      Get.back();
       //Get.offAllNamed(AppRoutes.home);
    }
  });
}

  void _cancelCallTimeout() {
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = null;
  }

  Future<void> _initializeCall() async {
    debugPrint("initialize called");
    if (_initialized) return;

    await _ensureSignalingReady();

    if (session.isCaller.value) {
      await webrtc.createOffer(session.isVideo.value);
      webrtc.speakerphoneService.startRingtone(isIncoming: false);
      _startCallTimeout();
    } 

    _initialized = true;

    // ✅ start timeout after setup
    //_startCallTimeout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        final isVideo = session.isVideo.value;

        // ✅ Cancel timeout once call is accepted/connected
        if ((webrtc.isConnected || webrtc.isCallAccepted.value) && !_timedOut) {
          _cancelCallTimeout();
          webrtc.speakerphoneService.stopRingtone();
        }

        return Stack(
          children: [
            // =========================
            // VIDEO BACKGROUND (remote)
            // =========================
            if (isVideo)
              Positioned.fill(
                child: RTCVideoView(
                  webrtc.remoteRenderer,
                  objectFit:
                      RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              )
            else
              const Positioned.fill(
                child: ColoredBox(color: Colors.black),
              ),

            // dark overlay for readability
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Container(
                  color: Colors.black.withOpacity(isVideo ? 0.15 : 0.0),
                ),
              ),
            ),

            // =========================
            // TOP INFO
            // =========================
            Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    session.peerName.value.isEmpty
                        ? "Call"
                        : session.peerName.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getCallStatus(),
                    style: TextStyle(color: _getStatusColor(), fontSize: 16),
                  ),
                ],
              ),
            ),

            // =========================
            // LOCAL PREVIEW (top-right)
            // =========================
            if (isVideo)
              Positioned(
                right: 14,
                top: 120,
                child: Container(
                  width: 110,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: RTCVideoView(
                    webrtc.localRenderer,
                    mirror: true,
                    objectFit:
                        RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),

            // =========================
            // CONTROLS
            // =========================
            Positioned(
              left: 0,
              right: 0,
              bottom: 90,
              child: _buildControls(isVideo: isVideo),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildControls({required bool isVideo}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _controlButton(
          icon: session.isMuted.value ? Icons.mic_off : Icons.mic,
          color: session.isMuted.value ? Colors.red : Colors.white,
          label: session.isMuted.value ? "Unmute" : "Mute",
          onTap: () {
            session.isMuted.toggle();
            webrtc.muteAudio(session.isMuted.value);
          },
        ),

        // ✅ Video-only buttons
        if (isVideo)
          _controlButton(
            icon: session.isVideoMuted.value
                ? Icons.videocam_off
                : Icons.videocam,
            color: session.isVideoMuted.value ? Colors.red : Colors.white,
            label: session.isVideoMuted.value ? "Cam Off" : "Cam On",
            onTap: () {
              final enable = session.isVideoMuted.value; // if muted -> enable
              webrtc.setVideoEnabled(enable);
            },
          ),

        if (isVideo)
          _controlButton(
            icon: Icons.cameraswitch,
            color: Colors.white,
            label: "Flip",
            onTap: () async => webrtc.switchCamera(),
          ),

        _controlButton(
          icon: session.isSpeakerOn.value ? Icons.volume_up : Icons.hearing,
          color: session.isSpeakerOn.value ? Colors.green : Colors.white,
          label: session.isSpeakerOn.value ? "Speaker" : "Earpiece",
          onTap: () {
            session.isSpeakerOn.toggle();
            webrtc.setSpeakerphoneOn(session.isSpeakerOn.value);
          },
        ),

        _controlButton(
          icon: Icons.call_end,
          color: Colors.red,
          label: "End",
          onTap: () async {
            debugPrint(
                "on call end inside call screen: fromNotification=${session.fromNotification.value}");

            _cancelCallTimeout();

            final callId = session.roomId.value;
            if (callId.isEmpty) return;

            if (Platform.isIOS) {
              await CallKitBridge.endCall(callId);
            }

            try {
              if (!webrtc.isCallAccepted.value) {
                signaling.callCancelled(callId);
              } else {
                signaling.callEnded(callId);
              }
            } catch (_) {}

            await webrtc.endCall();
            webrtc.speakerphoneService.stopRingtone();

            session.fromNotification.value
                ? Get.offAllNamed(AppRoutes.home)
                : Get.back();
          },
        ),
      ],
    );
  }

  Widget _controlButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  String _getCallStatus() {
    if (webrtc.isConnected) return "Connected ✅";
    if (webrtc.iceConnectionState ==
        RTCIceConnectionState.RTCIceConnectionStateChecking) {
      return "Connecting... 🔄";
    }
    if(webrtc.iceConnectionState == RTCIceConnectionState.RTCIceConnectionStateDisconnected){
      return "Call ended...";
    }
    return session.isCaller.value ? "Calling..." : "Joining...";
  }

  Color _getStatusColor() {
    if (webrtc.isConnected) return Colors.green;
    if (webrtc.iceConnectionState ==
        RTCIceConnectionState.RTCIceConnectionStateChecking) {
      return Colors.orange;
    }
    return Colors.grey;
  }
}
