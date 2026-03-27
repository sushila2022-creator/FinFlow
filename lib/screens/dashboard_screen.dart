import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finflow/providers/transaction_provider.dart';
import 'package:finflow/providers/currency_provider.dart';
import 'package:finflow/providers/theme_provider.dart';
import 'package:finflow/providers/user_provider.dart';
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
      if (mounted && _isSmsScanningEnabled) {
        setState(() {
          _detectedTransactions.add(detected);
        });
      }
    };

    // Initialize providers after widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Initialize transaction provider
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );
      if (!transactionProvider.isInitialized) {
        await transactionProvider.initializeTransactions();
      }

      // Load SMS scanning state from settings
      await _loadSmsScanState();

      // Initialize SMS permission
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

  Future<void> _loadSmsScanState() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('smart_sms_scan_enabled') ?? false;
    if (!mounted) return;
    setState(() {
      _isSmsScanningEnabled = enabled;
    });

    if (enabled) {
      _smsService.startScanning();
      _pulseController.repeat(reverse: true);
    } else {
      _smsService.stopScanning();
      _pulseController.stop();
      _pulseController.value = 0;
    }
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2B45),
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
          if (currentUser?.isPremium == true)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isSmsScanningEnabled = !_isSmsScanningEnabled;
                  if (_isSmsScanningEnabled) {
                    _smsService.startScanning();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SMS Scanner Activated')),
                    );
                    _pulseController.repeat(reverse: true);
                  } else {
                    _smsService.stopScanning();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SMS Scanner Deactivated')),
                    );
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
                      scale: _isSmsScanningEnabled
                          ? _scaleAnimation.value
                          : 1.0,
                      child: Icon(
                        _isSmsScanningEnabled
                            ? Icons.qr_code_scanner
                            : Icons.qr_code_scanner,
                        color: _isSmsScanningEnabled
                            ? Colors.green
                            : Colors.grey,
                        size: 22,
                      ),
                    );
                  },
                ),
              ),
            ),
          if (currentUser?.isPremium == false || currentUser == null)
            Container(
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
              child: Icon(
                Icons.qr_code_scanner,
                color: Colors.grey[400],
                size: 22,
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
                            const SizedBox(height: 12),
                            _buildIncomeExpenseCards(
                              income,
                              expense,
                              currencySymbol,
                              isDarkMode,
                            ),
                            const SizedBox(height: 14),
                            const SizedBox(height: 16),
                            _buildSearchBar(isDarkMode),
                            const SizedBox(height: 12),
                            _buildDetectedTransactionsCard(
                              currencySymbol,
                              isDarkMode,
                            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Label
          Text(
            'Total Balance',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),

          // Balance Amount with enhanced typography
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: balance),
            duration: const Duration(milliseconds: 1000),
            builder: (context, value, child) {
              return Text(
                AppTheme.formatCurrency(value.abs(), symbol: symbol),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // Monthly Change indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      monthlyChange >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      size: 14,
                      color: monthlyChange >= 0
                          ? AppTheme.accentColor
                          : const Color(0xFFF43F5E),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Monthly Change',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  AppTheme.formatCurrency(monthlyChange.abs(), symbol: symbol),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black12 : const Color(0xFFE2E8F0),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon and Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              // Spacer to push title to the right
              const SizedBox(width: 8),
            ],
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: isDarkMode
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 8),

          // Amount with proper alignment
          Align(
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: amount),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                final formattedAmount = AppTheme.formatCurrency(
                  value,
                  symbol: symbol,
                );
                return Text(
                  formattedAmount,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),
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
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: _detectedTransactions.map((detected) {
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
                                  fontSize: 11,
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
                }).toList(),
              ),
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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDarkMode
                ? const Color(0xFF2D2D2D)
                : const Color(0xFFF1F5F9),
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black12 : const Color(0xFFE2E8F0),
              blurRadius: 4,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color:
                  (isExpense
                          ? const Color(0xFFF43F5E)
                          : const Color(0xFF10B981))
                      .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color:
                      (isExpense
                              ? const Color(0xFFF43F5E)
                              : const Color(0xFF10B981))
                          .withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              AppTheme.getCategoryIcon(transaction.categoryName),
              color: isExpense
                  ? const Color(0xFFF43F5E)
                  : const Color(0xFF10B981),
              size: 20,
            ),
          ),
          title: Text(
            transaction.description.isNotEmpty
                ? transaction.description
                : transaction.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDarkMode
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
              height: 1.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${transaction.categoryName} • ${DateFormat('MMM dd, yyyy').format(transaction.date)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: isDarkMode
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:
                  (isExpense
                          ? const Color(0xFFF43F5E)
                          : const Color(0xFF10B981))
                      .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    (isExpense
                            ? const Color(0xFFF43F5E)
                            : const Color(0xFF10B981))
                        .withValues(alpha: 0.3),
              ),
            ),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: symbol,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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
                      fontWeight: FontWeight.w800,
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
