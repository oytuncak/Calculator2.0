import 'package:flutter/material.dart';

/// Light and dark themes for Calculator 2.0.
///
/// A calm indigo seed with a paper-like canvas surface; the monospace result
/// styling lives close to where it is used (the equation widget).
class AppTheme {
  static const _seed = Color(0xFF4F46E5); // indigo

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? const Color(0xFF111318)
          : const Color(0xFFF6F7FB),
      cardTheme: CardThemeData(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        isDense: true,
        border: InputBorder.none,
      ),
    );
  }

  /// Background paint colors for the infinite-canvas grid.
  static Color gridLine(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35);

  static Color linkLine(BuildContext context) =>
      Theme.of(context).colorScheme.primary.withValues(alpha: 0.45);
}
