import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme configuration for Kenya Pool Billiards app
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Color constants based on design
  static const Color primaryColor = Color(0xFF103621); // Dark green
  static const Color accentColor = Color(0xFFFFC107); // Yellow/Gold
  static const Color secondary1 = Color(0xFF16543A); // Medium green
  static const Color secondary2 = Color(0xFF0D2819); // Very dark green

  // Additional colors from the design
  static const Color backgroundColor = Color(0xFF0A0E21); // Dark background
  static const Color cardColor = Color(0xFF1D1E33); // Card background
  static const Color textDark = Color(0xFF333333); // Dark text
  static const Color textLight = Colors.white; // Light text
  static const Color formBackground = Color(0xFF1D1E33); // Form background
  static const Color errorColor = Color(0xFFE53935); // Error red
  static const Color successColor = Color(0xFF4CAF50); // Success green
  static const Color warningColor = Color(0xFFFFA726); // Warning orange

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF103621),
      Color(0xFF16543A),
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFC107),
      Color(0xFFFFB300),
    ],
  );

  // Text styles using Google Fonts
  static TextStyle get headingStyle => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textLight,
      );

  static TextStyle get subheadingStyle => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: textLight,
      );

  static TextStyle get bodyStyle => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textLight,
      );

  static TextStyle get buttonTextStyle => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textDark,
      );

  // Light theme
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      surface: cardColor,
      error: errorColor,
      onPrimary: textLight,
      onSecondary: textDark,
      onSurface: textLight,
      onError: textLight,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textLight,
      ),
      iconTheme: const IconThemeData(color: textLight),
    ),
    textTheme: TextTheme(
      headlineLarge: headingStyle,
      headlineMedium: subheadingStyle,
      bodyLarge: bodyStyle,
      bodyMedium: GoogleFonts.poppins(fontSize: 14, color: textLight),
      labelLarge: buttonTextStyle,
    ),
    cardTheme: CardTheme(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: accentColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textTheme: ButtonTextTheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: textDark,
        textStyle: buttonTextStyle,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        minimumSize: const Size(double.infinity, 56),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentColor,
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: formBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
      labelStyle: GoogleFonts.poppins(color: Colors.grey[300]),
      prefixIconColor: Colors.grey[400],
      suffixIconColor: Colors.grey[400],
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: cardColor,
      contentTextStyle: GoogleFonts.poppins(color: textLight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textLight,
      ),
      contentTextStyle: GoogleFonts.poppins(
        fontSize: 16,
        color: textLight,
      ),
    ),
  );

  // Theme getter
  static ThemeData get theme => lightTheme;
}
