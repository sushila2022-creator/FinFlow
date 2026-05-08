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
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row;
import 'package:open_file/open_file.dart';
import 'currency_provider.dart';

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
  StreamSubscription<QuerySnapshot>? _transactionsSubscription;
  StreamSubscription<User?>? _authStateSubscription;
  List<Transaction> _transactions = [];
  bool _isInitialized = false;
  bool _isLoading = false;

  // Dependency on CurrencyProvider
  CurrencyProvider? _currencyProvider;

  // Centralized SMS detection storage
  final List<Map<String, dynamic>> _detectedSmsTransactions = [];

  // Computed values
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _totalBalance = 0;
  double _thisMonthTotal = 0;
  double _lastMonthTotal = 0;

  // Memoized data
  Map<String, double>? _memoizedExpenseData;
  Map<String, double>? _memoizedIncomeData;
  Map<int, double>? _memoizedWeeklyExpenses;

  final Map<int, String> _categoryMap = {
    1: 'Food',
    2: 'Travel',
    3: 'Bills',
    4: 'Shopping',
    6: 'Salary',
    7: 'Freelance',
    8: 'Investments',
  };

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
  bool get isLoading => _isLoading;

  List<Transaction> get transactions => _transactions;
  List<Map<String, dynamic>> get detectedSmsTransactions =>
      List.unmodifiable(_detectedSmsTransactions);
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get totalBalance => _totalBalance;
  double get balance => _totalBalance;
  double get thisMonthTotal => _thisMonthTotal;
  double get lastMonthTotal => _lastMonthTotal;
  double get monthlyChange => _thisMonthTotal - _lastMonthTotal;

  TransactionProvider() {
    // Listen for auth state changes to re-initialize listeners
    _authStateSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        initializeTransactions();
      } else {
        _cleanup();
      }
    });
  }

  void _cleanup() {
    _transactionsSubscription?.cancel();
    _transactionsSubscription = null;
    _transactions = [];
    _totalBalance = 0.0;
    _totalIncome = 0.0;
    _totalExpense = 0.0;
    _thisMonthTotal = 0.0;
    _lastMonthTotal = 0.0;
    _clearMemoization();
    _isInitialized = false;
    _isLoading = false;
    notifyListeners();
  }

  void updateCurrencyProvider(CurrencyProvider currencyProvider) {
    _currencyProvider = currencyProvider;

    // Always recalculate when transactions are loaded so that any currency or
    // exchange-rate change is immediately reflected in totals. The guard on
    // _isInitialized prevents a no-op calculation before transactions arrive.
    if (_isInitialized) {
      _clearMemoization();
      _calculateTotals();
      notifyListeners();
    }
  }

  void _clearMemoization() {
    _memoizedExpenseData = null;
    _memoizedIncomeData = null;
    _memoizedWeeklyExpenses = null;
  }

  // SMS Detection Management
  void addDetectedSms(Map<String, dynamic> detected) {
    final alreadyDetected = _detectedSmsTransactions.any(
      (t) =>
          t['amount'] == detected['amount'] &&
          t['date'] == detected['date'] &&
          t['body'] == detected['body'],
    );

    if (!alreadyDetected) {
      _detectedSmsTransactions.add(detected);
      notifyListeners();
    }
  }

  void removeDetectedSms(Map<String, dynamic> detected) {
    _detectedSmsTransactions.removeWhere(
      (t) =>
          t['amount'] == detected['amount'] &&
          t['date'] == detected['date'] &&
          t['body'] == detected['body'],
    );
    notifyListeners();
  }

  void clearDetectedSms() {
    _detectedSmsTransactions.clear();
    notifyListeners();
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

    try {
      // Get user ID - this will throw if not authenticated
      final userId = currentUserId;
      logDebug('initializeTransactions: Starting for user: $userId');

      // Load initial data with limit to improve performance
      // Filter by current user's transactions only
      // Load initial data with limit to improve performance
      // Filter by current user's transactions only
      logDebug(
        'initializeTransactions: Loading transactions FROM CACHE FIRST (offline-first)',
      );

      // ✅ OFFLINE FIRST: Load from local cache immediately
      final cacheSnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(100)
          .get(const GetOptions(source: Source.cache));

      if (cacheSnapshot.docs.isNotEmpty) {
        _transactions = cacheSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Transaction.fromJson(data);
        }).toList();

        _calculateTotals();
        _isInitialized = true;
        notifyListeners();
        logDebug(
          'initializeTransactions: Loaded ${cacheSnapshot.docs.length} transactions from LOCAL CACHE - UI READY',
        );
      }

      // Then fetch latest data from server in background
      unawaited(
        _firestore
            .collection('transactions')
            .where('userId', isEqualTo: userId)
            .orderBy('date', descending: true)
            .limit(100)
            .get(const GetOptions(source: Source.serverAndCache))
            .then((serverSnapshot) {
              if (serverSnapshot.docs.isNotEmpty) {
                _transactions = serverSnapshot.docs.map((doc) {
                  final data = doc.data();
                  data['id'] = doc.id;
                  return Transaction.fromJson(data);
                }).toList();

                _calculateTotals();
                notifyListeners();
                logDebug(
                  'initializeTransactions: Synced ${serverSnapshot.docs.length} transactions from SERVER',
                );
              }
            })
            .catchError((error) {
              logDebug(
                'initializeTransactions: Working offline - using cached data only',
              );
            }),
      );

      _calculateTotals();
      _isInitialized = true;
      notifyListeners();

      // Start listening for real-time updates after initial load
      _startRealTimeListener();
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

    if (!isAuthenticated) return;

    try {
      final userId = currentUserId;
      _transactionsSubscription = _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(100) // Maintain limit for real-time stream performance
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

    _clearMemoization();

    double income = 0.0;
    double expense = 0.0;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
    final endOfLastMonth = startOfMonth.subtract(const Duration(days: 1));

    double thisMonth = 0.0;
    double lastMonth = 0.0;

    final targetCode = _currencyProvider?.currentCurrencyCode ?? 'USD';

    for (var t in _transactions) {
      final amount =
          _currencyProvider?.convertAmount(
            t.amount,
            t.currencyCode,
            targetCode,
          ) ??
          t.amount;

      if (t.isIncome) {
        income += amount;
      } else {
        expense += amount;
      }

      // Monthly totals for dashboard
      if (t.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          t.date.isBefore(now.add(const Duration(days: 1)))) {
        thisMonth += t.isIncome ? amount : -amount;
      } else if (t.date.isAfter(
            startOfLastMonth.subtract(const Duration(days: 1)),
          ) &&
          t.date.isBefore(endOfLastMonth.add(const Duration(days: 1)))) {
        lastMonth += t.isIncome ? amount : -amount;
      }
    }

    _totalIncome = income;
    _totalExpense = expense;
    _totalBalance = _totalIncome - _totalExpense;
    _thisMonthTotal = thisMonth;
    _lastMonthTotal = lastMonth;

    logDebug(
      '_calculateTotals: Income: $_totalIncome, Expense: $_totalExpense, Balance: $_totalBalance, Monthly Change: ${_thisMonthTotal - _lastMonthTotal}',
    );
  }

  String get currencySymbol => _currencyProvider?.currentCurrencySymbol ?? '₹';
  String get currencyCode => _currencyProvider?.currentCurrencyCode ?? 'INR';

  Future<void> addTransaction(Transaction transaction) async {
    try {
      if (!isAuthenticated) {
        throw UserNotAuthenticatedException(
          'User must be authenticated to add transactions',
        );
      }

      final userId = currentUserId;

      // Basic deduplication check: check if a transaction with same amount, category and title
      // was added in the last 10 seconds.
      final isDuplicate = _transactions.any(
        (t) =>
            t.amount == transaction.amount &&
            t.category == transaction.category &&
            t.title == transaction.title &&
            DateTime.now().difference(t.date).inSeconds.abs() < 10,
      );

      if (isDuplicate) {
        logWarning(
          'addTransaction: Duplicate transaction detected, skipping write',
        );
        return;
      }

      final transactionWithUser = transaction.copyWith(userId: userId);

      // ✅ OFFLINE FIRST: UPDATE UI INSTANTLY BEFORE NETWORK CALL
      _transactions.insert(0, transactionWithUser);
      _calculateTotals();
      _clearMemoization();
      notifyListeners();
      logDebug(
        'addTransaction: UI updated instantly with new transaction (offline-first)',
      );

      // Firestore write happens in background - will sync automatically when online
      unawaited(
        _firestore
            .collection('transactions')
            .doc(transactionWithUser.id)
            .set(transactionWithUser.toJson())
            .then((_) {
              logDebug(
                'addTransaction: Transaction synced to Firestore successfully',
              );
            })
            .catchError((error) {
              logError(
                'addTransaction: Failed to sync transaction to server - will retry automatically when online',
                error: error,
              );
              // No need to revert UI - Firestore will retry automatically in background
            }),
      );
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

  Future<void> deleteAllTransactionsFromFirestore() async {
    try {
      if (!isAuthenticated) {
        logError('deleteAllTransactionsFromFirestore: Not authenticated');
        return;
      }

      final userId = currentUserId;
      logDebug('deleteAllTransactionsFromFirestore: Starting for user $userId');

      // Fetch all transactions for this user
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) {
        logDebug('deleteAllTransactionsFromFirestore: No transactions found');
        _transactions = [];
        _calculateTotals();
        notifyListeners();
        return;
      }

      logDebug(
        'deleteAllTransactionsFromFirestore: Found ${snapshot.docs.length} transactions to delete',
      );

      // Delete in batches of 500 (Firestore limit)
      final batches = <WriteBatch>[_firestore.batch()];
      int counter = 0;
      int batchIndex = 0;

      for (var doc in snapshot.docs) {
        if (counter >= 500) {
          batches.add(_firestore.batch());
          batchIndex++;
          counter = 0;
        }
        batches[batchIndex].delete(doc.reference);
        counter++;
      }

      // Commit all batches
      for (var batch in batches) {
        await batch.commit();
      }

      logDebug(
        'deleteAllTransactionsFromFirestore: Successfully deleted all data',
      );

      // Clear local state
      _transactions = [];
      _calculateTotals();
      notifyListeners();
    } catch (e) {
      logError('deleteAllTransactionsFromFirestore: Failed', error: e);
      rethrow;
    }
  }

  Future<List<Transaction>> getRecurringTransactions() async {
    return _transactions.where((t) => t.isRecurring).toList();
  }

  // Pre-calculate expense data for the dashboard
  Map<String, double> get expenseData {
    if (_memoizedExpenseData != null) return _memoizedExpenseData!;

    final Map<String, double> expenseByCategory = {};
    final targetCode = _currencyProvider?.currentCurrencyCode ?? 'USD';

    for (var transaction in _transactions) {
      if (!transaction.isIncome) {
        final category =
            _categoryMap[transaction.categoryId] ?? transaction.category;
        final amount =
            _currencyProvider?.convertAmount(
              transaction.amount,
              transaction.currencyCode,
              targetCode,
            ) ??
            transaction.amount;

        expenseByCategory.update(
          category,
          (value) => value + amount,
          ifAbsent: () => amount,
        );
      }
    }
    _memoizedExpenseData = expenseByCategory;
    return expenseByCategory;
  }

  // Pre-calculate income data for stats
  Map<String, double> get incomeData {
    if (_memoizedIncomeData != null) return _memoizedIncomeData!;

    final Map<String, double> incomeByCategory = {};
    final targetCode = _currencyProvider?.currentCurrencyCode ?? 'USD';

    for (var transaction in _transactions) {
      if (transaction.isIncome) {
        final category =
            _categoryMap[transaction.categoryId] ?? transaction.category;
        final amount =
            _currencyProvider?.convertAmount(
              transaction.amount,
              transaction.currencyCode,
              targetCode,
            ) ??
            transaction.amount;

        incomeByCategory.update(
          category,
          (value) => value + amount,
          ifAbsent: () => amount,
        );
      }
    }
    _memoizedIncomeData = incomeByCategory;
    return incomeByCategory;
  }

  Map<String, double> getMonthlyReport(int year, int month) {
    final targetCode = _currencyProvider?.currentCurrencyCode ?? 'USD';
    final monthlyTransactions = _transactions.where((t) {
      return t.date.year == year && t.date.month == month;
    }).toList();

    double income = 0.0;
    double expense = 0.0;

    for (var t in monthlyTransactions) {
      final amount =
          _currencyProvider?.convertAmount(
            t.amount,
            t.currencyCode,
            targetCode,
          ) ??
          t.amount;

      if (t.isIncome) {
        income += amount;
      } else {
        expense += amount;
      }
    }

    return {'income': income, 'expense': expense};
  }

  Map<int, double> get weeklyExpenses {
    if (_memoizedWeeklyExpenses != null) return _memoizedWeeklyExpenses!;

    final Map<int, double> weeklyExpensesMap = {};
    final today = DateTime.now();
    final targetCode = _currencyProvider?.currentCurrencyCode ?? 'USD';

    for (int i = 0; i < 7; i++) {
      final weekDay = today.subtract(Duration(days: i));
      double total = 0.0;
      for (var transaction in _transactions) {
        if (transaction.date.day == weekDay.day &&
            transaction.date.month == weekDay.month &&
            transaction.date.year == weekDay.year &&
            !transaction.isIncome) {
          final amount =
              _currencyProvider?.convertAmount(
                transaction.amount,
                transaction.currencyCode,
                targetCode,
              ) ??
              transaction.amount;
          total += amount;
        }
      }
      weeklyExpensesMap[i] = total;
    }
    _memoizedWeeklyExpenses = weeklyExpensesMap;
    return weeklyExpensesMap;
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

  Future<void> exportTransactionsExcel(BuildContext context) async {
    try {
      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];

      // Set headers
      sheet.getRangeByName('A1').setText('ID');
      sheet.getRangeByName('B1').setText('Description');
      sheet.getRangeByName('C1').setText('Amount');
      sheet.getRangeByName('D1').setText('Currency');
      sheet.getRangeByName('E1').setText('Date');
      sheet.getRangeByName('F1').setText('Category');
      sheet.getRangeByName('G1').setText('Type');
      sheet.getRangeByName('H1').setText('Notes');
      sheet.getRangeByName('I1').setText('Is Recurring');

      // Add data
      for (int i = 0; i < _transactions.length; i++) {
        final transaction = _transactions[i];
        final row = i + 2;

        sheet.getRangeByName('A$row').setText(transaction.id);
        sheet.getRangeByName('B$row').setText(transaction.description);
        sheet.getRangeByName('C$row').setNumber(transaction.amount);
        sheet.getRangeByName('D$row').setText(transaction.currencyCode);
        sheet.getRangeByName('E$row').setDateTime(transaction.date);
        sheet.getRangeByName('F$row').setText(transaction.category);
        sheet
            .getRangeByName('G$row')
            .setText(transaction.isIncome ? 'Income' : 'Expense');
        sheet.getRangeByName('H$row').setText(transaction.notes ?? '');
        sheet
            .getRangeByName('I$row')
            .setText(transaction.isRecurring ? 'Yes' : 'No');
      }

      // Format headers
      final Range headerRange = sheet.getRangeByName('A1:I1');
      headerRange.cellStyle.backColor = '#0D2B45';
      headerRange.cellStyle.fontColor = '#FFFFFF';
      headerRange.cellStyle.bold = true;

      // Auto-fit columns
      for (int i = 1; i <= 9; i++) {
        sheet.autoFitColumn(i);
      }

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      final tempDir = await getTemporaryDirectory();
      if (!context.mounted) return;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'FinFlow_All_Transactions_$timestamp.xlsx';
      final filePath = '${tempDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (!context.mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              filePath,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ),
          ],
          subject: 'FinFlow All Transactions Data',
          text: 'Complete transaction records exported from FinFlow AI.',
        ),
      );

      if (!context.mounted) return;
      showSnackBar(context, 'Excel report exported successfully');

      // Also try to open it
      await OpenFile.open(filePath);
    } catch (e) {
      if (!context.mounted) return;
      showSnackBar(context, 'An error occurred during Excel export: $e');
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
