import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/controller_state.dart';

class HostPlayerInfo {
  final int playerId;
  final String remoteIp;
  int packetsThisSecond = 0;
  int currentHz = 0;
  double lastPingMs = 4.0;
  int lastPacketTime = 0;
  final ControllerState state = ControllerState();

  HostPlayerInfo({required this.playerId, required this.remoteIp});
}

class HostReceiverEngine {
  RawDatagramSocket? _socket;
  bool isListening = false;
  int port = 9999;

  final Map<int, HostPlayerInfo> activePlayers = {};
  Timer? _hzTimer;

  final ValueNotifier<int> activeCountNotifier = ValueNotifier<int>(0);
  final StreamController<int> _packetStreamController = StreamController<int>.broadcast();
  Stream<int> get packetStream => _packetStreamController.stream;

  Future<bool> startServer({int bindPort = 9999}) async {
    port = bindPort;
    try {
      _socket?.close();
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
      _socket?.broadcastEnabled = true;

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

  void _handleDatagram(Datagram datagram) {
    final data = datagram.data;
    final textStr = String.fromCharCodes(data);

    // Auto-Discovery request from mobile controllers
    if (textStr.startsWith('F1_CONTROLLER_DISCOVER')) {
      final announce = Uint8List.fromList('F1_HOST_ANNOUNCE:$port'.codeUnits);
      _socket?.send(announce, datagram.address, datagram.port);
      return;
    }

    // Binary Gamepad Report (10 Bytes)
    if (data.length >= 10 && data[0] == 0xF1) {
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
        () => HostPlayerInfo(playerId: playerId, remoteIp: datagram.address.address),
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

      _packetStreamController.add(playerId);
    }
  }

  void stopServer() {
    isListening = false;
    _hzTimer?.cancel();
    _socket?.close();
  }

  void dispose() {
    stopServer();
    activeCountNotifier.dispose();
    _packetStreamController.close();
  }
}
