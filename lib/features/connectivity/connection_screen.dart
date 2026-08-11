import 'package:flutter/material.dart';
import '../../core/hid/connection_manager.dart';
import '../../core/models/connection_stats.dart';
import '../../core/theme/f1_theme.dart';

class ConnectionScreen extends StatefulWidget {
  final ConnectionManager connectionManager;
  final VoidCallback onConnectUpdated;

  const ConnectionScreen({
    super.key,
    required this.connectionManager,
    required this.onConnectUpdated,
  });

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  late TextEditingController _ipController;
  late TextEditingController _portController;
  TransportMode _selectedMode = TransportMode.udpRelay;
  final List<String> _discoveredHosts = [];

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.connectionManager.activeMode;
    _ipController = TextEditingController(text: widget.connectionManager.socketRelay.hostAddress);
    _portController = TextEditingController(text: widget.connectionManager.socketRelay.hostPort.toString());

    widget.connectionManager.socketRelay.discoveredHosts.listen((hostIp) {
      if (!mounted) return;
      if (!_discoveredHosts.contains(hostIp)) {
        setState(() {
          _discoveredHosts.add(hostIp);
          // Auto-select the first discovered host if user still has the default IP
          if (_discoveredHosts.length == 1 && _ipController.text == '192.168.1.100') {
            _ipController.text = hostIp;
          }
        });
      }
    });

    widget.connectionManager.socketRelay.startAutoDiscovery();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    widget.connectionManager.socketRelay.stopAutoDiscovery();
    super.dispose();
  }

  void _applyConnection() async {
    int port = int.tryParse(_portController.text) ?? 9999;
    await widget.connectionManager.setMode(
      _selectedMode,
      hostAddress: _ipController.text.trim(),
      port: port,
    );
    widget.onConnectUpdated();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transport Connection Settings Applied'),
          backgroundColor: F1Theme.neonGreen,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: F1Theme.f1DarkBg,
      appBar: AppBar(
        backgroundColor: F1Theme.carbonSurface,
        title: const Text('CONNECTIVITY & SETUP'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Transport Mode Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: F1Theme.carbonDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TRANSPORT MODE',
                  style: TextStyle(color: F1Theme.neonCyan, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 12),
                RadioListTile<TransportMode>(
                  title: const Text('UDP Socket Relay (Recommended - USB/LAN)', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Sub-5ms latency via companion PC app or RNDIS USB tethering', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  value: TransportMode.udpRelay,
                  groupValue: _selectedMode,
                  activeColor: F1Theme.neonCyan,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedMode = val);
                  },
                ),
                RadioListTile<TransportMode>(
                  title: const Text('Bluetooth HID Gamepad (Native)', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('No PC software required (API 28+ native Bluetooth Gamepad)', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  value: TransportMode.bleHid,
                  groupValue: _selectedMode,
                  activeColor: F1Theme.neonGreen,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedMode = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // UDP Socket & Auto-Discovery Configuration
          if (_selectedMode == TransportMode.udpRelay)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: F1Theme.carbonDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'COMPANION PC RELAY CONFIGURATION',
                    style: TextStyle(color: F1Theme.electricAmber, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  if (_discoveredHosts.isNotEmpty) ...[
                    const Text('Auto-Discovered Hosts on Local Network:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _discoveredHosts.map((ip) {
                        return ChoiceChip(
                          label: Text(ip, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          selected: _ipController.text == ip,
                          selectedColor: F1Theme.f1Red,
                          backgroundColor: F1Theme.carbonCard,
                          onSelected: (_) {
                            setState(() {
                              _ipController.text = ip;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      labelText: 'Host IP Address',
                      labelStyle: TextStyle(color: Colors.white60),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.computer, color: F1Theme.neonCyan),
                    ),
                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: 'UDP Port',
                      labelStyle: TextStyle(color: Colors.white60),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers, color: F1Theme.neonCyan),
                    ),
                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: F1Theme.f1Red,
              padding: const EdgeInsets.all(16),
            ),
            onPressed: _applyConnection,
            child: const Text(
              'APPLY & SAVE CONNECTION',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}
