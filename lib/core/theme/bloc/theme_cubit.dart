import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  static const String _storageKey = 'is_dark_mode_preference_v1';
  final SharedPreferences? _prefs;

  ThemeCubit({SharedPreferences? preferences})
      : _prefs = preferences,
        super(const ThemeState()) {
    _loadThemePreference();
  }

  void _loadThemePreference() {
    if (_prefs != null) {
      final isDark = _prefs.getBool(_storageKey);
      if (isDark != null) {
        emit(ThemeState(themeMode: isDark ? ThemeMode.dark : ThemeMode.light));
      }
    }
  }

  Future<void> _saveThemePreference(ThemeMode mode) async {
    if (_prefs != null) {
      await _prefs.setBool(_storageKey, mode == ThemeMode.dark);
    }
  }

  void toggleTheme() {
    final newMode = state.isDarkMode ? ThemeMode.light : ThemeMode.dark;
    _saveThemePreference(newMode);
    emit(ThemeState(themeMode: newMode));
  }

  void setThemeMode(ThemeMode mode) {
    if (state.themeMode != mode) {
      _saveThemePreference(mode);
      emit(ThemeState(themeMode: mode));
    }
  }
}
