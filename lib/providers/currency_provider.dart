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
    switch (symbol) {
      case '₹':
        return 'Indian Rupee';
      case '\$':
        return 'US Dollar';
      case '€':
        return 'Euro';
      case '£':
        return 'British Pound';
      case '¥':
        return 'Japanese Yen';
      default:
        return 'US Dollar';
    }
  }

  // Get currency code from symbol
  String _getCurrencyCode(String symbol) {
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
      default:
        return 'USD';
    }
  }

  // List of available currencies
  static List<Map<String, String>> getAvailableCurrencies() {
    return [
      {'name': 'Indian Rupee', 'symbol': '₹'},
      {'name': 'US Dollar', 'symbol': '\$'},
      {'name': 'Euro', 'symbol': '€'},
      {'name': 'British Pound', 'symbol': '£'},
      {'name': 'Japanese Yen', 'symbol': '¥'},
    ];
  }
}
