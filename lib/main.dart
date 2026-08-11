import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/hid/connection_manager.dart';
import 'core/models/profile_model.dart';
import 'core/theme/f1_theme.dart';
import 'features/controller_ui/controller_screen.dart';
import 'features/host_mode/host_receiver_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force Landscape Orientation & Immersive Fullscreen
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize Hive Persistence
  await Hive.initFlutter();
  Hive.registerAdapter(ControllerProfileAdapter());
  await Hive.openBox<ControllerProfile>('profiles_box');

  final connectionManager = ConnectionManager();
  await connectionManager.init();

  runApp(F1ControllerApp(connectionManager: connectionManager));
}

class F1ControllerApp extends StatelessWidget {
  final ConnectionManager connectionManager;

  const F1ControllerApp({
    super.key,
    required this.connectionManager,
  });

  @override
  Widget build(BuildContext context) {
    // Automatically boot into Host mode on Desktop OS, and Controller mode on Mobile OS
    bool isDesktop = false;
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        isDesktop = true;
      }
    } catch (e) {
      // For web fallback
    }

    return MaterialApp(
      title: 'F1 Gaming Controller',
      debugShowCheckedModeBanner: false,
      theme: F1Theme.darkTheme,
      home: isDesktop 
          ? const HostReceiverScreen() 
          : ControllerScreen(connectionManager: connectionManager),
    );
  }
}
