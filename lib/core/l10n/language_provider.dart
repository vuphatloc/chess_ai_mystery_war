import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_strings.dart';

/// Provider for current language code
final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('en') {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_language') ?? 'en';
    AppStrings.setLanguage(saved);
    state = saved;
  }

  Future<void> setLanguage(String code) async {
    AppStrings.setLanguage(code);
    state = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', code);
  }
}

/// Helper extension so any widget can call context.s('key')
extension LocalizationExt on BuildContext {
  String s(String key) => AppStrings.get(key);
}

/// Convenience typedef — use S.get('key') statically
class S {
  static String get(String key) => AppStrings.get(key);
}
