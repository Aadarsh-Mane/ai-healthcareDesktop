import 'package:flutter/material.dart';

class NurseTheme {
  // Primary color palette - calming blue as the base with accent colors
  static const Color primaryColor = Color(0xFF3F8CFF);
  static const Color primaryLightColor = Color(0xFF70A9FF);
  static const Color primaryDarkColor = Color(0xFF2563EB);

  // Secondary color palette - teal-based for a fresh modern look
  static const Color secondaryColor = Color(0xFF0EA5E9);
  static const Color secondaryLightColor = Color(0xFF7DD3FC);
  static const Color secondaryDarkColor = Color(0xFF0369A1);

  // Accent colors - to highlight important information
  static const Color accentColor = Color(0xFFFF6384);
  static const Color successColor = Color(0xFF22C55E);
  static const Color warningColor = Color(0xFFFACC15);
  static const Color errorColor = Color(0xFFEF4444);

  // Background colors - soft and easy on the eyes
  static const Color backgroundColor = Color(0xFFF9FAFB);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);

  // Text colors
  static const Color textPrimaryColor = Color(0xFF1F2937);
  static const Color textSecondaryColor = Color(0xFF6B7280);
  static const Color textOnPrimaryColor = Color(0xFFFFFFFF);
  static const Color textOnSecondaryColor = Color(0xFFFFFFFF);

  // Border and divider colors
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color dividerColor = Color(0xFFE5E7EB);

  // Shadow color
  static const Color shadowColor = Color(0x1A000000);

  // Create the theme data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        primary: primaryColor,
        onPrimary: textOnPrimaryColor,
        primaryContainer: primaryLightColor,
        onPrimaryContainer: textOnPrimaryColor,
        secondary: secondaryColor,
        onSecondary: textOnSecondaryColor,
        secondaryContainer: secondaryLightColor,
        onSecondaryContainer: textPrimaryColor,
        tertiary: accentColor,
        onTertiary: textOnPrimaryColor,
        tertiaryContainer: accentColor.withOpacity(0.2),
        onTertiaryContainer: accentColor,
        error: errorColor,
        onError: textOnPrimaryColor,
        errorContainer: errorColor.withOpacity(0.2),
        onErrorContainer: errorColor,
        background: backgroundColor,
        onBackground: textPrimaryColor,
        surface: surfaceColor,
        onSurface: textPrimaryColor,
        surfaceVariant: cardColor,
        onSurfaceVariant: textSecondaryColor,
        outline: borderColor,
        brightness: Brightness.light,
        shadow: shadowColor,
      ),

      // Typography
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontSize: 32, fontWeight: FontWeight.bold, color: textPrimaryColor),
        displayMedium: TextStyle(
            fontSize: 28, fontWeight: FontWeight.bold, color: textPrimaryColor),
        displaySmall: TextStyle(
            fontSize: 24, fontWeight: FontWeight.bold, color: textPrimaryColor),
        headlineLarge: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w600, color: textPrimaryColor),
        headlineMedium: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: textPrimaryColor),
        headlineSmall: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: textPrimaryColor),
        titleLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: textPrimaryColor),
        titleMedium: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w500, color: textPrimaryColor),
        titleSmall: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: textPrimaryColor),
        bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: textPrimaryColor),
        bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: textPrimaryColor),
        bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: textSecondaryColor),
        labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: textPrimaryColor),
        labelMedium: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: textPrimaryColor),
        labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: textSecondaryColor),
      ),

      // Component themes
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: textPrimaryColor),
      ),

      cardTheme: CardTheme(
        color: cardColor,
        elevation: 2,
        shadowColor: shadowColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textOnPrimaryColor,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondaryColor),
        hintStyle: const TextStyle(color: textSecondaryColor),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: primaryLightColor.withOpacity(0.2),
        disabledColor: borderColor,
        selectedColor: primaryColor,
        secondarySelectedColor: secondaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(color: textPrimaryColor),
        secondaryLabelStyle: const TextStyle(color: textOnSecondaryColor),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.grey.shade400;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryLightColor;
          }
          return Colors.grey.shade300;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(textOnPrimaryColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: textSecondaryColor),
      ),

      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return textSecondaryColor;
        }),
      ),

      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: textSecondaryColor,
        indicatorColor: primaryColor,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      ),

      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      dialogTheme: DialogTheme(
        backgroundColor: surfaceColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryColor,
        elevation: 4,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimaryColor,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: textPrimaryColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: const TextStyle(color: Colors.white),
      ),
    );
  }

  // Custom shadows
  static List<BoxShadow> get lightShadow {
    return [
      BoxShadow(
        color: shadowColor.withOpacity(0.08),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static List<BoxShadow> get mediumShadow {
    return [
      BoxShadow(
        color: shadowColor.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> get largeShadow {
    return [
      BoxShadow(
        color: shadowColor.withOpacity(0.12),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ];
  }

  // Custom utilities for special components that might be needed in a nurse panel
  static BoxDecoration patientCardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: lightShadow,
    border: Border.all(color: borderColor, width: 1),
  );

  static BoxDecoration statsCardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: mediumShadow,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryLightColor.withOpacity(0.1),
        Colors.white,
      ],
    ),
  );

  static BoxDecoration alertCardDecoration = BoxDecoration(
    color: errorColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: errorColor.withOpacity(0.5), width: 1),
  );
}
