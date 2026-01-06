import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:finflow/providers/transaction_provider.dart';
import 'package:finflow/providers/currency_provider.dart';
import 'package:finflow/utils/utility.dart';
import 'package:finflow/models/transaction.dart';

class DashboardScreenCompact extends StatefulWidget {
  const DashboardScreenCompact({super.key});

  @override
  State<DashboardScreenCompact> createState() => _DashboardScreenCompactState();
}

class _DashboardScreenCompactState extends State<DashboardScreenCompact> {
  int _selectedTabIndex = 0; // 0: Today, 1: Week, 2: Month

  @override
  void initState() {
    super.initState();
    _generateDummyTransactionsIfEmpty();
  }

  void _generateDummyTransactionsIfEmpty() {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    if (transactionProvider.transactions.isEmpty) {
      _generateDummyTransactions(transactionProvider);
    }
  }

  void _generateDummyTransactions(TransactionProvider provider) {
    final now = DateTime.now();
    final List<Transaction> dummyTransactions = [
      // Income transactions
      Transaction(
        description: 'Salary Deposit',
        categoryName: 'Salary',
        amount: 75000.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, now.day - 1),
        categoryId: 6,
        type: 'income',
        accountId: 1,
        notes: 'Monthly salary',
      ),
      Transaction(
        description: 'Freelance Project',
        categoryName: 'Freelance',
        amount: 25000.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, now.day - 3),
        categoryId: 7,
        type: 'income',
        accountId: 1,
        notes: 'Web development',
      ),
      Transaction(
        description: 'Stock Dividends',
        categoryName: 'Investments',
        amount: 5000.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, now.day - 5),
        categoryId: 8,
        type: 'income',
        accountId: 1,
        notes: 'Quarterly dividends',
      ),
      
      // Expense transactions
      Transaction(
        description: 'Uber to Office',
        categoryName: 'Travel',
        amount: 450.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, now.day),
        categoryId: 2,
        type: 'expense',
        accountId: 1,
        notes: 'Daily commute',
      ),
      Transaction(
        description: 'Grocery Shopping',
        categoryName: 'Food',
        amount: 3200.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, now.day - 1),
        categoryId: 1,
        type: 'expense',
        accountId: 1,
        notes: 'Weekly groceries',
      ),
      Transaction(
        description: 'Electricity Bill',
        categoryName: 'Bills',
        amount: 2800.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, now.day - 2),
        categoryId: 3,
        type: 'expense',
        accountId: 1,
        notes: 'Monthly bill',
      ),
      Transaction(
        description: 'Restaurant Dinner',
        categoryName: 'Food',
        amount: 1800.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, now.day - 4),
        categoryId: 1,
        type: 'expense',
        accountId: 1,
        notes: 'Date night',
      ),
      Transaction(
        description: 'Online Shopping',
        categoryName: 'Shopping',
        amount: 5500.0,
        currencyCode: 'INR',
        date: DateTime(now.year, now.month, now.day - 6),
        categoryId: 4,
        type: 'expense',
        accountId: 1,
        notes: 'Electronics',
      ),
    ];

    for (var transaction in dummyTransactions) {
      provider.addTransaction(transaction);
    }
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    final now = DateTime.now();
    
    switch (_selectedTabIndex) {
      case 0: // Today
        return transactions.where((tx) {
          return tx.date.year == now.year &&
                 tx.date.month == now.month &&
                 tx.date.day == now.day;
        }).toList();
      case 1: // This Week
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return transactions.where((tx) {
          return tx.date.isAfter(startOfWeek.subtract(const Duration(days: 1))) && 
                 tx.date.isBefore(endOfWeek.add(const Duration(days: 1)));
        }).toList();
      case 2: // This Month
        return transactions.where((tx) {
          return tx.date.year == now.year && tx.date.month == now.month;
        }).toList();
      default:
        return transactions;
    }
  }

  Widget _buildPillChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A2540) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Consumer2<TransactionProvider, CurrencyProvider>(
          builder: (context, transactionProvider, currencyProvider, child) {
            final allTransactions = transactionProvider.transactions;
            final filteredTransactions = _getFilteredTransactions(allTransactions);
            final balance = transactionProvider.balance;
            final currencySymbol = currencyProvider.selectedCurrency['symbol'] ?? '₹';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FinFlow Compact Header - Left aligned with badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A2540),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0A2540).withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'FinFlow',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Compact Tabs
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _buildPillChip('Today', _selectedTabIndex == 0, () {
                        setState(() {
                          _selectedTabIndex = 0;
                        });
                      }),
                      _buildPillChip('Week', _selectedTabIndex == 1, () {
                        setState(() {
                          _selectedTabIndex = 1;
                        });
                      }),
                      _buildPillChip('Month', _selectedTabIndex == 2, () {
                        setState(() {
                          _selectedTabIndex = 2;
                        });
                      }),
                    ],
                  ),
                ),

                // Compact Balance Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF05445E), Color(0xFF189AB4)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Balance',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatIndianCurrency(balance, symbol: currencySymbol),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Income Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_upward,
                                      color: const Color(0xFF00C853),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Income',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatIndianCurrency(
                                    filteredTransactions
                                        .where((t) => t.type == 'income')
                                        .fold(0.0, (sum, item) => sum + item.amount),
                                    symbol: currencySymbol,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00C853),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Expense Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_downward,
                                      color: Colors.red,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Expense',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatIndianCurrency(
                                    filteredTransactions
                                        .where((t) => t.type == 'expense')
                                        .fold(0.0, (sum, item) => sum + item.amount),
                                    symbol: currencySymbol,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Transaction List with Green/Red Colored Icons
                Expanded(
                  child: filteredTransactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.receipt_long,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No transactions found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try selecting a different time period',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = filteredTransactions[index];
                            final isExpense = transaction.type == 'expense';
                            final isIncome = transaction.type == 'income';
                            final displayAmount = formatIndianCurrency(
                              transaction.amount.abs(),
                              symbol: currencySymbol,
                            );

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isIncome ? const Color(0xFFE8F5E8) : const Color(0xFFFFE8E8),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isIncome ? const Color(0xFF00C853) : Colors.red,
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    getCategoryIconByName(transaction.categoryName),
                                    color: isIncome ? const Color(0xFF00C853) : Colors.red,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  transaction.description,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  transaction.categoryName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isExpense ? '-' : '+'}$displayAmount',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isExpense ? Colors.red : const Color(0xFF00C853),
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MMM dd').format(transaction.date),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Transaction: ${transaction.description}'),
                                      backgroundColor: const Color(0xFF0A2540),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
