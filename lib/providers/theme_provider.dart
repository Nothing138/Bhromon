// providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // ========================
  // STORAGE KEYS
  // ========================
  static const String _themeKey = 'app_theme_mode';
  static const String _accentColorKey = 'app_accent_color';

  // ========================
  // STATE VARIABLES
  // ========================
  ThemeMode _themeMode = ThemeMode.light;
  Color _accentColor = const Color(0xFFF4B400);
  bool _isInitialized = false;

  // ========================
  // GETTERS
  // ========================
  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isInitialized => _isInitialized;

  // ========================
  // INITIALIZE FROM LOCAL STORAGE
  // ========================
  Future<void> initializeTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load saved theme mode (default: light)
      final savedThemeString = prefs.getString(_themeKey);
      if (savedThemeString != null) {
        _themeMode =
            savedThemeString == 'dark' ? ThemeMode.dark : ThemeMode.light;
      } else {
        _themeMode = ThemeMode.light; // First time: light mode
      }

      // Load saved accent color (default: gold)
      final savedColorInt = prefs.getInt(_accentColorKey);
      if (savedColorInt != null) {
        _accentColor = Color(savedColorInt);
      } else {
        _accentColor = const Color(0xFFF4B400); // First time: gold
      }

      _isInitialized = true;
      notifyListeners();

      debugPrint(
          ' Theme Initialized - Mode: ${_themeMode.name}, Color: #${_accentColor.value.toRadixString(16).toUpperCase()}');
    } catch (e) {
      debugPrint(' Error initializing theme: $e');
      _isInitialized = true;
      _themeMode = ThemeMode.light;
      _accentColor = const Color(0xFFF4B400);
      notifyListeners();
    }
  }

  // ========================
  // SET DARK MODE
  // ========================
  Future<void> setDarkMode(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    await _saveThemePreference();
    notifyListeners();
  }

  // ========================
  // TOGGLE THEME
  // ========================
  Future<void> toggleTheme(bool isOn) async {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    await _saveThemePreference();
    notifyListeners();
  }

  // ========================
  // SET ACCENT COLOR
  // ========================
  Future<void> setAccentColor(Color newColor) async {
    _accentColor = newColor;
    await _saveAccentColorPreference();
    notifyListeners();
  }

  // ========================
  // UPDATE ACCENT COLOR
  // ========================
  Future<void> updateAccentColor(Color newColor) async {
    _accentColor = newColor;
    await _saveAccentColorPreference();
    notifyListeners();
  }

  // ========================
  // SAVE THEME TO LOCAL STORAGE
  // ========================
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeValue = _themeMode == ThemeMode.dark ? 'dark' : 'light';
      await prefs.setString(_themeKey, themeValue);
      debugPrint('💾 Theme Saved: $themeValue');
    } catch (e) {
      debugPrint(' Error saving theme: $e');
    }
  }

  // ========================
  // SAVE ACCENT COLOR TO LOCAL STORAGE
  // ========================
  Future<void> _saveAccentColorPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_accentColorKey, _accentColor.value);
      debugPrint(
          '💾 Color Saved: #${_accentColor.value.toRadixString(16).toUpperCase()}');
    } catch (e) {
      debugPrint(' Error saving color: $e');
    }
  }

  // ========================
  // RESET TO DEFAULTS
  // ========================
  Future<void> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_themeKey);
      await prefs.remove(_accentColorKey);

      _themeMode = ThemeMode.light;
      _accentColor = const Color(0xFFF4B400);

      notifyListeners();
      debugPrint(' Theme Reset to Defaults - Light Mode + Gold Color');
    } catch (e) {
      debugPrint(' Error resetting theme: $e');
    }
  }
}
