import 'dart:typed_data';
import '../models/controller_state.dart';
import '../models/profile_model.dart';

class HidReportSerializer {
  // Pre-allocated 10-byte buffer for zero-GC allocation ticks
  final Uint8List _buffer = Uint8List(10);
  int _sequenceNumber = 0;

  Uint8List get buffer => _buffer;

  Uint8List packReport(ControllerState state, ControllerProfile profile) {
    _sequenceNumber = (_sequenceNumber + 1) & 0xFF;

    // Apply deadzones & response curves
    double steerProcessed = _applyAxisCurves(
      state.steering,
      profile.steeringDeadzone,
      profile.linearityMode,
    );

    double throttleProcessed = _applyUnidirectionalCurves(
      state.throttle,
      profile.throttleDeadzone,
      profile.linearityMode,
    );

    double brakeProcessed = _applyUnidirectionalCurves(
      state.brake,
      profile.brakeDeadzone,
      profile.linearityMode,
    );

    // Map steering (-1.0 to 1.0) -> Int16 (-32768 to 32767)
    int steerInt16 = (steerProcessed * 32767.0).clamp(-32768.0, 32767.0).round();
    if (steerInt16 < 0) steerInt16 += 65536;

    // Map throttle & brake (0.0 to 1.0) -> Uint8 (0 to 255)
    int throttleByte = (throttleProcessed * 255.0).clamp(0.0, 255.0).round();
    int brakeByte = (brakeProcessed * 255.0).clamp(0.0, 255.0).round();

    // 0: Magic Byte 'F1'
    _buffer[0] = 0xF1;
    // 1: Player ID (0..3)
    _buffer[1] = state.playerId & 0x03;
    // 2: Sequence Number
    _buffer[2] = _sequenceNumber;
    // 3 & 4: Steering Int16
    _buffer[3] = (steerInt16 >> 8) & 0xFF;
    _buffer[4] = steerInt16 & 0xFF;
    // 5: Throttle Byte
    _buffer[5] = throttleByte;
    // 6: Brake Byte
    _buffer[6] = brakeByte;
    // 7: D-Pad Hat Switch
    _buffer[7] = state.dpad & 0x0F;
    // 8 & 9: Button Bitmask (16 bits)
    int buttons = state.buttonBitmask;
    _buffer[8] = (buttons >> 8) & 0xFF;
    _buffer[9] = buttons & 0xFF;

    return _buffer;
  }

  static double _applyAxisCurves(double value, double deadzone, String curveMode) {
    if (value.abs() < deadzone) return 0.0;
    double sign = value < 0 ? -1.0 : 1.0;
    double normalized = (value.abs() - deadzone) / (1.0 - deadzone);
    normalized = normalized.clamp(0.0, 1.0);

    switch (curveMode) {
      case 'exponential':
        return sign * (normalized * normalized);
      case 's_curve':
        return sign * (3 * normalized * normalized - 2 * normalized * normalized * normalized);
      case 'linear':
      default:
        return sign * normalized;
    }
  }

  static double _applyUnidirectionalCurves(double value, double deadzone, String curveMode) {
    if (value < deadzone) return 0.0;
    double normalized = (value - deadzone) / (1.0 - deadzone);
    normalized = normalized.clamp(0.0, 1.0);

    switch (curveMode) {
      case 'exponential':
        return normalized * normalized;
      case 's_curve':
        return 3 * normalized * normalized - 2 * normalized * normalized * normalized;
      case 'linear':
      default:
        return normalized;
    }
  }
}
