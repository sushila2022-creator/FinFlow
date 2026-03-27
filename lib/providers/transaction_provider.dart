import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/transaction.dart';
import '../utils/utility.dart';

class TransactionProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _transactionsSubscription;
  List<Transaction> _transactions = [];
  bool _isInitialized = false;
  bool _isLoading = false;

  // Public getter for initialization status
  bool get isInitialized => _isInitialized;

  // Computed values
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _totalBalance = 0;

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
  String _currencySymbol = '₹';
  String _currencyCode = 'INR';

  TransactionProvider() {
    // Initialize without immediate data loading to improve startup performance
    _initializeProviders();
  }

  void _initializeProviders() {
    // Initialize currency and theme providers without loading transactions
    _currencySymbol = '₹';
    _currencyCode = 'INR';
  }

  Future<void> initializeTransactions() async {
    if (_isInitialized || _isLoading) return;

    _isLoading = true;
    _isInitialized = true;

    try {
      // Load initial data with limit to improve performance
      final snapshot = await _firestore
          .collection('transactions')
          .orderBy('date', descending: true)
          .limit(50) // Limit initial load
          .get();

      _transactions = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Transaction.fromJson(data);
      }).toList();

      _calculateTotals();
      notifyListeners();

      // Start listening for real-time updates after initial load
      _startRealTimeListener();
    } catch (e) {
      debugPrint('Failed to initialize transactions: $e');
      _isInitialized = false;
    } finally {
      _isLoading = false;
    }
  }

  void _startRealTimeListener() {
    try {
      _transactionsSubscription = _firestore
          .collection('transactions')
          .orderBy('date', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              try {
                _transactions = snapshot.docs.map((doc) {
                  final data = doc.data();
                  data['id'] = doc.id;
                  return Transaction.fromJson(data);
                }).toList();

                _calculateTotals();
                notifyListeners();
              } catch (e) {
                debugPrint('Error processing transactions snapshot: $e');
              }
            },
            onError: (error) {
              debugPrint('Error listening to transactions stream: $error');
            },
          );
    } catch (e) {
      debugPrint('Failed to start real-time listener: $e');
    }
  }

  void _calculateTotals() {
    _totalIncome = _transactions
        .where((t) => t.isIncome)
        .fold(0.0, (total, item) => total + item.amount);

    _totalExpense = _transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (total, item) => total + item.amount);

    _totalBalance = _totalIncome - _totalExpense;
  }

  List<Transaction> get transactions => _transactions;

  // Optimized getters using computed values
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get totalBalance => _totalBalance;
  double get balance =>
      _totalBalance; // Alias for totalBalance for compatibility

  String get currencySymbol => _currencySymbol;
  String get currencyCode => _currencyCode;

  void changeCurrency(String symbol, String code) {
    _currencySymbol = symbol;
    _currencyCode = code;
    notifyListeners();
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      await _firestore
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.toJson());
    } catch (e) {
      debugPrint('Error adding transaction: $e');
      rethrow;
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await _firestore
          .collection('transactions')
          .doc(transaction.id)
          .update(transaction.toJson());
    } catch (e) {
      debugPrint('Error updating transaction: $e');
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _firestore.collection('transactions').doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      rethrow;
    }
  }

  Future<void> refreshTransactions() async {
    notifyListeners();
  }

  Future<List<Transaction>> getRecurringTransactions() async {
    return _transactions.where((t) => t.isRecurring).toList();
  }

  // Pre-calculate expense data for the dashboard
  Map<String, double> get expenseData {
    final Map<String, double> expenseByCategory = {};
    for (var transaction in _transactions) {
      if (!transaction.isIncome) {
        final category =
            _categoryMap[transaction.categoryId] ?? transaction.category;
        final amount = transaction.amount;
        expenseByCategory.update(
          category,
          (value) => value + amount,
          ifAbsent: () => amount,
        );
      }
    }
    return expenseByCategory;
  }

  // Pre-calculate income data for stats
  Map<String, double> get incomeData {
    final Map<String, double> incomeByCategory = {};
    for (var transaction in _transactions) {
      if (transaction.isIncome) {
        final category =
            _categoryMap[transaction.categoryId] ?? transaction.category;
        final amount = transaction.amount;
        incomeByCategory.update(
          category,
          (value) => value + amount,
          ifAbsent: () => amount,
        );
      }
    }
    return incomeByCategory;
  }

  Map<String, double> getMonthlyReport(int year, int month) {
    final monthlyTransactions = _transactions.where((t) {
      return t.date.year == year && t.date.month == month;
    }).toList();

    final income = monthlyTransactions
        .where((t) => t.isIncome)
        .fold(0.0, (total, item) => total + item.amount);

    final expense = monthlyTransactions
        .where((t) => !t.isIncome)
        .fold(0.0, (total, item) => total + item.amount);

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
            !transaction.isIncome) {
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
      rows.add([
        'ID',
        'Description',
        'Amount',
        'Currency',
        'Date',
        'Category ID',
        'Category Name',
        'Type',
        'Account ID',
        'Notes',
        'Is Recurring',
        'Recurrence Frequency',
        'Recurrence End Date',
        'Attachment Path',
      ]);

      for (var transaction in _transactions) {
        rows.add([
          transaction.id,
          transaction.description,
          transaction.amount,
          transaction.currencyCode,
          transaction.date.toIso8601String(),
          transaction.categoryId,
          transaction.category,
          transaction.type,
          transaction.accountId,
          transaction.notes ?? '',
          transaction.isRecurring ? 'Yes' : 'No',
          transaction.recurrenceFrequency ?? '',
          transaction.recurrenceEndDate?.toIso8601String() ?? '',
          transaction.attachmentPath ?? '',
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);

      final tempDir = await getTemporaryDirectory();
      if (!context.mounted) return;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${tempDir.path}/transactions_export_$timestamp.csv';
      final file = File(path);
      await file.writeAsString(csv);
      if (!context.mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'text/csv')],
          subject: 'FinFlow Transaction Data',
          text:
              'Financial transaction data exported on ${DateTime.now().toString().split(' ')[0]}',
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

        final batch = _firestore.batch();
        for (var item in jsonData) {
          final transaction = Transaction.fromMap(item);
          batch.set(
            _firestore.collection('transactions').doc(transaction.id),
            transaction.toJson(),
          );
        }

        await batch.commit();
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

  @override
  void dispose() {
    _transactionsSubscription?.cancel();
    super.dispose();
  }
}
