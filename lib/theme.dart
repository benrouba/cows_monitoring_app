import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kAccentGreen = Color(0xFF27A660);
const kWheatGold = Color(0xFFFBC02D);
const kTextDark = Color(0xFF212121);
const kTextGray = Color(0xFF424242);
const kBorderLight = Color(0xFFE0E0E0);

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kAccentGreen,
      primary: kAccentGreen,
      secondary: kWheatGold,
      surface: Colors.white,
      background: Colors.white,
      error: const Color(0xFFE57373),
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: kTextDark,
      onBackground: kTextDark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.green,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    // appBarTheme: const AppBarTheme(
    //   backgroundColor: Colors.white,
    //   foregroundColor: kAccentGreen,
    //   elevation: 0,
    //   centerTitle: true,
    //   titleTextStyle: TextStyle(
    //     color: kAccentGreen,
    //     fontWeight: FontWeight.w600,
    //     fontSize: 18,
    //   ),
    //   iconTheme: IconThemeData(color: kAccentGreen),
    // ),
    textTheme: GoogleFonts.poppinsTextTheme(),
    primaryTextTheme: GoogleFonts.poppinsTextTheme(),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kWheatGold,
      foregroundColor: kAccentGreen,
      elevation: 3,
    ),
  );
}
