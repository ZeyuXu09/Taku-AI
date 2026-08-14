import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  ThemeService._();

  static final ThemeService instance = ThemeService._();
  static const _storageKey = 'dark_mode_enabled';

  /// App launches in dark mode until the user turns it off.
  final ValueNotifier<bool> isDark = ValueNotifier(true);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    isDark.value = prefs.getBool(_storageKey) ?? true;
  }

  Future<void> setDark(bool value) async {
    if (isDark.value == value) return;
    isDark.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey, value);
  }
}
