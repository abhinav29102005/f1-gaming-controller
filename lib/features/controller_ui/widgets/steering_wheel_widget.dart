import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../core/models/controller_state.dart';

class SteeringWheelWidget extends StatefulWidget {
  final ControllerState state;
  final int rotationDegrees;
  final bool gyroEnabled;
  final double gyroSensitivity;
  final Color playerColor;

  const SteeringWheelWidget({
    super.key,
    required this.state,
    required this.rotationDegrees,
    required this.gyroEnabled,
    required this.gyroSensitivity,
    required this.playerColor,
  });

  @override
  State<SteeringWheelWidget> createState() => _SteeringWheelWidgetState();
}

class _SteeringWheelWidgetState extends State<SteeringWheelWidget> with SingleTickerProviderStateMixin {
  late final ValueNotifier<double> _angleNotifier;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  late AnimationController _springController;
  Animation<double>? _springAnimation;

  @override
  void initState() {
    super.initState();
    _angleNotifier = ValueNotifier<double>(widget.state.steering * (widget.rotationDegrees / 2.0));

    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _springController.addListener(() {
      if (_springAnimation != null) {
        _setAngle(_springAnimation!.value);
      }
    });

    if (widget.gyroEnabled) {
      _startGyroListening();
    }
  }

  @override
  void didUpdateWidget(covariant SteeringWheelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gyroEnabled != oldWidget.gyroEnabled) {
      if (widget.gyroEnabled) {
        _startGyroListening();
      } else {
        _stopGyroListening();
      }
    }
  }

  void _startGyroListening() {
    _gyroSubscription?.cancel();
    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      if (!mounted || !widget.gyroEnabled) return;
      // Use Y-axis or Z-axis rotation depending on device landscape orientation
      double delta = event.z * widget.gyroSensitivity * 2.5;
      double newAngle = (_angleNotifier.value + delta).clamp(
        -widget.rotationDegrees / 2.0,
        widget.rotationDegrees / 2.0,
      );
      _setAngle(newAngle);
    });
  }

  void _stopGyroListening() {
    _gyroSubscription?.cancel();
    _gyroSubscription = null;
  }

  void _setAngle(double angleDeg) {
    double maxDeg = widget.rotationDegrees / 2.0;
    double clamped = angleDeg.clamp(-maxDeg, maxDeg);
    _angleNotifier.value = clamped;

    // Update mutable ControllerState without triggering parent setState
    widget.state.steering = (clamped / maxDeg).clamp(-1.0, 1.0);
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (widget.gyroEnabled) return;
    _springController.stop();

    Offset center = Offset(size.width / 2, size.height / 2);
    Offset pos = details.localPosition;
    Offset prev = pos - details.delta;

    double anglePrev = math.atan2(prev.dy - center.dy, prev.dx - center.dx);
    double angleCurr = math.atan2(pos.dy - center.dy, pos.dx - center.dx);
    double diffRad = angleCurr - anglePrev;

    // Normalize angle jump across pi/-pi bound
    if (diffRad > math.pi) diffRad -= 2 * math.pi;
    if (diffRad < -math.pi) diffRad += 2 * math.pi;

    double diffDeg = diffRad * (180.0 / math.pi);
    _setAngle(_angleNotifier.value + diffDeg * 1.5);
  }

  void _onPanEnd() {
    if (widget.gyroEnabled) return;
    // Spring back to center
    _springAnimation = Tween<double>(
      begin: _angleNotifier.value,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _springController, curve: Curves.easeOutCubic));
    _springController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _stopGyroListening();
    _springController.dispose();
    _angleNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          Size wheelSize = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            onPanUpdate: (details) => _onPanUpdate(details, wheelSize),
            onPanEnd: (_) => _onPanEnd(),
            child: ValueListenableBuilder<double>(
              valueListenable: _angleNotifier,
              builder: (context, angleDeg, child) {
                return CustomPaint(
                  size: wheelSize,
                  painter: _F1WheelPainter(
                    angleDeg: angleDeg,
                    maxDegrees: widget.rotationDegrees,
                    playerColor: widget.playerColor,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _F1WheelPainter extends CustomPainter {
  final double angleDeg;
  final int maxDegrees;
  final Color playerColor;

  _F1WheelPainter({
    required this.angleDeg,
    required this.maxDegrees,
    required this.playerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 12;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angleDeg * (math.pi / 180.0));

    // Outer Carbon Rim
    final rimPaint = Paint()
      ..color = const Color(0xFF1B202D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24;
    canvas.drawCircle(Offset.zero, radius, rimPaint);

    final innerRimPaint = Paint()
      ..color = Colors.black.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset.zero, radius + 10, innerRimPaint);

    // Grip textures (Left & Right handles)
    final gripPaint = Paint()
      ..color = const Color(0xFF2A3142)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius),
      math.pi * 0.75,
      math.pi * 0.5,
      false,
      gripPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius),
      -math.pi * 0.25,
      math.pi * 0.5,
      false,
      gripPaint,
    );

    // Center Strip (Yellow/Red Center Marker)
    final stripePaint = Paint()
      ..color = playerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24;
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius),
      -math.pi / 2 - 0.08,
      0.16,
      false,
      stripePaint,
    );

    // F1 Wheel Spokes (Y-Shape)
    final spokePaint = Paint()
      ..color = const Color(0xFF151924)
      ..style = PaintingStyle.fill;

    Path centerPlate = Path();
    centerPlate.addOval(Rect.fromCircle(center: Offset.zero, radius: radius * 0.45));
    canvas.drawPath(centerPlate, spokePaint);

    final spokeBorder = Paint()
      ..color = playerColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset.zero, radius * 0.45, spokeBorder);

    // Center Display Readout
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${angleDeg.round()}°',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          shadows: [
            Shadow(color: playerColor, blurRadius: 10),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2 - 4),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _F1WheelPainter oldDelegate) {
    return oldDelegate.angleDeg != angleDeg || oldDelegate.playerColor != playerColor;
  }
}
