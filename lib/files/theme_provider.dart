import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ThemeMode provider (light only for now — extend when dark mode is added)
// ─────────────────────────────────────────────────────────────────────────────
final themeModeProvider = StateProvider<ThemeMode>(
  (ref) => ThemeMode.light,
);

// ─────────────────────────────────────────────────────────────────────────────
// Resolved ThemeData provider
// ─────────────────────────────────────────────────────────────────────────────
final themeDataProvider = Provider<ThemeData>((ref) {
  final mode = ref.watch(themeModeProvider);
  return switch (mode) {
    ThemeMode.light  => AppTheme.light,
    ThemeMode.dark   => AppTheme.light, // replace with AppTheme.dark when ready
    ThemeMode.system => AppTheme.light,
  };
});

// ─────────────────────────────────────────────────────────────────────────────
// Notifier — to toggle / set theme mode
// ─────────────────────────────────────────────────────────────────────────────
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void setLight()  => state = ThemeMode.light;
  void setDark()   => state = ThemeMode.dark;
  void setSystem() => state = ThemeMode.system;
  void toggle()    => state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
}

final themeModeNotifierProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
