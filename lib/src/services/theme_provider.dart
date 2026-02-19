import 'package:flutter/material.dart';

/// Manages the app's theme state (light or dark).
///
/// It extends ChangeNotifier to notify widgets when the theme is changed,
/// allowing the UI to rebuild with the new theme.
class ThemeProvider extends ChangeNotifier {
  // Default to light mode.
  ThemeMode _themeMode = ThemeMode.dark;

  /// Returns the current theme mode.
  ThemeMode get themeMode => _themeMode;

  /// A convenience getter to check if the current theme is dark.
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Toggles the theme between light and dark mode.
  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    // Notify all listening widgets to rebuild.
    notifyListeners();
  }
}
