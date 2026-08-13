import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:vibration/vibration.dart';

/// Connection quality classification based on ping.
enum ConnectionQuality {
  excellent, // < 5ms
  good,      // 5-20ms
  degraded,  // 20-60ms
  poor,      // > 60ms
  disconnected,
}

/// UDP socket relay with QoS, reconnect watchdog, sequence-matched ping,
/// jitter tracking, and adaptive discovery backoff.
class SocketRelay {
  RawDatagramSocket? _socket;
  String hostAddress = '192.168.1.100';
  int hostPort = 9999;

  // ── Connection state ──────────────────────────────────────────────
  double currentPingMs = 0.0;
  double jitterMs = 0.0;
  int packetsSent = 0;
  int _lastPongTimestamp = 0;

  // ── Sequence-matched ping tracking ────────────────────────────────
  final Map<int, int> _pendingPingTimestamps = {};
  final List<double> _rttSamples = [];

  bool get isConnected {
    if (_socket == null) return false;
    int now = DateTime.now().millisecondsSinceEpoch;
    // Disconnected if 10+ packets sent but no PONG in 3s
    if (packetsSent > 10 && (now - _lastPongTimestamp > 3000)) {
      return false;
    }
    return packetsSent > 0 && (now - _lastPongTimestamp < 3000);
  }

  ConnectionQuality get connectionQuality {
    if (!isConnected) return ConnectionQuality.disconnected;
    if (currentPingMs < 5.0) return ConnectionQuality.excellent;
    if (currentPingMs < 20.0) return ConnectionQuality.good;
    if (currentPingMs < 60.0) return ConnectionQuality.degraded;
    return ConnectionQuality.poor;
  }

  // ── Discovery ──────────────────────────────────────────────────────
  Timer? _discoveryTimer;
  int _discoveryCount = 0;
  final StreamController<String> _discoveredHostsController =
      StreamController<String>.broadcast();
  Stream<String> get discoveredHosts => _discoveredHostsController.stream;

  // ── Reconnect watchdog ─────────────────────────────────────────────
  Timer? _reconnectWatchdog;

  // ══════════════════════════════════════════════════════════════════
  // Initialization
  // ══════════════════════════════════════════════════════════════════
  Future<void> initSocket() async {
    try {
      _socket?.close();
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socket?.broadcastEnabled = true;

      // Attempt to set socket options for better performance
      // (some platforms may not support all options)
      try {
        // Increase receive buffer to 2MB
        _socket?.setRawOption(RawSocketOption(
          RawSocketOption.levelSocket,
          8, // SO_RCVBUF
          _int32Bytes(2 * 1024 * 1024),
        ));
      } catch (_) {}

      try {
        // Increase send buffer to 512KB
        _socket?.setRawOption(RawSocketOption(
          RawSocketOption.levelSocket,
          7, // SO_SNDBUF
          _int32Bytes(512 * 1024),
        ));
      } catch (_) {}

      try {
        // Set DSCP EF (Expedited Forwarding) for low-latency QoS
        // IP_TOS = 0xB8 (DSCP 46 << 2)
        _socket?.setRawOption(RawSocketOption(
          RawSocketOption.levelIPv4,
          1, // IP_TOS
          Uint8List.fromList([0xB8, 0, 0, 0]),
        ));
      } catch (_) {
        // Silent fail - not all platforms support this
      }

      _socket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram != null) {
            _handleIncomingPacket(datagram);
          }
        }
      });

      // Start reconnect watchdog
      _startReconnectWatchdog();
    } catch (e) {
      _socket = null;
    }
  }

  Uint8List _int32Bytes(int value) {
    final bytes = Uint8List(4);
    bytes.buffer.asByteData().setInt32(0, value, Endian.host);
    return bytes;
  }

  // ══════════════════════════════════════════════════════════════════
  // Reconnect watchdog
  // ══════════════════════════════════════════════════════════════════
  void _startReconnectWatchdog() {
    _reconnectWatchdog?.cancel();
    _reconnectWatchdog = Timer.periodic(const Duration(seconds: 5), (_) async {
      // If we've sent packets but lost connection, attempt rebind
      if (packetsSent > 5 && !isConnected) {
        await initSocket();
      }
    });
  }

  // ══════════════════════════════════════════════════════════════════
  // Auto-discovery with adaptive backoff
  // ══════════════════════════════════════════════════════════════════
  void startAutoDiscovery() {
    _discoveryTimer?.cancel();
    _discoveryCount = 0;

    // Adaptive interval: fast at first, then slow down
    void scheduleNext() {
      Duration interval;
      if (_discoveryCount < 3) {
        interval = const Duration(seconds: 1); // First 3 pings: every 1s
      } else if (_discoveryCount < 10) {
        interval = const Duration(seconds: 3); // Next 7 pings: every 3s
      } else {
        interval = const Duration(seconds: 10); // After 10 pings: every 10s
      }

      _discoveryTimer = Timer(interval, () {
        _sendBroadcastDiscovery();
        _discoveryCount++;
        scheduleNext();
      });
    }

    _sendBroadcastDiscovery();
    _discoveryCount++;
    scheduleNext();
  }

  void stopAutoDiscovery() {
    _discoveryTimer?.cancel();
    _discoveryCount = 0;
  }

  void _sendBroadcastDiscovery() {
    if (_socket == null) return;
    try {
      final msg = Uint8List.fromList('F1_CONTROLLER_DISCOVER'.codeUnits);
      _socket?.send(msg, InternetAddress('255.255.255.255'), hostPort);
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════════════════
  // Packet handling
  // ══════════════════════════════════════════════════════════════════
  void _handleIncomingPacket(Datagram datagram) {
    final text = String.fromCharCodes(datagram.data);

    if (text.startsWith('F1_HOST_PONG')) {
      _handlePong(text);
    } else if (text.startsWith('F1_HOST_ANNOUNCE')) {
      _handleAnnounce(datagram);
    } else if (text.startsWith('F1_VIB:')) {
      _handleHapticFeedback(text);
    }
  }

  void _handlePong(String text) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _lastPongTimestamp = now;

    // Extract sequence number for matched ping
    final parts = text.split(':');
    if (parts.length >= 2) {
      final seq = int.tryParse(parts[1]);
      if (seq != null && _pendingPingTimestamps.containsKey(seq)) {
        final sentTime = _pendingPingTimestamps[seq]!;
        final rtt = (now - sentTime).toDouble();
        _pendingPingTimestamps.remove(seq);

        // Update current ping
        currentPingMs = rtt.clamp(1.0, 999.0);

        // Track RTT samples for jitter calculation
        _rttSamples.add(currentPingMs);
        if (_rttSamples.length > 8) {
          _rttSamples.removeAt(0);
        }

        // Compute jitter (variance)
        if (_rttSamples.length >= 3) {
          final mean =
              _rttSamples.reduce((a, b) => a + b) / _rttSamples.length;
          final variance = _rttSamples
                  .map((v) => (v - mean) * (v - mean))
                  .reduce((a, b) => a + b) /
              _rttSamples.length;
          jitterMs = variance;
        }
      }
    }

    // Clean up old pending timestamps (keep last 64)
    if (_pendingPingTimestamps.length > 64) {
      final oldest = _pendingPingTimestamps.keys.reduce(
          (a, b) => _pendingPingTimestamps[a]! < _pendingPingTimestamps[b]!
              ? a
              : b);
      _pendingPingTimestamps.remove(oldest);
    }
  }

  void _handleAnnounce(Datagram datagram) {
    final String ip = datagram.address.address;
    _discoveredHostsController.add(ip);
  }

  void _handleHapticFeedback(String text) async {
    final parts = text.split(':');
    if (parts.length == 3) {
      int large = int.tryParse(parts[1]) ?? 0;
      int small = int.tryParse(parts[2]) ?? 0;

      if (large == 0 && small == 0) {
        Vibration.cancel();
        return;
      }

      int maxMotor = large > small ? large : small;
      if (maxMotor < 10) return; // Prevent micro-vibrations

      bool? hasCustom = await Vibration.hasCustomVibrationsSupport();
      if (hasCustom == true) {
        Vibration.vibrate(duration: 150, amplitude: maxMotor.clamp(1, 255));
      } else {
        Vibration.vibrate(duration: 150);
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // Sending
  // ══════════════════════════════════════════════════════════════════
  void sendPacket(Uint8List payload) {
    if (_socket == null) return;
    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Extract sequence number from payload (byte 2)
      if (payload.length >= 3) {
        final seq = payload[2];
        _pendingPingTimestamps[seq] = now;
      }

      _socket?.send(payload, InternetAddress(hostAddress), hostPort);
      packetsSent++;
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════════════════
  // Cleanup
  // ══════════════════════════════════════════════════════════════════
  void dispose() {
    stopAutoDiscovery();
    _reconnectWatchdog?.cancel();
    _socket?.close();
    _discoveredHostsController.close();
  }
}
