import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class LocalAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to open the app',
      );
    } on PlatformException {
      return false;
    }
  }
}
