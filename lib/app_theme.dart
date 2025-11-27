import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPalette {
  // Primitive Colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Color(0xFF636E72);
  static const Color lightGrey = Color(0xFFFDFDFD); // Off-white background
  static const Color transparent = Colors.transparent;

  // Brand Colors
  static const Color purple = Color(0xFF6C63FF);
  static const Color green = Color(0xFF00B894);
  static const Color red = Color(0xFFFF7675);
  static const Color neoGreen = Color(0xFF00E676);

  // Pastels
  static const List<Color> pastels = [
    Color(0xFFFF9F9F), // Pink
    Color(0xFF9EFFFF), // Cyan
    Color(0xFFB6FF99), // Lime
    Color(0xFFFFF599), // Yellow
    Color(0xFFD099FF), // Purple
  ];
}

class AppColors {
  // Semantic Colors

  // Backgrounds
  static const Color background = AppPalette.lightGrey;
  static const Color cardSurface = AppPalette.white;
  static const Color overlayBackground =
      AppPalette.black; // with opacity usually

  // Text
  static const Color textPrimary = AppPalette.black;
  static const Color textSecondary = AppPalette.grey;
  static const Color textInverse = AppPalette.white;

  // Navigation
  static const Color navBackground = AppPalette.black;
  static const Color navSelectedIcon = AppPalette.white;
  static const Color navUnselectedIcon = AppPalette.white; // with opacity

  // Borders & Shadows
  static const Color border = AppPalette.black;
  static const Color shadow = AppPalette.black;

  // Status & Accents
  static const Color primaryAccent = AppPalette.purple;
  static const Color success = AppPalette.green;
  static const Color error = AppPalette.red;

  // Inputs
  static const Color inputBackground = AppPalette.white;
  static const Color inputBorder = AppPalette.black;

  // Misc
  static const Color transparent = AppPalette.transparent;
  static const Color white = AppPalette.white; // Kept for utility if needed
  static const Color black = AppPalette.black; // Kept for utility if needed

  static List<Color> get pastels => AppPalette.pastels;

  // Aliases for backward compatibility
  static const Color textMain = textPrimary;
  static const Color accent = primaryAccent;
  static const Color dashboardBackground = black;
  static const Color neoGreen = AppPalette.neoGreen;
}

class AppTextStyles {
  static final TextStyle display = GoogleFonts.archivoBlack(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -1.0,
  );

  static final TextStyle title = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static final TextStyle body = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static final TextStyle bodyBold = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
}

class DoSpireTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryAccent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryAccent,
        surface: AppColors.cardSurface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),

      // Typography
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display,
        titleLarge: AppTextStyles.title,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.body,
        labelLarge: AppTextStyles.bodyBold,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 2),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 2),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: AppColors.textInverse,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.border, width: 2),
        ),
      ),
    );
  }
}
