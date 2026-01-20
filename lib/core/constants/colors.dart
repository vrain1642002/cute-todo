import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors
  static const Color lightPrimary = Color(0xFFFF6B9D); // Cute Pink
  static const Color lightSecondary = Color(0xFFFEC84B); // Warm Yellow
  static const Color lightAccent = Color(0xFF8B5CF6); // Purple
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1F2937);
  static const Color lightTextSecondary = Color(0xFF6B7280);

  // Dark Theme Colors
  static const Color darkPrimary = Color(0xFFFF6B9D);
  static const Color darkSecondary = Color(0xFFFEC84B);
  static const Color darkAccent = Color(0xFFA78BFA);
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkText = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Priority Colors
  static const Color priorityHigh = Color(0xFFEF4444); // Red
  static const Color priorityMedium = Color(0xFFFBBF24); // Yellow
  static const Color priorityLow = Color(0xFF10B981); // Green

  // ==================== KANBAN COLUMN COLORS ====================

  // Todo Column - Soft Blue
  static const Color columnTodo = Color(0xFF3B82F6);
  static const Color columnTodoBg = Color(0xFFEFF6FF);
  static const Color columnTodoBorder = Color(0xFFBFDBFE);

  // In Progress Column - Warm Orange
  static const Color columnInProgress = Color(0xFFF97316);
  static const Color columnInProgressBg = Color(0xFFFFF7ED);
  static const Color columnInProgressBorder = Color(0xFFFED7AA);

  // Done Column - Fresh Green
  static const Color columnDone = Color(0xFF10B981);
  static const Color columnDoneBg = Color(0xFFECFDF5);
  static const Color columnDoneBorder = Color(0xFFA7F3D0);

  // ==================== CARD COLORS ====================

  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0x1A000000);
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Glassmorphism
  static const Color glassBackground = Color(0xCCFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // ==================== GRADIENT COLORS ====================

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6B9D), Color(0xFFFF8A80)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient todoGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient inProgressGradient = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFFB923C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient doneGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Category Colors
  static const List<Color> categoryColors = [
    Color(0xFFFF6B9D), // Pink
    Color(0xFF8B5CF6), // Purple
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Green
    Color(0xFFF59E0B), // Orange
    Color(0xFFEC4899), // Hot Pink
    Color(0xFF06B6D4), // Cyan
  ];
}
