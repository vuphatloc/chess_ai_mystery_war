import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design system for Chess AI: Mystery War
/// Theme: Dark Futuristic with Neon Cyan, Purple, Gold accents
class AppTheme {
  // === Color Palette ===
  static const Color bgDeep = Color(0xFF080B14);
  static const Color bgSurface = Color(0xFF0F1523);
  static const Color bgCard = Color(0xFF161E2E);

  // Neon Cyan (Primary)
  static const Color neonCyan = Color(0xFF00F5FF);
  static const Color neonCyanDim = Color(0xFF00C9D4);
  static const Color neonCyanGlow = Color(0x4400F5FF);

  // Neon Purple (Secondary)
  static const Color neonPurple = Color(0xFFBF00FF);
  static const Color neonPurpleDim = Color(0xFF8B00CC);
  static const Color neonPurpleGlow = Color(0x44BF00FF);

  // Gold (Accent)
  static const Color gold = Color(0xFFFFD700);
  static const Color goldDim = Color(0xFFB8960C);
  static const Color goldGlow = Color(0x44FFD700);

  // Text
  static const Color textPrimary = Color(0xFFEAF4FF);
  static const Color textSecondary = Color(0xFF7A8FA6);
  static const Color textMuted = Color(0xFF3D5266);

  // Glass
  static const Color glassBg = Color(0x1A00F5FF);
  static const Color glassBorder = Color(0x3300F5FF);

  // Board colors
  static const Color boardLight = Color(0xFF1E3A5F);
  static const Color boardDark = Color(0xFF0D1F35);
  static const Color boardSelected = Color(0x8800F5FF);
  static const Color boardValidMove = Color(0x88BF00FF);

  // === Gradients ===
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF080B14), Color(0xFF0D1325), Color(0xFF0A0F1E)],
  );

  static const LinearGradient cyanPurpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonCyan, neonPurple],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
  );

  // === Text Styles ===
  static TextStyle get displayLarge => GoogleFonts.outfit(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -1,
      );

  static TextStyle get displayMedium => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get titleLarge => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textSecondary,
        letterSpacing: 0.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );

  static TextStyle get labelSmall => GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: textMuted,
        letterSpacing: 1.5,
      );

  // === Theme Data ===
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: bgDeep,
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonPurple,
        tertiary: gold,
        surface: bgSurface,
        onPrimary: bgDeep,
        onSecondary: bgDeep,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: textPrimary),
          displayMedium: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textSecondary),
        ),
      ),
    );
  }

  // === Decoration Helpers ===
  static BoxDecoration glassDecoration({
    double borderRadius = 16,
    Color? borderColor,
    Color? backgroundColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? glassBg,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? glassBorder,
        width: 1,
      ),
    );
  }

  static BoxDecoration neonBorderDecoration({
    double borderRadius = 16,
    Color color = neonCyan,
    double glowRadius = 8,
  }) {
    return BoxDecoration(
      color: bgCard,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: color, width: 1.5),
      boxShadow: [
        BoxShadow(color: color.withOpacity(0.3), blurRadius: glowRadius, spreadRadius: 1),
      ],
    );
  }
}
