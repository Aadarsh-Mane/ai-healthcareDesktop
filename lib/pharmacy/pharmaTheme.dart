import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// PharmaTheme provides consistent theme data and colors across the application
/// It centralizes all theming logic for better maintainability
class PharmaTheme {
  // Primary colors
  static const Color primary = Color(0xFF2D5AB9);
  static const Color primaryLight = Color(0xFF5984E8);
  static const Color primaryDark = Color(0xFF193C89);

  // Accent colors
  static const Color accent = Color(0xFF4ECDC4);
  static const Color accentLight = Color(0xFF7EEAE3);
  static const Color accentDark = Color(0xFF2A9D95);

  // Background colors
  static const Color background = Color(0xFFF7F9FB);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;

  // Text colors
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF7A869A);
  static const Color textLight = Colors.white;

  // Border color
  static const Color border = Color(0xFFEAECF0);

  // Status colors
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA000);
  static const Color info = Color(0xFF2196F3);

  // Opacity values for consistent transparent elements
  static const double hoverOpacity = 0.05;
  static const double selectedOpacity = 0.1;
  static const double disabledOpacity = 0.3;
  static const double overlayOpacity = 0.5;

  // Spacing constants for consistent padding/margin
  static const double spacingXxs = 4.0;
  static const double spacingXs = 8.0;
  static const double spacingS = 12.0;
  static const double spacingM = 16.0;
  static const double spacingL = 20.0;
  static const double spacingXl = 24.0;
  static const double spacingXxl = 32.0;

  // Border radius constants
  static const double radiusXs = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusCircular = 100.0;

  // Transition durations
  static const Duration transitionFast = Duration(milliseconds: 150);
  static const Duration transitionMedium = Duration(milliseconds: 300);
  static const Duration transitionSlow = Duration(milliseconds: 500);

  // Shadow values
  static List<BoxShadow> get shadowSmall => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          offset: const Offset(0, 1),
          blurRadius: 2,
        ),
      ];

  static List<BoxShadow> get shadowMedium => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          offset: const Offset(0, 2),
          blurRadius: 5,
        ),
      ];

  static List<BoxShadow> get shadowLarge => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          offset: const Offset(0, 4),
          blurRadius: 10,
        ),
      ];

  // Common gradients
  static LinearGradient get primaryGradient => LinearGradient(
        colors: [primary, primaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get accentGradient => LinearGradient(
        colors: [accent, accentLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get primaryAccentGradient => LinearGradient(
        colors: [primary, accent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // Get a Flutter ThemeData object initialized with our colors
  static ThemeData get lightTheme {
    final baseTheme = ThemeData.light();

    return baseTheme.copyWith(
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: primary,
        secondary: accent,
        background: background,
        surface: surface,
        error: error,
        onPrimary: textLight,
        onSecondary: textLight,
        onBackground: textPrimary,
        onSurface: textPrimary,
        onError: textLight,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: textLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: textLight),
        titleTextStyle: baseTheme.textTheme.titleLarge?.copyWith(
          color: textLight,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),

      // Card
      cardTheme: CardTheme(
        color: card,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        margin: EdgeInsets.zero,
      ),

      // Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: textLight,
          backgroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            vertical: spacingS,
            horizontal: spacingM,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: spacingS,
            horizontal: spacingM,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: spacingXs,
            horizontal: spacingS,
          ),
        ),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        fillColor: surface,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: spacingS,
          horizontal: spacingM,
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusS),
        ),
        contentTextStyle: baseTheme.textTheme.titleMedium?.copyWith(
          color: textLight,
        ),
      ),
    );
  }

  // Responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Helper methods for responsive design
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tabletBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  // Responsive padding helper
  static EdgeInsets responsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(spacingM);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(spacingL);
    } else {
      return const EdgeInsets.all(spacingXl);
    }
  }

  // Common text styles
  static TextStyle get headingLarge => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      );

  static TextStyle get headingMedium => const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      );

  static TextStyle get headingSmall => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      );

  static TextStyle get bodyLarge => const TextStyle(
        fontSize: 16,
        color: textPrimary,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontSize: 14,
        color: textPrimary,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontSize: 13,
        color: textSecondary,
      );

  static TextStyle get caption => const TextStyle(
        fontSize: 12,
        color: textSecondary,
      );
}

// Riverpod provider for theme mode
final themeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.light; // Default to light mode
});

// Extension methods for easier access to theme
extension ThemeExtension on BuildContext {
  // Access theme colors and styles directly from context
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  // Check responsive breakpoints directly from context
  bool get isMobile => PharmaTheme.isMobile(this);
  bool get isTablet => PharmaTheme.isTablet(this);
  bool get isDesktop => PharmaTheme.isDesktop(this);

  // Get responsive padding
  EdgeInsets get responsivePadding => PharmaTheme.responsivePadding(this);
}
