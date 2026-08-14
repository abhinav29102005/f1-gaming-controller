import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Centralized service providing physical haptics (max hardware amplitude)
/// and speaker audio synthesized sound effects across all controller inputs.
class FeedbackService {
  static const MethodChannel _feedbackChannel =
      MethodChannel('com.example.f1_gaming_controller/feedback');

  static bool hapticsEnabled = true;
  static bool soundEnabled = true;

  // ── Haptic Presets ────────────────────────────────────────────────

  /// Light tick for navigation or subtle slider changes
  static void lightTick() {
    if (!hapticsEnabled) return;
    _triggerNativeHaptic(durationMs: 12, amplitude: 120);
    _triggerSound(freq: 800.0, durationMs: 25, volume: 0.3);
  }

  /// Medium click for button taps and D-Pad directions
  static void mediumClick() {
    if (!hapticsEnabled) return;
    _triggerNativeHaptic(durationMs: 20, amplitude: 200);
    _triggerSound(freq: 600.0, durationMs: 40, volume: 0.6);
  }

  /// Heavy impact for main attack buttons and triggers
  static void heavyImpact() {
    if (!hapticsEnabled) return;
    _triggerNativeHaptic(durationMs: 32, amplitude: 255);
    _triggerSound(freq: 440.0, durationMs: 60, volume: 0.9);
  }

  /// Distinct mechanical click for paddle gear shifters
  static void gearShift() {
    if (!hapticsEnabled) return;
    _triggerNativeHaptic(durationMs: 25, amplitude: 240);
    _triggerSound(freq: 950.0, durationMs: 35, volume: 0.8);
  }

  /// Powerful Tekken 8 Strike / Combo impact
  static void tekkenStrike() {
    if (!hapticsEnabled) return;
    _triggerNativeHaptic(durationMs: 45, amplitude: 255);
    _triggerSound(freq: 350.0, durationMs: 80, volume: 1.0);
  }

  /// Ultimate Heat Smash burst feedback
  static void heatSmash() {
    if (!hapticsEnabled) return;
    _triggerNativeHaptic(durationMs: 80, amplitude: 255);
    _triggerSound(freq: 220.0, durationMs: 120, volume: 1.0);
  }

  // ── Internal Dispatch ─────────────────────────────────────────────

  static void _triggerNativeHaptic({
    required int durationMs,
    required int amplitude,
  }) async {
    try {
      await _feedbackChannel.invokeMethod('triggerHaptic', {
        'duration': durationMs,
        'amplitude': amplitude,
      });
    } catch (_) {
      // Fallback to Vibration plugin if method channel fails
      Vibration.hasVibrator().then((has) {
        if (has == true) {
          Vibration.vibrate(duration: durationMs, amplitude: amplitude);
        }
      });
    }
  }

  static void _triggerSound({
    required double freq,
    required int durationMs,
    required double volume,
  }) async {
    if (!soundEnabled) return;
    try {
      await _feedbackChannel.invokeMethod('playSpeakerTone', {
        'freq': freq,
        'durationMs': durationMs,
        'volume': volume,
      });
    } catch (_) {
      // Fallback to system sound if needed
      SystemSound.play(SystemSoundType.click);
    }
  }
}
