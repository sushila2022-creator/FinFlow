import 'package:flutter/foundation.dart';
import 'package:finflow/models/transaction.dart' as finflow;

void main() {
  debugPrint('✅ Database initialized successfully');

  // Test 1: Create a new transaction
  final transaction = finflow.Transaction(
    userId: 'test-user-id',
    title: 'Test Transaction', // Added title parameter
    description: 'Test transaction',
    amount: 1000.0,
    currencyCode: 'INR',
    date: DateTime.now(),
    category: 'Test Category',
    categoryId: 1,
    isIncome: false,
    accountId: 1,
  );

  debugPrint('✅ Transaction created successfully: ${transaction.id}');
  debugPrint(
    'Transaction details: ${transaction.title} - ₹${transaction.amount} - ${transaction.category}',
  );
}
