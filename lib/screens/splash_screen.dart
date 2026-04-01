import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'main_wrapper.dart';
import 'welcome_screen.dart';

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
    // Immediately check authentication and navigate - no delay, no animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
  }

  Future<void> _checkAuthentication() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Check authentication status
    await userProvider.checkAuthStatus();

    // Check if widget is still mounted before navigating
    if (!mounted) return;

    // Navigate immediately to the appropriate screen (no animation)
    final nextScreen = userProvider.currentUser != null
        ? const MainWrapper()
        : const WelcomeScreen();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // No transition animation - instant switch
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
    // Return an empty scaffold - native splash screen handles the visuals
    // This screen is just a pass-through for routing logic
    return const Scaffold(backgroundColor: Color(0xFF0A2540));
  }
}
