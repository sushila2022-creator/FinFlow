import 'package:flutter_test/flutter_test.dart';
import 'package:finflow/models/transaction.dart';

void main() {
  group('TransactionModel', () {
    test('toMap() and fromMap()', () {
      final transaction = Transaction(
        id: 1,
        description: 'Groceries',
        amount: 50.0,
        date: DateTime.now(),
        currencyCode: 'USD',
        categoryId: 1,
        categoryName: 'Food',
        type: 'expense',
        accountId: 1,
      );

      final map = transaction.toMap();
      final fromMapTransaction = Transaction.fromMap(map);

      expect(fromMapTransaction.id, transaction.id);
      expect(fromMapTransaction.description, transaction.description);
      expect(fromMapTransaction.amount, transaction.amount);
      expect(fromMapTransaction.date.toIso8601String(), transaction.date.toIso8601String());
      expect(fromMapTransaction.currencyCode, transaction.currencyCode);
      expect(fromMapTransaction.categoryId, transaction.categoryId);
      expect(fromMapTransaction.accountId, transaction.accountId);
    });
  });
}
