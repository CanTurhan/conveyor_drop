import 'package:audioplayers/audioplayers.dart';

class GameAudioService {
  GameAudioService() {
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
    _musicPlayer.setVolume(0.42);

    _sfxPlayer.setReleaseMode(ReleaseMode.stop);
    _sfxPlayer.setVolume(0.70);
  }

  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _soundEnabled = true;
  bool _musicPlaying = false;

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;

    if (_soundEnabled) {
      await playMusic();
    } else {
      await stopMusic();
    }
  }

  Future<void> playMusic() async {
    if (!_soundEnabled || _musicPlaying) return;

    try {
      await _musicPlayer.play(
        AssetSource('audio/bg_music.wav'),
        mode: PlayerMode.mediaPlayer,
      );
      _musicPlaying = true;
    } catch (_) {
      _musicPlaying = false;
    }
  }

  Future<void> stopMusic() async {
    try {
      await _musicPlayer.stop();
    } finally {
      _musicPlaying = false;
    }
  }

  Future<void> playCorrectCatchEffect() async {
    if (!_soundEnabled) return;

    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(
        AssetSource('audio/blup.wav'),
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {
      // Ses efekti çalmazsa oyunu bozmasın.
    }
  }

  Future<void> dispose() async {
    await _musicPlayer.dispose();
    await _sfxPlayer.dispose();
  }
}
