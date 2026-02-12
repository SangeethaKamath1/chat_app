import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../audio_call/service/speakerphone_service.dart';
import '../../chat/chat_websocket/chat_web_socket_service.dart';
import '../../group_audio_video_call/repository/group_call_repository.dart';
import '../../model/join_group_call_data_response.dart';

class LiveKitOneToOneCallService extends GetxService {
  Room? _room;
  CancelListenFunc? _cancelRoomEvents;

  final isConnected = false.obs;
  final isMicMuted = false.obs;
  final isSpeakerOn = false.obs;
  final isCameraOff = false.obs;

  final Rx<RemoteParticipant?> remoteParticipant = Rx(null);
  
  // ✅ NEW: Track observables like group call
  final Rx<VideoTrack?> localVideoTrack = Rx(null);
  final Rx<VideoTrack?> remoteVideoTrack = Rx(null);
  final Rx<bool> isRemoteVideoMuted = Rx(true);

  bool _isCaller = false;
  bool _isVideoCall = false;
  bool _leaving = false;

  Room? get room => _room;

  final SpeakerphoneService _speakerSvc = Get.find();

  ChatWebSocketService _socket(String callId) {
    final s = Get.find<ChatWebSocketService>();
    s.ensureConnectedFromRoomId(callId);
    return s;
  }

  void setRole({required bool isCaller}) {
    _isCaller = isCaller;
    debugPrint("🎭 Role set - isCaller: $_isCaller");
  }

  void setCallType({required bool isVideo}) {
    _isVideoCall = isVideo;
    debugPrint("📹 Call type set - isVideo: $_isVideoCall");
  }

  Future<JoinGroupCallDataResponse> _joinBackend(String callId) {
    return GroupCallRepository.joinGroupCall(callId);
  }

  void _logEvent(dynamic event) {
    debugPrint("🛰️ [LK_EVT] ${event.runtimeType}");
  }

  void _logRoomSnapshot(Room room, {String tag = "SNAP"}) {
    final lp = room.localParticipant;
    debugPrint("🧩 [$tag] room.name=${room.name} local.identity=${lp?.identity}");
    debugPrint("🧩 [$tag] local video pubs=${lp?.videoTrackPublications.length ?? 0}");
    
    for (final rp in room.remoteParticipants.values) {
      debugPrint("🧩 [$tag] remote.identity=${rp.identity} video pubs=${rp.videoTrackPublications.length}");
      for (final pub in rp.videoTrackPublications) {
        debugPrint("   🎥 pub sid=${pub.sid} muted=${pub.muted} subscribed=${pub.subscribed} track=${pub.track?.runtimeType}");
      }
    }
  }

  // ✅ NEW: Update track observables like group call
  void _updateTracks(Room room) {
    // Local video track
    final lp = room.localParticipant;
    if (lp != null && lp.videoTrackPublications.isNotEmpty) {
      final pub = lp.videoTrackPublications.first;
      final track = pub.track;
      if (track is VideoTrack && !pub.muted) {
        localVideoTrack.value = track;
      } else {
        localVideoTrack.value = null;
      }
    } else {
      localVideoTrack.value = null;
    }

    // Remote video track
    final remote = remoteParticipant.value;
    if (remote != null && remote.videoTrackPublications.isNotEmpty) {
      final pub = remote.videoTrackPublications.first;
      final track = pub.track;
      isRemoteVideoMuted.value = pub.muted;
      
      if (track is VideoTrack && !pub.muted) {
        remoteVideoTrack.value = track;
        debugPrint("🎥 [UPDATE_TRACKS] Remote video track updated: ${track.runtimeType}");
      } else {
        remoteVideoTrack.value = null;
        debugPrint("🎥 [UPDATE_TRACKS] Remote video track is null or muted");
      }
    } else {
      remoteVideoTrack.value = null;
      isRemoteVideoMuted.value = true;
      debugPrint("🎥 [UPDATE_TRACKS] No remote video publications");
    }
  }

  Future<void> joinCall(String callId) async {
    await leaveCall();

    debugPrint("💡 [joinCall] Starting - isVideo: $_isVideoCall, isCaller: $_isCaller, callId: $callId");

    final join = await _joinBackend(callId);
    
    final room = Room();
    _room = room;

    _cancelRoomEvents = room.events.listen((event) async {
      _logEvent(event);

      if (event is RoomConnectedEvent) {
        isConnected.value = true;
        debugPrint("✅ Room connected - isCaller: $_isCaller");
        _logRoomSnapshot(room, tag: "AFTER_CONNECT");
        
        if (!_isCaller) {
          _speakerSvc.stopRingtone();
          _socket(callId).callAccepted(callId);
          debugPrint("📤 [CALLEE] emitted callAccepted");
        }
        
        _updateTracks(room); // ✅ Update tracks after connect
      }

      if (event is ParticipantConnectedEvent &&
          event.participant is RemoteParticipant) {
        remoteParticipant.value = event.participant as RemoteParticipant;
        debugPrint("👤 Remote participant connected: ${event.participant.identity}");
        _logRoomSnapshot(room, tag: "AFTER_REMOTE_JOIN");
        
        if (_isCaller) {
          _speakerSvc.stopRingtone();
          debugPrint("🔇 [CALLER] Stopped ringtone - peer joined");
        }
        
        _updateTracks(room); // ✅ Update tracks after remote joins
      }

      if (event is TrackPublishedEvent) {
        debugPrint("📡 [TRACK_PUBLISHED] by=${event.participant.identity} kind=${event.publication.kind} pubSid=${event.publication.sid}");

        if (event.participant is RemoteParticipant) {
          try {
            await event.publication.subscribe();
            debugPrint("✅ [SUBSCRIBE_OK] kind=${event.publication.kind} pubSid=${event.publication.sid} subscribed=${event.publication.subscribed}");
          } catch (e) {
            debugPrint("❌ [SUBSCRIBE_FAIL] kind=${event.publication.kind} pubSid=${event.publication.sid} err=$e");
          }
        } else {
          debugPrint("ℹ️ [TRACK_PUBLISHED] ignoring local publication subscribe");
        }
        
        _logRoomSnapshot(room, tag: "AFTER_PUBLISHED");
        _updateTracks(room); // ✅ Update tracks after publish
      }

      if (event is TrackSubscribedEvent) {
        debugPrint("✅ [TRACK_SUBSCRIBED] participant=${event.participant.identity} kind=${event.publication.kind} track=${event.track.runtimeType}");
        _logRoomSnapshot(room, tag: "AFTER_SUBSCRIBED");
        _updateTracks(room); // ✅ Update tracks after subscribe
      }

      if (event is TrackUnsubscribedEvent) {
        debugPrint("⚠️ [TRACK_UNSUBSCRIBED] participant=${event.participant.identity}");
        _logRoomSnapshot(room, tag: "AFTER_UNSUBSCRIBED");
        _updateTracks(room); // ✅ Update tracks after unsubscribe
      }

      if (event is TrackSubscriptionExceptionEvent) {
        debugPrint("❌ [SUB_EXCEPTION] participant=${event.participant?.identity} reason=${event.reason}");
      }

      if (event is TrackMutedEvent) {
        debugPrint("🚫 [TRACK_MUTED] participant=${event.participant.identity} kind=${event.publication.kind}");
        _updateTracks(room); // ✅ Update tracks when muted
      }

      if (event is TrackUnmutedEvent) {
        debugPrint("✅ [TRACK_UNMUTED] participant=${event.participant.identity} kind=${event.publication.kind}");
        _updateTracks(room); // ✅ Update tracks when unmuted
      }

      if (event is ParticipantDisconnectedEvent ||
          event is RoomDisconnectedEvent) {
        debugPrint("❌ Participant/Room disconnected");
        if (!_leaving) await leaveCall();
      }
    });

    debugPrint("🔌 Connecting to room with URL: ${join.url}");
    
    try {
      _leaving = false;
      await room.connect(
        join.url!,
        join.token!,
        roomOptions: const RoomOptions(
          adaptiveStream: false,
          dynacast: true,
        ),
        connectOptions: const ConnectOptions(
          autoSubscribe: true,
        ),
      );
    } catch (e) {
      if (_leaving) return;
      rethrow;
    }

    debugPrint("⏳ Waiting for localParticipant...");
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    final local = room.localParticipant;
    if (local != null) {
      debugPrint("🎤 Enabling microphone...");
      await local.setMicrophoneEnabled(true);
      isMicMuted.value = false;

      debugPrint("📹 Setting camera - isVideo: $_isVideoCall");
      if (_isVideoCall) {
        debugPrint("✅ Enabling camera for video call...");
        try {
          await local.setCameraEnabled(
            true,
            cameraCaptureOptions: const CameraCaptureOptions(
              cameraPosition: CameraPosition.front,
            ),
          );
          isCameraOff.value = false;
          debugPrint("✅ Camera enabled successfully");
        } catch (e) {
          debugPrint("❌ Camera enable failed: $e");
          isCameraOff.value = true;
        }
      } else {
        debugPrint("❌ Disabling camera for audio call...");
        await local.setCameraEnabled(false);
        isCameraOff.value = true;
      }
      
      _logRoomSnapshot(room, tag: "AFTER_LOCAL_MEDIA");
      _updateTracks(room); // ✅ Update tracks after setting up local media
    } else {
      debugPrint("⚠️ WARNING: localParticipant is null!");
    }

    debugPrint("🔊 Setting speakerphone: $_isVideoCall");
    await setSpeakerphone(_isVideoCall);
    
    debugPrint("✅ [joinCall] Complete - isVideo: $_isVideoCall, camera: ${!isCameraOff.value}");
  }

  Future<void> startOutgoingCall({
    required String callId,
    required bool isVideo,
  }) async {
    setRole(isCaller: true);
    setCallType(isVideo: isVideo);
    _socket(callId).callStarted(isVideo);
    debugPrint("📞 [CALLER] Started outgoing call - isVideo: $isVideo");
  }

  Future<void> toggleMute() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    final muted = !isMicMuted.value;
    await lp.setMicrophoneEnabled(!muted);
    isMicMuted.value = muted;
    debugPrint("🎤 Mic toggled - muted: $muted");
  }

  Future<void> toggleCamera() async {
    final lp = _room?.localParticipant;
    if (lp == null) {
      debugPrint("⚠️ Cannot toggle camera - localParticipant is null");
      return;
    }

    if (isCameraOff.value) {
      debugPrint("📹 Enabling camera...");
      await lp.setCameraEnabled(
        true,
        cameraCaptureOptions: const CameraCaptureOptions(
          cameraPosition: CameraPosition.front,
        ),
      );
      isCameraOff.value = false;
      debugPrint("✅ Camera enabled");
    } else {
      debugPrint("📹 Disabling camera...");
      await lp.setCameraEnabled(false);
      isCameraOff.value = true;
      debugPrint("❌ Camera disabled");
    }
    
    // ✅ Update tracks after toggle
    if (_room != null) _updateTracks(_room!);
  }

  Future<void> switchCamera() async {
    final pub = _room?.localParticipant?.videoTrackPublications.firstOrNull;
    final track = pub?.track;
    if (track is! LocalVideoTrack) {
      debugPrint("⚠️ Cannot switch camera - no video track");
      return;
    }

    final devices = await Hardware.instance.enumerateDevices();
    final cameras = devices.where((d) => d.kind == 'videoinput').toList();
    if (cameras.length < 2) {
      debugPrint("⚠️ Cannot switch camera - only one camera available");
      return;
    }

    final currentId = track.currentOptions.deviceId;
    final next = cameras.firstWhere(
      (d) => d.deviceId != currentId,
      orElse: () => cameras.first,
    );

    debugPrint("🔄 Switching camera to: ${next.label}");
    try {
      await track.switchCamera(next.deviceId);
    } catch (e) {
      debugPrint("❌ Switch failed: $e");
    }
  }

  Future<void> setSpeakerphone(bool enable) async {
    isSpeakerOn.value = enable;
    await Hardware.instance.setSpeakerphoneOn(enable);
    debugPrint("🔊 Speakerphone set: $enable");
  }

  Future<void> leaveCall() async {
    _leaving = true;
    debugPrint("👋 Leaving call...");

    try {
      _cancelRoomEvents?.call();
      await _room?.disconnect();
    } catch (e) {
      debugPrint("⚠️ Error during disconnect: $e");
    }

    _room = null;
    remoteParticipant.value = null;
    
    // ✅ Clear track observables
    localVideoTrack.value = null;
    remoteVideoTrack.value = null;
    isRemoteVideoMuted.value = true;

    isConnected.value = false;
    isMicMuted.value = false;
    isSpeakerOn.value = false;
    isCameraOff.value = false;

    _leaving = false;
    debugPrint("✅ Call left successfully");
  }

  @override
  void onClose() {
    leaveCall();
    super.onClose();
  }
}