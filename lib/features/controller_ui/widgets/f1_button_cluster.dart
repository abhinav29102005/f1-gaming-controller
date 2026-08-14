import 'package:flutter/material.dart';
import '../../../core/models/controller_state.dart';
import '../../../core/services/feedback_service.dart';
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
      FeedbackService.heavyImpact();
    }
  }

  Widget _buildCircularButton({
    required String label,
    required bool active,
    required Color color,
    required Function(bool) onChanged,
  }) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        _triggerHaptic();
        setState(() {
          onChanged(true);
          widget.state.notifyStateChanged();
        });
      },
      onPointerUp: (_) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            setState(() {
              onChanged(false);
              widget.state.notifyStateChanged();
            });
          }
        });
      },
      onPointerCancel: (_) {
        if (mounted) {
          setState(() {
            onChanged(false);
            widget.state.notifyStateChanged();
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? color.withOpacity(0.4) : F1Theme.carbonCard,
          border: Border.all(
            color: active ? color : Colors.white24,
            width: active ? 2.5 : 1,
          ),
          boxShadow: [
            if (active)
              BoxShadow(
                color: color.withOpacity(0.6),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            if (!active)
              const BoxShadow(
                color: Colors.black45,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : color.withOpacity(0.8),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillButton({
    required String label,
    required bool active,
    required Color color,
    required IconData icon,
    required Function(bool) onChanged,
  }) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        _triggerHaptic();
        setState(() {
          onChanged(true);
          widget.state.notifyStateChanged();
        });
      },
      onPointerUp: (_) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            setState(() {
              onChanged(false);
              widget.state.notifyStateChanged();
            });
          }
        });
      },
      onPointerCancel: (_) {
        if (mounted) {
          setState(() {
            onChanged(false);
            widget.state.notifyStateChanged();
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: active ? color.withOpacity(0.3) : F1Theme.carbonCard,
          border: Border.all(
            color: active ? color : Colors.white24,
            width: active ? 2 : 1,
          ),
          boxShadow: [
            if (active)
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? Colors.white : Colors.white60, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildF1Toggle({
    required String label,
    required bool active,
    required Color color,
    required Function(bool) onChanged,
  }) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        _triggerHaptic();
        setState(() {
          onChanged(!active);
          widget.state.notifyStateChanged();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.3) : F1Theme.carbonCard,
          borderRadius: BorderRadius.circular(6),
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
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: F1Theme.glassDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Start / Select Pills
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPillButton(
                label: 'SEL',
                active: widget.state.buttonSelect,
                color: Colors.white,
                icon: Icons.view_headline,
                onChanged: (v) => widget.state.buttonSelect = v,
              ),
              _buildPillButton(
                label: 'START',
                active: widget.state.buttonStart,
                color: Colors.white,
                icon: Icons.menu,
                onChanged: (v) => widget.state.buttonStart = v,
              ),
            ],
          ),

          // Center: The Xbox Diamond Layout
          // We use a Stack to precisely position the circular buttons
          SizedBox(
            height: 140,
            width: 140,
            child: Stack(
              children: [
                // Y Button (Top)
                Positioned(
                  top: 0,
                  left: 47.5,
                  child: _buildCircularButton(
                    label: 'Y',
                    active: widget.state.buttonY,
                    color: const Color(0xFFFFB900), // Xbox Yellow
                    onChanged: (v) => widget.state.buttonY = v,
                  ),
                ),
                // X Button (Left)
                Positioned(
                  top: 47.5,
                  left: 0,
                  child: _buildCircularButton(
                    label: 'X',
                    active: widget.state.buttonX,
                    color: const Color(0xFF0078D4), // Xbox Blue
                    onChanged: (v) => widget.state.buttonX = v,
                  ),
                ),
                // B Button (Right)
                Positioned(
                  top: 47.5,
                  right: 0,
                  child: _buildCircularButton(
                    label: 'B',
                    active: widget.state.buttonB,
                    color: const Color(0xFFE81123), // Xbox Red
                    onChanged: (v) => widget.state.buttonB = v,
                  ),
                ),
                // A Button (Bottom)
                Positioned(
                  bottom: 0,
                  left: 47.5,
                  child: _buildCircularButton(
                    label: 'A',
                    active: widget.state.buttonA,
                    color: const Color(0xFF107C10), // Xbox Green
                    onChanged: (v) => widget.state.buttonA = v,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Row: F1 Racing Toggles
          Row(
            children: [
              Expanded(
                child: _buildF1Toggle(
                  label: 'DRS',
                  active: widget.state.drs,
                  color: F1Theme.neonGreen,
                  onChanged: (v) => widget.state.drs = v,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildF1Toggle(
                  label: 'ERS',
                  active: widget.state.ers,
                  color: F1Theme.electricAmber,
                  onChanged: (v) => widget.state.ers = v,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildF1Toggle(
                  label: 'PIT',
                  active: widget.state.pitLimiter,
                  color: F1Theme.f1Red,
                  onChanged: (v) => widget.state.pitLimiter = v,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
