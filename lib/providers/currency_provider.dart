import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finflow/utils/debug_logger.dart';

/// Optimized CurrencyProvider with deferred async initialization
///
/// Performance optimizations:
/// 1. Starts with default currency immediately (no waiting)
/// 2. Loads saved currency asynchronously after first frame
/// 3. Uses Future.microtask for non-blocking initialization
class CurrencyProvider with ChangeNotifier {
  static const String _currencySymbolKey = 'currency_symbol';
  static const String _defaultCurrencySymbol = '\$'; // US Dollar
  static const String _defaultCurrencyName = 'US Dollar';

  // Start with default currency immediately - no waiting
  String _currentCurrencySymbol = _defaultCurrencySymbol;
  String _currentCurrencyName = _defaultCurrencyName;
  bool _isInitialized = false;

  // Getters for current currency
  String get currentCurrencySymbol => _currentCurrencySymbol;
  String get currentCurrencyName => _currentCurrencyName;
  bool get isInitialized => _isInitialized;

  // Getter for selected currency (as an object with symbol property)
  Map<String, String> get selectedCurrency => {
    'symbol': _currentCurrencySymbol,
    'name': _currentCurrencyName,
  };

  // Get currency code from symbol
  String get currentCurrencyCode => _getCurrencyCode(_currentCurrencySymbol);

  /// Initialize currency provider
  /// Loads saved currency asynchronously without blocking UI
  CurrencyProvider() {
    // Use Future.microtask to defer loading until after current event loop
    // This ensures the UI renders with default currency immediately
    Future.microtask(() => _loadCurrency());
  }

  // Load saved currency from SharedPreferences (async, non-blocking)
  Future<void> _loadCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSymbol = prefs.getString(_currencySymbolKey);

      if (savedSymbol != null && savedSymbol.isNotEmpty) {
        _currentCurrencySymbol = savedSymbol;
        _currentCurrencyName = _getCurrencyName(savedSymbol);
      }
      // If no saved currency, keep default
    } catch (e) {
      // Failed to load saved currency - keep default
      logError(
        'Failed to load saved currency',
        tag: 'CurrencyProvider',
        error: e,
      );
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Set currency and save to SharedPreferences immediately
  Future<void> setCurrency(String symbol) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencySymbolKey, symbol);

      _currentCurrencySymbol = symbol;
      _currentCurrencyName = _getCurrencyName(symbol);
    } catch (e) {
      logError('Failed to save currency', tag: 'CurrencyProvider', error: e);
    }
    notifyListeners();
  }

  // Get currency name for display purposes
  String _getCurrencyName(String symbol) {
    final currency = getAvailableCurrencies().firstWhere(
      (c) => c['symbol'] == symbol,
      orElse: () => {'name': 'US Dollar', 'symbol': '\$'},
    );
    return currency['name']!;
  }

  // Get currency code from symbol
  String _getCurrencyCode(String symbol) {
    // Basic mapping for major currencies, defaulting to USD
    switch (symbol) {
      case '₹':
        return 'INR';
      case '\$':
        return 'USD';
      case '€':
        return 'EUR';
      case '£':
        return 'GBP';
      case '¥':
        return 'JPY';
      case 'A\$':
        return 'AUD';
      case 'C\$':
        return 'CAD';
      case 'CHF':
        return 'CHF';
      case 'د.إ':
        return 'AED';
      case 'ر.س':
        return 'SAR';
      case 'S\$':
        return 'SGD';
      case 'HK\$':
        return 'HKD';
      case '₩':
        return 'KRW';
      case '₺':
        return 'TRY';
      case 'R\$':
        return 'BRL';
      case 'kr':
        return 'SEK'; // Note: Ambiguous, could be NOK/SEK/DKK
      case 'NZ\$':
        return 'NZD';
      default:
        return 'USD';
    }
  }

  // Comprehensive list of available currencies (Single Source of Truth)
  static List<Map<String, String>> getAvailableCurrencies() {
    return [
      {'name': 'US Dollar', 'symbol': '\$'},
      {'name': 'Euro', 'symbol': '€'},
      {'name': 'British Pound', 'symbol': '£'},
      {'name': 'Japanese Yen', 'symbol': '¥'},
      {'name': 'Australian Dollar', 'symbol': 'A\$'},
      {'name': 'Canadian Dollar', 'symbol': 'C\$'},
      {'name': 'Swiss Franc', 'symbol': 'CHF'},
      {'name': 'Chinese Yuan', 'symbol': '¥'},
      {'name': 'UAE Dirham', 'symbol': 'د.إ'},
      {'name': 'Saudi Riyal', 'symbol': 'ر.س'},
      {'name': 'Indian Rupee', 'symbol': '₹'},
      {'name': 'Singapore Dollar', 'symbol': 'S\$'},
      {'name': 'Hong Kong Dollar', 'symbol': 'HK\$'},
      {'name': 'South Korean Won', 'symbol': '₩'},
      {'name': 'Turkish Lira', 'symbol': '₺'},
      {'name': 'Brazilian Real', 'symbol': 'R\$'},
      {'name': 'Mexican Peso', 'symbol': '\$'},
      {'name': 'Swedish Krona', 'symbol': 'kr'},
      {'name': 'Norwegian Krone', 'symbol': 'kr'},
      {'name': 'New Zealand Dollar', 'symbol': 'NZ\$'},
    ];
  }
}
