import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.light;
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  ThemeService() {
    _loadThemeFromPrefs();
  }
  
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      
      if (savedTheme != null) {
        _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
        notifyListeners();
      }
    } catch (e) {
      // If there's an error loading the theme, use the default (light)
      _themeMode = ThemeMode.light;
    }
  }
  
  Future<void> _saveThemeToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, isDarkMode ? 'dark' : 'light');
    } catch (e) {
      // Handle error silently
    }
  }
  
  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    _saveThemeToPrefs();
    notifyListeners();
  }
  
  void setDarkMode() {
    if (!isDarkMode) {
      _themeMode = ThemeMode.dark;
      _saveThemeToPrefs();
      notifyListeners();
    }
  }
  
  void setLightMode() {
    if (isDarkMode) {
      _themeMode = ThemeMode.light;
      _saveThemeToPrefs();
      notifyListeners();
    }
  }
}