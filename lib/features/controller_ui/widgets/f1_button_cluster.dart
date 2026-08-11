import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../../../core/models/controller_state.dart';
import '../../../core/theme/f1_theme.dart';

class F1ButtonCluster extends StatefulWidget {
  final ControllerState state;
  final bool hapticsEnabled;

  const F1ButtonCluster({
    super.key,
    required this.state,
    this.hapticsEnabled = true,
  });

  @override
  State<F1ButtonCluster> createState() => _F1ButtonClusterState();
}

class _F1ButtonClusterState extends State<F1ButtonCluster> {
  void _triggerHaptic() {
    if (widget.hapticsEnabled) {
      Vibration.hasVibrator().then((has) {
        if (has == true) Vibration.vibrate(duration: 15, amplitude: 150);
      });
    }
  }

  Widget _buildActionButton({
    required String label,
    required bool active,
    required Color color,
    required Function(bool) onChanged,
    bool momentary = false,
    double fontSize = 10,
    IconData? icon,
  }) {
    return GestureDetector(
      onTapDown: (_) {
        _triggerHaptic();
        if (momentary) {
          setState(() => onChanged(true));
        } else {
          setState(() => onChanged(!active));
        }
      },
      onTapUp: momentary ? (_) {
        Future.delayed(const Duration(milliseconds: 80), () {
          if (mounted) setState(() => onChanged(false));
        });
      } : null,
      onTapCancel: momentary ? () {
        if (mounted) setState(() => onChanged(false));
      } : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.3) : F1Theme.carbonCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? color : Colors.white24,
            width: active ? 2 : 1,
          ),
          boxShadow: [
            if (active)
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: active ? color : Colors.white70, size: 16),
                const SizedBox(height: 2),
              ],
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white60,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: F1Theme.glassDecoration(),
      child: Column(
        children: [
          // Row 1: Xbox-style XYAB Diamond Layout
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Y on top
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildActionButton(
                      label: 'Y',
                      active: widget.state.buttonY,
                      color: const Color(0xFFFFB900), // Xbox Yellow
                      fontSize: 14,
                      momentary: true,
                      onChanged: (v) => widget.state.buttonY = v,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // X and B side by side
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          label: 'X',
                          active: widget.state.buttonX,
                          color: const Color(0xFF0078D4), // Xbox Blue
                          fontSize: 14,
                          momentary: true,
                          onChanged: (v) => widget.state.buttonX = v,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildActionButton(
                          label: 'B',
                          active: widget.state.buttonB,
                          color: const Color(0xFFE81123), // Xbox Red
                          fontSize: 14,
                          momentary: true,
                          onChanged: (v) => widget.state.buttonB = v,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // A on bottom
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildActionButton(
                      label: 'A',
                      active: widget.state.buttonA,
                      color: const Color(0xFF107C10), // Xbox Green
                      fontSize: 14,
                      momentary: true,
                      onChanged: (v) => widget.state.buttonA = v,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Row 2: Start + Select (Menu/View)
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'SELECT',
                    active: widget.state.buttonSelect,
                    color: Colors.white70,
                    fontSize: 8,
                    icon: Icons.view_headline,
                    momentary: true,
                    onChanged: (v) => widget.state.buttonSelect = v,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildActionButton(
                    label: 'START',
                    active: widget.state.buttonStart,
                    color: Colors.white70,
                    fontSize: 8,
                    icon: Icons.menu,
                    momentary: true,
                    onChanged: (v) => widget.state.buttonStart = v,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Row 3: F1-specific toggles (DRS, ERS, PIT)
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'DRS',
                    active: widget.state.drs,
                    color: F1Theme.neonGreen,
                    fontSize: 9,
                    onChanged: (v) => widget.state.drs = v,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildActionButton(
                    label: 'ERS',
                    active: widget.state.ers,
                    color: F1Theme.electricAmber,
                    fontSize: 9,
                    onChanged: (v) => widget.state.ers = v,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildActionButton(
                    label: 'PIT',
                    active: widget.state.pitLimiter,
                    color: F1Theme.f1Red,
                    fontSize: 9,
                    onChanged: (v) => widget.state.pitLimiter = v,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
