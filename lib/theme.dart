import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Palette Verdure & Or — Elegant Agronomy
const kPrimary       = Color(0xFF0B5C3A);
const kSecondary     = Color(0xFF27916D);
const kGold          = Color(0xFFC8890A);
const kGoldLight     = Color(0xFFF5C842);
const kBg            = Color(0xFFF4F1E8);
const kSurface       = Color(0xFFEFF7F2);
const kCardBg        = Color(0xFFFBFDF9);
const kTextPrimary   = Color(0xFF1A2C1E);
const kTextSecondary = Color(0xFF5B6E5A);
const kErrorColor    = Color(0xFFB84C2A);
const kBorderColor   = Color(0xFFD0E8D8);

TextStyle get kDisplayStyle => GoogleFonts.playfairDisplay(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: kTextPrimary,
    );

TextStyle get kSectionTitle => GoogleFonts.playfairDisplay(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: kPrimary,
    );

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: kBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimary,
      primary: kPrimary,
      secondary: kGold,
      surface: kCardBg,
      error: kErrorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: kTextPrimary,
    ),
    textTheme: GoogleFonts.nunitoTextTheme(),
    primaryTextTheme: GoogleFonts.nunitoTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: kCardBg,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kBorderColor, width: 0.8),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kGold,
      foregroundColor: Colors.white,
      elevation: 3,
    ),
    dividerTheme: const DividerThemeData(
      color: kBorderColor,
      thickness: 0.8,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 1.5),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: kCardBg,
      selectedItemColor: kPrimary,
      unselectedItemColor: kTextSecondary,
      elevation: 0,
    ),
  );
}
