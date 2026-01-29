import 'package:chat_app/audio_call/controller/call_session_controller.dart';
import 'package:chat_app/audio_call/service/speakerphone_service.dart';
import 'package:chat_app/chat_app.dart';
import 'package:chat_app/group_audio_video_call/service/livekit_group_audio_service.dart';
import 'package:get/get.dart';


class GlobalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(()=>ViewMembersController(), fenix: true);
    Get.lazyPut(() => ChatAddMembersController(),fenix:true);
    // Get.put(CallSignalingService(), permanent: true);
    Get.put(WebRTCService(), permanent: true);
    Get.put(PingWebSocketService(),permanent: true);
   
    Get.put(LiveKitGroupAudioService(), permanent: true);
   

    // ✅ Signaling socket for call events only
    Get.put(CallSessionController(), permanent: true);

    // ✅ Keep if you want ringtone stop/start always available
    Get.put(SpeakerphoneService(), permanent: true);
    
  }
}