import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../../../core/hid/native_hid_bridge.dart';
import '../../../core/models/controller_state.dart';
import '../../../core/theme/f1_theme.dart';

class PaddleShiftersWidget extends StatefulWidget {
  final ControllerState state;
  final bool hapticsEnabled;
  final bool volumeKeysEnabled;
  final bool swapPaddleShifters;

  const PaddleShiftersWidget({
    super.key,
    required this.state,
    this.hapticsEnabled = true,
    this.volumeKeysEnabled = true,
    this.swapPaddleShifters = false,
  });

  @override
  State<PaddleShiftersWidget> createState() => _PaddleShiftersWidgetState();
}

class _PaddleShiftersWidgetState extends State<PaddleShiftersWidget> {
  StreamSubscription<String>? _volumeSub;

  String get gearLabel {
    int g = widget.state.currentGear;
    if (g == 0) return 'R';
    if (g == 1) return 'N';
    return '${g - 1}';
  }

  @override
  void initState() {
    super.initState();
    if (widget.volumeKeysEnabled) {
      _setupVolumeKeyListeners();
    }
  }

  void _setupVolumeKeyListeners() {
    NativeHidBridge.setVolumeKeyInterception(true);
    _volumeSub = NativeHidBridge.volumeKeyStream.listen((event) {
      if (!mounted) return;
      if (event == 'VOLUME_UP_DOWN') {
        widget.swapPaddleShifters ? _shiftDown() : _shiftUp();
      } else if (event == 'VOLUME_DOWN_DOWN') {
        widget.swapPaddleShifters ? _shiftUp() : _shiftDown();
      }
    });
  }

  void _shiftUp() {
    setState(() {
      if (widget.state.currentGear < 9) {
        widget.state.currentGear++;
      }
      widget.state.paddleUpshift = true;
              widget.state.notifyListeners();
    });
    _triggerHaptic();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => widget.state.paddleUpshift = false);
      }
    });
  }

  void _shiftDown() {
    setState(() {
      if (widget.state.currentGear > 0) {
        widget.state.currentGear--;
      }
      widget.state.paddleDownshift = true;
    });
    _triggerHaptic();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => widget.state.paddleDownshift = false);
      }
    });
  }

  void _triggerHaptic() {
    if (widget.hapticsEnabled) {
      Vibration.hasVibrator().then((has) {
        if (has == true) Vibration.vibrate(duration: 25, amplitude: 200);
      });
    }
  }

  @override
  void dispose() {
    _volumeSub?.cancel();
    NativeHidBridge.setVolumeKeyInterception(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: F1Theme.glassDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Paddle
          Expanded(
            child: GestureDetector(
              onTapDown: (_) => widget.swapPaddleShifters ? _shiftUp() : _shiftDown(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                height: 52,
                decoration: BoxDecoration(
                  color: widget.state.paddleDownshift
                      ? F1Theme.f1Red.withOpacity(0.4)
                      : F1Theme.carbonCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.state.paddleDownshift ? F1Theme.f1Red : Colors.white24,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.keyboard_double_arrow_left, color: F1Theme.f1Red),
                    SizedBox(width: 6),
                    Text(
                      'DOWN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Gear Display Cluster
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: F1Theme.electricAmber, width: 1.5),
              boxShadow: const [
                BoxShadow(color: F1Theme.electricAmber, blurRadius: 10, spreadRadius: -2),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'GEAR',
                  style: TextStyle(
                    color: F1Theme.electricAmber,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  gearLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          // Right Paddle
          Expanded(
            child: GestureDetector(
              onTapDown: (_) => widget.swapPaddleShifters ? _shiftDown() : _shiftUp(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                height: 52,
                decoration: BoxDecoration(
                  color: widget.state.paddleUpshift
                      ? F1Theme.neonGreen.withOpacity(0.4)
                      : F1Theme.carbonCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.state.paddleUpshift ? F1Theme.neonGreen : Colors.white24,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'UP',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.keyboard_double_arrow_right, color: F1Theme.neonGreen),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
