// group_call_screen.dart (UPDATED UI: show avatar when camera muted)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../audio_call/service/speakerphone_service.dart';
import '../../chat/chat_websocket/group_chat_web_socket_service.dart';
import '../../model/lk_ui_participant.dart';
import '../service/livekit_group_audio_service.dart';
import '../../chat_app.dart';

// If you use CallKit:
import 'package:amu_alumni/amu_alumni.dart';

class GroupCallScreen extends StatefulWidget {
  const GroupCallScreen({super.key});

  @override
  State<GroupCallScreen> createState() => _GroupCallScreenState();
}

class _GroupCallScreenState extends State<GroupCallScreen> {
  final svc = Get.find<LiveKitGroupAudioService>();
  final socket = Get.find<GroupChatWebSocketService>();
  final speakerSvc = Get.find<SpeakerphoneService>();

  late final bool isCaller;
  late final bool isVideo;
  late final bool fromNotification;
  late final String callId;

  bool _joined = false;

  @override
  void initState() {
    super.initState();

    final args = (Get.arguments ?? {}) as Map;
    isCaller = args["isCaller"] ?? false;
    isVideo = args["isVideo"] ?? false;
    fromNotification = args["fromNotification"] ?? false;
    callId = args["callID"];

    socket.callID.value = callId;
    socket.ensureConnectedFromRoomId(callId);

    svc.setRole(isCaller: isCaller);
    svc.setCallType(isVideo: isVideo);

    if (isCaller) speakerSvc.startRingtone(isIncoming: false);

    _join();
  }

  Future<void> _join() async {
    if (_joined) return;
    _joined = true;

    await svc.joinGroupAudio(callId);

    if (isCaller) {
      svc.startNoAnswerTimeout(
        callId: callId,
        seconds: 30,
        onTimeout: () async {
          fromNotification ? Get.offAllNamed(AppRoutes.home) : Get.back();
        },
      );
    }
  }

  @override
  void dispose() {
    speakerSvc.stopRingtone();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Obx(() {
          final list = svc.participants;

          return Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        svc.isConnected.value
                            ? "Group call connected ✅"
                            : (isCaller ? "Calling…" : "Joining…"),
                        style: TextStyle(
                          color: svc.isConnected.value ? Colors.green : Colors.orange,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: isVideo ? _videoGrid(list) : _audioList(list),
              ),
              _controls(),
            ],
          );
        }),
      ),
    );
  }

  Widget _videoGrid(List<LKUiParticipant> participants) {
    if (participants.isEmpty) {
      return const Center(
        child: Text("Connecting…", style: TextStyle(color: Colors.white)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: participants.length,
      itemBuilder: (_, i) {
        final u = participants[i];

        final showVideo = u.videoTrack != null && !u.isVideoMuted;

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (showVideo)
                VideoTrackRenderer(u.videoTrack!)
              else
                Container(
                  color: Colors.grey.shade900,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_circle, size: 64, color: Colors.grey.shade700),
                        const SizedBox(height: 8),
                        if (u.hasVideoPub && u.isVideoMuted)
                          const Text("Camera off", style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),

              // name overlay
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (u.isSpeaking)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.volume_up, color: Colors.green, size: 16),
                        ),
                      Text(
                        (u.name.trim().isNotEmpty) ? u.name : (u.isLocal ? "You" : "Guest"),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _audioList(List<LKUiParticipant> participants) {
    if (participants.isEmpty) {
      return const Center(
        child: Text("Connecting…", style: TextStyle(color: Colors.white)),
      );
    }

    return ListView.separated(
      itemCount: participants.length,
      separatorBuilder: (_, __) => Divider(color: Colors.grey.shade900, height: 1),
      itemBuilder: (_, i) {
        final u = participants[i];
        final name = (u.name.trim().isNotEmpty) ? u.name : (u.isLocal ? "You" : "Guest");

        return ListTile(
          tileColor: Colors.transparent,
          leading: const Icon(Icons.account_circle, color: Colors.white),
          title: Text(name, style: const TextStyle(color: Colors.white)),
          trailing: u.isSpeaking ? const Icon(Icons.volume_up, color: Colors.green) : null,
        );
      },
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18, top: 8),
      child: Obx(() {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _btn(
              icon: svc.isMicMuted.value ? Icons.mic_off : Icons.mic,
              color: svc.isMicMuted.value ? Colors.red : Colors.white,
              onTap: () => svc.toggleMute(),
            ),
            if (isVideo)
              _btn(
                icon: svc.isCameraOff.value ? Icons.videocam_off : Icons.videocam,
                color: svc.isCameraOff.value ? Colors.red : Colors.white,
                onTap: () => svc.toggleCamera(),
              ),
            if (isVideo)
              _btn(
                icon: Icons.cameraswitch,
                color: Colors.white,
                onTap: () => svc.switchCamera(),
              ),
            _btn(
              icon: Icons.call_end,
              color: Colors.red,
              onTap: _leave,
            ),
          ],
        );
      }),
    );
  }

  Future<void> _leave() async {
    await speakerSvc.stopRingtone();
      if (Platform.isIOS) {
      await CallKitBridge.endCall(callId);
    }

    if (isCaller && !svc.anyRemoteJoined) {
      socket.emitGroupCallCancelled(callId: callId);
    } else {
      socket.emitGroupCallLeft(callId: callId);
    }

  

    await svc.leaveGroupAudio();

    fromNotification ? Get.offAllNamed(AppRoutes.home) : Get.back();
  }

  Widget _btn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
