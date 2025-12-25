import 'package:chat_app/chat/chat_websocket/chat_web_socket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

import '../../chat/controller/chat_controller.dart';
import '../service/webrtc_service.dart';
import 'package:amu_alumni/amu_alumni.dart';

class VoiceCallScreen extends StatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  final ChatController chatController = Get.find<ChatController>();
  final WebRTCService webRTCService = Get.find<WebRTCService>();
  bool _initialized = false;
  bool fromNotification=false;
  late bool _isCaller;

  @override
  void initState() {
    super.initState();
    
    // Determine if we're caller or callee from route arguments
    final arguments = Get.arguments ?? {};
    _isCaller = arguments['isCaller'] ?? false;
     fromNotification = Get.arguments['fromNotification']??false;
    
    _initializeCall();
  
  }

  Future<void> _initializeCall() async {
    if (_initialized) return;
    
    if (_isCaller) {
      debugPrint("📞 CALLER: Creating offer...");
//       await Helper.setAndroidAudioConfiguration(
//   AndroidAudioConfiguration(
//     manageAudioFocus: true,
//     androidAudioMode: AndroidAudioMode.inCommunication,
//     androidAudioFocusMode: AndroidAudioFocusMode.gain,
//     androidAudioAttributesUsageType:
//         AndroidAudioAttributesUsageType.voiceCommunication,
//     androidAudioAttributesContentType:
//         AndroidAudioAttributesContentType.speech,
//     forceHandleAudioRouting: true,
//   ),
// );
      await webRTCService.createOffer();
      webRTCService.speakerphoneService.startRingtone(isIncoming: false,);
    } else {
      debugPrint("📞 CALLEE: Waiting for offer from caller...");
      // Do nothing - we'll handle the offer when it arrives via WebSocket
    }
    
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Caller Info
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    chatController.name,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getCallStatus(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _isCaller ? "Caller" : "Callee",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 150,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _buildStatusRow("Connection:", 
                      webRTCService.isConnected ? "Connected" : "Connecting...",
                      webRTCService.isConnected ? Colors.green : Colors.orange,
                    ),
                    SizedBox(height: 8),
                    _buildStatusRow("ICE State:", 
                      webRTCService.iceConnectionState.toString().split('.').last,
                      _getIceStateColor(webRTCService.iceConnectionState),
                    ),
                    SizedBox(height: 8),
                    _buildStatusRow("Remote Audio:", 
                      webRTCService.hasRemoteAudio ? "Receiving" : "No Audio",
                      webRTCService.hasRemoteAudio ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ),
            ),

            // Call Controls
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: _buildCallControls(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 14)),
        SizedBox(width: 8),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCallControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: chatController.isMuted.value ? Icons.mic_off : Icons.mic,
          color: chatController.isMuted.value ? Colors.red : Colors.white,
          label: chatController.isMuted.value ? "Unmute" : "Mute",
          onPressed: () {
            chatController.isMuted.toggle();
            webRTCService.muteAudio(chatController.isMuted.value);
          },
        ),
        _buildControlButton(
          icon: chatController.isSpeakerOn.value ? Icons.volume_up : Icons.hearing,
          color: chatController.isSpeakerOn.value ? Colors.green : Colors.white,
          label: chatController.isSpeakerOn.value ? "Speaker" : "Earpiece",
          onPressed: () {
            chatController.isSpeakerOn.toggle();
            webRTCService.setSpeakerphoneOn(chatController.isSpeakerOn.value);
          },
        ),
        _buildControlButton(
          icon: Icons.call_end,
          color: Colors.red,
          label: "End",
          onPressed: () async {
            await webRTCService.endCall();
          webRTCService.speakerphoneService.stopRingtone();
            chatController.chatWebSocket!.callEnded(chatController.roomId);
            //Get.back();
           fromNotification?  Get.offAll(HomeScreen()):Get.back();
            
          },
        ),
      ],
    );
  }

  Widget _buildControlButton({
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
            height: 65,
            width: 65,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }
       
   String _getCallStatus() {
    if (webRTCService.isConnected) {
      return "Call Connected ✅";
    } else if (webRTCService.iceConnectionState == RTCIceConnectionState.RTCIceConnectionStateChecking) {
      return "Connecting... 🔄";
    } else {
      return _isCaller ? "Calling..." : "Waiting for call...";
    }
  }

  Color _getIceStateColor(RTCIceConnectionState state) {
    switch (state) {
      case RTCIceConnectionState.RTCIceConnectionStateConnected: return Colors.green;
      case RTCIceConnectionState.RTCIceConnectionStateChecking: return Colors.orange;
      case RTCIceConnectionState.RTCIceConnectionStateFailed: return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _getStatusColor() {
    if (webRTCService.isConnected) return Colors.green;
    if (webRTCService.iceConnectionState == RTCIceConnectionState.RTCIceConnectionStateChecking) return Colors.orange;
    return Colors.grey;
  }



}