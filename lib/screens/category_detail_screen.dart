import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:finflow/providers/transaction_provider.dart';
import 'package:finflow/providers/currency_provider.dart';
import 'package:finflow/models/transaction.dart';
import 'package:finflow/utils/app_theme.dart';
import 'package:finflow/screens/add_transaction_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryName;
  final bool isIncome;

  const CategoryDetailScreen({
    super.key,
    required this.categoryName,
    required this.isIncome,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, double> _calculatePeriodTotals(List<Transaction> transactions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfYear = DateTime(now.year, 1, 1);

    double totalToday = 0;
    double totalWeek = 0;
    double totalMonth = 0;
    double totalYear = 0;

    for (var t in transactions) {
      if (t.categoryName.trim().toLowerCase() == widget.categoryName.trim().toLowerCase() && t.isIncome == widget.isIncome) {
        final tDate = DateTime(t.date.year, t.date.month, t.date.day);
        
        if (tDate.isAtSameMomentAs(today)) totalToday += t.amount.abs();
        if (tDate.isAtSameMomentAs(startOfWeek) || tDate.isAfter(startOfWeek)) totalWeek += t.amount.abs();
        if (tDate.isAtSameMomentAs(startOfMonth) || tDate.isAfter(startOfMonth)) totalMonth += t.amount.abs();
        if (tDate.isAtSameMomentAs(startOfYear) || tDate.isAfter(startOfYear)) totalYear += t.amount.abs();
      }
    }

    return {
      'Today': totalToday,
      'Week': totalWeek,
      'Month': totalMonth,
      'Year': totalYear,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeColor = widget.isIncome ? AppTheme.incomeColor : AppTheme.expenseColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: Text(
          '${widget.categoryName} Details',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer2<TransactionProvider, CurrencyProvider>(
        builder: (context, transactionProvider, currencyProvider, child) {
          final categoryTransactions = transactionProvider.transactions
              .where((t) => t.categoryName.trim().toLowerCase() == widget.categoryName.trim().toLowerCase() && 
                            t.isIncome == widget.isIncome)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          final periodTotals = _calculatePeriodTotals(categoryTransactions);
          final filteredTransactions = categoryTransactions.where((t) {
            return _searchQuery.isEmpty ||
                t.description.toLowerCase().contains(_searchQuery) ||
                t.title.toLowerCase().contains(_searchQuery);
          }).toList();

          return Column(
            children: [
              // Period Totals Section
              _buildPeriodTotals(periodTotals, currencyProvider.currentCurrencySymbol, themeColor, isDarkMode),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search in ${widget.categoryName}...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),

              // Transactions List
              Expanded(
                child: filteredTransactions.isEmpty
                    ? _buildEmptyState(isDarkMode)
                    : _buildTransactionsList(filteredTransactions, currencyProvider, isDarkMode),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPeriodTotals(Map<String, double> totals, String symbol, Color themeColor, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildTotalCard('Today', totals['Today']!, symbol, themeColor),
              const SizedBox(width: 12),
              _buildTotalCard('This Week', totals['Week']!, symbol, themeColor),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTotalCard('This Month', totals['Month']!, symbol, themeColor),
              const SizedBox(width: 12),
              _buildTotalCard('This Year', totals['Year']!, symbol, themeColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(String label, double amount, String symbol, Color themeColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppTheme.formatCurrency(amount, symbol: symbol),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(List<Transaction> transactions, CurrencyProvider cp, bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final t = transactions[index];
        final isExpense = !t.isIncome;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF1F5F9),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isExpense ? AppTheme.expenseColor : AppTheme.incomeColor).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppTheme.getCategoryIcon(t.categoryName),
                size: 18,
                color: isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
              ),
            ),
            title: Text(
              t.description.isNotEmpty ? t.description : t.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : AppTheme.primaryColor,
              ),
            ),
            subtitle: Text(
              DateFormat('MMM dd, yyyy').format(t.date),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            trailing: Text(
              AppTheme.formatCurrency(t.amount.abs(), symbol: cp.currentCurrencySymbol),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTransactionScreen(
                    transactionToEdit: {
                      'id': t.id,
                      'amount': t.amount.abs(),
                      'note': t.description,
                      'date': t.date.toIso8601String(),
                      'category': t.categoryName,
                      'type': t.isIncome ? 'Income' : 'Expense',
                      'is_recurring': t.isRecurring ? 1 : 0,
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
