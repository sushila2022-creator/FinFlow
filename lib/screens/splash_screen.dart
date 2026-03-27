import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/professional_app_icon.dart';
import 'main_wrapper.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding.instance.addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
  }

  Future<void> _checkAuthentication() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Check authentication status
    await userProvider.checkAuthStatus();

    // Limit splash duration to 1.5 seconds maximum
    await Future.delayed(const Duration(milliseconds: 1500));

    // Check if widget is still mounted before navigating
    if (!mounted) return;

    // Check if user is authenticated
    if (userProvider.currentUser != null) {
      // User is authenticated, navigate to main app
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainWrapper()),
        );
      }
    } else {
      // User is not authenticated, navigate to onboarding/welcome screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2540), // Dark professional background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Professional app icon
            ProfessionalAppIcon(size: 140, animate: true),

            const SizedBox(height: 24),

            // App name
            const Text(
              'FinFlow',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),

            const SizedBox(height: 8),

            // Tagline
            const Text(
              'Professional Finance Management',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
