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
  int _selectedTabIndex = 0; // Today is selected by default
  bool _showExpenses = true; // Toggle between Expenses and Income
  final List<String> _tabLabels = ['Today', 'Week', 'Month', 'Year'];

  // SINGLE SOURCE OF TRUTH: Current selected period
  DateTime _selectedPeriod = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedPeriod = DateTime.now();
  }

  // Color palette matching Dashboard's Deep Navy (#0D2B45) and Emerald (#006D5B)
  static const Color primaryNavy = AppTheme.primaryColor;
  static const Color accentEmerald = AppTheme.incomeColor;

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

                          // Bar Chart (Dynamic based on selected tab)
                          _buildBarChart(chartData, isDarkMode),

                          const SizedBox(height: 24),

                          // Spending by Category Header
                          _buildCategoryHeader(isDarkMode),

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
                                style: GoogleFonts.plusJakartaSans(
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
                                style: GoogleFonts.plusJakartaSans(
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
                        style: GoogleFonts.plusJakartaSans(
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
                            style: GoogleFonts.plusJakartaSans(
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
                            // Only update if selection actually changed
                            if (newDate != _selectedPeriod) {
                              // Update state immediately for instant UI feedback
                              setState(() {
                                _selectedPeriod = newDate;
                              });
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
                            style: GoogleFonts.plusJakartaSans(
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
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedTabIndex == index
                        ? primaryNavy
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
                            ? accentEmerald
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
                fontSize: 28, // Standardized to match Dashboard Balance
                fontWeight: FontWeight.w900,
                color: isDarkMode ? Colors.white : primaryNavy,
                letterSpacing: -0.8,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                      height: 120,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
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
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ),

                          // Bar
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOut,
                            height: 120 * heightPercent,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: accentEmerald.withValues(
                                alpha: isHighlighted
                                    ? 1.0
                                    : 0.3 + (heightPercent * 0.4),
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ),

                          // Highlight label on middle bar
                          if (isHighlighted && chartData[index] > 0)
                            Positioned(
                              top: 8,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryNavy,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    AppTheme.formatCurrency(
                                      chartData[index],
                                      symbol: '₹',
                                    ).replaceAll('.00', 'k'),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
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

                    const SizedBox(height: 8),

                    // Label
                    Text(
                      labels[index],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDarkMode ? Colors.white : primaryNavy,
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Text(
            'View All',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
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
                color: isDarkMode ? Colors.white : primaryNavy,
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

    return Column(
      children: sortedEntries.map((entry) {
        final percentage = totalAmount > 0
            ? (entry.value / totalAmount) * 100
            : 0;
        final categoryColor = AppTheme.getCategoryColor(entry.key);

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
          ),
          child: Row(
            children: [
              // Category Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  AppTheme.getCategoryIcon(entry.key),
                  size: 20,
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: 12),

              // Category Name and Percentage
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
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

              // Amount
              Text(
                AppTheme.formatCurrency(entry.value, symbol: currencySymbol),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, // Standardized to match Dashboard/Transactions
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : primaryNavy,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
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
