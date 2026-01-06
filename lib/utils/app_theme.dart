import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Tier-1 Fintech color palette
  static const Color primaryColor = Color(0xFF0A2540); // Navy #0A2540
  static const Color accentColor = Color(0xFF00C853); // Green #00C853
  static const Color backgroundColor = Color(0xFFF8F9FA); // Light Bg #F8F9FA
  static const Color textColor = Color(0xFF333333); // Dark Grey

  // Compact High-Density UI TextTheme (font sizes reduced by ~15-20%)
  static TextTheme get _compactTextTheme {
    return GoogleFonts.poppinsTextTheme().copyWith(
      // Display styles (reduced ~15-20%)
      displayLarge: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.w400, color: textColor),
      displayMedium: GoogleFonts.poppins(fontSize: 38, fontWeight: FontWeight.w400, color: textColor),
      displaySmall: GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.w400, color: textColor),
      // Headline styles (reduced to ~22px range)
      headlineLarge: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w600, color: textColor),
      headlineMedium: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: textColor),
      headlineSmall: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
      // Title styles (reduced ~15-20%)
      titleLarge: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600, color: textColor),
      titleMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
      titleSmall: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
      // Body styles (reduced to ~13px)
      bodyLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: textColor),
      bodyMedium: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400, color: textColor),
      bodySmall: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400, color: textColor),
      // Label styles (reduced ~15-20%)
      labelLarge: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
      labelMedium: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: textColor),
      labelSmall: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: textColor),
    );
  }

  static ThemeData get theme {
    final textTheme = _compactTextTheme;

    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: textTheme,
      visualDensity: VisualDensity.compact,
      // Compact ListTile theme for high-density UI
      listTileTheme: const ListTileThemeData(
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        minVerticalPadding: 4,
        visualDensity: VisualDensity.compact,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: const Color.fromRGBO(0, 0, 0, 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        toolbarHeight: 52,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 22),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFF5F5F5), // Soft Grey
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none, // Removes the black line
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none, // Removes the black line
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.teal, width: 1.5), // Soft teal when typing
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      // Compact icon theme
      iconTheme: const IconThemeData(size: 20),
      // Reduced divider thickness
      dividerTheme: const DividerThemeData(
        thickness: 0.5,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = _compactTextTheme;

    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: const Color(0xFF1E1E1E),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(color: Colors.white),
        displayMedium: textTheme.displayMedium?.copyWith(color: Colors.white),
        displaySmall: textTheme.displaySmall?.copyWith(color: Colors.white),
        headlineLarge: textTheme.headlineLarge?.copyWith(color: Colors.white),
        headlineMedium: textTheme.headlineMedium?.copyWith(color: Colors.white),
        headlineSmall: textTheme.headlineSmall?.copyWith(color: Colors.white),
        titleLarge: textTheme.titleLarge?.copyWith(color: Colors.white),
        titleMedium: textTheme.titleMedium?.copyWith(color: Colors.white),
        titleSmall: textTheme.titleSmall?.copyWith(color: Colors.white),
        bodyLarge: textTheme.bodyLarge?.copyWith(color: Colors.white70),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: Colors.white70),
        bodySmall: textTheme.bodySmall?.copyWith(color: Colors.white60),
        labelLarge: textTheme.labelLarge?.copyWith(color: Colors.white),
        labelMedium: textTheme.labelMedium?.copyWith(color: Colors.white),
        labelSmall: textTheme.labelSmall?.copyWith(color: Colors.white),
      ),
      visualDensity: VisualDensity.compact,
      // Compact ListTile theme for high-density UI
      listTileTheme: const ListTileThemeData(
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        minVerticalPadding: 4,
        visualDensity: VisualDensity.compact,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: const Color.fromRGBO(0, 0, 0, 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: const Color(0xFF1E1E1E),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        toolbarHeight: 52,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 22),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: const TextStyle(color: Colors.white60),
        labelStyle: const TextStyle(color: Colors.white70),
      ),
      // Compact icon theme
      iconTheme: const IconThemeData(size: 20, color: Colors.white70),
      // Reduced divider thickness
      dividerTheme: const DividerThemeData(
        thickness: 0.5,
        space: 1,
        color: Colors.white24,
      ),
    );
  }
}
