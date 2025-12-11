/// App-wide spacing constants
/// Following 4px grid system for consistency
class AppSpacing {
  AppSpacing._();

  // Base unit
  static const double unit = 4.0;

  // Common spacing values
  static const double xs = 4.0; // unit * 1
  static const double sm = 8.0; // unit * 2
  static const double md = 16.0; // unit * 4
  static const double lg = 24.0; // unit * 6
  static const double xl = 32.0; // unit * 8
  static const double xxl = 48.0; // unit * 12
  static const double xxxl = 64.0; // unit * 16

  // Screen padding
  static const double screenPadding = 20.0;

  // Card padding
  static const double cardPadding = 16.0;

  // Section spacing
  static const double sectionGap = 32.0;

  // Item spacing in lists
  static const double listItemGap = 12.0;
}

/// App-wide border radius constants
class AppRadius {
  AppRadius._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;
}

/// App-wide animation durations
class AppDurations {
  AppDurations._();

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
}

/// App-wide icon sizes
class AppIconSizes {
  AppIconSizes._();

  static const double xs = 16.0;
  static const double sm = 20.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 48.0;
}
