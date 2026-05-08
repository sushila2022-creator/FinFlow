import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium Deep Navy & Emerald Theme for FinFlow
/// A professional fintech color palette with micro-animations support
class AppTheme {
  // ===== Core Color Palette =====

  // Deep Navy - Primary brand color (trust, professionalism) - Dashboard matched
  static const Color primaryColor = Color(0xFF0D2B45);
  static const Color primaryColorLight = Color(0xFF1A3A5C);
  static const Color primaryColorDark = Color(0xFF051220);

  // Emerald - Accent color (growth, positive, finance)
  static const Color accentColor = Color(0xFF00C853);
  static const Color accentColorLight = Color(0xFF5EFC82);
  static const Color accentColorDark = Color(0xFF009624);

  // Secondary Emerald for gradients
  static const Color secondaryEmerald = Color(0xFF26A69A);
  static const Color secondaryTeal = Color(0xFF00897B);

  // Background Colors
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF666666);
  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // Status Colors
  static const Color incomeColor = Color(0xFF00C853);
  static const Color expenseColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color infoColor = Color(0xFF2196F3);

  // Gradient Presets
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D2B45), Color(0xFF1A3A5C)],
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00C853), Color(0xFF26A69A)],
  );

  static const LinearGradient cardGradientLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white, Color(0xFFF5F7FA)],
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2D2D2D), Color(0xFF1E1E1E)],
  );

  // ===== Typography =====

  static TextTheme get _lightTextTheme {
    return GoogleFonts.plusJakartaSansTextTheme().copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: textPrimaryLight,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: textPrimaryLight,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: textPrimaryLight,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: textPrimaryLight,
        height: 1.25,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textPrimaryLight,
        height: 1.28,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimaryLight,
        height: 1.33,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimaryLight,
        height: 1.27,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimaryLight,
        height: 1.50,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimaryLight,
        height: 1.42,
        letterSpacing: 0.1,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimaryLight,
        height: 1.50,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondaryLight,
        height: 1.42,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondaryLight,
        height: 1.33,
        letterSpacing: 0.4,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimaryLight,
        height: 1.42,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondaryLight,
        height: 1.33,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textSecondaryLight,
        height: 1.45,
        letterSpacing: 0.5,
      ),
    );
  }

  static TextTheme get _darkTextTheme {
    return _lightTextTheme.copyWith(
      displayLarge: _lightTextTheme.displayLarge?.copyWith(
        color: textPrimaryDark,
      ),
      displayMedium: _lightTextTheme.displayMedium?.copyWith(
        color: textPrimaryDark,
      ),
      displaySmall: _lightTextTheme.displaySmall?.copyWith(
        color: textPrimaryDark,
      ),
      headlineLarge: _lightTextTheme.headlineLarge?.copyWith(
        color: textPrimaryDark,
      ),
      headlineMedium: _lightTextTheme.headlineMedium?.copyWith(
        color: textPrimaryDark,
      ),
      headlineSmall: _lightTextTheme.headlineSmall?.copyWith(
        color: textPrimaryDark,
      ),
      titleLarge: _lightTextTheme.titleLarge?.copyWith(color: textPrimaryDark),
      titleMedium: _lightTextTheme.titleMedium?.copyWith(
        color: textPrimaryDark,
      ),
      titleSmall: _lightTextTheme.titleSmall?.copyWith(color: textPrimaryDark),
      bodyLarge: _lightTextTheme.bodyLarge?.copyWith(color: textPrimaryDark),
      bodyMedium: _lightTextTheme.bodyMedium?.copyWith(
        color: textSecondaryDark,
      ),
      bodySmall: _lightTextTheme.bodySmall?.copyWith(color: textSecondaryDark),
      labelLarge: _lightTextTheme.labelLarge?.copyWith(color: textPrimaryDark),
      labelMedium: _lightTextTheme.labelMedium?.copyWith(
        color: textSecondaryDark,
      ),
      labelSmall: _lightTextTheme.labelSmall?.copyWith(
        color: textSecondaryDark,
      ),
    );
  }

  // ===== Light Theme =====

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        tertiary: secondaryEmerald,
        surface: surfaceLight,
        error: expenseColor,
      ),
      scaffoldBackgroundColor: backgroundLight,
      textTheme: _lightTextTheme,
      visualDensity: VisualDensity.compact,

      // Component Themes
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: primaryColor.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: surfaceLight,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: surfaceLight,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
        ),
        iconTheme: const IconThemeData(color: textPrimaryLight, size: 24),
        actionsIconTheme: const IconThemeData(
          color: textPrimaryLight,
          size: 24,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: expenseColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: textSecondaryLight,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: textSecondaryLight,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF0F0F0),
        selectedColor: primaryColor,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      iconTheme: const IconThemeData(size: 24, color: textPrimaryLight),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor;
          }
          return const Color(0xFFB0B0B0);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor.withValues(alpha: 0.3);
          }
          return const Color(0xFFE0E0E0);
        }),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor,
        inactiveTrackColor: const Color(0xFFE0E0E0),
        thumbColor: accentColor,
        activeTickMarkColor: accentColor,
        overlayColor: accentColor.withValues(alpha: 0.2),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: textSecondaryLight,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceLight,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceLight,
        indicatorColor: accentColor.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            );
          }
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondaryLight,
          );
        }),
      ),
    );
  }

  // ===== Dark Theme =====

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary:
            accentColor, // Use accentColor for primary in dark mode for better visibility
        secondary: accentColor,
        tertiary: secondaryEmerald,
        surface: surfaceDark,
        error: expenseColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: backgroundDark,
      textTheme: _darkTextTheme,
      visualDensity: VisualDensity.compact,

      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: primaryColor.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: surfaceDark,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor:
              accentColor, // Corrected to accentColor for dark mode
          side: const BorderSide(color: accentColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor:
              accentColor, // Use accentColor for visibility in dark mode
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
        actionsIconTheme: const IconThemeData(color: Colors.white, size: 24),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: expenseColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: textSecondaryDark,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: textSecondaryDark,
        ),
      ),

      iconTheme: const IconThemeData(size: 24, color: textPrimaryDark),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor;
          }
          return const Color(0xFF606060);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor.withValues(alpha: 0.3);
          }
          return const Color(0xFF404040);
        }),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: textSecondaryDark,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark,
        indicatorColor: accentColor.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accentColor,
            );
          }
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondaryDark,
          );
        }),
      ),
    );
  }

  // ===== Utility Methods =====

  /// Get category icon based on category name
  static IconData getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase().trim();
    switch (name) {
      // Expense categories
      case 'groceries':
      case 'supermarket':
        return Icons.local_grocery_store;
      case 'rent':
      case 'housing':
      case 'mortgage':
        return Icons.home;
      case 'electricity':
      case 'light':
      case 'power':
        return Icons.electrical_services;
      case 'mobile':
      case 'wifi':
      case 'recharge':
      case 'mobile/wifi':
        return Icons.wifi;
      case 'petrol':
      case 'fuel':
      case 'petrol/fuel':
      case 'gas station':
        return Icons.local_gas_station;
      case 'emi':
      case 'loan':
        return Icons.credit_card;
      case 'health':
      case 'medical':
      case 'medicine':
      case 'pharmacy':
      case 'doctor':
      case 'hospital':
        return Icons.medical_services;
      case 'food':
      case 'food/dining':
      case 'dining':
      case 'restaurant':
      case 'cafe':
      case 'coffee':
        return Icons.restaurant;
      case 'school fees':
      case 'education':
      case 'school':
      case 'fees':
      case 'college':
      case 'courses':
        return Icons.school;
      case 'maid':
      case 'cleaning':
      case 'servant':
        return Icons.cleaning_services;
      case 'repair':
      case 'maintenance':
      case 'repairs':
      case 'build':
        return Icons.build;
      case 'shopping':
      case 'mall':
      case 'retail':
      case 'store':
      case 'shopping bag':
        return Icons.shopping_bag;
      case 'travel':
      case 'trip':
      case 'flight':
      case 'train':
      case 'directions car':
        return Icons.directions_car;
      case 'bank':
      case 'sbi':
      case 'bob':
      case 'sbi bank':
      case 'bob bank':
      case 'hdfc':
      case 'icici':
        return Icons.account_balance;
      case 'parking':
        return Icons.local_parking;
      case 'insurance':
      case 'life insurance':
        return Icons.security;
      case 'donations':
        return Icons.volunteer_activism;

      // Income categories
      case 'salary':
      case 'paycheck':
      case 'income':
        return Icons.account_balance_wallet;
      case 'business':
      case 'profit':
      case 'freelance':
      case 'side hustle':
        return Icons.business_center;
      case 'bonus':
      case 'incentive':
        return Icons.redeem;
      case 'gift':
      case 'gifts':
        return Icons.card_giftcard;
      case 'rent income':
      case 'rental':
        return Icons.real_estate_agent;
      case 'interest':
      case 'dividends':
      case 'returns':
      case 'investments':
      case 'stocks':
      case 'mutual funds':
        return Icons.trending_up;
      case 'savings':
        return Icons.savings;

      default:
        // Use a persistent pseudorandom icon based on name sum if no match
        final charSum = name
            .split('')
            .fold<int>(0, (p, c) => p + c.codeUnits[0]);
        final fallbackIcons = [
          Icons.category,
          Icons.stars,
          Icons.account_balance,
          Icons.wallet,
          Icons.savings,
          Icons.payments,
          Icons.style,
          Icons.label,
        ];
        return fallbackIcons[charSum % fallbackIcons.length];
    }
  }

  /// Get category color based on category name and type (income/expense)
  /// Get category color based on category name and type (income/expense)
  static Color getCategoryColor(String categoryName, {bool isIncome = false}) {
    final name = categoryName.toLowerCase().trim();

    // Exact matches for common categories
    if (name.contains('food') ||
        name.contains('dining') ||
        name.contains('groceries')) {
      return const Color(0xFFFF7043);
    }
    if (name.contains('travel') ||
        name.contains('transport') ||
        name.contains('petrol')) {
      return const Color(0xFF42A5F5);
    }
    if (name.contains('shopping') || name.contains('mall')) {
      return const Color(0xFFEC407A);
    }
    if (name.contains('bills') ||
        name.contains('electricity') ||
        name.contains('mobile') ||
        name.contains('wifi')) {
      return const Color(0xFF7E57C2);
    }
    if (name.contains('health') ||
        name.contains('medical') ||
        name.contains('medicine')) {
      return const Color(0xFFEF5350);
    }
    if (name.contains('education') ||
        name.contains('school') ||
        name.contains('fees')) {
      return const Color(0xFF5C6BC0);
    }
    if (name.contains('housing') ||
        name.contains('rent') ||
        name.contains('emi')) {
      return const Color(0xFF26A69A);
    }
    if (name.contains('salary') || name.contains('income')) {
      return const Color(0xFF00C853);
    }
    if (name.contains('business') ||
        name.contains('bonus') ||
        name.contains('gift')) {
      return const Color(0xFFFFCA28);
    }
    if (name.contains('bank') || name.contains('bob') || name.contains('sbi')) {
      return const Color(0xFF455A64);
    }

    // Fallback: Generate a consistent unique color based on the name hash for unknown categories
    final hashData = name.hashCode;
    final h = (hashData.abs() % 360).toDouble();
    return HSVColor.fromAHSV(1.0, h, 0.65, 0.85).toColor();
  }

  /// Format currency with symbol
  static String formatCurrency(double amount, {String symbol = '₹'}) {
    return '$symbol${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  /// Animation duration presets
  static Duration get shortAnimation => const Duration(milliseconds: 200);
  static Duration get mediumAnimation => const Duration(milliseconds: 400);
  static Duration get longAnimation => const Duration(milliseconds: 600);
}
