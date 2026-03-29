import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'theme_extensions.dart';

class AppTheme {
  AppTheme._();

  // ── Primary ColorScheme ────────────────────────────────────────────────────
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness:           Brightness.light,
    primary:              AppColors.primary,
    onPrimary:            AppColors.textOnPrimary,
    primaryContainer:     AppColors.primaryLight,
    onPrimaryContainer:   AppColors.primaryDark,
    secondary:            AppColors.info,
    onSecondary:          AppColors.textOnPrimary,
    secondaryContainer:   AppColors.infoLight,
    onSecondaryContainer: AppColors.primaryDark,
    tertiary:             AppColors.success,
    onTertiary:           AppColors.textOnPrimary,
    tertiaryContainer:    AppColors.successLight,
    onTertiaryContainer:  Color(0xFF14532D),
    error:                AppColors.danger,
    onError:              AppColors.textOnPrimary,
    errorContainer:       AppColors.dangerLight,
    onErrorContainer:     Color(0xFF7F1D1D),
    surface:              AppColors.surface,
    onSurface:            AppColors.textPrimary,
    onSurfaceVariant:     AppColors.textSecondary,
    outline:              AppColors.border,
    outlineVariant:       AppColors.divider,
    shadow:               Color(0x1A2383E2),
    scrim:                AppColors.overlay,
    inverseSurface:       AppColors.grey800,
    onInverseSurface:     AppColors.textOnPrimary,
    inversePrimary:       AppColors.primaryLight,
    surfaceContainerHighest: AppColors.sectionBg,
    surfaceContainerHigh:    AppColors.primaryLight,
    surfaceContainer:        AppColors.surface,
    surfaceContainerLow:     AppColors.background,
    surfaceContainerLowest:  AppColors.background,
  );

  // ── Light ThemeData ────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3:       true,
    colorScheme:        _lightColorScheme,
    fontFamily:         'Inter',
    textTheme:          AppTypography.textTheme,
    scaffoldBackgroundColor: AppColors.background,
    extensions: const [HmsColors.light],

    // ── AppBar ──────────────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      elevation:        0,
      scrolledUnderElevation: 1,
      backgroundColor:  AppColors.background,
      foregroundColor:  AppColors.textPrimary,
      shadowColor:      const Color(0x0D2383E2),
      surfaceTintColor: Colors.transparent,
      titleTextStyle:   AppTypography.headingSm.copyWith(color: AppColors.textPrimary),
      iconTheme:        const IconThemeData(color: AppColors.textSecondary, size: 20),
      toolbarHeight:    AppSpacing.topBarHeight,
    ),

    // ── Card ────────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      elevation:        0,
      color:            AppColors.surface,
      shadowColor:      Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    // ── Elevated Button ─────────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor:   AppColors.primary,
        foregroundColor:   AppColors.textOnPrimary,
        disabledBackgroundColor: AppColors.grey200,
        disabledForegroundColor: AppColors.textDisabled,
        elevation:         0,
        shadowColor:       Colors.transparent,
        padding:           AppSpacing.buttonPaddingAll,
        minimumSize:       const Size(80, 40),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
        textStyle:         AppTypography.labelLg,
      ).copyWith(
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) return 2;
          return 0;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) return Colors.white.withOpacity(0.08);
          if (states.contains(WidgetState.pressed)) return Colors.white.withOpacity(0.16);
          return Colors.transparent;
        }),
      ),
    ),

    // ── Outlined Button ─────────────────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.textDisabled,
        padding: AppSpacing.buttonPaddingAll,
        minimumSize: const Size(80, 40),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
        textStyle: AppTypography.labelLg,
      ).copyWith(
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
            return const BorderSide(color: AppColors.primary);
          }
          return const BorderSide(color: AppColors.border);
        }),
      ),
    ),

    // ── Text Button ─────────────────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        minimumSize: const Size(48, 36),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
        textStyle: AppTypography.labelLg,
      ),
    ),

    // ── Input Decoration ────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled:          true,
      fillColor:       AppColors.background,
      contentPadding:  AppSpacing.inputPaddingAll,
      hintStyle:       AppTypography.bodyMd.copyWith(color: AppColors.textDisabled),
      labelStyle:      AppTypography.labelMd.copyWith(color: AppColors.textSecondary),
      floatingLabelStyle: AppTypography.labelSm.copyWith(color: AppColors.primary),
      errorStyle:      AppTypography.bodyXs.copyWith(color: AppColors.danger),
      border: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.input,
        borderSide: const BorderSide(color: AppColors.grey200),
      ),
    ),

    // ── Chip ────────────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor:    AppColors.sectionBg,
      selectedColor:      AppColors.primarySurface,
      disabledColor:      AppColors.grey100,
      labelStyle:         AppTypography.labelSm.copyWith(color: AppColors.textPrimary),
      secondaryLabelStyle: AppTypography.labelSm.copyWith(color: AppColors.primary),
      padding:            const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.chip,
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 0,
      pressElevation: 0,
    ),

    // ── Dialog ──────────────────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor:  AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation:        0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.dialog),
      titleTextStyle:   AppTypography.headingMd,
      contentTextStyle: AppTypography.bodyMd,
    ),

    // ── Divider ─────────────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color:     AppColors.divider,
      thickness: 1,
      space:     1,
    ),

    // ── ListTile ────────────────────────────────────────────────────────────
    listTileTheme: const ListTileThemeData(
      contentPadding:  EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      minVerticalPadding: 8,
      iconColor:       AppColors.textSecondary,
      textColor:       AppColors.textPrimary,
      selectedColor:   AppColors.primary,
      selectedTileColor: AppColors.primaryLight,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusMd,
      ),
    ),

    // ── NavigationRail ──────────────────────────────────────────────────────
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor:          AppColors.sectionBg,
      elevation:                0,
      selectedIconTheme:        const IconThemeData(color: AppColors.primary, size: 20),
      unselectedIconTheme:      const IconThemeData(color: AppColors.textSecondary, size: 20),
      selectedLabelTextStyle:   AppTypography.labelSm.copyWith(color: AppColors.primary),
      unselectedLabelTextStyle: AppTypography.labelSm.copyWith(color: AppColors.textSecondary),
      indicatorColor:           AppColors.primarySurface,
      indicatorShape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
      useIndicator: true,
    ),

    // ── Drawer ──────────────────────────────────────────────────────────────
    drawerTheme: const DrawerThemeData(
      backgroundColor:  AppColors.sectionBg,
      surfaceTintColor: Colors.transparent,
      elevation:        0,
    ),

    // ── Tooltip ─────────────────────────────────────────────────────────────
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.grey800,
        borderRadius: AppRadius.tooltip,
      ),
      textStyle: AppTypography.labelSm.copyWith(color: AppColors.textOnPrimary),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
    ),

    // ── SnackBar ────────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor:    AppColors.grey800,
      contentTextStyle:   AppTypography.bodyMd.copyWith(color: AppColors.textOnPrimary),
      actionTextColor:    AppColors.primaryLight,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),

    // ── Switch ──────────────────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.textOnPrimary;
        return AppColors.grey400;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return AppColors.grey200;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),

    // ── Checkbox ────────────────────────────────────────────────────────────
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(AppColors.textOnPrimary),
      side: const BorderSide(color: AppColors.border, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXs),
    ),

    // ── Radio ────────────────────────────────────────────────────────────────
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return AppColors.textDisabled;
      }),
    ),

    // ── Progress Indicator ───────────────────────────────────────────────────
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color:                AppColors.primary,
      linearTrackColor:     AppColors.primaryLight,
      circularTrackColor:   AppColors.primaryLight,
    ),

    // ── Scrollbar ───────────────────────────────────────────────────────────
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(AppColors.grey300),
      trackColor: WidgetStateProperty.all(Colors.transparent),
      radius: const Radius.circular(AppRadius.full),
      thickness: WidgetStateProperty.all(4),
      thumbVisibility: WidgetStateProperty.all(false),
    ),

    // ── Tab Bar ─────────────────────────────────────────────────────────────
    tabBarTheme: TabBarThemeData(
      labelColor:         AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      labelStyle:         AppTypography.labelMd.copyWith(color: AppColors.primary),
      unselectedLabelStyle: AppTypography.labelMd.copyWith(color: AppColors.textSecondary),
      indicatorColor:     AppColors.primary,
      indicatorSize:      TabBarIndicatorSize.label,
      dividerColor:       AppColors.divider,
    ),

    // ── PopupMenu ────────────────────────────────────────────────────────────
    popupMenuTheme: PopupMenuThemeData(
      color:            AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation:        0,
      shadowColor:      Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusLg,
        side: const BorderSide(color: AppColors.border),
      ),
      textStyle: AppTypography.bodyMd,
      labelTextStyle: WidgetStateProperty.all(AppTypography.bodyMd),
    ),

    // ── DataTable ────────────────────────────────────────────────────────────
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStateProperty.all(AppColors.sectionBg),
      dataRowColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) return AppColors.surfaceHover;
        return AppColors.surface;
      }),
      headingTextStyle:   AppTypography.labelSm.copyWith(color: AppColors.textSecondary),
      dataTextStyle:      AppTypography.bodyMd,
      dividerThickness:   1,
      headingRowHeight:   AppSpacing.tableRowHeight,
      dataRowMinHeight:   AppSpacing.tableRowHeight,
      dataRowMaxHeight:   AppSpacing.tableRowHeight * 1.5,
      columnSpacing:      AppSpacing.s24,
      horizontalMargin:   AppSpacing.s16,
    ),
  );
}
