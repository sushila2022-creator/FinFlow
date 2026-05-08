import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:finflow/providers/transaction_provider.dart';
import 'package:finflow/providers/currency_provider.dart';
import 'package:finflow/providers/theme_provider.dart';
import 'package:finflow/providers/user_provider.dart';
import 'package:finflow/providers/settings_provider.dart';
import 'package:finflow/utils/app_theme.dart';
import 'package:finflow/utils/debug_logger.dart';
import 'package:finflow/models/transaction.dart';
import 'package:finflow/providers/navigation_provider.dart';
import 'package:finflow/screens/add_transaction_screen.dart';
import 'package:finflow/services/sms_service.dart';
import 'package:finflow/utils/utility.dart';
// import removed

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late int _selectedTabIndex;
  late TabController _tabController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  final SmsService _smsService = SmsService();

  final List<String> _tabLabels = ['Day', 'Week', 'Month', 'Year'];

  late bool _smsPermissionDenied;
  bool _isScanning = false;
  late String _searchQuery;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = 3;
    _smsPermissionDenied = false;
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
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      if (mounted && (settings.isSmsScanEnabled || _isScanning)) {
        Provider.of<TransactionProvider>(
          context,
          listen: false,
        ).addDetectedSms(detected);
      }
    };

    _smsService.onSmsLimitReached = () {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('SMS Scan Limit Reached'),
            content: const Text(
              'You have reached the limit of 15 free bank transaction scans. '
              'Upgrade to Premium for unlimited SMS scanning and additional features.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Later'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/premium');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Upgrade Now'),
              ),
            ],
          ),
        );
      }
    };

    // Initialize providers after widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // SMS scanning state is now handled by SettingsProvider

      if (!mounted) return;

      // Initialize transaction provider
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );
      if (!transactionProvider.isInitialized) {
        try {
          await transactionProvider.initializeTransactions();
        } catch (e) {
          if (mounted) {
            showErrorSnackBar(context, 'Failed to load transactions: $e');
          }
        }
      }

      // Initialize SMS permission
      _checkSmsPermission();
    });

    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _checkSmsPermission() async {
    try {
      final status = await Permission.sms.status;
      if (mounted) {
        setState(() {
          _smsPermissionDenied = !status.isGranted;
        });

        // If granted, ensure scanning starts if enabled
        if (status.isGranted) {
          final settings = Provider.of<SettingsProvider>(
            context,
            listen: false,
          );
          if (settings.isSmsScanEnabled) {
            await _smsService.startScanning();
          }
        }
      }
    } catch (e) {
      logError('Error checking SMS permission', error: e);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSmsPermission();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // Method _loadSmsScanningState removed as it's now handled by SettingsProvider

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
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    // Use select to avoid rebuilds when unrelated state changes
    final currentUser = context.select((UserProvider p) => p.currentUser);
    final currencySymbol = context.select(
      (CurrencyProvider p) => p.currentCurrencySymbol,
    );
    final isInitialized = context.select(
      (TransactionProvider p) => p.isInitialized,
    );
    final isLoading = context.select((TransactionProvider p) => p.isLoading);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2B45),
        title: Text(
          'FinFlow - AI',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          if (currentUser?.isPremium == true)
            Consumer<SettingsProvider>(
              builder: (context, settings, _) => GestureDetector(
                onTap: () async {
                  if (!settings.isSmsScanEnabled) {
                    setState(() => _isScanning = true);
                    await settings.setSmsScanEnabled(true);
                    if (!mounted) return;
                    setState(() => _isScanning = false);

                    if (settings.isSmsScanEnabled) {
                      _pulseController.repeat(reverse: true);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('SMS Scanner Activated'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'SMS Permission Denied. Please enable it in Settings.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    await settings.setSmsScanEnabled(false);
                    if (!mounted) return;
                    _pulseController.stop();
                    _pulseController.value = 0;
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SMS Scanner Deactivated')),
                    );
                  }
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
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: settings.isSmsScanEnabled
                              ? _scaleAnimation.value
                              : 1.0,
                          child: Icon(
                            Icons.qr_code_scanner,
                            color: settings.isSmsScanEnabled
                                ? Colors.green
                                : Colors.grey,
                            size: 22,
                          ),
                        );
                      },
                    ),
                  ),
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
                backgroundColor: AppTheme.expenseColor.withValues(alpha: 0.1),
                content: Text(
                  'SMS permission is required for smart scanning. Financial messages will not be detected.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.expenseColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                leading: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.expenseColor,
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      final status = await Permission.sms.status;
                      if (status.isPermanentlyDenied) {
                        await openAppSettings();
                      } else {
                        final granted = await _smsService
                            .requestSmsPermission();
                        if (granted) {
                          _checkSmsPermission();
                        }
                      }
                    },
                    child: Text(
                      'Grant Permission',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.expenseColor,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _smsPermissionDenied = false;
                      });
                    },
                    child: Text(
                      'Dismiss',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            Expanded(
              child: !isInitialized && isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading your financial flow...'),
                        ],
                      ),
                    )
                  : CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              _buildTabBar(isDarkMode),
                              const SizedBox(height: 14),

                              // Balance Section - with Selector
                              Selector<
                                TransactionProvider,
                                Map<String, double>
                              >(
                                selector: (_, p) => {
                                  'balance': p.totalBalance,
                                  'change': p.monthlyChange,
                                },
                                builder: (context, data, _) {
                                  return _buildBalanceCard(
                                    data['balance']!,
                                    currencySymbol,
                                    data['change']!,
                                    isDarkMode,
                                  );
                                },
                              ),

                              const SizedBox(height: 12),

                              // Income/Expense Section - with Selector
                              Selector<
                                TransactionProvider,
                                Map<String, double>
                              >(
                                selector: (_, p) => {
                                  'income': p.totalIncome,
                                  'expense': p.totalExpense,
                                },
                                builder: (context, data, _) {
                                  return _buildIncomeExpenseCards(
                                    data['income']!,
                                    data['expense']!,
                                    currencySymbol,
                                    isDarkMode,
                                  );
                                },
                              ),

                              const SizedBox(height: 14),
                              const SizedBox(height: 16),
                              _buildSearchBar(isDarkMode),
                              _buildScannerStatus(isDarkMode),
                              const SizedBox(height: 12),
                              Selector2<
                                SettingsProvider,
                                TransactionProvider,
                                Map<String, dynamic>
                              >(
                                selector: (_, settings, trans) => {
                                  'isEnabled': settings.isSmsScanEnabled,
                                  'detected': trans.detectedSmsTransactions,
                                },
                                builder: (context, data, _) {
                                  return _buildDetectedTransactionsCard(
                                    data['isEnabled'],
                                    data['detected'],
                                    currencySymbol,
                                    isDarkMode,
                                  );
                                },
                              ),
                              _buildRecentTransactionsHeader(isDarkMode),
                            ],
                          ),
                        ),

                        // Transactions List - with Selector and lazy loading
                        Selector<TransactionProvider, List<Transaction>>(
                          selector: (_, p) => p.transactions,
                          builder: (context, allTransactions, _) {
                            final filteredTransactions =
                                _getFilteredTransactions(allTransactions);
                            return SliverPadding(
                              padding: const EdgeInsets.only(
                                top: 8,
                                bottom: 20,
                              ),
                              sliver: _buildSliverTransactionsList(
                                filteredTransactions,
                                currencySymbol,
                                isDarkMode,
                              ),
                            );
                          },
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
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

  Widget _buildDetectedTransactionsCard(
    bool isEnabled,
    List<Map<String, dynamic>> detectedTransactions,
    String symbol,
    bool isDarkMode,
  ) {
    if (!isEnabled) {
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
                Expanded(
                  child: Text(
                    'SMS Smart Scanning',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _isScanning
                        ? AppTheme.accentColor.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isScanning
                          ? AppTheme.accentColor.withValues(alpha: 0.2)
                          : Colors.green.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isScanning)
                        const SizedBox(
                          width: 8,
                          height: 8,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.accentColor,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      const SizedBox(width: 4),
                      Text(
                        _isScanning ? 'SCANNING...' : 'SCANNER ACTIVE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: _isScanning
                              ? AppTheme.accentColor
                              : Colors.green,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (detectedTransactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isScanning ? Icons.search : Icons.radar,
                          color: AppTheme.accentColor.withValues(alpha: 0.4),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isScanning
                            ? 'Scanning recent SMS inbox...'
                            : 'No bank transactions detected',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? const Color(0xFFB0B0B0)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isScanning
                            ? 'This may take a few seconds'
                            : 'Showing messages from last 100 SMS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: isDarkMode
                              ? const Color(0xFF808080)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      if (!_isScanning) ...[
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () async {
                            setState(() {
                              _isScanning = true;
                              context
                                  .read<TransactionProvider>()
                                  .clearDetectedSms();
                            });
                            await _smsService.checkRecentSms();
                            if (mounted) {
                              setState(() {
                                _isScanning = false;
                              });
                            }
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Scan Again'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.accentColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: detectedTransactions.length,
                itemBuilder: (context, index) {
                  final detected = detectedTransactions[index];

                  // Extract bank name and transaction details from detected data
                  final bankName =
                      detected['bankName'] ??
                      detected['merchant'] ??
                      'Unknown Bank';

                  // Fix transaction type detection from SMS service
                  final isDebit = detected['isDebit'] ?? false;
                  final isCredit = detected['isCredit'] ?? !isDebit;

                  // Determine transaction type and color
                  final transactionType = isCredit ? 'Received' : 'Sent';
                  final transactionAmount = detected['amount'] ?? 0.0;
                  final isIncome = isCredit;

                  // Format the transaction note to show bank name instead of full description
                  final shortNote =
                      detected['note'] ?? '$bankName - $transactionType';

                  // Get the proper transaction type for the AddTransactionScreen
                  final transactionTypeForAdd = isIncome ? 'Income' : 'Expense';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCredit
                          ? const Color(0xFF10B981).withValues(alpha: 0.05)
                          : const Color(0xFFF43F5E).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCredit
                            ? const Color(0xFF10B981).withValues(alpha: 0.2)
                            : const Color(0xFFF43F5E).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCredit ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isCredit
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF43F5E),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // First row: Bank name and amount
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      bankName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDarkMode
                                            ? AppTheme.textPrimaryDark
                                            : AppTheme.textPrimaryLight,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$transactionType: ${AppTheme.formatCurrency(transactionAmount.abs(), symbol: symbol)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isCredit
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF43F5E),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Second row: Category and date
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isCredit
                                          ? const Color(
                                              0xFF10B981,
                                            ).withValues(alpha: 0.15)
                                          : const Color(
                                              0xFFF43F5E,
                                            ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      detected['category'] ??
                                          (isCredit ? 'Income' : 'Expense'),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isCredit
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFF43F5E),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat(
                                      'MMM dd',
                                    ).format(detected['date']),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      color: isDarkMode
                                          ? const Color(0xFFB0B0B0)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Third row: Short description
                              Text(
                                shortNote,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: isDarkMode
                                      ? const Color(0xFFB0B0B0)
                                      : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () {
                                final transactionProvider = context
                                    .read<TransactionProvider>();
                                if (!transactionProvider.isAuthenticated) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please log in to add transactions',
                                      ),
                                      backgroundColor: AppTheme.expenseColor,
                                    ),
                                  );
                                  return;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddTransactionScreen(
                                      transactionToEdit: {
                                        'amount': transactionAmount.abs(),
                                        'note': shortNote,
                                        'date': detected['date']
                                            .toIso8601String(),
                                        'type': transactionTypeForAdd,
                                        'category': detected['category'],
                                        'merchant': bankName,
                                        // Include userId from detected transaction for validation
                                        'userId': detected['userId'],
                                      },
                                    ),
                                  ),
                                ).then((result) {
                                  if (result == true && mounted) {
                                    transactionProvider.removeDetectedSms(
                                      detected,
                                    );
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
                            TextButton(
                              onPressed: () {
                                // Allow user to edit the detected transaction before adding
                                _showEditDetectedTransactionDialog(
                                  context,
                                  detected,
                                  symbol,
                                  isDarkMode,
                                );
                              },
                              child: Text(
                                'Edit',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? const Color(0xFFB0B0B0)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
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
              Provider.of<NavigationProvider>(context, listen: false).setTab(1);
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

  Widget _buildSliverTransactionsList(
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
      return SliverToBoxAdapter(child: _buildEmptyState(isDarkMode));
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final transaction = filteredTransactions[index];
        final isExpense = !transaction.isIncome;

        return _buildTransactionTile(
          transaction,
          symbol,
          isExpense,
          isDarkMode,
        );
      }, childCount: filteredTransactions.length.clamp(0, 10)),
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
            try {
              await transactionProvider.deleteTransaction(transaction.id);
              if (!mounted) return false;
              if (mounted) {
                showSnackBar(context, 'Transaction deleted successfully');
              }
            } catch (e) {
              if (mounted) {
                showErrorSnackBar(context, 'Failed to delete transaction: $e');
              }
              return false;
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
          trailing: Consumer<CurrencyProvider>(
            builder: (context, currencyProvider, child) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
                child: Text(
                  currencyProvider.formatConvertedAmount(
                    transaction.amount.abs(),
                    transaction.currencyCode,
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isExpense
                        ? const Color(0xFFF43F5E)
                        : const Color(0xFF10B981),
                  ),
                ),
              );
            },
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

  Widget _buildScannerStatus(bool isDarkMode) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              settings.isSmsScanEnabled ? Icons.sensors : Icons.sensors_off,
              size: 14,
              color: settings.isSmsScanEnabled
                  ? Colors.green
                  : (isDarkMode ? Colors.grey[600] : Colors.grey[400]),
            ),
            const SizedBox(width: 6),
            Text(
              settings.isSmsScanEnabled
                  ? 'SMS Smart Scanner IS ON'
                  : 'SMS Smart Scanner IS OFF',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: settings.isSmsScanEnabled
                    ? Colors.green
                    : (isDarkMode ? Colors.grey[600] : Colors.grey[400]),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to show edit dialog for detected transactions
  Future<void> _showEditDetectedTransactionDialog(
    BuildContext context,
    Map<String, dynamic> detected,
    String symbol,
    bool isDarkMode,
  ) async {
    final bankName =
        detected['bankName'] ?? detected['merchant'] ?? 'Unknown Bank';
    final isCredit = detected['isCredit'] ?? true;
    final transactionAmount = detected['amount'] ?? 0.0;
    final currentNote = detected['note'] ?? '';
    final currentCategory =
        detected['category'] ?? (isCredit ? 'Income' : 'Expense');

    String editedBankName = bankName;
    double editedAmount = transactionAmount.abs();
    String editedNote = currentNote;
    String selectedCategory = currentCategory;
    bool isEditedCredit = isCredit;

    // Get available categories from provider
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );

    // Get categories from the transaction provider's category map
    final availableCategories = transactionProvider.transactions
        .map((t) => t.category)
        .toSet()
        .toList();

    // Add default categories if not present
    final allCategories = <String>{
      ...availableCategories,
      if (isCredit) 'Income',
      'Salary',
      'Freelance',
      'Investments',
      if (!isCredit) 'Expense',
      'Food',
      'Travel',
      'Bills',
      'Shopping',
    }.toList();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Transaction',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDarkMode
                ? AppTheme.textPrimaryDark
                : AppTheme.textPrimaryLight,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bank Name
              TextField(
                controller: TextEditingController(text: bankName),
                onChanged: (value) => editedBankName = value,
                decoration: InputDecoration(
                  labelText: 'Bank Name',
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDarkMode
                        ? const Color(0xFFB0B0B0)
                        : const Color(0xFF64748B),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Transaction Type
              Row(
                children: [
                  Text(
                    'Transaction Type:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? const Color(0xFFB0B0B0)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() => isEditedCredit = true);
                          Navigator.of(context).pop();
                          _showEditDetectedTransactionDialog(
                            context,
                            detected,
                            symbol,
                            isDarkMode,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isEditedCredit
                                ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isEditedCredit
                                  ? const Color(0xFF10B981)
                                  : (isDarkMode
                                        ? const Color(0xFF2D2D2D)
                                        : const Color(0xFFF1F5F9)),
                            ),
                          ),
                          child: Text(
                            'Credit',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isEditedCredit
                                  ? const Color(0xFF10B981)
                                  : (isDarkMode
                                        ? const Color(0xFFB0B0B0)
                                        : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          setState(() => isEditedCredit = false);
                          Navigator.of(context).pop();
                          _showEditDetectedTransactionDialog(
                            context,
                            detected,
                            symbol,
                            isDarkMode,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: !isEditedCredit
                                ? const Color(0xFFF43F5E).withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: !isEditedCredit
                                  ? const Color(0xFFF43F5E)
                                  : (isDarkMode
                                        ? const Color(0xFF2D2D2D)
                                        : const Color(0xFFF1F5F9)),
                            ),
                          ),
                          child: Text(
                            'Debit',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: !isEditedCredit
                                  ? const Color(0xFFF43F5E)
                                  : (isDarkMode
                                        ? const Color(0xFFB0B0B0)
                                        : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Amount
              TextField(
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                controller: TextEditingController(
                  text: transactionAmount.abs().toString(),
                ),
                onChanged: (value) {
                  try {
                    editedAmount = double.parse(value);
                  } catch (e) {
                    editedAmount = transactionAmount.abs();
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDarkMode
                        ? const Color(0xFFB0B0B0)
                        : const Color(0xFF64748B),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Category
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                items: allCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDarkMode
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedCategory = value;
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDarkMode
                        ? const Color(0xFFB0B0B0)
                        : const Color(0xFF64748B),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Note
              TextField(
                controller: TextEditingController(text: currentNote),
                onChanged: (value) => editedNote = value,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDarkMode
                        ? const Color(0xFFB0B0B0)
                        : const Color(0xFF64748B),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? const Color(0xFFB0B0B0)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // Update the detected transaction with edited values
              detected.updateAll((key, value) {
                switch (key) {
                  case 'merchant':
                  case 'bankName':
                    return editedBankName;
                  case 'amount':
                    return isEditedCredit ? editedAmount : -editedAmount;
                  case 'note':
                    return editedNote;
                  case 'category':
                    return selectedCategory;
                  case 'isCredit':
                    return isEditedCredit;
                  default:
                    return value;
                }
              });

              Navigator.of(context).pop();
            },
            child: Text(
              'Save',
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
  }
}
