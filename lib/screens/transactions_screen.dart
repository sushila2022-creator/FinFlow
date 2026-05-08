import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:finflow/providers/transaction_provider.dart'
    show TransactionProvider, UserNotAuthenticatedException;
import 'package:finflow/providers/currency_provider.dart';
import 'package:finflow/models/transaction.dart';
import 'package:finflow/utils/app_theme.dart';
import 'package:finflow/screens/add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final String? title;
  final String? categoryName;
  final bool? initialIsIncome;

  const TransactionsScreen({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    this.title,
    this.categoryName,
    this.initialIsIncome,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filterType = 'All'; // 'All', 'Income', 'Expense'
  String _searchQuery = '';
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategory;
  bool? _selectedIsIncome;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _selectedCategory = widget.categoryName;
    _selectedIsIncome = widget.initialIsIncome;
    if (_selectedIsIncome != null) {
      _filterType = _selectedIsIncome! ? 'Income' : 'Expense';
    }
  }

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
        _selectedIsIncome = null;
      } else {
        _filterType = type;
        _selectedIsIncome = type == 'Income';
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getDynamicTitle(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if (_startDate != null && _endDate != null)
            Text(
              _getDateRangeText(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
        ],
      );
    }

    return Container(
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
          if (!transactionProvider.isInitialized &&
              transactionProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Fetching transactions...'),
                ],
              ),
            );
          }

          final filteredTransactions = _getFilteredTransactions(
            transactionProvider.transactions,
          );

          final monthlyTotals = _calculateMonthlyTotals(
            transactionProvider.transactions,
            currencyProvider,
          );

          return Column(
            children: [
              if (_startDate != null || _endDate != null || _selectedCategory != null || _selectedIsIncome != null)
                _buildFilterChips(),
              _buildSummaryCards(
                monthlyTotals,
                currencyProvider.currentCurrencySymbol,
              ),
              Expanded(
                child: _buildTransactionsList(
                  filteredTransactions,
                  currencyProvider,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getDynamicTitle() {
    if (_selectedCategory != null) return '$_selectedCategory Transactions';
    
    String typeLabel = _filterType == 'All' ? 'Transactions' : _filterType;
    
    if (widget.title != null && widget.title!.contains(':')) {
       final parts = widget.title!.split(':');
       if (_filterType == 'All') return 'Transactions';
       return '$typeLabel:${parts[1]}';
    }
    
    return typeLabel;
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_startDate != null && _endDate != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    _getDateRangeText(),
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  onSelected: (_) => setState(() { _startDate = null; _endDate = null; }),
                  selected: true,
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  checkmarkColor: AppTheme.primaryColor,
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => setState(() { _startDate = null; _endDate = null; }),
                ),
              ),
            if (_selectedCategory != null)
              FilterChip(
                label: Text(
                  _selectedCategory!,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
                ),
                onSelected: (_) => setState(() { _selectedCategory = null; }),
                selected: true,
                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                checkmarkColor: AppTheme.primaryColor,
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () => setState(() { _selectedCategory = null; }),
              ),
            if (_selectedIsIncome != null)
              FilterChip(
                label: Text(
                  _selectedIsIncome! ? 'Income Only' : 'Expense Only',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
                ),
                onSelected: (_) => setState(() { _selectedIsIncome = null; _filterType = 'All'; }),
                selected: true,
                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                checkmarkColor: AppTheme.primaryColor,
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () => setState(() { _selectedIsIncome = null; _filterType = 'All'; }),
              ),
          ],
        ),
      ),
    );
  }

  String _getDateRangeText() {
    if (_startDate == null || _endDate == null) return '';
    final df = DateFormat('MMM dd');
    if (_startDate == _endDate) return df.format(_startDate!);
    return '${df.format(_startDate!)} - ${df.format(_endDate!)}';
  }

  List<Transaction> _getFilteredTransactions(
    List<Transaction> allTransactions,
  ) {
    final sortedTransactions = allTransactions
      ..sort((a, b) => b.date.compareTo(a.date));

    return sortedTransactions.where((transaction) {
      final matchesQuery =
          _searchQuery.isEmpty ||
          transaction.description.toLowerCase().contains(_searchQuery) ||
          transaction.categoryName.toLowerCase().contains(_searchQuery) ||
          transaction.title.toLowerCase().contains(_searchQuery);

      bool matchesType = true;
      if (_filterType == 'Income') {
        matchesType = transaction.isIncome;
      } else if (_filterType == 'Expense') {
        matchesType = !transaction.isIncome;
      }

      bool matchesDate = true;
      if (_startDate != null && _endDate != null) {
        final trDate = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        matchesDate = (trDate.isAtSameMomentAs(start) || trDate.isAfter(start)) &&
            (trDate.isAtSameMomentAs(end) || trDate.isBefore(end));
      }

      bool matchesCategory = true;
      if (_selectedCategory != null) {
        matchesCategory = transaction.categoryName.toLowerCase() == _selectedCategory!.toLowerCase();
      }

      return matchesQuery && matchesType && matchesDate && matchesCategory;
    }).toList();
  }

  Map<String, double> _calculateMonthlyTotals(
    List<Transaction> transactions,
    CurrencyProvider currencyProvider,
  ) {
    final targetCode = currencyProvider.currentCurrencyCode;
    final filteredTransactions = transactions.where((t) {
      bool matchesDate = true;
      if (_startDate != null && _endDate != null) {
        final trDate = DateTime(t.date.year, t.date.month, t.date.day);
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        matchesDate = (trDate.isAtSameMomentAs(start) || trDate.isAfter(start)) &&
            (trDate.isAtSameMomentAs(end) || trDate.isBefore(end));
      } else {
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        matchesDate = t.date.isAfter(startOfMonth.subtract(const Duration(days: 1)));
      }

      bool matchesCategory = true;
      if (_selectedCategory != null) {
        matchesCategory = t.categoryName.toLowerCase() == _selectedCategory!.toLowerCase();
      }

      return matchesDate && matchesCategory;
    }).toList();

    double income = 0.0;
    double expense = 0.0;

    for (var t in filteredTransactions) {
      final amount = currencyProvider.convertAmount(
        t.amount,
        t.currencyCode,
        targetCode,
      );

      if (t.isIncome) {
        income += amount;
      } else {
        expense += amount;
      }
    }

    return {'income': income, 'expense': expense};
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
                            Icons.arrow_upward,
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
                            text: NumberFormat(
                              '#,##0',
                            ).format(monthlyTotals['income']!),
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
                            Icons.arrow_downward,
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
                            text: NumberFormat(
                              '#,##0',
                            ).format(monthlyTotals['expense']!),
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
    List<Transaction> transactions,
    CurrencyProvider currencyProvider,
  ) {
    if (transactions.isEmpty) {
      return _buildEmptyState();
    }

    final groupedTransactions = _groupTransactionsByDate(transactions);
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final List<dynamic> flattenedItems = [];
    for (final date in sortedDates) {
      flattenedItems.add(date); 
      flattenedItems.addAll(groupedTransactions[date]!);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: flattenedItems.length,
      itemBuilder: (context, index) {
        final item = flattenedItems[index];
        if (item is String) {
          final date = DateTime.parse(item);
          final isToday = DateUtils.isSameDay(date, DateTime.now());
          final isYesterday = DateUtils.isSameDay(
            date,
            DateTime.now().subtract(const Duration(days: 1)),
          );

          String dateLabel;
          if (isToday) {
            dateLabel = 'TODAY';
          } else if (isYesterday) {
            dateLabel = 'YESTERDAY';
          } else {
            dateLabel = DateFormat('EEE, MMM dd, yyyy').format(date).toUpperCase();
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              dateLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF1A1A1A),
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        } else {
          return _buildTransactionCard(item as Transaction, currencyProvider);
        }
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
            try {
              await transactionProvider.deleteTransaction(transaction.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } on UserNotAuthenticatedException catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.message),
                    backgroundColor: AppTheme.expenseColor,
                    action: SnackBarAction(
                      label: 'Login',
                      textColor: Colors.white,
                      onPressed: () {
                        if (mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ),
                );
              }
              return false;
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error deleting transaction: ${e.toString()}',
                    ),
                    backgroundColor: AppTheme.expenseColor,
                  ),
                );
              }
              return false;
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
          trailing: (() {
            // Convert the stored amount to the user's selected base currency
            // before displaying. Without this conversion, a transaction stored
            // as INR 5000 would appear as $5000 (wrong) when USD is selected.
            final convertedAmount = currencyProvider.convertAmount(
              transaction.amount.abs(),
              transaction.currencyCode,
              currencyProvider.currentCurrencyCode,
            );
            return RichText(
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
                    text: NumberFormat('#,##0').format(convertedAmount),
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
            );
          }()),
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
