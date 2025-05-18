// lib/utils/design_system.dart
import 'package:flutter/material.dart';

class AppColors {
  static final primary = Colors.blue[800]!;
  static final primaryLight = Colors.blue[600]!;
  static final primaryDark = Colors.blue[900]!;
  static final secondary = Colors.blue[300]!;

  static final backgroundLight = Colors.grey[50]!;
  static final backgroundDark = Color(0xFF1E1E1E);

  static final cardLight = Colors.white;
  static final cardDark = Color(0xFF2C2C2C);

  static final textPrimaryLight = Colors.grey[900]!;
  static final textSecondaryLight = Colors.grey[700]!;
  static final textPrimaryDark = Colors.white;
  static final textSecondaryDark = Colors.grey[300]!;

  static final shadowColor = Colors.black26;
  static final inputBorderLight = Colors.grey[300]!;
  static final inputBorderDark = Colors.grey[700]!;

  static final success = Colors.green[700]!;
  static final error = Colors.red[700]!;
  static final warning = Colors.orange[700]!;
  static final info = Colors.blue[700]!;
}

class AppStyles {
  // Text styles
  static TextStyle headingStyle(BuildContext context,
      {bool isDarkMode = false}) {
    return TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primary,
      letterSpacing: 0.5,
    );
  }

  static TextStyle subheadingStyle(BuildContext context,
      {bool isDarkMode = false}) {
    return TextStyle(
      fontSize: 16,
      color: isDarkMode
          ? AppColors.textSecondaryDark
          : AppColors.textSecondaryLight,
      letterSpacing: 0.3,
    );
  }

  static TextStyle buttonTextStyle(BuildContext context) {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    );
  }

  // Input decoration
  static InputDecoration inputDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    bool isDarkMode = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDarkMode
              ? AppColors.inputBorderDark
              : AppColors.inputBorderLight,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDarkMode
              ? AppColors.inputBorderDark
              : AppColors.inputBorderLight,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: AppColors.primary,
      ),
      suffixIcon: suffixIcon,
      fillColor: isDarkMode ? AppColors.backgroundDark : Colors.white,
      filled: true,
      labelStyle: TextStyle(
        color: isDarkMode
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
      ),
      hintStyle: TextStyle(
        color: isDarkMode
            ? AppColors.textSecondaryDark.withOpacity(0.6)
            : AppColors.textSecondaryLight.withOpacity(0.6),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }

  // Card decoration
  static BoxDecoration cardDecoration({bool isDarkMode = false}) {
    return BoxDecoration(
      color: isDarkMode ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowColor,
          offset: Offset(0, 10),
          blurRadius: 20,
          spreadRadius: 0,
        ),
      ],
    );
  }

  // Button style
  static ButtonStyle primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      shadowColor: AppColors.shadowColor,
      padding: EdgeInsets.symmetric(horizontal: 20),
    );
  }
}
