import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Constructor - automatically loads saved theme
  ThemeProvider() {
    _loadThemeMode();
  }

  // Load saved theme mode from SharedPreferences
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_themeModeKey);

    if (savedMode != null) {
      _themeMode = savedMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
    } else {
      // Default to light mode
      _themeMode = ThemeMode.light;
    }

    notifyListeners();
  }

  // Toggle between light and dark mode
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _saveThemeMode();
    notifyListeners();
  }

  // Set theme mode directly
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _saveThemeMode();
    notifyListeners();
  }

  // Save theme mode to SharedPreferences
  Future<void> _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = _themeMode == ThemeMode.dark ? 'dark' : 'light';
    await prefs.setString(_themeModeKey, modeString);
  }
}
