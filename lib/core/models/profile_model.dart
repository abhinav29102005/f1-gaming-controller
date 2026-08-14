import 'package:hive/hive.dart';

part 'profile_model.g.dart';

@HiveType(typeId: 0)
class ControllerProfile extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double steeringDeadzone;

  @HiveField(3)
  double throttleDeadzone;

  @HiveField(4)
  double brakeDeadzone;

  @HiveField(5)
  int steeringRotationDegrees;

  @HiveField(6)
  String linearityMode; // "linear", "exponential", "s_curve"

  @HiveField(7)
  bool gyroSteeringEnabled;

  @HiveField(8)
  double gyroSensitivity;

  @HiveField(9)
  bool hapticFeedbackEnabled;

  @HiveField(10)
  bool hardwareVolumePaddles;

  @HiveField(11)
  int playerId; // 0=P1, 1=P2, 2=P3, 3=P4

  @HiveField(12)
  bool swapPaddleShifters;

  @HiveField(13)
  bool invertGyro;

  @HiveField(14)
  double gyroDeadzone;

  @HiveField(15)
  String layoutMode; // 'f1_racing' | 'tekken_8' | 'generic'

  @HiveField(16)
  bool soundFeedbackEnabled;

  ControllerProfile({
    required this.id,
    required this.name,
    this.steeringDeadzone = 0.03,
    this.throttleDeadzone = 0.02,
    this.brakeDeadzone = 0.02,
    this.steeringRotationDegrees = 360,
    this.linearityMode = 'linear',
    this.gyroSteeringEnabled = true,
    this.gyroSensitivity = 1.5,
    this.hapticFeedbackEnabled = true,
    this.hardwareVolumePaddles = false,
    this.playerId = 0,
    this.swapPaddleShifters = false,
    this.invertGyro = false,
    this.gyroDeadzone = 0.02,
    this.layoutMode = 'f1_racing',
    this.soundFeedbackEnabled = true,
  });

  // ── Built-in Presets ──────────────────────────────────────────────

  static ControllerProfile defaultF1Preset() {
    return ControllerProfile(
      id: 'f1_2025_default',
      name: 'F1 24/25 Official Preset',
      steeringDeadzone: 0.02,
      throttleDeadzone: 0.01,
      brakeDeadzone: 0.01,
      steeringRotationDegrees: 360,
      linearityMode: 'linear',
      gyroSteeringEnabled: true,
      gyroSensitivity: 1.5,
      hapticFeedbackEnabled: true,
      soundFeedbackEnabled: true,
      hardwareVolumePaddles: true,
      playerId: 0,
      swapPaddleShifters: false,
      invertGyro: false,
      gyroDeadzone: 0.02,
      layoutMode: 'f1_racing',
    );
  }

  static ControllerProfile gt3Preset() {
    return ControllerProfile(
      id: 'gt3_preset',
      name: 'GT3 / Endurance Preset',
      steeringDeadzone: 0.04,
      throttleDeadzone: 0.03,
      brakeDeadzone: 0.03,
      steeringRotationDegrees: 540,
      linearityMode: 'exponential',
      gyroSteeringEnabled: true,
      gyroSensitivity: 1.3,
      hapticFeedbackEnabled: true,
      soundFeedbackEnabled: true,
      hardwareVolumePaddles: false,
      playerId: 0,
      swapPaddleShifters: false,
      invertGyro: false,
      gyroDeadzone: 0.04,
      layoutMode: 'f1_racing',
    );
  }

  static ControllerProfile genericGamepadPreset() {
    return ControllerProfile(
      id: 'generic_preset',
      name: 'Generic Gamepad / Arcade',
      steeringDeadzone: 0.05,
      throttleDeadzone: 0.05,
      brakeDeadzone: 0.05,
      steeringRotationDegrees: 900,
      linearityMode: 's_curve',
      gyroSteeringEnabled: true,
      gyroSensitivity: 1.8,
      hapticFeedbackEnabled: true,
      soundFeedbackEnabled: true,
      hardwareVolumePaddles: false,
      playerId: 0,
      swapPaddleShifters: false,
      invertGyro: false,
      gyroDeadzone: 0.05,
      layoutMode: 'generic',
    );
  }

  static ControllerProfile tekken8Preset() {
    return ControllerProfile(
      id: 'tekken8_preset',
      name: 'Tekken 8 Official Fight Pad',
      steeringDeadzone: 0.0,
      throttleDeadzone: 0.0,
      brakeDeadzone: 0.0,
      steeringRotationDegrees: 360,
      linearityMode: 'linear',
      gyroSteeringEnabled: false,
      gyroSensitivity: 1.0,
      hapticFeedbackEnabled: true,
      soundFeedbackEnabled: true,
      hardwareVolumePaddles: false,
      playerId: 0,
      swapPaddleShifters: false,
      invertGyro: false,
      gyroDeadzone: 0.0,
      layoutMode: 'tekken_8',
    );
  }

  static ControllerProfile tekken7Preset() => tekken8Preset();
}

