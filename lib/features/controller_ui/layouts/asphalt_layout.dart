import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/models/controller_state.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/theme/f1_theme.dart';
import '../widgets/dpad_cluster.dart';
import '../widgets/steering_wheel_widget.dart';

/// Asphalt Legends Unite official arcade controller layout.
///
/// Designed specifically for Asphalt 9 / Asphalt Legends Unite:
///   LEFT  — TouchDrive Route Selectors (Q/E) + D-Pad + TouchDrive Mode Toggle
///   CENTER— Nitro Level Bar & Gyro Tilt Gauge
///   RIGHT — Primary Nitro & Drift Action Buttons + 360° Spin, Perfect Nitro & Shockwave Macros
///   TOP   — L2 Drift & R2 Nitro Triggers
class AsphaltControllerLayout extends StatefulWidget {
  final ControllerState state;
  final bool hapticsEnabled;

  const AsphaltControllerLayout({
    super.key,
    required this.state,
    this.hapticsEnabled = true,
  });

  @override
  State<AsphaltControllerLayout> createState() => _AsphaltControllerLayoutState();
}

class _AsphaltControllerLayoutState extends State<AsphaltControllerLayout> {
  bool _touchDriveEnabled = true;
  double _nitroLevel = 1.0; // 0.0 to 1.0 simulation
  Timer? _nitroTimer;

  @override
  void initState() {
    super.initState();
    AudioService.init().then((_) {
      if (mounted) {
        AudioService.playBgm();
        AudioService.startEngine();
      }
    });
    // Simulate slight ambient nitro refill for visual dynamism
    _nitroTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (mounted && _nitroLevel < 1.0) {
        setState(() {
          _nitroLevel = (_nitroLevel + 0.04).clamp(0.0, 1.0);
        });
      }
    });
  }

  @override
  void dispose() {
    AudioService.stopBgm();
    AudioService.stopEngine();
    _nitroTimer?.cancel();
    super.dispose();
  }

  // ── Macro Executors ──────────────────────────────────────────────────

  /// Fires Instant Double-Tap Nitro for Shockwave
  void _fireShockwaveNitro() {
    FeedbackService.shockwaveBurst();
    AudioService.playNitroSound();
    setState(() {
      _nitroLevel = 0.0;
      widget.state.buttonA = true;
      widget.state.throttle = 1.0;
      widget.state.notifyStateChanged();
    });

    Future.delayed(const Duration(milliseconds: 60), () {
      if (!mounted) return;
      setState(() {
        widget.state.buttonA = false;
        widget.state.notifyStateChanged();
      });
      Future.delayed(const Duration(milliseconds: 60), () {
        if (!mounted) return;
        setState(() {
          widget.state.buttonA = true;
          widget.state.notifyStateChanged();
        });
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!mounted) return;
          setState(() {
            widget.state.buttonA = false;
            widget.state.throttle = 0.0;
            widget.state.notifyStateChanged();
          });
        });
      });
    });
  }

  /// Fires Perfect Nitro Macro (Timed double tap)
  void _firePerfectNitro() {
    FeedbackService.nitroBoost();
    AudioService.playNitroSound();
    setState(() {
      _nitroLevel = (_nitroLevel - 0.4).clamp(0.0, 1.0);
      widget.state.buttonA = true;
      widget.state.notifyStateChanged();
    });

    Future.delayed(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      setState(() {
        widget.state.buttonA = false;
        widget.state.notifyStateChanged();
      });
      Future.delayed(const Duration(milliseconds: 140), () {
        if (!mounted) return;
        FeedbackService.nitroBoost();
        setState(() {
          widget.state.buttonA = true;
          widget.state.notifyStateChanged();
        });
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!mounted) return;
          setState(() {
            widget.state.buttonA = false;
            widget.state.notifyStateChanged();
          });
        });
      });
    });
  }

  /// Fires 360° Flat Spin (Double tap Drift shortcut)
  void _fire360Spin() {
    FeedbackService.driftSpin();
    setState(() {
      widget.state.buttonB = true;
      widget.state.brake = 1.0;
      widget.state.notifyStateChanged();
    });

    Future.delayed(const Duration(milliseconds: 60), () {
      if (!mounted) return;
      setState(() {
        widget.state.buttonB = false;
        widget.state.notifyStateChanged();
      });
      Future.delayed(const Duration(milliseconds: 60), () {
        if (!mounted) return;
        setState(() {
          widget.state.buttonB = true;
          widget.state.notifyStateChanged();
        });
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!mounted) return;
          setState(() {
            widget.state.buttonB = false;
            widget.state.brake = 0.0;
            widget.state.notifyStateChanged();
          });
        });
      });
    });
  }

  // ── UI Builders ──────────────────────────────────────────────────────

  Widget _buildSmallSysButton({
    required IconData icon,
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
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: active ? Colors.white24 : F1Theme.carbonCard,
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? Colors.white : Colors.white38,
            width: 1.0,
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: active ? Colors.white : Colors.white70,
        ),
      ),
    );
  }

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
          height: 38,
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.4) : F1Theme.carbonCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? color : color.withOpacity(0.35),
              width: active ? 2.0 : 1.0,
            ),
            boxShadow: [
              if (active)
                BoxShadow(color: color.withOpacity(0.6), blurRadius: 10, spreadRadius: 1),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                sublabel,
                style: TextStyle(
                  color: active ? Colors.white70 : Colors.white38,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCircle({
    required String mainLabel,
    required String subLabel,
    required bool active,
    required Color color,
    required void Function(bool) onChanged,
    required double size,
  }) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        FeedbackService.nitroBoost();
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
            color: active ? color : color.withOpacity(0.5),
            width: active ? 3.0 : 2.0,
          ),
          boxShadow: [
            if (active)
              BoxShadow(color: color.withOpacity(0.85), blurRadius: 20, spreadRadius: 3),
            if (!active)
              BoxShadow(color: color.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              mainLabel,
              style: TextStyle(
                color: active ? Colors.white : color,
                fontSize: size * 0.22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              subLabel,
              style: TextStyle(
                color: active ? Colors.white70 : Colors.white54,
                fontSize: size * 0.12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroChip({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.6)),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.15), blurRadius: 4),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: color.withOpacity(0.8),
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoutePickButton({
    required String label,
    required String keyName,
    required bool active,
    required void Function(bool) onChanged,
    required IconData icon,
  }) {
    return Expanded(
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {
          FeedbackService.routePick();
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
          height: 42,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFF6B00).withOpacity(0.4) : F1Theme.carbonCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? const Color(0xFFFF6B00) : F1Theme.neonCyan.withOpacity(0.4),
              width: active ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: active ? Colors.white : F1Theme.neonCyan, size: 16),
              const SizedBox(width: 4),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: active ? Colors.white : Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    keyName,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
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
          // ── LEFT PANEL: TouchDrive Routes + D-Pad + TouchDrive Mode Toggle ──
          Container(
            width: 175,
            padding: const EdgeInsets.all(6),
            decoration: F1Theme.glassDecoration(borderColor: const Color(0xFFFF6B00).withOpacity(0.5)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title Badge & Mode Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B00).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFFF6B00)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.flash_on, color: Color(0xFFFF6B00), size: 10),
                          SizedBox(width: 2),
                          Text(
                            'ASPHALT 9/UNITE',
                            style: TextStyle(
                              color: Color(0xFFFF6B00),
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        FeedbackService.lightTick();
                        setState(() => _touchDriveEnabled = !_touchDriveEnabled);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: _touchDriveEnabled ? F1Theme.neonGreen.withOpacity(0.2) : Colors.black45,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _touchDriveEnabled ? F1Theme.neonGreen : Colors.white24),
                        ),
                        child: Text(
                          _touchDriveEnabled ? 'TOUCHDRIVE' : 'MANUAL',
                          style: TextStyle(
                            color: _touchDriveEnabled ? F1Theme.neonGreen : Colors.white60,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_touchDriveEnabled) ...[
                  // TouchDrive Route Selectors (Q/E)
                  Row(
                    children: [
                      _buildRoutePickButton(
                        label: 'ROUTE LEFT',
                        keyName: 'Q / D-LEFT',
                        active: s.buttonX || s.dpad == 7,
                        onChanged: (v) {
                          s.buttonX = v;
                          s.dpad = v ? 7 : 0;
                        },
                        icon: Icons.arrow_back_ios,
                      ),
                      _buildRoutePickButton(
                        label: 'ROUTE RIGHT',
                        keyName: 'E / D-RIGHT',
                        active: s.buttonY || s.dpad == 3,
                        onChanged: (v) {
                          s.buttonY = v;
                          s.dpad = v ? 3 : 0;
                        },
                        icon: Icons.arrow_forward_ios,
                      ),
                    ],
                  ),

                  // Precision D-Pad Cluster
                  DPadCluster(
                    state: s,
                    hapticsEnabled: widget.hapticsEnabled,
                  ),
                ] else ...[
                  // Manual Mode Steering Wheel
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: SteeringWheelWidget(
                        state: s,
                        rotationDegrees: 180,
                        gyroEnabled: true,
                        gyroSensitivity: 1.5,
                        playerColor: const Color(0xFFFF6B00),
                      ),
                    ),
                  ),
                  const Text(
                    'GYRO STEERING ACTIVE',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 6),

          // ── CENTER PANEL: Speedometer & Nitro Level Gauge ─────────────────
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: F1Theme.glassDecoration(borderColor: F1Theme.neonCyan.withOpacity(0.4)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSmallSysButton(
                      icon: Icons.pause,
                      active: s.buttonStart,
                      onChanged: (v) => s.buttonStart = v,
                    ),
                    _buildSmallSysButton(
                      icon: Icons.videocam,
                      active: s.buttonSelect,
                      onChanged: (v) => s.buttonSelect = v,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'NITRO',
                  style: TextStyle(
                    color: F1Theme.neonCyan,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    width: 24,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: F1Theme.neonCyan.withOpacity(0.5)),
                    ),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        FractionallySizedBox(
                          heightFactor: _nitroLevel,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6B00), F1Theme.neonCyan, Colors.purpleAccent],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  '${(_nitroLevel * 100).round()}%',
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

          const SizedBox(width: 6),

          // ── RIGHT PANEL: Shoulders + Action Circles + Macro Strip ──────────
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: F1Theme.glassDecoration(borderColor: const Color(0xFFFF6B00).withOpacity(0.5)),
              child: Column(
                children: [
                  // ── Row 1: Shoulder Triggers ──
                  Row(
                    children: [
                      _buildShoulderButton(
                        label: 'L2',
                        sublabel: 'DRIFT / BRAKE',
                        active: s.brake > 0.5,
                        color: const Color(0xFFFF3333),
                        onChanged: (v) => s.brake = v ? 1.0 : 0.0,
                      ),
                      const SizedBox(width: 4),
                      _buildShoulderButton(
                        label: 'L1',
                        sublabel: 'ROUTE L (Q)',
                        active: s.buttonX,
                        color: F1Theme.neonCyan,
                        onChanged: (v) => s.buttonX = v,
                      ),
                      const SizedBox(width: 4),
                      _buildShoulderButton(
                        label: 'R1',
                        sublabel: 'ROUTE R (E)',
                        active: s.buttonY,
                        color: F1Theme.electricAmber,
                        onChanged: (v) => s.buttonY = v,
                      ),
                      const SizedBox(width: 4),
                      _buildShoulderButton(
                        label: 'R2',
                        sublabel: 'NITRO BOOST',
                        active: s.throttle > 0.5,
                        color: const Color(0xFFFF6B00),
                        onChanged: (v) => s.throttle = v ? 1.0 : 0.0,
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // ── Row 2: Large Action Buttons (NITRO & DRIFT) ──
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final actionBtnSize = (constraints.maxHeight * 0.85).clamp(64.0, 96.0);
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // DRIFT Button (Red / Orange)
                            _buildActionCircle(
                              mainLabel: 'DRIFT',
                              subLabel: 'TAP / SLIPSTREAM',
                              active: s.buttonB,
                              color: const Color(0xFFFF3333),
                              onChanged: (v) {
                                s.buttonB = v;
                                s.brake = v ? 1.0 : 0.0;
                              },
                              size: actionBtnSize,
                            ),

                            // NITRO Button (Cyan / Gold)
                            _buildActionCircle(
                              mainLabel: 'NITRO',
                              subLabel: 'TAP BOOST',
                              active: s.buttonA,
                              color: const Color(0xFFFF6B00),
                              onChanged: (v) {
                                s.buttonA = v;
                                s.throttle = v ? 1.0 : 0.0;
                                if (v) {
                                  _nitroLevel = (_nitroLevel - 0.15).clamp(0.0, 1.0);
                                }
                              },
                              size: actionBtnSize,
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ── Row 3: Specialized Asphalt Macros Strip ──
                  Row(
                    children: [
                      _buildMacroChip(
                        title: 'SHOCKWAVE',
                        subtitle: 'DOUBLE NITRO',
                        onTap: _fireShockwaveNitro,
                        color: F1Theme.neonCyan,
                        icon: Icons.flash_on,
                      ),
                      _buildMacroChip(
                        title: 'PERFECT NITRO',
                        subtitle: 'TIMED BOOST',
                        onTap: _firePerfectNitro,
                        color: const Color(0xFFFF6B00),
                        icon: Icons.bolt,
                      ),
                      _buildMacroChip(
                        title: '360° FLAT SPIN',
                        subtitle: 'DOUBLE DRIFT',
                        onTap: _fire360Spin,
                        color: const Color(0xFFFF3333),
                        icon: Icons.sync,
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
