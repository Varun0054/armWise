import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Palette - Sleek & Modern Glassmorphic Light Mode
  static const bgLight = Color(0xFFF8FAFC);
  static const bgCard = Color(0xFFFFFFFF);
  static const bgCardHover = Color(0xFFF1F5F9);
  static const borderColor = Color(0xFFE2E8F0);
  
  // Accents
  static const accentBlue = Color(0xFF2563EB);
  static const accentCyan = Color(0xFF0891B2);
  
  // Rating Badge Colors
  static const nativeEmerald = Color(0xFF059669);
  static const compatibleBlue = Color(0xFF2563EB);
  static const uncertainAmber = Color(0xFFD97706);
  static const riskCrimson = Color(0xFFDC2626);
  
  // Typography Colors
  static const textMain = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);

  static Color categoryColor(String category) {
    switch (category) {
      case 'Native': return nativeEmerald;
      case 'Likely Compatible': return compatibleBlue;
      case 'Uncertain': return uncertainAmber;
      case 'High Risk': return riskCrimson;
      default: return textMuted;
    }
  }

  static Color categoryBg(String category) {
    return categoryColor(category).withOpacity(0.12);
  }

  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: bgLight,
    colorScheme: const ColorScheme.light(
      primary: accentBlue,
      secondary: accentCyan,
      surface: bgCard,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).apply(
      bodyColor: textMain,
      displayColor: textMain,
    ),
    cardTheme: CardThemeData(
      color: bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: borderColor),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: accentBlue),
      ),
      hintStyle: const TextStyle(color: textMuted),
    ),
  );
}
