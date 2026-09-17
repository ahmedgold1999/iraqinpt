import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  double _fontScale = 1.0;
  ThemeMode _themeMode = ThemeMode.light;

  static const String _fontScaleKey = 'user_font_scale';
  static const String _themeModeKey = 'user_theme_mode';

  double get fontScale => _fontScale;
  ThemeMode get themeMode => _themeMode ?? ThemeMode.light;
  bool get isDarkMode => themeMode == ThemeMode.dark;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _fontScale = prefs.getDouble(_fontScaleKey) ?? 1.0;
      
      final themeIndex = prefs.getInt(_themeModeKey);
      if (themeIndex != null && themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[themeIndex];
      } else {
        _themeMode = ThemeMode.light;
      }
    } catch (_) {
      _themeMode = ThemeMode.light;
    }
    
    notifyListeners();
  }

  Future<void> setFontScale(double scale) async {
    _fontScale = scale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontScaleKey, scale);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, mode.index);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (isDarkMode) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}
