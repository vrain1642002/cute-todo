import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends ChangeNotifier {
  Locale _locale = const Locale('en');
  Map<String, String> _localizedStrings = {};

  Locale get locale => _locale;

  LocalizationService() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? langCode = prefs.getString('language_code');
    if (langCode != null) {
      _locale = Locale(langCode);
    }
    await load();
  }

  Future<void> load() async {
    final String jsonString =
        await rootBundle.loadString('assets/lang/${_locale.languageCode}.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });
    notifyListeners();
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  Future<void> changeLanguage(Locale type) async {
    if (_locale == type) return;

    _locale = type;
    await load();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', type.languageCode);
  }
}
