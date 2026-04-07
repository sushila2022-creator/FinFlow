import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finflow/utils/debug_logger.dart';

/// TestUserService - Creates a permanent test account for Google Play review
///
/// This service runs silently in the background to ensure a test account
/// is always available for reviewers. It will:
/// 1. Check if the test user exists
/// 2. Create the user if it doesn't exist
/// 3. Ensure the account can log in without OTP or verification
///
/// Test credentials:
/// - Email: appsmasters26@gmail.com
/// - Password: 1234@5678
class TestUserService {
  static const String _testEmail = 'appsmasters26@gmail.com';
  static const String _testPassword = '1234@5678';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize test user - call this on app startup
  /// This runs silently in the background and won't interfere with normal users
  Future<void> ensureTestUserExists() async {
    try {
      // First check if the test user already exists by trying to fetch user data
      final bool exists = await _checkIfUserExists(_testEmail);

      if (!exists) {
        logDebug('Test user does not exist, creating...');
        await _createTestUser();
      } else {
        logDebug('Test user already exists');
      }
    } catch (e) {
      // Log error but don't crash the app
      logError('Failed to ensure test user exists', error: e);
    }
  }

  /// Check if a user with the given email exists
  /// Note: Firebase doesn't provide a direct way to check if a user exists by email
  /// We'll try to sign in with a dummy password and check the error
  Future<bool> _checkIfUserExists(String email) async {
    try {
      // Try to fetch user document from Firestore (if we store user data there)
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        return true;
      }

      // If not found in Firestore, try to check via Firebase Auth
      // We'll attempt to sign in with an invalid password and check the error code
      try {
        // Use a definitely wrong password to check if user exists
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: 'definitely_wrong_password_12345',
        );
        // If sign in somehow succeeded (very unlikely), sign out immediately
        await _auth.signOut();
        return true;
      } on FirebaseAuthException catch (e) {
        // If error is user-not-found, user doesn't exist
        if (e.code == 'user-not-found') {
          return false;
        }
        // If error is wrong-password, user exists
        if (e.code == 'wrong-password') {
          return true;
        }
        // For other errors, assume user might exist
        logDebug('Error checking user existence: ${e.code}');
        return false;
      }
    } catch (e) {
      logError('Error checking if user exists', error: e);
      return false;
    }
  }

  /// Create the test user with email/password authentication
  Future<void> _createTestUser() async {
    try {
      // Create user with Firebase Auth
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _testEmail,
            password: _testPassword,
          );

      final User? user = userCredential.user;
      if (user == null) {
        logError('Failed to create test user: user is null');
        return;
      }

      logDebug('Test user created successfully: $_testEmail');

      // Send email verification (optional - we'll also mark as verified in Firestore)
      // Note: We won't require email verification for this test account
      try {
        await user.sendEmailVerification();
        logDebug('Email verification sent to test user');
      } catch (e) {
        // Don't fail if email verification fails
        logDebug('Could not send email verification: $e');
      }

      // Save user data to Firestore
      await _saveTestUserData(user.uid);

      // Sign out so the test user is not automatically logged in
      // The reviewer should manually log in with the credentials
      await _auth.signOut();

      logDebug('Test user setup complete');
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      String errorMessage = 'Firebase Auth error: ${e.code}';

      switch (e.code) {
        case 'email-already-in-use':
          // User already exists - this is fine, we can still use it
          logDebug('Test user already exists (email-already-in-use)');
          // Try to sign in to verify credentials work
          await _verifyTestUserCredentials();
          return;
        case 'weak-password':
          errorMessage = 'Password is too weak';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password authentication is not enabled';
          break;
        default:
          errorMessage = 'Failed to create test user: ${e.message}';
      }

      logError(errorMessage, error: e);
      rethrow;
    } catch (e) {
      logError('Unexpected error creating test user', error: e);
      rethrow;
    }
  }

  /// Verify that the test user credentials work
  Future<void> _verifyTestUserCredentials() async {
    try {
      // Try to sign in with test credentials
      await _auth.signInWithEmailAndPassword(
        email: _testEmail,
        password: _testPassword,
      );

      logDebug('Test user credentials verified successfully');

      // Sign out immediately
      await _auth.signOut();
    } catch (e) {
      logError('Test user credentials verification failed', error: e);
    }
  }

  /// Save test user data to Firestore
  Future<void> _saveTestUserData(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'email': _testEmail,
        'name': 'Test User',
        'isTestAccount': true,
        'provider': 'email',
        'emailVerified': true, // Mark as verified to bypass verification
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      logDebug('Test user data saved to Firestore');
    } catch (e) {
      logError('Failed to save test user data to Firestore', error: e);
    }
  }

  /// Get test user credentials (for debugging purposes)
  static Map<String, String> getTestCredentials() {
    return {'email': _testEmail, 'password': _testPassword};
  }
}
