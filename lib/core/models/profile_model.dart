import 'package:hive/hive.dart';

part 'profile_model.g.dart';

@HiveType(typeId: 0)
class ControllerProfile extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double steeringDeadzone; // e.g. 0.05 (5%)

  @HiveField(3)
  double throttleDeadzone; // e.g. 0.02

  @HiveField(4)
  double brakeDeadzone; // e.g. 0.02

  @HiveField(5)
  int steeringRotationDegrees; // 270, 540, 900

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
  int playerId; // 0=P1 (Red), 1=P2 (Cyan), 2=P3 (Amber), 3=P4 (Purple)

  ControllerProfile({
    required this.id,
    required this.name,
    this.steeringDeadzone = 0.03,
    this.throttleDeadzone = 0.02,
    this.brakeDeadzone = 0.02,
    this.steeringRotationDegrees = 540,
    this.linearityMode = 'linear',
    this.gyroSteeringEnabled = false,
    this.gyroSensitivity = 1.0,
    this.hapticFeedbackEnabled = true,
    this.hardwareVolumePaddles = false,
    this.playerId = 0,
  });

  static ControllerProfile defaultF1Preset() {
    return ControllerProfile(
      id: 'f1_2025_default',
      name: 'F1 24/25 Official Preset',
      steeringDeadzone: 0.02,
      throttleDeadzone: 0.01,
      brakeDeadzone: 0.01,
      steeringRotationDegrees: 360,
      linearityMode: 'linear',
      gyroSteeringEnabled: false,
      gyroSensitivity: 1.0,
      hapticFeedbackEnabled: true,
      hardwareVolumePaddles: true,
      playerId: 0,
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
      gyroSteeringEnabled: false,
      gyroSensitivity: 1.0,
      hapticFeedbackEnabled: true,
      hardwareVolumePaddles: false,
      playerId: 0,
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
      gyroSteeringEnabled: false,
      gyroSensitivity: 1.0,
      hapticFeedbackEnabled: true,
      hardwareVolumePaddles: false,
      playerId: 0,
    );
  }
}
