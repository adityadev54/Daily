import 'package:flutter/material.dart';

/// Spera Color System
/// Design Philosophy: CALM + BOLD + MINIMAL + PREMIUM
/// Supports both dark and light modes
class AppColors {
  AppColors._();

  // ============================================
  // DARK MODE PALETTE
  // ============================================

  /// Deep black - Primary background (dark)
  static const Color backgroundDark = Color(0xFF0A0A0B);

  /// Slightly elevated surface (dark)
  static const Color surfaceDark = Color(0xFF121214);

  /// Card and elevated elements (dark)
  static const Color surfaceElevatedDark = Color(0xFF1A1A1D);

  /// Subtle borders and dividers (dark)
  static const Color borderDark = Color(0xFF2A2A2E);

  /// Hover/pressed states (dark)
  static const Color surfaceHoverDark = Color(0xFF222226);

  /// Primary text (dark)
  static const Color textPrimaryDark = Color(0xFFFAFAFA);

  /// Secondary text (dark)
  static const Color textSecondaryDark = Color(0xFFA0A0A5);

  /// Tertiary text (dark)
  static const Color textTertiaryDark = Color(0xFF6B6B70);

  /// Disabled text (dark)
  static const Color textDisabledDark = Color(0xFF4A4A4E);

  // ============================================
  // LIGHT MODE PALETTE
  // ============================================

  /// Light background
  static const Color backgroundLight = Color(0xFFF8F9FA);

  /// Light surface
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Light elevated surface
  static const Color surfaceElevatedLight = Color(0xFFF1F3F5);

  /// Light border
  static const Color borderLight = Color(0xFFE5E7EB);

  /// Light hover
  static const Color surfaceHoverLight = Color(0xFFE9ECEF);

  /// Primary text (light)
  static const Color textPrimaryLight = Color(0xFF111827);

  /// Secondary text (light)
  static const Color textSecondaryLight = Color(0xFF4B5563);

  /// Tertiary text (light)
  static const Color textTertiaryLight = Color(0xFF9CA3AF);

  /// Disabled text (light)
  static const Color textDisabledLight = Color(0xFFD1D5DB);

  // ============================================
  // LEGACY ALIASES (for backwards compatibility - use dark values)
  // These will be deprecated - use theme-aware methods instead
  // ============================================

  /// Deep black - Primary background
  static const Color background = backgroundDark;

  /// Slightly elevated surface
  static const Color surface = surfaceDark;

  /// Card and elevated elements
  static const Color surfaceElevated = surfaceElevatedDark;

  /// Subtle borders and dividers
  static const Color border = borderDark;

  /// Hover/pressed states
  static const Color surfaceHover = surfaceHoverDark;

  /// Primary text - High contrast white
  static const Color textPrimary = textPrimaryDark;

  /// Secondary text - Muted
  static const Color textSecondary = textSecondaryDark;

  /// Tertiary text - Very muted
  static const Color textTertiary = textTertiaryDark;

  /// Disabled text
  static const Color textDisabled = textDisabledDark;

  // ============================================
  // ACCENT COLORS - Purposeful, not decorative
  // ============================================

  /// Primary accent - Faded Gold (Premium/Wisdom)
  static const Color accent = Color(0xFFD4A574);

  /// Accent muted for backgrounds
  static const Color accentMuted = Color(0xFF5C4A3A);

  /// Success - Green (Completion/Mastery)
  static const Color success = Color(0xFF22C55E);

  /// Warning - Amber (Attention/Temporal)
  static const Color warning = Color(0xFFF59E0B);

  /// Error - Red (Critical)
  static const Color error = Color(0xFFEF4444);

  // ============================================
  // RANK COLORS - Professional Progression
  // ============================================

  /// Observer - Starting tier (Slate)
  static const Color rankObserver = Color(0xFF64748B);

  /// Analyst - Second tier (Blue)
  static const Color rankAnalyst = Color(0xFF3B82F6);

  /// Strategist - Third tier (Purple)
  static const Color rankStrategist = Color(0xFF8B5CF6);

  /// Architect - Highest tier (Gold)
  static const Color rankArchitect = Color(0xFFD4AF37);

  // ============================================
  // CONTENT TYPE INDICATORS
  // ============================================

  /// Audio content
  static const Color contentAudio = Color(0xFF8B5CF6);

  /// Video content
  static const Color contentVideo = Color(0xFF06B6D4);

  /// Thinking tools
  static const Color categoryThinking = Color(0xFF3B82F6);

  /// Real-world problems
  static const Color categoryProblems = Color(0xFFF59E0B);

  /// Skill unlocks
  static const Color categorySkills = Color(0xFF22C55E);

  /// Temporal content (limited time)
  static const Color categoryTemporal = Color(0xFFEF4444);

  // ============================================
  // GRADIENTS - Subtle, premium
  // ============================================

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0A0B), Color(0xFF0F0F12)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A1D), Color(0xFF151517)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
  );

  // ============================================
  // SHADOWS - Subtle depth
  // ============================================

  static List<BoxShadow> get elevationLow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get elevationMedium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevationHigh => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
