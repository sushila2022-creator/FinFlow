import 'package:shared_preferences/shared_preferences.dart';
import 'package:finflow/utils/debug_logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

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
  static const String _exchangeRatesKey = 'exchange_rates';
  static const String _lastUpdateKey = 'exchange_rates_last_update';
  static const int _exchangeRateCacheDuration = 3600; // 1 hour in seconds

  // Start with default currency immediately - no waiting
  String _currentCurrencySymbol = _defaultCurrencySymbol;
  String _currentCurrencyName = _defaultCurrencyName;
  bool _isInitialized = false;
  Map<String, double> _exchangeRates = {};
  DateTime _lastExchangeRateUpdate = DateTime.now().subtract(
    const Duration(days: 1),
  );

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

  // Getters for exchange rates
  Map<String, double> get exchangeRates => _exchangeRates;
  DateTime get lastExchangeRateUpdate => _lastExchangeRateUpdate;

  /// Initialize currency provider
  /// Loads saved currency asynchronously without blocking UI
  CurrencyProvider() {
    // Use Future.microtask to defer loading until after current event loop
    // This ensures the UI renders with default currency immediately
    Future.microtask(() => _initializeCurrency());
  }

  // Initialize currency with locale detection and exchange rates
  Future<void> _initializeCurrency() async {
    try {
      // First, try to load saved currency
      final prefs = await SharedPreferences.getInstance();
      final savedSymbol = prefs.getString(_currencySymbolKey);

      if (savedSymbol != null && savedSymbol.isNotEmpty) {
        _currentCurrencySymbol = savedSymbol;
        _currentCurrencyName = _getCurrencyName(savedSymbol);
      } else {
        // No saved currency, detect locale and set default
        await _detectAndSetDefaultCurrency();
      }

      // Load exchange rates
      await _loadExchangeRates();
    } catch (e) {
      logError(
        'Failed to initialize currency provider',
        tag: 'CurrencyProvider',
        error: e,
      );
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Detect device locale and set appropriate default currency
  Future<void> _detectAndSetDefaultCurrency() async {
    try {
      // Get device locale using PlatformDispatcher
      final locale = PlatformDispatcher.instance.locale;
      final countryCode = locale.countryCode;

      logDebug('Detected country code: $countryCode', tag: 'CurrencyProvider');

      // Map country codes to currency symbols
      final countryToCurrency = {
        'IN': '₹', // Indian Rupee
        'US': '\$', // US Dollar
        'GB': '£', // British Pound
        'DE': '€', // Euro (Germany)
        'FR': '€', // Euro (France)
        'IT': '€', // Euro (Italy)
        'ES': '€', // Euro (Spain)
        'JP': '¥', // Japanese Yen
        'AU': 'A\$', // Australian Dollar
        'CA': 'C\$', // Canadian Dollar
        'CH': 'CHF', // Swiss Franc
        'AE': 'د.إ', // UAE Dirham
        'SA': 'ر.س', // Saudi Riyal
        'SG': 'S\$', // Singapore Dollar
        'HK': 'HK\$', // Hong Kong Dollar
        'KR': '₩', // South Korean Won
        'TR': '₺', // Turkish Lira
        'BR': 'R\$', // Brazilian Real
        'MX': '\$', // Mexican Peso
        'SE': 'kr', // Swedish Krona
        'NO': 'kr', // Norwegian Krone
        'NZ': 'NZ\$', // New Zealand Dollar
      };

      final defaultSymbol =
          countryToCurrency[countryCode] ?? _defaultCurrencySymbol;
      _currentCurrencySymbol = defaultSymbol;
      _currentCurrencyName = _getCurrencyName(defaultSymbol);

      // Save the detected currency
      await _saveCurrency(defaultSymbol);
    } catch (e) {
      logError(
        'Failed to detect locale and set default currency',
        tag: 'CurrencyProvider',
        error: e,
      );
    }
  }

  // Load exchange rates from cache or API
  Future<void> _loadExchangeRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedRates = prefs.getString(_exchangeRatesKey);
      final lastUpdate = prefs.getInt(_lastUpdateKey);

      // Check if cached rates are still valid
      if (cachedRates != null && lastUpdate != null) {
        final cacheAge = DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(lastUpdate))
            .inSeconds;
        if (cacheAge < _exchangeRateCacheDuration) {
          _exchangeRates = Map<String, double>.from(
            (json.decode(cachedRates) as Map).map(
              (k, v) => MapEntry(k.toString(), v.toDouble()),
            ),
          );
          _lastExchangeRateUpdate = DateTime.fromMillisecondsSinceEpoch(
            lastUpdate,
          );
          return;
        }
      }

      // Fetch fresh rates from API
      await _fetchExchangeRates();
    } catch (e) {
      logError(
        'Failed to load exchange rates',
        tag: 'CurrencyProvider',
        error: e,
      );
    }
  }

  // Fetch exchange rates from API
  Future<void> _fetchExchangeRates() async {
    try {
      // Using a free API for exchange rates
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        // Convert rates to Map<String, double>
        _exchangeRates = {};
        rates.forEach((key, value) {
          _exchangeRates[key] = value.toDouble();
        });

        // Save rates to cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_exchangeRatesKey, json.encode(_exchangeRates));
        await prefs.setInt(
          _lastUpdateKey,
          DateTime.now().millisecondsSinceEpoch,
        );
        _lastExchangeRateUpdate = DateTime.now();

        // Notify so that TransactionProvider (via ChangeNotifierProxyProvider)
        // recalculates all totals with the freshly fetched rates.
        notifyListeners();

        logDebug(
          'Exchange rates updated successfully',
          tag: 'CurrencyProvider',
        );
      } else {
        logError(
          'Failed to fetch exchange rates: ${response.statusCode}',
          tag: 'CurrencyProvider',
        );
      }
    } catch (e) {
      logError(
        'Error fetching exchange rates',
        tag: 'CurrencyProvider',
        error: e,
      );
    }
  }

  // Convert amount from one currency to another
  double convertAmount(
    double amount,
    String fromCurrencyCode,
    String toCurrencyCode,
  ) {
    if (fromCurrencyCode == toCurrencyCode) return amount;
    if (_exchangeRates.isEmpty) return amount;

    try {
      // The API gives rates relative to USD
      final fromRate = _exchangeRates[fromCurrencyCode];
      final toRate = _exchangeRates[toCurrencyCode];

      if (fromRate == null || toRate == null) {
        logError(
          'Rate not found for $fromCurrencyCode or $toCurrencyCode',
          tag: 'CurrencyProvider',
        );
        return amount;
      }

      // Convert amount to USD first, then to target currency
      final amountInUSD = amount / fromRate;
      final convertedAmount = amountInUSD * toRate;

      return convertedAmount;
    } catch (e) {
      logError('Error converting amount', tag: 'CurrencyProvider', error: e);
      return amount; // Return original amount on error
    }
  }

  // Get formatted amount with current currency symbol (no conversion)
  String formatAmount(double amount, {int decimalPlaces = 2}) {
    final formatter = NumberFormat.currency(
      symbol: _currentCurrencySymbol,
      decimalDigits: decimalPlaces,
    );
    return formatter.format(amount);
  }

  // Get formatted and converted amount
  String formatConvertedAmount(
    double amount,
    String fromCurrencyCode, {
    int decimalPlaces = 2,
  }) {
    final convertedAmount = convertAmount(
      amount,
      fromCurrencyCode,
      currentCurrencyCode,
    );
    return formatAmount(convertedAmount, decimalPlaces: decimalPlaces);
  }

  // Get formatted amount with specific currency symbol
  String formatAmountWithSymbol(
    double amount,
    String symbol, {
    int decimalPlaces = 2,
  }) {
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalPlaces,
    );
    return formatter.format(amount);
  }

  // Set currency and save to SharedPreferences immediately
  Future<void> setCurrency(String symbol) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencySymbolKey, symbol);

      _currentCurrencySymbol = symbol;
      _currentCurrencyName = _getCurrencyName(symbol);

      // Notify listeners so UI updates with new symbol and possibly converted amounts
      notifyListeners();

      // Fetch fresh rates if they are old
      await _loadExchangeRates();
    } catch (e) {
      logError('Failed to save currency', tag: 'CurrencyProvider', error: e);
    }
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

  // Save currency to SharedPreferences
  Future<void> _saveCurrency(String symbol) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencySymbolKey, symbol);
    } catch (e) {
      logError('Failed to save currency', tag: 'CurrencyProvider', error: e);
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
