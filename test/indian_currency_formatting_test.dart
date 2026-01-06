import 'package:flutter_test/flutter_test.dart';
import 'package:finflow/utils/utility.dart';

void main() {
  group('Indian Currency Formatting Tests', () {
    test('Test basic Indian currency formatting', () {
      // Test with a simple amount
      final result = formatIndianCurrency(150000.50);
      expect(result, '₹1,50,000.50');
    });

    test('Test large amount formatting', () {
      // Test with a large amount
      final result = formatIndianCurrency(10000000.00);
      expect(result, '₹1,00,00,000.00');
    });

    test('Test small amount formatting', () {
      // Test with a small amount
      final result = formatIndianCurrency(1234.56);
      expect(result, '₹1,234.56');
    });

    test('Test custom symbol formatting', () {
      // Test with custom currency symbol
      final result = formatIndianCurrency(50000.00, symbol: '\$');
      expect(result, '\$50,000.00');
    });

    test('Test zero amount formatting', () {
      // Test with zero amount
      final result = formatIndianCurrency(0.00);
      expect(result, '₹0.00');
    });
  });
}
