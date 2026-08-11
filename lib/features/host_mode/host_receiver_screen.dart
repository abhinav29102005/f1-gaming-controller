import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/hid/host_receiver_engine.dart';
import '../../core/theme/f1_theme.dart';

class HostReceiverScreen extends StatefulWidget {
  const HostReceiverScreen({super.key});

  @override
  State<HostReceiverScreen> createState() => _HostReceiverScreenState();
}

class _HostReceiverScreenState extends State<HostReceiverScreen> {
  final HostReceiverEngine _engine = HostReceiverEngine();
  StreamSubscription<int>? _packetSub;
  bool _isServerRunning = false;
  String _localIp = 'Discovering IP...';

  @override
  void initState() {
    super.initState();
    _fetchLocalIp();
    _startHostServer();
  }

  Future<void> _fetchLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (var interface in interfaces) {
        // Prefer Wi-Fi or Ethernet over virtual adapters
        if (interface.name.toLowerCase().contains('wi-fi') || 
            interface.name.toLowerCase().contains('eth') ||
            interface.name.toLowerCase().contains('wlan')) {
          setState(() {
            _localIp = interface.addresses.first.address;
          });
          return;
        }
      }
      // Fallback to first available if no standard names match
      if (interfaces.isNotEmpty) {
        setState(() {
          _localIp = interfaces.first.addresses.first.address;
        });
      } else {
        setState(() {
          _localIp = '127.0.0.1';
        });
      }
    } catch (e) {
      setState(() {
        _localIp = 'Unknown IP';
      });
    }
  }

  void _startHostServer() async {
    bool started = await _engine.startServer(bindPort: 9999);
    setState(() {
      _isServerRunning = started;
    });

    _packetSub = _engine.packetStream.listen((playerId) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _packetSub?.cancel();
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: F1Theme.f1DarkBg,
      appBar: AppBar(
        backgroundColor: F1Theme.carbonSurface,
        title: const Row(
          children: [
            Icon(Icons.computer, color: F1Theme.neonCyan),
            SizedBox(width: 8),
            Text('WINDOWS PC HOST TELEMETRY RECEIVER'),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isServerRunning ? F1Theme.neonGreen.withOpacity(0.2) : F1Theme.f1Red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _isServerRunning ? F1Theme.neonGreen : F1Theme.f1Red),
            ),
            child: Row(
              children: [
                Icon(
                  _isServerRunning ? Icons.check_circle : Icons.error_outline,
                  color: _isServerRunning ? F1Theme.neonGreen : F1Theme.f1Red,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _isServerRunning ? 'UDP SERVER ACTIVE (PORT 9999)' : 'SERVER STOPPED',
                  style: TextStyle(
                    color: _isServerRunning ? F1Theme.neonGreen : F1Theme.f1Red,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: F1Theme.glassDecoration(borderColor: F1Theme.electricAmber),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: F1Theme.electricAmber),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'The F1 Controller connected on the local network (or USB tethered) will automatically stream inputs to this Windows host server.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Host IP Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi, color: Colors.white54, size: 20),
                  const SizedBox(width: 12),
                  const Text('Host IP Address (For Manual Connection): ', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  Text(
                    _localIp,
                    style: const TextStyle(
                      color: F1Theme.neonCyan,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Connected Controller HUD Telemetry Card
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 500, // Constrain width for a clean look on desktop
                  child: _buildPlayerTelemetryCard(0), // Only Player 1 (Index 0)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerTelemetryCard(int playerIndex) {
    Color playerColor = F1Theme.getPlayerColor(playerIndex);
    HostPlayerInfo? info = _engine.activePlayers[playerIndex];

    bool isConnected = info != null && (DateTime.now().millisecondsSinceEpoch - info.lastPacketTime < 3000);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: F1Theme.carbonDecoration(
        borderColor: isConnected ? playerColor : Colors.white10,
        glowColor: isConnected ? playerColor : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Player Badge + IP + Hz
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.router, color: F1Theme.neonCyan, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    isConnected ? (info.remoteIp) : 'DISCONNECTED',
                    style: TextStyle(
                      color: isConnected ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (isConnected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: F1Theme.neonCyan),
                  ),
                  child: Text(
                    '${info.currentHz} Hz',
                    style: const TextStyle(color: F1Theme.neonCyan, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isConnected) ...[
            // Steering Angle Gauge
            Row(
              children: [
                const SizedBox(
                  width: 70,
                  child: Text('STEERING:', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (info.state.steering + 1.0) / 2.0,
                      backgroundColor: Colors.black,
                      valueColor: AlwaysStoppedAnimation<Color>(playerColor),
                      minHeight: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(info.state.steering * 100).round()}%',
                  style: TextStyle(color: playerColor, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Throttle & Brake Gauges
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('THROTTLE', style: TextStyle(color: F1Theme.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: info.state.throttle,
                          backgroundColor: Colors.black,
                          valueColor: const AlwaysStoppedAnimation<Color>(F1Theme.neonGreen),
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BRAKE', style: TextStyle(color: F1Theme.f1Red, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: info.state.brake,
                          backgroundColor: Colors.black,
                          valueColor: const AlwaysStoppedAnimation<Color>(F1Theme.f1Red),
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action Button LED Status Indicators
            Row(
              children: [
                _buildLedBadge('DRS', info.state.drs, F1Theme.neonGreen),
                const SizedBox(width: 6),
                _buildLedBadge('ERS', info.state.ers, F1Theme.electricAmber),
                const SizedBox(width: 6),
                _buildLedBadge('PIT', info.state.pitLimiter, F1Theme.f1Red),
                const SizedBox(width: 6),
                _buildLedBadge('RADIO', info.state.radio, F1Theme.neonCyan),
              ],
            ),
          ] else ...[
            const Expanded(
              child: Center(
                child: Text(
                  'Waiting for controller packet...',
                  style: TextStyle(color: Colors.white24, fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLedBadge(String label, bool active, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.3) : Colors.black45,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: active ? color : Colors.white12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? color : Colors.white30,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
