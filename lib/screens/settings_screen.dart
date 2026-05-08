import 'package:finflow/providers/transaction_provider.dart';
import 'package:finflow/providers/currency_provider.dart';
import 'package:finflow/providers/theme_provider.dart';
import 'package:finflow/providers/user_provider.dart';
import 'package:finflow/providers/settings_provider.dart';
import 'package:finflow/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finflow/services/auth/local_auth_service.dart';
import 'package:finflow/services/auth/google_auth_service.dart';
import 'package:finflow/screens/manage_categories_screen.dart';
import 'package:finflow/utils/database_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:finflow/screens/premium_screen.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row;
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final LocalAuthService _localAuthService = LocalAuthService();
  final TextEditingController _pinController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  bool _isBackupInProgress = false;
  bool _isRestoreInProgress = false;
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    _packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {});
    }
  }

  // Methods removed: _loadAppLockState, _loadNotificationSettings, _loadSmsScanSettings
  // These are now handled by SettingsProvider

  Future<void> _editProfile(dynamic user) async {
    if (user == null) return;

    final TextEditingController nameController = TextEditingController(
      text: user.name,
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Enter your new name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, nameController.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty && newName != user.name) {
      if (!mounted) return;
      try {
        final authUser = FirebaseAuth.instance.currentUser;
        if (authUser != null) {
          await authUser.updateDisplayName(newName);
        }

        if (!mounted) return;
        final updatedUser = user.copyWith(name: newName);
        await Provider.of<UserProvider>(
          context,
          listen: false,
        ).updateUser(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: $e')),
          );
        }
      }
    }
  }

  void _shareApp() {
    SharePlus.instance.share(
      ShareParams(
        text:
            'Check out FinFlow AI – Money Manager - Your personal finance management app! Download now and take control of your finances. https://play.google.com/store/apps/details?id=com.finflowai.money.manager',
        subject: 'FinFlow AI – Money Manager - Personal Finance Management',
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
      // FIX: Use the correct database filename that matches DatabaseHelper
      final dbFilePath = path.join(dbPath, 'finflow_v4.db');

      final dbFile = File(dbFilePath);
      if (!await dbFile.exists()) {
        throw Exception('Database file not found');
      }
      if (!mounted) return;

      final backupFileName =
          'finflow_backup_${DateTime.now().millisecondsSinceEpoch}.db';
      final tempDir = await getTemporaryDirectory();
      if (!mounted) return;
      final backupPath = path.join(tempDir.path, backupFileName);

      await dbFile.copy(backupPath);
      if (!mounted) return;

      // Use SharePlus to share the backup file
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(backupPath, mimeType: 'application/octet-stream')],
          text: 'This is your FinFlow database backup.',
          subject: 'FinFlow Database Backup',
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
      // FIX: Use the correct database filename that matches DatabaseHelper
      final dbFilePath = path.join(dbPath, 'finflow_v4.db');
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
        ).pushNamedAndRemoveUntil('/welcome', (route) => false);
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
            // Profile Section
            _buildSectionHeader('Profile', isDarkMode),
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                final user = userProvider.currentUser;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 2,
                  ),
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
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppTheme.primaryColor,
                            child: Text(
                              user != null && user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : 'U',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? 'User',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDarkMode
                                        ? AppTheme.textPrimaryDark
                                        : AppTheme.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.email ?? 'No email',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode
                                        ? AppTheme.textSecondaryDark
                                        : AppTheme.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: isDarkMode
                                  ? AppTheme.textPrimaryDark
                                  : AppTheme.primaryColor,
                            ),
                            tooltip: 'Edit Profile',
                            onPressed: () => _editProfile(user),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
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
                    'trailing': Consumer<SettingsProvider>(
                      builder: (context, settings, _) => Switch(
                        value: settings.isSmsScanEnabled,
                        activeThumbColor: const Color(0xFF00C853),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (value) async {
                          if (value) {
                            final success = await settings.setSmsScanEnabled(
                              true,
                            );
                            if (!success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'SMS permission is required for this feature',
                                  ),
                                  backgroundColor: AppTheme.expenseColor,
                                  action: SnackBarAction(
                                    label: 'Settings',
                                    textColor: Colors.white,
                                    onPressed: () => openAppSettings(),
                                  ),
                                ),
                              );
                            }
                          } else {
                            await settings.setSmsScanEnabled(false);
                          }
                        },
                      ),
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
                  transactionProvider.exportTransactionsExcel(context);
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
                'onTap': () => _toggleAppLock(
                  context.read<SettingsProvider>().isAppLockEnabled,
                ),
                'trailing': Consumer<SettingsProvider>(
                  builder: (context, settings, _) => Switch(
                    value: settings.isAppLockEnabled,
                    activeThumbColor: const Color(0xFF00C853),
                    onChanged: (value) => _toggleAppLock(!value),
                  ),
                ),
              },
            ], isDarkMode),
            const SizedBox(height: 16),
            _buildSectionHeader('Notifications', isDarkMode),
            _buildSection([
              {
                'icon': Icons.notifications,
                'title': 'Daily Reminder',
                'onTap': () => _toggleDailyReminder(
                  context.read<SettingsProvider>().dailyReminderEnabled,
                ),
                'trailing': Consumer<SettingsProvider>(
                  builder: (context, settings, _) => Switch(
                    value: settings.dailyReminderEnabled,
                    activeThumbColor: const Color(0xFF00C853),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (value) => _toggleDailyReminder(!value),
                  ),
                ),
              },
            ], isDarkMode),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            _buildSectionHeader('Support & About', isDarkMode),
            _buildSection([
              {
                'icon': Icons.privacy_tip,
                'title': 'Privacy Policy',
                'onTap': () async {
                  try {
                    // Privacy policy hosted on Google Sites
                    final privacyPolicyUrl =
                        'https://sites.google.com/view/finflow-app-privacy/home';
                    await launchUrl(Uri.parse(privacyPolicyUrl));
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
                'icon': Icons.description,
                'title': 'Terms of Service',
                'onTap': () async {
                  try {
                    // Terms of Service hosted on Google Sites
                    final termsOfServiceUrl =
                        'https://sites.google.com/view/finflow-terms-of-service/terms-of-service';
                    await launchUrl(Uri.parse(termsOfServiceUrl));
                  } catch (e) {
                    if (!mounted) return;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not launch terms of service'),
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
                    final currentUser = Provider.of<UserProvider>(
                      context,
                      listen: false,
                    ).currentUser;

                    // Check if user is premium
                    if (currentUser?.isPremium != true) {
                      // Show premium upgrade dialog
                      if (!mounted) return;
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Unlock Premium Features'),
                          content: const Text(
                            'Rating functionality is available for premium users only. '
                            'Upgrade to premium to access this and other exclusive features.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PremiumScreen(),
                                  ),
                                );
                              },
                              child: const Text('Upgrade to Premium'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    // Try to open Google Play Store first
                    final playStoreUrl =
                        'market://details?id=com.finflowai.money.manager';
                    if (await canLaunchUrl(Uri.parse(playStoreUrl))) {
                      await launchUrl(Uri.parse(playStoreUrl));
                    } else {
                      // Fallback to web URL if Play Store is not available
                      final webUrl =
                          'https://play.google.com/store/apps/details?id=com.finflowai.money.manager';
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
                  // Sign out from Firebase - AuthWrapper will handle navigation
                  await FirebaseAuth.instance.signOut();
                  // Navigation is handled by AuthWrapper via auth state changes
                },
                'iconColor': Colors.red,
              },
            ], isDarkMode),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'App Version ${_packageInfo?.version ?? '1.0.8'} (${_packageInfo?.buildNumber ?? '8'})',
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
    if (!mounted) return;

    try {
      // 1. Clear Firestore Transactions
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );
      await transactionProvider.deleteAllTransactionsFromFirestore();

      // 2. Clear Local SQLite Database
      await _databaseHelper.clearAllData();

      // 3. Clear SharedPreferences (App Settings)
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 4. Clear Secure Storage (PIN/App Lock)
      await _secureStorage.deleteAll();

      // 5. Sign Out from Google and Firebase
      await _googleAuthService.signOutFromGoogle();
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'App reset to factory settings. All cloud and local data cleared.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/welcome', (route) => false);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reset failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportMonthlyExcel() async {
    try {
      final DateTime now = DateTime.now();
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );
      final transactions = transactionProvider.transactions
          .where((t) => t.date.year == now.year && t.date.month == now.month)
          .toList();

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

        sheet.getRangeByName('A$row').setDateTime(transaction.date);
        sheet.getRangeByName('B$row').setText(transaction.description);
        sheet.getRangeByName('C$row').setNumber(transaction.amount);
        sheet
            .getRangeByName('D$row')
            .setText(transaction.isIncome ? 'Income' : 'Expense');
        sheet.getRangeByName('E$row').setText(transaction.category);
        sheet.getRangeByName('F$row').setText(transaction.notes ?? '');
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

  Future<void> _toggleAppLock(bool currentValue) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (currentValue) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_lock_enabled', false);
      await _secureStorage.write(key: 'pin', value: '');
      settings.setAppLockEnabled(false);
    } else {
      _showBiometricSetupDialog();
    }
  }

  Future<void> _toggleDailyReminder(bool currentValue) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final success = await settings.setDailyReminderEnabled(!currentValue);

    if (!success && !currentValue && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification permission is required for reminders'),
          backgroundColor: AppTheme.expenseColor,
        ),
      );
    }
  }

  void _showBiometricSetupDialog() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
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
                    settings.setAppLockEnabled(true);
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
    final settings = Provider.of<SettingsProvider>(context, listen: false);
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
                  settings.setAppLockEnabled(true);
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
