import 'package:flutter/material.dart';

import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/hid/connection_manager.dart';
import '../../core/hid/input_loop.dart';
import '../../core/models/controller_state.dart';
import '../../core/models/profile_model.dart';
import '../../core/theme/f1_theme.dart';
import '../connectivity/connection_screen.dart';
import '../connectivity/widgets/multiplayer_lobby_widget.dart';
import '../host_mode/host_receiver_screen.dart';
import '../profiles/profile_manager_screen.dart';
import 'layouts/asphalt_layout.dart';
import 'layouts/tekken_layout.dart';
import 'widgets/dpad_cluster.dart';
import 'widgets/f1_button_cluster.dart';
import 'widgets/paddle_shifters.dart';
import 'widgets/pedal_slider_widget.dart';
import 'widgets/steering_wheel_widget.dart';

class ControllerScreen extends StatefulWidget {
  final ConnectionManager connectionManager;

  const ControllerScreen({
    super.key,
    required this.connectionManager,
  });

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  final ControllerState _state = ControllerState();
  late ControllerProfile _profile;
  late InputLoop _inputLoop;

  @override
  void initState() {
    super.initState();
    // Enable wakelock to prevent screen sleep mid-race
    WakelockPlus.enable();

    _profile = ControllerProfile.defaultF1Preset();
    _inputLoop = InputLoop(
      state: _state,
      connectionManager: widget.connectionManager,
      profile: _profile,
    );

    _inputLoop.start();
  }

  @override
  void dispose() {
    _inputLoop.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _onPlayerSlotChanged(int newSlot) {
    setState(() {
      _state.playerId = newSlot;
      _profile.playerId = newSlot;
    });
  }

  void _onLayoutChanged(String newLayout) {
    ControllerProfile preset;
    switch (newLayout) {
      case 'asphalt_legends':
        preset = ControllerProfile.asphaltLegendsPreset();
        break;
      case 'tekken_8':
      case 'tekken_7':
        preset = ControllerProfile.tekken8Preset();
        break;
      case 'generic':
        preset = ControllerProfile.genericGamepadPreset();
        break;
      case 'f1_racing':
      default:
        preset = ControllerProfile.defaultF1Preset();
        break;
    }
    setState(() {
      _profile = preset;
      _inputLoop.updateProfile(preset);
    });
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileManagerScreen(
          currentProfile: _profile,
          onSaveProfile: (updatedProfile) {
            setState(() {
              _profile = updatedProfile;
              _inputLoop.updateProfile(updatedProfile);
            });
          },
        ),
      ),
    );
  }

  void _openConnection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConnectionScreen(
          connectionManager: widget.connectionManager,
          onConnectUpdated: () {
            setState(() {});
          },
        ),
      ),
    );
  }

  void _openHostMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HostReceiverScreen(),
      ),
    );
  }

  // ── F1 cockpit layout (original 5-column row) ─────────────────────
  Widget _buildF1CockpitRow() {
    final Color playerColor = F1Theme.getPlayerColor(_state.playerId);
    return Row(
      children: [
        // Brake pedal
        SizedBox(
          width: 90,
          child: PedalSliderWidget(
            state: _state,
            type: PedalType.brake,
            hapticsEnabled: _profile.hapticFeedbackEnabled,
          ),
        ),
        const SizedBox(width: 8),
        // D-Pad
        DPadCluster(
          state: _state,
          hapticsEnabled: _profile.hapticFeedbackEnabled,
        ),
        const SizedBox(width: 8),
        // Center: steering wheel + paddles
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: SteeringWheelWidget(
                  state: _state,
                  rotationDegrees: _profile.steeringRotationDegrees,
                  gyroEnabled: _profile.gyroSteeringEnabled,
                  gyroSensitivity: _profile.gyroSensitivity,
                  playerColor: playerColor,
                  invertGyro: _profile.invertGyro,
                  gyroDeadzone: _profile.gyroDeadzone,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: PaddleShiftersWidget(
                  state: _state,
                  hapticsEnabled: _profile.hapticFeedbackEnabled,
                  volumeKeysEnabled: _profile.hardwareVolumePaddles,
                  swapPaddleShifters: _profile.swapPaddleShifters,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Button cluster
        Expanded(
          child: F1ButtonCluster(
            state: _state,
            hapticsEnabled: _profile.hapticFeedbackEnabled,
          ),
        ),
        const SizedBox(width: 8),
        // Throttle pedal
        SizedBox(
          width: 90,
          child: PedalSliderWidget(
            state: _state,
            type: PedalType.throttle,
            hapticsEnabled: _profile.hapticFeedbackEnabled,
          ),
        ),
      ],
    );
  }

  Widget _buildBodyForLayout() {
    if (_profile.layoutMode == 'asphalt_legends') {
      return AsphaltControllerLayout(
        state: _state,
        hapticsEnabled: _profile.hapticFeedbackEnabled,
      );
    }
    if (_profile.layoutMode == 'tekken_8' || _profile.layoutMode == 'tekken_7') {
      return TekkenControllerLayout(
        state: _state,
        hapticsEnabled: _profile.hapticFeedbackEnabled,
      );
    }
    return _buildF1CockpitRow();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: F1Theme.f1DarkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            children: [
              // Compact Top Bar: Multiplayer Lobby, Telemetry HUD & Layout Switcher
              MultiplayerLobbyWidget(
                state: _state,
                profile: _profile,
                inputLoop: _inputLoop,
                layoutMode: _profile.layoutMode,
                onPlayerSlotChanged: _onPlayerSlotChanged,
                onOpenSettings: _openSettings,
                onOpenConnection: _openConnection,
                onOpenHostMode: _openHostMode,
                onLayoutChanged: _onLayoutChanged,
              ),
              const SizedBox(height: 6),
              // Main controller body — switches dynamically on layoutMode
              Expanded(
                child: _buildBodyForLayout(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
