import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // ── Base Scale (4px grid) ──────────────────────────────────────────────────
  static const double px   = 1;
  static const double s2   = 2;
  static const double s4   = 4;
  static const double s6   = 6;
  static const double s8   = 8;
  static const double s10  = 10;
  static const double s12  = 12;
  static const double s14  = 14;
  static const double s16  = 16;
  static const double s20  = 20;
  static const double s24  = 24;
  static const double s28  = 28;
  static const double s32  = 32;
  static const double s36  = 36;
  static const double s40  = 40;
  static const double s48  = 48;
  static const double s56  = 56;
  static const double s64  = 64;
  static const double s80  = 80;
  static const double s96  = 96;
  static const double s128 = 128;

  // ── Semantic Aliases ───────────────────────────────────────────────────────
  static const double pagePadding     = s24;
  static const double sectionGap      = s32;
  static const double cardPadding     = s20;
  static const double cardGap         = s16;
  static const double inputPaddingV   = s10;
  static const double inputPaddingH   = s14;
  static const double buttonPaddingV  = s10;
  static const double buttonPaddingH  = s20;
  static const double sidebarWidth    = 240;
  static const double compactSidebarWidth = 64;
  static const double topBarHeight    = 56;
  static const double tableRowHeight  = 48;
  static const double dialogMaxWidth  = 560;
  static const double formFieldGap    = s16;
  static const double iconSm         = 16;
  static const double iconMd         = 20;
  static const double iconLg         = 24;
  static const double iconXl         = 32;

  // ── EdgeInsets helpers ─────────────────────────────────────────────────────
  static const EdgeInsets pagePaddingAll    = EdgeInsets.all(pagePadding);
  static const EdgeInsets cardPaddingAll    = EdgeInsets.all(cardPadding);
  static const EdgeInsets buttonPaddingAll  = EdgeInsets.symmetric(
    vertical: buttonPaddingV,
    horizontal: buttonPaddingH,
  );
  static const EdgeInsets inputPaddingAll   = EdgeInsets.symmetric(
    vertical: inputPaddingV,
    horizontal: inputPaddingH,
  );
  static const EdgeInsets listTilePadding   = EdgeInsets.symmetric(
    vertical: s12,
    horizontal: s16,
  );

  // ── Responsive breakpoints ─────────────────────────────────────────────────
  static const double breakpointTablet    = 768;
  static const double breakpointDesktopS  = 1024;
  static const double breakpointDesktopM  = 1280;
  static const double breakpointDesktopL  = 1440;
  static const double breakpointDesktopXL = 1920;

  static bool isTablet(BuildContext ctx)    => MediaQuery.of(ctx).size.width < breakpointDesktopS;
  static bool isDesktopS(BuildContext ctx)  => MediaQuery.of(ctx).size.width >= breakpointDesktopS && MediaQuery.of(ctx).size.width < breakpointDesktopM;
  static bool isDesktopM(BuildContext ctx)  => MediaQuery.of(ctx).size.width >= breakpointDesktopM && MediaQuery.of(ctx).size.width < breakpointDesktopL;
  static bool isDesktopL(BuildContext ctx)  => MediaQuery.of(ctx).size.width >= breakpointDesktopL;

  static double responsivePagePadding(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.width;
    if (w < breakpointDesktopS) return s16;
    if (w < breakpointDesktopM) return s24;
    if (w < breakpointDesktopL) return s32;
    return s40;
  }
}
