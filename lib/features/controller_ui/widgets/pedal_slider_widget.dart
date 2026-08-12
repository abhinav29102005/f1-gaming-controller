import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../../../core/models/controller_state.dart';
import '../../../core/theme/f1_theme.dart';

enum PedalType { throttle, brake }

class PedalSliderWidget extends StatefulWidget {
  final ControllerState state;
  final PedalType type;
  final bool hapticsEnabled;

  const PedalSliderWidget({
    super.key,
    required this.state,
    required this.type,
    this.hapticsEnabled = true,
  });

  @override
  State<PedalSliderWidget> createState() => _PedalSliderWidgetState();
}

class _PedalSliderWidgetState extends State<PedalSliderWidget> {
  late final ValueNotifier<double> _pressureNotifier;

  Color get _accentColor {
    return widget.type == PedalType.throttle ? F1Theme.neonGreen : F1Theme.f1Red;
  }

  String get _label {
    return widget.type == PedalType.throttle ? 'THROTTLE' : 'BRAKE';
  }

  @override
  void initState() {
    super.initState();
    double initialVal = widget.type == PedalType.throttle ? widget.state.throttle : widget.state.brake;
    _pressureNotifier = ValueNotifier<double>(initialVal);
  }

  void _updatePressure(double rawVal) {
    double clamped = rawVal.clamp(0.0, 1.0);
    _pressureNotifier.value = clamped;

    if (widget.type == PedalType.throttle) {
      widget.state.throttle = clamped;
    } else {
      widget.state.brake = clamped;
    }
    widget.state.notifyListeners();
  }

  void _onPanUpdate(Offset localPosition, double height) {
    // 0 pressure is at the bottom, 1.0 is at the top
    double pressure = 1.0 - (localPosition.dy / height).clamp(0.0, 1.0);
    _updatePressure(pressure);
  }

  void _onPanDown(Offset localPosition, double height) {
    _onPanUpdate(localPosition, height);
    _triggerHaptic();
  }

  void _onPanEnd() {
    _updatePressure(0.0);
  }

  void _triggerHaptic() {
    if (widget.hapticsEnabled) {
      Vibration.hasVibrator().then((has) {
        if (has == true) Vibration.vibrate(duration: 12, amplitude: 128);
      });
    }
  }

  @override
  void dispose() {
    _pressureNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          double totalHeight = constraints.maxHeight;
          return GestureDetector(
            onPanDown: (details) => _onPanDown(details.localPosition, totalHeight),
            onPanUpdate: (details) => _onPanUpdate(details.localPosition, totalHeight),
            onPanEnd: (_) => _onPanEnd(),
            onPanCancel: () => _onPanEnd(),
            child: Container(
              decoration: F1Theme.carbonDecoration(
                borderColor: _accentColor.withOpacity(0.4),
                glowColor: _accentColor,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ValueListenableBuilder<double>(
                  valueListenable: _pressureNotifier,
                  builder: (context, pressure, child) {
                    return Stack(
                      children: [
                        // Vertical Progress Bar
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: pressure,
                            widthFactor: 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _accentColor.withOpacity(0.85),
                                    _accentColor.withOpacity(0.35),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Label & Value Readout Overlay
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  widget.type == PedalType.throttle ? Icons.speed : Icons.warning_amber_rounded,
                                  color: _accentColor,
                                  size: 28,
                                ),
                                Column(
                                  children: [
                                    Text(
                                      '${(pressure * 100).round()}%',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                        shadows: [
                                          Shadow(color: _accentColor, blurRadius: 12),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _label,
                                      style: TextStyle(
                                        color: _accentColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
