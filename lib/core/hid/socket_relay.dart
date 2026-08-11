import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:vibration/vibration.dart';

class SocketRelay {
  RawDatagramSocket? _socket;
  String hostAddress = '192.168.1.100';
  int hostPort = 9999;
  
  double currentPingMs = 0.0;
  int packetsSent = 0;
  int _lastSentTimestamp = 0;
  int _lastPongTimestamp = 0;

  bool get isConnected {
    if (_socket == null) return false;
    int now = DateTime.now().millisecondsSinceEpoch;
    // If we have sent packets, but haven't received a pong in 3 seconds, we are disconnected
    if (packetsSent > 10 && (now - _lastPongTimestamp > 3000)) {
      return false;
    }
    return true;
  }

  Timer? _discoveryTimer;
  final StreamController<String> _discoveredHostsController = StreamController<String>.broadcast();
  Stream<String> get discoveredHosts => _discoveredHostsController.stream;

  Future<void> initSocket() async {
    try {
      _socket?.close();
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socket?.broadcastEnabled = true;

      _socket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram != null) {
            _handleIncomingPacket(datagram);
          }
        }
      });
    } catch (e) {
      _socket = null;
    }
  }

  void startAutoDiscovery() {
    _discoveryTimer?.cancel();
    _discoveryTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _sendBroadcastDiscovery();
    });
    _sendBroadcastDiscovery();
  }

  void stopAutoDiscovery() {
    _discoveryTimer?.cancel();
  }

  void _sendBroadcastDiscovery() {
    if (_socket == null) return;
    try {
      final msg = Uint8List.fromList('F1_CONTROLLER_DISCOVER'.codeUnits);
      _socket?.send(msg, InternetAddress('255.255.255.255'), hostPort);
    } catch (_) {}
  }

  void _handleIncomingPacket(Datagram datagram) {
    final text = String.fromCharCodes(datagram.data);
    if (text.startsWith('F1_HOST_PONG')) {
      int now = DateTime.now().millisecondsSinceEpoch;
      _lastPongTimestamp = now;
      if (_lastSentTimestamp > 0) {
        currentPingMs = (now - _lastSentTimestamp).toDouble().clamp(1.0, 999.0);
      }
    } else if (text.startsWith('F1_HOST_ANNOUNCE')) {
      final parts = text.split(':');
      if (parts.length >= 2) {
        String ip = datagram.address.address;
        _discoveredHostsController.add(ip);
      }
    } else if (text.startsWith('F1_VIB:')) {
      final parts = text.split(':');
      if (parts.length == 3) {
        int large = int.tryParse(parts[1]) ?? 0;
        int small = int.tryParse(parts[2]) ?? 0;
        _handleHapticFeedback(large, small);
      }
    }
  }

  void _handleHapticFeedback(int large, int small) async {
    if (large == 0 && small == 0) {
      Vibration.cancel();
      return;
    }
    
    // Calculate intensity 0-255
    int maxMotor = large > small ? large : small;
    if (maxMotor < 10) return; // Prevent micro vibrations from freezing the phone

    bool? hasCustom = await Vibration.hasCustomVibrationsSupport();
    if (hasCustom == true) {
      // Convert 0-255 to 1-255 amplitude
      Vibration.vibrate(duration: 150, amplitude: maxMotor.clamp(1, 255));
    } else {
      Vibration.vibrate(duration: 150);
    }
  }

  void sendPacket(Uint8List payload) {
    if (_socket == null) return;
    try {
      _lastSentTimestamp = DateTime.now().millisecondsSinceEpoch;
      _socket?.send(payload, InternetAddress(hostAddress), hostPort);
      packetsSent++;
    } catch (_) {}
  }

  void dispose() {
    stopAutoDiscovery();
    _socket?.close();
    _discoveredHostsController.close();
  }
}
