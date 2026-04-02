import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'main_wrapper.dart';
import 'login_screen.dart';

/// SplashScreen acts as a pass-through screen that immediately checks
/// authentication status and navigates to the appropriate screen.
/// The native splash screen (configured via flutter_native_splash) handles
/// the visual splash experience - this screen only handles routing logic.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Delay navigation by 2-3 seconds to show splash UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _checkAuthentication();
        }
      });
    });
  }

  Future<void> _checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    // Check if user is already logged in (has_logged_in flag)
    final hasLoggedIn = prefs.getBool('has_logged_in') ?? false;

    if (hasLoggedIn) {
      // User is already logged in, go to main app
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.checkAuthStatus();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainWrapper(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else {
      // Not first time, but not logged in, show login screen
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D2B45), // Dark navy blue background
      body: Center(
        child: Image.asset(
          'assets/splash_screen.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
