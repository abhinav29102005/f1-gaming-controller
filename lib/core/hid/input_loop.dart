import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/controller_state.dart';
import '../models/profile_model.dart';
import 'connection_manager.dart';
import 'hid_report.dart';

class InputLoop {
  final ControllerState state;
  final ConnectionManager connectionManager;
  ControllerProfile profile;

  Timer? _timer;
  final HidReportSerializer _serializer = HidReportSerializer();

  bool isRunning = false;
  int _packetsThisSecond = 0;
  int currentHz = 0;
  Timer? _hzTimer;

  final ValueNotifier<int> hzNotifier = ValueNotifier<int>(0);

  InputLoop({
    required this.state,
    required this.connectionManager,
    required this.profile,
  });

  void start() {
    if (isRunning) return;
    isRunning = true;

    // High-frequency async tick loop for true real-time input
    // Timer.periodic has poor resolution on Android (~16ms).
    // This tight loop achieves ~500Hz actual throughput.
    _runTickLoop();

    _hzTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      currentHz = _packetsThisSecond;
      hzNotifier.value = currentHz;
      _packetsThisSecond = 0;
    });
  }

  Future<void> _runTickLoop() async {
    while (isRunning) {
      _tick();
      // 2ms target = ~500Hz. Future.delayed yields to the engine
      // but resumes much faster than Timer.periodic on Android.
      await Future.delayed(const Duration(milliseconds: 2));
    }
  }

  void updateProfile(ControllerProfile newProfile) {
    profile = newProfile;
  }

  void _tick() {
    final report = _serializer.packReport(state, profile);
    connectionManager.sendReport(
      report,
      connectionManager.socketRelay.hostAddress,
      connectionManager.socketRelay.hostPort,
    );
    _packetsThisSecond++;
  }

  void stop() {
    isRunning = false;
    _timer?.cancel();
    _hzTimer?.cancel();
  }

  void dispose() {
    stop();
    hzNotifier.dispose();
  }
}
