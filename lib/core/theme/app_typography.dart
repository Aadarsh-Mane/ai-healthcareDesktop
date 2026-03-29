import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static const String _fontFamily = 'Inter';

  // ── Display ───────────────────────────────────────────────────────────────
  static const TextStyle display2xl = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.96,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayXl = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.8,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.64,
    color: AppColors.textPrimary,
  );

  // ── Heading ───────────────────────────────────────────────────────────────
  static const TextStyle headingXl = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.48,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.36,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingSm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.16,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingXs = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.14,
    color: AppColors.textPrimary,
  );

  // ── Body ──────────────────────────────────────────────────────────────────
  static const TextStyle bodyLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.57,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.54,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodyXs = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  // ── Label ─────────────────────────────────────────────────────────────────
  static const TextStyle labelLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.38,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
    color: AppColors.textSecondary,
    letterSpacing: 0.12,
  );

  static const TextStyle labelXs = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.27,
    color: AppColors.textSecondary,
    letterSpacing: 0.22,
  );

  // ── Caption / Overline ────────────────────────────────────────────────────
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.27,
    letterSpacing: 0.88,
    color: AppColors.textSecondary,
  );

  // ── Code ─────────────────────────────────────────────────────────────────
  static const TextStyle code = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.54,
    color: AppColors.textPrimary,
  );

  // ── Flutter TextTheme mapping ─────────────────────────────────────────────
  static TextTheme get textTheme => const TextTheme(
    displayLarge:   display2xl,
    displayMedium:  displayXl,
    displaySmall:   displayLg,
    headlineLarge:  headingXl,
    headlineMedium: headingLg,
    headlineSmall:  headingMd,
    titleLarge:     headingSm,
    titleMedium:    labelLg,
    titleSmall:     labelMd,
    bodyLarge:      bodyLg,
    bodyMedium:     bodyMd,
    bodySmall:      bodySm,
    labelLarge:     labelLg,
    labelMedium:    labelMd,
    labelSmall:     labelSm,
  );
}
