import 'package:flutter/material.dart';

import '../../../core/models/controller_state.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/theme/f1_theme.dart';
import '../widgets/dpad_cluster.dart';

/// Tekken 8 official fight pad controller layout.
///
/// Layout (landscape):
///   LEFT  — Large D-Pad + Start/Select pills + Reference Guide button
///   RIGHT — Shoulder/trigger row (L2=Rage Art / L1=Block / R1=Throw / R2=Heat Engage)
///            + 2×2 attack buttons in standard Tekken Arcade grid:
///              [1 (LP - Top Left)]  [2 (RP - Top Right)]
///              [3 (LK - Bottom Left)] [4 (RK - Bottom Right)]
///            + Tekken 8 macro combo strip (1+2, 3+4, 1+3, 2+4, 2+3 Heat Smash, Rage Art)
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

  // ── Open Interactive Tekken 8 Reference Guide Modal ──────────────────
  void _showTekkenReferenceGuide(BuildContext context) {
    FeedbackService.lightTick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: const Color(0xFF141419),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: const Color(0xFFFF6B00), width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0xFFFF6B00), blurRadius: 20, spreadRadius: -5),
            ],
          ),
          child: Column(
            children: [
              // Modal Header Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E26),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  border: Border(bottom: BorderSide(color: Colors.white10)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.sports_martial_arts, color: Color(0xFFFF6B00), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'TEKKEN 8 ULTIMATE REFERENCE GUIDE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Scrollable Content Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Key Maps & Universal Notation
                      _buildGuideSectionHeader('1. KEY MAPS & UNIVERSAL NOTATION', Icons.gamepad),
                      _buildGuideCard(
                        children: [
                          const Text(
                            'Tekken uses a universal numbering system for attack limbs across all platforms:',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          _buildNotationRow('1', 'Left Punch (LP)', 'PlayStation: Square | Xbox: X | Arcade: Top Left'),
                          _buildNotationRow('2', 'Right Punch (RP)', 'PlayStation: Triangle | Xbox: Y | Arcade: Top Right'),
                          _buildNotationRow('3', 'Left Kick (LK)', 'PlayStation: Cross/X | Xbox: A | Arcade: Bottom Left'),
                          _buildNotationRow('4', 'Right Kick (RK)', 'PlayStation: Circle | Xbox: B | Arcade: Bottom Right'),
                          _buildNotationRow('1+2', 'LP + RP', 'Left Punch + Right Punch simultaneously'),
                          _buildNotationRow('3+4', 'LK + RK', 'Left Kick + Right Kick simultaneously'),
                          const Divider(color: Colors.white12, height: 16),
                          const Text('Directional Inputs (Assuming P1 facing right):', style: TextStyle(color: F1Theme.electricAmber, fontWeight: FontWeight.bold, fontSize: 11)),
                          const SizedBox(height: 6),
                          const Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _GuideChip(label: 'f = Forward'),
                              _GuideChip(label: 'b = Back (Guard)'),
                              _GuideChip(label: 'u = Up (Sidestep)'),
                              _GuideChip(label: 'd = Down (Crouch)'),
                              _GuideChip(label: 'd/f = Down-Forward (Launcher)'),
                              _GuideChip(label: 'd/b = Down-Back (Crouch block)'),
                              _GuideChip(label: 'u/f = Up-Forward (Hopkick)'),
                              _GuideChip(label: 'qcf = Quarter Circle Forward'),
                              _GuideChip(label: 'qcb = Quarter Circle Back'),
                              _GuideChip(label: '~ = Slide input (e.g. 1~2)'),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Section 2: Hit Levels & Properties
                      _buildGuideSectionHeader('2. HIT LEVELS & PROPERTIES', Icons.layers),
                      _buildGuideCard(
                        children: [
                          _buildPropertyRow('High', 'Can be blocked standing. Can be completely ducked under.', F1Theme.neonCyan),
                          _buildPropertyRow('Mid', 'Must be blocked standing. Will hit ducking opponents!', F1Theme.electricAmber),
                          _buildPropertyRow('Low', 'Must be blocked crouching. Hits standing opponents.', F1Theme.f1Red),
                          const Divider(color: Colors.white12, height: 16),
                          _buildPropertyRow('High Crush', 'Moves that duck underneath high attacks.', Colors.lightBlueAccent),
                          _buildPropertyRow('Low Crush', 'Moves that leap or hop over low attacks (e.g., u/f+4 hopkicks).', Colors.lightGreenAccent),
                          _buildPropertyRow('Tornado (T!)', 'Combo extension property. Rapidly spins airborne opponent for juggle continuity.', const Color(0xFFFF6B00)),
                          _buildPropertyRow('Power Crush', 'Armored move that absorbs incoming High and Mid attacks.', Colors.purpleAccent),
                          _buildPropertyRow('Homing Attacks', 'Glowing blue trail attacks that track sidestepping opponents.', Colors.cyanAccent),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Section 3: Core Mechanics in Tekken 8
                      _buildGuideSectionHeader('3. CORE MECHANICS IN TEKKEN 8', Icons.whatshot),
                      _buildGuideCard(
                        children: [
                          const Text('HEAT SYSTEM (Aggressive Play Drive):', style: TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.w900, fontSize: 12)),
                          const SizedBox(height: 6),
                          _buildPropertyRow('Heat Burst', 'Press 1+2 in neutral to activate Heat with short knockdown pushback.', const Color(0xFFFF6B00)),
                          _buildPropertyRow('Heat Engager', 'Specific character moves that trigger cinematic dash into Heat state.', const Color(0xFFFF6B00)),
                          _buildPropertyRow('Heat Dash', 'Hold Forward (f) after Heat Engager to dash directly into opponent face.', const Color(0xFFFF6B00)),
                          _buildPropertyRow('Heat Smash', 'High-damage universal one-button attack (2+3 or button) consuming remaining Heat.', const Color(0xFFFF6B00)),
                          const Divider(color: Colors.white12, height: 16),
                          const Text('RAGE & RECOVERABLE GAUGE:', style: TextStyle(color: F1Theme.f1Red, fontWeight: FontWeight.w900, fontSize: 12)),
                          const SizedBox(height: 6),
                          _buildPropertyRow('Rage State', 'Activates at <= 25% health. Grants damage buff and unlocks Rage Art.', F1Theme.f1Red),
                          _buildPropertyRow('Rage Art', '3+4 or d/f+1+2 super cinematic high-damage strike. Once per round.', F1Theme.f1Red),
                          _buildPropertyRow('Recoverable Gauge', 'Blocked attacks deal white health chip damage. Regenerates by attacking back!', Colors.white),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Section 4: Complete Character Roster
                      _buildGuideSectionHeader('4. COMPLETE CHARACTER ROSTER', Icons.people),
                      _buildGuideCard(
                        children: [
                          const Text('BASE ROSTER (32 Characters):', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                          const SizedBox(height: 6),
                          const Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _RosterTag(name: 'Alisa Bosconovitch'),
                              _RosterTag(name: 'Asuka Kazama'),
                              _RosterTag(name: 'Azucena Ortiz'),
                              _RosterTag(name: 'Bryan Fury'),
                              _RosterTag(name: 'Claudio Serafino'),
                              _RosterTag(name: 'Devil Jin'),
                              _RosterTag(name: 'Sergei Dragunov'),
                              _RosterTag(name: 'Feng Wei'),
                              _RosterTag(name: 'Hwoarang'),
                              _RosterTag(name: 'Jack-8'),
                              _RosterTag(name: 'Jin Kazama'),
                              _RosterTag(name: 'Jun Kazama'),
                              _RosterTag(name: 'Kazuya Mishima'),
                              _RosterTag(name: 'King II'),
                              _RosterTag(name: 'Kuma'),
                              _RosterTag(name: 'Lars Alexandersson'),
                              _RosterTag(name: 'Marshall Law'),
                              _RosterTag(name: 'Lee Chaolan'),
                              _RosterTag(name: 'Leo Kliesen'),
                              _RosterTag(name: 'Leroy Smith'),
                              _RosterTag(name: 'Lili De Rochefort'),
                              _RosterTag(name: 'Nina Williams'),
                              _RosterTag(name: 'Panda'),
                              _RosterTag(name: 'Paul Phoenix'),
                              _RosterTag(name: 'Raven'),
                              _RosterTag(name: 'Reina Mishima'),
                              _RosterTag(name: 'Shaheen'),
                              _RosterTag(name: 'Steve Fox'),
                              _RosterTag(name: 'Victor Chevalier'),
                              _RosterTag(name: 'Ling Xiaoyu'),
                              _RosterTag(name: 'Yoshimitsu'),
                              _RosterTag(name: 'Zafina'),
                            ],
                          ),
                          const Divider(color: Colors.white12, height: 16),
                          const Text('SEASON 1 DLC CHARACTERS:', style: TextStyle(color: F1Theme.electricAmber, fontWeight: FontWeight.bold, fontSize: 11)),
                          const SizedBox(height: 6),
                          const Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _RosterTag(name: 'Eddy Gordo', isDlc: true),
                              _RosterTag(name: 'Lidia Sobieska', isDlc: true),
                              _RosterTag(name: 'Heihachi Mishima', isDlc: true),
                              _RosterTag(name: 'Clive Rosfield (Guest)', isDlc: true),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Section 5: Standard Combo Blueprint
                      _buildGuideSectionHeader('5. STANDARD COMBO BLUEPRINT', Icons.schema),
                      _buildGuideCard(
                        children: [
                          _buildComboStep('Step 1', 'The Launcher', 'A move sending opponent airborne (e.g. d/f+2 or u/f+4 hopkick).'),
                          _buildComboStep('Step 2', 'Filler / Juggle Extension', 'Quick mid/high attack string maintaining airborne height.'),
                          _buildComboStep('Step 3', 'Tornado (T!)', 'Forces mid-air spin, landing opponent for additional run-up hits.'),
                          _buildComboStep('Step 4', 'Ender / Wall Carry', 'Hard-hitting finisher or carrying opponent into wall splat.'),
                          _buildComboStep('Step 5', 'Wall Combo', 'Additional follow-up string after wall splat for max damage!'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Guide Helper Widgets ─────────────────────────────────────────────
  Widget _buildGuideSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFF6B00), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFFF6B00),
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildGuideCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildNotationRow(String number, String limb, String platforms) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 36,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B00).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFFF6B00)),
            ),
            child: Text(
              number,
              style: const TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.w900, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 11),
                children: [
                  TextSpan(text: '$limb — ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  TextSpan(text: platforms, style: const TextStyle(color: Colors.white60)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyRow(String name, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 90,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Text(
              name,
              style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComboStep(String step, String name, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: F1Theme.electricAmber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: F1Theme.electricAmber),
            ),
            child: Text(
              step,
              style: const TextStyle(color: F1Theme.electricAmber, fontWeight: FontWeight.w900, fontSize: 9),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                Text(desc, style: const TextStyle(color: Colors.white60, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Attack & Control Button Builders ─────────────────────────────────

  /// Standard Arcade Attack Button: 1=LP, 2=RP, 3=LK, 4=RK
  Widget _buildAttackButton({
    required String tekkenNumber,
    required String limbNotation,
    required String platformInput,
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
              tekkenNumber,
              style: TextStyle(
                color: active ? Colors.white : color,
                fontSize: size * 0.35,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              limbNotation,
              style: TextStyle(
                color: active ? Colors.white70 : Colors.white70,
                fontSize: size * 0.14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              platformInput,
              style: TextStyle(
                color: active ? Colors.white54 : Colors.white38,
                fontSize: size * 0.11,
              ),
            ),
          ],
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
          height: 44,
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.4) : F1Theme.carbonCard,
            borderRadius: BorderRadius.circular(8),
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
                  fontSize: 13,
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
          height: 38,
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
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                line2,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: active ? Colors.white.withOpacity(0.25) : F1Theme.carbonCard,
          border: Border.all(
            color: active ? Colors.white : Colors.white24,
            width: active ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white60,
            fontSize: 9,
            fontWeight: FontWeight.bold,
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
          // ── LEFT PANEL: D-Pad + Start/Select + Reference Guide CTA ──
          Container(
            width: 175,
            padding: const EdgeInsets.all(6),
            decoration: F1Theme.glassDecoration(borderColor: const Color(0xFFFF6B00).withOpacity(0.5)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tekken 8 Title Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B00).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFF6B00).withOpacity(0.8)),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFFFF6B00), blurRadius: 8, spreadRadius: -4),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports_martial_arts, color: Color(0xFFFF6B00), size: 12),
                      SizedBox(width: 4),
                      Text(
                        'TEKKEN 8 FIGHT PAD',
                        style: TextStyle(
                          color: Color(0xFFFF6B00),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),

                // D-Pad Cluster
                DPadCluster(
                  state: s,
                  hapticsEnabled: widget.hapticsEnabled,
                ),

                // Guide Button + Start / Select
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.menu_book, size: 12, color: Colors.white),
                        label: const Text('REF GUIDE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 9)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B00),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          minimumSize: const Size(0, 26),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () => _showTekkenReferenceGuide(context),
                      ),
                    ),
                    const SizedBox(height: 4),
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
              ],
            ),
          ),

          const SizedBox(width: 6),

          // ── RIGHT PANEL: Shoulders + 2x2 Arcade Grid + Combos ─────────
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: F1Theme.glassDecoration(borderColor: const Color(0xFFFF6B00).withOpacity(0.5)),
              child: Column(
                children: [
                  // ── Row 1: Shoulder / Trigger Row ──
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
                        sublabel: 'BLOCK / SPECIAL',
                        active: s.paddleDownshift,
                        color: F1Theme.neonCyan,
                        onChanged: (v) => s.paddleDownshift = v,
                      ),
                      const SizedBox(width: 4),
                      _buildShoulderButton(
                        label: 'R1',
                        sublabel: 'THROW (1+3)',
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

                  const SizedBox(height: 6),

                  // ── Row 2: 2×2 Attack Buttons (Tekken Standard Arcade Grid) ──
                  // Top Left: 1 (LP, Xbox X)  |  Top Right: 2 (RP, Xbox Y)
                  // Bottom Left: 3 (LK, Xbox A)| Bottom Right: 4 (RK, Xbox B)
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final btnSize = (constraints.maxHeight * 0.44).clamp(52.0, 84.0);
                        final spacing = (constraints.maxHeight * 0.06).clamp(4.0, 14.0);
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Top Row: 1 (LP) | 2 (RP)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildAttackButton(
                                    tekkenNumber: '1',
                                    limbNotation: 'LP',
                                    platformInput: 'X / Square',
                                    active: s.buttonX,
                                    color: F1Theme.neonCyan,
                                    onChanged: (v) => s.buttonX = v,
                                    size: btnSize,
                                  ),
                                  SizedBox(width: spacing * 1.5),
                                  _buildAttackButton(
                                    tekkenNumber: '2',
                                    limbNotation: 'RP',
                                    platformInput: 'Y / Triangle',
                                    active: s.buttonY,
                                    color: F1Theme.electricAmber,
                                    onChanged: (v) => s.buttonY = v,
                                    size: btnSize,
                                  ),
                                ],
                              ),
                              SizedBox(height: spacing),
                              // Bottom Row: 3 (LK) | 4 (RK)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildAttackButton(
                                    tekkenNumber: '3',
                                    limbNotation: 'LK',
                                    platformInput: 'A / Cross',
                                    active: s.buttonA,
                                    color: const Color(0xFF107C10),
                                    onChanged: (v) => s.buttonA = v,
                                    size: btnSize,
                                  ),
                                  SizedBox(width: spacing * 1.5),
                                  _buildAttackButton(
                                    tekkenNumber: '4',
                                    limbNotation: 'RK',
                                    platformInput: 'B / Circle',
                                    active: s.buttonB,
                                    color: F1Theme.f1Red,
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

                  const SizedBox(height: 4),

                  // ── Row 3: Tekken 8 Macro Combo Strip ──
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
                        line1: '3+4',
                        line2: 'LK · RK',
                        setters: [
                          (v) => s.buttonX = v,
                          (v) => s.buttonB = v,
                        ],
                        color: F1Theme.neonGreen,
                      ),
                      _buildComboChip(
                        line1: '1+3',
                        line2: 'THROW 1',
                        setters: [
                          (v) => s.buttonA = v,
                          (v) => s.buttonX = v,
                        ],
                        color: F1Theme.electricAmber,
                      ),
                      _buildComboChip(
                        line1: '2+4',
                        line2: 'THROW 2',
                        setters: [
                          (v) => s.buttonY = v,
                          (v) => s.buttonB = v,
                        ],
                        color: Colors.purpleAccent,
                      ),
                      _buildComboChip(
                        line1: 'HEAT SMASH (2+3)',
                        line2: 'RP · LK',
                        setters: [
                          (v) => s.buttonY = v,
                          (v) => s.buttonX = v,
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

// ── Private Roster & Chip helper widgets ───────────────────────────────
class _GuideChip extends StatelessWidget {
  final String label;
  const _GuideChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 10),
      ),
    );
  }
}

class _RosterTag extends StatelessWidget {
  final String name;
  final bool isDlc;
  const _RosterTag({required this.name, this.isDlc = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDlc ? F1Theme.electricAmber.withOpacity(0.2) : Colors.black45,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isDlc ? F1Theme.electricAmber : Colors.white24),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: isDlc ? F1Theme.electricAmber : Colors.white70,
          fontSize: 10,
          fontWeight: isDlc ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
