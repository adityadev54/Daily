import 'package:flutter/material.dart';

/// App color constants - Pure black and white only
class AppColors {
  AppColors._();

  // Light mode colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightDivider = Color(0xFFEEEEEE);

  // Dark mode colors
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF999999);
  static const Color darkBorder = Color(0xFF333333);
  static const Color darkDivider = Color(0xFF222222);

  // Common colors
  static const Color error = Color(0xFFDC3545);
  static const Color success = Color(0xFF28A745);
}
