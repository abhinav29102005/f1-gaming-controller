import 'package:flutter/material.dart';

import '../../../core/models/controller_state.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/theme/f1_theme.dart';
import '../widgets/dpad_cluster.dart';

/// Tekken 8 official fight pad controller layout.
///
/// Layout (landscape):
///   LEFT  — Large D-Pad + Start/Select pills
///   RIGHT — Shoulder/trigger row (L2=Rage Art / L1=Block / R1=Throw / R2=Heat Engage)
///            + 2×2 attack buttons (X=LK, Y=RP, A=LP, B=RK)
///            + Tekken 8 combo strip (1+2, 2+4, 3+4, 1+3+4, Heat Smash, Rage Art)
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
  // ── Combo fire: press all buttons simultaneously, release after 100ms ──
  void _fireCombo(List<void Function(bool)> setters, {bool isHeat = false}) {
    if (isHeat) {
      FeedbackService.heatSmash();
    } else {
      FeedbackService.tekkenStrike();
    }
    setState(() {
      for (final s in setters) {
        s(true);
      }
      widget.state.notifyStateChanged();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          for (final s in setters) {
            s(false);
          }
          widget.state.notifyStateChanged();
        });
      }
    });
  }

  // ── Builders ─────────────────────────────────────────────────────────

  /// Large circular attack button with Xbox letter + Tekken 8 notation.
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
        FeedbackService.tekkenStrike();
        setState(() {
          onChanged(true);
          widget.state.notifyStateChanged();
        });
      },
      onPointerUp: (_) {
        Future.delayed(const Duration(milliseconds: 40), () {
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
        duration: const Duration(milliseconds: 30),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? color.withOpacity(0.55) : F1Theme.carbonCard,
          border: Border.all(
            color: active ? color : color.withOpacity(0.4),
            width: active ? 3.0 : 1.5,
          ),
          boxShadow: [
            if (active)
              BoxShadow(color: color.withOpacity(0.85), blurRadius: 24, spreadRadius: 4),
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
                fontSize: size * 0.32,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              tekkenLabel,
              style: TextStyle(
                color: active ? Colors.white70 : Colors.white54,
                fontSize: size * 0.14,
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
          FeedbackService.mediumClick();
          setState(() {
            onChanged(true);
            widget.state.notifyStateChanged();
          });
        },
        onPointerUp: (_) {
          Future.delayed(const Duration(milliseconds: 40), () {
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
          duration: const Duration(milliseconds: 30),
          height: 48,
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.4) : F1Theme.carbonCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? color : color.withOpacity(0.35),
              width: active ? 2.0 : 1.0,
            ),
            boxShadow: [
              if (active)
                BoxShadow(color: color.withOpacity(0.65), blurRadius: 14, spreadRadius: 2),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                sublabel,
                style: TextStyle(
                  color: active ? Colors.white70 : Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom combo chip — fires multiple Tekken 8 inputs simultaneously.
  Widget _buildComboChip({
    required String line1,
    required String line2,
    required List<void Function(bool)> setters,
    required Color color,
    bool isHeat = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _fireCombo(setters, isHeat: isHeat),
        child: Container(
          height: 42,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.55)),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.1), blurRadius: 4),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                line1,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                line2,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
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
        FeedbackService.lightTick();
        setState(() {
          onChanged(true);
          widget.state.notifyStateChanged();
        });
      },
      onPointerUp: (_) {
        Future.delayed(const Duration(milliseconds: 40), () {
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
        duration: const Duration(milliseconds: 30),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: active ? Colors.white.withOpacity(0.25) : F1Theme.carbonCard,
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
            fontSize: 10,
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

    return RepaintBoundary(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── LEFT PANEL: D-Pad + Start/Select ────────────────────────
          Container(
            width: 175,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: F1Theme.glassDecoration(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tekken 8 Title Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B00).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFF6B00).withOpacity(0.6)),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFFFF6B00), blurRadius: 10, spreadRadius: -4),
                    ],
                  ),
                  child: const Text(
                    'TEKKEN 8 FIGHT PAD',
                    style: TextStyle(
                      color: Color(0xFFFF6B00),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                // D-Pad Cluster
                DPadCluster(
                  state: s,
                  hapticsEnabled: widget.hapticsEnabled,
                ),
                const SizedBox(height: 12),
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

          // ── RIGHT PANEL: Shoulders + 2x2 Attack + Combos ─────────────
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: F1Theme.glassDecoration(),
              child: Column(
                children: [
                  // ── Row 1: Shoulder / Trigger row (Tekken 8) ────────
                  Row(
                    children: [
                      _buildShoulderButton(
                        label: 'L2',
                        sublabel: 'RAGE ART',
                        active: s.brake > 0.5,
                        color: F1Theme.f1Red,
                        onChanged: (v) => s.brake = v ? 1.0 : 0.0,
                      ),
                      const SizedBox(width: 4),
                      _buildShoulderButton(
                        label: 'L1',
                        sublabel: 'BLOCK',
                        active: s.paddleDownshift,
                        color: F1Theme.neonCyan,
                        onChanged: (v) => s.paddleDownshift = v,
                      ),
                      const SizedBox(width: 4),
                      _buildShoulderButton(
                        label: 'R1',
                        sublabel: 'THROW',
                        active: s.paddleUpshift,
                        color: F1Theme.electricAmber,
                        onChanged: (v) => s.paddleUpshift = v,
                      ),
                      const SizedBox(width: 4),
                      _buildShoulderButton(
                        label: 'R2',
                        sublabel: 'HEAT ENGAGE',
                        active: s.throttle > 0.5,
                        color: const Color(0xFFFF6B00),
                        onChanged: (v) => s.throttle = v ? 1.0 : 0.0,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ── Row 2: 2×2 Attack Buttons (Tekken 8 Notation) ──
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final btnSize =
                            (constraints.maxHeight * 0.42).clamp(56.0, 88.0);
                        final spacing =
                            (constraints.maxHeight * 0.07).clamp(6.0, 18.0);
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
                                    tekkenLabel: '3 (LK)',
                                    active: s.buttonX,
                                    color: const Color(0xFF0078D4),
                                    onChanged: (v) => s.buttonX = v,
                                    size: btnSize,
                                  ),
                                  SizedBox(width: spacing * 1.5),
                                  _buildAttackButton(
                                    xboxLabel: 'Y',
                                    tekkenLabel: '2 (RP)',
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
                                    tekkenLabel: '1 (LP)',
                                    active: s.buttonA,
                                    color: const Color(0xFF107C10),
                                    onChanged: (v) => s.buttonA = v,
                                    size: btnSize,
                                  ),
                                  SizedBox(width: spacing * 1.5),
                                  _buildAttackButton(
                                    xboxLabel: 'B',
                                    tekkenLabel: '4 (RK)',
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

                  const SizedBox(height: 6),

                  // ── Row 3: Tekken 8 Combo Strip ──────────────────────
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
                        line1: '3+4',
                        line2: 'LK · RK',
                        setters: [
                          (v) => s.buttonX = v,
                          (v) => s.buttonB = v,
                        ],
                        color: F1Theme.neonGreen,
                      ),
                      _buildComboChip(
                        line1: '1+3+4',
                        line2: 'TAUNT',
                        setters: [
                          (v) => s.buttonA = v,
                          (v) => s.buttonX = v,
                          (v) => s.buttonB = v,
                        ],
                        color: F1Theme.magentaPurple,
                      ),
                      _buildComboChip(
                        line1: 'HEAT SMASH',
                        line2: 'LP · RK',
                        setters: [
                          (v) => s.buttonA = v,
                          (v) => s.buttonB = v,
                        ],
                        color: const Color(0xFFFF6B00),
                        isHeat: true,
                      ),
                      _buildComboChip(
                        line1: 'RAGE ART',
                        line2: 'd/f+1+2',
                        setters: [
                          (v) { s.brake = v ? 1.0 : 0.0; },
                          (v) => s.buttonA = v,
                          (v) => s.buttonY = v,
                        ],
                        color: F1Theme.f1Red,
                        isHeat: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
