import 'package:flutter_test/flutter_test.dart';
import 'package:f1_gaming_controller/core/models/controller_state.dart';
import 'package:f1_gaming_controller/core/models/profile_model.dart';
import 'package:f1_gaming_controller/core/hid/hid_report.dart';

void main() {
  group('HidReportSerializer Tests', () {
    late HidReportSerializer serializer;
    late ControllerState state;
    late ControllerProfile profile;

    setUp(() {
      serializer = HidReportSerializer();
      state = ControllerState();
      profile = ControllerProfile.defaultF1Preset();
    });

    test('Magic header byte and player ID packed correctly', () {
      state.playerId = 2; // P3
      final buffer = serializer.packReport(state, profile);

      expect(buffer[0], equals(0xF1));
      expect(buffer[1], equals(2));
    });

    test('Steering deadzone clamps small values to zero', () {
      state.steering = 0.01; // Below default 0.02 deadzone
      final buffer = serializer.packReport(state, profile);

      int steerInt16 = (buffer[3] << 8) | buffer[4];
      expect(steerInt16, equals(0));
    });

    test('Full steering right packs to Int16 max 32767', () {
      state.steering = 1.0;
      final buffer = serializer.packReport(state, profile);

      int steerInt16 = (buffer[3] << 8) | buffer[4];
      expect(steerInt16, equals(32767));
    });

    test('Throttle and Brake uint8 packing', () {
      state.throttle = 1.0;
      state.brake = 0.5;

      final buffer = serializer.packReport(state, profile);

      expect(buffer[5], equals(255)); // Throttle
      expect(buffer[6], greaterThan(120)); // Brake approx half
    });

    test('Buttons packed into bitmask', () {
      state.drs = true;
      state.paddleUpshift = true;

      final buffer = serializer.packReport(state, profile);

      int mask = (buffer[8] << 8) | buffer[9];
      expect(mask & (1 << 0), isNot(0)); // DRS
      expect(mask & (1 << 7), isNot(0)); // Upshift
    });
  });
}
