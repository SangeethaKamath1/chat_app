import 'dart:async';
import 'dart:io';
import 'package:amu_alumni/amu_alumni.dart';
import 'package:chat_app/chat_app.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/chat_app_routes.dart';
import '../../chat/chat_websocket/group_chat_web_socket_service.dart';
import '../../audio_call/service/speakerphone_service.dart';

class GroupIncomingCallScreen extends StatefulWidget {
  const GroupIncomingCallScreen({super.key});

  @override
  State<GroupIncomingCallScreen> createState() => _GroupIncomingCallScreenState();
}

class _GroupIncomingCallScreenState extends State<GroupIncomingCallScreen> {
  late final GroupChatWebSocketService groupSocket;
  late final SpeakerphoneService speakerSvc;

  bool fromNotification = false;

  String callId = "";
  String callerId = "";
  String callerName = "";
  bool isVideo = false;

  Timer? _autoDismissTimer;
  bool _handled = false; // prevents double actions

  static const int _incomingTimeoutSeconds = 30; // change as needed

  @override
  void initState() {
    super.initState();

    final args = (Get.arguments ?? {}) as Map;

    fromNotification = (args['fromNotification'] ?? false) as bool;

    callId = (args["callID"] ?? "").toString();
    callerId = (args["callerId"] ?? "").toString();
    callerName = (args["callerName"] ?? "Group Call").toString();
    isVideo = (args["isVideo"] ?? false) as bool;

    groupSocket = Get.isRegistered<GroupChatWebSocketService>()
        ? Get.find<GroupChatWebSocketService>()
        : Get.put(GroupChatWebSocketService());

    speakerSvc = Get.find<SpeakerphoneService>();

    debugPrint("📲 [GROUP_INCOMING] init callId=$callId caller=$callerName video=$isVideo");

    // Ensure callId stored
    groupSocket.callID.value = callId;

    // Ensure websocket connected
    groupSocket.ensureConnectedFromRoomId(callId);

    // Start ringtone only if not from notification
    if (!fromNotification) {
      speakerSvc.startRingtone(isIncoming: true);
    }

    // ✅ Auto-dismiss timer
    _startAutoDismissTimer();
  }

  void _startAutoDismissTimer() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(const Duration(seconds: _incomingTimeoutSeconds), () async {
      if (_handled) return;
      _handled = true;

      debugPrint("⏳ [GROUP_INCOMING] Timeout ($_incomingTimeoutSeconds s) -> auto dismiss callId=$callId");

      await speakerSvc.stopRingtone();

      if (Platform.isIOS) {
        await CallKitBridge.dismissIncoming(callId);
      }

      // Optional: notify server "missed" (only if you have/need it)
      // groupSocket.emitGroupCallMissed(callId: callId);

      if (!mounted) return;
      fromNotification ? Get.offAllNamed(AppRoutes.home) : Get.back();
    });
  }

  Future<void> _handleReject() async {
    if (_handled) return;
    _handled = true;
    _autoDismissTimer?.cancel();

    debugPrint("❌ [GROUP_INCOMING] Reject pressed callId=$callId");
    await speakerSvc.stopRingtone();

    if (Platform.isIOS) {
      await CallKitBridge.dismissIncoming(callId);
    }

    if (!mounted) return;
    fromNotification ? Get.offAllNamed(AppRoutes.home) : Get.back();
  }

  Future<void> _handleAccept() async {
    if (_handled) return;
    _handled = true;
    _autoDismissTimer?.cancel();

    debugPrint("✅ [GROUP_INCOMING] Accept pressed callId=$callId");
    // await speakerSvc.stopRingtone();

    groupSocket.callID.value = callId;

    if (Platform.isIOS) {
      await CallKitBridge.acceptCallFromApp(callId);
    }

    //groupSocket.emitGroupCallAccepted(callId: callId);

    if (!mounted) return;
    Get.offNamed(
      ChatAppRoutes.groupCallScreen,
      arguments: {
        "isCaller": false,
        "callID": callId,
        "isVideo": isVideo,
      },
    );
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    speakerSvc.stopRingtone();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 160,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Icon(Icons.group, color: Colors.white70, size: 100),
                  const SizedBox(height: 16),
                  Text(
                    callerName.isNotEmpty ? callerName : "Group Call",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isVideo ? "Incoming group video call..." : "Incoming group audio call...",
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Auto closing in $_incomingTimeoutSeconds seconds",
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _actionButton(
                    icon: Icons.call_end,
                    color: Colors.red,
                    label: "Reject",
                    onPressed: () => _handleReject(),
                  ),
                  _actionButton(
                    icon: Icons.call,
                    color: Colors.green,
                    label: "Accept",
                    onPressed: () => _handleAccept(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }
}
