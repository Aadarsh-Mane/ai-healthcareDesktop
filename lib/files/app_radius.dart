import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  static const double none   = 0;
  static const double xs     = 4;
  static const double sm     = 6;
  static const double md     = 8;
  static const double lg     = 12;
  static const double xl     = 16;
  static const double xxl    = 20;
  static const double xxxl   = 24;
  static const double full   = 999;

  // ── Border Radius Objects ──────────────────────────────────────────────────
  static const BorderRadius radiusNone  = BorderRadius.zero;
  static const BorderRadius radiusXs    = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius radiusSm    = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMd    = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLg    = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXl    = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusXxl   = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius radiusXxxl  = BorderRadius.all(Radius.circular(xxxl));
  static const BorderRadius radiusFull  = BorderRadius.all(Radius.circular(full));

  // ── Semantic Aliases ───────────────────────────────────────────────────────
  static const BorderRadius card    = radiusLg;   // 12
  static const BorderRadius button  = radiusMd;   // 8
  static const BorderRadius input   = radiusMd;   // 8
  static const BorderRadius badge   = radiusFull;
  static const BorderRadius dialog  = radiusXl;   // 16
  static const BorderRadius chip    = radiusFull;
  static const BorderRadius tooltip = radiusSm;   // 6
  static const BorderRadius avatar  = radiusFull;
}
