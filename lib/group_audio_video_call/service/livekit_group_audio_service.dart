// livekit_group_audio_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../audio_call/service/speakerphone_service.dart';
import '../../chat/chat_websocket/group_chat_web_socket_service.dart';
import '../../group_audio_video_call/repository/group_call_repository.dart';
import '../../model/join_group_call_data_response.dart';
import '../../model/lk_ui_participant.dart';

class LiveKitGroupAudioService extends GetxService {
  Room? _room;
  CancelListenFunc? _cancelRoomEvents;

  final isConnected = false.obs;
  final isMicMuted = false.obs;
  final isSpeakerOn = false.obs;
  final isCameraOff = false.obs;

  bool _isVideoCall = false;

  final participants = <LKUiParticipant>[].obs;
  final activeSpeakerSids = <String>[].obs;

  final SpeakerphoneService _speakerSvc = Get.find<SpeakerphoneService>();

  bool _isCaller = false;
  bool _callerToneStopped = false;
  bool _anyRemoteJoined = false;
  bool _leaving = false;

  Timer? _noAnswerTimer;
  String? _callId;

  Room? get room => _room;
  bool get anyRemoteJoined => _anyRemoteJoined;

  // Cache device list for camera switching
  List<MediaDevice> _videoInputs = [];
  String? _currentVideoDeviceId;

  // ─────────────────────────────────────────────
  // ROLE & CALL TYPE
  // ─────────────────────────────────────────────
  void setRole({required bool isCaller}) {
    _isCaller = isCaller;
    _callerToneStopped = false;
    debugPrint("🎭 [LK] role=${_isCaller ? "CALLER" : "CALLEE"}");
  }

  void setCallType({required bool isVideo}) {
    _isVideoCall = isVideo;
    debugPrint("🎥 [LK] callType=${isVideo ? "VIDEO" : "AUDIO"}");
  }

  // ─────────────────────────────────────────────
  // SOCKET ENSURE
  // ─────────────────────────────────────────────
  GroupChatWebSocketService _ensureSocket(String callId) {
    final socket = Get.find<GroupChatWebSocketService>();
    socket.callID.value = callId;
    socket.ensureConnectedFromRoomId(callId);
    debugPrint("🔌 [SOCKET] ensured for callId=$callId");
    return socket;
  }

  // ─────────────────────────────────────────────
  // NO ANSWER TIMEOUT (CALLER)
  // ─────────────────────────────────────────────
  void startNoAnswerTimeout({
    required String callId,
    int seconds = 30,
    Future<void> Function()? onTimeout,
  }) {
    stopNoAnswerTimeout();
    _anyRemoteJoined = false;

    debugPrint("⏳ [NO_ANSWER] start $seconds s callId=$callId");

    _noAnswerTimer = Timer(Duration(seconds: seconds), () async {
      if (!_isCaller || _anyRemoteJoined) return;

      debugPrint("🚫 [NO_ANSWER] timeout → cancel call");

      try {
        _ensureSocket(callId).emitGroupCallCancelled(callId: callId);
      } catch (e) {
        debugPrint("⚠️ cancel emit failed: $e");
      }

      await leaveGroupAudio();
      if (onTimeout != null) await onTimeout();
    });
  }

  void stopNoAnswerTimeout() {
    debugPrint("stop no answer timeout called");
    _noAnswerTimer?.cancel();
    _noAnswerTimer = null;
  }

  // ─────────────────────────────────────────────
  // BACKEND JOIN
  // ─────────────────────────────────────────────
  Future<JoinGroupCallDataResponse> _joinFromBackend(String callId) async {
    return await GroupCallRepository.joinGroupCall(callId);
  }

  Future<void> _stopTone(String reason) async {
    debugPrint("🔕 [TONE] stop ($reason)");
    await _speakerSvc.stopRingtone();
  }

  // ─────────────────────────────────────────────
  // DEVICES
  // ─────────────────────────────────────────────
  Future<void> _refreshVideoInputs() async {
    final devices = await Hardware.instance.enumerateDevices(type: 'videoinput');
    _videoInputs = devices;
    debugPrint("📷 [DEVICES] video inputs=${_videoInputs.length}");
  }

  // ─────────────────────────────────────────────
  // LOG HELPERS (very useful for your issue)
  // ─────────────────────────────────────────────
  void _logEvent(dynamic event) {
    debugPrint("🛰️ [LK_EVT] ${event.runtimeType} => $event");
  }

  void _logRoomSnapshot(Room room, {String tag = "SNAP"}) {
    final lp = room.localParticipant;
    debugPrint("🧩 [$tag] room.name=${room.name} room.sid=${room.getSid()}");
    debugPrint("🧩 [$tag] local.identity=${lp?.identity} local.sid=${lp?.sid} isVideoCall=$_isVideoCall");

    debugPrint("🧩 [$tag] local pubs: "
        "audio=${lp?.audioTrackPublications.length ?? 0}, "
        "video=${lp?.videoTrackPublications.length ?? 0}");

    debugPrint("🧩 [$tag] remoteParticipants=${room.remoteParticipants.length}");
    for (final rp in room.remoteParticipants.values) {
      debugPrint("🧩 [$tag] remote.identity=${rp.identity} remote.sid=${rp.sid} name=${rp.name}");
      debugPrint("🧩 [$tag] remote pubs: audio=${rp.audioTrackPublications.length}, video=${rp.videoTrackPublications.length}");

      for (final pub in rp.audioTrackPublications) {
        debugPrint("   🎧 pub(A) sid=${pub.sid} muted=${pub.muted} subscribed=${pub.subscribed} track=${pub.track?.runtimeType}");
      }
      for (final pub in rp.videoTrackPublications) {
        debugPrint("   🎥 pub(V) sid=${pub.sid} muted=${pub.muted} subscribed=${pub.subscribed} track=${pub.track?.runtimeType}");
      }
    }
  }

  // ─────────────────────────────────────────────
  // VIDEO STATE HELPERS (FIXES "VIDEO OFF" UI BUG)
  // ─────────────────────────────────────────────
  ({VideoTrack? track, bool hasPub, bool muted}) _localVideoState(LocalParticipant lp) {
    final pubs = lp.videoTrackPublications;
    if (pubs.isEmpty) return (track: null, hasPub: false, muted: true);

    final pub = pubs.first;
    final t = pub.track;
    final muted = pub.muted;
    return (track: (t is VideoTrack) ? t : null, hasPub: true, muted: muted);
  }

  ({VideoTrack? track, bool hasPub, bool muted}) _remoteVideoState(RemoteParticipant rp) {
    final pubs = rp.videoTrackPublications;
    if (pubs.isEmpty) return (track: null, hasPub: false, muted: true);

    final pub = pubs.first;
    final t = pub.track;
    final muted = pub.muted;
    return (track: (t is VideoTrack) ? t : null, hasPub: true, muted: muted);
  }

  // ─────────────────────────────────────────────
  // JOIN
  // ─────────────────────────────────────────────
  Future<void> joinGroupAudio(String callId) async {
    _callId = callId;
    _anyRemoteJoined = false;
    _callerToneStopped = false;

    debugPrint("📞 [JOIN] callId=$callId role=${_isCaller ? "CALLER" : "CALLEE"}");
    await leaveGroupAudio();

    final joinInfo = await _joinFromBackend(callId);

    if (_isCaller) {
      _ensureSocket(callId).emitGroupCallStarted(callId: callId, isVideo: _isVideoCall);
    }

    final room = Room();
    _room = room;

    _cancelRoomEvents = room.events.listen((event) async {
      _logEvent(event);

      if (event is ActiveSpeakersChangedEvent) {
        activeSpeakerSids.value = event.speakers.map((e) => e.sid).toList();
        debugPrint("🔊 [SPEAKERS] ${activeSpeakerSids.join(",")}");
      }

      if (event is RoomConnectedEvent) {
        isConnected.value = true;
//         if (Platform.isIOS && _isCaller && !_callerToneStopped) {
//     _callerToneStopped = true;
//     await _stopTone("caller_room_connected");
//   }
//   if (Platform.isIOS && _isCaller) {
//   final lp = room.localParticipant;
//   if (lp != null) {
//     await lp.setMicrophoneEnabled(false);
//     await lp.setMicrophoneEnabled(true);
//     debugPrint("🎛️ [IOS_FIX] restarted mic after stopping ringback");
//   }
// }
        debugPrint("✅ [ROOM] connected url=${room.engine.url} name=${room.name} sid=${room.getSid()}");
        _logRoomSnapshot(room, tag: "AFTER_CONNECT");

        if (!_isCaller) {
          await _stopTone("callee_connected");
          _ensureSocket(callId).emitGroupCallAccepted(callId: callId);
          debugPrint("📤 [ACCEPT] emitted AFTER connect");
        }
      }

      if (event is RoomDisconnectedEvent) {
        debugPrint("❌ [ROOM] disconnected reason=${event.reason}");
        isConnected.value = false;
      //  _isCaller? stopNoAnswerTimeout():null;
        _logRoomSnapshot(room, tag: "AFTER_DISCONNECT");
      }

      if (event is ParticipantConnectedEvent) {
        _anyRemoteJoined = true;
        // stopNoAnswerTimeout();

        debugPrint("👤 [REMOTE_JOIN] identity=${event.participant.identity} sid=${event.participant.sid} name=${event.participant.name}");
        _logRoomSnapshot(room, tag: "AFTER_REMOTE_JOIN");

        if (_isCaller && !_callerToneStopped) {
          _callerToneStopped = true;
          await _stopTone("remote_joined");
        }
      }

      if (event is ParticipantDisconnectedEvent) {
        debugPrint("👋 [REMOTE_LEFT] identity=${event.participant.identity} sid=${event.participant.sid}");
        _logRoomSnapshot(room, tag: "AFTER_REMOTE_LEFT");
      }

      if (event is ParticipantPermissionsUpdatedEvent) {
        debugPrint("🔐 [PERMS_UPDATED] permissions=${event.permissions != null}");
      }

      // Subscribe ONLY to remote publications
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
      }

      if (event is TrackSubscribedEvent) {
        debugPrint("✅ [TRACK_SUBSCRIBED] participant=${event.participant.identity} kind=${event.publication.kind} pubSid=${event.publication.sid} track=${event.track.runtimeType}");
        _logRoomSnapshot(room, tag: "AFTER_SUBSCRIBED");
      }

      if (event is TrackUnsubscribedEvent) {
        debugPrint("⚠️ [TRACK_UNSUBSCRIBED] participant=${event.participant.identity} pubSid=${event.publication.sid}");
        _logRoomSnapshot(room, tag: "AFTER_UNSUBSCRIBED");
      }

      if (event is TrackSubscriptionExceptionEvent) {
        debugPrint("❌ [SUB_EXCEPTION] participant=${event.participant?.identity} reason=${event.reason}");
        _logRoomSnapshot(room, tag: "AFTER_SUB_EXCEPTION");
      }

      if (event is TrackMutedEvent) {
        debugPrint("🚫 [TRACK_MUTED] participant=${event.participant.identity} kind=${event.publication.kind} source=${event.publication.source} pubSid=${event.publication.sid} subscribed=${event.publication.subscribed} track=${event.publication.track?.runtimeType}");
      }

      if (event is TrackUnmutedEvent) {
        debugPrint("✅ [TRACK_UNMUTED] participant=${event.participant.identity} kind=${event.publication.kind} source=${event.publication.source} pubSid=${event.publication.sid} subscribed=${event.publication.subscribed}");
      }

      _rebuildParticipantsUi(room);
    });

    try {
      _leaving = false;
      await room.connect(
        joinInfo.url!,
        joinInfo.token!,
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

    await _refreshVideoInputs();

    // Enable local participant media
    final local = room.localParticipant;
    if (local != null) {
      await local.setMicrophoneEnabled(true);
      debugPrint("🎛️ [LOCAL_MEDIA] micEnabled=true");

      if (_isVideoCall) {
        // Enable camera
        try {
          await local.setCameraEnabled(
            true,
            cameraCaptureOptions: const CameraCaptureOptions(cameraPosition: CameraPosition.front),
          );
          isCameraOff.value = false;
          debugPrint("✅ [CAM] enabled attempt=0");
        } catch (e) {
          debugPrint("❌ [CAM] enable failed: $e");
          isCameraOff.value = true;
        }

        _syncCurrentDeviceFromLocalTrack();
      } else {
        await local.setCameraEnabled(false);
        isCameraOff.value = true;
      }

      _logRoomSnapshot(room, tag: "AFTER_LOCAL_MEDIA");
    }

    isMicMuted.value = false;
    await setSpeakerphone(false);

    _rebuildParticipantsUi(room);
  }

  void _syncCurrentDeviceFromLocalTrack() {
    final r = _room;
    if (r == null) return;

    final pub = r.localParticipant?.videoTrackPublications.isNotEmpty == true
        ? r.localParticipant!.videoTrackPublications.first
        : null;

    final t = pub?.track;
    if (t is LocalVideoTrack) {
      final opts = t.currentOptions;
      if (opts is CameraCaptureOptions) {
        _currentVideoDeviceId = opts.deviceId;
        debugPrint("📷 [CAM] current deviceId=$_currentVideoDeviceId pos=${opts.cameraPosition}");
      }
    }
  }

  String _safeName({required bool isLocal, String? name, String? identity}) {
    if (isLocal) return "You";
    final n = (name ?? "").trim();
    if (n.isNotEmpty) return n;
    final id = (identity ?? "").trim();
    if (id.isNotEmpty) return id;
    return "Guest";
  }

  // ─────────────────────────────────────────────
  // PARTICIPANTS UI (USES pub.muted to fix video-off)
  // ─────────────────────────────────────────────
  void _rebuildParticipantsUi(Room room) {
    final speaking = activeSpeakerSids.toSet();
    final list = <LKUiParticipant>[];

    final local = room.localParticipant;
    if (local != null) {
      final st = _localVideoState(local);

      list.add(LKUiParticipant(
        sid: local.sid,
        name: _safeName(isLocal: true, name: local.name, identity: local.identity),
        isLocal: true,
        isSpeaking: speaking.contains(local.sid),
        videoTrack: st.track,
        hasVideoPub: st.hasPub,
        isVideoMuted: st.muted,
      ));
    }

    for (final rp in room.remoteParticipants.values) {
      final st = _remoteVideoState(rp);

      list.add(LKUiParticipant(
        sid: rp.sid,
        name: _safeName(isLocal: false, name: rp.name, identity: rp.identity),
        isLocal: false,
        isSpeaking: speaking.contains(rp.sid),
        videoTrack: st.track,
        hasVideoPub: st.hasPub,
        isVideoMuted: st.muted,
      ));
    }

    participants.value = list;
  }

  // ─────────────────────────────────────────────
  // CONTROLS
  // ─────────────────────────────────────────────
  Future<void> toggleMute() async {
    final r = _room;
    if (r == null) return;

    final newMuted = !isMicMuted.value;
    await r.localParticipant?.setMicrophoneEnabled(!newMuted);
    isMicMuted.value = newMuted;
    debugPrint("🎤 [MUTE] nowMuted=$newMuted");
  }

  Future<void> toggleCamera() async {
    final r = _room;
    if (r == null) return;

    final lp = r.localParticipant;
    if (lp == null) return;

    final before = lp.videoTrackPublications.length;
    debugPrint("🎥 [CAM_TOGGLE] before pubs=$before isCameraOff=${isCameraOff.value}");

    if (isCameraOff.value) {
      await _refreshVideoInputs();

      // Turning ON
      await lp.setCameraEnabled(
        true,
        cameraCaptureOptions: CameraCaptureOptions(
          cameraPosition: CameraPosition.front,
          deviceId: _currentVideoDeviceId,
        ),
      );

      isCameraOff.value = false;
      _syncCurrentDeviceFromLocalTrack();
      debugPrint("📷 [CAM] toggled ON");
    } else {
      // Turning OFF
      await lp.setCameraEnabled(false);
      isCameraOff.value = true;
      debugPrint("📷 [CAM] toggled OFF");
    }

    final after = lp.videoTrackPublications.length;
    debugPrint("🎥 [CAM_TOGGLE] after pubs=$after isCameraOff=${isCameraOff.value}");

    _rebuildParticipantsUi(r);
  }

  Future<void> switchCamera() async {
    final r = _room;
    if (r == null) return;

    await _refreshVideoInputs();
    if (_videoInputs.length < 2) {
      debugPrint("⚠️ [CAM] Only ${_videoInputs.length} video input(s). Cannot switch.");
      return;
    }

    final pub = r.localParticipant?.videoTrackPublications.isNotEmpty == true
        ? r.localParticipant!.videoTrackPublications.first
        : null;

    final track = pub?.track;
    if (track is! LocalVideoTrack) {
      debugPrint("⚠️ [CAM] No LocalVideoTrack to switch.");
      return;
    }

    final opts = track.currentOptions;
    if (opts is CameraCaptureOptions) {
      _currentVideoDeviceId = opts.deviceId;
    }

    int idx = _videoInputs.indexWhere((d) => d.deviceId == _currentVideoDeviceId);
    if (idx == -1) idx = 0;
    final next = _videoInputs[(idx + 1) % _videoInputs.length];

    debugPrint("🔄 [CAM] switch deviceId ${_currentVideoDeviceId ?? '(unknown)'} -> ${next.deviceId}");

    try {
      await track.switchCamera(next.deviceId, fastSwitch: true);
      _currentVideoDeviceId = next.deviceId;
    } catch (e) {
      debugPrint("❌ [CAM] switch failed: $e");
      // fallback: restart camera with explicit deviceId
      try {
        await r.localParticipant?.setCameraEnabled(false);
        await r.localParticipant?.setCameraEnabled(
          true,
          cameraCaptureOptions: CameraCaptureOptions(
            deviceId: next.deviceId,
            cameraPosition: CameraPosition.front,
          ),
        );
        _currentVideoDeviceId = next.deviceId;
      } catch (e2) {
        debugPrint("❌ [CAM] fallback restart failed: $e2");
      }
    }

    _rebuildParticipantsUi(r);
  }

  Future<void> setSpeakerphone(bool enable) async {
    isSpeakerOn.value = enable;
    await Hardware.instance.setSpeakerphoneOn(enable);
    debugPrint("🔈 [SPK] speakerOn=$enable");
  }

  // ─────────────────────────────────────────────
  // LEAVE
  // ─────────────────────────────────────────────
  Future<void> leaveGroupAudio() async {
    debugPrint("📴 [LEAVE]");

    stopNoAnswerTimeout();
    isConnected.value = false;
    _leaving = true;

    try {
      _cancelRoomEvents?.call();
    } catch (_) {}

    try {
      await _room?.disconnect();
    } catch (_) {}

    _room = null;
    participants.clear();
    activeSpeakerSids.clear();

    isMicMuted.value = false;
    isSpeakerOn.value = false;
    isCameraOff.value = false;

    _videoInputs = [];
    _currentVideoDeviceId = null;

    _leaving = false;
  }

  @override
  void onClose() {
    leaveGroupAudio();
    super.onClose();
  }
}
