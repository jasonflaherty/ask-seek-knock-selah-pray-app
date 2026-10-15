import 'package:audioplayers/audioplayers.dart';

import '../domain/silence_bell.dart';

class AudioSilenceBell implements SilenceBell {
  AudioSilenceBell({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  static const _asset = 'sounds/bell.wav';

  @override
  Future<void> chime() async {
    await _player.stop();
    await _player.play(AssetSource(_asset));
  }

  @override
  Future<void> dispose() => _player.dispose();
}
