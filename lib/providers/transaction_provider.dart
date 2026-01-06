import 'dart:convert';
import 'dart:io';
import 'package:finflow/utils/utility.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/db_service.dart';
import '../models/transaction.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];

  final Map<int, String> _categoryMap = {
    1: 'Food',
    2: 'Travel',
    3: 'Bills',
    4: 'Shopping',
    6: 'Salary',
    7: 'Freelance',
    8: 'Investments',
  };

  // Currency settings
  String _currencySymbol = '₹'; // Default to INR
  String _currencyCode = 'INR'; // Default to INR

  TransactionProvider() {
    _loadTransactions();
    // In a real app, you would load currency settings from persistent storage here
    // For now, we'll use defaults.
  }

  List<Transaction> get transactions => _transactions;

  String get currencySymbol => _currencySymbol;
  String get currencyCode => _currencyCode;

  // Method to change currency
  void changeCurrency(String symbol, String code) {
    _currencySymbol = symbol;
    _currencyCode = code;
    // In a real app, you would save this to persistent storage
    notifyListeners();
  }

  Future<void> _loadTransactions() async {
    final dbService = DBService();
    final transactionsMap = await dbService.getTransactions();
    _transactions = transactionsMap.map((txMap) => Transaction.fromMap(txMap)).toList();

    // Add dummy transactions if database is empty
    if (_transactions.isEmpty) {
      await _addDummyTransactions();
      // Reload after adding dummy transactions
      final updatedTransactionsMap = await dbService.getTransactions();
      _transactions = updatedTransactionsMap.map((txMap) => Transaction.fromMap(txMap)).toList();
    }

    // Sort transactions by date (newest first)
    _transactions.sort((a, b) => b.date.compareTo(a.date));

    notifyListeners();
  }

  Future<void> refreshTransactions() async {
    await _loadTransactions();
  }

  Future<void> addTransaction(Transaction transaction) async {
    final dbService = DBService();
    await dbService.insertTransaction(transaction.toMap());
    await _loadTransactions();
  }

  Transaction? _lastRemovedTransaction;
  int? _lastRemovedTransactionIndex;

  Future<void> updateTransaction(Transaction transaction) async {
    final dbService = DBService();
    await dbService.updateTransaction(transaction.toMap());
    await _loadTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    final dbService = DBService();
    // Optimistically remove from list for snappy UI
    final index = _transactions.indexWhere((tx) => tx.id == id);
    if (index != -1) {
      _lastRemovedTransaction = _transactions.removeAt(index);
      _lastRemovedTransactionIndex = index;
      notifyListeners();

      // Now delete from database
      await dbService.deleteTransaction(id);

      // Refresh from database to ensure consistency
      await _loadTransactions();
    }
  }

  Future<void> undoDelete() async {
    if (_lastRemovedTransaction != null && _lastRemovedTransactionIndex != null) {
      final dbService = DBService();
      // Re-insert into database
      await dbService.insertTransaction(_lastRemovedTransaction!.toMap());
      // Re-insert into list locally and refresh from DB to ensure consistency
      // _transactions.insert(_lastRemovedTransactionIndex!, _lastRemovedTransaction!);
      await _loadTransactions(); // Reload to get the correct state from DB
      
      _lastRemovedTransaction = null;
      _lastRemovedTransactionIndex = null;
      notifyListeners();
    }
  }

  Future<List<Transaction>> getRecurringTransactions() async {
    // This should be implemented in DBService if needed
    return [];
  }

  double get totalIncome {
    return _transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalExpense {
    return _transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get balance {
    return totalIncome - totalExpense;
  }

  // Pre-calculate expense data for the dashboard
  Map<String, double> get expenseData {
    final Map<String, double> expenseByCategory = {};
    for (var transaction in _transactions) {
      if (transaction.type == 'expense') {
        final category = _categoryMap[transaction.categoryId] ?? 'Misc';
        final amount = transaction.amount;
        expenseByCategory.update(category, (value) => value + amount, ifAbsent: () => amount);
      }
    }
    return expenseByCategory;
  }

  // Pre-calculate income data for stats
  Map<String, double> get incomeData {
    final Map<String, double> incomeByCategory = {};
    for (var transaction in _transactions) {
      if (transaction.type == 'income') {
        final category = _categoryMap[transaction.categoryId] ?? 'Misc';
        final amount = transaction.amount;
        incomeByCategory.update(category, (value) => value + amount, ifAbsent: () => amount);
      }
    }
    return incomeByCategory;
  }

  Map<String, double> getMonthlyReport(int year, int month) {
    final monthlyTransactions = _transactions.where((t) {
      return t.date.year == year && t.date.month == month;
    }).toList();

    final income = monthlyTransactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, item) => sum + item.amount);

    final expense = monthlyTransactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, item) => sum + item.amount);

    return {'income': income, 'expense': expense};
  }

  Map<int, double> get weeklyExpenses {
    final Map<int, double> weeklyExpenses = {};
    final today = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final weekDay = today.subtract(Duration(days: i));
      double total = 0.0;
      for (var transaction in _transactions) {
        if (transaction.date.day == weekDay.day &&
            transaction.date.month == weekDay.month &&
            transaction.date.year == weekDay.year &&
            transaction.type == 'expense') {
          total += transaction.amount;
        }
      }
      weeklyExpenses[i] = total;
    }
    return weeklyExpenses;
  }

  Future<void> exportTransactionsCsv(BuildContext context) async {
    try {
      List<List<dynamic>> rows = [];
      // Add comprehensive CSV headers
      rows.add([
        'ID', 'Description', 'Amount', 'Currency', 'Date', 'Category ID',
        'Category Name', 'Type', 'Account ID', 'Notes', 'Is Recurring',
        'Recurrence Frequency', 'Recurrence End Date', 'Attachment Path'
      ]);

      for (var transaction in _transactions) {
        rows.add([
          transaction.id ?? '',
          transaction.description,
          transaction.amount,
          transaction.currencyCode,
          transaction.date.toIso8601String(),
          transaction.categoryId,
          transaction.categoryName,
          transaction.type,
          transaction.accountId,
          transaction.notes ?? '',
          transaction.isRecurring ? 'Yes' : 'No',
          transaction.recurrenceFrequency ?? '',
          transaction.recurrenceEndDate?.toIso8601String() ?? '',
          transaction.attachmentPath ?? ''
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);
      
      // Use temporary directory to avoid storage permission issues
      final tempDir = await getTemporaryDirectory();
      if (!context.mounted) return;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${tempDir.path}/transactions_export_$timestamp.csv';
      final file = File(path);
      await file.writeAsString(csv);
      if (!context.mounted) return;

      // Share using share_plus - no storage permissions needed
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'text/csv')],
          subject: 'FinFlow Transaction Data',
          text: 'Financial transaction data exported on ${DateTime.now().toString().split(' ')[0]}',
        ),
      );
      if (!context.mounted) return;
      
      showSnackBar(context, 'Transactions exported successfully');
    } catch (e) {
      if (!context.mounted) return;
      showSnackBar(context, 'An error occurred: $e');
    }
  }

  Future<void> importTransactionsJson(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (!context.mounted) return;

      if (result != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        if (!context.mounted) return;
        final List<dynamic> jsonData = json.decode(content);

        final dbService = DBService();
        for (var item in jsonData) {
          final transaction = Transaction.fromMap(item);
          await dbService.insertTransaction(transaction.toMap());
        }

        await _loadTransactions();
        if (!context.mounted) return;
        showSnackBar(context, 'Transactions imported successfully');
      } else {
        showSnackBar(context, 'No file selected');
      }
    } catch (e) {
      if (!context.mounted) return;
      showSnackBar(context, 'An error occurred during import: $e');
    }
  }

  Future<void> _addDummyTransactions() async {
    final dbService = DBService();
    final now = DateTime.now();
    
    // Create 5 dummy income transactions
    final List<Transaction> dummyIncomeTransactions = [
      Transaction(
        description: 'Salary Deposit',
        categoryName: 'Salary',
        amount: 50000.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, now.day - 2),
        categoryId: 6, // Salary
        type: 'income',
        accountId: 1,
        notes: 'Monthly salary',
      ),
      Transaction(
        description: 'Freelance Work',
        categoryName: 'Freelance',
        amount: 15000.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, now.day - 5),
        categoryId: 7, // Freelance
        type: 'income',
        accountId: 1,
        notes: 'Web development project',
      ),
      Transaction(
        description: 'Stock Dividends',
        categoryName: 'Investments',
        amount: 7500.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, now.day - 7),
        categoryId: 8, // Investments
        type: 'income',
        accountId: 1,
        notes: 'Quarterly dividends',
      ),
      Transaction(
        description: 'Consulting Fee',
        categoryName: 'Freelance',
        amount: 12000.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, now.day - 10),
        categoryId: 7, // Freelance
        type: 'income',
        accountId: 1,
        notes: 'Business consulting',
      ),
      Transaction(
        description: 'Bonus Payment',
        categoryName: 'Salary',
        amount: 10000.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, now.day - 12),
        categoryId: 6, // Salary
        type: 'income',
        accountId: 1,
        notes: 'Performance bonus',
      ),
    ];

    // Create 5 dummy expense transactions
    final List<Transaction> dummyExpenseTransactions = [
      Transaction(
        description: 'Grocery Shopping',
        categoryName: 'Food',
        amount: 2500.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, now.day - 1),
        categoryId: 1, // Food
        type: 'expense',
        accountId: 1,
        notes: 'Weekly groceries',
      ),
      Transaction(
        description: 'Uber Ride to Airport',
        categoryName: 'Travel',
        amount: 850.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, now.day - 3),
        categoryId: 2, // Travel
        type: 'expense',
        accountId: 1,
        notes: 'Airport ride',
      ),
      Transaction(
        description: 'Electricity Bill',
        categoryName: 'Bills',
        amount: 1800.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, now.day - 6),
        categoryId: 3, // Bills
        type: 'expense',
        accountId: 1,
        notes: 'Monthly electricity',
      ),
      Transaction(
        description: 'Clothing Purchase',
        categoryName: 'Shopping',
        amount: 3200.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, now.day - 8),
        categoryId: 4, // Shopping
        type: 'expense',
        accountId: 1,
        notes: 'New winter clothes',
      ),
      Transaction(
        description: 'Restaurant Dinner',
        categoryName: 'Food',
        amount: 1800.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, now.day - 9),
        categoryId: 1, // Food
        type: 'expense',
        accountId: 1,
        notes: 'Family dinner',
      ),
    ];

    // Combine all dummy transactions
    final List<Transaction> dummyTransactions = [
      ...dummyIncomeTransactions,
      ...dummyExpenseTransactions,
    ];

    for (var transaction in dummyTransactions) {
      await dbService.insertTransaction(transaction.toMap());
    }
  }
}
