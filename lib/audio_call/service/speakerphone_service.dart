// audio_call/service/speakerphone_service.dart
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class SpeakerphoneService extends GetxService {
  static const platform = MethodChannel('audio_channel');
  
  final isSpeakerOn = false.obs;
  
  Future<void> setSpeakerphoneOn(bool on) async {
    try {
      final result = await platform.invokeMethod('setSpeakerphoneOn', on);
      if (result == true) {
        isSpeakerOn.value = on;
        print("🔊 Speakerphone ${on ? 'ON' : 'OFF'}");
      } else {
        print("❌ Failed to set speakerphone");
      }
    } on PlatformException catch (e) {
      print("❌ Failed to set speakerphone: '${e.message}'");
    }
  }
  
  Future<void> toggleSpeakerphone() async {
    await setSpeakerphoneOn(!isSpeakerOn.value);
  }
}