import 'package:flutter/material.dart';
// import 'package:dynamic_color/dynamic_color.dart';

class AppTheme {
  // Generate light theme based on provided settings
  static ThemeData getLightTheme({
    required bool useDynamicColor,
    required Color seedColor,
    ColorScheme? dynamicLightColorScheme,
  }) {
    ColorScheme colorScheme;
    
    if (useDynamicColor && dynamicLightColorScheme != null) {
      // Use dynamic color if available and enabled
      colorScheme = dynamicLightColorScheme;
    } else {
      // Otherwise use the seed color
      colorScheme = ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      );
    }
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: colorScheme.primaryContainer,
      ),
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 1,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
  
  // Generate dark theme based on provided settings
  static ThemeData getDarkTheme({
    required bool useDynamicColor,
    required Color seedColor,
    ColorScheme? dynamicDarkColorScheme,
  }) {
    ColorScheme colorScheme;
    
    if (useDynamicColor && dynamicDarkColorScheme != null) {
      // Use dynamic color if available and enabled
      colorScheme = dynamicDarkColorScheme;
    } else {
      // Otherwise use the seed color
      colorScheme = ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      );
    }
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
  
  // Legacy theme getters for backward compatibility
  static ThemeData get lightTheme => getLightTheme(
    useDynamicColor: false,
    seedColor: Colors.blue,
    dynamicLightColorScheme: null,
  );
  
  static ThemeData get darkTheme => getDarkTheme(
    useDynamicColor: false,
    seedColor: Colors.blue,
    dynamicDarkColorScheme: null,
  );
}