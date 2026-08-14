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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: F1Theme.f1DarkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Top Bar: Multiplayer Lobby & Telemetry HUD
              MultiplayerLobbyWidget(
                state: _state,
                profile: _profile,
                inputLoop: _inputLoop,
                layoutMode: _profile.layoutMode,
                onPlayerSlotChanged: _onPlayerSlotChanged,
                onOpenSettings: _openSettings,
                onOpenConnection: _openConnection,
                onOpenHostMode: _openHostMode,
              ),
              const SizedBox(height: 8),
              // Main controller body — switches on layoutMode
              Expanded(
                child: (_profile.layoutMode == 'tekken_8' || _profile.layoutMode == 'tekken_7')
                    ? TekkenControllerLayout(
                        state: _state,
                        hapticsEnabled: _profile.hapticFeedbackEnabled,
                      )
                    : _buildF1CockpitRow(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
