import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_shadows.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HmsColors — semantic color extension
// ─────────────────────────────────────────────────────────────────────────────
@immutable
class HmsColors extends ThemeExtension<HmsColors> {
  const HmsColors({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.primarySurface,
    required this.background,
    required this.sectionBg,
    required this.pageBg,
    required this.surface,
    required this.surfaceHover,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.textOnPrimary,
    required this.success,
    required this.successLight,
    required this.danger,
    required this.dangerLight,
    required this.warning,
    required this.warningLight,
    required this.info,
    required this.infoLight,
    required this.overlay,
  });

  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color primarySurface;
  final Color background;
  final Color sectionBg;
  final Color pageBg;
  final Color surface;
  final Color surfaceHover;
  final Color border;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color textOnPrimary;
  final Color success;
  final Color successLight;
  final Color danger;
  final Color dangerLight;
  final Color warning;
  final Color warningLight;
  final Color info;
  final Color infoLight;
  final Color overlay;

  static const HmsColors light = HmsColors(
    primary:        AppColors.primary,
    primaryLight:   AppColors.primaryLight,
    primaryDark:    AppColors.primaryDark,
    primarySurface: AppColors.primarySurface,
    background:     AppColors.background,
    sectionBg:      AppColors.sectionBg,
    pageBg:         AppColors.pageBg,
    surface:        AppColors.surface,
    surfaceHover:   AppColors.surfaceHover,
    border:         AppColors.border,
    divider:        AppColors.divider,
    textPrimary:    AppColors.textPrimary,
    textSecondary:  AppColors.textSecondary,
    textDisabled:   AppColors.textDisabled,
    textOnPrimary:  AppColors.textOnPrimary,
    success:        AppColors.success,
    successLight:   AppColors.successLight,
    danger:         AppColors.danger,
    dangerLight:    AppColors.dangerLight,
    warning:        AppColors.warning,
    warningLight:   AppColors.warningLight,
    info:           AppColors.info,
    infoLight:      AppColors.infoLight,
    overlay:        AppColors.overlay,
  );

  @override
  HmsColors copyWith({
    Color? primary, Color? primaryLight, Color? primaryDark, Color? primarySurface,
    Color? background, Color? sectionBg, Color? pageBg, Color? surface,
    Color? surfaceHover, Color? border, Color? divider, Color? textPrimary,
    Color? textSecondary, Color? textDisabled, Color? textOnPrimary,
    Color? success, Color? successLight, Color? danger, Color? dangerLight,
    Color? warning, Color? warningLight, Color? info, Color? infoLight,
    Color? overlay,
  }) => HmsColors(
    primary:        primary        ?? this.primary,
    primaryLight:   primaryLight   ?? this.primaryLight,
    primaryDark:    primaryDark    ?? this.primaryDark,
    primarySurface: primarySurface ?? this.primarySurface,
    background:     background     ?? this.background,
    sectionBg:      sectionBg      ?? this.sectionBg,
    pageBg:         pageBg         ?? this.pageBg,
    surface:        surface        ?? this.surface,
    surfaceHover:   surfaceHover   ?? this.surfaceHover,
    border:         border         ?? this.border,
    divider:        divider        ?? this.divider,
    textPrimary:    textPrimary    ?? this.textPrimary,
    textSecondary:  textSecondary  ?? this.textSecondary,
    textDisabled:   textDisabled   ?? this.textDisabled,
    textOnPrimary:  textOnPrimary  ?? this.textOnPrimary,
    success:        success        ?? this.success,
    successLight:   successLight   ?? this.successLight,
    danger:         danger         ?? this.danger,
    dangerLight:    dangerLight    ?? this.dangerLight,
    warning:        warning        ?? this.warning,
    warningLight:   warningLight   ?? this.warningLight,
    info:           info           ?? this.info,
    infoLight:      infoLight      ?? this.infoLight,
    overlay:        overlay        ?? this.overlay,
  );

  @override
  HmsColors lerp(HmsColors? other, double t) {
    if (other is! HmsColors) return this;
    return HmsColors(
      primary:        Color.lerp(primary,        other.primary,        t)!,
      primaryLight:   Color.lerp(primaryLight,   other.primaryLight,   t)!,
      primaryDark:    Color.lerp(primaryDark,    other.primaryDark,    t)!,
      primarySurface: Color.lerp(primarySurface, other.primarySurface, t)!,
      background:     Color.lerp(background,     other.background,     t)!,
      sectionBg:      Color.lerp(sectionBg,      other.sectionBg,      t)!,
      pageBg:         Color.lerp(pageBg,         other.pageBg,         t)!,
      surface:        Color.lerp(surface,         other.surface,        t)!,
      surfaceHover:   Color.lerp(surfaceHover,   other.surfaceHover,   t)!,
      border:         Color.lerp(border,         other.border,         t)!,
      divider:        Color.lerp(divider,         other.divider,        t)!,
      textPrimary:    Color.lerp(textPrimary,    other.textPrimary,    t)!,
      textSecondary:  Color.lerp(textSecondary,  other.textSecondary,  t)!,
      textDisabled:   Color.lerp(textDisabled,   other.textDisabled,   t)!,
      textOnPrimary:  Color.lerp(textOnPrimary,  other.textOnPrimary,  t)!,
      success:        Color.lerp(success,        other.success,        t)!,
      successLight:   Color.lerp(successLight,   other.successLight,   t)!,
      danger:         Color.lerp(danger,         other.danger,         t)!,
      dangerLight:    Color.lerp(dangerLight,    other.dangerLight,    t)!,
      warning:        Color.lerp(warning,        other.warning,        t)!,
      warningLight:   Color.lerp(warningLight,   other.warningLight,   t)!,
      info:           Color.lerp(info,           other.info,           t)!,
      infoLight:      Color.lerp(infoLight,      other.infoLight,      t)!,
      overlay:        Color.lerp(overlay,        other.overlay,        t)!,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Context helpers — Theme.of(context).extension<HmsColors>()!
// ─────────────────────────────────────────────────────────────────────────────
extension HmsThemeContext on BuildContext {
  HmsColors get hmsColors => Theme.of(this).extension<HmsColors>()!;
  ThemeData  get theme     => Theme.of(this);
}
