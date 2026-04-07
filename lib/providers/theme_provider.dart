import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finflow/utils/debug_logger.dart';

/// Optimized ThemeProvider with deferred async initialization
///
/// Performance optimizations:
/// 1. Starts with default theme immediately (no waiting)
/// 2. Loads saved theme asynchronously after first frame
/// 3. Uses Future.microtask for non-blocking initialization
class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';

  // Start with default theme immediately - no waiting
  ThemeMode _themeMode = ThemeMode.light;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isInitialized => _isInitialized;

  /// Initialize theme provider
  /// Loads saved theme asynchronously without blocking UI
  ThemeProvider() {
    // Use Future.microtask to defer loading until after current event loop
    // This ensures the UI renders with default theme immediately
    Future.microtask(() => _loadThemeMode());
  }

  // Load saved theme mode from SharedPreferences (async, non-blocking)
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themeModeKey);

      if (savedMode != null) {
        _themeMode = savedMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
      }
      // If no saved mode, keep default (light mode)
    } catch (e) {
      // Failed to load saved theme - keep default
      logError('Failed to load saved theme', tag: 'ThemeProvider', error: e);
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Toggle between light and dark mode
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = _themeMode == ThemeMode.dark ? 'dark' : 'light';
      await prefs.setString(_themeModeKey, modeString);
    } catch (e) {
      logError('Failed to save theme mode', tag: 'ThemeProvider', error: e);
    }
  }
}
