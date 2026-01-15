import 'dart:io';
import 'dart:developer';

import 'package:amu_alumni/amu_alumni.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

import '../../chat_app.dart';
import '../../routes/chat_app_routes.dart';
import '../controller/call_session_controller.dart';
import '../service/call_signaling_service.dart';
import '../service/webrtc_service.dart';

class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({super.key});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  late final WebRTCService webrtc;
  late final ChatWebSocketService signaling;
  late final CallSessionController session;

  bool fromNotification = false;
  String callerId = "";
  String roomId = "";
  String callerName = "";
  String sdp = "";
  String offerType = "";

  @override
  void initState() {
    super.initState();

    final args = (Get.arguments ?? {}) as Map;
    fromNotification = (args['fromNotification'] ?? false) as bool;
    callerId = (args["callerId"] ?? "").toString();
    roomId = (args["roomId"] ?? "").toString();
    callerName = (args["callerName"] ?? "").toString();
    sdp = (args["sdp"] ?? "").toString();
    offerType = (args["offerType"] ?? "offer").toString();

    webrtc = Get.find<WebRTCService>();
    signaling = Get.find<ChatWebSocketService>();
    session = Get.find<CallSessionController>();

    // ✅ default to VIDEO (can override later via args["isVideo"]=false)
    final isVideo =
        args.containsKey("isVideo") ? (args["isVideo"] as bool) : true;

    session.hydrate(
      roomId: roomId,
      isCaller: false,
      fromNotification: fromNotification,
      peerId: callerId,
      peerName: callerName,
      isVideo: isVideo,
    );

    signaling.setRoom(roomId);
    signaling.ensureConnectedFromRoomId(roomId);
debugPrint("from notification:${fromNotification}");
    if (!fromNotification) {
      webrtc.speakerphoneService.startRingtone(isIncoming: true);
    }
  }

  @override
  void dispose() {
    webrtc.speakerphoneService.stopRingtone();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    log("IncomingCallScreen offerType=$offerType");

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
                  const Icon(Icons.account_circle,
                      color: Colors.white70, size: 100),
                  const SizedBox(height: 16),
                  Text(
                    callerName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Text(
                        session.isVideo.value
                            ? "Incoming video call..."
                            : "Incoming audio call...",
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 16),
                      )),
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
                    onPressed: () async {
                      webrtc.speakerphoneService.stopRingtone();
                      signaling.callRejected(roomId);
                      if (Platform.isIOS) {
                        await CallKitBridge.dismissIncoming(roomId);
                      }
                      fromNotification
                          ? Get.offAllNamed(AppRoutes.home)
                          : Get.back();
                    },
                  ),
                  _actionButton(
                    icon: Icons.call,
                    color: Colors.green,
                    label: "Accept",
                    onPressed: () async {
                      webrtc.speakerphoneService.stopRingtone();
                      // await webrtc.activateCallAudioSession();

                      signaling.setRoom(roomId);
                      signaling.ensureConnectedFromRoomId(roomId);
                          
                            if (Platform.isIOS) {
                        await CallKitBridge.acceptCallFromApp(roomId);
                      }

                      // ✅ Apply offer. WebRTCService auto-detects video from SDP ("m=video")
                      await webrtc
                          .handleOffer(RTCSessionDescription(sdp, offerType));
                    

                      // signaling.callAccepted(roomId);
                    

                      Get.offNamed(
                        ChatAppRoutes.callScreen,
                        arguments: {
                          "fromNotification": fromNotification,
                          "isCaller": false,
                          "roomId": roomId,
                          "callerId": callerId,
                          "callerName": callerName,
                          // ✅ You can omit isVideo here, because SDP decides.
                          // But we keep it for UI correctness before SDP track arrives.
                          "isVideo": session.isVideo.value,
                        },
                      );
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
