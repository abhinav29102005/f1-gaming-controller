import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import '../../../core/models/controller_state.dart';
import '../../../core/theme/f1_theme.dart';
import '../widgets/dpad_cluster.dart';

/// Tekken 7 fighting game controller layout.
///
/// Layout (landscape):
///   LEFT  — Large D-Pad + Start/Select pills
///   RIGHT — Shoulder/trigger row (L2 / L1 / R1 / R2)
///            + 2×2 attack buttons (X=LK, Y=RP, A=LP, B=RK)
///            + combo strip at the bottom
class TekkenControllerLayout extends StatefulWidget {
  final ControllerState state;
  final bool hapticsEnabled;

  const TekkenControllerLayout({
    super.key,
    required this.state,
    this.hapticsEnabled = true,
  });

  @override
  State<TekkenControllerLayout> createState() => _TekkenControllerLayoutState();
}

class _TekkenControllerLayoutState extends State<TekkenControllerLayout> {
  // ── Haptics ─────────────────────────────────────────────────────────
  void _haptic({int duration = 15, int amplitude = 180}) {
    if (!widget.hapticsEnabled) return;
    Vibration.hasVibrator().then((has) {
      if (has == true) Vibration.vibrate(duration: duration, amplitude: amplitude);
    });
  }

  // ── Combo fire: press all buttons simultaneously, release after 100ms ──
  void _fireCombo(List<void Function(bool)> setters) {
    _haptic(duration: 25, amplitude: 220);
    setState(() {
      for (final s in setters) s(true);
      widget.state.notifyListeners();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          for (final s in setters) s(false);
          widget.state.notifyListeners();
        });
      }
    });
  }

  // ── Builders ─────────────────────────────────────────────────────────

  /// Large circular attack button with Xbox letter + Tekken label.
  Widget _buildAttackButton({
    required String xboxLabel,
    required String tekkenLabel,
    required bool active,
    required Color color,
    required void Function(bool) onChanged,
    required double size,
  }) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        _haptic();
        setState(() {
          onChanged(true);
          widget.state.notifyListeners();
        });
      },
      onPointerUp: (_) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            setState(() {
              onChanged(false);
              widget.state.notifyListeners();
            });
          }
        });
      },
      onPointerCancel: (_) {
        if (mounted) {
          setState(() {
            onChanged(false);
            widget.state.notifyListeners();
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 40),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? color.withOpacity(0.45) : F1Theme.carbonCard,
          border: Border.all(
            color: active ? color : color.withOpacity(0.4),
            width: active ? 3.0 : 1.5,
          ),
          boxShadow: [
            if (active)
              BoxShadow(color: color.withOpacity(0.75), blurRadius: 22, spreadRadius: 4),
            if (!active)
              const BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              xboxLabel,
              style: TextStyle(
                color: active ? Colors.white : color,
                fontSize: size * 0.30,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              tekkenLabel,
              style: TextStyle(
                color: active ? Colors.white70 : Colors.white38,
                fontSize: size * 0.13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Wide shoulder / trigger pill button.
  Widget _buildShoulderButton({
    required String label,
    required String sublabel,
    required bool active,
    required Color color,
    required void Function(bool) onChanged,
  }) {
    return Expanded(
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {
          _haptic(duration: 12, amplitude: 140);
          setState(() {
            onChanged(true);
            widget.state.notifyListeners();
          });
        },
        onPointerUp: (_) {
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted) {
              setState(() {
                onChanged(false);
                widget.state.notifyListeners();
              });
            }
          });
        },
        onPointerCancel: (_) {
          if (mounted) {
            setState(() {
              onChanged(false);
              widget.state.notifyListeners();
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 40),
          height: 50,
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.35) : F1Theme.carbonCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? color : color.withOpacity(0.35),
              width: active ? 2.0 : 1.0,
            ),
            boxShadow: [
              if (active)
                BoxShadow(color: color.withOpacity(0.55), blurRadius: 12, spreadRadius: 2),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                sublabel,
                style: TextStyle(
                  color: active ? Colors.white54 : Colors.white30,
                  fontSize: 9,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom combo chip — fires multiple buttons simultaneously.
  Widget _buildComboChip({
    required String line1,
    required String line2,
    required List<void Function(bool)> setters,
    required Color color,
  }) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _fireCombo(setters),
        child: Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.45)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                line1,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                line2,
                style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 8,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Small Start / Select pill button.
  Widget _buildPillButton({
    required String label,
    required bool active,
    required void Function(bool) onChanged,
  }) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        _haptic(duration: 10, amplitude: 100);
        setState(() {
          onChanged(true);
          widget.state.notifyListeners();
        });
      },
      onPointerUp: (_) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            setState(() {
              onChanged(false);
              widget.state.notifyListeners();
            });
          }
        });
      },
      onPointerCancel: (_) {
        if (mounted) {
          setState(() {
            onChanged(false);
            widget.state.notifyListeners();
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: active ? Colors.white.withOpacity(0.2) : F1Theme.carbonCard,
          border: Border.all(
            color: active ? Colors.white : Colors.white24,
            width: active ? 2.0 : 1.0,
          ),
          boxShadow: [
            if (active)
              const BoxShadow(color: Colors.white30, blurRadius: 8, spreadRadius: 1),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final s = widget.state;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── LEFT PANEL: D-Pad + Start/Select ────────────────────────
        Container(
          width: 180,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: F1Theme.glassDecoration(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Game title badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: F1Theme.f1Red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: F1Theme.f1Red.withOpacity(0.4)),
                ),
                child: const Text(
                  'TEKKEN 7',
                  style: TextStyle(
                    color: F1Theme.f1Red,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              // D-Pad (reuse existing widget)
              DPadCluster(
                state: s,
                hapticsEnabled: widget.hapticsEnabled,
              ),
              const SizedBox(height: 16),
              // Start / Select
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPillButton(
                    label: 'SEL',
                    active: s.buttonSelect,
                    onChanged: (v) => s.buttonSelect = v,
                  ),
                  _buildPillButton(
                    label: 'START',
                    active: s.buttonStart,
                    onChanged: (v) => s.buttonStart = v,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // ── RIGHT PANEL: Shoulders + Attack + Combos ─────────────────
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: F1Theme.glassDecoration(),
            child: Column(
              children: [
                // ── Row 1: Shoulder / Trigger row ────────────────────
                Row(
                  children: [
                    _buildShoulderButton(
                      label: 'L2',
                      sublabel: 'RAGE ART',
                      active: s.brake > 0.5,
                      color: F1Theme.f1Red,
                      onChanged: (v) => s.brake = v ? 1.0 : 0.0,
                    ),
                    const SizedBox(width: 6),
                    _buildShoulderButton(
                      label: 'L1',
                      sublabel: 'BLOCK',
                      active: s.paddleDownshift,
                      color: F1Theme.neonCyan,
                      onChanged: (v) => s.paddleDownshift = v,
                    ),
                    const SizedBox(width: 6),
                    _buildShoulderButton(
                      label: 'R1',
                      sublabel: 'THROW',
                      active: s.paddleUpshift,
                      color: F1Theme.electricAmber,
                      onChanged: (v) => s.paddleUpshift = v,
                    ),
                    const SizedBox(width: 6),
                    _buildShoulderButton(
                      label: 'R2',
                      sublabel: 'RAGE DRIVE',
                      active: s.throttle > 0.5,
                      color: F1Theme.neonGreen,
                      onChanged: (v) => s.throttle = v ? 1.0 : 0.0,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ── Row 2: 2×2 Attack Buttons ─────────────────────────
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Responsive button sizing
                      final btnSize =
                          (constraints.maxHeight * 0.40).clamp(58.0, 90.0);
                      final spacing =
                          (constraints.maxHeight * 0.08).clamp(8.0, 22.0);
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Top row: X (LK, blue)  |  Y (RP, yellow)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildAttackButton(
                                  xboxLabel: 'X',
                                  tekkenLabel: 'LK',
                                  active: s.buttonX,
                                  color: const Color(0xFF0078D4),
                                  onChanged: (v) => s.buttonX = v,
                                  size: btnSize,
                                ),
                                SizedBox(width: spacing * 1.6),
                                _buildAttackButton(
                                  xboxLabel: 'Y',
                                  tekkenLabel: 'RP',
                                  active: s.buttonY,
                                  color: const Color(0xFFFFB900),
                                  onChanged: (v) => s.buttonY = v,
                                  size: btnSize,
                                ),
                              ],
                            ),
                            SizedBox(height: spacing),
                            // Bottom row: A (LP, green)  |  B (RK, red)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildAttackButton(
                                  xboxLabel: 'A',
                                  tekkenLabel: 'LP',
                                  active: s.buttonA,
                                  color: const Color(0xFF107C10),
                                  onChanged: (v) => s.buttonA = v,
                                  size: btnSize,
                                ),
                                SizedBox(width: spacing * 1.6),
                                _buildAttackButton(
                                  xboxLabel: 'B',
                                  tekkenLabel: 'RK',
                                  active: s.buttonB,
                                  color: const Color(0xFFE81123),
                                  onChanged: (v) => s.buttonB = v,
                                  size: btnSize,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // ── Row 3: Combo Strip ────────────────────────────────
                Row(
                  children: [
                    _buildComboChip(
                      line1: '1+2',
                      line2: 'LP · RP',
                      setters: [
                        (v) => s.buttonA = v,
                        (v) => s.buttonY = v,
                      ],
                      color: F1Theme.neonCyan,
                    ),
                    _buildComboChip(
                      line1: '2+4',
                      line2: 'RP · RK',
                      setters: [
                        (v) => s.buttonY = v,
                        (v) => s.buttonB = v,
                      ],
                      color: F1Theme.electricAmber,
                    ),
                    _buildComboChip(
                      line1: '1+3+4',
                      line2: 'LP · LK · RK',
                      setters: [
                        (v) => s.buttonA = v,
                        (v) => s.buttonX = v,
                        (v) => s.buttonB = v,
                      ],
                      color: F1Theme.magentaPurple,
                    ),
                    _buildComboChip(
                      line1: 'RAGE ART',
                      line2: 'L2 · LP · RP',
                      setters: [
                        (v) { s.brake = v ? 1.0 : 0.0; },
                        (v) => s.buttonA = v,
                        (v) => s.buttonY = v,
                      ],
                      color: F1Theme.f1Red,
                    ),
                    _buildComboChip(
                      line1: 'HEAT SMASH',
                      line2: 'LP · RK',
                      setters: [
                        (v) => s.buttonA = v,
                        (v) => s.buttonB = v,
                      ],
                      color: const Color(0xFFFF6B00),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
