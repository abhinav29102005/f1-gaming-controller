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
  final Function(String newLayout)? onLayoutChanged;

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
    this.onLayoutChanged,
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

  Color get _themeAccentColor {
    if (layoutMode == 'asphalt_legends') return const Color(0xFFFF6B00);
    if (layoutMode == 'tekken_8' || layoutMode == 'tekken_7') return const Color(0xFFFF3333);
    return F1Theme.getPlayerColor(state.playerId);
  }

  IconData get _layoutIcon {
    if (layoutMode == 'asphalt_legends') return Icons.flash_on;
    if (layoutMode == 'tekken_8' || layoutMode == 'tekken_7') return Icons.sports_martial_arts;
    if (layoutMode == 'generic') return Icons.gamepad;
    return Icons.sports_motorsports;
  }

  String get _layoutTitle {
    if (layoutMode == 'asphalt_legends') return 'ASPHALT UNITE';
    if (layoutMode == 'tekken_8' || layoutMode == 'tekken_7') return 'TEKKEN 8';
    if (layoutMode == 'generic') return 'GENERIC PAD';
    return 'F1 RACING';
  }

  Widget _buildLayoutChip(String id, String label, Color activeColor) {
    final bool isSelected = (layoutMode == id) || (id == 'tekken_8' && layoutMode == 'tekken_7');
    return InkWell(
      onTap: () {
        if (onLayoutChanged != null) {
          onLayoutChanged!(id);
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.25) : Colors.black38,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white12,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 9,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = _themeAccentColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: F1Theme.glassDecoration(borderColor: accent.withOpacity(0.6)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Layout Logo & Quick Switcher
          Row(
            children: [
              Icon(_layoutIcon, color: accent, size: 16),
              const SizedBox(width: 6),
              Text(
                _layoutTitle,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.2,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(width: 10),
              // Layout Switcher Chips
              _buildLayoutChip('f1_racing', 'F1', F1Theme.f1Red),
              _buildLayoutChip('asphalt_legends', 'ASPHALT', const Color(0xFFFF6B00)),
              _buildLayoutChip('tekken_8', 'TEKKEN 8', const Color(0xFFFF3333)),
              _buildLayoutChip('generic', 'GENERIC', F1Theme.neonCyan),
            ],
          ),

          // Right: Hz & Ping & Sync + Quick Action Buttons
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
                      // Player Slot Toggle
                      InkWell(
                        onTap: () {
                          final nextSlot = (state.playerId + 1) % 4;
                          onPlayerSlotChanged(nextSlot);
                        },
                        child: ListenableBuilder(
                          listenable: state,
                          builder: (context, child) {
                            final pColor = F1Theme.getPlayerColor(state.playerId);
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: pColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: pColor),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.person, color: pColor, size: 10),
                                  const SizedBox(width: 3),
                                  Text(
                                    'P${state.playerId + 1}',
                                    style: TextStyle(
                                      color: pColor,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        ),
                      ),
                      // Full Sync Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: F1Theme.neonCyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: F1Theme.neonCyan.withOpacity(0.6)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.sync_lock, color: F1Theme.neonCyan, size: 10),
                            SizedBox(width: 3),
                            Text(
                              '100% SYNC',
                              style: TextStyle(
                                color: F1Theme.neonCyan,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Connection Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: isConnected
                              ? F1Theme.neonGreen.withOpacity(0.18)
                              : F1Theme.f1Red.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isConnected ? F1Theme.neonGreen : F1Theme.f1Red,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isConnected ? Icons.wifi : Icons.wifi_off,
                              color: isConnected ? F1Theme.neonGreen : F1Theme.f1Red,
                              size: 10,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              isConnected ? 'LIVE' : 'OFFLINE',
                              style: TextStyle(
                                color: isConnected ? F1Theme.neonGreen : F1Theme.f1Red,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Hz Monitor
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: F1Theme.neonCyan.withOpacity(0.6)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt, color: F1Theme.neonCyan, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              '$hz Hz',
                              style: const TextStyle(
                                color: F1Theme.neonCyan,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Ping Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: qualityColor.withOpacity(0.6)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.network_ping, color: qualityColor, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              '${ping.round()}ms',
                              style: TextStyle(
                                color: qualityColor,
                                fontSize: 9,
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
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.computer, color: F1Theme.neonCyan, size: 18),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
                onPressed: onOpenHostMode,
                tooltip: 'Windows Host Dashboard',
              ),
              IconButton(
                icon: const Icon(Icons.wifi_tethering, color: Colors.white, size: 18),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
                onPressed: onOpenConnection,
                tooltip: 'Connection Setup',
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                icon: const Icon(Icons.tune, color: Colors.black, size: 12),
                label: const Text('CALIBRATE',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 9)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: F1Theme.electricAmber,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  minimumSize: const Size(0, 26),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
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
