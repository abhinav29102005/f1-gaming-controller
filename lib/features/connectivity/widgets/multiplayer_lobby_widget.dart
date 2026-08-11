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
          // Player Slot Selector Badges
          Row(
            children: List.generate(4, (index) {
              bool isSelected = state.playerId == index;
              Color slotColor = F1Theme.getPlayerColor(index);
              return GestureDetector(
                onTap: () => onPlayerSlotChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? slotColor : F1Theme.carbonCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: slotColor, width: isSelected ? 2 : 1),
                  ),
                  child: Text(
                    'P${index + 1}',
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }),
          ),
          // Live Hz & Telemetry Monitor + Mode Switchers
          Row(
            children: [
              ValueListenableBuilder<int>(
                valueListenable: inputLoop.hzNotifier,
                builder: (context, hz, child) {
                  return Container(
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
              IconButton(
                icon: const Icon(Icons.tune, color: Colors.white),
                onPressed: onOpenSettings,
                tooltip: 'Profile & Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
