import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToMain();
  }

  void _navigateToMain() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/icon/icon.jpg',
          width: 250,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.account_balance_wallet,
              size: 250,
              color: Colors.teal,
            );
          },
        ),
      ),
    );
  }
}
