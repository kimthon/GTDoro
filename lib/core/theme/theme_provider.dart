import 'package:flutter/material.dart';
import 'package:gtdoro/core/theme/dracula_theme.dart';
import 'package:gtdoro/core/theme/app_theme_base.dart';

class ThemeProvider extends ChangeNotifier {
  // Load Dracula theme file as default
  AppThemeBase _currentTheme = DraculaTheme();

  AppThemeBase get theme => _currentTheme;
  ThemeData get themeData => _currentTheme.themeData;

  // Change theme function (called from SettingsView, etc.)
  void changeTheme(AppThemeBase newTheme) {
    _currentTheme = newTheme;
    notifyListeners(); // Notify entire app that theme has changed
  }
}
