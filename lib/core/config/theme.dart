import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme configuration for Kenya Pool Billiards app
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Color constants based on design system
  static const Color primaryColor = Color(0xFF103621); // Dark green
  static const Color accentColor = Color(0xFFFFC107); // Yellow/Gold
  static const Color secondary1 = Color(0xFF16543A); // Medium green
  static const Color secondary2 = Color(0xFF0D2819); // Very dark green

  // Additional colors from the design system
  static const Color backgroundColor = Color(
      0xFF002711); // App background (global dark theme) - color-bg-primary
  static const Color cardColor =
      Color(0xFF16543A); // Card background (medium green to match theme)
  static const Color textDark = Color(0xFF333333); // Dark text
  static const Color textLight = Colors.white; // Light text
  static const Color formBackground =
      Color(0xFF16543A); // Form background (medium green to match theme)
  static const Color errorColor = Color(0xFFE53935); // Error red
  static const Color successColor = Color(0xFF4CAF50); // Success green
  static const Color warningColor = Color(0xFFFFA726); // Warning orange
  static const Color infoColor = Color(0xFF2196F3); // Info blue
  static const Color secondaryColor =
      Color(0xFFFFC107); // Same as accentColor for consistency

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

  // Typography System - Raleway Font Family
  // H1 - Section Headers (24px • Bold • Raleway)
  static TextStyle get h1Style => GoogleFonts.raleway(
        fontSize: 24,
        fontWeight: FontWeight.w700, // Bold
        color: textLight,
      );

  // H2 - Card Titles (20px • SemiBold • Raleway)
  static TextStyle get h2Style => GoogleFonts.raleway(
        fontSize: 20,
        fontWeight: FontWeight.w600, // SemiBold
        color: textLight,
      );

  // H3 - Categories (18px • Medium • Raleway)
  static TextStyle get h3Style => GoogleFonts.raleway(
        fontSize: 18,
        fontWeight: FontWeight.w500, // Medium
        color: textLight,
      );

  // Body Large - General body text (16px • Regular • Raleway)
  static TextStyle get bodyLargeStyle => GoogleFonts.raleway(
        fontSize: 16,
        fontWeight: FontWeight.w400, // Regular
        color: textLight,
      );

  // Body Small - Meta information (14px • Regular • Raleway)
  static TextStyle get bodySmallStyle => GoogleFonts.raleway(
        fontSize: 14,
        fontWeight: FontWeight.w400, // Regular
        color: textLight,
      );

  // Caption - Tags, badges (12px • Medium • Raleway)
  static TextStyle get captionStyle => GoogleFonts.raleway(
        fontSize: 12,
        fontWeight: FontWeight.w500, // Medium
        color: textLight,
      );

  // Overline - Timestamps, brackets (10px • Regular • Raleway)
  static TextStyle get overlineStyle => GoogleFonts.raleway(
        fontSize: 10,
        fontWeight: FontWeight.w400, // Regular
        color: textLight,
      );

  // Legacy styles for backward compatibility
  static TextStyle get headingStyle => h1Style;
  static TextStyle get subheadingStyle => h3Style;
  static TextStyle get bodyStyle => bodyLargeStyle;
  static TextStyle get buttonTextStyle => GoogleFonts.raleway(
        fontSize: 16,
        fontWeight: FontWeight.w600, // SemiBold for buttons
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
      titleTextStyle: h2Style,
      iconTheme: const IconThemeData(color: textLight),
    ),
    textTheme: TextTheme(
      headlineLarge: h1Style,
      headlineMedium: h2Style,
      headlineSmall: h3Style,
      bodyLarge: bodyLargeStyle,
      bodyMedium: bodySmallStyle,
      bodySmall: captionStyle,
      labelLarge: buttonTextStyle,
      labelMedium: captionStyle,
      labelSmall: overlineStyle,
    ),
    cardTheme: CardThemeData(
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
        textStyle: GoogleFonts.raleway(fontWeight: FontWeight.w600),
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
      hintStyle: GoogleFonts.raleway(color: Colors.grey[400]),
      labelStyle: GoogleFonts.raleway(color: Colors.grey[300]),
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
      contentTextStyle: GoogleFonts.raleway(color: textLight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: h2Style,
      contentTextStyle: bodyLargeStyle,
    ),
  );

  // Theme getter
  static ThemeData get theme => lightTheme;
}
