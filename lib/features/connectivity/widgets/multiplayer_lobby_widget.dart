import 'package:flutter/material.dart';
import '../../../core/hid/input_loop.dart';
import '../../../core/models/controller_state.dart';
import '../../../core/models/profile_model.dart';
import '../../../core/theme/f1_theme.dart';

class MultiplayerLobbyWidget extends StatelessWidget {
  final ControllerState state;
  final ControllerProfile profile;
  final InputLoop inputLoop;
  final Function(int playerSlot) onPlayerSlotChanged;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenConnection;
  final VoidCallback onOpenHostMode;

  const MultiplayerLobbyWidget({
    super.key,
    required this.state,
    required this.profile,
    required this.inputLoop,
    required this.onPlayerSlotChanged,
    required this.onOpenSettings,
    required this.onOpenConnection,
    required this.onOpenHostMode,
  });

  @override
  Widget build(BuildContext context) {
    Color playerColor = F1Theme.getPlayerColor(state.playerId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: F1Theme.glassDecoration(borderColor: playerColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App Title / Logo Area
          Row(
            children: [
              Icon(Icons.sports_motorsports, color: playerColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'F1 CONTROLLER',
                style: TextStyle(
                  color: playerColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 2.0,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          // Live Hz & Telemetry Monitor + Mode Switchers
          Row(
            children: [
              ValueListenableBuilder<int>(
                valueListenable: inputLoop.hzNotifier,
                builder: (context, hz, child) {
                  final isConnected = inputLoop.connectionManager.getStats().isConnected;
                  return Row(
                    children: [
                      // Connection Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isConnected ? F1Theme.neonGreen.withOpacity(0.2) : F1Theme.f1Red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isConnected ? F1Theme.neonGreen : F1Theme.f1Red),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isConnected ? Icons.wifi : Icons.wifi_off,
                              color: isConnected ? F1Theme.neonGreen : F1Theme.f1Red,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isConnected ? 'CONNECTED' : 'DISCONNECTED',
                              style: TextStyle(
                                color: isConnected ? F1Theme.neonGreen : F1Theme.f1Red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Hz Monitor
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: F1Theme.neonCyan),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt, color: F1Theme.neonCyan, size: 14),
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
                label: const Text('CALIBRATE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: F1Theme.electricAmber,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
