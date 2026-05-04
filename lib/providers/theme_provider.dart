// providers/theme_provider.dart
import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  Color _accentColor = const Color(0xFFF4B400);

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void updateAccentColor(Color newColor) {
    _accentColor = newColor;
    notifyListeners();
  }
}
