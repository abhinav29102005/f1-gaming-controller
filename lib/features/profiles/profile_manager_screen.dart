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

class _ProfileManagerScreenState extends State<ProfileManagerScreen>
    with SingleTickerProviderStateMixin {
  late ControllerProfile _profile;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _profile = _copyProfile(widget.currentProfile);

    // Start on the tab that matches the current layout
    int initialTab = 0;
    if (_profile.layoutMode == 'tekken_7') initialTab = 1;
    if (_profile.layoutMode == 'generic') initialTab = 2;

    _tabController = TabController(length: 3, vsync: this, initialIndex: initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ControllerProfile _copyProfile(ControllerProfile src) {
    return ControllerProfile(
      id: src.id,
      name: src.name,
      steeringDeadzone: src.steeringDeadzone,
      throttleDeadzone: src.throttleDeadzone,
      brakeDeadzone: src.brakeDeadzone,
      steeringRotationDegrees: src.steeringRotationDegrees,
      linearityMode: src.linearityMode,
      gyroSteeringEnabled: src.gyroSteeringEnabled,
      gyroSensitivity: src.gyroSensitivity,
      hapticFeedbackEnabled: src.hapticFeedbackEnabled,
      hardwareVolumePaddles: src.hardwareVolumePaddles,
      playerId: src.playerId,
      swapPaddleShifters: src.swapPaddleShifters,
      invertGyro: src.invertGyro,
      gyroDeadzone: src.gyroDeadzone,
      layoutMode: src.layoutMode,
    );
  }

  void _applyPreset(ControllerProfile preset) {
    setState(() => _profile = preset);
  }

  // ── Shared slider tile ─────────────────────────────────────────────
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
            Text(title,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text(displayVal,
                style: const TextStyle(
                    color: F1Theme.neonCyan,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace')),
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

  // ══════════════════════════════════════════════════════════════════
  // TAB 0 — F1 RACING
  // ══════════════════════════════════════════════════════════════════
  Widget _buildF1Tab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Presets
        Container(
          padding: const EdgeInsets.all(16),
          decoration: F1Theme.carbonDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('LOAD PRESET PROFILE',
                  style: TextStyle(
                      color: F1Theme.electricAmber,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: F1Theme.f1Red),
                      onPressed: () {
                        _applyPreset(ControllerProfile.defaultF1Preset());
                      },
                      child: const Text('F1 24/25',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: F1Theme.carbonCard),
                      onPressed: () =>
                          _applyPreset(ControllerProfile.gt3Preset()),
                      child: const Text('GT3 / GT4',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Deadzones
        Container(
          padding: const EdgeInsets.all(16),
          decoration: F1Theme.carbonDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('DEADZONE TUNING',
                  style: TextStyle(
                      color: F1Theme.neonCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const SizedBox(height: 12),
              _buildSliderTile(
                title: 'Steering Deadzone',
                value: _profile.steeringDeadzone,
                min: 0.0,
                max: 0.20,
                onChanged: (v) =>
                    setState(() => _profile.steeringDeadzone = v),
                displayVal:
                    '${(_profile.steeringDeadzone * 100).round()}%',
              ),
              _buildSliderTile(
                title: 'Throttle Deadzone',
                value: _profile.throttleDeadzone,
                min: 0.0,
                max: 0.20,
                onChanged: (v) =>
                    setState(() => _profile.throttleDeadzone = v),
                displayVal:
                    '${(_profile.throttleDeadzone * 100).round()}%',
              ),
              _buildSliderTile(
                title: 'Brake Deadzone',
                value: _profile.brakeDeadzone,
                min: 0.0,
                max: 0.20,
                onChanged: (v) =>
                    setState(() => _profile.brakeDeadzone = v),
                displayVal:
                    '${(_profile.brakeDeadzone * 100).round()}%',
              ),
              _buildSliderTile(
                title: 'Gyro Tilt Deadzone',
                value: _profile.gyroDeadzone,
                min: 0.0,
                max: 0.20,
                onChanged: (v) =>
                    setState(() => _profile.gyroDeadzone = v),
                displayVal:
                    '${(_profile.gyroDeadzone * 100).round()}%',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Steering / Gyro
        Container(
          padding: const EdgeInsets.all(16),
          decoration: F1Theme.carbonDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('STEERING ROTATION & GYRO',
                  style: TextStyle(
                      color: F1Theme.neonGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Rotation Range:',
                      style: TextStyle(color: Colors.white)),
                  DropdownButton<int>(
                    value: _profile.steeringRotationDegrees,
                    dropdownColor: F1Theme.carbonCard,
                    items: const [
                      DropdownMenuItem(
                          value: 270, child: Text('270° (Arcade)')),
                      DropdownMenuItem(
                          value: 360,
                          child: Text('360° (F1 Standard)')),
                      DropdownMenuItem(
                          value: 540, child: Text('540° (Rally/GT)')),
                      DropdownMenuItem(
                          value: 900,
                          child: Text('900° (Full Road)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(
                            () => _profile.steeringRotationDegrees = val);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Response Curve:',
                      style: TextStyle(color: Colors.white)),
                  DropdownButton<String>(
                    value: _profile.linearityMode,
                    dropdownColor: F1Theme.carbonCard,
                    items: const [
                      DropdownMenuItem(
                          value: 'linear', child: Text('Linear 1:1')),
                      DropdownMenuItem(
                          value: 'exponential',
                          child: Text('Exponential')),
                      DropdownMenuItem(
                          value: 's_curve',
                          child: Text('S-Curve')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _profile.linearityMode = val);
                      }
                    },
                  ),
                ],
              ),
              SwitchListTile(
                title: const Text('Enable Gyro Tilt Steering',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Tilt phone left/right to steer',
                    style:
                        TextStyle(color: Colors.white54, fontSize: 11)),
                value: _profile.gyroSteeringEnabled,
                onChanged: (v) =>
                    setState(() => _profile.gyroSteeringEnabled = v),
                activeTrackColor: F1Theme.neonGreen,
              ),
              _buildSliderTile(
                title: 'Gyro Sensitivity',
                value: _profile.gyroSensitivity,
                min: 0.5,
                max: 3.0,
                onChanged: (v) =>
                    setState(() => _profile.gyroSensitivity = v),
                displayVal:
                    '${_profile.gyroSensitivity.toStringAsFixed(1)}x',
              ),
              SwitchListTile(
                title: const Text('Invert Gyro',
                    style: TextStyle(color: Colors.white)),
                value: _profile.invertGyro,
                onChanged: (v) =>
                    setState(() => _profile.invertGyro = v),
                activeTrackColor: F1Theme.neonGreen,
              ),
              SwitchListTile(
                title: const Text('Volume Key Paddles',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Vol+ / Vol- for gear shift',
                    style:
                        TextStyle(color: Colors.white54, fontSize: 11)),
                value: _profile.hardwareVolumePaddles,
                onChanged: (v) =>
                    setState(() => _profile.hardwareVolumePaddles = v),
                activeTrackColor: F1Theme.neonCyan,
              ),
              SwitchListTile(
                title: const Text('Swap Paddle Shifters',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text(
                    'Left = Upshift, Right = Downshift',
                    style:
                        TextStyle(color: Colors.white54, fontSize: 11)),
                value: _profile.swapPaddleShifters,
                onChanged: (v) =>
                    setState(() => _profile.swapPaddleShifters = v),
                activeTrackColor: F1Theme.neonCyan,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // TAB 1 — TEKKEN 7
  // ══════════════════════════════════════════════════════════════════
  Widget _buildTekkenTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Load preset CTA
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.sports_martial_arts, size: 20),
            label: const Text(
              'LOAD TEKKEN 7 LAYOUT',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: F1Theme.f1Red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () =>
                _applyPreset(ControllerProfile.tekken7Preset()),
          ),
        ),
        const SizedBox(height: 16),

        // Haptics toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: F1Theme.carbonDecoration(),
          child: SwitchListTile(
            title: const Text('Haptic Feedback',
                style: TextStyle(color: Colors.white)),
            subtitle: const Text('Vibrate on every button press',
                style: TextStyle(color: Colors.white54, fontSize: 11)),
            value: _profile.hapticFeedbackEnabled,
            onChanged: (v) =>
                setState(() => _profile.hapticFeedbackEnabled = v),
            activeTrackColor: F1Theme.f1Red,
          ),
        ),
        const SizedBox(height: 16),

        // Button reference card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: F1Theme.carbonDecoration(
              borderColor: F1Theme.f1Red.withOpacity(0.4)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('BUTTON REFERENCE',
                  style: TextStyle(
                      color: F1Theme.f1Red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1)),
              const SizedBox(height: 14),
              _buildButtonRefRow(
                  'A', const Color(0xFF107C10), 'LP', 'Left Punch'),
              _buildButtonRefRow(
                  'Y', const Color(0xFFFFB900), 'RP', 'Right Punch'),
              _buildButtonRefRow(
                  'X', const Color(0xFF0078D4), 'LK', 'Left Kick'),
              _buildButtonRefRow(
                  'B', const Color(0xFFE81123), 'RK', 'Right Kick'),
              const Divider(color: Colors.white12, height: 20),
              _buildButtonRefRow('L1', F1Theme.neonCyan, '', 'Block'),
              _buildButtonRefRow(
                  'R1', F1Theme.electricAmber, '', 'Throw'),
              _buildButtonRefRow(
                  'L2', F1Theme.f1Red, '', 'Rage Art Trigger'),
              _buildButtonRefRow(
                  'R2', F1Theme.neonGreen, '', 'Rage Drive Trigger'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Combo reference card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: F1Theme.carbonDecoration(
              borderColor: F1Theme.electricAmber.withOpacity(0.4)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('COMBO REFERENCE',
                  style: TextStyle(
                      color: F1Theme.electricAmber,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1)),
              const SizedBox(height: 14),
              _buildComboRefRow(
                  '1+2', 'LP + RP', F1Theme.neonCyan),
              _buildComboRefRow(
                  '2+4', 'RP + RK', F1Theme.electricAmber),
              _buildComboRefRow(
                  '1+3+4', 'LP + LK + RK', F1Theme.magentaPurple),
              _buildComboRefRow(
                  'RAGE ART', 'L2 + LP + RP', F1Theme.f1Red),
              _buildComboRefRow(
                  'HEAT SMASH', 'LP + RK', const Color(0xFFFF6B00)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButtonRefRow(
      String button, Color color, String tekken, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Center(
              child: Text(
                button,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (tekken.isNotEmpty) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tekken,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            action,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildComboRefRow(String name, String inputs, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 90,
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Text(
              name,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            inputs,
            style:
                const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // TAB 2 — GENERIC GAMEPAD
  // ══════════════════════════════════════════════════════════════════
  Widget _buildGenericTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Load preset CTA
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.gamepad, size: 20),
            label: const Text(
              'LOAD GENERIC / ARCADE PRESET',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.2),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: F1Theme.carbonCard,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: F1Theme.neonCyan),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () =>
                _applyPreset(ControllerProfile.genericGamepadPreset()),
          ),
        ),
        const SizedBox(height: 16),

        // Deadzones
        Container(
          padding: const EdgeInsets.all(16),
          decoration: F1Theme.carbonDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('DEADZONE TUNING',
                  style: TextStyle(
                      color: F1Theme.neonCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const SizedBox(height: 12),
              _buildSliderTile(
                title: 'Steering Deadzone',
                value: _profile.steeringDeadzone,
                min: 0.0,
                max: 0.20,
                onChanged: (v) =>
                    setState(() => _profile.steeringDeadzone = v),
                displayVal:
                    '${(_profile.steeringDeadzone * 100).round()}%',
              ),
              _buildSliderTile(
                title: 'Throttle Deadzone',
                value: _profile.throttleDeadzone,
                min: 0.0,
                max: 0.20,
                onChanged: (v) =>
                    setState(() => _profile.throttleDeadzone = v),
                displayVal:
                    '${(_profile.throttleDeadzone * 100).round()}%',
              ),
              _buildSliderTile(
                title: 'Brake Deadzone',
                value: _profile.brakeDeadzone,
                min: 0.0,
                max: 0.20,
                onChanged: (v) =>
                    setState(() => _profile.brakeDeadzone = v),
                displayVal:
                    '${(_profile.brakeDeadzone * 100).round()}%',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Gyro settings
        Container(
          padding: const EdgeInsets.all(16),
          decoration: F1Theme.carbonDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('GYRO STEERING',
                  style: TextStyle(
                      color: F1Theme.neonGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Rotation Range:',
                      style: TextStyle(color: Colors.white)),
                  DropdownButton<int>(
                    value: _profile.steeringRotationDegrees,
                    dropdownColor: F1Theme.carbonCard,
                    items: const [
                      DropdownMenuItem(
                          value: 270, child: Text('270°')),
                      DropdownMenuItem(
                          value: 360, child: Text('360°')),
                      DropdownMenuItem(
                          value: 540, child: Text('540°')),
                      DropdownMenuItem(
                          value: 900, child: Text('900°')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(
                            () => _profile.steeringRotationDegrees = val);
                      }
                    },
                  ),
                ],
              ),
              SwitchListTile(
                title: const Text('Enable Gyro',
                    style: TextStyle(color: Colors.white)),
                value: _profile.gyroSteeringEnabled,
                onChanged: (v) =>
                    setState(() => _profile.gyroSteeringEnabled = v),
                activeTrackColor: F1Theme.neonGreen,
              ),
              _buildSliderTile(
                title: 'Gyro Sensitivity',
                value: _profile.gyroSensitivity,
                min: 0.5,
                max: 3.0,
                onChanged: (v) =>
                    setState(() => _profile.gyroSensitivity = v),
                displayVal:
                    '${_profile.gyroSensitivity.toStringAsFixed(1)}x',
              ),
              SwitchListTile(
                title: const Text('Haptic Feedback',
                    style: TextStyle(color: Colors.white)),
                value: _profile.hapticFeedbackEnabled,
                onChanged: (v) =>
                    setState(() => _profile.hapticFeedbackEnabled = v),
                activeTrackColor: F1Theme.neonCyan,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // MAIN BUILD
  // ══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: F1Theme.f1DarkBg,
      appBar: AppBar(
        backgroundColor: F1Theme.carbonSurface,
        title: const Text(
          'CONTROLLER PROFILES & CALIBRATION',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: F1Theme.neonGreen),
            tooltip: 'Save & Apply',
            onPressed: () {
              widget.onSaveProfile(_profile);
              Navigator.pop(context);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: F1Theme.electricAmber,
          indicatorWeight: 3,
          labelColor: F1Theme.electricAmber,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8),
          tabs: const [
            Tab(
              icon: Icon(Icons.sports_motorsports, size: 18),
              text: 'F1 RACING',
            ),
            Tab(
              icon: Icon(Icons.sports_martial_arts, size: 18),
              text: 'TEKKEN 7',
            ),
            Tab(
              icon: Icon(Icons.gamepad, size: 18),
              text: 'GENERIC',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildF1Tab(),
          _buildTekkenTab(),
          _buildGenericTab(),
        ],
      ),
    );
  }
}
