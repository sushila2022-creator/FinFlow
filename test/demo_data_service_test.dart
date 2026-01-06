import 'package:flutter_test/flutter_test.dart';
import 'package:finflow/services/demo_data_service.dart';
import 'package:finflow/services/db_service.dart';
import 'package:finflow/services/category_service.dart';
import 'package:finflow/models/transaction.dart';
import 'package:finflow/models/category.dart';

void main() {
  group('DemoDataService Tests', () {
    late DemoDataService demoDataService;
    late DBService dbService;
    late CategoryService categoryService;

    setUp(() {
      demoDataService = DemoDataService();
      dbService = DBService();
      categoryService = CategoryService();
    });

    test('DemoDataService should be instantiated', () {
      expect(demoDataService, isNotNull);
      expect(demoDataService, isA<DemoDataService>());
    });

    test('DBService should be instantiated', () {
      expect(dbService, isNotNull);
      expect(dbService, isA<DBService>());
    });

    test('CategoryService should be instantiated', () {
      expect(categoryService, isNotNull);
      expect(categoryService, isA<CategoryService>());
    });

    test('Transaction model should work correctly', () {
      final transaction = Transaction(
        description: 'Test Transaction',
        categoryName: 'Test Category',
        amount: 100.0,
        currencyCode: 'USD',
        date: DateTime.now(),
        categoryId: 1,
        type: 'income',
        accountId: 1,
      );

      expect(transaction, isNotNull);
      expect(transaction.description, 'Test Transaction');
      expect(transaction.amount, 100.0);
      expect(transaction.type, 'income');
    });

    test('Category model should work correctly', () {
      final category = Category(
        name: 'Test Category',
        icon: 'test_icon',
        color: 'FF0000',
        type: 'expense',
      );

      expect(category, isNotNull);
      expect(category.name, 'Test Category');
      expect(category.type, 'expense');
    });
  });
}
