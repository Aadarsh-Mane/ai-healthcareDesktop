import 'package:flutter/material.dart';

class AppTheme {
  // Primary color (Background)
  static const Color primaryColor = Color(0xffE3F2FD); // Light blue

  // Accent colors
  static const Color secondaryColor = Color(0xff90CAF9); // Slightly darker blue
  static const Color accentColor =
      Color(0xff42A5F5); // Stronger blue for highlights

  // Neutral colors
  static const Color textColor = Color(0xff212121); // Dark grey for text
  static const Color lightTextColor =
      Color(0xff757575); // Lighter grey for secondary text
  static const Color cardColor = Colors.white; // White for cards
  static const Color borderColor = Color(0xffBDBDBD); // Grey for borders

  // Error color
  static const Color errorColor = Color(0xffD32F2F); // Red for error states

  // Success color
  static const Color successColor =
      Color(0xff4CAF50); // Green for success messages

  // Warning color
  static const Color warningColor = Color(0xffFFC107); // Amber for warnings

  // Icon colors
  static const Color iconColor = Color(0xff616161); // Dark grey for icons

  // Divider color
  static const Color dividerColor =
      Color(0xffE0E0E0); // Light grey for dividers

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
