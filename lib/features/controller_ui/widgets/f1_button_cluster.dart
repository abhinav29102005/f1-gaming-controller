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

  Widget _buildF1Button({
    required String label,
    required IconData icon,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTapDown: (_) {
        onTap();
        _triggerHaptic();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? color : Colors.white70, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: F1Theme.glassDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildF1Button(
                  label: 'DRS',
                  icon: Icons.air,
                  active: widget.state.drs,
                  color: F1Theme.neonGreen,
                  onTap: () {
                    setState(() => widget.state.drs = !widget.state.drs);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildF1Button(
                  label: 'ERS',
                  icon: Icons.bolt,
                  active: widget.state.ers,
                  color: F1Theme.electricAmber,
                  onTap: () {
                    setState(() => widget.state.ers = !widget.state.ers);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildF1Button(
                  label: 'PIT LIMIT',
                  icon: Icons.speed,
                  active: widget.state.pitLimiter,
                  color: F1Theme.f1Red,
                  onTap: () {
                    setState(() => widget.state.pitLimiter = !widget.state.pitLimiter);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildF1Button(
                  label: 'RADIO',
                  icon: Icons.graphic_eq,
                  active: widget.state.radio,
                  color: F1Theme.neonCyan,
                  onTap: () {
                    setState(() => widget.state.radio = !widget.state.radio);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildF1Button(
                  label: 'BOX BOX',
                  icon: Icons.build_circle_outlined,
                  active: widget.state.boxBox,
                  color: F1Theme.magentaPurple,
                  onTap: () {
                    setState(() => widget.state.boxBox = !widget.state.boxBox);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildF1Button(
                  label: 'MIX +',
                  icon: Icons.tune,
                  active: widget.state.engineMapUp,
                  color: Colors.white,
                  onTap: () {
                    setState(() {
                      widget.state.engineMapUp = true;
                    });
                    Future.delayed(const Duration(milliseconds: 120), () {
                      if (mounted) setState(() => widget.state.engineMapUp = false);
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
