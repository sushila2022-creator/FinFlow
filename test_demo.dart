import 'package:finflow/utils/utility.dart';
import 'package:flutter/foundation.dart';

void main() {
  // Test the Indian Numbering System formatting
  debugPrint('Indian Numbering System Formatting Demo:');
  debugPrint('==========================================');

  // Test cases
  final testCases = [
    150000.50,
    10000000.00,
    1234.56,
    50000.00,
    0.00,
    123456789.12
  ];

  for (final amount in testCases) {
    final formatted = formatIndianCurrency(amount);
    debugPrint('Amount: $amount -> Formatted: $formatted');
  }

  // Test with different currency symbols
  debugPrint('\nTesting with different currency symbols:');
  debugPrint('===========================================');
  final amount = 150000.50;
  final symbols = ['₹', '\$', '€', '£'];
  for (final symbol in symbols) {
    final formatted = formatIndianCurrency(amount, symbol: symbol);
    debugPrint('Amount: $amount with symbol $symbol -> Formatted: $formatted');
  }
}
