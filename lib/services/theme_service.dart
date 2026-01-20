import 'dart:async';
import 'package:flutter/material.dart';

enum AppThemeMode { morning, day, sunset, night }

class ThemePalette {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color text;
  final Color textSecondary;
  final LinearGradient backgroundGradient;

  const ThemePalette({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.text,
    required this.textSecondary,
    required this.backgroundGradient,
  });
}

class ThemeService extends ChangeNotifier {
  AppThemeMode _currentMode = AppThemeMode.day;
  Timer? _timer;

  AppThemeMode get currentMode => _currentMode;

  ThemePalette get currentPalette => _getPaletteForMode(_currentMode);

  ThemeService() {
    _updateThemeMode();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    // Check every minute
    _timer =
        Timer.periodic(const Duration(minutes: 1), (_) => _updateThemeMode());
  }

  void _updateThemeMode() {
    final hour = DateTime.now().hour;
    AppThemeMode newMode;

    if (hour >= 6 && hour < 11) {
      newMode = AppThemeMode.morning;
    } else if (hour >= 11 && hour < 17) {
      newMode = AppThemeMode.day;
    } else if (hour >= 17 && hour < 21) {
      newMode = AppThemeMode.sunset;
    } else {
      newMode = AppThemeMode.night;
    }

    if (newMode != _currentMode) {
      _currentMode = newMode;
      notifyListeners();
    }
  }

  ThemePalette _getPaletteForMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.morning:
        return _morningPalette;
      case AppThemeMode.day:
        return _dayPalette;
      case AppThemeMode.sunset:
        return _sunsetPalette;
      case AppThemeMode.night:
        return _nightPalette;
    }
  }

  // --- PALETTES ---

  static const _morningPalette = ThemePalette(
    primary: Color(0xFFFFB74D), // Soft Orange
    secondary: Color(0xFFFFCC80),
    background: Color(0xFFFFF8E1), // Very light yellow/cream
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF5D4037), // Brownish gray
    textSecondary: Color(0xFF8D6E63),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
    ),
  );

  static const _dayPalette = ThemePalette(
    primary: Color(0xFFFF6B9D), // Original Pink
    secondary: Color(0xFFFEC84B),
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF1F2937),
    textSecondary: Color(0xFF6B7280),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
    ),
  );

  static const _sunsetPalette = ThemePalette(
    primary: Color(0xFFFF8A65), // Deep Orange/Salmon
    secondary: Color(0xFFBA68C8), // Purple accent
    background: Color(0xFFF3E5F5), // Lavender mix
    surface: Color(0xFFFFF3E0), // Warm surface
    text: Color(0xFF4A148C), // Deep Purple text
    textSecondary: Color(0xFF7B1FA2),
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFCCBC), Color(0xFFE1BEE7)], // Orange to Purple
    ),
  );

  static const _nightPalette = ThemePalette(
    primary: Color(0xFF818CF8), // Indigo
    secondary: Color(0xFF4F46E5),
    background: Color(0xFF0F172A), // Dark Blue/Grey
    surface: Color(0xFF1E293B),
    text: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    ),
  );
}
