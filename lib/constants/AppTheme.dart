import 'package:flutter/material.dart';

class AppTheme {
  // Doctor Color Palette - "heartworthy"
  static const Color primaryColor = Color(0xffffffff); // White background
  static const Color lightGrayColor = Color(0xffdddddd); // Light gray
  static const Color darkGrayColor = Color(0xff49535a); // Dark blue-gray
  static const Color darkColor = Color(0xff222222); // Near black
  static const Color blueAccentColor = Color(0xff2a7fba); // Medical blue

  // Themed color assignments
  static const Color secondaryColor =
      lightGrayColor; // Light gray for secondary elements
  static const Color accentColor =
      blueAccentColor; // Medical blue for highlights
  static const Color textColor = darkColor; // Near black for primary text
  static const Color lightTextColor =
      darkGrayColor; // Dark blue-gray for secondary text
  static const Color cardColor = primaryColor; // White for cards
  static const Color borderColor = lightGrayColor; // Light gray for borders

  // Status colors (keeping original healthcare-appropriate colors)
  static const Color errorColor = Color(0xffD32F2F); // Red for error states
  static const Color successColor =
      Color(0xff4CAF50); // Green for success messages
  static const Color warningColor = Color(0xffFFC107); // Amber for warnings

  // Icon colors
  static const Color iconColor = darkGrayColor; // Dark blue-gray for icons

  // Divider color
  static const Color dividerColor = lightGrayColor; // Light gray for dividers

  // Button themes
  static final ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: accentColor,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  static final ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: accentColor,
    side: BorderSide(color: accentColor),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  static final ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: accentColor,
  );

  // Text themes
  static final TextTheme textTheme = TextTheme(
    displayLarge:
        TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
    titleMedium:
        TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
    bodyMedium: TextStyle(fontSize: 16, color: textColor),
    bodySmall: TextStyle(fontSize: 14, color: lightTextColor),
    labelLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w500, color: accentColor),
  );

  // Main theme
  static final ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: primaryColor,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onError: Colors.white,
    ),
    textTheme: textTheme,
    elevatedButtonTheme: ElevatedButtonThemeData(style: elevatedButtonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButtonStyle),
    textButtonTheme: TextButtonThemeData(style: textButtonStyle),
    appBarTheme: AppBarTheme(
      backgroundColor: accentColor,
      titleTextStyle:
          TextStyle(fontFamily: 'Poppins', fontSize: 20, color: Colors.white),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardColor: cardColor,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    dividerColor: dividerColor,
    iconTheme: IconThemeData(color: iconColor),
  );
}
