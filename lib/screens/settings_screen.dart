import 'package:finflow/providers/transaction_provider.dart';
import 'package:finflow/providers/currency_provider.dart';
import 'package:finflow/providers/theme_provider.dart';
import 'package:finflow/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finflow/services/auth/local_auth_service.dart';
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

  final List<Map<String, String>> currencies = [
    {'name': 'US Dollar', 'symbol': '\$'},
    {'name': 'Euro', 'symbol': '€'},
    {'name': 'British Pound', 'symbol': '£'},
    {'name': 'Japanese Yen', 'symbol': '¥'},
    {'name': 'Australian Dollar', 'symbol': 'A\$'},
    {'name': 'Canadian Dollar', 'symbol': 'C\$'},
    {'name': 'Swiss Franc', 'symbol': 'CHF'},
    {'name': 'Chinese Yuan', 'symbol': '¥'},
    {'name': 'UAE Dirham', 'symbol': 'د.إ'},
    {'name': 'Saudi Riyal', 'symbol': 'ر.س'},
    {'name': 'Indian Rupee', 'symbol': '₹'},
    {'name': 'Singapore Dollar', 'symbol': 'S\$'},
    {'name': 'Hong Kong Dollar', 'symbol': 'HK\$'},
    {'name': 'South Korean Won', 'symbol': '₩'},
    {'name': 'Turkish Lira', 'symbol': '₺'},
    {'name': 'Brazilian Real', 'symbol': 'R\$'},
    {'name': 'Mexican Peso', 'symbol': '\$'},
    {'name': 'Swedish Krona', 'symbol': 'kr'},
    {'name': 'Norwegian Krone', 'symbol': 'kr'},
    {'name': 'New Zealand Dollar', 'symbol': 'NZ\$'},
  ];

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
      SmsService().start();
    } else {
      SmsService().stop();
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
        toolbarHeight: kToolbarHeight + 20, // Professional spacious look
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
                final currentCurrency = currencies.firstWhere(
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
                    'onTap': () async {
                      final prefs = await SharedPreferences.getInstance();
                      final newValue = !_isSmsScanEnabled;
                      await prefs.setBool('smart_sms_scan_enabled', newValue);
                      setState(() {
                        _isSmsScanEnabled = newValue;
                      });

                      if (newValue) {
                        SmsService().start();
                      } else {
                        SmsService().stop();
                      }
                    },
                    'trailing': Switch(
                      value: _isSmsScanEnabled,
                      activeThumbColor: const Color(0xFF00C853),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (value) async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('smart_sms_scan_enabled', value);
                        setState(() {
                          _isSmsScanEnabled = value;
                        });

                        if (value) {
                          SmsService().start();
                        } else {
                          SmsService().stop();
                        }
                      },
                    ),
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
            _buildSectionHeader('Support & About', isDarkMode),
            _buildSection([
              {
                'icon': Icons.privacy_tip,
                'title': 'Privacy Policy',
                'onTap': () async {
                  try {
                    await launchUrl(Uri.parse('https://www.google.com'));
                  } catch (e) {
                    if (!mounted) return;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not launch link'),
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
                    await launchUrl(
                      Uri.parse('market://details?id=com.example.finflow'),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not launch link'),
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
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.blueGrey,
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
                  fontSize: 12,
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
}
