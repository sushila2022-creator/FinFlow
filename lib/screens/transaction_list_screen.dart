import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:finflow/providers/transaction_provider.dart'; // Corrected import path
import 'package:finflow/widgets/transaction_tile.dart'; // Corrected import path
import 'package:finflow/models/transaction.dart'; // Corrected import path
import 'package:finflow/screens/add_transaction_screen.dart'; // Import for SMS to transaction
import 'package:finflow/utils/database_helper.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool showCalendar = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  void _deleteTransaction(BuildContext context, int id) {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    transactionProvider.deleteTransaction(id).then((_) {
      // Check if both the widget is mounted and the context is still valid
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction deleted'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                transactionProvider.undoDelete();
              },
            ),
          ),
        );
      }
    });
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
    _searchFocusNode.requestFocus();
  }

  void _stopSearch() {
    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions, String query) {
    if (query.isEmpty) return transactions;
    return transactions.where((t) =>
      t.description.toLowerCase().contains(query.toLowerCase()) ||
      t.categoryName.toLowerCase().contains(query.toLowerCase()) ||
      (t.notes?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
      t.amount.toString().contains(query)
    ).toList();
  }

  List<Transaction> _getTransactionsForDay(List<Transaction> transactions, DateTime day) {
    return transactions.where((t) =>
      t.date.year == day.year &&
      t.date.month == day.month &&
      t.date.day == day.day
    ).toList();
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  List<Widget> _buildGroupedWidgets(List<String> sortedDateKeys, Map<String, List<Transaction>> groupedTransactions) {
    final List<Widget> widgets = [];
    for (final dateKey in sortedDateKeys) {
      final date = DateTime.parse(dateKey);
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            _getDateHeader(date),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
      for (final transaction in groupedTransactions[dateKey]!) {
        widgets.add(
          Dismissible(
            key: ValueKey(transaction.id),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              _deleteTransaction(context, transaction.id!);
            },
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: TransactionTile(transaction: transaction),
          ),
        );
      }
    }
    return widgets;
  }

  Future<void> scanSMS() async {
    var status = await Permission.sms.status;
    if (status.isDenied) {
      status = await Permission.sms.request();
    }
    if (status.isPermanentlyDenied) {
      openAppSettings();
    } else if (status.isGranted) {
      final smsQuery = SmsQuery();
      final messages = await smsQuery.querySms(kinds: [SmsQueryKind.inbox]);
      final filteredMessages = messages.where((msg) {
        final body = msg.body?.toLowerCase() ?? '';
        return body.contains('debited') ||
               body.contains('spent') ||
               body.contains('purchase') ||
               body.contains('txn');
      }).toList();

      // Get existing transaction signatures to filter duplicates
      final signatures = await DatabaseHelper.instance.getAllTransactionSignatures();
      if (!mounted) return;

      // Filter out duplicates based on amount and date
      final uniqueFilteredMessages = filteredMessages.where((msg) {
        double? amount;
        final regExp = RegExp(r'(?:Rs\.?|INR|INR)\s*[\.]?\s*([\d,]+\.?\d*)', caseSensitive: false);
        final match = regExp.firstMatch(msg.body ?? '');
        if (match != null) {
          final amountStr = match.group(1)!.replaceAll(',', '');
          amount = double.tryParse(amountStr);
        }
        final date = msg.date ?? DateTime.now();
        if (amount != null) {
          final signature = "${amount.toStringAsFixed(2)}_${DateFormat('yyyy-MM-dd').format(date)}";
          return !signatures.contains(signature);
        }
        return false; // Exclude if amount cannot be parsed
      }).toList();

      showModalBottomSheet(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return ListView.builder(
                  itemCount: uniqueFilteredMessages.length,
                  itemBuilder: (context, index) {
                    final msg = uniqueFilteredMessages[index];
                    return ListTile(
                      title: Text(msg.address ?? 'Unknown'),
                      subtitle: Text(msg.body ?? ''),
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        final scaffoldMessenger = ScaffoldMessenger.of(context);

                        // Extract amount from SMS text using regex
                        final regExp = RegExp(r'(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{2})?)');
                        final match = regExp.firstMatch(msg.body ?? '');
                        double? parsedAmount;
                        if (match != null) {
                          final amountStr = match.group(1)!.replaceAll(',', '');
                          parsedAmount = double.tryParse(amountStr);
                        }

                        if (parsedAmount != null) {
                          // Navigate to AddTransactionScreen with pre-filled data
                          final result = await navigator.push(
                            MaterialPageRoute(
                              builder: (_) => AddTransactionScreen(
                                transactionToEdit: {
                                  'amount': parsedAmount,
                                  'note': msg.body,
                                  'date': DateTime.now().toIso8601String(),
                                  'type': 'Expense'
                                }
                              ),
                            ),
                          );

                          if (result == true) {
                            uniqueFilteredMessages.remove(msg);
                            setModalState(() {});
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('Transaction added and removed from list')),
                            );
                          }
                        } else {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(content: Text('Could not extract amount from SMS')),
                          );
                        }
                      },
                    );
                  },
                );
              },
            );
          },
        );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SMS permission denied')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get transactions from TransactionProvider
    final transactions = context.watch<TransactionProvider>().transactions;

    final allTransactions = transactions;
    final filteredTransactions = _filterTransactions(allTransactions, _searchController.text);

    // Group transactions by date
    final Map<String, List<Transaction>> groupedTransactions = {};
    for (final transaction in filteredTransactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      groupedTransactions.putIfAbsent(dateKey, () => []).add(transaction);
    }

    // Sort dates descending (latest first)
    final sortedDateKeys = groupedTransactions.keys.toList()..sort((a, b) => b.compareTo(a));

    // Sort transactions within each day by date descending
    for (final key in sortedDateKeys) {
      groupedTransactions[key]!.sort((a, b) => b.date.compareTo(a.date));
    }

    return Scaffold(
      appBar: AppBar(
          backgroundColor: const Color(0xFF0A2540),
          elevation: 0,
          centerTitle: false,
          automaticallyImplyLeading: false,
          title: _isSearching
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: const TextStyle(color: Colors.black87),
                cursorColor: Colors.teal,
                decoration: const InputDecoration(
                  hintText: 'Search transactions...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() {}),
              )
            : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.sms_rounded),
              tooltip: 'Scan SMS',
              onPressed: scanSMS,
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () {
                // 1. Kill the focus (Close Keyboard)
                FocusScope.of(context).unfocus();
                // 2. Wait for 200ms to let the keyboard animation finish
                Future.delayed(Duration(milliseconds: 200), () {
                  if (mounted) {
                    setState(() {
                      // 3. Reset search if active
                      if (_isSearching) {
                        _isSearching = false;
                        _searchController.clear();
                      }
                      // 4. NOW switch to calendar
                      showCalendar = !showCalendar;
                    });
                  }
                });
              },
            ),
            _isSearching
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _stopSearch,
                )
              : IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _startSearch,
                ),
          ],

        ),
      body: showCalendar
        ? Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final transactionsForDay = _selectedDay == null ? <Transaction>[] : _getTransactionsForDay(allTransactions, _selectedDay!);
                    final visibleTransactions = _filterTransactions(transactionsForDay, _searchController.text);
                    return _selectedDay == null
                      ? const Center(child: Text('Select a date to view transactions.'))
                      : (visibleTransactions.isEmpty
                        ? const Center(child: Text('No transactions for this date.'))
                        : ListView.builder(
                            itemCount: visibleTransactions.length,
                            itemBuilder: (context, index) {
                              final transaction = visibleTransactions[index];
                              return Dismissible(
                                key: ValueKey(transaction.id),
                                direction: DismissDirection.endToStart,
                                onDismissed: (direction) {
                                  _deleteTransaction(context, transaction.id!);
                                },
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                child: TransactionTile(transaction: transaction),
                              );
                            },
                          ));
                  },
                ),
              ),
            ],
          )
        : (filteredTransactions.isEmpty
          ? const Center(child: Text('No transactions yet.'))
          : ListView(
              children: _buildGroupedWidgets(sortedDateKeys, groupedTransactions),
            )),
    );
  }
}
