import 'package:flutter/material.dart';

/// Responsive sizing utility for mobile-first design
/// Oppo A53 screen: ~6.5" (1080x2400 pixels)
class ResponsiveSize {
  static late BuildContext _context;

  /// Initialize with BuildContext (call in main widget build)
  static void init(BuildContext context) {
    _context = context;
  }

  static MediaQueryData get _mediaQuery => MediaQuery.of(_context);
  static Size get screenSize => _mediaQuery.size;
  static double get screenWidth => screenSize.width;
  static double get screenHeight => screenSize.height;
  static bool get isMobile => screenWidth < 600;
  static bool get isTablet => screenWidth >= 600 && screenWidth < 1200;
  static bool get isDesktop => screenWidth >= 1200;

  /// Responsive font sizes
  static double get h1 => _scale(32); // 28-36
  static double get h2 => _scale(28); // 24-32
  static double get h3 => _scale(24); // 20-28
  static double get h4 => _scale(20); // 18-24
  static double get h5 => _scale(18); // 16-22
  static double get h6 => _scale(16); // 14-18
  static double get bodyLarge => _scale(16); // 14-18
  static double get body => _scale(14); // 12-16
  static double get bodySmall => _scale(12); // 10-14
  static double get caption => _scale(11); // 9-12
  static double get label => _scale(12); // 10-14

  /// Responsive spacing
  static double get xs => _scale(4); // 4
  static double get sm => _scale(8); // 8
  static double get md => _scale(12); // 12
  static double get lg => _scale(16); // 16
  static double get xl => _scale(24); // 24
  static double get xxl => _scale(32); // 32

  /// Responsive icon sizes
  static double get iconXs => _scale(16); // 16
  static double get iconSm => _scale(20); // 20
  static double get iconMd => _scale(24); // 24
  static double get iconLg => _scale(32); // 32
  static double get iconXl => _scale(48); // 48

  /// Responsive border radius
  static double get radiusSm => _scale(8); // 8
  static double get radiusMd => _scale(12); // 12
  static double get radiusLg => _scale(16); // 16
  static double get radiusXl => _scale(24); // 24

  /// Input field heights
  static double get inputHeight => _scale(48); // ~48
  static double get buttonHeight => _scale(48); // ~48

  /// Scale function - base breakpoint 360 (small mobile)
  static double _scale(double baseSize) {
    const breakpoint = 360.0;
    final scale = screenWidth / breakpoint;
    
    // Limit scaling between 0.85 and 1.2 for readability
    final clampedScale = scale.clamp(0.85, 1.2);
    return baseSize * clampedScale;
  }

  /// Padding helper
  static EdgeInsets paddingAll(double size) => EdgeInsets.all(_scale(size));
  static EdgeInsets paddingSymmetric({double horizontal = 0, double vertical = 0}) =>
      EdgeInsets.symmetric(
        horizontal: _scale(horizontal),
        vertical: _scale(vertical),
      );
  static EdgeInsets paddingOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) =>
      EdgeInsets.only(
        left: _scale(left),
        top: _scale(top),
        right: _scale(right),
        bottom: _scale(bottom),
      );
}
