import 'package:audioplayers/audioplayers.dart';

class CallAudioManager {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playOutgoingRingtone() async {
    await _player.play(AssetSource('tunes/outgoing_ringtone.mp3'));
  }

  static Future<void> stopRingtone() async {
    await _player.stop();
  }
}
