import 'package:flutter/material.dart';
import '../../../core/hid/input_loop.dart';
import '../../../core/hid/socket_relay.dart';
import '../../../core/models/controller_state.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/theme/f1_theme.dart';

class MultiplayerLobbyWidget extends StatelessWidget {
  final ControllerState state;
  final ControllerProfile profile;
  final InputLoop inputLoop;
  final String layoutMode;
  final Function(int playerSlot) onPlayerSlotChanged;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenConnection;
  final VoidCallback onOpenHostMode;

  const MultiplayerLobbyWidget({
    super.key,
    required this.state,
    required this.profile,
    required this.inputLoop,
    required this.layoutMode,
    required this.onPlayerSlotChanged,
    required this.onOpenSettings,
    required this.onOpenConnection,
    required this.onOpenHostMode,
  });

  static Color _qualityColor(ConnectionQuality q) {
    switch (q) {
      case ConnectionQuality.excellent:
      case ConnectionQuality.good:
        return F1Theme.neonGreen;
      case ConnectionQuality.degraded:
        return F1Theme.electricAmber;
      case ConnectionQuality.poor:
        return F1Theme.f1Red;
      case ConnectionQuality.disconnected:
        return Colors.white30;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color playerColor = F1Theme.getPlayerColor(state.playerId);
    final bool isTekken = layoutMode == 'tekken_8' || layoutMode == 'tekken_7';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: F1Theme.glassDecoration(borderColor: isTekken ? const Color(0xFFFF6B00) : playerColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App Title / Logo Area — dynamic based on layoutMode
          Row(
            children: [
              Icon(
                isTekken ? Icons.sports_martial_arts : Icons.sports_motorsports,
                color: isTekken ? const Color(0xFFFF6B00) : playerColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isTekken ? 'TEKKEN 8' : 'F1 CONTROLLER',
                style: TextStyle(
                  color: isTekken ? const Color(0xFFFF6B00) : playerColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 2.0,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          // Live Hz & Ping & Telemetry Monitor + Sync Badge + Mode Switchers
          Row(
            children: [
              ValueListenableBuilder<int>(
                valueListenable: inputLoop.hzNotifier,
                builder: (context, hz, child) {
                  final isConnected = inputLoop.connectionManager.getStats().isConnected;
                  final ping = inputLoop.connectionManager.socketRelay.currentPingMs;
                  final quality = inputLoop.connectionManager.socketRelay.connectionQuality;
                  final qualityColor = _qualityColor(quality);

                  return Row(
                    children: [
                      // Full Sync Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: F1Theme.neonCyan.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: F1Theme.neonCyan),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.sync_lock, color: F1Theme.neonCyan, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'FULL SYNC 100%',
                              style: TextStyle(
                                color: F1Theme.neonCyan,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Connection Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: isConnected
                              ? F1Theme.neonGreen.withOpacity(0.2)
                              : F1Theme.f1Red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: isConnected
                                  ? F1Theme.neonGreen
                                  : F1Theme.f1Red),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isConnected ? Icons.wifi : Icons.wifi_off,
                              color: isConnected
                                  ? F1Theme.neonGreen
                                  : F1Theme.f1Red,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isConnected ? 'CONNECTED' : 'DISCONNECTED',
                              style: TextStyle(
                                color: isConnected
                                    ? F1Theme.neonGreen
                                    : F1Theme.f1Red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Hz Monitor
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: F1Theme.neonCyan),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt,
                                color: F1Theme.neonCyan, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '$hz Hz',
                              style: const TextStyle(
                                color: F1Theme.neonCyan,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Ping Badge
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: qualityColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.network_ping,
                                color: qualityColor, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${ping.round()}ms',
                              style: TextStyle(
                                color: qualityColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.computer, color: F1Theme.neonCyan),
                onPressed: onOpenHostMode,
                tooltip: 'Windows Host Telemetry Dashboard',
              ),
              IconButton(
                icon: const Icon(Icons.wifi_tethering, color: Colors.white),
                onPressed: onOpenConnection,
                tooltip: 'Connection Setup',
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                icon: const Icon(Icons.tune, color: Colors.black, size: 16),
                label: const Text('CALIBRATE',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: F1Theme.electricAmber,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: onOpenSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
