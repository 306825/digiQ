import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Light palette ──────────────────────────────────────────────────────────
  static const primary = Color(0xFF0D47A1);
  static const primaryLight = Color(0xFFE3F2FD);
  static const secondary = Color(0xFF1565C0);

  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFF9A825);
  static const danger = Color(0xFFC62828);

  static const background = Color(0xFFF0F4F9);
  static const surface = Color(0xFFFFFFFF);
  static const divider = Color(0xFFDDE3EC);

  static const textDark = Color(0xFF0D1B2E);
  static const textMuted = Color(0xFF56687A);

  // ── Dark palette ───────────────────────────────────────────────────────────
  static const darkBackground = Color(0xFF0B1120);
  static const darkSurface = Color(0xFF141E30);
  static const darkCard = Color(0xFF1C2840);
  static const darkDivider = Color(0xFF2A3750);
  static const darkPrimary = Color(0xFF5B9BD5);
  static const darkTextPrimary = Color(0xFFE4ECF7);
  static const darkTextMuted = Color(0xFF7F94AD);

  // ── Shared ─────────────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Color primary, Color secondary) =>
      GoogleFonts.dmSansTextTheme().copyWith(
        displayLarge: GoogleFonts.dmSans(
            color: primary, fontSize: 32, fontWeight: FontWeight.w700),
        displayMedium: GoogleFonts.dmSans(
            color: primary, fontSize: 28, fontWeight: FontWeight.w700),
        headlineLarge: GoogleFonts.dmSans(
            color: primary, fontSize: 24, fontWeight: FontWeight.w700),
        headlineMedium: GoogleFonts.dmSans(
            color: primary, fontSize: 20, fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.dmSans(
            color: primary, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.dmSans(
            color: primary, fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.dmSans(
            color: primary, fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.dmSans(
            color: primary, fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.dmSans(
            color: primary, fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: GoogleFonts.dmSans(
            color: secondary, fontSize: 12, fontWeight: FontWeight.w400),
        labelLarge: GoogleFonts.dmSans(
            color: primary, fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: GoogleFonts.dmSans(
            color: secondary, fontSize: 12, fontWeight: FontWeight.w500),
      );

  // ── Light theme ────────────────────────────────────────────────────────────
  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryLight,
      onPrimaryContainer: primary,
      secondary: secondary,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: textDark,
      surfaceContainerHighest: const Color(0xFFE8EFF7),
      error: danger,
      onError: Colors.white,
      outline: divider,
    );

    final textTheme = _buildTextTheme(textDark, textMuted);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.dmSans(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: primary, width: 1.5),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger),
        ),
        hintStyle: GoogleFonts.dmSans(color: textMuted, fontSize: 14),
        labelStyle: GoogleFonts.dmSans(color: textMuted, fontSize: 14),
        floatingLabelStyle: GoogleFonts.dmSans(color: primary, fontSize: 12),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: divider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: primaryLight,
        labelStyle: GoogleFonts.dmSans(
          color: primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      iconTheme: const IconThemeData(color: textDark, size: 22),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: textDark,
        contentTextStyle: GoogleFonts.dmSans(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }

  // ── Dark theme ─────────────────────────────────────────────────────────────
  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      primary: darkPrimary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF1A3A6B),
      onPrimaryContainer: darkTextPrimary,
      secondary: const Color(0xFF7BB3E8),
      onSecondary: Colors.white,
      surface: darkSurface,
      onSurface: darkTextPrimary,
      surfaceContainerHighest: darkCard,
      error: const Color(0xFFEF5350),
      onError: Colors.white,
      outline: darkDivider,
    );

    final textTheme = _buildTextTheme(darkTextPrimary, darkTextMuted);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: darkPrimary,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.dmSans(
          color: darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: darkTextPrimary),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: darkPrimary, width: 1.5),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350)),
        ),
        hintStyle: GoogleFonts.dmSans(color: darkTextMuted, fontSize: 14),
        labelStyle: GoogleFonts.dmSans(color: darkTextMuted, fontSize: 14),
        floatingLabelStyle: GoogleFonts.dmSans(color: darkPrimary, fontSize: 12),
      ),

      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkDivider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      dividerTheme: const DividerThemeData(
        color: darkDivider,
        thickness: 1,
        space: 1,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1A3A6B),
        labelStyle: GoogleFonts.dmSans(
          color: darkPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      iconTheme: IconThemeData(color: darkTextPrimary, size: 22),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: darkCard,
        contentTextStyle: GoogleFonts.dmSans(
          color: darkTextPrimary,
          fontSize: 14,
        ),
      ),
    );
  }
}
