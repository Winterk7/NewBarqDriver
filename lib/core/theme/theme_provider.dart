import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeKey = 'barq_driver_theme';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_kThemeKey);
    ThemeMode mode;
    if (val == 'dark') {
      mode = ThemeMode.dark;
    } else if (val == 'light') {
      mode = ThemeMode.light;
    } else {
      mode = ThemeMode.system;
    }
    state = mode;
    _applySystemChrome(mode);
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    _applySystemChrome(mode);
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.dark) {
      await prefs.setString(_kThemeKey, 'dark');
    } else if (mode == ThemeMode.light) {
      await prefs.setString(_kThemeKey, 'light');
    } else {
      await prefs.setString(_kThemeKey, 'system');
    }
  }

  /// Immediately updates iOS status bar + Control Centre colours on theme change.
  void _applySystemChrome(ThemeMode mode) {
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor:
          isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5),
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ));
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
