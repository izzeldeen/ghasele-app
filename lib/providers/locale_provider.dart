import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('ar'); // Default to Arabic

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'ar';
    _locale = Locale(languageCode);
    _syncApiLanguage();
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    _syncApiLanguage();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
  }

  /// Mirrors the locale onto ApiService so outgoing requests carry a matching
  /// Accept-Language header and the backend replies with error messages in the
  /// same language the UI is showing.
  void _syncApiLanguage() {
    ApiService.language = _locale.languageCode;
  }

  void toggleLocale() {
    if (_locale.languageCode == 'ar') {
      setLocale(const Locale('en'));
    } else {
      setLocale(const Locale('ar'));
    }
  }
}
