import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFF2383E2);
  static const Color primaryLight   = Color(0xFFEFF7FF); // section bg
  static const Color primaryDark    = Color(0xFF1565C0);
  static const Color primarySurface = Color(0xFFD6EAFF);

  // ── Backgrounds ────────────────────────────────────────────────────────────
  static const Color background     = Color(0xFFFFFFFF); // main bg
  static const Color sectionBg      = Color(0xFFEFF7FF); // section / sidebar bg
  static const Color pageBg         = Color(0xFFF7FAFF); // subtle page tint (keep)
  static const Color surface        = Color(0xFFFFFFFF); // card surface
  static const Color surfaceHover   = Color(0xFFF0F6FF);

  // ── Border & Dividers ──────────────────────────────────────────────────────
  static const Color border         = Color(0xFFE6EEF8);
  static const Color divider        = Color(0xFFE6EEF8);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFF1E293B);
  static const Color textSecondary  = Color(0xFF64748B);
  static const Color textDisabled   = Color(0xFFB0BEC5);
  static const Color textOnPrimary  = Color(0xFFFFFFFF);
  static const Color textInverse    = Color(0xFFFFFFFF);

  // ── Status ─────────────────────────────────────────────────────────────────
  static const Color success        = Color(0xFF22C55E);
  static const Color successLight   = Color(0xFFDCFCE7);
  static const Color danger         = Color(0xFFEF4444);
  static const Color dangerLight    = Color(0xFFFEE2E2);
  static const Color warning        = Color(0xFFF59E0B);
  static const Color warningLight   = Color(0xFFFEF3C7);
  static const Color info           = Color(0xFF60A5FA);
  static const Color infoLight      = Color(0xFFDBEAFE);

  // ── Neutral Greys ──────────────────────────────────────────────────────────
  static const Color grey50         = Color(0xFFF8FAFC);
  static const Color grey100        = Color(0xFFF1F5F9);
  static const Color grey200        = Color(0xFFE2E8F0);
  static const Color grey300        = Color(0xFFCBD5E1);
  static const Color grey400        = Color(0xFF94A3B8);
  static const Color grey500        = Color(0xFF64748B);
  static const Color grey600        = Color(0xFF475569);
  static const Color grey700        = Color(0xFF334155);
  static const Color grey800        = Color(0xFF1E293B);
  static const Color grey900        = Color(0xFF0F172A);

  // ── Overlay ────────────────────────────────────────────────────────────────
  static const Color overlay        = Color(0x4D000000);
  static const Color overlayLight   = Color(0x1A2383E2);
}
