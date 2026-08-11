import 'package:flutter/material.dart';

import '../../core/models/profile_model.dart';
import '../../core/theme/f1_theme.dart';

class ProfileManagerScreen extends StatefulWidget {
  final ControllerProfile currentProfile;
  final Function(ControllerProfile updatedProfile) onSaveProfile;

  const ProfileManagerScreen({
    super.key,
    required this.currentProfile,
    required this.onSaveProfile,
  });

  @override
  State<ProfileManagerScreen> createState() => _ProfileManagerScreenState();
}

class _ProfileManagerScreenState extends State<ProfileManagerScreen> {
  late ControllerProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = ControllerProfile(
      id: widget.currentProfile.id,
      name: widget.currentProfile.name,
      steeringDeadzone: widget.currentProfile.steeringDeadzone,
      throttleDeadzone: widget.currentProfile.throttleDeadzone,
      brakeDeadzone: widget.currentProfile.brakeDeadzone,
      steeringRotationDegrees: widget.currentProfile.steeringRotationDegrees,
      linearityMode: widget.currentProfile.linearityMode,
      gyroSteeringEnabled: widget.currentProfile.gyroSteeringEnabled,
      gyroSensitivity: widget.currentProfile.gyroSensitivity,
      hapticFeedbackEnabled: widget.currentProfile.hapticFeedbackEnabled,
      hardwareVolumePaddles: widget.currentProfile.hardwareVolumePaddles,
      playerId: widget.currentProfile.playerId,
      swapPaddleShifters: widget.currentProfile.swapPaddleShifters,
      invertGyro: widget.currentProfile.invertGyro,
      gyroDeadzone: widget.currentProfile.gyroDeadzone,
    );
  }

  void _applyPreset(ControllerProfile preset) {
    setState(() {
      _profile = preset;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: F1Theme.f1DarkBg,
      appBar: AppBar(
        backgroundColor: F1Theme.carbonSurface,
        title: const Text('CONTROLLER PROFILES & CALIBRATION'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: F1Theme.neonGreen),
            onPressed: () {
              widget.onSaveProfile(_profile);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Presets Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: F1Theme.carbonDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LOAD PRESET PROFILE',
                  style: TextStyle(color: F1Theme.electricAmber, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: F1Theme.f1Red),
                        onPressed: () => _applyPreset(ControllerProfile.defaultF1Preset()),
                        child: const Text('F1 24/25', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: F1Theme.carbonCard),
                        onPressed: () => _applyPreset(ControllerProfile.gt3Preset()),
                        child: const Text('GT3 / GT4', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: F1Theme.carbonCard),
                        onPressed: () => _applyPreset(ControllerProfile.genericGamepadPreset()),
                        child: const Text('Arcade', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Deadzones & Calibration
          Container(
            padding: const EdgeInsets.all(16),
            decoration: F1Theme.carbonDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DEADZONE TUNING',
                  style: TextStyle(color: F1Theme.neonCyan, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 12),
                _buildSliderTile(
                  title: 'Steering Deadzone',
                  value: _profile.steeringDeadzone,
                  min: 0.0,
                  max: 0.20,
                  onChanged: (val) => setState(() => _profile.steeringDeadzone = val),
                  displayVal: '${(_profile.steeringDeadzone * 100).round()}%',
                ),
                _buildSliderTile(
                  title: 'Throttle Deadzone',
                  value: _profile.throttleDeadzone,
                  min: 0.0,
                  max: 0.20,
                  onChanged: (val) => setState(() => _profile.throttleDeadzone = val),
                  displayVal: '${(_profile.throttleDeadzone * 100).round()}%',
                ),
                _buildSliderTile(
                  title: 'Brake Deadzone',
                  value: _profile.brakeDeadzone,
                  min: 0.0,
                  max: 0.20,
                  onChanged: (val) => setState(() => _profile.brakeDeadzone = val),
                  displayVal: '${(_profile.brakeDeadzone * 100).round()}%',
                ),
                _buildSliderTile(
                  title: 'Gyro Tilt Deadzone',
                  value: _profile.gyroDeadzone,
                  min: 0.0,
                  max: 0.20,
                  onChanged: (val) => setState(() => _profile.gyroDeadzone = val),
                  displayVal: '${(_profile.gyroDeadzone * 100).round()}%',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Wheel & Gyro Settings
          Container(
            padding: const EdgeInsets.all(16),
            decoration: F1Theme.carbonDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STEERING ROTATION & GYRO',
                  style: TextStyle(color: F1Theme.neonGreen, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Rotation Range:', style: TextStyle(color: Colors.white)),
                    DropdownButton<int>(
                      value: _profile.steeringRotationDegrees,
                      dropdownColor: F1Theme.carbonCard,
                      items: const [
                        DropdownMenuItem(value: 270, child: Text('270° (Arcade)')),
                        DropdownMenuItem(value: 360, child: Text('360° (F1 Standard)')),
                        DropdownMenuItem(value: 540, child: Text('540° (Rally/GT)')),
                        DropdownMenuItem(value: 900, child: Text('900° (Full Road)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _profile.steeringRotationDegrees = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Response Curve:', style: TextStyle(color: Colors.white)),
                    DropdownButton<String>(
                      value: _profile.linearityMode,
                      dropdownColor: F1Theme.carbonCard,
                      items: const [
                        DropdownMenuItem(value: 'linear', child: Text('Linear 1:1')),
                        DropdownMenuItem(value: 'exponential', child: Text('Exponential (Precision)')),
                        DropdownMenuItem(value: 's_curve', child: Text('S-Curve (Progressive)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _profile.linearityMode = val);
                      },
                    ),
                  ],
                ),
                SwitchListTile(
                  title: const Text('Enable Gyro Tilt Steering', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Tilt phone left/right to steer', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  value: _profile.gyroSteeringEnabled,
                  onChanged: (val) => setState(() => _profile.gyroSteeringEnabled = val),
                  activeTrackColor: F1Theme.neonGreen,
                ),
                const SizedBox(height: 8),
                _buildSliderTile(
                  title: 'Gyro Sensitivity Multiplier',
                  value: _profile.gyroSensitivity,
                  min: 0.5,
                  max: 3.0,
                  onChanged: (val) => setState(() => _profile.gyroSensitivity = val),
                  displayVal: '${_profile.gyroSensitivity.toStringAsFixed(1)}x',
                ),
                SwitchListTile(
                  title: const Text('Invert Gyro Steering', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Reverse left/right tilt direction', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  value: _profile.invertGyro,
                  onChanged: (val) => setState(() => _profile.invertGyro = val),
                  activeTrackColor: F1Theme.neonGreen,
                ),
                SwitchListTile(
                  title: const Text('Hardware Volume Key Paddles', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Use Vol+ / Vol- physical keys for gear shift', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  value: _profile.hardwareVolumePaddles,
                  onChanged: (val) => setState(() => _profile.hardwareVolumePaddles = val),
                  activeTrackColor: F1Theme.neonCyan,
                ),
                SwitchListTile(
                  title: const Text('Swap Paddle Shifters', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Left = Upshift, Right = Downshift', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  value: _profile.swapPaddleShifters,
                  onChanged: (val) => setState(() => _profile.swapPaddleShifters = val),
                  activeTrackColor: F1Theme.neonCyan,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required String displayVal,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text(displayVal, style: const TextStyle(color: F1Theme.neonCyan, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: F1Theme.neonCyan,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
