import 'package:finflow/providers/transaction_provider.dart';
import 'package:finflow/providers/currency_provider.dart';
import 'package:finflow/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finflow/services/auth/secure_storage_service.dart';
import 'package:finflow/services/auth/local_auth_service.dart';
import 'package:finflow/screens/manage_categories_screen.dart';
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
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool _isAppLockEnabled = false;
  bool _dailyReminderEnabled = false;
  final SecureStorageService _secureStorageService = SecureStorageService();
  final LocalAuthService _localAuthService = LocalAuthService();
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _pinController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  bool _isBackupInProgress = false;
  bool _isRestoreInProgress = false;

  // Define a list of common currencies with their symbols
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
  }

  Future<void> _loadAppLockState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAppLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
    });
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('daily_reminder_enabled') ?? false;
    setState(() {
      _dailyReminderEnabled = enabled;
    });

    // Schedule or cancel reminder based on saved setting
    if (enabled) {
      await _notificationService.scheduleDailyReminder(9, 0); // 9 AM
    } else {
      await _notificationService.cancelDailyReminder();
    }
  }



  void _shareApp() {
    SharePlus.instance.share(
      ShareParams(
        text: 'Check out FinFlow - Your personal finance management app! Download now and take control of your finances. https://play.google.com/store/apps/details?id=com.finflow.app',
        subject: 'FinFlow - Personal Finance Management',
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, CurrencyProvider currencyProvider) {
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
                final isSelected = currency['symbol'] == currencyProvider.currentCurrencySymbol;

                return ListTile(
                  title: Text('${currency['name']} (${currency['symbol']})'),
                  trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF0A2540)) : null,
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
      // Get the database file path
      final dbPath = await getDatabasesPath();
      if (!mounted) return;
      final dbFilePath = path.join(dbPath, 'FinFlow.db');
      
      final dbFile = File(dbFilePath);
      if (!await dbFile.exists()) {
        throw Exception('Database file not found');
      }
      if (!mounted) return;

      // Create a backup filename
      final backupFileName = 'finflow_backup.db';

      // Get temporary directory to store backup
      final tempDir = await getTemporaryDirectory();
      if (!mounted) return;
      final backupPath = path.join(tempDir.path, backupFileName);

      // Copy the database file to backup location
      await dbFile.copy(backupPath);
      if (!mounted) return;

      // Share the backup file using SharePlus
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(backupPath, mimeType: 'application/octet-stream')],
          subject: 'FinFlow Database Backup',
          text: 'This is your FinFlow database backup.',
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
    // Show confirmation dialog
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
      // Pick the backup file
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
      
      // Validate that it's a SQLite database file
      if (!selectedFile.path.toLowerCase().endsWith('.db')) {
        throw Exception('Please select a valid database file (.db)');
      }

      // Get the current database path
      final dbPath = await getDatabasesPath();
      if (!mounted) return;
      final dbFilePath = path.join(dbPath, 'FinFlow.db');
      final currentDbFile = File(dbFilePath);

      // Close the current database connection
      Database? currentDb = await _databaseHelper.database;
      if (!mounted) return;
      await currentDb.close();
      if (!mounted) return;
      
      // Create a backup of current database before replacing
      if (await currentDbFile.exists()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final emergencyBackupPath = path.join(dbPath, 'FinFlow_emergency_backup_$timestamp.db');
        await currentDbFile.copy(emergencyBackupPath);
      }
      if (!mounted) return;

      // Copy the selected backup file to replace the current database
      await selectedFile.copy(dbFilePath);

      if (!mounted) return;

      // Show success message and restart the app
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data Restored Successfully. Please restart the app'),
          backgroundColor: Colors.green,
        ),
      );

      // Restart the app after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          // Restart the app by navigating to splash screen
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/splash',
            (route) => false,
          );
        }
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0A2540),
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<CurrencyProvider>(
                builder: (context, currencyProvider, child) {
                  final currentCurrency = currencies.firstWhere(
                    (currency) => currency['symbol'] == currencyProvider.currentCurrencySymbol,
                    orElse: () => {'name': 'US Dollar', 'symbol': '\$'},
                  );

                  return ListTile(
                    leading: const Icon(Icons.currency_rupee),
                    title: const Text('Currency'),
                    trailing: Text(
                      '${currentCurrency['name']} (${currentCurrency['symbol']})',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    onTap: () => _showCurrencyDialog(context, currencyProvider),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Appearance',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF0A2540)),
              ),
              const SizedBox(height: 16),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return SwitchListTile(
                    title: const Text('Dark Mode'),
                    value: themeProvider.isDarkMode,
                    secondary: const Icon(Icons.dark_mode),
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('Manage Categories'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageCategoriesScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Data Management',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF0A2540)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.table_view, color: Colors.green),
                title: const Text('Export to Excel'),
                trailing: const Icon(Icons.file_upload),
                onTap: () {
                  final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
                  transactionProvider.exportTransactionsCsv(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Reset App Data'),
                trailing: const Icon(Icons.delete_forever, color: Colors.red),
                onTap: _deleteAllData,
              ),
              const SizedBox(height: 24),
              Text(
                'Backup & Restore',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF0A2540)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.cloud_upload),
                title: const Text('Backup Database'),
                subtitle: const Text('Export your complete database'),
                trailing: _isBackupInProgress
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.backup),
                onTap: _isBackupInProgress ? null : _backupDatabase,
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Restore Database'),
                subtitle: const Text('Import a database backup file'),
                trailing: _isRestoreInProgress
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restore),
                onTap: _isRestoreInProgress ? null : _restoreDatabase,
              ),
              const SizedBox(height: 24),
              Text(
                'Security',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF0A2540)),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Enable App Lock'),
                value: _isAppLockEnabled,
                secondary: const Icon(Icons.lock),
                onChanged: (value) async {
                  if (value) {
                    _showBiometricSetupDialog();
                  } else {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('app_lock_enabled', false);
                    await _secureStorageService.writePin('');
                    setState(() {
                      _isAppLockEnabled = false;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Notifications',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF0A2540)),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Daily Reminder'),
                subtitle: const Text('Get reminded daily at 9 AM'),
                value: _dailyReminderEnabled,
                secondary: const Icon(Icons.notifications),
                onChanged: (value) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('daily_reminder_enabled', value);
                  setState(() {
                    _dailyReminderEnabled = value;
                  });

                  // Schedule or cancel daily reminder
                  if (value) {
                    await _notificationService.scheduleDailyReminder(9, 0); // 9 AM
                  } else {
                    await _notificationService.cancelDailyReminder();
                  }
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Support & About',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF0A2540)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  final currentContext = context;
                  const url = 'https://www.google.com';
                  try {
                    await launchUrl(Uri.parse(url));
                  } catch (e) {
                    // Handle launch error silently
                  }
                  if (!currentContext.mounted) return;
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(content: Text('Could not launch link')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Rate Us'),
                trailing: const Icon(Icons.star_border),
                onTap: () async {
                  final currentContext = context;
                  const url = 'market://details?id=com.example.finflow';
                  try {
                    await launchUrl(Uri.parse(url));
                  } catch (e) {
                    // Handle launch error silently
                  }
                  if (!currentContext.mounted) return;
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(content: Text('Could not launch link')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share App'),
                trailing: const Icon(Icons.share),
                onTap: _shareApp,
              ),
              const SizedBox(height: 24),
              ListTile(
                title: const Text('Logout'),
                leading: const Icon(Icons.logout, color: Colors.red),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  await FirebaseAuth.instance.signOut();
                  navigator.pushNamedAndRemoveUntil('/login', (route) => false);
                },
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'App Version 1.0.0',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBiometricSetupDialog() async {
    final isBiometricAvailable = await _localAuthService.isBiometricAvailable();

    if (!mounted) return;

    if (isBiometricAvailable) {
      // Capture Navigator reference to avoid BuildContext across async gaps
      final navigator = Navigator.of(context);
      
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Enable Biometric Authentication'),
            content: const Text('Use your fingerprint or face ID to secure the app.'),
            actions: [
              TextButton(
                onPressed: () {
                  navigator.pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final isAuthenticated = await _localAuthService.authenticate();
                  if (isAuthenticated) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('app_lock_enabled', true);
                    if (!mounted) return;
                    setState(() {
                      _isAppLockEnabled = true;
                    });
                    // Use microtask with navigator reference to avoid BuildContext across async gaps
                    if (!mounted) return;
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
      // Fallback to PIN if biometrics are not available
      _showSetPinDialog();
    }
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
          content: Text('App reset to factory settings. Default categories restored.'),
          backgroundColor: Colors.green,
        ),
      );

      // Restart the app after deleting data
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/splash',
            (route) => false,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSetPinDialog() {
    // Capture Navigator reference to avoid BuildContext across async gaps
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set PIN'),
          content: TextField(
            controller: _pinController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Enter a 4-digit PIN',
            ),
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
                  await _secureStorageService.writePin(_pinController.text);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('app_lock_enabled', true);
                  if (!mounted) return;
                  setState(() {
                    _isAppLockEnabled = true;
                  });
                  // Use microtask with navigator reference to avoid BuildContext across async gaps
                  if (!mounted) return;
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
