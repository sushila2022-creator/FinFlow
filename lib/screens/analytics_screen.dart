import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:finflow/providers/transaction_provider.dart';
import 'package:finflow/providers/currency_provider.dart';
import 'package:finflow/providers/theme_provider.dart';
import 'package:finflow/utils/app_theme.dart';
import 'package:finflow/models/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedTabIndex = 0; // Today is selected by default
  bool _showExpenses = true; // Toggle between Expenses and Income
  final List<String> _tabLabels = ['Today', 'Week', 'Month', 'Year'];

  // SINGLE SOURCE OF TRUTH: Current selected period
  DateTime _selectedPeriod = DateTime.now();

  // Debouncing and caching
  Timer? _debounceTimer;
  static const _cacheKeyPrefix = 'analytics_cache_';

  @override
  void initState() {
    super.initState();
    // Set default to current year for Year tab
    _selectedPeriod = DateTime.now();
    debugPrint('Analytics: Initialized with selectedPeriod: $_selectedPeriod');

    // Load cached data if available
    _loadCachedData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _getCacheKey();
    final cachedData = prefs.getString(cacheKey);

    if (cachedData != null) {
      // Data is cached, use it
      // Note: In a real implementation, you'd parse the cached JSON
      // For now, we'll just trigger a refresh to get fresh data
      _refreshData();
    }
  }

  String _getCacheKey() {
    final period = _getPeriodString();
    return '$_cacheKeyPrefix${_selectedTabIndex}_$period';
  }

  String _getPeriodString() {
    switch (_selectedTabIndex) {
      case 0: // Today
        return _selectedPeriod.toIso8601String().split('T').first;
      case 1: // Week
        // Calculate week of year manually
        final firstDayOfYear = DateTime(_selectedPeriod.year, 1, 1);
        final daysSinceFirst = _selectedPeriod
            .difference(firstDayOfYear)
            .inDays;
        final weekOfYear = (daysSinceFirst ~/ 7) + 1;
        return 'week_${_selectedPeriod.year}_$weekOfYear';
      case 2: // Month
        return '${_selectedPeriod.year}-${_selectedPeriod.month}';
      case 3: // Year
        return _selectedPeriod.year.toString();
      default:
        return 'default';
    }
  }

  void _refreshData() {
    // This would trigger data fetching in a real implementation
    // For now, we'll just rebuild the UI
    setState(() {
      // Update UI state
    });
  }

  // Color palette matching Dashboard's Deep Navy (#0D2B45) and Emerald (#006D5B)
  static const Color primaryNavy = Color(0xFF0D2B45);
  static const Color accentEmerald = Color(0xFF006D5B);

  // Scale factor for compact design
  double get _scale => 0.8;

  double _scaled(double value) => value * _scale;

  Map<String, double> _computeCategoryData(
    List<Transaction> transactions,
    bool isIncome,
  ) {
    final Map<String, double> categoryData = {};
    for (var transaction in transactions) {
      if ((isIncome && transaction.isIncome) ||
          (!isIncome && !transaction.isIncome)) {
        final category = transaction.categoryName;
        final amount = transaction.amount.abs();
        categoryData.update(
          category,
          (value) => value + amount,
          ifAbsent: () => amount,
        );
      }
    }
    return categoryData;
  }

  List<double> _getWeeklySpendingData(List<Transaction> transactions) {
    // Group by week of month (4 weeks)
    final List<double> weeklyTotals = List.filled(4, 0.0);

    for (var transaction in transactions) {
      if (!transaction.isIncome) {
        // Only expenses
        final weekOfMonth = ((transaction.date.day - 1) ~/ 7).clamp(0, 3);
        weeklyTotals[weekOfMonth] += transaction.amount.abs();
      }
    }

    return weeklyTotals;
  }

  List<double> _getDailySpendingData(List<Transaction> transactions) {
    // Group by day of week (7 days)
    final List<double> dailyTotals = List.filled(7, 0.0);

    for (var transaction in transactions) {
      if (!transaction.isIncome) {
        // Only expenses
        final dayOfWeek = transaction.date.weekday - 1; // 0-6 for Mon-Sun
        dailyTotals[dayOfWeek] += transaction.amount.abs();
      }
    }

    return dailyTotals;
  }

  List<double> _getMonthlySpendingData(List<Transaction> transactions) {
    // Group by month (12 months)
    final List<double> monthlyTotals = List.filled(12, 0.0);

    for (var transaction in transactions) {
      if (!transaction.isIncome) {
        // Only expenses
        final monthIndex = transaction.date.month - 1; // 0-11 for Jan-Dec
        monthlyTotals[monthIndex] += transaction.amount.abs();
      }
    }

    return monthlyTotals;
  }

  List<double> _getYearlySpendingData(List<Transaction> transactions) {
    // Group by year (last 5 years)
    final List<double> yearlyTotals = List.filled(5, 0.0);
    final currentYear = _selectedPeriod.year;

    for (var transaction in transactions) {
      if (!transaction.isIncome) {
        // Only expenses
        final yearDiff = currentYear - transaction.date.year;
        if (yearDiff >= 0 && yearDiff < 5) {
          yearlyTotals[yearDiff] += transaction.amount.abs();
        }
      }
    }

    return yearlyTotals;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2B45),
        toolbarHeight: 80,
        title: Text(
          'Analytics',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => _showMonthYearPicker(),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.calendar_today, size: 22, color: primaryNavy),
            ),
          ),
        ],
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

            // Get data for bar chart based on selected tab
            final chartData = _getChartDataForTab(
              filteredTransactions,
              _selectedTabIndex,
            );

            return Column(
              children: [
                // Tab Bar
                _buildTabBar(isDarkMode),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: _scaled(16)),
                      child: Column(
                        children: [
                          SizedBox(height: _scaled(16)),

                          // Toggle and Total
                          _buildToggleAndTotal(
                            totalAmount,
                            currencySymbol,
                            isDarkMode,
                          ),

                          SizedBox(height: _scaled(16)),

                          // Bar Chart (Dynamic based on selected tab)
                          _buildBarChart(chartData, isDarkMode),

                          SizedBox(height: _scaled(24)),

                          // Spending by Category Header
                          _buildCategoryHeader(isDarkMode),

                          SizedBox(height: _scaled(12)),

                          // Category List
                          _buildCategoryList(
                            selectedData,
                            totalAmount,
                            currencySymbol,
                            isDarkMode,
                          ),

                          SizedBox(height: _scaled(80)), // Space for bottom nav
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

  Future<void> _showMonthYearPicker() async {
    final isDarkMode = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).isDarkMode;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final now = DateTime.now();
          final currentYear = now.year;
          final years = List.generate(11, (index) => currentYear - 5 + index);
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

          // Use local state for picker selection
          int selectedYear = _selectedPeriod.year;
          int selectedMonth = _selectedPeriod.month;

          return Container(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(context).size.height * 0.6, // 40% reduction
            ),
            decoration: BoxDecoration(
              color: isDarkMode ? primaryNavy : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF404040)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Month & Year',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.white : primaryNavy,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedYear = currentYear;
                            selectedMonth = now.month;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: accentEmerald.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Today',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: accentEmerald,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Year Grid (Compact)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5, // Compact grid
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.8,
                        ),
                    itemCount: years.length,
                    itemBuilder: (context, index) {
                      final year = years[index];
                      final isSelected = year == selectedYear;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedYear = year;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accentEmerald
                                : (isDarkMode
                                      ? const Color(0xFF1A2536)
                                      : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? accentEmerald
                                  : (isDarkMode
                                        ? const Color(0xFF2D3A4D)
                                        : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              year.toString(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (isDarkMode ? Colors.white : primaryNavy),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Month Horizontal Scroll
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: months.length,
                    itemBuilder: (context, index) {
                      final monthIndex = index + 1;
                      final isSelected = monthIndex == selectedMonth;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedMonth = monthIndex;
                          });
                        },
                        child: Container(
                          width: 70,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accentEmerald
                                : (isDarkMode
                                      ? const Color(0xFF1A2536)
                                      : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? accentEmerald
                                  : (isDarkMode
                                        ? const Color(0xFF2D3A4D)
                                        : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                months[index],
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDarkMode
                                            ? Colors.white
                                            : primaryNavy),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                monthIndex.toString().padLeft(2, '0'),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : (isDarkMode
                                            ? Colors.white.withValues(
                                                alpha: 0.7,
                                              )
                                            : primaryNavy.withValues(
                                                alpha: 0.7,
                                              )),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Selected Date Preview
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF1A2536)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode
                          ? const Color(0xFF2D3A4D)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: accentEmerald,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${months[selectedMonth - 1]} $selectedYear',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.white : primaryNavy,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: isDarkMode
                                  ? const Color(0xFF404040)
                                  : const Color(0xFFE2E8F0),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? const Color(0xFFB0B0B0)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Select Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);

                            // Create new date from selection
                            final newDate = DateTime(
                              selectedYear,
                              selectedMonth,
                              1,
                            );

                            // Only update if selection actually changed
                            if (newDate != _selectedPeriod) {
                              // Cancel any existing debounce timer
                              _debounceTimer?.cancel();

                              // Update state immediately for instant UI feedback
                              setState(() {
                                _selectedPeriod = newDate;
                                debugPrint(
                                  'Analytics: Selected period updated to: $_selectedPeriod',
                                );
                              });

                              // Debounce the data refresh to minimize API calls
                              _debounceTimer = Timer(
                                const Duration(milliseconds: 300),
                                () {
                                  _refreshData();
                                },
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentEmerald,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Select',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 24),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Transaction> _filterTransactionsByTab(
    List<Transaction> transactions,
    int tabIndex,
  ) {
    // Update selectedPeriod to current date when switching to Today or Week tabs
    if (tabIndex == 0 || tabIndex == 1) {
      _selectedPeriod = DateTime.now();
    }

    final now = _selectedPeriod;
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    return transactions.where((transaction) {
      switch (tabIndex) {
        case 0: // Today
          return transaction.date.day == today.day &&
              transaction.date.month == today.month &&
              transaction.date.year == today.year;
        case 1: // Week
          return transaction.date.isAfter(
                startOfWeek.subtract(const Duration(days: 1)),
              ) &&
              transaction.date.isBefore(today.add(const Duration(days: 1)));
        case 2: // Month
          return transaction.date.month == now.month &&
              transaction.date.year == now.year;
        case 3: // Year
          return transaction.date.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildTabBar(bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _scaled(16)),
      child: Container(
        padding: EdgeInsets.all(_scaled(3)),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(_scaled(14)),
        ),
        child: Row(
          children: List.generate(_tabLabels.length, (index) {
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: _scaled(10)),
                  decoration: BoxDecoration(
                    color: _selectedTabIndex == index
                        ? primaryNavy
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(_scaled(11)),
                  ),
                  child: Text(
                    _tabLabels[index],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: _scaled(12),
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
          padding: EdgeInsets.all(_scaled(3)),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF1E1E1E)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(_scaled(12)),
          ),
          child: Row(
            children: [
              // Expenses Button
              GestureDetector(
                onTap: () => setState(() => _showExpenses = true),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _scaled(12),
                    vertical: _scaled(8),
                  ),
                  decoration: BoxDecoration(
                    color: _showExpenses ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(_scaled(10)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.south_west,
                        size: _scaled(12),
                        color: _showExpenses
                            ? const Color(0xFFF43F5E)
                            : (isDarkMode
                                  ? const Color(0xFFB0B0B0)
                                  : const Color(0xFF64748B)),
                      ),
                      SizedBox(width: _scaled(4)),
                      Text(
                        'Expenses',
                        style: GoogleFonts.inter(
                          fontSize: _scaled(11),
                          fontWeight: FontWeight.w600,
                          color: _showExpenses
                              ? primaryNavy
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
                  padding: EdgeInsets.symmetric(
                    horizontal: _scaled(12),
                    vertical: _scaled(8),
                  ),
                  decoration: BoxDecoration(
                    color: !_showExpenses ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(_scaled(10)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.north_east,
                        size: _scaled(12),
                        color: !_showExpenses
                            ? accentEmerald
                            : (isDarkMode
                                  ? const Color(0xFFB0B0B0)
                                  : const Color(0xFF64748B)),
                      ),
                      SizedBox(width: _scaled(4)),
                      Text(
                        'Income',
                        style: GoogleFonts.inter(
                          fontSize: _scaled(11),
                          fontWeight: FontWeight.w600,
                          color: !_showExpenses
                              ? primaryNavy
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

        Spacer(),

        // Total Amount
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _showExpenses ? 'Total Spent' : 'Total Earned',
              style: GoogleFonts.inter(
                fontSize: _scaled(10),
                fontWeight: FontWeight.w500,
                color: isDarkMode
                    ? const Color(0xFFB0B0B0)
                    : const Color(0xFF64748B),
              ),
            ),
            SizedBox(height: _scaled(2)),
            Text(
              AppTheme.formatCurrency(totalAmount, symbol: currencySymbol),
              style: GoogleFonts.inter(
                fontSize: _scaled(18),
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : primaryNavy,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBarChart(List<double> chartData, bool isDarkMode) {
    final maxValue = chartData.isNotEmpty
        ? chartData.reduce((a, b) => a > b ? a : b)
        : 1.0;

    // Get labels based on current tab
    final labels = _getChartLabels(_selectedTabIndex);

    return Container(
      padding: EdgeInsets.all(_scaled(16)),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(_scaled(20)),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(chartData.length, (index) {
              final heightPercent = maxValue > 0
                  ? (chartData[index] / maxValue)
                  : 0.0;
              final isHighlighted =
                  index == (chartData.length ~/ 2); // Highlight middle bar

              return Expanded(
                child: Column(
                  children: [
                    // Bar Container
                    Container(
                      height: _scaled(120),
                      margin: EdgeInsets.symmetric(horizontal: _scaled(4)),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // Background
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF2D2D2D)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(_scaled(6)),
                              ),
                            ),
                          ),

                          // Bar
                          AnimatedContainer(
                            duration: Duration(milliseconds: 600),
                            curve: Curves.easeOut,
                            height: _scaled(120) * heightPercent,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: accentEmerald.withValues(
                                alpha: isHighlighted
                                    ? 1.0
                                    : 0.3 + (heightPercent * 0.4),
                              ),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(_scaled(6)),
                              ),
                            ),
                          ),

                          // Highlight label on middle bar
                          if (isHighlighted && chartData[index] > 0)
                            Positioned(
                              top: _scaled(8),
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: _scaled(6),
                                    vertical: _scaled(2),
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryNavy,
                                    borderRadius: BorderRadius.circular(
                                      _scaled(4),
                                    ),
                                  ),
                                  child: Text(
                                    AppTheme.formatCurrency(
                                      chartData[index],
                                      symbol: '₹',
                                    ).replaceAll('.00', 'k'),
                                    style: GoogleFonts.inter(
                                      fontSize: _scaled(8),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: _scaled(8)),

                    // Label
                    Text(
                      labels[index],
                      style: GoogleFonts.inter(
                        fontSize: _scaled(9),
                        fontWeight: FontWeight.w700,
                        color: isHighlighted
                            ? (isDarkMode ? accentEmerald : primaryNavy)
                            : (isDarkMode
                                  ? const Color(0xFFB0B0B0)
                                  : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  List<String> _getChartLabels(int tabIndex) {
    switch (tabIndex) {
      case 0: // Today - Day of week
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      case 1: // Week - Week of month
        return ['01-07', '08-14', '15-21', '22-28'];
      case 2: // Month - Months of year
        return [
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
      case 3: // Year - Last 5 years
        final currentYear = _selectedPeriod.year;
        return [
          '${currentYear - 4}',
          '${currentYear - 3}',
          '${currentYear - 2}',
          '${currentYear - 1}',
          '$currentYear',
        ];
      default:
        return ['01-07', '08-14', '15-21', '22-28'];
    }
  }

  Widget _buildCategoryHeader(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Spending by Category',
          style: GoogleFonts.inter(
            fontSize: _scaled(16),
            fontWeight: FontWeight.w700,
            color: isDarkMode ? Colors.white : primaryNavy,
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Text(
            'View All',
            style: GoogleFonts.inter(
              fontSize: _scaled(12),
              fontWeight: FontWeight.w600,
              color: accentEmerald,
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
        padding: EdgeInsets.all(_scaled(20)),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(_scaled(16)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: _scaled(48),
              color: isDarkMode
                  ? const Color(0xFFB0B0B0)
                  : const Color(0xFF64748B),
            ),
            SizedBox(height: _scaled(12)),
            Text(
              'No data available',
              style: GoogleFonts.inter(
                fontSize: _scaled(14),
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : primaryNavy,
              ),
            ),
            SizedBox(height: _scaled(4)),
            Text(
              'Add some transactions to see category breakdown',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: _scaled(11),
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

    return Column(
      children: sortedEntries.map((entry) {
        final percentage = totalAmount > 0
            ? (entry.value / totalAmount) * 100
            : 0;
        final categoryColor = _getCategoryColor(entry.key);

        return Container(
          margin: EdgeInsets.only(bottom: _scaled(8)),
          padding: EdgeInsets.all(_scaled(16)),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(_scaled(16)),
            border: Border.all(
              color: isDarkMode
                  ? const Color(0xFF2D2D2D)
                  : const Color(0xFFF1F5F9),
            ),
          ),
          child: Row(
            children: [
              // Category Icon
              Container(
                width: _scaled(36),
                height: _scaled(36),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(_scaled(10)),
                ),
                child: Icon(
                  _getCategoryIcon(entry.key),
                  size: _scaled(18),
                  color: categoryColor,
                ),
              ),
              SizedBox(width: _scaled(12)),

              // Category Name and Percentage
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: GoogleFonts.inter(
                        fontSize: _scaled(13),
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : primaryNavy,
                      ),
                    ),
                    SizedBox(height: _scaled(2)),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: _scaled(11),
                        color: isDarkMode
                            ? const Color(0xFFB0B0B0)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // Amount
              Text(
                AppTheme.formatCurrency(entry.value, symbol: currencySymbol),
                style: GoogleFonts.inter(
                  fontSize: _scaled(14),
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : primaryNavy,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getCategoryColor(String category) {
    // Map categories to colors
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFF59E0B);
      case 'transport':
        return const Color(0xFF3B82F6);
      case 'shopping':
        return const Color(0xFF8B5CF6);
      case 'entertainment':
        return const Color(0xFFEC4899);
      case 'bills':
        return const Color(0xFF10B981);
      case 'health':
        return const Color(0xFFEF4444);
      case 'education':
        return const Color(0xFF6366F1);
      case 'travel':
        return const Color(0xFFF97316);
      default:
        return accentEmerald;
    }
  }

  IconData _getCategoryIcon(String category) {
    // Map categories to icons
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'bills':
        return Icons.receipt;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'travel':
        return Icons.flight;
      default:
        return Icons.category;
    }
  }

  List<double> _getChartDataForTab(
    List<Transaction> transactions,
    int tabIndex,
  ) {
    switch (tabIndex) {
      case 0: // Today
        return _getDailySpendingData(transactions);
      case 1: // Week
        return _getWeeklySpendingData(transactions);
      case 2: // Month
        return _getMonthlySpendingData(transactions);
      case 3: // Year
        return _getYearlySpendingData(transactions);
      default:
        return List.filled(4, 0.0);
    }
  }
}
