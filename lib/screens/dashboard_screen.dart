import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:finflow/providers/transaction_provider.dart';
import 'package:finflow/providers/currency_provider.dart';
import 'package:finflow/utils/utility.dart';
import 'package:finflow/models/transaction.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTabIndex = 0; // 0: Today, 1: Week, 2: Month, 3: Year

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
      // Today
      Transaction(
        description: 'Salary Deposit',
        categoryName: 'Salary',
        amount: 50000.0,
        currencyCode: 'INR',
        date: now,
        categoryId: 6,
        type: 'income',
        accountId: 1,
        notes: 'Monthly salary',
      ),
      Transaction(
        description: 'Grocery Shopping',
        categoryName: 'Grocery',
        amount: 2500.0,
        currencyCode: 'INR',
        date: now,
        categoryId: 1,
        type: 'expense',
        accountId: 1,
        notes: 'Daily groceries',
      ),
      // Yesterday
      Transaction(
        description: 'Freelance Project',
        categoryName: 'Freelance',
        amount: 15000.0,
        currencyCode: 'INR',
        date: now.subtract(const Duration(days: 1)),
        categoryId: 7,
        type: 'income',
        accountId: 1,
        notes: 'App development',
      ),
      Transaction(
        description: 'Uber Ride',
        categoryName: 'Uber',
        amount: 450.0,
        currencyCode: 'INR',
        date: now.subtract(const Duration(days: 1)),
        categoryId: 2,
        type: 'expense',
        accountId: 1,
        notes: 'To work',
      ),
      // 5 days ago
      Transaction(
        description: 'Monthly Rent',
        categoryName: 'Rent',
        amount: 10000.0,
        currencyCode: 'INR',
        date: now.subtract(const Duration(days: 5)),
        categoryId: 3,
        type: 'expense',
        accountId: 1,
        notes: 'Apartment rent',
      ),
      Transaction(
        description: 'Grocery Shopping',
        categoryName: 'Grocery',
        amount: 2500.0,
        currencyCode: 'INR',
        date: now.subtract(const Duration(days: 5)),
        categoryId: 1,
        type: 'expense',
        accountId: 1,
        notes: 'Weekly groceries',
      ),
      Transaction(
        description: 'Uber Ride',
        categoryName: 'Uber',
        amount: 450.0,
        currencyCode: 'INR',
        date: now.subtract(const Duration(days: 5)),
        categoryId: 2,
        type: 'expense',
        accountId: 1,
        notes: 'Meeting',
      ),
      // 10 days ago
      Transaction(
        description: 'Freelance Work',
        categoryName: 'Freelance',
        amount: 15000.0,
        currencyCode: 'INR',
        date: now.subtract(const Duration(days: 10)),
        categoryId: 7,
        type: 'income',
        accountId: 1,
        notes: 'Design project',
      ),
      Transaction(
        description: 'Grocery Shopping',
        categoryName: 'Grocery',
        amount: 2500.0,
        currencyCode: 'INR',
        date: now.subtract(const Duration(days: 10)),
        categoryId: 1,
        type: 'expense',
        accountId: 1,
        notes: 'Monthly stock',
      ),
      Transaction(
        description: 'Uber Ride',
        categoryName: 'Uber',
        amount: 450.0,
        currencyCode: 'INR',
        date: now.subtract(const Duration(days: 10)),
        categoryId: 2,
        type: 'expense',
        accountId: 1,
        notes: 'Airport pickup',
      ),
      // 15 days ago
      Transaction(
        description: 'Grocery Shopping',
        categoryName: 'Grocery',
        amount: 2500.0,
        currencyCode: 'INR',
        date: now.subtract(const Duration(days: 15)),
        categoryId: 1,
        type: 'expense',
        accountId: 1,
        notes: 'Household items',
      ),
      Transaction(
        description: 'Uber Ride',
        categoryName: 'Uber',
        amount: 450.0,
        currencyCode: 'INR',
        date: now.subtract(const Duration(days: 15)),
        categoryId: 2,
        type: 'expense',
        accountId: 1,
        notes: 'City travel',
      ),
      // 20 days ago
      Transaction(
        description: 'Freelance Payment',
        categoryName: 'Freelance',
        amount: 15000.0,
        currencyCode: 'INR',
        date: now.subtract(const Duration(days: 20)),
        categoryId: 7,
        type: 'income',
        accountId: 1,
        notes: 'Consulting',
      ),
      Transaction(
        description: 'Grocery Shopping',
        categoryName: 'Grocery',
        amount: 2500.0,
        currencyCode: 'INR',
        date: now.subtract(const Duration(days: 20)),
        categoryId: 1,
        type: 'expense',
        accountId: 1,
        notes: 'Fresh produce',
      ),
      // 25 days ago
      Transaction(
        description: 'Uber Ride',
        categoryName: 'Uber',
        amount: 450.0,
        currencyCode: 'INR',
        date: now.subtract(const Duration(days: 25)),
        categoryId: 2,
        type: 'expense',
        accountId: 1,
        notes: 'Weekend outing',
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
      case 3: // This Year
        return transactions.where((tx) {
          return tx.date.year == now.year;
        }).toList();
      default:
        return transactions;
    }
  }

  // Get category-specific icons
  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'food':
      case 'restaurant':
        return Icons.fastfood;
      case 'travel':
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'bills':
        return Icons.receipt;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'salary':
      case 'freelance':
        return Icons.work;
      case 'investments':
        return Icons.trending_up;
      default:
        return Icons.category;
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A2540),
        elevation: 0,
        centerTitle: false,
        title: Text('FinFlow', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26)),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Consumer2<TransactionProvider, CurrencyProvider>(
          builder: (context, transactionProvider, currencyProvider, child) {
            final allTransactions = transactionProvider.transactions;
            final filteredTransactions = _getFilteredTransactions(allTransactions);
            final balance = transactionProvider.balance;
            final currencySymbol = currencyProvider.selectedCurrency['symbol'] ?? '₹';

            final income = filteredTransactions.where((t) => t.type == 'income').fold(0.0, (sum, item) => sum + item.amount);
            final expense = filteredTransactions.where((t) => t.type == 'expense').fold(0.0, (sum, item) => sum + item.amount);
            final netFlow = income - expense;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact Tabs with horizontal scrolling for 4 tabs
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                        _buildPillChip('Year', _selectedTabIndex == 3, () {
                          setState(() {
                            _selectedTabIndex = 3;
                          });
                        }),
                      ],
                    ),
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
                      colors: [
                        Color(0xFF00695C), // Darker rich Teal
                        Color(0xFF4DB6AC), // Lighter vibrant Teal
                      ],
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
                                  formatIndianCurrency(income, symbol: currencySymbol),
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
                                  formatIndianCurrency(expense, symbol: currencySymbol),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Net Flow Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Net Flow',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatIndianCurrency(netFlow, symbol: currencySymbol),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
                                leading: CircleAvatar(
                                  backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                                  child: Icon(
                                    _getCategoryIcon(transaction.categoryName),
                                    color: isIncome ? Colors.green : Colors.red,
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
