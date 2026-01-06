import 'package:finflow/models/category.dart';
import 'package:finflow/models/transaction.dart';
import 'package:finflow/services/db_service.dart';
import 'package:finflow/services/category_service.dart';
import 'package:finflow/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DemoDataService {
  final DBService _dbService = DBService();
  final CategoryService _categoryService = CategoryService();

  Future<void> loadDemoData(BuildContext context) async {
    try {
      // Clear existing data first
      await _clearExistingData();
      if (!context.mounted) return;

      // Add default categories
      await _addDefaultCategories();
      if (!context.mounted) return;

      // Add sample transactions
      await _addSampleTransactions();
      if (!context.mounted) return;

      // Refresh the UI
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      await transactionProvider.refreshTransactions();
      if (!context.mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demo data loaded successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading demo data: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _clearExistingData() async {
    // Clear transactions
    final db = await _dbService.database;
    await db.delete('transactions');

    // Clear categories
    await db.delete('categories');
  }

  Future<void> _addDefaultCategories() async {
    final defaultCategories = [
      Category(name: 'Salary', icon: 'attach_money', color: '4CAF50', type: 'income'),
      Category(name: 'Freelance', icon: 'work', color: 'FFC107', type: 'income'),
      Category(name: 'Investments', icon: 'trending_up', color: '2196F3', type: 'income'),
      Category(name: 'Gifts', icon: 'card_giftcard', color: 'E91E63', type: 'income'),

      Category(name: 'Food', icon: 'fastfood', color: 'FF5722', type: 'expense'),
      Category(name: 'Housing', icon: 'home', color: '607D8B', type: 'expense'),
      Category(name: 'Bills', icon: 'receipt', color: '9C27B0', type: 'expense'),
      Category(name: 'Travel', icon: 'directions_bus', color: 'FF9800', type: 'expense'),
      Category(name: 'Shopping', icon: 'shopping_bag', color: 'E91E63', type: 'expense'),
      Category(name: 'Entertainment', icon: 'movie', color: '795548', type: 'expense'),
      Category(name: 'Health', icon: 'local_hospital', color: 'F44336', type: 'expense'),
      Category(name: 'Transport', icon: 'directions_car', color: '673AB7', type: 'expense'),
    ];

    for (final category in defaultCategories) {
      await _dbService.insertCategory(category.toMap());
    }
  }

  Future<void> _addSampleTransactions() async {
    final now = DateTime.now();
    final categories = await _categoryService.getAllCategories();

    // Find category IDs - only those that are used in sample transactions
    final salaryCategory = categories.firstWhere((c) => c.name == 'Salary');
    final freelanceCategory = categories.firstWhere((c) => c.name == 'Freelance');
    final investmentsCategory = categories.firstWhere((c) => c.name == 'Investments');
    final foodCategory = categories.firstWhere((c) => c.name == 'Food');
    final housingCategory = categories.firstWhere((c) => c.name == 'Housing');
    final billsCategory = categories.firstWhere((c) => c.name == 'Bills');
    final entertainmentCategory = categories.firstWhere((c) => c.name == 'Entertainment');
    final transportCategory = categories.firstWhere((c) => c.name == 'Transport');

    // Sample transactions
    final sampleTransactions = [
      // Income transactions
      Transaction(
        description: 'Monthly Salary',
        categoryName: 'Salary',
        amount: 50000.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, 1),
        categoryId: salaryCategory.id!,
        type: 'income',
        accountId: 1,
        notes: 'Regular monthly salary',
      ),
      Transaction(
        description: 'Freelance Project',
        categoryName: 'Freelance',
        amount: 15000.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, 5),
        categoryId: freelanceCategory.id!,
        type: 'income',
        accountId: 1,
        notes: 'Web development project',
      ),
      Transaction(
        description: 'Stock Dividends',
        categoryName: 'Investments',
        amount: 7500.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, 10),
        categoryId: investmentsCategory.id!,
        type: 'income',
        accountId: 1,
        notes: 'Quarterly dividends',
      ),
      Transaction(
        description: 'Consulting Fee',
        categoryName: 'Freelance',
        amount: 12000.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, 15),
        categoryId: freelanceCategory.id!,
        type: 'income',
        accountId: 1,
        notes: 'Business consulting',
      ),
      Transaction(
        description: 'Bonus Payment',
        categoryName: 'Salary',
        amount: 10000.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, 20),
        categoryId: salaryCategory.id!,
        type: 'income',
        accountId: 1,
        notes: 'Performance bonus',
      ),

      // Expense transactions
      Transaction(
        description: 'Grocery Shopping',
        categoryName: 'Food',
        amount: 2500.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, 2),
        categoryId: foodCategory.id!,
        type: 'expense',
        accountId: 1,
        notes: 'Weekly groceries',
      ),
      Transaction(
        description: 'Rent Payment',
        categoryName: 'Housing',
        amount: 15000.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, 3),
        categoryId: housingCategory.id!,
        type: 'expense',
        accountId: 1,
        notes: 'Monthly rent',
      ),
      Transaction(
        description: 'Electricity Bill',
        categoryName: 'Bills',
        amount: 1800.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, 4),
        categoryId: billsCategory.id!,
        type: 'expense',
        accountId: 1,
        notes: 'Monthly electricity',
      ),
      Transaction(
        description: 'Uber Ride',
        categoryName: 'Transport',
        amount: 850.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, 5),
        categoryId: transportCategory.id!,
        type: 'expense',
        accountId: 1,
        notes: 'Airport ride',
      ),
      Transaction(
        description: 'Movie Tickets',
        categoryName: 'Entertainment',
        amount: 1200.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, 6),
        categoryId: entertainmentCategory.id!,
        type: 'expense',
        accountId: 1,
        notes: 'Weekend movie',
      ),
    ];

    for (final transaction in sampleTransactions) {
      await _dbService.insertTransaction(transaction.toMap());
    }
  }
}
