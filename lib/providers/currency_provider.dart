import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider with ChangeNotifier {
  static const String _currencySymbolKey = 'currency_symbol';
  static const String _defaultCurrencySymbol = '\$'; // US Dollar
  static const String _defaultCurrencyName = 'US Dollar';

  String _currentCurrencySymbol = _defaultCurrencySymbol;
  String _currentCurrencyName = _defaultCurrencyName;

  // Getters for current currency
  String get currentCurrencySymbol => _currentCurrencySymbol;
  String get currentCurrencyName => _currentCurrencyName;

  // Getter for selected currency (as an object with symbol property)
  Map<String, String> get selectedCurrency => {
    'symbol': _currentCurrencySymbol,
    'name': _currentCurrencyName,
  };

  // Get currency code from symbol
  String get currentCurrencyCode => _getCurrencyCode(_currentCurrencySymbol);

  // Constructor - automatically loads saved currency
  CurrencyProvider() {
    _loadCurrency();
  }

  // Load saved currency from SharedPreferences
  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSymbol = prefs.getString(_currencySymbolKey);

    if (savedSymbol != null && savedSymbol.isNotEmpty) {
      _currentCurrencySymbol = savedSymbol;
      _currentCurrencyName = _getCurrencyName(savedSymbol);
    } else {
      // Set default currency if none is saved
      await setCurrency(_defaultCurrencySymbol);
    }

    notifyListeners();
  }

  // Set currency and save to SharedPreferences immediately
  Future<void> setCurrency(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencySymbolKey, symbol);

    _currentCurrencySymbol = symbol;
    _currentCurrencyName = _getCurrencyName(symbol);

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
