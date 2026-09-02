import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleCubit extends Cubit<Locale> {
  static const String _localeKey = 'cherish_app_locale_code_v1';
  final SharedPreferences? _prefs;

  LocaleCubit({SharedPreferences? preferences})
      : _prefs = preferences,
        super(const Locale('en')) {
    _loadLocale();
  }

  void _loadLocale() {
    if (_prefs == null) return;
    final savedCode = _prefs.getString(_localeKey);
    if (savedCode != null && (savedCode == 'km' || savedCode == 'en')) {
      emit(Locale(savedCode));
    }
  }

  Future<void> changeLocale(Locale newLocale) async {
    if (state.languageCode == newLocale.languageCode) return;
    emit(newLocale);
    await _prefs?.setString(_localeKey, newLocale.languageCode);
  }

  bool get isKhmer => state.languageCode == 'km';
  bool get isEnglish => state.languageCode == 'en';
}
