import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction.dart';
import '../utils/utility.dart';
import '../utils/debug_logger.dart';

/// Exception thrown when a user is not authenticated
class UserNotAuthenticatedException implements Exception {
  final String message;
  UserNotAuthenticatedException([
    this.message = 'User must be authenticated to perform this action',
  ]);

  @override
  String toString() => message;
}

class TransactionProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _transactionsSubscription;
  StreamSubscription? _authStateSubscription;
  List<Transaction> _transactions = [];
  bool _isInitialized = false;
  bool _isLoading = false;

  // Get current user ID - throws if not authenticated
  String get currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw UserNotAuthenticatedException('No authenticated user found');
    }
    return user.uid;
  }

  // Get current user ID safely (returns null if not authenticated)
  String? get currentUserIdOrNull => _auth.currentUser?.uid;

  // Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

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
    // Defer auth state listener setup to avoid Firebase access during startup
    Future.microtask(() => _setupAuthStateListener());
  }

  void _initializeProviders() {
    // Initialize currency and theme providers without loading transactions
    _currencySymbol = '₹';
    _currencyCode = 'INR';
  }

  /// Sets up a listener for Firebase Auth state changes
  /// This ensures we react to login/logout events properly
  void _setupAuthStateListener() {
    try {
      _authStateSubscription = _auth.authStateChanges().listen(
        (User? user) {
          if (user == null) {
            // User logged out - clear transactions and reset state
            logError('User logged out - clearing transactions');
            _transactions = [];
            _isInitialized = false;
            _totalIncome = 0;
            _totalExpense = 0;
            _totalBalance = 0;
            notifyListeners();
          } else {
            // User logged in - reinitialize transactions if needed
            logError('User logged in - will reinitialize transactions');
            _isInitialized = false;
            // Don't auto-initialize here, let the UI trigger it
          }
        },
        onError: (error) {
          logError('Auth state listener error', error: error);
        },
      );
    } catch (e) {
      logError('Failed to setup auth state listener', error: e);
    }
  }

  Future<void> initializeTransactions() async {
    if (_isInitialized || _isLoading) return;

    // Check if user is authenticated
    if (!isAuthenticated) {
      logError(
        'initializeTransactions: User not authenticated, cannot load transactions',
      );
      _isInitialized = false;
      return;
    }

    _isLoading = true;
    _isInitialized = true;

    try {
      // Get user ID - this will throw if not authenticated
      final userId = currentUserId;
      logDebug('initializeTransactions: Starting for user: $userId');

      // Load initial data with limit to improve performance
      // Filter by current user's transactions only
      logDebug(
        'initializeTransactions: Fetching transactions from Firestore...',
      );
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(50) // Limit initial load
          .get();

      logDebug(
        'initializeTransactions: Loaded ${snapshot.docs.length} transactions',
      );

      _transactions = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Transaction.fromJson(data);
      }).toList();

      _calculateTotals();
      logDebug(
        'initializeTransactions: Total income: $_totalIncome, Total expense: $_totalExpense, Balance: $_totalBalance',
      );
      notifyListeners();

      // Start listening for real-time updates after initial load
      _startRealTimeListener();
      logDebug('initializeTransactions: Successfully initialized');
    } catch (e) {
      logError(
        'initializeTransactions: Failed to initialize transactions',
        error: e,
      );
      _isInitialized = false;
    } finally {
      _isLoading = false;
    }
  }

  void _startRealTimeListener() {
    // Cancel any existing subscription first
    _transactionsSubscription?.cancel();

    // Check if user is authenticated before starting listener
    if (!isAuthenticated) {
      logError('_startRealTimeListener: Cannot start - user not authenticated');
      return;
    }

    try {
      final userId = currentUserId;
      logDebug(
        '_startRealTimeListener: Starting real-time listener for user: $userId',
      );

      _transactionsSubscription = _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              try {
                logDebug(
                  '_startRealTimeListener: Received snapshot with ${snapshot.docs.length} documents',
                );
                _transactions = snapshot.docs.map((doc) {
                  final data = doc.data();
                  data['id'] = doc.id;
                  return Transaction.fromJson(data);
                }).toList();

                _calculateTotals();
                notifyListeners();
                logDebug(
                  '_startRealTimeListener: UI updated with latest transactions',
                );
              } catch (e) {
                logError(
                  '_startRealTimeListener: Error processing transactions snapshot',
                  error: e,
                );
              }
            },
            onError: (error) {
              logError(
                '_startRealTimeListener: Error listening to transactions stream',
                error: error,
              );
              // If it's a permission error, it might be due to user logout
              if (error is FirebaseException &&
                  error.code == 'permission-denied') {
                logError(
                  '_startRealTimeListener: Permission denied - likely user logged out',
                );
                _transactions = [];
                _isInitialized = false;
                notifyListeners();
              }
            },
          );

      logDebug(
        '_startRealTimeListener: Real-time listener started successfully',
      );
    } catch (e) {
      logError(
        '_startRealTimeListener: Failed to start real-time listener',
        error: e,
      );
    }
  }

  void _calculateTotals() {
    logDebug(
      '_calculateTotals: Calculating totals for ${_transactions.length} transactions',
    );

    _totalIncome = _transactions
        .where((t) => t.isIncome)
        .fold(0.0, (total, item) => total + item.amount);

    _totalExpense = _transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (total, item) => total + item.amount);

    _totalBalance = _totalIncome - _totalExpense;

    logDebug(
      '_calculateTotals: Income: $_totalIncome, Expense: $_totalExpense, Balance: $_totalBalance',
    );
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
      // Ensure user is authenticated - get userId (throws if not authenticated)
      if (!isAuthenticated) {
        logError('addTransaction failed: User not authenticated');
        throw UserNotAuthenticatedException(
          'User must be authenticated to add transactions',
        );
      }

      final userId = currentUserId;
      logDebug('addTransaction: User authenticated with uid: $userId');

      // Ensure userId is set to current user
      final transactionWithUser = transaction.copyWith(userId: userId);
      logDebug(
        'addTransaction: Transaction ID: ${transactionWithUser.id}, Amount: ${transactionWithUser.amount}, Category: ${transactionWithUser.category}',
      );

      await _firestore
          .collection('transactions')
          .doc(transactionWithUser.id)
          .set(transactionWithUser.toJson());

      logDebug('addTransaction: Successfully wrote transaction to Firestore');
    } catch (e) {
      logError('addTransaction: Failed to add transaction', error: e);
      rethrow;
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      // Ensure user is authenticated - get userId (throws if not authenticated)
      if (!isAuthenticated) {
        logError('updateTransaction failed: User not authenticated');
        throw UserNotAuthenticatedException(
          'User must be authenticated to update transactions',
        );
      }

      final userId = currentUserId;
      logDebug('updateTransaction: User authenticated with uid: $userId');
      logDebug(
        'updateTransaction: Transaction ID: ${transaction.id}, Amount: ${transaction.amount}',
      );

      // Ensure userId is set to current user
      final transactionWithUser = transaction.copyWith(userId: userId);

      await _firestore
          .collection('transactions')
          .doc(transactionWithUser.id)
          .update(transactionWithUser.toJson());

      logDebug(
        'updateTransaction: Successfully updated transaction in Firestore',
      );
    } catch (e) {
      logError('updateTransaction: Failed to update transaction', error: e);
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      // Ensure user is authenticated
      if (!isAuthenticated) {
        logError('deleteTransaction failed: User not authenticated');
        throw UserNotAuthenticatedException(
          'User must be authenticated to delete transactions',
        );
      }

      final userId = currentUserId;
      logDebug(
        'deleteTransaction: User authenticated with uid: $userId, deleting transaction: $id',
      );

      // Verify the transaction belongs to the current user before deleting
      final doc = await _firestore.collection('transactions').doc(id).get();
      if (!doc.exists) {
        logError('deleteTransaction: Transaction not found: $id');
        throw Exception('Transaction not found');
      }

      final data = doc.data();
      if (data == null || data['userId'] != userId) {
        logError(
          'deleteTransaction: User mismatch - cannot delete transaction belonging to another user',
        );
        throw Exception('You can only delete your own transactions');
      }

      await _firestore.collection('transactions').doc(id).delete();
      logDebug(
        'deleteTransaction: Successfully deleted transaction from Firestore',
      );
    } catch (e) {
      logError('deleteTransaction: Failed to delete transaction', error: e);
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
      // Ensure user is authenticated
      if (!isAuthenticated) {
        if (context.mounted) {
          showSnackBar(context, 'You must be logged in to import transactions');
        }
        return;
      }

      final userId = currentUserId;

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
          // Override userId to ensure it belongs to current user
          final transactionWithUser = transaction.copyWith(userId: userId);
          batch.set(
            _firestore.collection('transactions').doc(transactionWithUser.id),
            transactionWithUser.toJson(),
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
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
