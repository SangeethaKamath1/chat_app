// // import 'dart:async';

// // import 'package:chat_app/audio_call/service/speakerphone_service.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_webrtc/flutter_webrtc.dart';
// // import 'package:get/get.dart' hide navigator;

// // import '../../chat/chat_websocket/chat_web_socket_service.dart';
// // import '../controller/call_session_controller.dart';
// // import 'call_signaling_service.dart';

// // class WebRTCService extends GetxService {
// //   RTCPeerConnection? _pc;
// //   MediaStream? _localStream;
// //   MediaStream? _remoteStream;

// //   final List<RTCRtpSender> _senders = [];

// //   // ✅ Renderers (only used if session.isVideo == true)
// //   final RTCVideoRenderer localRenderer = RTCVideoRenderer();
// //   final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

// //   final _isConnected = false.obs;
// //   final _isCallActive = false.obs;
// //   final RxBool isCallAccepted = false.obs;

// //   final _iceConnectionState = RTCIceConnectionState.RTCIceConnectionStateNew.obs;
// //   final _signalingState = RTCSignalingState.RTCSignalingStateStable.obs;

// //   final _hasRemoteAudio = false.obs;
// //   final _hasRemoteVideo = false.obs;

// //   bool _isInitializing = false;
// //   bool _isDisposed = false;

// //   bool get isConnected => _isConnected.value;
// //   bool get isCallActive => _isCallActive.value;

// //   bool get hasRemoteAudio => _hasRemoteAudio.value;
// //   bool get hasRemoteVideo => _hasRemoteVideo.value;

// //   RTCIceConnectionState get iceConnectionState => _iceConnectionState.value;
// //   RTCSignalingState get signalingState => _signalingState.value;

// //   SpeakerphoneService get speakerphoneService => Get.find<SpeakerphoneService>();
// //   ChatWebSocketService get signaling => Get.find<ChatWebSocketService>();
// //   CallSessionController get session => Get.find<CallSessionController>();

// //   // ------------------------------------------------------------
// //   // INIT / DISPOSE
// //   // ------------------------------------------------------------

// //   @override
// //   void onInit() {
// //     super.onInit();
// //     if (!Get.isRegistered<SpeakerphoneService>()) {
// //       Get.put(SpeakerphoneService(), permanent: true);
// //     }
// //     _initRenderers();
// //   }

// //   Future<void> _initRenderers() async {
// //     await localRenderer.initialize();
// //     await remoteRenderer.initialize();
// //   }

// //   @override
// //   void onClose() {
// //     _isDisposed = true;
// //     _cleanup();
// //     try {
// //       localRenderer.dispose();
// //       remoteRenderer.dispose();
// //     } catch (_) {}
// //     super.onClose();
// //   }

// //   // ------------------------------------------------------------
// //   // PEER CONNECTION
// //   // ------------------------------------------------------------

// //   Future<void> initializePeerConnection() async {
// //     if (_isDisposed) return;
// //     if (_isInitializing) return;

// //     _isInitializing = true;
// //     try {
// //       debugPrint("🔄 INITIALIZING PEER CONNECTION...");

// //       // If old pc exists, close it
// //       if (_pc != null) {
// //         try {
// //           await _removeAllSendersFromPc();
// //         } catch (_) {}
// //         try {
// //           await _pc?.close();
// //         } catch (_) {}
// //         _pc = null;
// //         await Future.delayed(const Duration(milliseconds: 100));
// //       }

// //       final config = {
// //         'iceServers': [
// //           {'urls': 'stun:stun.l.google.com:19302'},
// //           {'urls': 'stun:stun1.l.google.com:19302'},
// //         ],
// //         'sdpSemantics': 'unified-plan',
// //       };

// //       _pc = await createPeerConnection(config);
// //       if (_pc == null) throw Exception("Failed to create RTCPeerConnection");

// //       _setupEventHandlers();
// //       debugPrint("✅✅✅ PEER CONNECTION INITIALIZED");
// //     } finally {
// //       _isInitializing = false;
// //     }
// //   }

// //   void _setupEventHandlers() {
// //     final pc = _pc;
// //     if (pc == null) return;

// //     pc.onIceCandidate = (RTCIceCandidate c) {
// //       if (c.candidate == null || c.candidate!.isEmpty) return;
// //       if (!_shouldSendCandidate(c)) return;
// //       signaling.sendIceCandidate(c);
// //     };

// //     pc.onSignalingState = (RTCSignalingState s) {
// //       debugPrint("📡 Signaling State: $s");
// //       _signalingState.value = s;
// //     };

// //     pc.onTrack = (RTCTrackEvent e) {
// //       debugPrint("📥 onTrack kind=${e.track.kind}");

// //       if (e.track.kind == 'audio') {
// //         _handleRemoteAudioTrack(e.track, e.streams.isNotEmpty ? e.streams.first : null);
// //       } else if (e.track.kind == 'video') {
// //         _handleRemoteVideoTrack(e.track, e.streams.isNotEmpty ? e.streams.first : null);
// //       }
// //     };

// //     pc.onConnectionState = (RTCPeerConnectionState s) {
// //       debugPrint("🌐 PC Connection State: $s");
// //       if (s == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
// //         _isConnected.value = true;
// //         _isCallActive.value = true;
// //       }
// //       if (s == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
// //           s == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
// //           s == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
// //         _isConnected.value = false;
// //         _isCallActive.value = false;
// //       }
// //     };

// //     pc.onIceConnectionState = (RTCIceConnectionState s) {
// //       debugPrint("❄️ ICE Connection State: $s");
// //       _iceConnectionState.value = s;
// //       if (s == RTCIceConnectionState.RTCIceConnectionStateConnected) {
// //         _isConnected.value = true;
// //         _isCallActive.value = true;
// //       }
// //     };
// //   }

// //   bool _shouldSendCandidate(RTCIceCandidate c) {
// //     final str = (c.candidate ?? '').toLowerCase();
// //     return !str.contains('tcp') && !str.contains('127.0.0.1');
// //   }

// //   // ------------------------------------------------------------
// //   // LOCAL MEDIA
// //   // ------------------------------------------------------------

// //   Future<void> _disposeLocalStream() async {
// //     final s = _localStream;
// //     if (s == null) return;

// //     try {
// //       for (final t in s.getTracks()) {
// //         try {
// //           await t.stop();
// //         } catch (_) {}
// //       }
// //     } catch (_) {}

// //     try {
// //       await s.dispose();
// //     } catch (_) {}

// //     _localStream = null;
// //   }

// //   Future<void> getLocalMedia({required bool video}) async {
// //     // Always recreate local stream
// //     await _disposeLocalStream();

// //     final constraints = <String, dynamic>{
// //       'audio': true,
// //       'video': video
// //           ? {
// //               'facingMode': 'user',
// //               // You can add:
// //               // 'width': {'ideal': 640},
// //               // 'height': {'ideal': 480},
// //               // 'frameRate': {'ideal': 30},
// //             }
// //           : false,
// //     };

// //     debugPrint("🎥 getUserMedia(video=$video)");
// //     _localStream = await navigator.mediaDevices.getUserMedia(constraints);

// //     // attach local renderer for video
// //     if (video) {
// //       localRenderer.srcObject = _localStream;
// //     } else {
// //       localRenderer.srcObject = null;
// //     }
// //   }

// //   Future<void> _removeAllSendersFromPc() async {
// //     final pc = _pc;
// //     if (pc == null) return;

// //     try {
// //       final senders = await pc.getSenders();
// //       for (final s in senders) {
// //         try {
// //           await pc.removeTrack(s);
// //         } catch (_) {}
// //       }
// //     } catch (_) {}

// //     _senders.clear();
// //   }

// //   Future<void> _addLocalTracks() async {
// //     final pc = _pc;
// //     final stream = _localStream;
// //     if (pc == null || stream == null) return;

// //     // CRITICAL: remove existing senders
// //     await _removeAllSendersFromPc();

// //     for (final track in stream.getTracks()) {
// //       final sender = await pc.addTrack(track, stream);
// //       _senders.add(sender);
// //       debugPrint("✅ addTrack(${track.kind})");
// //     }
// //   }

// //   // ------------------------------------------------------------
// //   // CONTROLS
// //   // ------------------------------------------------------------

// //   void muteAudio(bool mute) {
// //     final s = _localStream;
// //     if (s == null) return;

// //     for (final t in s.getAudioTracks()) {
// //       t.enabled = !mute;
// //     }
// //     session.isMuted.value = mute;
// //     debugPrint("🎤 ${mute ? 'MUTED' : 'UNMUTED'}");
// //   }

// //   void setVideoEnabled(bool enabled) {
// //     final s = _localStream;
// //     if (s == null) return;

// //     for (final t in s.getVideoTracks()) {
// //       t.enabled = enabled;
// //     }
// //     session.isVideoMuted.value = !enabled;
// //     debugPrint("📷 Video ${enabled ? 'ENABLED' : 'DISABLED'}");
// //   }

// //   Future<void> switchCamera() async {
// //     final s = _localStream;
// //     if (s == null) return;

// //     final vids = s.getVideoTracks();
// //     if (vids.isEmpty) return;

// //     await Helper.switchCamera(vids.first);
// //     debugPrint("🔁 Camera switched");
// //   }

// //   Future<void> setSpeakerphoneOn(bool on) async {
// //     await speakerphoneService.setSpeakerphoneOn(on);
// //     session.isSpeakerOn.value = on;
// //   }

// //   // ------------------------------------------------------------
// //   // OFFER / ANSWER FLOW
// //   // ------------------------------------------------------------

// //   /// CALLER
// //   Future<void> createOffer(bool isVideo) async {
// //     await initializePeerConnection();

// //     final video = session.isVideo.value; // default true
// //     await getLocalMedia(video: video);
// //     await _addLocalTracks();

// //     final offer = await _pc!.createOffer({
// //       'offerToReceiveAudio': true,
// //       'offerToReceiveVideo': video,
// //     });

// //     await _pc!.setLocalDescription(offer);
// //     signaling.sendOffer(offer,isVideo);
// //   }

// //   /// CALLEE: called when offer is received (CallKit fetch or WS)
// //   Future<void> handleOffer(RTCSessionDescription offer) async {
// //     await _setRemoteDescription(offer);
// //   }

// //   /// CALLER: called when answer is received
// //   Future<void> handleAnswer(RTCSessionDescription answer) async {
// //     await _setRemoteDescription(answer);
// //     isCallAccepted.value = true;
// //   }

// //   Future<void> _setRemoteDescription(RTCSessionDescription desc) async {
// //     if (_pc == null) {
// //       await initializePeerConnection();
// //     }

// //     await _pc!.setRemoteDescription(desc);

// //     if (desc.type == 'offer') {
// //       // Determine if remote expects video
// //       final wantsVideo = (desc.sdp ?? '').contains('m=video');
// //       session.isVideo.value = wantsVideo;

// //       await getLocalMedia(video: wantsVideo);
// //       await _addLocalTracks();

// //       final answer = await _pc!.createAnswer({
// //         'offerToReceiveAudio': true,
// //         'offerToReceiveVideo': wantsVideo,
// //       });

// //       await _pc!.setLocalDescription(answer);
// //       signaling.sendAnswer(answer);
// //       isCallAccepted.value = true;
// //     }
// //   }

// //   Future<void> addIceCandidate(RTCIceCandidate c) async {
// //     final pc = _pc;
// //     if (pc == null) return;
// //     try {
// //       await pc.addCandidate(c);
// //     } catch (e) {
// //       debugPrint("❌ addCandidate failed: $e");
// //     }
// //   }

// //   // ------------------------------------------------------------
// //   // REMOTE TRACK HANDLERS
// //   // ------------------------------------------------------------

// //   void _handleRemoteAudioTrack(MediaStreamTrack track, MediaStream? stream) {
// //     _remoteStream = stream;
// //     _hasRemoteAudio.value = true;
// //     track.enabled = true;
// //     debugPrint("🔊 Remote audio active");
// //   }

// //   void _handleRemoteVideoTrack(MediaStreamTrack track, MediaStream? stream) {
// //     _remoteStream = stream;
// //     _hasRemoteVideo.value = true;

// //     if (stream != null) {
// //       remoteRenderer.srcObject = stream;
// //     }
// //     track.enabled = true;
// //     debugPrint("🎥 Remote video active");
// //   }

// //   // ------------------------------------------------------------
// //   // END CALL / CLEANUP
// //   // ------------------------------------------------------------

// //   Future<void> endCall() async {
// //    await _cleanup();
// //   }

// //   Future<void> _cleanup() async{
// //     debugPrint("🧹 WebRTC cleanup...");

// //     _isConnected.value = false;
// //     _isCallActive.value = false;
// //     _hasRemoteAudio.value = false;
// //     _hasRemoteVideo.value = false;
// //     isCallAccepted.value = false;

// //     try {
// //       speakerphoneService.setSpeakerphoneOn(false);
// //     } catch (_) {}

// //     // Close pc
// //     try {
// //      await _removeAllSendersFromPc();
// //     } catch (_) {}
// //     try {
// //     await  _pc?.close();
// //     } catch (_) {}
// //     _pc = null;

// //     // dispose streams
// //     try {
// //     await  _disposeLocalStream();
// //     } catch (_) {}
// //     try {
// //       _remoteStream?.dispose();
// //     } catch (_) {}
// //     _remoteStream = null;

// //     // detach renderers
// //     localRenderer.srcObject = null;
// //     remoteRenderer.srcObject = null;

// //     _senders.clear();
// //     _isInitializing = false;
// //   }
// // }

// import 'dart:async';

// import 'package:chat_app/audio_call/service/speakerphone_service.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:get/get.dart' hide navigator;

// import '../../chat/chat_websocket/chat_web_socket_service.dart';
// import '../controller/call_session_controller.dart';
// import 'call_signaling_service.dart';

// class WebRTCService extends GetxService {
//   RTCPeerConnection? _pc;
//   MediaStream? _localStream;
//   MediaStream? _remoteStream;

//   final List<RTCRtpSender> _senders = [];

//   final RTCVideoRenderer localRenderer = RTCVideoRenderer();
//   final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

//   final _isConnected = false.obs;
//   final _isCallActive = false.obs;
//   final RxBool isCallAccepted = false.obs;

//   final _iceConnectionState =
//       RTCIceConnectionState.RTCIceConnectionStateNew.obs;
//   final _signalingState =
//       RTCSignalingState.RTCSignalingStateStable.obs;

//   final _hasRemoteAudio = false.obs;
//   final _hasRemoteVideo = false.obs;

//   bool _isInitializing = false;
//   bool _isDisposed = false;

//   /// ✅ NEW (internal only)
//   bool _remoteDescriptionSet = false;
//   final List<RTCIceCandidate> _pendingIce = [];

//   bool get isConnected => _isConnected.value;
//   bool get isCallActive => _isCallActive.value;
//   bool get hasRemoteAudio => _hasRemoteAudio.value;
//   bool get hasRemoteVideo => _hasRemoteVideo.value;

//   RTCIceConnectionState get iceConnectionState =>
//       _iceConnectionState.value;
//   RTCSignalingState get signalingState =>
//       _signalingState.value;

//   SpeakerphoneService get speakerphoneService =>
//       Get.find<SpeakerphoneService>();
//   ChatWebSocketService get signaling =>
//       Get.find<ChatWebSocketService>();
//   CallSessionController get session =>
//       Get.find<CallSessionController>();

//   // ------------------------------------------------------------
//   // INIT / DISPOSE
//   // ------------------------------------------------------------

//   @override
//   void onInit() {
//     super.onInit();
//     if (!Get.isRegistered<SpeakerphoneService>()) {
//       Get.put(SpeakerphoneService(), permanent: true);
//     }
//     _initRenderers();
//   }

//   Future<void> _initRenderers() async {
//     await localRenderer.initialize();
//     await remoteRenderer.initialize();
//   }

//   @override
//   void onClose() {
//     _isDisposed = true;
//     _cleanup();
//     try {
//       localRenderer.dispose();
//       remoteRenderer.dispose();
//     } catch (_) {}
//     super.onClose();
//   }

//   // ------------------------------------------------------------
//   // PEER CONNECTION
//   // ------------------------------------------------------------

//   Future<void> initializePeerConnection() async {
//     if (_isDisposed) return;
//     if (_pc != null || _isInitializing) return;

//     _isInitializing = true;
//     try {
//       debugPrint("🔄 INITIALIZING PEER CONNECTION");

//       final config = {
//         "iceServers": [
//           {"urls": ["stun:stun.relay.metered.ca:80"]},
//           {
//             "urls": ["turn:global.relay.metered.ca:80"],
//             "username": "6766647978f33c6b6af9bae6",
//             "credential": "nKtapWM3obK/4WqO",
//           },
//           {
//             "urls": ["turn:global.relay.metered.ca:80?transport=tcp"],
//             "username": "6766647978f33c6b6af9bae6",
//             "credential": "nKtapWM3obK/4WqO",
//           },
//           {
//             "urls": ["turn:global.relay.metered.ca:443"],
//             "username": "6766647978f33c6b6af9bae6",
//             "credential": "nKtapWM3obK/4WqO",
//           },
//           {
//             "urls": ["turns:global.relay.metered.ca:443?transport=tcp"],
//             "username": "6766647978f33c6b6af9bae6",
//             "credential": "nKtapWM3obK/4WqO",
//           },
//         ],
//         "sdpSemantics": "unified-plan",
//       };

//       _pc = await createPeerConnection(config);
//       _setupEventHandlers();

//       debugPrint("✅ PEER CONNECTION READY");
//     } finally {
//       _isInitializing = false;
//     }
//   }

//   void _handleRemoteAudioTrack(
//   MediaStreamTrack track,
//   MediaStream? stream,
// ) {
//   debugPrint("🔊 Remote audio track received");

//   if (stream != null) {
//     _remoteStream = stream;
//   }

//   track.enabled = true;
//   speakerphoneService.setSpeakerphoneOn(false);
//   _hasRemoteAudio.value = true;
// }

//   void _setupEventHandlers() {
//     final pc = _pc!;
//     pc.onIceCandidate = (c) {
//       if (c.candidate == null) return;
//       signaling.sendIceCandidate(c);
//     };

//     pc.onIceConnectionState = (s) {
//       _iceConnectionState.value = s;
//       debugPrint("❄️ ICE: $s");
//       if (s ==
//           RTCIceConnectionState
//               .RTCIceConnectionStateConnected) {
//         _isConnected.value = true;
//         _isCallActive.value = true;
//       }
//     };

//     pc.onConnectionState = (s) {
//       if (s ==
//           RTCPeerConnectionState
//               .RTCPeerConnectionStateConnected) {
//         _isConnected.value = true;
//         _isCallActive.value = true;
//       }
//     };
//     pc.onTrack = (RTCTrackEvent event) {
//   if (event.streams.isEmpty) return;

//   final stream = event.streams.first;

//   for (final track in stream.getTracks()) {
//     if (track.kind == 'audio') {
//       _handleRemoteAudioTrack(track, stream);
//     } else if (track.kind == 'video') {
//       remoteRenderer.srcObject = stream;
//       _hasRemoteVideo.value = true;
//     }
//   }
// };

//     // pc.onTrack = (e) {
//     //   if (e.track.kind == 'audio') {
//     //     _remoteStream = e.streams.first;
//     //     _hasRemoteAudio.value = true;
//     //   } else if (e.track.kind == 'video') {
//     //     _remoteStream = e.streams.first;
//     //     remoteRenderer.srcObject = _remoteStream;
//     //     _hasRemoteVideo.value = true;
//     //   }
//     // };
//   }

//   // ------------------------------------------------------------
//   // LOCAL MEDIA
//   // ------------------------------------------------------------

//   Future<void> getLocalMedia({required bool video}) async {
//     await _disposeLocalStream();

//     _localStream = await navigator.mediaDevices.getUserMedia({
//       "audio": true,
//       "video": video ? {"facingMode": "user"} : false,
//     });

//     if (video) localRenderer.srcObject = _localStream;
//   }

//   Future<void> _addLocalTracks() async {
//     final pc = _pc!;
//     final stream = _localStream!;
//     await _removeAllSendersFromPc();

//     for (final track in stream.getTracks()) {
//       _senders.add(await pc.addTrack(track, stream));
//     }
//   }

//   Future<void> _removeAllSendersFromPc() async {
//     final pc = _pc;
//     if (pc == null) return;

//     final senders = await pc.getSenders();
//     for (final s in senders) {
//       try {
//         await pc.removeTrack(s);
//       } catch (_) {}
//     }
//     _senders.clear();
//   }

//   // ------------------------------------------------------------
//   // CONTROLS (UNCHANGED)
//   // ------------------------------------------------------------

//   void muteAudio(bool mute) {
//     _localStream?.getAudioTracks().forEach((t) {
//         debugPrint("🎤 Local audio enabled: ${t.enabled}");
//       t.enabled = !mute;
//     });
//     session.isMuted.value = mute;
//   }

//   void setVideoEnabled(bool enabled) {
//     _localStream?.getVideoTracks().forEach((t) {
//       t.enabled = enabled;
//     });
//     session.isVideoMuted.value = !enabled;
//   }

//   Future<void> switchCamera() async {
//     final videoTrack =
//         _localStream?.getVideoTracks().firstOrNull;
//     if (videoTrack != null) {
//       await Helper.switchCamera(videoTrack);
//     }
//   }

//   Future<void> setSpeakerphoneOn(bool on) async {
//     await speakerphoneService.setSpeakerphoneOn(on);
//     session.isSpeakerOn.value = on;
//   }

//   // ------------------------------------------------------------
//   // OFFER / ANSWER
//   // ------------------------------------------------------------

//   Future<void> createOffer(bool isVideo) async {
//     await initializePeerConnection();
//     session.isVideo.value = isVideo;

//     await getLocalMedia(video: isVideo);
//     for (final t in _localStream!.getAudioTracks()) {
//   debugPrint("🎤 Local audio enabled: ${t.enabled}");
//   t.enabled = true;
// }
//     await _addLocalTracks();

//     final offer = await _pc!.createOffer();
//     await _pc!.setLocalDescription(offer);
//    // signaling.sendOffer(offer, isVideo);
//   }

//   Future<void> handleOffer(RTCSessionDescription offer) async {
//     await _setRemoteDescription(offer);
//   }

//   Future<void> handleAnswer(RTCSessionDescription answer) async {
//     await _setRemoteDescription(answer);
//     isCallAccepted.value = true;
//   }

//   Future<void> _setRemoteDescription(
//       RTCSessionDescription desc) async {
//     await initializePeerConnection();
//     await _pc!.setRemoteDescription(desc);

//     _remoteDescriptionSet = true;

//     for (final c in _pendingIce) {
//       await _pc!.addCandidate(c);
//     }
//     _pendingIce.clear();

//     if (desc.type == 'offer') {
//        final wantsVideo = session.isVideo.value;
//       // final wantsVideo =
//       //     (desc.sdp ?? '').contains('m=video');
//       // session.isVideo.value = wantsVideo;

//       await getLocalMedia(video: wantsVideo);
//       await _addLocalTracks();

//       final answer = await _pc!.createAnswer({
//       // 'offerToReceiveAudio': true,
//       // 'offerToReceiveVideo': wantsVideo,
//     });
//       await _pc!.setLocalDescription(answer);
//       signaling.sendAnswer(answer);
//       isCallAccepted.value = true;
//     }
//   }

//   Future<void> addIceCandidate(RTCIceCandidate c) async {
//     if (!_remoteDescriptionSet) {
//       _pendingIce.add(c);
//       return;
//     }
//     await _pc?.addCandidate(c);
//   }

//   // ------------------------------------------------------------
//   // CLEANUP
//   // ------------------------------------------------------------

//   Future<void> endCall() async {
//     await _cleanup();
//   }

//   Future<void> _cleanup() async {
//     _remoteDescriptionSet = false;
//     _pendingIce.clear();

//     _isConnected.value = false;
//     _isCallActive.value = false;
//     _hasRemoteAudio.value = false;
//     _hasRemoteVideo.value = false;
//     isCallAccepted.value = false;

//     try {
//       await _removeAllSendersFromPc();
//       await _pc?.close();
//     } catch (_) {}

//     _pc = null;

//     await _disposeLocalStream();
//     try {
//       await _remoteStream?.dispose();
//     } catch (_) {}

//     _remoteStream = null;
//     localRenderer.srcObject = null;
//     remoteRenderer.srcObject = null;
//   }

//   Future<void> _disposeLocalStream() async {
//     final s = _localStream;
//     if (s == null) return;

//     for (final t in s.getTracks()) {
//       try {
//         await t.stop();
//       } catch (_) {}
//     }
//     await s.dispose();
//     _localStream = null;
//   }
// }
