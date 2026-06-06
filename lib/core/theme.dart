import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Qanoon Buddy Elite Palette
  static const Color navyDeep   = Color(0xFF0A1128); // Deep Space Navy
  static const Color navyLight  = Color(0xFF1C2541);
  static const Color goldPremium = Color(0xFFD4AF37); // Luxury Gold
  static const Color goldMuted   = Color(0xFF9A8447);
  static const Color glassWhite  = Color(0x1FFFFFFF); // Glassmorphism base
  static const Color surface     = Color(0xFFF8FAFC);
  static const Color textDark    = Color(0xFF0F172A);
  static const Color textGrey    = Color(0xFF64748B);
  static const Color border      = Color(0xFFE2E8F0);
  static const Color warning     = Color(0xFFF59E0B);
  static const Color pending     = Color(0xFFF59E0B);
  static const Color accepted    = Color(0xFF2563EB);
  static const Color inProgress  = Color(0xFF8B5CF6);
  static const Color completed   = Color(0xFF10B981);
  static const Color error       = Color(0xFFEF4444);
  static const Color cancelled   = Color(0xFFEF4444);
  static const Color navyDarker  = Color(0xFF070B1A);
  static const Color glassBorder = Color(0x26FFFFFF);
  static const Color brandJazz   = Color(0xFFEF1B23); // JazzCash Brand Color

  // Action Gradients
  static const List<Color> gradPurple  = [Color(0xFF8B5CF6), Color(0xFF6366F1)];
  static const List<Color> gradBlue    = [Color(0xFF1E3A8A), Color(0xFF312E81)];
  static const List<Color> gradCyan    = [Color(0xFF06B6D4), Color(0xFF3B82F6)];
  static const List<Color> gradPink    = [Color(0xFFEC4899), Color(0xFFE11D48)];
  static const List<Color> gradEmerald = [Color(0xFF10B981), Color(0xFF059669)];
  static const List<Color> gradAmber   = [Color(0xFFF59E0B), Color(0xFFEA580C)];
  static const List<Color> gradBlueMid = [Color(0xFF2563EB), Color(0xFF1D4ED8)];

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    textTheme: GoogleFonts.poppinsTextTheme(),
    scaffoldBackgroundColor: surface,
    colorScheme: const ColorScheme.light(
      primary:   navyDeep,
      secondary: goldPremium,
      surface:   Colors.white,
      onPrimary: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: navyDeep,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: navyDeep,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: navyDeep, width: 1.5),
      ),
    ),
  );
}