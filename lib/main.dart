import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:finflow/screens/main_wrapper.dart';
import 'package:finflow/screens/welcome_screen.dart';
import 'package:finflow/screens/add_transaction_screen.dart';
import 'package:finflow/providers/transaction_provider.dart';
import 'package:finflow/providers/currency_provider.dart';
import 'package:finflow/providers/theme_provider.dart';
import 'package:finflow/utils/app_theme.dart';
import 'package:finflow/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  tz.initializeTimeZones();
  runApp(const FinFlowApp());
}

class FinFlowApp extends StatelessWidget {
  const FinFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: '',
            theme: AppTheme.theme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
            routes: {
              '/home': (context) => const MainWrapper(),
              '/welcome': (context) => const WelcomeScreen(),
              '/add_transaction': (context) => const AddTransactionScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate loading

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasLoggedIn = prefs.getBool('has_logged_in') ?? false;

      if (hasLoggedIn) {
        // User has logged in before, navigate to home
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        // First time user or not logged in, show welcome screen
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/welcome');
        }
      }
    } catch (e) {
      // If there's an error, default to welcome screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2540),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'FinFlow',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading your finances...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
