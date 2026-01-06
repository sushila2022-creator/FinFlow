import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finflow/app.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:finflow/providers/transaction_provider.dart';
import 'package:finflow/providers/currency_provider.dart';
import 'package:finflow/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finflow/screens/auth/auth_screen.dart';
import 'package:finflow/utils/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finflow/screens/login_screen.dart';
import 'package:finflow/screens/main_screen.dart';
import 'package:finflow/screens/signup_screen.dart';
import 'package:finflow/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.init();

  final prefs = await SharedPreferences.getInstance();
  final isAppLockEnabled = prefs.getBool('app_lock_enabled') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Add other providers here if needed in the future
      ],
      child: App(isAppLockEnabled: isAppLockEnabled),
    ),
  );
}

class App extends StatefulWidget {
  final bool isAppLockEnabled;

  const App({super.key, required this.isAppLockEnabled});

  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isAppLockEnabled) {
      _isAuthenticated = true;
    }
  }

  void _onAuthenticated() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            theme: AppTheme.theme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const LoginScreen(),
            routes: {
              '/home': (context) => const MainScreen(),
              '/signup': (context) => const SignupScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      );
    } else {
      return Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return _isAuthenticated
              ? FinFlowApp(themeProvider: themeProvider)
              : MaterialApp(
                  theme: AppTheme.theme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeProvider.themeMode,
                  home: AuthScreen(onAuthenticated: _onAuthenticated),
                  routes: {
                    '/home': (context) => const MainScreen(),
                    '/signup': (context) => const SignupScreen(),
                  },
                  debugShowCheckedModeBanner: false,
                );
        },
      );
    }
  }
}
