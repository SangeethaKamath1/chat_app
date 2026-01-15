import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../service/livekit_group_audio_service.dart';
import '../../chat/chat_websocket/group_chat_web_socket_service.dart';
import '../../audio_call/service/speakerphone_service.dart';

class GroupCallScreen extends StatefulWidget {
  const GroupCallScreen({super.key});

  @override
  State<GroupCallScreen> createState() => _GroupAudioCallScreenState();
}

class _GroupAudioCallScreenState extends State<GroupCallScreen> {
  final svc = Get.find<LiveKitGroupAudioService>();
  final groupCallWebSocket = Get.find<GroupChatWebSocketService>();
  final speakerSvc = Get.find<SpeakerphoneService>();

  bool _joined = false;
   bool isCaller=false;

  @override
  void initState() {
    super.initState();

   final args = (Get.arguments ?? {}) as Map;
final isCaller = (args["isCaller"] ?? false) as bool;

// ✅ prefer explicit callId
final callId = (args["callId"] as String?) ?? groupCallWebSocket.roomId.value;
    debugPrint("📞 GroupCallScreen callId: ${groupCallWebSocket.roomId.value}, isCaller=$isCaller");

    // Tell LiveKit service who we are (caller/callee) for ringtone stop logic
    svc.setRole(isCaller: isCaller);

    // ✅ Start tone immediately on entering screen
    _startTone();

    // ✅ Join LiveKit
    _join(callId);
  }

  Future<void> _startTone() async {
    try {
      // Caller => outgoing (ringback), Callee => incoming ringtone
      await speakerSvc.startRingtone(isIncoming: !isCaller);
    } catch (e) {
      debugPrint("❌ startRingtone error: $e");
    }
  }

  Future<void> _join(callId) async {
    if (_joined) return;
    _joined = true;

    try {
      await svc.joinGroupAudio(callId);
    } catch (e) {
      _joined = false;

      // ✅ Stop tone if join fails
      await speakerSvc.stopRingtone();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Join failed: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    // ✅ Ensure ringtone stops no matter what
    speakerSvc.stopRingtone();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Obx(() {
          final connected = svc.isConnected.value;
          final muted = svc.isMicMuted.value;
          final speaker = svc.isSpeakerOn.value;
          final participants = svc.participants;

          return Column(
            children: [
              const SizedBox(height: 24),
              Text(
                connected ? "Group audio connected ✅" : (isCaller ? "Calling…" : "Ringing…"),
                style: TextStyle(
                  color: connected ? Colors.green : Colors.orange,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (_, i) {
                    final p = participants[i];
                    final isActive = p.isSpeaking;
                    final name = p.isLocal ? "${p.name} (You)" : p.name;

                    return Row(
                      children: [
                        Icon(Icons.account_circle,
                            color: isActive ? Colors.green : Colors.white70, size: 34),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                        if (isActive) const Icon(Icons.graphic_eq, color: Colors.green),
                      ],
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                  itemCount: participants.length,
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _btn(
                      icon: muted ? Icons.mic_off : Icons.mic,
                      label: muted ? "Unmute" : "Mute",
                      color: muted ? Colors.red : Colors.white,
                      onTap: () => svc.toggleMute(),
                    ),
                    _btn(
                      icon: speaker ? Icons.volume_up : Icons.hearing,
                      label: speaker ? "Speaker" : "Earpiece",
                      color: speaker ? Colors.green : Colors.white,
                      onTap: () => svc.setSpeakerphone(!speaker),
                    ),
                    _btn(
                      icon: Icons.call_end,
                      label: "Leave",
                      color: Colors.red,
                      onTap: () async {
                        await speakerSvc.stopRingtone();
                        await svc.leaveGroupAudio();
                        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _btn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 64,
            height: 64,
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
}
