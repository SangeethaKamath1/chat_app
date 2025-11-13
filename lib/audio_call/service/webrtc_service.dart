import 'dart:async';
import 'dart:convert';
import 'package:chat_app/audio_call/service/speakerphone_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;
import '../../chat/controller/chat_controller.dart';

class WebRTCService extends GetxService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  List<RTCRtpSender> _senders = [];
  
  final _isConnected = false.obs;
  final _isCallActive = false.obs;
  final _iceConnectionState = RTCIceConnectionState.RTCIceConnectionStateNew.obs;
  final _hasRemoteAudio = false.obs;
  final _signalingState = RTCSignalingState.RTCSignalingStateStable.obs;
  
  bool _isInitializing = false;
  bool _isDisposed = false;

  bool get isConnected => _isConnected.value;
  bool get isCallActive => _isCallActive.value;
  bool get hasRemoteAudio => _hasRemoteAudio.value;
  RTCIceConnectionState get iceConnectionState => _iceConnectionState.value;
  RTCSignalingState get signalingState => _signalingState.value;
   SpeakerphoneService get speakerphoneService => Get.find<SpeakerphoneService>();

  ChatController get chatController => Get.find<ChatController>();

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
      Get.put(SpeakerphoneService());
  }

  @override
  void onClose() {
    _isDisposed = true;
    _cleanup();
    super.onClose();
  }

  void _cleanup() {
    debugPrint("🧹 Cleaning up WebRTC resources...");
    speakerphoneService.setSpeakerphoneOn(false);
    _isConnected.value = false;
    _isCallActive.value = false;
    _hasRemoteAudio.value = false;
    
    if (_peerConnection != null) {
      try {
        _peerConnection!.close();
        _peerConnection = null;
        debugPrint("✅ PeerConnection closed");
      } catch (e) {
        debugPrint("❌ Error closing PeerConnection: $e");
      }
    }
    
    _localStream?.dispose();
    _remoteStream?.dispose();
    _localStream = null;
    _remoteStream = null;
    
    _senders.clear();
    _isInitializing = false;
  }

  Future<void> initializePeerConnection() async {
    if (_isInitializing || _isDisposed) {
      debugPrint("⏸️ Skipping initialization - already in progress or disposed");
      return;
    }

    try {
      _isInitializing = true;
      debugPrint("🔄 INITIALIZING PEER CONNECTION...");

      // Clean up existing connection
      if (_peerConnection != null) {
        _peerConnection!.close();
        _peerConnection = null;
        await Future.delayed(Duration(milliseconds: 100));
      }

      final configuration = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
        ],
        'sdpSemantics': 'unified-plan',
      };

      _peerConnection = await createPeerConnection(configuration);
      
      if (_peerConnection == null) {
        throw Exception("Failed to create PeerConnection");
      }

      _setupEventHandlers();
      debugPrint("✅✅✅ PEER CONNECTION INITIALIZED SUCCESSFULLY");
      
    } catch (e) {
      debugPrint("❌ Error initializing PeerConnection: $e");
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  void _setupEventHandlers() {
    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      debugPrint("❄️ ICE Candidate: ${candidate.candidate}");
      if (_shouldSendCandidate(candidate)) {
        _sendIceCandidate(candidate);
      }
    };

    _peerConnection?.onSignalingState = (RTCSignalingState state) {
      debugPrint("📡 Signaling State: $state");
      _signalingState.value = state;
    };

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      debugPrint("🎵 REMOTE TRACK RECEIVED: ${event.track.kind}");
      
      if (event.track.kind == 'audio') {
        _handleRemoteAudioTrack(event.track, event.streams.isNotEmpty ? event.streams.first : null);
      }
    };

    _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint("🌐 Connection State: $state");
      
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _isConnected.value = true;
        _isCallActive.value = true;
        debugPrint("✅✅✅ PEER CONNECTION CONNECTED!");
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        _isConnected.value = false;
        _isCallActive.value = false;
        debugPrint("🔴 PeerConnection closed");
      }
    };

    _peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      debugPrint("❄️ ICE Connection State: $state");
      _iceConnectionState.value = state;
      
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
        _isConnected.value = true;
        _isCallActive.value = true;
        debugPrint("✅✅✅ ICE CONNECTED!");
      }
    };
  }

  void _handleRemoteAudioTrack(MediaStreamTrack audioTrack, MediaStream? stream) {
    try {
      debugPrint("🎧 Setting up remote audio...");
      
      if (stream != null) {
        _remoteStream = stream;
      }

      _hasRemoteAudio.value = true;
      audioTrack.enabled = true;
      debugPrint("✅✅✅ REMOTE AUDIO READY!");
      
    } catch (e) {
      debugPrint("❌ Error handling remote audio: $e");
    }
  }

  bool _shouldSendCandidate(RTCIceCandidate candidate) {
    final candidateStr = candidate.candidate!.toLowerCase();
    return !candidateStr.contains('tcp') &&
           !candidateStr.contains('127.0.0.1') &&
           candidate.candidate!.isNotEmpty;
  }

  Future<void> getLocalMedia() async {
    try {
      debugPrint("🎤 Getting local media...");
      
      final mediaConstraints = {
        'audio': true,
        'video': false
      };

      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      debugPrint("✅ Local media obtained");
      
    } catch (e) {
      debugPrint("❌ Error getting local media: $e");
      rethrow;
    }
  }

  // ✅ ADDED BACK: createOffer method for caller
  Future<void> createOffer() async {
    try {
      debugPrint("🔄 CREATING OFFER (CALLER)...");
      
      await initializePeerConnection();
      await getLocalMedia();
      
      if (_localStream != null) {
        final audioTracks = _localStream!.getAudioTracks();
        for (final track in audioTracks) {
          final sender = await _peerConnection!.addTrack(track, _localStream!);
          _senders.add(sender);
          debugPrint("✅ Added local audio track");
        }
      }

      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      _sendOffer(offer);
      
      debugPrint("✅✅✅ OFFER CREATED AND SENT");
      
    } catch (e) {
      debugPrint("❌ Error creating offer: $e");
      rethrow;
    }
  }

  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    try {
      debugPrint("📥 Setting remote description: ${description.type}");
      
      if (_peerConnection == null) {
        debugPrint("❌ No PeerConnection, initializing...");
        await initializePeerConnection();
      }

      await _peerConnection!.setRemoteDescription(description);
      debugPrint("✅ Remote description set: ${description.type}");

      // ✅ CREATE ANSWER HERE when we receive an offer (for callee)
      if (description.type == 'offer') {
        debugPrint("🔄 Creating answer for received offer...");
        
        // Get local media if not already done
        if (_localStream == null) {
          await getLocalMedia();
        }
        
        // Add local tracks
        if (_localStream != null) {
          final audioTracks = _localStream!.getAudioTracks();
          for (final track in audioTracks) {
            final sender = await _peerConnection!.addTrack(track, _localStream!);
            _senders.add(sender);
            debugPrint("✅ Added local audio track");
          }
        }
        
        // Create and send answer
        final answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);
        _sendAnswer(answer);
        
        debugPrint("✅✅✅ ANSWER CREATED AND SENT");
      }
      
    } catch (e) {
      debugPrint("❌ Error setting remote description: $e");
      rethrow;
    }
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    try {
      if (_peerConnection == null) {
        debugPrint("❌ No PeerConnection for ICE candidate");
        return;
      }

      await _peerConnection!.addCandidate(candidate);
      debugPrint("✅ ICE candidate added");
    } catch (e) {
      debugPrint("❌ Error adding ICE candidate: $e");
    }
  }

  Future<void> handleOffer(RTCSessionDescription offer) async {
    try {
      debugPrint("📥 HANDLING INCOMING OFFER...");
      await setRemoteDescription(offer);
      debugPrint("✅✅✅ OFFER HANDLED - ANSWER SENT");
    } catch (e) {
      debugPrint("❌ Error handling offer: $e");
      rethrow;
    }
  }

  Future<void> handleAnswer(RTCSessionDescription answer) async {
    try {
      debugPrint("📥 HANDLING INCOMING ANSWER...");
      await setRemoteDescription(answer);
      debugPrint("✅✅✅ ANSWER HANDLED - CONNECTION SHOULD ESTABLISH");
    } catch (e) {
      debugPrint("❌ Error handling answer: $e");
      rethrow;
    }
  }

  void muteAudio(bool mute) {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      for (final track in audioTracks) {
        track.enabled = !mute;
      }
      debugPrint("🎤 ${mute ? 'MUTED' : 'UNMUTED'}");
    }
  }

   Future<void> setSpeakerphoneOn(bool on) async {
    try {
      await speakerphoneService.setSpeakerphoneOn(on);
      debugPrint("🔊 Speakerphone ${on ? 'activated' : 'deactivated'}");
    } catch (e) {
      debugPrint("❌ Error setting speakerphone: $e");
    }
  }

  Future<void> toggleSpeakerphone() async {
    await speakerphoneService.toggleSpeakerphone();
  }

  // Get current speakerphone state
  bool get isSpeakerOn => speakerphoneService.isSpeakerOn.value;

  Future<void> endCall() async {
    debugPrint("📞 Ending call...");
    _cleanup();
  }

  // WebSocket Signaling
  void _sendOffer(RTCSessionDescription offer) {
    final payload = {
      "type": "offer",
      "offer": {"sdp": offer.sdp, "type": offer.type},
      "callID": chatController.roomId
    };
    chatController.chatWebSocket.channel?.sink.add(jsonEncode(payload));
    debugPrint("📤 OFFER SENT");
  }

  void _sendAnswer(RTCSessionDescription answer) {
    final payload = {
      "type": "answer", 
      "answer": {"sdp": answer.sdp, "type": answer.type},
      "callID": chatController.roomId
    };
    chatController.chatWebSocket.channel?.sink.add(jsonEncode(payload));
    debugPrint("📤 ANSWER SENT");
  }

  void _sendIceCandidate(RTCIceCandidate candidate) {
    final payload = {
      "type": "candidate",
      "candidate": {
        "candidate": candidate.candidate,
        "sdpMid": candidate.sdpMid ?? '0',
        "sdpMLineIndex": candidate.sdpMLineIndex ?? 0
      },
      "callID": chatController.roomId
    };
    chatController.chatWebSocket.channel?.sink.add(jsonEncode(payload));
    debugPrint("📤 ICE CANDIDATE SENT");
  }
}