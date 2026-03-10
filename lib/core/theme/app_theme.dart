// lib/core/theme/app_theme.dart
// Theme Thanh Taxi Xanh SM - Light/Dark mode theo system
// Primary: #00C853 (xanh Xanh SM), tối ưu cho Android giá rẻ

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryGreen = Color(AppColors.primaryGreen);
  static const Color accentYellow = Color(AppColors.accentYellow);
  static const Color negativeRed = Color(AppColors.negativeRed);

  // === LIGHT THEME ===
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
        primary: primaryGreen,
        secondary: accentYellow,
        error: negativeRed,
        surface: const Color(AppColors.cardLight),
        onSurface: const Color(0xFF1A1A1A),
      ),
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardTheme(
        color: const Color(AppColors.cardLight),
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryGreen,
        unselectedItemColor: Color(0xFF9E9E9E),
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: CircleBorder(),
        extendedSizeConstraints: BoxConstraints.tightFor(height: 56),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52), // >= 48dp
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: primaryGreen, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: negativeRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(fontSize: 16),
        hintStyle: TextStyle(fontSize: 16, color: Colors.grey[400]),
      ),
      chipTheme: ChipThemeData(
        selectedColor: primaryGreen,
        checkmarkColor: Colors.white,
        labelStyle: const TextStyle(fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEEEEEE),
        thickness: 1,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF323232),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  // === DARK THEME ===
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.dark,
        primary: primaryGreen,
        secondary: accentYellow,
        error: negativeRed,
        surface: const Color(AppColors.cardDark),
        onSurface: const Color(0xFFF5F5F5),
      ),
      textTheme: _buildTextTheme(Brightness.dark),
      scaffoldBackgroundColor: const Color(AppColors.backgroundDark),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(AppColors.cardDark),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardTheme(
        color: const Color(AppColors.cardDark),
        elevation: 2,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryGreen,
        unselectedItemColor: Color(0xFF9E9E9E),
        backgroundColor: Color(AppColors.cardDark),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: CircleBorder(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(AppColors.surfaceDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(fontSize: 16, color: Colors.white70),
        hintStyle: const TextStyle(fontSize: 16, color: Colors.white30),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF3A3A3A),
        thickness: 1,
        space: 0,
      ),
    );
  }

  // === TEXT THEME ===
  static TextTheme _buildTextTheme(Brightness brightness) {
    final baseColor = brightness == Brightness.light
        ? const Color(0xFF1A1A1A)
        : Colors.white;

    return GoogleFonts.robotoTextTheme().copyWith(
      displayLarge: GoogleFonts.roboto(
        fontSize: 32, fontWeight: FontWeight.bold, color: baseColor,
      ),
      displayMedium: GoogleFonts.roboto(
        fontSize: 28, fontWeight: FontWeight.bold, color: baseColor,
      ),
      headlineLarge: GoogleFonts.roboto(
        fontSize: 24, fontWeight: FontWeight.w700, color: baseColor,
      ),
      headlineMedium: GoogleFonts.roboto(
        fontSize: 20, fontWeight: FontWeight.w600, color: baseColor,
      ),
      headlineSmall: GoogleFonts.roboto(
        fontSize: 18, fontWeight: FontWeight.w600, color: baseColor,
      ),
      titleLarge: GoogleFonts.roboto(
        fontSize: 18, fontWeight: FontWeight.w600, color: baseColor,
      ),
      titleMedium: GoogleFonts.roboto(
        fontSize: 16, fontWeight: FontWeight.w500, color: baseColor,
      ),
      titleSmall: GoogleFonts.roboto(
        fontSize: 14, fontWeight: FontWeight.w500, color: baseColor,
      ),
      bodyLarge: GoogleFonts.roboto(
        fontSize: 16, fontWeight: FontWeight.normal, color: baseColor,
      ),
      bodyMedium: GoogleFonts.roboto(
        fontSize: 14, fontWeight: FontWeight.normal, color: baseColor,
      ),
      bodySmall: GoogleFonts.roboto(
        fontSize: 12, fontWeight: FontWeight.normal,
        color: baseColor.withOpacity(0.7),
      ),
      labelLarge: GoogleFonts.roboto(
        fontSize: 16, fontWeight: FontWeight.w600, color: baseColor,
      ),
    );
  }
}
