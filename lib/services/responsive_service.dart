// lib/utils/responsive_helper.dart
import 'package:flutter/material.dart';

class ResponsiveHelper {
  static const double _mobileBreakpoint = 650;
  static const double _tabletBreakpoint = 1100;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < _mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= _mobileBreakpoint &&
      MediaQuery.of(context).size.width < _tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= _tabletBreakpoint;

  // Get adaptive width based on screen size
  static double getAdaptiveWidth(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width < _mobileBreakpoint) {
      return mobile;
    } else if (width < _tabletBreakpoint) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Get adaptive height for card
  static double getAdaptiveCardHeight(BuildContext context) {
    if (isMobile(context)) {
      return MediaQuery.of(context).size.height * 0.85;
    } else if (isTablet(context)) {
      return MediaQuery.of(context).size.height * 0.8;
    } else {
      return MediaQuery.of(context).size.height * 0.85;
    }
  }

  // Get adaptive login card width
  static double getLoginCardWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < _mobileBreakpoint) {
      return width * 0.9; // 90% of screen on mobile
    } else if (width < _tabletBreakpoint) {
      return width * 0.7; // 70% of screen on tablet
    } else {
      return 640; // Fixed width on desktop
    }
  }

  // Get adaptive padding
  static EdgeInsets getAdaptivePadding(BuildContext context) {
    if (isMobile(context)) {
      return EdgeInsets.all(20);
    } else if (isTablet(context)) {
      return EdgeInsets.all(32);
    } else {
      return EdgeInsets.all(40);
    }
  }

  // Get adaptive font size
  static double getAdaptiveFontSize(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Get adaptive logo size
  static double getAdaptiveLogoSize(BuildContext context) {
    if (isMobile(context)) {
      return 100;
    } else if (isTablet(context)) {
      return 120;
    } else {
      return 140;
    }
  }

  // Get adaptive button height
  static double getAdaptiveButtonHeight(BuildContext context) {
    if (isMobile(context)) {
      return 52;
    } else if (isTablet(context)) {
      return 56;
    } else {
      return 60;
    }
  }

  // Get adaptive spacing between elements
  static double getSpacing(
    BuildContext context, {
    required double small,
    required double medium,
    required double large,
  }) {
    if (isMobile(context)) {
      return small;
    } else if (isTablet(context)) {
      return medium;
    } else {
      return large;
    }
  }
}
