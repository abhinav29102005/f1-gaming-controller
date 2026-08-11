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

    // 250Hz = 4ms tick rate
    _timer = Timer.periodic(const Duration(milliseconds: 4), (_) {
      _tick();
    });

    _hzTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      currentHz = _packetsThisSecond;
      hzNotifier.value = currentHz;
      _packetsThisSecond = 0;
    });
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
