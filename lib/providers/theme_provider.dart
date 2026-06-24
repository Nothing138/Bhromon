// providers/theme_provider.dart
import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  Color _accentColor = const Color(0xFFF4B400);

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // ========================
  // SET DARK MODE
  // ========================
  void setDarkMode(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // ========================
  // TOGGLE THEME
  // ========================
  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // ========================
  // SET ACCENT COLOR
  // ========================
  void setAccentColor(Color newColor) {
    _accentColor = newColor;
    notifyListeners();
  }

  // ========================
  // UPDATE ACCENT COLOR (Legacy - same as setAccentColor)
  // ========================
  void updateAccentColor(Color newColor) {
    _accentColor = newColor;
    notifyListeners();
  }
}
