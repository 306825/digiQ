import 'dart:ui';

import 'package:flutter/material.dart';

class AppTheme {
  // 🌊 Brand Colors (Blue System)
  static const primary = Color(0xFF0D47A1); // Deep Blue
  static const primaryLight = Color(0xFFE3F2FD); // Soft Blue Tint
  static const secondary = Color(0xFF1976D2); // Accent Blue

  // 🌱 Semantic Colors
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFF9A825);
  static const danger = Color(0xFFC62828);

  // 🧱 Surfaces
  static const background = Color(0xFFF4F7FB);
  static const surface = Colors.white;
  static const divider = Color(0xFFE0E6ED);

  // ✍️ Text
  static const textDark = Color(0xFF0F1C2E);
  static const textMuted = Color(0xFF5F6B7A);

  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: primary,
      secondary: secondary,
      background: background,
      surface: surface,
      error: danger,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: colorScheme,

      // ───────────────────────── App Bar ─────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // ───────────────────────── Floating Button ─────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),

      // ───────────────────────── Elevated Buttons ─────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ───────────────────────── Outlined Buttons ─────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: primary),
        ),
      ),

      // ───────────────────────── Inputs ─────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted),
        labelStyle: const TextStyle(color: textMuted),
      ),

      // ───────────────────────── Cards ─────────────────────────
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ───────────────────────── Dividers ─────────────────────────
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
      ),

      // ───────────────────────── Icons ─────────────────────────
      iconTheme: const IconThemeData(
        color: textDark,
      ),

      // ───────────────────────── Text ─────────────────────────
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textDark),
        bodyMedium: TextStyle(color: textDark),
        bodySmall: TextStyle(color: textMuted),
        titleMedium: TextStyle(
          color: textDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
