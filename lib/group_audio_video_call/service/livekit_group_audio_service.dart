import 'dart:async';
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

  // ─────────────────────────────────────────────
  // ROLE
  // ─────────────────────────────────────────────
  void setRole({required bool isCaller}) {
    _isCaller = isCaller;
    _callerToneStopped = false;
    debugPrint("🎭 [LK] role=${_isCaller ? "CALLER" : "CALLEE"}");
  }

  // ─────────────────────────────────────────────
  // SOCKET ENSURE (CRITICAL)
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
      _ensureSocket(callId).emitGroupCallStarted(
        callId: callId,
        isVideo: false,
      );
    }

    final room = Room();
    _room = room;

    _cancelRoomEvents = room.events.listen((event) async {
      if (event is ActiveSpeakersChangedEvent) {
        activeSpeakerSids.value = event.speakers.map((e) => e.sid).toList();
      }

      if (event is RoomConnectedEvent) {
        isConnected.value = true;
        debugPrint("✅ [ROOM] connected");

        if (!_isCaller) {
          await _stopTone("callee_connected");
          _ensureSocket(callId).emitGroupCallAccepted(callId: callId);
          debugPrint("📤 [ACCEPT] emitted AFTER connect");
        }
      }

      if (event is RoomDisconnectedEvent) {
        isConnected.value = false;
        stopNoAnswerTimeout();
      }

      if (event is ParticipantConnectedEvent) {
        _anyRemoteJoined = true;
        stopNoAnswerTimeout();

        if (_isCaller && !_callerToneStopped) {
          _callerToneStopped = true;
          await _stopTone("remote_joined");
        }
      }

      _rebuildParticipantsUi(room);
    });

    try {
      _leaving = false;
      await room.connect(joinInfo.url!, joinInfo.token!);
    } catch (e) {
      if (_leaving) return;
      rethrow;
    }

    await room.localParticipant?.setMicrophoneEnabled(true);
    isMicMuted.value = false;

    await setSpeakerphone(false);
  }

  void _rebuildParticipantsUi(Room room) {
    final speaking = activeSpeakerSids.toSet();
    final list = <LKUiParticipant>[];

    final local = room.localParticipant;
    if (local != null) {
      list.add(
        LKUiParticipant(
          sid: local.sid,
          name: local.name ?? "You",
          isLocal: true,
          isSpeaking: speaking.contains(local.sid),
        ),
      );
    }

    for (final rp in room.remoteParticipants.values) {
      list.add(
        LKUiParticipant(
          sid: rp.sid,
          name: rp.name ?? rp.identity,
          isLocal: false,
          isSpeaking: speaking.contains(rp.sid),
        ),
      );
    }

    participants.value = list;
  }

  // ─────────────────────────────────────────────
  // CONTROLS
  // ─────────────────────────────────────────────
  Future<void> toggleMute() async {
    final r = _room;
    if (r == null) return;

    final muted = !isMicMuted.value;
    await r.localParticipant?.setMicrophoneEnabled(!muted);
    isMicMuted.value = muted;
  }

  Future<void> setSpeakerphone(bool enable) async {
    isSpeakerOn.value = enable;
    await Hardware.instance.setSpeakerphoneOn(enable);
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
    _leaving = false;
  }

  @override
  void onClose() {
    leaveGroupAudio();
    super.onClose();
  }
}
