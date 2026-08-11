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

  int _lastSendTime = 0;
  Uint8List? _lastReportBytes;

  Future<void> _runTickLoop() async {
    while (isRunning) {
      _tick();
      // Internal polling engine runs at 1000Hz (1ms) for 0ms latency
      await Future.delayed(const Duration(milliseconds: 1));
    }
  }

  void updateProfile(ControllerProfile newProfile) {
    profile = newProfile;
  }

  void _tick() {
    final report = _serializer.packReport(state, profile);
    
    // Delta-Sending Logic:
    // Only send if the report has changed, OR if 10ms (keepalive) has passed.
    // This prevents Android's USB network stack from choking on 1000Hz polling.
    bool changed = false;
    if (_lastReportBytes == null) {
      changed = true;
    } else {
      // Compare bytes (skip sequence number at byte 2)
      for (int i = 3; i < report.length; i++) {
        if (report[i] != _lastReportBytes![i]) {
          changed = true;
          break;
        }
      }
    }

    int now = DateTime.now().millisecondsSinceEpoch;
    if (changed || (now - _lastSendTime) >= 10) {
      _lastReportBytes = Uint8List.fromList(report);
      _lastSendTime = now;
      
      connectionManager.sendReport(
        report,
        connectionManager.socketRelay.hostAddress,
        connectionManager.socketRelay.hostPort,
      );
      _packetsThisSecond++;
    }
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
