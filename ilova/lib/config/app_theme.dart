import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFFE50914);
  static const Color primaryDark = Color(0xFFB81D24);
  static const Color primaryLight = Color(0xFFFF3D47);
  
  static const Color bgDark = Color(0xFF0F1017);
  static const Color bgDarker = Color(0xFF08090C);
  static const Color bgCard = Color(0xFF181A24);
  static const Color bgElevated = Color(0xFF222533);
  
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF9E9EA7);
  static const Color textDark = Color(0xFF121212);
  
  static const Color accentGold = Color(0xFFFFB800);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primary,
    scaffoldBackgroundColor: bgDark,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: primaryLight,
      surface: bgCard,
      error: danger,
      onPrimary: textLight,
      onSecondary: textLight,
      onSurface: textLight,
      onError: textLight,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bgDarker,
      foregroundColor: textLight,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textLight,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Montserrat',
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: bgDarker,
      selectedItemColor: primary,
      unselectedItemColor: textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: textLight, fontWeight: FontWeight.bold, fontSize: 28),
      headlineMedium: TextStyle(color: textLight, fontWeight: FontWeight.bold, fontSize: 22),
      titleLarge: TextStyle(color: textLight, fontWeight: FontWeight.w600, fontSize: 18),
      titleMedium: TextStyle(color: textLight, fontWeight: FontWeight.w500, fontSize: 16),
      bodyLarge: TextStyle(color: textLight, fontSize: 15),
      bodyMedium: TextStyle(color: textMuted, fontSize: 13),
      labelLarge: TextStyle(color: textLight, fontWeight: FontWeight.w600, fontSize: 14),
    ),
    cardTheme: CardThemeData(
      color: bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF262938), width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgCard,
      hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E3346)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2E3346)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: textLight,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
