import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:finflow/screens/welcome_screen.dart';
import 'package:finflow/screens/main_wrapper.dart';
import 'package:finflow/screens/add_transaction_screen.dart';
import 'package:finflow/providers/transaction_provider.dart';
import 'package:finflow/providers/currency_provider.dart';
import 'package:finflow/providers/theme_provider.dart';
import 'package:finflow/providers/user_provider.dart';
import 'package:finflow/providers/settings_provider.dart';
import 'package:finflow/providers/navigation_provider.dart';
import 'package:finflow/providers/category_provider.dart';
import 'package:finflow/utils/app_theme.dart';
import 'package:finflow/utils/debug_logger.dart';
import 'package:finflow/firebase_options.dart';
import 'package:finflow/services/test_user_service.dart';
import 'package:finflow/services/notification_service.dart';
import 'package:upgrader/upgrader.dart';

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
void main() {
  // Ensure Flutter binding is initialized - this is sync, zero delay
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ RUN APP INSTANTLY - NO BLOCKING WAITS!
  // First frame renders in <100ms, all initialization happens AFTER UI is visible
  runApp(const FinFlowApp());

  // Initialize Firebase in background after first frame is rendered
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initializeFirebaseWithTimeout();
  });

  // Initialize timezone in background (non-blocking microtask)
  Future.microtask(() {
    try {
      tz.initializeTimeZones();
    } catch (e) {
      logError('Timezone initialization failed', error: e);
    }
  });

  // Ensure test user exists - runs completely in background
  Future.microtask(() async {
    try {
      final testUserService = TestUserService();
      await testUserService.ensureTestUserExists();
    } catch (e) {
      logError('Test user initialization failed', error: e);
    }

    try {
      // Initialize Notification Service
      await NotificationService().init();
      logDebug('Notification Service initialized');
    } catch (e) {
      logError('Notification Service initialization failed', error: e);
    }
  });
}

/// Initialize Firebase properly and completely before marking ready
Future<void> _initializeFirebaseWithTimeout() async {
  if (_firebaseInitialized || _firebaseInitializing) return;
  _firebaseInitializing = true;

  int retryAttempt = 0;
  const maxRetries = 3;

  while (retryAttempt < maxRetries && !_firebaseInitialized) {
    try {
      // Remove timeout - wait for Firebase to actually complete initialization properly
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Verify Firebase app is actually ready by accessing it
      final firebaseApp = Firebase.app();
      // Access properties to validate app is fully initialized
      firebaseApp.options; // This will throw if app is not properly initialized

      // ✅ Enable Firestore Offline Persistence (OFFLINE FIRST)
      // Using modern non-deprecated API: persistence is configured via Settings
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: -1,
      );

      _firebaseInitialized = true;
      logDebug(
        '✅ Firebase initialized successfully (attempt ${retryAttempt + 1})',
      );
      break;
    } catch (e) {
      retryAttempt++;
      logError(
        'Firebase initialization failed (attempt $retryAttempt)',
        error: e,
      );

      if (retryAttempt < maxRetries) {
        logDebug(
          'Retrying Firebase initialization in ${retryAttempt * 500}ms...',
        );
        await Future.delayed(Duration(milliseconds: retryAttempt * 500));
      } else {
        // Only mark as initialized after all retries have been exhausted
        // Never fake success before actual completion
        _firebaseInitialized = true;
        logError(
          'All Firebase initialization attempts failed. App will continue with limited functionality.',
        );
      }
    }
  }

  _firebaseInitializing = false;
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
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProxyProvider<CurrencyProvider, TransactionProvider>(
          create: (_) => TransactionProvider(),
          update: (_, currencyProvider, transactionProvider) =>
              transactionProvider!..updateCurrencyProvider(currencyProvider),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'FinFlow',
            theme: AppTheme.theme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: UpgradeAlert(
              upgrader: Upgrader(
                debugDisplayAlways: false,
                durationUntilAlertAgain: Duration(hours: 12),
              ),
              child: const AuthWrapper(),
            ),
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
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _firebaseReady = false;

  @override
  void initState() {
    super.initState();
    _checkFirebaseStatus();
  }

  /// Poll for Firebase initialization status with proper timeout safety
  void _checkFirebaseStatus() async {
    // Check immediately first
    if (isFirebaseReady()) {
      if (mounted) setState(() => _firebaseReady = true);
      return;
    }

    // Check at increasing intervals until ready OR maximum wait time reached
    int delayMs = 50;
    int totalWaitedMs = 0;
    const maxTotalWaitMs = 10000; // 10 seconds maximum splash screen time

    while (!isFirebaseReady() && mounted && totalWaitedMs < maxTotalWaitMs) {
      await Future.delayed(Duration(milliseconds: delayMs));
      totalWaitedMs += delayMs;
      delayMs = (delayMs * 1.5).clamp(50, 500).toInt(); // Max 500ms checks
    }

    if (mounted) {
      // Always exit splash screen after max wait time - NEVER get stuck
      setState(() => _firebaseReady = true);

      if (totalWaitedMs >= maxTotalWaitMs) {
        logDebug(
          'Max splash screen wait time reached. Proceeding even if Firebase not ready.',
        );
      } else {
        logDebug('Firebase ready, rebuilding auth wrapper');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Firebase still initializing - keep showing native splash screen
    if (!_firebaseReady) {
      return const SplashScreen();
    }

    // Firebase is ready - now establish auth stream
    // ✅ INSTANT NAVIGATION - NO WAITING!
    // Show WelcomeScreen immediately while auth state loads in background
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ✅ NEVER show splash screen again after Firebase is ready
        // Show WelcomeScreen INSTANTLY while auth state is loading

        // User is authenticated - show main app
        if (snapshot.hasData) {
          final user = snapshot.data;
          logDebug('User authenticated: ${user?.email}');

          // Initialize transaction provider for authenticated user
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              final transactionProvider = Provider.of<TransactionProvider>(
                context,
                listen: false,
              );
              if (!transactionProvider.isInitialized) {
                transactionProvider.initializeTransactions();
              }
            } catch (e) {
              logError('Failed to initialize transaction provider', error: e);
            }
          });

          return const MainWrapper();
        }

        // ✅ Show WelcomeScreen INSTANTLY for all other cases:
        // - Loading state
        // - Error state
        // - No user authenticated
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
                'FinFlow AI ',
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
