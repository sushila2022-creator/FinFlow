import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:finflow/providers/transaction_provider.dart';
import 'package:finflow/providers/currency_provider.dart';
import 'package:finflow/providers/theme_provider.dart';
import 'package:finflow/utils/app_theme.dart';
import 'package:finflow/models/transaction.dart';
import 'package:finflow/screens/transactions_screen.dart';
import 'package:finflow/screens/add_transaction_screen.dart';
import 'package:finflow/services/sms_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late int _selectedTabIndex;
  late TabController _tabController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  final SmsService _smsService = SmsService();

  final List<String> _tabLabels = ['Day', 'Week', 'Month', 'Year'];

  // Detected SMS transactions
  final List<Map<String, dynamic>> _detectedTransactions = [];

  late bool _smsPermissionDenied;
  late bool _isSmsScanningEnabled;
  late String _searchQuery;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = 3;
    _smsPermissionDenied = false;
    _isSmsScanningEnabled = false;
    _searchQuery = '';

    _tabController = TabController(
      length: _tabLabels.length,
      initialIndex: _selectedTabIndex,
      vsync: this,
    );
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _smsService.onTransactionDetected = (detected) {
      if (mounted) {
        setState(() {
          _detectedTransactions.add(detected);
        });
      }
    };
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final granted = await _smsService.requestSmsPermission();
      if (!mounted) return;
      if (!granted && mounted) {
        setState(() {
          _smsPermissionDenied = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    return transactions.where((transaction) {
      switch (_selectedTabIndex) {
        case 0:
          return transaction.date.day == today.day &&
              transaction.date.month == today.month &&
              transaction.date.year == today.year;
        case 1:
          return transaction.date.isAfter(
                startOfWeek.subtract(const Duration(days: 1)),
              ) &&
              transaction.date.isBefore(today.add(const Duration(days: 1)));
        case 2:
          return transaction.date.month == now.month &&
              transaction.date.year == now.year;
        case 3:
          return transaction.date.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _showNotificationSummary(
    BuildContext context,
    double monthlyTotal,
    double balance,
    String symbol,
    bool isDarkMode,
  ) async {
    final now = DateTime.now();
    final monthlyAvg = now.day > 0 ? monthlyTotal / now.day : 0;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF404040)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.notifications_active,
                        color: AppTheme.accentColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Monthly Summary',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildNotificationItem(
                  'Total Spending This Month',
                  AppTheme.formatCurrency(monthlyTotal.abs(), symbol: symbol),
                  Icons.trending_down,
                  const Color(0xFFF43F5E),
                  isDarkMode,
                ),
                _buildNotificationItem(
                  'Current Balance',
                  AppTheme.formatCurrency(balance, symbol: symbol),
                  Icons.account_balance_wallet,
                  balance < 1000
                      ? const Color(0xFFFF9800)
                      : AppTheme.accentColor,
                  isDarkMode,
                ),
                _buildNotificationItem(
                  'Daily Average',
                  AppTheme.formatCurrency(
                    monthlyAvg.toDouble(),
                    symbol: symbol,
                  ),
                  Icons.calendar_today,
                  AppTheme.primaryColor,
                  isDarkMode,
                ),
                const SizedBox(height: 24),
                if (balance < 1000)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: const Color(0xFFFF9800),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Low balance alert! Consider reviewing your expenses.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode
                                  ? const Color(0xFFFFB74D)
                                  : const Color(0xFFE65100),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Got It',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        ),
      ),
    );

    if (!mounted) return;
  }

  Widget _buildNotificationItem(
    String title,
    String value,
    IconData icon,
    Color iconColor,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDarkMode
                        ? const Color(0xFFB0B0B0)
                        : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
          'FinFlow',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              if (!_isSmsScanningEnabled) {
                _smsService.startScanning();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('SMS Scanner Activated')),
                );
              }
              setState(() {
                _isSmsScanningEnabled = !_isSmsScanningEnabled;
                if (_isSmsScanningEnabled) {
                  _pulseController.repeat(reverse: true);
                } else {
                  _pulseController.stop();
                  _pulseController.value = 0;
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
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
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isSmsScanningEnabled ? _scaleAnimation.value : 1.0,
                    child: Icon(
                      _isSmsScanningEnabled
                          ? Icons.qr_code_scanner
                          : Icons.qr_code_scanner,
                      color: _isSmsScanningEnabled ? Colors.green : Colors.grey,
                      size: 22,
                    ),
                  );
                },
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              final transactionProvider = Provider.of<TransactionProvider>(
                context,
                listen: false,
              );
              final currencyProvider = Provider.of<CurrencyProvider>(
                context,
                listen: false,
              );

              final now = DateTime.now();
              final startOfMonth = DateTime(now.year, now.month, 1);
              final monthlyTransactions = transactionProvider.transactions
                  .where(
                    (t) =>
                        t.date.isAfter(
                          startOfMonth.subtract(const Duration(days: 1)),
                        ) &&
                        t.date.isBefore(now.add(const Duration(days: 1))) &&
                        !t.isIncome,
                  )
                  .toList();

              final monthlyTotal = monthlyTransactions.fold(
                0.0,
                (sum, item) => sum + item.amount,
              );

              await _showNotificationSummary(
                context,
                monthlyTotal,
                transactionProvider.balance,
                currencyProvider.currentCurrencySymbol,
                isDarkMode,
              );
            },
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
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: const Color(0xFF64748B),
                    size: 22,
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (_smsPermissionDenied)
              MaterialBanner(
                content: const Text(
                  'SMS permission is required for smart scanning. Please grant permission to enable this feature.',
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      await openAppSettings();
                    },
                    child: const Text('Open Settings'),
                  ),
                ],
              ),
            Expanded(
              child: Consumer2<TransactionProvider, CurrencyProvider>(
                builder:
                    (context, transactionProvider, currencyProvider, child) {
                      final allTransactions = transactionProvider.transactions;
                      final filteredTransactions = _getFilteredTransactions(
                        allTransactions,
                      );
                      final balance = filteredTransactions.fold(
                        0.0,
                        (sum, t) => sum + (t.isIncome ? t.amount : -t.amount),
                      );
                      final currencySymbol =
                          currencyProvider.currentCurrencySymbol;

                      final now = DateTime.now();
                      final startOfMonth = DateTime(now.year, now.month, 1);
                      final startOfLastMonth = DateTime(
                        now.year,
                        now.month - 1,
                        1,
                      );
                      final endOfLastMonth = startOfMonth.subtract(
                        const Duration(days: 1),
                      );

                      final thisMonthTransactions = allTransactions
                          .where(
                            (t) =>
                                t.date.isAfter(
                                  startOfMonth.subtract(
                                    const Duration(days: 1),
                                  ),
                                ) &&
                                t.date.isBefore(
                                  now.add(const Duration(days: 1)),
                                ),
                          )
                          .toList();

                      final lastMonthTransactions = allTransactions
                          .where(
                            (t) =>
                                t.date.isAfter(
                                  startOfLastMonth.subtract(
                                    const Duration(days: 1),
                                  ),
                                ) &&
                                t.date.isBefore(
                                  endOfLastMonth.add(const Duration(days: 1)),
                                ),
                          )
                          .toList();

                      final thisMonthTotal = thisMonthTransactions.fold(
                        0.0,
                        (sum, item) =>
                            sum + (item.isIncome ? item.amount : -item.amount),
                      );
                      final lastMonthTotal = lastMonthTransactions.fold(
                        0.0,
                        (sum, item) =>
                            sum + (item.isIncome ? item.amount : -item.amount),
                      );
                      final monthlyChange = thisMonthTotal - lastMonthTotal;

                      final income = filteredTransactions
                          .where((t) => t.isIncome)
                          .fold(0.0, (sum, item) => sum + item.amount);
                      final expense = filteredTransactions
                          .where((t) => !t.isIncome)
                          .fold(0.0, (sum, item) => sum + item.amount);

                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            _buildTabBar(isDarkMode),
                            const SizedBox(height: 14),
                            _buildBalanceCard(
                              balance,
                              currencySymbol,
                              monthlyChange,
                              isDarkMode,
                            ),
                            const SizedBox(height: 14),
                            _buildIncomeExpenseCards(
                              income,
                              expense,
                              currencySymbol,
                              isDarkMode,
                            ),
                            const SizedBox(height: 14),
                            _buildDetectedTransactionsCard(
                              currencySymbol,
                              isDarkMode,
                            ),
                            const SizedBox(height: 20),
                            _buildSearchBar(isDarkMode),
                            const SizedBox(height: 12),
                            _buildRecentTransactionsHeader(isDarkMode),
                            _buildTransactionsList(
                              filteredTransactions,
                              currencySymbol,
                              isDarkMode,
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      );
                    },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDarkMode
                ? const Color(0xFF2D2D2D)
                : const Color(0xFFF1F5F9),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(11),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: isDarkMode
              ? const Color(0xFFB0B0B0)
              : const Color(0xFF64748B),
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          tabAlignment: TabAlignment.fill,
          tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    double balance,
    String symbol,
    double monthlyChange,
    bool isDarkMode,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F253E), Color(0xFF1A3A5C)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  'Total Balance',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: balance),
                  duration: const Duration(milliseconds: 1000),
                  builder: (context, value, child) {
                    return Text(
                      AppTheme.formatCurrency(value.abs(), symbol: symbol),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.8,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Change',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  AppTheme.formatCurrency(monthlyChange.abs(), symbol: symbol),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: monthlyChange >= 0
                        ? AppTheme.accentColor
                        : const Color(0xFFF43F5E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseCards(
    double income,
    double expense,
    String symbol,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Income',
              amount: income,
              icon: Icons.arrow_upward,
              iconColor: const Color(0xFF10B981),
              bgColor: const Color(0xFF10B981).withValues(alpha: 0.1),
              symbol: symbol,
              isDarkMode: isDarkMode,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: 'Expense',
              amount: expense,
              icon: Icons.arrow_downward,
              iconColor: const Color(0xFFF43F5E),
              bgColor: const Color(0xFFF43F5E).withValues(alpha: 0.1),
              symbol: symbol,
              isDarkMode: isDarkMode,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String symbol,
    required bool isDarkMode,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: isDarkMode
                  ? const Color(0xFFB0B0B0)
                  : const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: amount),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Text(
                AppTheme.formatCurrency(value, symbol: symbol),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDarkMode
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
              );
            },
          ),
          const SizedBox(height: 3),
        ],
      ),
    );
  }

  Widget _buildDetectedTransactionsCard(String symbol, bool isDarkMode) {
    if (_detectedTransactions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.smartphone,
                    color: AppTheme.accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'SMS Smart Scanning',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _detectedTransactions.length,
              itemBuilder: (context, index) {
                final detected = _detectedTransactions[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF43F5E).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF43F5E).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: const Color(0xFFF43F5E),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detected: ${AppTheme.formatCurrency(detected['amount'], symbol: symbol)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFF43F5E),
                              ),
                            ),
                            Text(
                              '${detected['merchant']} • ${detected['category']} • ${DateFormat('MMM dd').format(detected['date'])}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: isDarkMode
                                    ? const Color(0xFFB0B0B0)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddTransactionScreen(
                                transactionToEdit: {
                                  'amount': detected['amount'],
                                  'note': detected['body'] ?? '',
                                  'date': detected['date'].toIso8601String(),
                                  'type': 'Expense',
                                  'category': detected['category'],
                                },
                              ),
                            ),
                          ).then((result) {
                            if (result == true && mounted) {
                              setState(() {
                                _detectedTransactions.remove(detected);
                              });
                            }
                          });
                        },
                        child: Text(
                          'Add',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            Icon(
              Icons.search,
              color: isDarkMode
                  ? const Color(0xFFB0B0B0)
                  : const Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDarkMode
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDarkMode
                        ? const Color(0xFFB0B0B0)
                        : const Color(0xFF64748B),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _searchQuery = '';
                  });
                },
                child: Icon(
                  Icons.clear,
                  color: isDarkMode
                      ? const Color(0xFFB0B0B0)
                      : const Color(0xFF64748B),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsHeader(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Recent Transactions',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDarkMode
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionsScreen(),
                ),
              );
            },
            child: Text(
              'See All',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(
    List<Transaction> transactions,
    String symbol,
    bool isDarkMode,
  ) {
    // Filter transactions based on search query
    final filteredTransactions = _searchQuery.isEmpty
        ? transactions
        : transactions.where((transaction) {
            final description = transaction.description.toLowerCase();
            final category = transaction.categoryName.toLowerCase();
            final title = transaction.title.toLowerCase();
            return description.contains(_searchQuery) ||
                category.contains(_searchQuery) ||
                title.contains(_searchQuery);
          }).toList();

    if (filteredTransactions.isEmpty) {
      return _buildEmptyState(isDarkMode);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filteredTransactions.length.clamp(0, 10),
        itemBuilder: (context, index) {
          final transaction = filteredTransactions[index];
          final isExpense = !transaction.isIncome;

          return _buildTransactionTile(
            transaction,
            symbol,
            isExpense,
            isDarkMode,
          );
        },
      ),
    );
  }

  Widget _buildTransactionTile(
    Transaction transaction,
    String symbol,
    bool isExpense,
    bool isDarkMode,
  ) {
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
        child: Icon(Icons.edit, color: Colors.white, size: 24),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF43F5E),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Edit
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(
                transactionToEdit: {
                  'id': transaction.id,
                  'amount': transaction.amount.abs(),
                  'note': transaction.description,
                  'date': transaction.date.toIso8601String(),
                  'category': transaction.categoryName,
                  'type': transaction.isIncome ? 'Income' : 'Expense',
                  'is_recurring': transaction.isRecurring ? 1 : 0,
                },
              ),
            ),
          );
          return false; // Don't dismiss, just navigate
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
            if (!mounted) return false;
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode
                ? const Color(0xFF2D2D2D)
                : const Color(0xFFF1F5F9),
          ),
        ),
        child: ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 0,
          ),
          leading: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color:
                  (isExpense
                          ? const Color(0xFFF43F5E)
                          : const Color(0xFF10B981))
                      .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              AppTheme.getCategoryIcon(transaction.categoryName),
              color: isExpense
                  ? const Color(0xFFF43F5E)
                  : const Color(0xFF10B981),
              size: 18,
            ),
          ),
          title: Text(
            transaction.description.isNotEmpty
                ? transaction.description
                : transaction.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDarkMode
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
            ),
          ),
          subtitle: Text(
            '${transaction.categoryName} • ${DateFormat('MMM dd, yyyy').format(transaction.date)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
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
                  text: symbol,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isExpense
                        ? const Color(0xFFF43F5E)
                        : const Color(0xFF10B981),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isExpense
                        ? const Color(0xFFF43F5E)
                        : const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.receipt_long,
              size: 56,
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Transactions Yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDarkMode
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your finances by adding your first transaction',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDarkMode
                  ? const Color(0xFFB0B0B0)
                  : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
