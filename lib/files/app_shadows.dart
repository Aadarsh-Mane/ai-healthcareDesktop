import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppShadows {
  AppShadows._();

  // ── Elevation Shadows (blue-tinted to match primary) ──────────────────────
  static const List<BoxShadow> none = [];

  static const List<BoxShadow> xs = [
    BoxShadow(
      color: Color(0x0A2383E2),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0D2383E2),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x082383E2),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x112383E2),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0A2383E2),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x152383E2),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0D2383E2),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x1A2383E2),
      blurRadius: 40,
      offset: Offset(0, 16),
    ),
    BoxShadow(
      color: Color(0x112383E2),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  // ── Semantic Aliases ───────────────────────────────────────────────────────
  static const List<BoxShadow> card    = sm;
  static const List<BoxShadow> cardHover = md;
  static const List<BoxShadow> dialog  = lg;
  static const List<BoxShadow> sidebar = [
    BoxShadow(
      color: Color(0x0D2383E2),
      blurRadius: 12,
      offset: Offset(2, 0),
    ),
  ];
  static const List<BoxShadow> popover = md;
  static const List<BoxShadow> button  = xs;
  static const List<BoxShadow> input   = [
    BoxShadow(
      color: Color(0x142383E2),
      blurRadius: 0,
      spreadRadius: 3,
      offset: Offset(0, 0),
    ),
  ]; // focus ring
}
