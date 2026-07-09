import 'package:audioplayers/audioplayers.dart';

class GameAudioService {
  GameAudioService() {
    _player.setReleaseMode(ReleaseMode.loop);
    _player.setVolume(0.45);
  }

  final AudioPlayer _player = AudioPlayer();

  bool _soundEnabled = true;
  bool _isPlaying = false;

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;

    if (_soundEnabled) {
      await playMusic();
    } else {
      await stopMusic();
    }
  }

  Future<void> playMusic() async {
    if (!_soundEnabled || _isPlaying) return;

    try {
      await _player.play(AssetSource('audio/bg_music.wav'));
      _isPlaying = true;
    } catch (_) {
      _isPlaying = false;
    }
  }

  Future<void> stopMusic() async {
    try {
      await _player.stop();
    } finally {
      _isPlaying = false;
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
