import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
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
  int _selectedCategoryIndex = -1;
  final List<String> _tabLabels = ['Today', 'Week', 'Month', 'Year'];
  DateTime _selectedStartDate = DateTime.now();
  DateTime _selectedEndDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _updateDateRangeForTab(_selectedTabIndex);
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
        _currentMonth = _selectedStartDate;
        break;
      case 3: // Year
        _selectedStartDate = DateTime(now.year, 1, 1);
        _selectedEndDate = DateTime(now.year, 12, 31);
        break;
    }
  }

  void _updateSelectedDateRange(DateTime startDate, DateTime endDate) {
    setState(() {
      _selectedStartDate = startDate;
      _selectedEndDate = endDate;
      _currentMonth = startDate;
    });
  }

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
        actions: [
          GestureDetector(
            onTap: () => _showDateRangePicker(),
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
              child: Icon(
                Icons.calendar_today,
                size: 22,
                color: AppTheme.primaryColor,
              ),
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

                          // Pie Chart (Category breakdown)
                          _buildPieChart(selectedData, isDarkMode),

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

  // New method to handle date range selection
  Future<void> _showDateRangePicker() async {
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

          // Extended year range: from 100 years ago to 100 years in the future
          final years = List.generate(
            201,
            (index) => currentYear - 100 + index,
          );
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
          int selectedYear = _currentMonth.year;
          int selectedMonth = _currentMonth.month;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: isDarkMode ? AppTheme.primaryColor : Colors.white,
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
                        'Select Date Range',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode
                              ? Colors.white
                              : AppTheme.primaryColor,
                        ),
                      ),
                      Row(
                        children: [
                          // Previous Year Button
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedYear = selectedYear - 1;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? const Color(0xFF2D3A4D)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                size: 16,
                                color: isDarkMode
                                    ? Colors.white
                                    : AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Today Button
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
                                color: AppTheme.incomeColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Today',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.incomeColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Next Year Button
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedYear = selectedYear + 1;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? const Color(0xFF2D3A4D)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: isDarkMode
                                    ? Colors.white
                                    : AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Year Grid with Scroll
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
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
                                  ? AppTheme.incomeColor
                                  : (isDarkMode
                                        ? const Color(0xFF1A2536)
                                        : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.incomeColor
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
                                      : (isDarkMode
                                            ? Colors.white
                                            : AppTheme.primaryColor),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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
                                ? AppTheme.incomeColor
                                : (isDarkMode
                                      ? const Color(0xFF1A2536)
                                      : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.incomeColor
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
                                            : AppTheme.primaryColor),
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
                                            : AppTheme.primaryColor.withValues(
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
                        color: AppTheme.incomeColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${months[selectedMonth - 1]} $selectedYear',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode
                              ? Colors.white
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // Last Month Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              if (selectedMonth == 1) {
                                selectedMonth = 12;
                                selectedYear = selectedYear - 1;
                              } else {
                                selectedMonth = selectedMonth - 1;
                              }
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: isDarkMode
                                  ? const Color(0xFF404040)
                                  : const Color(0xFFE2E8F0),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Last Month',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? const Color(0xFFB0B0B0)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Next Month Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              if (selectedMonth == 12) {
                                selectedMonth = 1;
                                selectedYear = selectedYear + 1;
                              } else {
                                selectedMonth = selectedMonth + 1;
                              }
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: isDarkMode
                                  ? const Color(0xFF404040)
                                  : const Color(0xFFE2E8F0),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Next Month',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? const Color(0xFFB0B0B0)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

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
                            final newStartDate = DateTime(
                              selectedYear,
                              selectedMonth,
                              1,
                            );
                            final newEndDate = DateTime(
                              selectedYear,
                              selectedMonth + 1,
                              0,
                            );

                            // Only update if selection actually changed
                            if (newStartDate != _currentMonth) {
                              // Update state immediately for instant UI feedback
                              setState(() {
                                _selectedStartDate = newStartDate;
                                _selectedEndDate = newEndDate;
                                _currentMonth = newStartDate;
                                _selectedTabIndex = -1; // Custom selection
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.incomeColor,
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

  Widget _buildPieChart(Map<String, double> categoryData, bool isDarkMode) {
    if (categoryData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode
                ? const Color(0xFF2D2D2D)
                : const Color(0xFFF1F5F9),
          ),
        ),
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
            const SizedBox(height: 12),
            Text(
              'No data available',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add transactions to see category breakdown',
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
    final sortedEntries = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Get colors for each category
    final colors = sortedEntries.map((entry) {
      return AppTheme.getCategoryColor(entry.key, isIncome: !_showExpenses);
    }).toList();

    // Calculate total for percentages
    final totalAmount = sortedEntries.fold(
      0.0,
      (sum, entry) => sum + entry.value,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Chart Title
          Text(
            _showExpenses ? 'Expense Breakdown' : 'Income Breakdown',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Pie Chart
          AspectRatio(
            aspectRatio: 1.2,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _selectedCategoryIndex = -1;
                        return;
                      }
                      _selectedCategoryIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: List.generate(sortedEntries.length, (index) {
                  final entry = sortedEntries[index];

                  return PieChartSectionData(
                    color: colors[index],
                    value: entry.value,
                    title: '',
                    radius: 20,
                    titleStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    titlePositionPercentageOffset: 0.55,
                    borderSide: BorderSide(
                      color: _selectedCategoryIndex == index
                          ? Colors.white
                          : colors[index].withValues(alpha: 0),
                      width: _selectedCategoryIndex == index ? 3 : 0,
                    ),
                    showTitle: false,
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: sortedEntries.map((entry) {
              final index = sortedEntries.indexOf(entry);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategoryIndex = index;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _selectedCategoryIndex == index
                              ? Colors.white
                              : colors[index].withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${entry.key} • ${((entry.value / totalAmount) * 100).toStringAsFixed(1)}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: _selectedCategoryIndex == index
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isDarkMode
                            ? (_selectedCategoryIndex == index
                                  ? Colors.white
                                  : const Color(0xFFB0B0B0))
                            : (_selectedCategoryIndex == index
                                  ? AppTheme.primaryColor
                                  : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
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
    final now = _currentMonth;
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
    final now = _currentMonth;
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
