import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../audio_call/service/speakerphone_service.dart';
import '../../chat/chat_websocket/chat_web_socket_service.dart';
import '../../group_audio_video_call/repository/group_call_repository.dart';
import '../../model/join_group_call_data_response.dart';

extension IterableX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final v in this) {
      if (test(v)) return v;
    }
    return null;
  }
}

class LiveKitOneToOneCallService extends GetxService {
  Room? _room;
  CancelListenFunc? _cancelRoomEvents;

  final isConnected = false.obs;
  final isMicMuted = false.obs;
  final isSpeakerOn = false.obs;
  final isCameraOff = false.obs;

  final Rx<RemoteParticipant?> remoteParticipant = Rx<RemoteParticipant?>(null);

  final Rx<VideoTrack?> localVideoTrack = Rx<VideoTrack?>(null);
  final Rx<VideoTrack?> remoteVideoTrack = Rx<VideoTrack?>(null);
  final Rx<bool> isRemoteVideoMuted = true.obs;

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

    debugPrint("🧩 [$tag] remote count=${room.remoteParticipants.length}");
    for (final rp in room.remoteParticipants.values) {
      debugPrint("🧩 [$tag] remote.identity=${rp.identity} video pubs=${rp.videoTrackPublications.length}");
      for (final pub in rp.videoTrackPublications) {
        debugPrint(
          "   🎥 pub sid=${pub.sid} muted=${pub.muted} "
          "track=${pub.track?.runtimeType}",
        );
      }
    }
  }

  /// ✅ pick remote even when caller already exists in room
  void _setRemoteIfExists(Room room) {
    if (remoteParticipant.value != null) return;

    if (room.remoteParticipants.isNotEmpty) {
      final rp = room.remoteParticipants.values.first;
      remoteParticipant.value = rp;
      debugPrint("👤 [EXISTING_REMOTE] Set from room snapshot: ${rp.identity}");

      // ✅ subscribe to their video publications (even if track is currently null)
      _subscribeRemoteVideo(rp);
    }
  }

  /// ✅ subscribe remote video pubs safely (track can be null before subscription)
  Future<void> _subscribeRemoteVideo(RemoteParticipant rp) async {
    if (rp.videoTrackPublications.isEmpty) {
      debugPrint("🎥 [SUBSCRIBE_REMOTE] No remote video pubs yet");
      return;
    }

    // Prefer the camera publication if possible
    final pub = rp.videoTrackPublications.firstWhereOrNull((p) {
          // Some SDKs expose source; if not, fallback to first
          final src = p.source;
          return src == TrackSource.camera;
        }) ??
        rp.videoTrackPublications.first;

    debugPrint("🎥 [SUBSCRIBE_REMOTE] Trying subscribe pubSid=${pub.sid} muted=${pub.muted}");

    try {
      await pub.subscribe();
      debugPrint("✅ [SUBSCRIBE_REMOTE_OK] pubSid=${pub.sid}");
    } catch (e) {
      debugPrint("❌ [SUBSCRIBE_REMOTE_FAIL] pubSid=${pub.sid} err=$e");
    }
  }

  /// ✅ update local track (ok to use track is VideoTrack)
  void _updateLocalTrack(Room room) {
    final lp = room.localParticipant;
    final localPub = lp?.videoTrackPublications.firstWhereOrNull((p) => !p.muted);
    final t = localPub?.track;
    localVideoTrack.value = (t is VideoTrack) ? t : null;
  }

  /// ✅ update remote track WITHOUT requiring track!=null in the selection filter
  void _updateRemoteTrack() {
    final rp = remoteParticipant.value;
    if (rp == null) {
      remoteVideoTrack.value = null;
      isRemoteVideoMuted.value = true;
      return;
    }

    if (rp.videoTrackPublications.isEmpty) {
      remoteVideoTrack.value = null;
      isRemoteVideoMuted.value = true;
      debugPrint("🎥 [REMOTE_TRACK] no pubs");
      return;
    }

    // Choose camera if available (or first pub)
    final pub = rp.videoTrackPublications.firstWhereOrNull((p) {
          final src = p.source;
          return src == TrackSource.camera;
        }) ??
        rp.videoTrackPublications.first;

    isRemoteVideoMuted.value = pub.muted;

    final t = pub.track;
    remoteVideoTrack.value = (t is VideoTrack && !pub.muted) ? t : null;

    debugPrint(
      "🎥 [REMOTE_TRACK] pubSid=${pub.sid} muted=${pub.muted} track=${t?.runtimeType}",
    );
  }
  Future<void> startOutgoingCall({
  required String callId,
  required bool isVideo,
}) async {
  setRole(isCaller: true);
  setCallType(isVideo: isVideo);

  // Signal the other side (your websocket layer)
  _socket(callId).callStarted(isVideo);

  debugPrint("📞 [CALLER] Started outgoing call - callId=$callId isVideo=$isVideo");
}

  void _updateTracks(Room room) {
    _updateLocalTrack(room);
    _updateRemoteTrack();

    debugPrint(
      "🎥 [UPDATE_TRACKS] local=${localVideoTrack.value != null} "
      "remote=${remoteVideoTrack.value != null} remoteMuted=${isRemoteVideoMuted.value}",
    );
  }

  Future<void> joinCall(String callId) async {
    await leaveCall();

    debugPrint(
      "💡 [joinCall] Starting - isVideo: $_isVideoCall, isCaller: $_isCaller, callId: $callId",
    );

    final join = await _joinBackend(callId);

    final room = Room();
    _room = room;

    _cancelRoomEvents = room.events.listen((event) async {
      _logEvent(event);

      if (event is RoomConnectedEvent) {
        isConnected.value = true;
        debugPrint("✅ Room connected - isCaller: $_isCaller");

        if (!_isCaller) {
          _speakerSvc.stopRingtone();
          _socket(callId).callAccepted(callId);
          debugPrint("📤 [CALLEE] emitted callAccepted");
        }

        // ✅ handle “caller already in room”
        _setRemoteIfExists(room);

        _logRoomSnapshot(room, tag: "AFTER_CONNECT");
        _updateTracks(room);
      }

      if (event is ParticipantConnectedEvent && event.participant is RemoteParticipant) {
        final rp = event.participant as RemoteParticipant;
        remoteParticipant.value = rp;
        debugPrint("👤 Remote participant connected: ${rp.identity}");

        if (_isCaller) {
          _speakerSvc.stopRingtone();
          debugPrint("🔇 [CALLER] Stopped ringtone - peer joined");
        }

        // ✅ subscribe to remote video now
        await _subscribeRemoteVideo(rp);

        _logRoomSnapshot(room, tag: "AFTER_REMOTE_JOIN");
        _updateTracks(room);
      }

      // When remote publishes, subscribe (only for remote participant)
      if (event is TrackPublishedEvent) {
        debugPrint(
          "📡 [TRACK_PUBLISHED] by=${event.participant.identity} kind=${event.publication.kind} pubSid=${event.publication.sid}",
        );

        if (event.participant is RemoteParticipant) {
          try {
            await event.publication.subscribe();
            debugPrint("✅ [SUBSCRIBE_OK] pubSid=${event.publication.sid}");
          } catch (e) {
            debugPrint("❌ [SUBSCRIBE_FAIL] pubSid=${event.publication.sid} err=$e");
          }
        }

        _logRoomSnapshot(room, tag: "AFTER_PUBLISHED");
        _updateTracks(room);
      }

      if (event is TrackSubscribedEvent) {
        debugPrint(
          "✅ [TRACK_SUBSCRIBED] participant=${event.participant.identity} kind=${event.publication.kind} track=${event.track.runtimeType}",
        );

        // ✅ IMPORTANT: make sure remoteParticipant is set even if events came weird
        if (event.participant is RemoteParticipant && remoteParticipant.value == null) {
          remoteParticipant.value = event.participant as RemoteParticipant;
        }

        _logRoomSnapshot(room, tag: "AFTER_SUBSCRIBED");
        _updateTracks(room);
      }

      if (event is TrackUnsubscribedEvent) {
        debugPrint("⚠️ [TRACK_UNSUBSCRIBED] participant=${event.participant.identity}");
        _logRoomSnapshot(room, tag: "AFTER_UNSUBSCRIBED");
        _updateTracks(room);
      }

      if (event is TrackMutedEvent) {
        debugPrint("🚫 [TRACK_MUTED] participant=${event.participant.identity} kind=${event.publication.kind}");
        _updateTracks(room);
      }

      if (event is TrackUnmutedEvent) {
        debugPrint("✅ [TRACK_UNMUTED] participant=${event.participant.identity} kind=${event.publication.kind}");
        _updateTracks(room);
      }

      if (event is ParticipantDisconnectedEvent || event is RoomDisconnectedEvent) {
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

    // ✅ after connect: handle existing remote again
    _setRemoteIfExists(room);
    _updateTracks(room);

    await Future.delayed(const Duration(milliseconds: 300));

    final local = room.localParticipant;
    if (local != null) {
      await local.setMicrophoneEnabled(true);
      isMicMuted.value = false;

      if (_isVideoCall) {
        try {
          await local.setCameraEnabled(
            true,
            cameraCaptureOptions: const CameraCaptureOptions(
              cameraPosition: CameraPosition.front,
            ),
          );
          isCameraOff.value = false;
        } catch (e) {
          debugPrint("❌ Camera enable failed: $e");
          isCameraOff.value = true;
        }
      } else {
        await local.setCameraEnabled(false);
        isCameraOff.value = true;
      }

      _logRoomSnapshot(room, tag: "AFTER_LOCAL_MEDIA");
      _updateTracks(room);
    }

    await setSpeakerphone(_isVideoCall);
    debugPrint("✅ [joinCall] Complete");
  }

  Future<void> toggleMute() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    final muted = !isMicMuted.value;
    await lp.setMicrophoneEnabled(!muted);
    isMicMuted.value = muted;
  }

  Future<void> toggleCamera() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;

    if (isCameraOff.value) {
      await lp.setCameraEnabled(
        true,
        cameraCaptureOptions: const CameraCaptureOptions(
          cameraPosition: CameraPosition.front,
        ),
      );
      isCameraOff.value = false;
    } else {
      await lp.setCameraEnabled(false);
      isCameraOff.value = true;
    }

    if (_room != null) _updateTracks(_room!);
  }

  Future<void> switchCamera() async {
    final pub = _room?.localParticipant?.videoTrackPublications.firstWhereOrNull((_) => true);
    final track = pub?.track;
    if (track is! LocalVideoTrack) return;

    final devices = await Hardware.instance.enumerateDevices();
    final cameras = devices.where((d) => d.kind == 'videoinput').toList();
    if (cameras.length < 2) return;

    final currentId = track.currentOptions.deviceId;
    final next = cameras.firstWhere(
      (d) => d.deviceId != currentId,
      orElse: () => cameras.first,
    );

    await track.switchCamera(next.deviceId);
  }

  Future<void> setSpeakerphone(bool enable) async {
    isSpeakerOn.value = enable;
    await Hardware.instance.setSpeakerphoneOn(enable);
  }

  Future<void> leaveCall() async {
    _leaving = true;

    try {
      _cancelRoomEvents?.call();
      await _room?.disconnect();
    } catch (_) {}

    _room = null;
    remoteParticipant.value = null;

    localVideoTrack.value = null;
    remoteVideoTrack.value = null;
    isRemoteVideoMuted.value = true;

    isConnected.value = false;
    isMicMuted.value = false;
    isSpeakerOn.value = false;
    isCameraOff.value = false;

    _leaving = false;
  }

  @override
  void onClose() {
    leaveCall();
    super.onClose();
  }
}
