import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CyberTheme {
  // Brand Color Palette
  static const Color background = Color(0xFF131722);
  static const Color cardBg = Color(0xFF1E222B);
  static const Color borderDark = Color(0xFF2D313C);
  static const Color colorTextSecondary = Color(0xFFC1C6D2);
  static const Color colorTextMuted = Color(0xFF787E8D);
  
  // Accents
  static const Color neonGreen = Color(0xFF00C853);
  static const Color neonRed = Color(0xFFFF3D00);
  static const Color neonYellow = Color(0xFFFFB300);
  static const Color neonBlue = Color(0xFF00D2FF);
  static const Color neonPink = Color(0xFFFF007F);
  static const Color neonPurple = Color(0xFF9D00FF);

  // Theme Mode Settings
  static ThemeData get themeData {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: background,
      primaryColor: neonGreen,
      cardColor: cardBg,
      dialogTheme: const DialogTheme(
        backgroundColor: cardBg,
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
      colorScheme: const ColorScheme.dark(
        primary: neonGreen,
        secondary: neonYellow,
        error: neonRed,
        surface: cardBg,
      ),
    );
  }

  // Visual UI Decorations (14px Rounded Corners & Neon Glowing borders)
  static BoxDecoration neonCardDecoration({
    required Color accentColor,
    double glowRadius = 8.0,
    bool showGlow = true,
  }) {
    return BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: accentColor,
        width: 1.5,
      ),
      boxShadow: showGlow
          ? [
              BoxShadow(
                color: accentColor.withOpacity(0.35),
                blurRadius: glowRadius,
                spreadRadius: 1,
              )
            ]
          : null,
    );
  }

  static BoxDecoration standardCardDecoration() {
    return BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: borderDark,
        width: 1.0,
      ),
    );
  }

  // Typography helpers
  static TextStyle digitalStyle({
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}
