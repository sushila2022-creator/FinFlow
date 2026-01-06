import 'package:flutter/material.dart';
import 'package:finflow/services/auth/local_auth_service.dart';
import 'package:finflow/services/auth/secure_storage_service.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  AuthScreenState createState() => AuthScreenState();
}

class AuthScreenState extends State<AuthScreen> {
  final LocalAuthService _localAuthService = LocalAuthService();
  final SecureStorageService _secureStorageService = SecureStorageService();
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAuthenticationMethod();
  }

  Future<void> _checkAuthenticationMethod() async {
    final isBiometricAvailable = await _localAuthService.isBiometricAvailable();
    final storedPin = await _secureStorageService.readPin();

    if (isBiometricAvailable) {
      // Try biometric authentication first
      final isAuthenticated = await _localAuthService.authenticate();
      if (isAuthenticated) {
        widget.onAuthenticated();
      }
      // If biometrics fail, show PIN fallback
    } else if (storedPin != null && storedPin.isNotEmpty) {
      // If no biometrics available but PIN is set, show PIN screen
      setState(() {}); // Just to trigger rebuild if needed
    } else {
      // This shouldn't happen if app lock is properly enabled
      widget.onAuthenticated(); // Fallback - allow access if no auth method available
    }
  }

  Future<void> _authenticateWithPin() async {
    final storedPin = await _secureStorageService.readPin();
    if (storedPin != null && storedPin == _pinController.text) {
      widget.onAuthenticated();
    } else {
      // Check if the widget is still mounted before using BuildContext
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect PIN')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Please authenticate to access the app',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _pinController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Enter PIN',
                hintText: 'Enter your 4-digit PIN',
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _authenticateWithPin,
              child: const Text('Authenticate with PIN'),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () async {
                final isAuthenticated = await _localAuthService.authenticate();
                if (isAuthenticated) {
                  widget.onAuthenticated();
                }
              },
              child: const Text('Try Biometric Authentication'),
            ),
          ],
        ),
      ),
    );
  }
}
