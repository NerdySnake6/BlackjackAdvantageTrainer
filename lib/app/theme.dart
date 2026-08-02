/// Visual system for the training application.
library;

import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF07161C);
  static const felt = Color(0xFF0A4F45);
  static const feltLight = Color(0xFF147463);
  static const mint = Color(0xFF56E0B5);
  static const gold = Color(0xFFF2C14E);
  static const cream = Color(0xFFF6F0DE);
  static const danger = Color(0xFFFF6B6B);
}

ThemeData buildAppTheme() {
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.mint,
        brightness: Brightness.dark,
        surface: const Color(0xFF10252C),
      ).copyWith(
        primary: AppColors.mint,
        secondary: AppColors.gold,
        error: AppColors.danger,
      );

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.ink,
    useMaterial3: true,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -1),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(height: 1.4),
      bodyMedium: TextStyle(height: 1.35),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF0B1C22),
      indicatorColor: AppColors.mint.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.selected)
              ? AppColors.mint
              : Colors.white60,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
  );
}
