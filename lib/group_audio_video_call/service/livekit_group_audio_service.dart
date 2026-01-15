import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';

import 'package:chat_app/group_audio_video_call/repository/group_call_repository.dart';
import 'package:chat_app/model/join_group_call_data_response.dart';
import '../../model/lk_ui_participant.dart';

// If you want to stop ringtone here too, uncomment this:
// import '../../audio_call/service/speakerphone_service.dart';

class LiveKitGroupAudioService extends GetxService {
  Room? _room;

  CancelListenFunc? _cancelRoomEvents;

  final isConnected = false.obs;
  final isMicMuted = false.obs;
  final isSpeakerOn = false.obs;

  final participants = <LKUiParticipant>[].obs;
  final activeSpeakerSids = <String>[].obs;

  Room? get room => _room;

  // ✅ caller/callee role (used only for logs here)
  bool _isCaller = false;
  bool _callerToneStopped = false;

  // If you want ringtone stop from here too:
  // final speakerSvc = Get.find<SpeakerphoneService>();

  void setRole({required bool isCaller}) {
    _isCaller = isCaller;
    _callerToneStopped = false;
    debugPrint("🎭 [LiveKitGroupAudioService] setRole => isCaller=$_isCaller");
  }

  Future<JoinGroupCallDataResponse> _joinFromBackend(String callId) async {
    debugPrint("🌐 [JOIN_API] Calling joinGroupCall(callId=$callId)");
    try {
      final response = await GroupCallRepository.joinGroupCall(callId);
      debugPrint("✅ [JOIN_API] Success token=${response.token}, url=${response.url}");
      return response;
    } catch (e, st) {
      debugPrint("❌ [JOIN_API] Error: $e");
      debugPrint("🧵 [JOIN_API] Stack: $st");
      throw Exception("Join API network error: $e");
    }
  }

  Future<void> joinGroupAudio(String callId) async {
    debugPrint("📞 [JOIN] joinGroupAudio START callId=$callId role=${_isCaller ? "CALLER" : "CALLEE"}");

    await leaveGroupAudio();
    debugPrint("🧹 [JOIN] leaveGroupAudio done (cleanup before join)");

    final joinInfo = await _joinFromBackend(callId);

    final roomOptions = const RoomOptions(
      adaptiveStream: true,
      dynacast: true,
      defaultAudioPublishOptions: AudioPublishOptions(dtx: true),
    );

    final r = Room();
    _room = r;

    debugPrint("🏠 [ROOM] Created Room instance hash=${r.hashCode}");
    debugPrint("⚙️ [ROOM] Options adaptiveStream=${roomOptions.adaptiveStream}, dynacast=${roomOptions.dynacast}");

    _cancelRoomEvents = r.events.listen((event) async {
      // Basic event log
      debugPrint("📡 [ROOM_EVENT] ${event.runtimeType}");

      // 1) Active speakers
      if (event is ActiveSpeakersChangedEvent) {
        final sids = event.speakers.map((p) => p.sid).toList();
        activeSpeakerSids.value = sids;
        debugPrint("🎙️ [SPEAKERS] Active speakers changed => $sids");
      }

      // 2) Connection flags
      if (event is RoomConnectedEvent) {
        isConnected.value = true;
        debugPrint("✅ [ROOM] Connected! role=${_isCaller ? "CALLER" : "CALLEE"}");

        // 🔔 RINGTONE STOP POINT (callee)
        if (!_isCaller) {
          debugPrint("🔕 [TONE] (CALLEE) STOP ringtone NOW (on RoomConnectedEvent)");
          // await speakerSvc.stopRingtone();
        }
      }

      if (event is RoomDisconnectedEvent) {
        isConnected.value = false;
        debugPrint("🛑 [ROOM] Disconnected");

        // 🔔 RINGTONE STOP POINT (any side)
        debugPrint("🔕 [TONE] STOP ringtone NOW (on RoomDisconnectedEvent)");
        // await speakerSvc.stopRingtone();
      }

      // 3) Participant connected (caller ringback stop)
      if (event is ParticipantConnectedEvent) {
        final p = event.participant;
        debugPrint("➕ [PARTICIPANT] Connected sid=${p.sid} identity=${p.identity} name=${p.name}");

        // 🔔 Caller should stop outgoing ringback once first remote joins
        if (_isCaller && p is RemoteParticipant && !_callerToneStopped) {
          _callerToneStopped = true;
          debugPrint("🔕 [TONE] (CALLER) STOP outgoing ringback NOW (remote joined)");
          // await speakerSvc.stopRingtone();
        }
      }

      if (event is ParticipantDisconnectedEvent) {
        final p = event.participant;
        debugPrint("➖ [PARTICIPANT] Disconnected sid=${p.sid} identity=${p.identity} name=${p.name}");
      }

      // 4) Rebuild UI list (local + all remotes) every event
      final speakingSet = activeSpeakerSids.toSet();
      final local = r.localParticipant;

      final localName = (local?.name?.isNotEmpty == true) ? local!.name! : (local?.identity ?? "");
      debugPrint("👤 [LOCAL] sid=${local?.sid} identity=${local?.identity} name=$localName");

      final list = <LKUiParticipant>[
        LKUiParticipant(
          sid: local?.sid ?? "",
          name: localName,
          isLocal: true,
          isSpeaking: speakingSet.contains(local?.sid),
        ),
      ];

      debugPrint("👥 [REMOTES] count=${r.remoteParticipants.length}");
      for (final rp in r.remoteParticipants.values) {
        final name = (rp.name?.isNotEmpty == true) ? rp.name! : rp.identity;
        list.add(
          LKUiParticipant(
            sid: rp.sid,
            name: name,
            isLocal: false,
            isSpeaking: speakingSet.contains(rp.sid),
          ),
        );
        debugPrint("   ↳ remote sid=${rp.sid} identity=${rp.identity} name=$name speaking=${speakingSet.contains(rp.sid)}");
      }

      participants.value = list;
      debugPrint("🧾 [UI_LIST] participants updated => total=${participants.length}");
    });

    try {
      debugPrint("🔌 [CONNECT] Connecting to url=${joinInfo.url} token=${(joinInfo.token ?? "").substring(0, (joinInfo.token ?? "").length.clamp(0, 10))}...");
      await r.connect(joinInfo.url ?? "", joinInfo.token ?? "", roomOptions: roomOptions);
      debugPrint("✅ [CONNECT] connect() completed");
    } catch (e, st) {
      debugPrint("❌ [CONNECT] Failed: $e");
      debugPrint("🧵 [CONNECT] Stack: $st");
      // 🔔 Stop tone if connect fails
      debugPrint("🔕 [TONE] STOP ringtone NOW (connect failed)");
      // await speakerSvc.stopRingtone();
      rethrow;
    }

    try {
      debugPrint("🎤 [MIC] Enabling microphone");
      await r.localParticipant?.setMicrophoneEnabled(true);
      isMicMuted.value = false;
      debugPrint("✅ [MIC] Microphone enabled");
    } catch (e) {
      debugPrint("❌ [MIC] Failed to enable mic: $e");
    }

    debugPrint("🔈 [AUDIO] Default speakerphone OFF (earpiece)");
    await setSpeakerphone(false);

    debugPrint("🏁 [JOIN] joinGroupAudio DONE");
  }

  Future<void> toggleMute() async {
    final r = _room;
    if (r == null) {
      debugPrint("⚠️ [MUTE] toggleMute ignored (room is null)");
      return;
    }

    final newMuted = !isMicMuted.value;
    debugPrint("🎛️ [MUTE] toggleMute => newMuted=$newMuted");
    try {
      await r.localParticipant?.setMicrophoneEnabled(!newMuted);
      isMicMuted.value = newMuted;
      debugPrint("✅ [MUTE] setMicrophoneEnabled(${!newMuted}) done");
    } catch (e) {
      debugPrint("❌ [MUTE] Failed: $e");
    }
  }

  Future<void> setSpeakerphone(bool enable) async {
    debugPrint("🔊 [SPEAKER] setSpeakerphone(enable=$enable)");
    isSpeakerOn.value = enable;

    try {
      await Hardware.instance.setSpeakerphoneOn(enable);
      debugPrint("✅ [SPEAKER] Hardware setSpeakerphoneOn($enable) done");
    } catch (e) {
      debugPrint("❌ [SPEAKER] Failed: $e");
    }
  }

  Future<void> leaveGroupAudio() async {
    debugPrint("📴 [LEAVE] leaveGroupAudio START");
    isConnected.value = false;

    // 🔔 Stop tone on leave
    debugPrint("🔕 [TONE] STOP ringtone NOW (leaveGroupAudio)");
    // await speakerSvc.stopRingtone();

    try {
      _cancelRoomEvents?.call();
      debugPrint("🛑 [LEAVE] CancelListenFunc called");
    } catch (e) {
      debugPrint("⚠️ [LEAVE] CancelListenFunc error: $e");
    }
    _cancelRoomEvents = null;

    try {
      await _room?.disconnect();
      debugPrint("✅ [LEAVE] room.disconnect() done");
    } catch (e) {
      debugPrint("⚠️ [LEAVE] room.disconnect() error: $e");
    }
    _room = null;

    participants.clear();
    activeSpeakerSids.clear();
    debugPrint("🧹 [LEAVE] cleared participants & speakers");

    isMicMuted.value = false;
    isSpeakerOn.value = false;

    debugPrint("✅ [LEAVE] leaveGroupAudio DONE");
  }

  @override
  void onClose() {
    debugPrint("🧨 [SERVICE] onClose called");
    leaveGroupAudio();
    super.onClose();
  }
}
