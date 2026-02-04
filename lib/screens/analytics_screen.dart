import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:finflow/providers/transaction_provider.dart';
import 'package:finflow/providers/currency_provider.dart';
import 'package:finflow/providers/theme_provider.dart';
import 'package:finflow/utils/app_theme.dart';
import 'package:finflow/models/transaction.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedTabIndex = 0;
  bool _showExpenses = true;
  final List<String> _tabLabels = ['Today', 'Week', 'Month', 'Year'];
  DateTime _selectedStartDate = DateTime.now();
  DateTime _selectedEndDate = DateTime.now();

  // Caching and debouncing
  final Map<String, Map<String, double>> _cachedCategoryData = {};
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _updateDateRangeForTab(_selectedTabIndex);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _updateDateRangeForTab(int tabIndex) {
    final now = DateTime.now();
    switch (tabIndex) {
      case 0: // Today
        _selectedStartDate = DateTime(now.year, now.month, now.day);
        _selectedEndDate = _selectedStartDate;
        break;
      case 1: // Week
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        _selectedStartDate = startOfWeek;
        _selectedEndDate = startOfWeek.add(const Duration(days: 6));
        break;
      case 2: // Month
        _selectedStartDate = DateTime(now.year, now.month, 1);
        _selectedEndDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 3: // Year
        _selectedStartDate = DateTime(now.year, 1, 1);
        _selectedEndDate = DateTime(now.year, 12, 31);
        break;
    }
  }

  Map<String, double> _computeCategoryData(
    List<Transaction> transactions,
    bool isIncome,
  ) {
    // Create cache key based on filter parameters
    final cacheKey = _createCacheKey(transactions, isIncome);

    // Check if we have cached data
    if (_cachedCategoryData.containsKey(cacheKey)) {
      return _cachedCategoryData[cacheKey]!;
    }

    // Compute new data with optimized filtering
    final Map<String, double> categoryData = {};
    final targetIsIncome = isIncome;

    // Use for loop for better performance than where().fold()
    for (var i = 0; i < transactions.length; i++) {
      final transaction = transactions[i];
      if (transaction.isIncome == targetIsIncome) {
        final category = transaction.categoryName;
        final amount = transaction.amount.abs();
        categoryData.update(
          category,
          (value) => value + amount,
          ifAbsent: () => amount,
        );
      }
    }

    // Cache the result
    _cachedCategoryData[cacheKey] = categoryData;

    // Limit cache size to prevent memory issues
    if (_cachedCategoryData.length > 25) {
      // Remove oldest entries when cache gets too large
      final keysToRemove = _cachedCategoryData.keys.take(5).toList();
      for (final key in keysToRemove) {
        _cachedCategoryData.remove(key);
      }
    }

    return categoryData;
  }

  String _createCacheKey(List<Transaction> transactions, bool isIncome) {
    // Create a unique key based on the filter parameters
    // Use more specific parameters for better cache hit rate
    final transactionCount = transactions.length;
    final lastTransactionDate = transactions.isNotEmpty
        ? transactions.last.date.toIso8601String()
        : 'empty';
    final filterType = isIncome ? 'income' : 'expenses';
    final dateRange =
        '${_selectedStartDate.toIso8601String()}-${_selectedEndDate.toIso8601String()}';
    final tabIndex = _selectedTabIndex;

    // Include more specific parameters for better cache accuracy
    return '$transactionCount-$lastTransactionDate-$filterType-$dateRange-$tabIndex-${transactions.isNotEmpty ? transactions.first.id : 'no-transactions'}';
  }

  void _debouncedUpdateTab(int tabIndex) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      setState(() {
        _selectedTabIndex = tabIndex;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2B45),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _getDateRangeDisplay(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Consumer2<TransactionProvider, CurrencyProvider>(
          builder: (context, transactionProvider, currencyProvider, child) {
            final allTransactions = transactionProvider.transactions;
            final currencySymbol = currencyProvider.currentCurrencySymbol;

            // Filter transactions based on selected tab
            final filteredTransactions = _filterTransactionsByTab(
              allTransactions,
              _selectedTabIndex,
            );

            // Get data for the selected view
            final selectedData = _computeCategoryData(
              filteredTransactions,
              !_showExpenses, // If not showing expenses, show income
            );

            final totalAmount = selectedData.values.fold(
              0.0,
              (sum, amount) => sum + amount,
            );

            return Column(
              children: [
                // Tab Bar
                _buildTabBar(isDarkMode),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),

                          // Toggle and Total
                          _buildToggleAndTotal(
                            totalAmount,
                            currencySymbol,
                            isDarkMode,
                          ),

                          const SizedBox(height: 16),

                          const SizedBox(height: 24),

                          // Summary Section (Net Balance Only)
                          _buildSummarySection(
                            filteredTransactions,
                            currencySymbol,
                            isDarkMode,
                          ),

                          const SizedBox(height: 24),

                          // Spending by Category Header
                          _buildCategoryHeader(isDarkMode),

                          const SizedBox(height: 12),

                          // Pie Chart
                          _buildPieChart(selectedData, totalAmount, isDarkMode),

                          const SizedBox(height: 12),

                          // Category List
                          _buildCategoryList(
                            selectedData,
                            totalAmount,
                            currencySymbol,
                            isDarkMode,
                          ),

                          const SizedBox(height: 80), // Space for bottom nav
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Transaction> _filterTransactionsByTab(
    List<Transaction> transactions,
    int tabIndex,
  ) {
    // Update date range when switching tabs (only for predefined tabs)
    if (tabIndex >= 0) {
      _updateDateRangeForTab(tabIndex);
    }

    return transactions.where((transaction) {
      // Check if transaction date is within the selected date range
      final transactionDate = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      final startDate = DateTime(
        _selectedStartDate.year,
        _selectedStartDate.month,
        _selectedStartDate.day,
      );
      final endDate = DateTime(
        _selectedEndDate.year,
        _selectedEndDate.month,
        _selectedEndDate.day,
      );

      return transactionDate.isAtSameMomentAs(startDate) ||
          (transactionDate.isAfter(
                startDate.subtract(const Duration(days: 1)),
              ) &&
              transactionDate.isBefore(endDate.add(const Duration(days: 1))));
    }).toList();
  }

  Widget _buildTabBar(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: List.generate(_tabLabels.length, (index) {
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  _debouncedUpdateTab(index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedTabIndex == index
                        ? AppTheme.primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _selectedTabIndex == index
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    _tabLabels[index],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: _selectedTabIndex == index
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: _selectedTabIndex == index
                          ? Colors.white
                          : (isDarkMode
                                ? const Color(0xFFB0B0B0)
                                : const Color(0xFF64748B)),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildToggleAndTotal(
    double totalAmount,
    String currencySymbol,
    bool isDarkMode,
  ) {
    return Row(
      children: [
        // Toggle Switch
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF1E1E1E)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              // Expenses Button
              GestureDetector(
                onTap: () => setState(() => _showExpenses = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, // Reduced from 16 to prevent overflow
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _showExpenses ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _showExpenses
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.south_west,
                        size: 16,
                        color: _showExpenses
                            ? AppTheme.expenseColor
                            : (isDarkMode
                                  ? const Color(0xFFB0B0B0)
                                  : const Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 4), // Reduced from 6
                      Text(
                        'Expenses',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _showExpenses
                              ? AppTheme.primaryColor
                              : (isDarkMode
                                    ? const Color(0xFFB0B0B0)
                                    : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Income Button
              GestureDetector(
                onTap: () => setState(() => _showExpenses = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, // Reduced from 16
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: !_showExpenses ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: !_showExpenses
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.north_east,
                        size: 16,
                        color: !_showExpenses
                            ? AppTheme.incomeColor
                            : (isDarkMode
                                  ? const Color(0xFFB0B0B0)
                                  : const Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 4), // Reduced from 6
                      Text(
                        'Income',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: !_showExpenses
                              ? AppTheme.primaryColor
                              : (isDarkMode
                                    ? const Color(0xFFB0B0B0)
                                    : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Total Amount
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _showExpenses ? 'Total Spent' : 'Total Earned',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: isDarkMode
                    ? const Color(0xFFB0B0B0)
                    : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              AppTheme.formatCurrency(totalAmount, symbol: currencySymbol),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16, // Reduced size for better balance
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : AppTheme.primaryColor,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryHeader(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Spending by Category',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDarkMode ? Colors.white : AppTheme.primaryColor,
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Text(
            'View All',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.incomeColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryList(
    Map<String, double> data,
    double totalAmount,
    String currencySymbol,
    bool isDarkMode,
  ) {
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: isDarkMode
                  ? const Color(0xFFB0B0B0)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(height: 12),
            Text(
              'No data available',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add some transactions to see category breakdown',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDarkMode
                    ? const Color(0xFFB0B0B0)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    // Sort categories by amount (descending)
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Get colors for each category to match pie chart
    final colors = sortedEntries.map((entry) {
      return AppTheme.getCategoryColor(entry.key, isIncome: !_showExpenses);
    }).toList();

    return Column(
      children: sortedEntries.map((entry) {
        final index = sortedEntries.indexOf(entry);
        final categoryColor = colors[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode
                  ? const Color(0xFF2D2D2D)
                  : const Color(0xFFF1F5F9),
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Category Color Indicator
              Container(
                width: 8,
                height: 40,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Category Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  AppTheme.getCategoryIcon(entry.key),
                  size: 18,
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: 12),

              // Category Name and Percentage
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      entry.key,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? Colors.white
                            : AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${((entry.value / totalAmount) * 100).toStringAsFixed(1)}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDarkMode
                            ? const Color(0xFFB0B0B0)
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount - Right-aligned and vertically centered
              Container(
                alignment: Alignment.centerRight,
                constraints: const BoxConstraints(minWidth: 80),
                child: Text(
                  AppTheme.formatCurrency(entry.value, symbol: currencySymbol),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount,
    String currencySymbol,
    Color iconColor,
    IconData icon,
    bool isDarkMode,
  ) {
    final isPositive = amount >= 0;
    final displayAmount = amount.abs();

    return Row(
      children: [
        // Icon and Label
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : AppTheme.primaryColor,
              ),
            ),
          ],
        ),

        const Spacer(),

        // Amount
        Text(
          '${isPositive ? '+' : '-'}${AppTheme.formatCurrency(displayAmount, symbol: currencySymbol)}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isPositive ? AppTheme.incomeColor : AppTheme.expenseColor,
          ),
        ),
      ],
    );
  }

  String _getPeriodLabel() {
    final now = DateTime.now();
    switch (_selectedTabIndex) {
      case 0:
        return 'Today';
      case 1:
        return 'This Week';
      case 2:
        return '${_getMonthName(now.month)} ${now.year}';
      case 3:
        return 'Year ${now.year}';
      default:
        return 'Period';
    }
  }

  String _getMonthName(int month) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _getDateRangeDisplay() {
    final now = DateTime.now();
    switch (_selectedTabIndex) {
      case 0:
        return 'Today • ${_getMonthName(now.month)} ${now.day}, ${now.year}';
      case 1:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return 'This Week • ${_getMonthName(startOfWeek.month)} ${startOfWeek.day} - ${_getMonthName(endOfWeek.month)} ${endOfWeek.day}';
      case 2:
        return '${_getMonthName(now.month)} ${now.year}';
      case 3:
        return 'Year ${now.year}';
      default:
        return '${_getMonthName(now.month)} ${now.year}';
    }
  }

  Widget _buildPieChart(
    Map<String, double> data,
    double totalAmount,
    bool isDarkMode,
  ) {
    if (data.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode
                ? const Color(0xFF2D2D2D)
                : const Color(0xFFF1F5F9),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 48,
                color: isDarkMode
                    ? const Color(0xFFB0B0B0)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(height: 8),
              Text(
                'No data to display',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: isDarkMode
                      ? const Color(0xFFB0B0B0)
                      : const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sort categories by amount (descending) and get colors
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = sortedEntries.map((entry) {
      return AppTheme.getCategoryColor(entry.key, isIncome: !_showExpenses);
    }).toList();

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(
        children: [
          // Chart Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _showExpenses
                      ? 'Spending Distribution'
                      : 'Income Distribution',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : AppTheme.primaryColor,
                  ),
                ),
                Text(
                  AppTheme.formatCurrency(totalAmount),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Pie Chart
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Chart Area
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF2D2D2D)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(80),
                          border: Border.all(
                            color: isDarkMode
                                ? const Color(0xFF404040)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: CustomPaint(
                          painter: _PieChartPainter(
                            data: sortedEntries,
                            colors: colors,
                            totalAmount: totalAmount,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Legend
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: sortedEntries.length,
                      itemBuilder: (context, index) {
                        final entry = sortedEntries[index];
                        final color = colors[index];
                        final percentage = ((entry.value / totalAmount) * 100);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode
                                        ? Colors.white
                                        : AppTheme.primaryColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? Colors.white
                                      : AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(
    List<Transaction> filteredTransactions,
    String currencySymbol,
    bool isDarkMode,
  ) {
    // Get expenses and income data for the selected period
    final expensesData = _computeCategoryData(
      filteredTransactions,
      false, // Expenses
    );

    final incomeData = _computeCategoryData(
      filteredTransactions,
      true, // Income
    );

    final totalExpenses = expensesData.values.fold(
      0.0,
      (sum, amount) => sum + amount,
    );
    final totalIncome = incomeData.values.fold(
      0.0,
      (sum, amount) => sum + amount,
    );

    final netBalance = totalIncome - totalExpenses;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Summary',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : AppTheme.primaryColor,
                ),
              ),
              Text(
                _getPeriodLabel(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDarkMode
                      ? const Color(0xFFB0B0B0)
                      : const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Net Balance Row Only
          _buildSummaryRow(
            'Net Balance',
            netBalance,
            currencySymbol,
            (netBalance) >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor,
            (netBalance) >= 0 ? Icons.north_east : Icons.south_west,
            isDarkMode,
          ),
        ],
      ),
    );
  }
}

// Custom painter for the pie chart
class _PieChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> data;
  final List<Color> colors;
  final double totalAmount;
  final bool isDarkMode;

  _PieChartPainter({
    required this.data,
    required this.colors,
    required this.totalAmount,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;

    double startAngle = -pi / 2; // Start from top

    for (int i = 0; i < data.length; i++) {
      final entry = data[i];
      final color = colors[i];
      final sweepAngle = (entry.value / totalAmount) * 2 * pi;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }

    // Draw center circle for donut effect
    final centerPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.6, centerPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF404040) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, borderPaint);
    canvas.drawCircle(center, radius * 0.6, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
