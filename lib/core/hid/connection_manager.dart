import 'dart:typed_data';

import '../models/connection_stats.dart';
import 'native_hid_bridge.dart';
import 'socket_relay.dart';

class ConnectionManager {
  TransportMode activeMode = TransportMode.udpRelay;
  final SocketRelay socketRelay = SocketRelay();
  bool isBleHidRegistered = false;

  Future<void> init() async {
    await socketRelay.initSocket();
  }

  Future<bool> setMode(TransportMode mode, {String? hostAddress, int? port, String? deviceName}) async {
    activeMode = mode;
    if (mode == TransportMode.udpRelay) {
      if (hostAddress != null) socketRelay.hostAddress = hostAddress;
      if (port != null) socketRelay.hostPort = port;
      await socketRelay.initSocket();
      return true;
    } else {
      bool supported = await NativeHidBridge.isBleHidSupported();
      if (supported) {
        isBleHidRegistered = await NativeHidBridge.registerHidDevice(deviceName ?? 'F1 Controller');
        return isBleHidRegistered;
      }
      return false;
    }
  }

  void sendReport(Uint8List report, String hostAddress, int port) {
    if (activeMode == TransportMode.udpRelay) {
      // Use direct Kotlin UDP sender for minimal channel latency or SocketRelay
      NativeHidBridge.sendUdpPacket(hostAddress, port, report);
    } else {
      NativeHidBridge.sendHidReport(report);
    }
  }

  ConnectionStats getStats() {
    return ConnectionStats(
      mode: activeMode,
      isConnected: activeMode == TransportMode.udpRelay ? socketRelay.isConnected : isBleHidRegistered,
      hostAddress: socketRelay.hostAddress,
      hostPort: socketRelay.hostPort,
      pingMs: socketRelay.currentPingMs,
      totalPacketsSent: socketRelay.packetsSent,
    );
  }

  void dispose() {
    socketRelay.dispose();
  }
}
