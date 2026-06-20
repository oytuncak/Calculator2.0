import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted app settings. M1 only tracks theme mode; more settings (number
/// format, etc.) slot in here later.
class SettingsController extends StateNotifier<ThemeMode> {
  SettingsController(this._prefs) : super(_read(_prefs));

  static const _themeKey = 'theme_mode';
  final SharedPreferences _prefs;

  static ThemeMode _read(SharedPreferences prefs) {
    return switch (prefs.getString(_themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _prefs.setString(_themeKey, mode.name);
  }

  void toggleDark() =>
      setThemeMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, ThemeMode>(
      (ref) => throw UnimplementedError(
        'settingsControllerProvider must be overridden in main()',
      ),
    );
