import 'package:flutter/material.dart';

class AppTheme {
  // Cobalt Sky Palette
  static const Color cobaltBlue = Color(0xFF0047AB); // #0047AB Primary
  static const Color navyBlue = Color(0xFF000080);   // #000080 Deep Accent
  static const Color skyBlue = Color(0xFF82C8E5);    // #82C8E5 Sky Accent
  static const Color steelBlue = Color(0xFF475569);  // #475569 High-Contrast Slate

  // Functional semantic aliases
  static const Color primary = Color(0xFF10B981);    // Emerald Green (#10B981) for primary CTA buttons
  static const Color primaryDark = Color(0xFF059669);
  static const Color primaryLight = cobaltBlue;
  static const Color secondary = cobaltBlue;
  static const Color accent = Color(0xFF10B981);     // Emerald Green
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);

  // Light Theme Palette (Clean White)
  static const Color backgroundLight = Color(0xFFF8FAFC); // Crisp canvas
  static const Color surfaceLight = Color(0xFFFFFFFF);    // Pure White surface
  static const Color cardLight = Color(0xFFFFFFFF);       // Pure White cards
  static const Color borderLight = Color(0xFFE2E8F0);     // Subtle border
  static const Color textPrimaryLight = Color(0xFF0F172A); // High-contrast dark text
  static const Color textSecondaryLight = Color(0xFF475569); // High-contrast secondary text (Darker Slate)

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cobaltGradient = LinearGradient(
    colors: [cobaltBlue, Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFF8FAFC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Backward-compatible semantic aliases for screens
  static const Color backgroundDark = backgroundLight;
  static const Color surfaceDark = surfaceLight;
  static const Color cardDark = Color(0xFFF1F5F9);
  static const Color textPrimaryDark = textPrimaryLight;
  static const Color textSecondaryDark = textSecondaryLight;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: cobaltBlue,
        surface: surfaceLight,
        error: danger,
        onPrimary: Colors.white,
        onSurface: textPrimaryLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceLight,
        foregroundColor: textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimaryLight),
        titleTextStyle: TextStyle(
          color: textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        labelStyle: const TextStyle(color: textSecondaryLight, fontWeight: FontWeight.w500),
        prefixIconColor: cobaltBlue,
        suffixIconColor: textSecondaryLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: cobaltBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: danger),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimaryLight,
          side: const BorderSide(color: borderLight, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceLight,
        modalBackgroundColor: surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF1F5F9),
        labelStyle: const TextStyle(
          color: textPrimaryLight,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: borderLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
