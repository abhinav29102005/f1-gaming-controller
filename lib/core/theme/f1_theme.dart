import 'package:flutter/material.dart';

class F1Theme {
  // Brand Racing Colors
  static const Color f1Red = Color(0xFFFF1801);
  static const Color f1DarkBg = Color(0xFF0B0D12);
  static const Color carbonSurface = Color(0xFF141822);
  static const Color carbonCard = Color(0xFF1C2230);
  
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color neonGreen = Color(0xFF00FF66);
  static const Color electricAmber = Color(0xFFFFB800);
  static const Color magentaPurple = Color(0xFFD000FF);

  // Player Slot LED Accents (P1..P4)
  static const List<Color> playerColors = [
    f1Red,        // P1: Electric Red
    neonCyan,     // P2: Neon Cyan
    electricAmber,// P3: Amber Gold
    magentaPurple,// P4: Neon Purple
  ];

  static Color getPlayerColor(int playerId) {
    return playerColors[playerId.clamp(0, 3)];
  }

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: f1DarkBg,
      primaryColor: f1Red,
      colorScheme: const ColorScheme.dark(
        primary: f1Red,
        secondary: neonCyan,
        surface: carbonSurface,
      ),
      cardTheme: CardThemeData(
        color: carbonCard,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white10, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: f1Red,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: f1Red.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
    );
  }

  // Carbon Fiber Pattern Decoration
  static BoxDecoration carbonDecoration({
    Color borderColor = Colors.white24,
    double borderRadius = 16.0,
    Color? glowColor,
  }) {
    return BoxDecoration(
      color: carbonSurface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: 1.5),
      boxShadow: [
        if (glowColor != null)
          BoxShadow(
            color: glowColor.withOpacity(0.35),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        const BoxShadow(
          color: Colors.black54,
          blurRadius: 12,
          offset: Offset(0, 6),
        ),
      ],
    );
  }

  // Glassmorphic HUD Card
  static BoxDecoration glassDecoration({
    Color borderColor = Colors.white12,
    double borderRadius = 16.0,
  }) {
    return BoxDecoration(
      color: const Color(0xFF141A29).withOpacity(0.75),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 15,
          spreadRadius: 1,
        ),
      ],
    );
  }
}
