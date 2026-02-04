import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:finflow/providers/transaction_provider.dart';
import 'package:finflow/providers/currency_provider.dart';
import 'package:finflow/models/transaction.dart';
import 'package:finflow/utils/app_theme.dart';
import 'package:finflow/screens/add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filterType = 'All'; // 'All', 'Income', 'Expense'
  String _searchQuery = '';
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleFilter(String type) {
    setState(() {
      if (_filterType == type) {
        _filterType = 'All';
      } else {
        _filterType = type;
      }
    });
  }

  void _toggleFilterSearch() {
    setState(() {
      if (_isSearchExpanded) {
        _isSearchExpanded = false;
        _searchQuery = '';
        _searchController.clear();
        _searchFocusNode.unfocus();
      } else {
        _isSearchExpanded = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      }
    });
  }

  Widget _buildSearchField() {
    if (!_isSearchExpanded) {
      return Text(
        'Transactions',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          autofocus: true,
          style: TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: 'PlusJakartaSans',
          ),
          cursorColor: Colors.black,
          cursorWidth: 2,
          keyboardType: TextInputType.text,
          keyboardAppearance: Theme.of(context).brightness,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search transactions...',
            hintStyle: TextStyle(
              color: Theme.of(context).hintColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'PlusJakartaSans',
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            prefixIcon: Icon(
              Icons.search,
              color: Theme.of(context).hintColor,
              size: 20,
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // AppBar always dark navy with white text/icons
    final appBarBgColor = AppTheme.primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: appBarBgColor,
        elevation: 0,
        title: _buildSearchField(),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            color: Colors.white,
            icon: _isSearchExpanded
                ? const Icon(Icons.close, color: Colors.white)
                : const Icon(Icons.search, color: Colors.white),
            onPressed: _toggleFilterSearch,
          ),
        ],
      ),
      body: Consumer2<TransactionProvider, CurrencyProvider>(
        builder: (context, transactionProvider, currencyProvider, child) {
          // Get and filter transactions
          final filteredTransactions = _getFilteredTransactions(
            transactionProvider.transactions,
          );

          // Calculate monthly totals (independent of filter)
          final monthlyTotals = _calculateMonthlyTotals(
            transactionProvider.transactions,
          );

          // Group transactions by date
          final groupedTransactions = _groupTransactionsByDate(
            filteredTransactions,
          );

          return Column(
            children: [
              // Header Summary (Interactive Toggle Buttons)
              _buildSummaryCards(
                monthlyTotals,
                currencyProvider.currentCurrencySymbol,
              ),
              // Transactions List
              Expanded(
                child: filteredTransactions.isEmpty
                    ? _buildEmptyState()
                    : _buildTransactionsList(
                        groupedTransactions,
                        currencyProvider,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper methods for better code organization
  List<Transaction> _getFilteredTransactions(
    List<Transaction> allTransactions,
  ) {
    final sortedTransactions = allTransactions
      ..sort((a, b) => b.date.compareTo(a.date));

    return sortedTransactions.where((transaction) {
      // Search Query Filter
      final matchesQuery =
          _searchQuery.isEmpty ||
          transaction.description.toLowerCase().contains(_searchQuery) ||
          transaction.categoryName.toLowerCase().contains(_searchQuery) ||
          transaction.title.toLowerCase().contains(_searchQuery);

      // Type Filter (Income/Expense)
      bool matchesType = true;
      if (_filterType == 'Income') {
        matchesType = transaction.isIncome;
      } else if (_filterType == 'Expense') {
        matchesType = !transaction.isIncome;
      }

      return matchesQuery && matchesType;
    }).toList();
  }

  Map<String, double> _calculateMonthlyTotals(List<Transaction> transactions) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final monthlyTransactions = transactions
        .where(
          (t) => t.date.isAfter(startOfMonth.subtract(const Duration(days: 1))),
        )
        .toList();

    final totalIncome = monthlyTransactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpense = monthlyTransactions
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);

    return {'income': totalIncome, 'expense': totalExpense};
  }

  Map<String, List<Transaction>> _groupTransactionsByDate(
    List<Transaction> transactions,
  ) {
    final groupedTransactions = <String, List<Transaction>>{};

    for (final transaction in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      if (groupedTransactions[dateKey] == null) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(transaction);
    }

    return groupedTransactions;
  }

  Widget _buildSummaryCards(
    Map<String, double> monthlyTotals,
    String currencySymbol,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Income Toggle
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleFilter('Income'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: _filterType == 'Income'
                      ? AppTheme.incomeColor.withValues(alpha: 0.15)
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _filterType == 'Income'
                        ? AppTheme.incomeColor
                        : Colors.transparent,
                    width: 1.5,
                  ),
                  boxShadow: _filterType == 'Income'
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.incomeColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_downward,
                            size: 14,
                            color: AppTheme.incomeColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Income',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: currencySymbol,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.incomeColor,
                            ),
                          ),
                          TextSpan(
                            text: monthlyTotals['income']!.toStringAsFixed(0),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.incomeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Expense Toggle
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleFilter('Expense'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: _filterType == 'Expense'
                      ? AppTheme.expenseColor.withValues(alpha: 0.15)
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _filterType == 'Expense'
                        ? AppTheme.expenseColor
                        : Colors.transparent,
                    width: 1.5,
                  ),
                  boxShadow: _filterType == 'Expense'
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.expenseColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_upward,
                            size: 14,
                            color: AppTheme.expenseColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Expense',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: currencySymbol,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.expenseColor,
                            ),
                          ),
                          TextSpan(
                            text: monthlyTotals['expense']!.toStringAsFixed(0),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.expenseColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(
    Map<String, List<Transaction>> groupedTransactions,
    CurrencyProvider currencyProvider,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: groupedTransactions.keys.length,
      itemBuilder: (context, index) {
        final dateKey = groupedTransactions.keys.elementAt(index);
        final dateTransactions = groupedTransactions[dateKey]!;
        final date = DateTime.parse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                DateFormat('dd/MM').format(date),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // Transactions for this date
            ...dateTransactions.map(
              (transaction) =>
                  _buildTransactionCard(transaction, currencyProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionCard(
    Transaction transaction,
    CurrencyProvider currencyProvider,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isExpense = !transaction.isIncome;
    final categoryIcon = AppTheme.getCategoryIcon(transaction.categoryName);

    return Dismissible(
      key: Key(transaction.id.toString()),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.accentColor,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.edit, color: Colors.white, size: 24),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.expenseColor,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Edit
          final addTransactionScreen = AddTransactionScreen(
            transactionToEdit: {
              'id': transaction.id,
              'amount': transaction.amount.abs(),
              'note': transaction.description,
              'date': transaction.date.toIso8601String(),
              'category': transaction.categoryName,
              'type': transaction.isIncome ? 'Income' : 'Expense',
              'is_recurring': transaction.isRecurring ? 1 : 0,
            },
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => addTransactionScreen),
          );
          return false;
        } else {
          // Delete
          final shouldDelete = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Transaction'),
              content: const Text(
                'Are you sure you want to delete this transaction?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
          if (!mounted) return false;
          if (shouldDelete == true) {
            final transactionProvider = Provider.of<TransactionProvider>(
              context,
              listen: false,
            );
            await transactionProvider.deleteTransaction(transaction.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
          return shouldDelete ?? false;
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 0,
          vertical: 0,
        ), // Full width, no gaps
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isDarkMode
                  ? const Color(0xFF2D2D2D)
                  : const Color(0xFFF1F5F9),
              width: 1,
            ),
          ),
        ),
        child: ListTile(
          dense: true,
          visualDensity: const VisualDensity(
            horizontal: 0,
            vertical: -4,
          ), // Maximum compactness
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, // Keep internal padding for readability
            vertical: 0,
          ),
          leading: Container(
            width: 32, // Slightly larger touch target for icon
            height: 32,
            decoration: BoxDecoration(
              color: (isExpense ? AppTheme.expenseColor : AppTheme.incomeColor)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16), // Circle
            ),
            child: Icon(
              categoryIcon,
              color: isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
              size: 16, // Small icon
            ),
          ),
          title: Text(
            transaction.description.isNotEmpty
                ? transaction.description
                : transaction.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600, // Semi-bold for cleaner look
              color: isDarkMode
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
            ),
          ),
          subtitle: Text(
            '${transaction.categoryName} • ${DateFormat('MMM dd').format(transaction.date)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: isDarkMode
                  ? const Color(0xFFB0B0B0)
                  : const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: currencyProvider.currentCurrencySymbol,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isExpense
                        ? AppTheme.expenseColor
                        : AppTheme.incomeColor,
                  ),
                ),
                TextSpan(
                  text: transaction.amount.abs().toStringAsFixed(
                    transaction.amount.abs().truncateToDouble() ==
                            transaction.amount.abs()
                        ? 0
                        : 2,
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, // Standardized to match Dashboard
                    fontWeight: FontWeight.w600,
                    color: isExpense
                        ? AppTheme.expenseColor
                        : AppTheme.incomeColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.receipt_long,
              size: 64,
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Transactions',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transactions will appear here',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}
