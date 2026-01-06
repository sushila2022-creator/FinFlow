import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static const String _currencySymbolKey = 'currency_symbol';
  static const String _defaultCurrencySymbol = '₹'; // Changed from '$' to '₹' (Indian Rupee)
  static const String _defaultCurrencyName = 'Indian Rupee';

  Future<void> setCurrencySymbol(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencySymbolKey, symbol);
  }

  Future<String> getCurrencySymbol() async {
    final prefs = await SharedPreferences.getInstance();
    final currencySymbol = prefs.getString(_currencySymbolKey);
    
    // Force default to 'Indian Rupee' if no currency is saved or if it's null
    if (currencySymbol == null || currencySymbol.isEmpty) {
      // Set the default currency immediately if not set
      await setCurrencySymbol(_defaultCurrencySymbol);
      return _defaultCurrencySymbol;
    }
    
    return currencySymbol;
  }

  // Initialize currency preferences immediately when app starts
  Future<void> initializePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final currencySymbol = prefs.getString(_currencySymbolKey);
    
    // Ensure default currency is set if not already set
    if (currencySymbol == null || currencySymbol.isEmpty) {
      await prefs.setString(_currencySymbolKey, _defaultCurrencySymbol);
    }
  }

  // Get currency name for display purposes
  static String getCurrencyName(String symbol) {
    if (symbol == '₹') {
      return _defaultCurrencyName;
    } else if (symbol == '\$') {
      return 'US Dollar';
    } else if (symbol == '€') {
      return 'Euro';
    } else if (symbol == '£') {
      return 'British Pound';
    } else if (symbol == '¥') {
      return 'Japanese Yen';
    } else {
      return _defaultCurrencyName;
    }
  }
}
