import 'package:flutter/material.dart';
import 'package:finflow/utils/database_helper.dart';
import 'package:finflow/models/transaction.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('Testing transaction fix...');

  try {
    // Test 1: Create a new transaction
    final transaction = Transaction(
      description: 'Test transaction',
      amount: 1000.0,
      currencyCode: 'INR',
      date: DateTime.now(),
      category: 'Salary',
      categoryId: 1,
      isIncome: true,
      accountId: 1,
    );

    debugPrint(
      'Created transaction: ${transaction.description} - ₹${transaction.amount}',
    );

    // Test 2: Save to database
    final dbHelper = DatabaseHelper.instance;
    final result = await dbHelper.insertTransaction(transaction.toMap());

    debugPrint('Transaction saved successfully with ID: $result');

    // Test 3: Retrieve and verify
    final transactions = await dbHelper.getTransactions();
    debugPrint('Total transactions in database: ${transactions.length}');

    if (transactions.isNotEmpty) {
      final savedTransaction = transactions.first;
      debugPrint('Retrieved transaction:');
      debugPrint('  Description: ${savedTransaction['description']}');
      debugPrint('  Amount: ${savedTransaction['amount']}');
      debugPrint('  Category: ${savedTransaction['category']}');
      debugPrint('  Is Income: ${savedTransaction['isIncome']}');
    }

    debugPrint('✅ Transaction fix test PASSED!');
  } catch (e) {
    debugPrint('❌ Transaction fix test FAILED: $e');
  }
}
