import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _useDynamicColor = true;
  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = Colors.blue;
  
  // Keys for shared preferences
  static const String _useDynamicColorKey = 'use_dynamic_color';
  static const String _themeModeKey = 'theme_mode';
  static const String _seedColorKey = 'seed_color';
  
  ThemeProvider() {
    _loadSettings();
  }
  
  bool get useDynamicColor => _useDynamicColor;
  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  
  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _useDynamicColor = prefs.getBool(_useDynamicColorKey) ?? true;
    _themeMode = ThemeMode.values[prefs.getInt(_themeModeKey) ?? 0];
    _seedColor = Color(prefs.getInt(_seedColorKey) ?? Colors.blue.value);
    notifyListeners();
  }
  
  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useDynamicColorKey, _useDynamicColor);
    await prefs.setInt(_themeModeKey, _themeMode.index);
    await prefs.setInt(_seedColorKey, _seedColor.value);
  }
  
  void setUseDynamicColor(bool value) {
    _useDynamicColor = value;
    _saveSettings();
    notifyListeners();
  }
  
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveSettings();
    notifyListeners();
  }
  
  void setSeedColor(Color color) {
    _seedColor = color;
    _saveSettings();
    notifyListeners();
  }
}