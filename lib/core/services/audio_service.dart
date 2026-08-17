import 'package:audioplayers/audioplayers.dart';

/// Centralized service providing audio playback for background music
/// and game-related sound effects (SFX).
class AudioService {
  static final AudioPlayer _bgmPlayer = AudioPlayer();
  static final AudioPlayer _enginePlayer = AudioPlayer();
  static final AudioPlayer _sfxPlayer = AudioPlayer();

  static bool _isBgmPlaying = false;
  static bool _isEnginePlaying = false;
  
  static bool audioEnabled = true;

  static Future<void> init() async {
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _enginePlayer.setReleaseMode(ReleaseMode.loop);
  }

  /// Starts background music if enabled.
  static Future<void> playBgm() async {
    if (!audioEnabled || _isBgmPlaying) return;
    try {
      await _bgmPlayer.setVolume(0.4);
      await _bgmPlayer.play(AssetSource('audio/bgm.wav'));
      _isBgmPlaying = true;
    } catch (e) {
      // Ignored - handle missing assets gracefully
    }
  }

  /// Stops background music.
  static Future<void> stopBgm() async {
    if (!_isBgmPlaying) return;
    try {
      await _bgmPlayer.stop();
      _isBgmPlaying = false;
    } catch (e) {
      // Ignored
    }
  }

  /// Starts an engine loop sound for driving games.
  static Future<void> startEngine() async {
    if (!audioEnabled || _isEnginePlaying) return;
    try {
      await _enginePlayer.setVolume(0.5);
      await _enginePlayer.play(AssetSource('audio/engine_loop.wav'));
      _isEnginePlaying = true;
    } catch (e) {
      // Ignored
    }
  }

  /// Stops the engine sound.
  static Future<void> stopEngine() async {
    if (!_isEnginePlaying) return;
    try {
      await _enginePlayer.stop();
      _isEnginePlaying = false;
    } catch (e) {
      // Ignored
    }
  }

  /// Plays a short nitro sound effect.
  static Future<void> playNitroSound() async {
    if (!audioEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource('audio/nitro.wav'), volume: 0.8);
    } catch (e) {
      // Ignored
    }
  }

  /// Disposes all audio players to free up resources.
  static void dispose() {
    _bgmPlayer.dispose();
    _enginePlayer.dispose();
    _sfxPlayer.dispose();
  }
}
