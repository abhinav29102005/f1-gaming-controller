import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../../../core/models/controller_state.dart';
import '../../../core/theme/f1_theme.dart';

class DPadCluster extends StatefulWidget {
  final ControllerState state;
  final bool hapticsEnabled;

  const DPadCluster({
    super.key,
    required this.state,
    this.hapticsEnabled = true,
  });

  @override
  State<DPadCluster> createState() => _DPadClusterState();
}

class _DPadClusterState extends State<DPadCluster> {
  void _setDpad(int val) {
    setState(() {
      widget.state.dpad = val;
    });
    if (val != 0 && widget.hapticsEnabled) {
      Vibration.hasVibrator().then((has) {
        if (has == true) Vibration.vibrate(duration: 10, amplitude: 100);
      });
    }
  }

  Widget _buildDpadBtn(int directionVal, IconData icon, String label) {
    bool active = widget.state.dpad == directionVal;
    return GestureDetector(
      onTapDown: (_) => _setDpad(directionVal),
      onTapUp: (_) => _setDpad(0),
      onTapCancel: () => _setDpad(0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active ? F1Theme.neonCyan.withOpacity(0.4) : F1Theme.carbonCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? F1Theme.neonCyan : Colors.white24,
          ),
          boxShadow: [
            if (active)
              const BoxShadow(color: F1Theme.neonCyan, blurRadius: 8, spreadRadius: 1),
          ],
        ),
        child: Icon(
          icon,
          color: active ? Colors.white : Colors.white70,
          size: 24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: F1Theme.glassDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 44),
              _buildDpadBtn(1, Icons.arrow_drop_up, 'UP'),
              const SizedBox(width: 44),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDpadBtn(7, Icons.arrow_left, 'LEFT'),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
              ),
              _buildDpadBtn(3, Icons.arrow_right, 'RIGHT'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 44),
              _buildDpadBtn(5, Icons.arrow_drop_down, 'DOWN'),
              const SizedBox(width: 44),
            ],
          ),
        ],
      ),
    );
  }
}
