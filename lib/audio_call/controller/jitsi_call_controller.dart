// import 'package:chat_app/chat/chat_websocket/chat_web_socket_service.dart';
// import 'package:get/get.dart';
// import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

// class JitsiVoiceCallController extends GetxController {
//   final jitsiMeet = JitsiMeet();
//   late String roomId;
//   late String userName;

//   final isMuted = false.obs;
//   final callStatus = "Connecting...".obs;
  

//   @override
//   void onInit() {
//     super.onInit();
//     final args = Get.arguments ?? {};
//     roomId = args['roomId'] ?? '';
//     userName = args['userName'] ?? 'Unknown';
//     chatWebSocket = 
//     _startCall();
//   }

//   Future<void> _startCall() async {
//     try {
//       callStatus.value = "Connecting...";
//       final options = JitsiMeetConferenceOptions(
//         room: roomId,
//         configOverrides: {
//           "startWithAudioMuted": false,
//           "startWithVideoMuted": true,
//           "prejoinPageEnabled": false,
//           "subject": "",
//           "p2p.enabled": true,
//         },
//         featureFlags: {
//           "toolbox.enabled": false,
//           "chat.enabled": false,
//           "invite.enabled": false,
//           "meetingName.enabled": false,
//           "meetingPassword.enabled": false,
//           "liveStreaming.enabled": false,
//           "recording.enabled": false,
//           "pip.enabled": false,
//           "filmstrip.enabled": false,
//           "fullscreen.enabled": false,
//         },
//         userInfo: JitsiMeetUserInfo(displayName: userName),
//       );

//       await jitsiMeet.join(options);

//       // Simulate connection delay
//       await Future.delayed(const Duration(seconds: 2));
//       callStatus.value = "Connected";
//     } catch (e) {
//       callStatus.value = "Failed to connect";
//       print("Error starting call: $e");
//     }
//   }

//   void toggleMute() {
//     isMuted.value = !isMuted.value;
//     jitsiMeet.setAudioMuted(isMuted.value);
//   }

//   void endCall() {
//     jitsiMeet.hangUp();
//     Get.back();
//   }

//   @override
//   void onClose() {
//     jitsiMeet.hangUp();
//     super.onClose();
//   }
// }
