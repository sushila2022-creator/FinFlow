import 'package:finflow/providers/transaction_provider.dart';
import 'package:finflow/providers/currency_provider.dart';
import 'package:finflow/providers/theme_provider.dart';
import 'package:finflow/providers/user_provider.dart';
import 'package:finflow/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finflow/services/auth/local_auth_service.dart';
import 'package:finflow/services/auth/google_auth_service.dart';
import 'package:finflow/screens/manage_categories_screen.dart';
import 'package:finflow/screens/welcome_screen.dart';
import 'package:finflow/utils/database_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finflow/services/notification_service.dart';
import 'package:finflow/services/sms_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:finflow/screens/premium_screen.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column;
import 'package:open_file/open_file.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool _isAppLockEnabled = false;
  bool _dailyReminderEnabled = false;
  bool _isSmsScanEnabled = false;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final LocalAuthService _localAuthService = LocalAuthService();
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _pinController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  bool _isBackupInProgress = false;
  bool _isRestoreInProgress = false;
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  @override
  void initState() {
    super.initState();
    _loadAppLockState();
    _loadNotificationSettings();
    _loadSmsScanSettings();
  }

  Future<void> _loadAppLockState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isAppLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
    });
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('daily_reminder_enabled') ?? false;
    if (!mounted) return;
    setState(() {
      _dailyReminderEnabled = enabled;
    });

    if (enabled) {
      await _notificationService.scheduleDailyReminder(9, 0);
    } else {
      await _notificationService.cancelDailyReminder();
    }
  }

  Future<void> _loadSmsScanSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('smart_sms_scan_enabled') ?? false;
    if (!mounted) return;
    setState(() {
      _isSmsScanEnabled = enabled;
    });

    if (enabled) {
      SmsService().startScanning();
    } else {
      SmsService().stopScanning();
    }
  }

  void _shareApp() {
    SharePlus.instance.share(
      ShareParams(
        text:
            'Check out FinFlow - Your personal finance management app! Download now and take control of your finances. https://play.google.com/store/apps/details?id=com.finflow.app',
        subject: 'FinFlow - Personal Finance Management',
      ),
    );
  }

  void _showCurrencyDialog(
    BuildContext context,
    CurrencyProvider currencyProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final currencies = CurrencyProvider.getAvailableCurrencies();
        return AlertDialog(
          title: const Text('Select Currency'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: currencies.length,
              itemBuilder: (context, index) {
                final currency = currencies[index];
                final isSelected =
                    currency['symbol'] ==
                    currencyProvider.currentCurrencySymbol;

                return ListTile(
                  dense: true,
                  title: Text('${currency['name']} (${currency['symbol']})'),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFF0A2540))
                      : null,
                  onTap: () {
                    currencyProvider.setCurrency(currency['symbol']!);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showSmsScanInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Smart SMS Scan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Smart SMS Scan automatically detects bank transaction SMS messages and suggests them for quick entry.',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Automatically scans incoming SMS messages'),
              const Text('• Detects bank transaction details'),
              const Text('• Suggests transactions for quick addition'),
              const Text('• Supports multiple bank formats'),
              const SizedBox(height: 16),
              Text(
                'Note: This feature requires SMS permissions and will run in the background.',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _backupDatabase() async {
    if (!mounted) return;

    setState(() {
      _isBackupInProgress = true;
    });

    try {
      final dbPath = await getDatabasesPath();
      if (!mounted) return;
      final dbFilePath = path.join(dbPath, 'FinFlow.db');

      final dbFile = File(dbFilePath);
      if (!await dbFile.exists()) {
        throw Exception('Database file not found');
      }
      if (!mounted) return;

      final backupFileName = 'finflow_backup.db';
      final tempDir = await getTemporaryDirectory();
      if (!mounted) return;
      final backupPath = path.join(tempDir.path, backupFileName);

      await dbFile.copy(backupPath);
      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          text: 'This is your FinFlow database backup.',
          subject: 'FinFlow Database Backup',
          files: [XFile(backupPath, mimeType: 'application/octet-stream')],
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBackupInProgress = false;
        });
      }
    }
  }

  Future<void> _restoreDatabase() async {
    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Database'),
        content: const Text(
          'This will replace your current database with the backup file. '
          'This action cannot be undone. Make sure you have a backup of your current data.\n\n'
          'Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldRestore != true) return;

    if (!mounted) return;

    setState(() {
      _isRestoreInProgress = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
        allowMultiple: false,
      );
      if (!mounted) return;

      if (result == null || result.files.single.path == null) {
        throw Exception('No file selected');
      }

      final selectedFile = File(result.files.single.path!);

      if (!selectedFile.path.toLowerCase().endsWith('.db')) {
        throw Exception('Please select a valid database file (.db)');
      }

      final dbPath = await getDatabasesPath();
      if (!mounted) return;
      final dbFilePath = path.join(dbPath, 'FinFlow.db');
      final currentDbFile = File(dbFilePath);

      Database? currentDb = await _databaseHelper.database;
      if (!mounted) return;
      await currentDb.close();
      if (!mounted) return;

      if (await currentDbFile.exists()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final emergencyBackupPath = path.join(
          dbPath,
          'FinFlow_emergency_backup_$timestamp.db',
        );
        await currentDbFile.copy(emergencyBackupPath);
      }
      if (!mounted) return;

      await selectedFile.copy(dbFilePath);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data Restored Successfully. Please restart the app'),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/splash', (route) => false);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restore failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRestoreInProgress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(
          0xFF0D2B45,
        ), // Deep Navy - consistent across app
        title: Text(
          'Settings',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildSectionHeader('General', isDarkMode),
            Consumer<CurrencyProvider>(
              builder: (context, currencyProvider, child) {
                final currentCurrency =
                    CurrencyProvider.getAvailableCurrencies().firstWhere(
                      (currency) =>
                          currency['symbol'] ==
                          currencyProvider.currentCurrencySymbol,
                      orElse: () => {'name': 'US Dollar', 'symbol': '\$'},
                    );

                return _buildSection([
                  {
                    'icon': Icons.currency_exchange,
                    'title': 'Currency',
                    'subtitle':
                        '${currentCurrency['name']} (${currentCurrency['symbol']})',
                    'onTap': () =>
                        _showCurrencyDialog(context, currencyProvider),
                  },
                  {
                    'icon': context.watch<ThemeProvider>().isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    'title': 'Dark Mode',
                    'trailing': Switch(
                      value: context.watch<ThemeProvider>().isDarkMode,
                      activeThumbColor: const Color(0xFF00C853),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (value) =>
                          context.read<ThemeProvider>().toggleTheme(),
                    ),
                  },
                  {
                    'icon': Icons.sms,
                    'title': 'Smart SMS Scan',
                    'subtitle':
                        Provider.of<UserProvider>(
                              context,
                            ).currentUser?.isPremium ==
                            true
                        ? 'Auto-detect bank transaction SMS'
                        : 'Premium feature',
                    'onTap': () {
                      final isPremium =
                          Provider.of<UserProvider>(
                            context,
                            listen: false,
                          ).currentUser?.isPremium ==
                          true;
                      if (!isPremium) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PremiumScreen(),
                          ),
                        );
                      } else {
                        _showSmsScanInfoDialog();
                      }
                    },
                    'trailing':
                        Provider.of<UserProvider>(
                              context,
                            ).currentUser?.isPremium ==
                            true
                        ? Switch(
                            value: _isSmsScanEnabled,
                            activeThumbColor: const Color(0xFF00C853),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: (value) async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool(
                                'smart_sms_scan_enabled',
                                value,
                              );
                              setState(() {
                                _isSmsScanEnabled = value;
                              });

                              if (value) {
                                SmsService().startScanning();
                              } else {
                                SmsService().stopScanning();
                              }
                            },
                          )
                        : Icon(
                            Icons.lock,
                            color: const Color(0xFFFFD700),
                            size: 24,
                          ),
                  },
                  {
                    'title':
                        'We only read transaction-related messages. No OTPs or personal chats.',
                    'isDescription': true,
                  },
                  {
                    'icon': Icons.category,
                    'title': 'Manage Categories',
                    'onTap': () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageCategoriesScreen(),
                        ),
                      );
                    },
                  },
                ], isDarkMode);
              },
            ),
            const SizedBox(height: 16),
            _buildSectionHeader('Data Management', isDarkMode),
            _buildSection([
              {
                'icon': Icons.table_view,
                'title': 'Export to Excel',
                'onTap': () {
                  final transactionProvider = Provider.of<TransactionProvider>(
                    context,
                    listen: false,
                  );
                  transactionProvider.exportTransactionsCsv(context);
                },
                'iconColor': const Color(0xFF00C853),
              },
              {
                'icon': Icons.calendar_month,
                'title': 'Export Monthly Excel',
                'onTap': _exportMonthlyExcel,
                'iconColor': const Color(0xFF00C853),
              },
              {
                'icon': Icons.delete_forever,
                'title': 'Reset App Data',
                'onTap': _deleteAllData,
                'iconColor': Colors.red,
              },
            ], isDarkMode),
            const SizedBox(height: 16),
            _buildSectionHeader('Backup & Restore', isDarkMode),
            _buildSection([
              {
                'icon': Icons.cloud_upload,
                'title': 'Backup Database',
                'onTap': _isBackupInProgress ? null : _backupDatabase,
                'trailing': _isBackupInProgress
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              },
              {
                'icon': Icons.restore,
                'title': 'Restore Database',
                'onTap': _isRestoreInProgress ? null : _restoreDatabase,
                'trailing': _isRestoreInProgress
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              },
            ], isDarkMode),
            const SizedBox(height: 16),
            _buildSectionHeader('Security', isDarkMode),
            _buildSection([
              {
                'icon': Icons.lock,
                'title': 'Enable App Lock',
                'onTap': () async {
                  if (_isAppLockEnabled) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('app_lock_enabled', false);
                    await _secureStorage.write(key: 'pin', value: '');
                    setState(() {
                      _isAppLockEnabled = false;
                    });
                  } else {
                    _showBiometricSetupDialog();
                  }
                },
                'trailing': Switch(
                  value: _isAppLockEnabled,
                  activeThumbColor: const Color(0xFF00C853),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (value) async {
                    if (value) {
                      _showBiometricSetupDialog();
                    } else {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('app_lock_enabled', false);
                      await _secureStorage.write(key: 'pin', value: '');
                      setState(() {
                        _isAppLockEnabled = false;
                      });
                    }
                  },
                ),
              },
            ], isDarkMode),
            const SizedBox(height: 16),
            _buildSectionHeader('Notifications', isDarkMode),
            _buildSection([
              {
                'icon': Icons.notifications,
                'title': 'Daily Reminder',
                'onTap': () async {
                  final prefs = await SharedPreferences.getInstance();
                  final newValue = !_dailyReminderEnabled;
                  await prefs.setBool('daily_reminder_enabled', newValue);
                  setState(() {
                    _dailyReminderEnabled = newValue;
                  });

                  if (newValue) {
                    await _notificationService.scheduleDailyReminder(9, 0);
                  } else {
                    await _notificationService.cancelDailyReminder();
                  }
                },
                'trailing': Switch(
                  value: _dailyReminderEnabled,
                  activeThumbColor: const Color(0xFF00C853),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (value) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('daily_reminder_enabled', value);
                    setState(() {
                      _dailyReminderEnabled = value;
                    });

                    if (value) {
                      await _notificationService.scheduleDailyReminder(9, 0);
                    } else {
                      await _notificationService.cancelDailyReminder();
                    }
                  },
                ),
              },
            ], isDarkMode),
            const SizedBox(height: 16),
            _buildSectionHeader('Google Account', isDarkMode),
            _buildGoogleSection(isDarkMode),
            const SizedBox(height: 16),
            _buildSectionHeader('Support & About', isDarkMode),
            _buildSection([
              {
                'icon': Icons.privacy_tip,
                'title': 'Privacy Policy',
                'onTap': () async {
                  try {
                    await launchUrl(
                      Uri.parse('https://finflow-privacy-policy.com'),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not launch privacy policy'),
                          ),
                        );
                      }
                    });
                  }
                },
              },
              {
                'icon': Icons.star,
                'title': 'Rate Us',
                'onTap': () async {
                  try {
                    // Try to open Google Play Store first
                    final playStoreUrl = 'market://details?id=com.finflow.app';
                    if (await canLaunchUrl(Uri.parse(playStoreUrl))) {
                      await launchUrl(Uri.parse(playStoreUrl));
                    } else {
                      // Fallback to web URL if Play Store is not available
                      final webUrl =
                          'https://play.google.com/store/apps/details?id=com.finflow.app';
                      await launchUrl(Uri.parse(webUrl));
                    }
                  } catch (e) {
                    if (!mounted) return;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Could not open rating page: ${e.toString()}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    });
                  }
                },
              },
              {'icon': Icons.share, 'title': 'Share App', 'onTap': _shareApp},
              {
                'icon': Icons.logout,
                'title': 'Logout',
                'onTap': () async {
                  final navigator = Navigator.of(context);
                  await FirebaseAuth.instance.signOut();
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const WelcomeScreen(),
                    ),
                    (route) => false,
                  );
                },
                'iconColor': Colors.red,
              },
            ], isDarkMode),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'App Version 1.0.0',
                style: GoogleFonts.plusJakartaSans(
                  color: isDarkMode
                      ? const Color(0xFFB0B0B0)
                      : const Color(0xFF666666),
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13, // Increased from 12
          fontWeight: FontWeight.w700, // Adjusted weight
          color: isDarkMode
              ? AppTheme.textSecondaryDark
              : AppTheme.textSecondaryLight, // Use AppTheme
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSection(List<Map<String, dynamic>> items, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: items.map((item) {
            // Handle description items
            if (item['isDescription'] == true) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Text(
                  item['title'],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDarkMode
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.left,
                ),
              );
            }

            // Handle regular list items
            return ListTile(
              onTap: item['onTap'],
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              splashColor: Colors.transparent,
              leading: Icon(
                item['icon'],
                color: item['iconColor'] ?? AppTheme.primaryColor,
                size: 18,
              ),
              title: Text(
                item['title'],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, // Increased from 12 to match Dashboard standard
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
              ),
              subtitle: item['subtitle'] != null
                  ? Text(
                      item['subtitle'],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: isDarkMode
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    )
                  : null,
              trailing:
                  item['trailing'] ??
                  Icon(
                    Icons.chevron_right,
                    color: isDarkMode
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                  ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _deleteAllData() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset App Data'),
        content: const Text(
          'This will reset the app to factory settings, deleting all your transactions, budgets, and savings goals. '
          'Default categories will be restored. This action cannot be undone.\n\n'
          'Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await _databaseHelper.clearAllData();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'App reset to factory settings. Default categories restored.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/splash', (route) => false);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportMonthlyExcel() async {
    try {
      final DateTime now = DateTime.now();
      final DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
      final DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

      final transactions = await _databaseHelper.getTransactionsByDateRange(
        firstDayOfMonth,
        lastDayOfMonth,
      );

      if (transactions.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No transactions found for this month.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];

      // Set headers
      sheet.getRangeByName('A1').setText('Date');
      sheet.getRangeByName('B1').setText('Description');
      sheet.getRangeByName('C1').setText('Amount');
      sheet.getRangeByName('D1').setText('Type');
      sheet.getRangeByName('E1').setText('Category');
      sheet.getRangeByName('F1').setText('Payment Method');

      // Add data
      for (int i = 0; i < transactions.length; i++) {
        final transaction = transactions[i];
        final row = i + 2;

        sheet
            .getRangeByName('A$row')
            .setDateTime(
              DateTime.fromMillisecondsSinceEpoch(transaction['date'] as int),
            );
        sheet.getRangeByName('B$row').setText(transaction['note'] as String);
        sheet
            .getRangeByName('C$row')
            .setNumber(transaction['amount'] as double);
        sheet.getRangeByName('D$row').setText(transaction['type'] as String);
        sheet
            .getRangeByName('E$row')
            .setText(transaction['category'] as String);
        sheet.getRangeByName('F$row').setText('Unknown');
      }

      // Format headers
      final headerRange = sheet.getRangeByName('A1:F1');
      headerRange.cellStyle.backColor = '#4F81BD';
      headerRange.cellStyle.fontColor = '#FFFFFF';
      headerRange.cellStyle.bold = true;

      // Auto-fit columns
      sheet.autoFitColumn(1);
      sheet.autoFitColumn(2);
      sheet.autoFitColumn(3);
      sheet.autoFitColumn(4);
      sheet.autoFitColumn(5);
      sheet.autoFitColumn(6);

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      final String fileName =
          'FinFlow_Monthly_${now.year}_${now.month.toString().padLeft(2, '0')}.xlsx';
      final Directory directory = await getApplicationDocumentsDirectory();
      final String filePath = '${directory.path}/$fileName';

      final File file = File(filePath);
      await file.writeAsBytes(bytes);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Monthly Excel export completed!'),
          backgroundColor: Colors.green,
        ),
      );

      // Open the file
      await OpenFile.open(filePath);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBiometricSetupDialog() async {
    final isBiometricAvailable = await _localAuthService.isBiometricAvailable();

    if (!mounted) return;

    if (isBiometricAvailable) {
      final navigator = Navigator.of(context);

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Enable Biometric Authentication'),
            content: const Text(
              'Use your fingerprint or face ID to secure the app.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  navigator.pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final isAuthenticated = await _localAuthService
                      .authenticate();
                  if (isAuthenticated) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('app_lock_enabled', true);
                    if (!mounted) return;
                    setState(() {
                      _isAppLockEnabled = true;
                    });
                    Future.microtask(() => navigator.pop());
                  }
                },
                child: const Text('Enable'),
              ),
            ],
          );
        },
      );
    } else {
      _showSetPinDialog();
    }
  }

  void _showSetPinDialog() {
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set PIN'),
          content: TextField(
            controller: _pinController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Enter a 4-digit PIN'),
            keyboardType: TextInputType.number,
            maxLength: 4,
          ),
          actions: [
            TextButton(
              onPressed: () {
                navigator.pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_pinController.text.length == 4) {
                  await _secureStorage.write(
                    key: 'pin',
                    value: _pinController.text,
                  );
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('app_lock_enabled', true);
                  if (!mounted) return;
                  setState(() {
                    _isAppLockEnabled = true;
                  });
                  Future.microtask(() => navigator.pop());
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGoogleSection(bool isDarkMode) {
    final currentUser = _googleAuthService.getCurrentGoogleUser();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              splashColor: Colors.transparent,
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.g_mobiledata, color: Colors.white),
              ),
              title: Text(
                currentUser != null
                    ? 'Connected to Google'
                    : 'Connect to Google',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
              ),
              subtitle: currentUser != null
                  ? Text(
                      currentUser.email,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: isDarkMode
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    )
                  : Text(
                      'Sign in with Google to sync your data',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: isDarkMode
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
              trailing: currentUser != null
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () async {
                        await _googleAuthService.signOutFromGoogle();
                        if (!mounted) return;
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Disconnected from Google'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: Text(
                        'Disconnect',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4285F4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () async {
                        final user = await _googleAuthService.signInWithGoogle(
                          context,
                        );
                        if (user != null && mounted) {
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Connected to Google as ${user.email}',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Connect',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
