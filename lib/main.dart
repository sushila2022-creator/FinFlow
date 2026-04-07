import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:finflow/screens/welcome_screen.dart';
import 'package:finflow/screens/main_wrapper.dart';
import 'package:finflow/screens/add_transaction_screen.dart';
import 'package:finflow/providers/transaction_provider.dart';
import 'package:finflow/providers/currency_provider.dart';
import 'package:finflow/providers/theme_provider.dart';
import 'package:finflow/providers/user_provider.dart';
import 'package:finflow/utils/app_theme.dart';
import 'package:finflow/utils/debug_logger.dart';
import 'package:finflow/firebase_options.dart';
import 'package:finflow/services/test_user_service.dart';

/// Global flag to track Firebase initialization status
bool _firebaseInitialized = false;
bool _firebaseInitializing = false;

/// FinFlow - Main Entry Point with Optimized Startup Performance
///
/// Performance optimizations:
/// 1. Firebase initialized with timeout to prevent hanging
/// 2. Timezone initialization is non-blocking
/// 3. All providers start with default values immediately
/// 4. Splash screen shown while Firebase initializes
///
/// Authentication:
/// - StreamBuilder listens to FirebaseAuth.instance.authStateChanges for navigation
/// - FirebaseAuth.instance.currentUser is the single source of truth
/// - No SharedPreferences-based login flags
void main() async {
  // Ensure Flutter binding is initialized before any async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with timeout for better startup performance
  await _initializeFirebaseWithTimeout();

  // Initialize timezone in background (non-blocking)
  Future.microtask(() => tz.initializeTimeZones());

  // Ensure test user exists for Google Play review (runs silently in background)
  // This will not block app startup and won't interfere with normal users
  Future.microtask(() async {
    try {
      final testUserService = TestUserService();
      await testUserService.ensureTestUserExists();
    } catch (e) {
      // Silently fail - don't crash the app if test user creation fails
      logError('Failed to create test user', error: e);
    }
  });

  // Run the app
  runApp(const FinFlowApp());
}

/// Initialize Firebase with a timeout to prevent long startup delays
Future<void> _initializeFirebaseWithTimeout() async {
  if (_firebaseInitialized || _firebaseInitializing) return;
  _firebaseInitializing = true;

  try {
    // Use timeout to prevent Firebase initialization from blocking too long
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 2),
      onTimeout: () {
        logDebug('Firebase initialization timeout - continuing anyway');
        return Firebase.app(); // Return the app instance
      },
    );
    _firebaseInitialized = true;
    logDebug('Firebase initialized successfully');
  } catch (e) {
    logError('Firebase initialization failed', error: e);
    // Mark as initialized even on failure to prevent retry loops
    _firebaseInitialized = true;
  }
}

/// Check if Firebase is ready for use
bool isFirebaseReady() => _firebaseInitialized;

/// Main application widget with global auth state management
class FinFlowApp extends StatelessWidget {
  const FinFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'FinFlow',
            theme: AppTheme.theme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),
            routes: {
              '/home': (context) => const MainWrapper(),
              '/welcome': (context) => const WelcomeScreen(),
              '/login': (context) => const WelcomeScreen(),
              '/signup': (context) => const WelcomeScreen(),
              '/add_transaction': (context) => const AddTransactionScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

/// Authentication Wrapper - Controls navigation based on auth state
/// This is the single source of truth for authentication-based navigation
///
/// Performance optimization: Handles case where Firebase is initializing in background
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Use a try-catch to handle Firebase not being initialized yet
    Stream<User?>? authStream;
    try {
      authStream = FirebaseAuth.instance.authStateChanges();
    } catch (e) {
      // Firebase not ready yet - show splash and retry
      logDebug('Firebase not ready for auth stream, showing splash');
      return const SplashScreen();
    }

    return StreamBuilder<User?>(
      stream: authStream,
      builder: (context, snapshot) {
        // Connection is still pending
        if (snapshot.connectionState == ConnectionState.waiting) {
          logDebug('Auth state connection pending...');
          return const SplashScreen();
        }

        // Handle stream errors (e.g., Firebase not fully initialized)
        if (snapshot.hasError) {
          logDebug('Auth stream error: ${snapshot.error}');
          // Show splash screen and let it retry
          return const SplashScreen();
        }

        // User is authenticated - show main app
        if (snapshot.hasData) {
          final user = snapshot.data;
          logDebug('User authenticated: ${user?.email}');

          // Initialize transaction provider for authenticated user
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final transactionProvider = Provider.of<TransactionProvider>(
              context,
              listen: false,
            );
            if (!transactionProvider.isInitialized) {
              transactionProvider.initializeTransactions();
            }
          });

          return const MainWrapper();
        }

        // User is NOT authenticated - show login/welcome screen
        logDebug('No authenticated user, showing welcome screen');
        return const WelcomeScreen();
      },
    );
  }
}

/// Splash screen shown while checking authentication state
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A2540), Color(0xFF05192D)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 24),
              Text(
                'FinFlow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
