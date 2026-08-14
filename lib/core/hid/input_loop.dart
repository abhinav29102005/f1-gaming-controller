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

  Timer? _keepAliveTimer;
  Timer? _hzTimer;
  final HidReportSerializer _serializer = HidReportSerializer();

  bool isRunning = false;
  int _packetsThisSecond = 0;
  int currentHz = 0;

  final ValueNotifier<int> hzNotifier = ValueNotifier<int>(0);

  int _lastSendTime = 0;
  final Uint8List _lastReportBytes = Uint8List(10);
  bool _hasLastReport = false;

  InputLoop({
    required this.state,
    required this.connectionManager,
    required this.profile,
  }) {
    // Instantly send a packet the exact millisecond state changes (0ms input latency)
    state.addListener(_onStateChanged);
  }

  void start() {
    if (isRunning) return;
    isRunning = true;

    // Lightweight 50Hz (20ms) periodic keepalive timer
    // Replaces the heavy 1000Hz Future.delayed loop that caused mobile hanging
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
      _tick(isKeepAlive: true);
    });

    _hzTimer?.cancel();
    _hzTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      currentHz = _packetsThisSecond;
      hzNotifier.value = currentHz;
      _packetsThisSecond = 0;
    });
  }

  void _onStateChanged() {
    if (isRunning) {
      _tick(isKeepAlive: false);
    }
  }

  void updateProfile(ControllerProfile newProfile) {
    profile = newProfile;
  }

  void _tick({bool isKeepAlive = false}) {
    final report = _serializer.packReport(state, profile);

    int now = DateTime.now().millisecondsSinceEpoch;
    bool changed = false;

    if (!_hasLastReport) {
      changed = true;
    } else {
      // Compare bytes (skip sequence number at byte 2)
      for (int i = 3; i < report.length; i++) {
        if (report[i] != _lastReportBytes[i]) {
          changed = true;
          break;
        }
      }
    }

    // Send immediately if state changed OR if keepalive interval (15ms) passed
    if (changed || isKeepAlive || (now - _lastSendTime) >= 15) {
      _lastReportBytes.setRange(0, report.length, report);
      _hasLastReport = true;
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
    _keepAliveTimer?.cancel();
    _hzTimer?.cancel();
  }

  void dispose() {
    stop();
    state.removeListener(_onStateChanged);
    hzNotifier.dispose();
  }
}
