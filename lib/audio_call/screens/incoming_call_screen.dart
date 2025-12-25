import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../chat/controller/chat_controller.dart';
import '../../routes/chat_app_routes.dart';

import '../service/webrtc_service.dart';

class IncomingCallScreen extends StatefulWidget {
  final String roomId;
final String callerName;

  const IncomingCallScreen({
    super.key,
    required this.roomId,
    required this.callerName,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
    late final WebRTCService webRTCService;
      final ChatController chatController = Get.find<ChatController>();
      @override
  void initState() {
    super.initState();
    webRTCService = Get.find<WebRTCService>();
    webRTCService.speakerphoneService.startRingtone(isIncoming: true);
  }

  @override
  void dispose() {
    webRTCService.speakerphoneService.stopRingtone();
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
            // Caller Info
            Positioned(
              top: 160,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Icon(Icons.account_circle, color: Colors.white70, size: 100),
                  const SizedBox(height: 16),
                  Text(
                    widget.callerName,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text("Incoming call...", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            ),

            // Accept/Reject buttons
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reject
                  _buildActionButton(
                    icon: Icons.call_end,
                    color: Colors.red,
                    label: "Reject",
                    onPressed: () {
                      chatController.chatWebSocket!.callRejected(widget.roomId);
                       webRTCService.speakerphoneService.stopRingtone();
                      Get.back();
                    },
                  ),

                  // Accept - FIXED: Remove createAnswer() call
                  _buildActionButton(
                    icon: Icons.call,
                    color: Colors.green,
                    label: "Accept",
                    onPressed: () async {
                      chatController.chatWebSocket!.callAccepted(widget.roomId);
                      webRTCService.speakerphoneService.stopRingtone();
                      chatController.roomId = widget.roomId;
                      chatController.callStatus.value = "Connecting...";

                      // ✅ FIX: Only navigate to call screen
                      // The WebRTC answer will be created when we receive the offer
                      Get.offNamed(ChatAppRoutes.callScreen);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
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