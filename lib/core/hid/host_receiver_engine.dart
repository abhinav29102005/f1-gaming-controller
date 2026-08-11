import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/controller_state.dart';

class HostPlayerInfo {
  final int playerId;
  final String remoteIp;
  final int remotePort;
  int packetsThisSecond = 0;
  int currentHz = 0;
  double lastPingMs = 4.0;
  int lastPacketTime = 0;
  final ControllerState state = ControllerState();

  HostPlayerInfo({required this.playerId, required this.remoteIp, required this.remotePort});
}

class HostReceiverEngine {
  RawDatagramSocket? _socket;
  bool isListening = false;
  int port = 9999;

  final Map<int, HostPlayerInfo> activePlayers = {};
  Timer? _hzTimer;
  Process? _pythonProcess;
  bool companionError = false;

  int rawPacketsReceived = 0;
  String lastRawPacketType = "NONE";
  String lastRawPacketTime = "Never";

  final ValueNotifier<int> activeCountNotifier = ValueNotifier<int>(0);
  final StreamController<int> _packetStreamController = StreamController<int>.broadcast();
  Stream<int> get packetStream => _packetStreamController.stream;

  Future<bool> startServer({int bindPort = 9999}) async {
    port = bindPort;
    try {
      companionError = false;
      _socket?.close();
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
      _socket?.broadcastEnabled = true;

      // On Windows, launch the Virtual Gamepad relay script automatically
      if (Platform.isWindows) {
        _launchCompanionServer();
      }

      _socket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram != null) {
            _handleDatagram(datagram);
          }
        }
      });

      isListening = true;

      _hzTimer?.cancel();
      _hzTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        int active = 0;
        int now = DateTime.now().millisecondsSinceEpoch;
        activePlayers.forEach((id, player) {
          player.currentHz = player.packetsThisSecond;
          player.packetsThisSecond = 0;
          if (now - player.lastPacketTime < 3000) {
            active++;
          }
        });
        activeCountNotifier.value = active;
      });

      return true;
    } catch (e) {
      isListening = false;
      return false;
    }
  }

  Future<void> _launchCompanionServer() async {
    try {
      // Look for setup.bat in relative path (development) or next to the executable (production)
      File setupFile = File('companion_server\\setup.bat');
      if (!setupFile.existsSync()) {
        final execDir = File(Platform.resolvedExecutable).parent.path;
        setupFile = File('$execDir\\companion_server\\setup.bat');
      }

      if (setupFile.existsSync()) {
        _pythonProcess = await Process.start(
          setupFile.absolute.path,
          ['--slave'],
          workingDirectory: setupFile.parent.absolute.path,
          runInShell: true,
        );
        debugPrint('Launched Virtual Xbox Companion Server: ${_pythonProcess?.pid}');
        
        _pythonProcess?.exitCode.then((code) {
          if (isListening && code != 0) {
            companionError = true;
            _packetStreamController.add(-1); // Trigger UI rebuild
          }
        });
      } else {
        companionError = true;
        debugPrint('WARNING: Could not find companion_server\\setup.bat');
        _packetStreamController.add(-1); // Trigger UI rebuild
      }
    } catch (e) {
      companionError = true;
      debugPrint('Failed to launch companion server: $e');
      _packetStreamController.add(-1);
    }
  }

  void _handleDatagram(Datagram datagram) {
    final data = datagram.data;
    if (data.isEmpty) return;

    rawPacketsReceived++;
    final now = DateTime.now();
    lastRawPacketTime = "${now.hour}:${now.minute}:${now.second}.${now.millisecond}";

    final textStr = String.fromCharCodes(data);

    // Auto-Discovery request from mobile controllers
    if (textStr.startsWith('F1_CONTROLLER_DISCOVER')) {
      lastRawPacketType = "BROADCAST_DISCOVER";
      _packetStreamController.add(-1);
      final announce = Uint8List.fromList('F1_HOST_ANNOUNCE:$port'.codeUnits);
      _socket?.send(announce, datagram.address, datagram.port);
      return;
    }

    // Haptic Feedback from Python Slave -> Forward to Mobile App
    if (textStr.startsWith('F1_VIB:')) {
      lastRawPacketType = "INTERNAL_VIBRATION";
      _packetStreamController.add(-1);
      if (activePlayers.isNotEmpty) {
        // Forward to the primary connected mobile client (Player 0)
        final player = activePlayers[0] ?? activePlayers.values.first;
        try {
          _socket?.send(data, InternetAddress(player.remoteIp), player.remotePort);
        } catch (_) {}
      }
      return;
    }

    // Binary Gamepad Report (10 Bytes)
    if (data.length >= 10 && data[0] == 0xF1) {
      lastRawPacketType = "TELEMETRY";
      int playerId = data[1] & 0x03;
      int seq = data[2];

      // Decode Steering Int16 (-32768 to 32767)
      int steerRaw = (data[3] << 8) | data[4];
      if (steerRaw > 32767) steerRaw -= 65536;
      double steerNorm = (steerRaw / 32767.0).clamp(-1.0, 1.0);

      // Decode Throttle & Brake uint8 (0 to 255)
      double throttleNorm = (data[5] / 255.0).clamp(0.0, 1.0);
      double brakeNorm = (data[6] / 255.0).clamp(0.0, 1.0);

      // Decode D-Pad & Buttons bitmask
      int dpad = data[7] & 0x0F;
      int buttons = (data[8] << 8) | data[9];

      HostPlayerInfo player = activePlayers.putIfAbsent(
        playerId,
        () => HostPlayerInfo(playerId: playerId, remoteIp: datagram.address.address, remotePort: datagram.port),
      );

      player.lastPacketTime = DateTime.now().millisecondsSinceEpoch;
      player.packetsThisSecond++;
      player.state.playerId = playerId;
      player.state.steering = steerNorm;
      player.state.throttle = throttleNorm;
      player.state.brake = brakeNorm;
      player.state.dpad = dpad;

      // Extract button bitmask flags
      player.state.drs = (buttons & (1 << 0)) != 0;
      player.state.ers = (buttons & (1 << 1)) != 0;
      player.state.pitLimiter = (buttons & (1 << 2)) != 0;
      player.state.radio = (buttons & (1 << 3)) != 0;
      player.state.boxBox = (buttons & (1 << 4)) != 0;
      player.state.engineMapUp = (buttons & (1 << 5)) != 0;
      player.state.engineMapDown = (buttons & (1 << 6)) != 0;
      player.state.paddleUpshift = (buttons & (1 << 7)) != 0;
      player.state.paddleDownshift = (buttons & (1 << 8)) != 0;

      // Send Pong RTT
      final pongMsg = Uint8List.fromList('F1_HOST_PONG:$seq'.codeUnits);
      _socket?.send(pongMsg, datagram.address, datagram.port);

      // Forward to local Python slave process
      if (Platform.isWindows && _pythonProcess != null) {
        _socket?.send(data, InternetAddress.loopbackIPv4, 9998);
      }

      _packetStreamController.add(playerId);
    }
  }

  void stopServer() {
    isListening = false;
    _hzTimer?.cancel();
    _socket?.close();
    
    if (_pythonProcess != null) {
      // Force kill the cmd tree
      Process.run('taskkill', ['/F', '/T', '/PID', _pythonProcess!.pid.toString()]);
      _pythonProcess = null;
      debugPrint('Killed Virtual Xbox Companion Server');
    }
  }

  void dispose() {
    stopServer();
    activeCountNotifier.dispose();
    _packetStreamController.close();
  }
}
