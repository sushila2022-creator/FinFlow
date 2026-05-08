import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FinFlow Design System - Standardized UI Constants
/// Single source of truth for all spacing, typography, radius, shadows, and dimensions
class DesignSystem {
  // ==============================================
  // SPACING SYSTEM (8px base grid)
  // ==============================================
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacing2Xl = 48.0;
  static const double spacing3Xl = 64.0;

  // ==============================================
  // BORDER RADIUS SYSTEM
  // ==============================================
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radius2Xl = 28.0;
  static const double radiusFull = 9999.0;

  // ==============================================
  // ELEVATION & SHADOW SYSTEM
  // ==============================================
  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(color: Color(0x26000000), blurRadius: 16, offset: Offset(0, 8)),
  ];

  // ==============================================
  // TYPOGRAPHY SCALE (Proper Material 3 sizing)
  // ==============================================
  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    height: 1.12,
    letterSpacing: -0.25,
  );

  static TextStyle get displayMedium => GoogleFonts.plusJakartaSans(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    height: 1.15,
  );

  static TextStyle get displaySmall => GoogleFonts.plusJakartaSans(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    height: 1.22,
  );

  static TextStyle get headlineLarge => GoogleFonts.plusJakartaSans(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static TextStyle get headlineMedium => GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.28,
  );

  static TextStyle get headlineSmall => GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.27,
  );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.50,
    letterSpacing: 0.15,
  );

  static TextStyle get titleSmall => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.42,
    letterSpacing: 0.1,
  );

  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.50,
    letterSpacing: 0.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.42,
    letterSpacing: 0.25,
  );

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 0.4,
  );

  static TextStyle get labelLarge => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.42,
    letterSpacing: 0.1,
  );

  static TextStyle get labelMedium => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.5,
  );

  static TextStyle get labelSmall => GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.45,
    letterSpacing: 0.5,
  );

  // ==============================================
  // RESPONSIVE BREAKPOINTS
  // ==============================================
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // ==============================================
  // RESPONSIVE HELPER METHODS
  // ==============================================
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobileBreakpoint &&
      MediaQuery.sizeOf(context).width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  static double responsivePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width > desktopBreakpoint) return spacing3Xl;
    if (width > tabletBreakpoint) return spacingXl;
    return spacingMd;
  }

  static double responsiveCardMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width > desktopBreakpoint) return 600;
    if (width > tabletBreakpoint) return 500;
    return double.infinity;
  }
}

// ==============================================
// PADDING EXTENSIONS
// ==============================================
extension EdgeInsetsSpacing on EdgeInsets {
  static EdgeInsets get allXs => const EdgeInsets.all(DesignSystem.spacingXs);
  static EdgeInsets get allSm => const EdgeInsets.all(DesignSystem.spacingSm);
  static EdgeInsets get allMd => const EdgeInsets.all(DesignSystem.spacingMd);
  static EdgeInsets get allLg => const EdgeInsets.all(DesignSystem.spacingLg);
  static EdgeInsets get allXl => const EdgeInsets.all(DesignSystem.spacingXl);

  static EdgeInsets get horizontalMd =>
      const EdgeInsets.symmetric(horizontal: DesignSystem.spacingMd);
  static EdgeInsets get verticalMd =>
      const EdgeInsets.symmetric(vertical: DesignSystem.spacingMd);

  static EdgeInsets get horizontalLg =>
      const EdgeInsets.symmetric(horizontal: DesignSystem.spacingLg);
  static EdgeInsets get verticalLg =>
      const EdgeInsets.symmetric(vertical: DesignSystem.spacingLg);

  static EdgeInsets get screenPadding => const EdgeInsets.symmetric(
    horizontal: DesignSystem.spacingMd,
    vertical: DesignSystem.spacingLg,
  );
}

// ==============================================
// BORDER RADIUS EXTENSIONS
// ==============================================
extension BorderRadiusRadius on BorderRadius {
  static BorderRadius get xs => BorderRadius.circular(DesignSystem.radiusXs);
  static BorderRadius get sm => BorderRadius.circular(DesignSystem.radiusSm);
  static BorderRadius get md => BorderRadius.circular(DesignSystem.radiusMd);
  static BorderRadius get lg => BorderRadius.circular(DesignSystem.radiusLg);
  static BorderRadius get xl => BorderRadius.circular(DesignSystem.radiusXl);
  static BorderRadius get full =>
      BorderRadius.circular(DesignSystem.radiusFull);
}
