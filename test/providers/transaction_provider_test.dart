import 'package:flutter_test/flutter_test.dart';
import 'package:finflow/models/transaction.dart';
import 'package:finflow/providers/transaction_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

void main() {
  // Initialize FFI
  sqflite_ffi.sqfliteFfiInit();
  sqflite_ffi.databaseFactory = sqflite_ffi.databaseFactoryFfi;

  group('TransactionProvider', () {
    late TransactionProvider transactionProvider;

    setUp(() {
      transactionProvider = TransactionProvider();
    });

    test('add and delete transaction', () async {
      final transaction = Transaction(
        id: 1,
        description: 'Test Transaction',
        amount: 100.0,
        date: DateTime.now(),
        categoryId: 1,
        categoryName: 'Test Category',
        type: 'expense',
        accountId: 1,
        currencyCode: 'USD',
      );

      await transactionProvider.addTransaction(transaction);
      expect(transactionProvider.transactions.length, 1);
      expect(transactionProvider.transactions.first.description, 'Test Transaction');

      await transactionProvider.deleteTransaction(1);
      expect(transactionProvider.transactions.isEmpty, true);
    });
  });
}
