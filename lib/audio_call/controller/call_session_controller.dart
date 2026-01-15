import 'package:get/get.dart';

class CallSessionController extends GetxController {
  /// Required
  final roomId = "".obs; // callId
  final peerId = "".obs; // callerId / calleeId
  final peerName = "".obs; // callerName / calleeName

  /// Mode
  /// ✅ Default is VIDEO call
  final isVideo = true.obs;

  /// UI-only
  final isMuted = false.obs;
  final isSpeakerOn = false.obs;
  final isCaller = false.obs;
  final fromNotification = false.obs;

  /// Video UI state
  final isVideoMuted = false.obs; // local camera enabled/disabled

  void hydrate({
    required String roomId,
    required bool isCaller,
    bool fromNotification = false,
    String peerId = "",
    String peerName = "",
    bool? isVideo, // optional override; default true if null
  }) {
    this.roomId.value = roomId;
    this.isCaller.value = isCaller;
    this.fromNotification.value = fromNotification;

    if (peerId.isNotEmpty) this.peerId.value = peerId;
    if (peerName.isNotEmpty) this.peerName.value = peerName;

    // ✅ default video
    this.isVideo.value = isVideo ?? true;
  }

  void reset() {
    roomId.value = "";
    peerId.value = "";
    peerName.value = "";
    isVideo.value = true;

    isMuted.value = false;
    isSpeakerOn.value = false;
    isCaller.value = false;
    fromNotification.value = false;
    isVideoMuted.value = false;
  }
}
