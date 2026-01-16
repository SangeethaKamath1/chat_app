import 'dart:io';

import 'package:amu_alumni/amu_alumni.dart';
import 'package:chat_app/chat_app.dart';
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
    bool fromNotification = false;

  String callId = "";
  bool isVideo = false;

  @override
void initState() {
  super.initState();

  debugPrint("group call initstate:${Get.arguments}");

  final args = (Get.arguments ?? {}) as Map;

  isCaller = (args["isCaller"] ?? false) as bool;
  isVideo = (args["isVideo"] ?? false) as bool;
  fromNotification = (args['fromNotification'] ?? false) as bool;

  // ✅ Prefer explicit callId
  callId = (args["callID"] as String?) ?? groupCallWebSocket.callID.value;

  debugPrint(
    "📞 GroupCallScreen callId=$callId socketCallId=${groupCallWebSocket.callID.value}",
  );

  // ─────────────────────────────────────────────
  // ✅ ENSURE GROUP SOCKET CONNECTED (KEY PART)
  // ─────────────────────────────────────────────
  groupCallWebSocket.callID.value = callId;
  groupCallWebSocket.ensureConnectedFromRoomId(callId);

  // Tell LiveKit service who we are
  svc.setRole(isCaller: isCaller);

  // Start ringtone only for caller
  if (isCaller) {
    _startTone();
  }

  // Join LiveKit
  _join(callId);

  // No-answer timeout (caller only)
  if (isCaller) {
    svc.startNoAnswerTimeout(
      callId: callId,
      seconds: 30,
      onTimeout: () async {
        if (mounted) {
          fromNotification
              ? Get.offAllNamed(AppRoutes.home)
              : Get.back();
        }
      },
    );
  }
}

  Future<void> _startTone() async {
    try {
      // Caller => outgoing (ringback), Callee => incoming ringtone
      await speakerSvc.startRingtone(isIncoming: false);
    } catch (e) {
      debugPrint("❌ startRingtone error: $e");
    }
  }

Future<void> _join(String callId) async {
  debugPrint("══════════════════════════════════════════════");
  debugPrint("📞 [GROUP_JOIN_UI] _join() called");
  debugPrint("📌 callId = $callId");
  debugPrint("📌 _joined(before) = $_joined");
  debugPrint("══════════════════════════════════════════════");

  if (_joined) {
    debugPrint("⚠️ [GROUP_JOIN_UI] Already joined, skipping join()");
    return;
  }

  if (callId.trim().isEmpty) {
    debugPrint("❌ [GROUP_JOIN_UI] callId is EMPTY ❌ join cancelled");
    return;
  }

  _joined = true;
  debugPrint("✅ [GROUP_JOIN_UI] _joined set to true, calling svc.joinGroupAudio()...");

  try {
    await svc.joinGroupAudio(callId);
    debugPrint("✅ [GROUP_JOIN_UI] svc.joinGroupAudio() SUCCESS callId=$callId");
  } catch (e, st) {
    _joined = false;

    debugPrint("❌ [GROUP_JOIN_UI] svc.joinGroupAudio() FAILED callId=$callId");
    debugPrint("❌ Error: $e");
    debugPrint("🧵 Stack: $st");

    // ✅ Stop tone if join fails
    debugPrint("🔕 [GROUP_JOIN_UI] Stopping ringtone due to join failure...");
    await speakerSvc.stopRingtone();

    if (mounted) {
      debugPrint("📢 [GROUP_JOIN_UI] Showing SnackBar for join failure");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Join failed: $e')),
      );
    } else {
      debugPrint("⚠️ [GROUP_JOIN_UI] Widget not mounted, SnackBar skipped");
    }
  }

  debugPrint("══════════════════════════════════════════════");
  debugPrint("📞 [GROUP_JOIN_UI] _join() END callId=$callId _joined=$_joined");
  debugPrint("══════════════════════════════════════════════");
}

  @override
  void dispose() {
    svc.stopNoAnswerTimeout();
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
                        debugPrint("group call leave pressed:${callId},${groupCallWebSocket.callID.value}");
                        await speakerSvc.stopRingtone();
                        debugPrint("group call perticipants:${svc.participants.length},${svc.activeSpeakerSids.length},${svc.anyRemoteJoined}");
               if (isCaller && !svc.anyRemoteJoined) {
  groupCallWebSocket.emitGroupCallCancelled(callId: callId);
} else {
  groupCallWebSocket.emitGroupCallLeft(callId: callId);
}
                       if (Platform.isIOS) {
              await CallKitBridge.endCall(callId);
            }
                      
                        fromNotification ? Get.offAllNamed(AppRoutes.home) : Get.back();
                        await svc.leaveGroupAudio();
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
