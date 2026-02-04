import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in with Google
  Future<User?> signInWithGoogle(BuildContext context) async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If user cancels, return null
      if (googleUser == null) {
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Capture the mounted state before using context
      if (context.mounted) {
        _handleAuthError(context, e, context.mounted);
      }
      return null;
    } catch (e) {
      // Capture the mounted state before using context
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  // Sign out from Google and Firebase
  Future<void> signOutFromGoogle() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      // Handle sign out error if needed
      Logger('GoogleAuthService').severe('Error signing out from Google: $e');
    }
  }

  // Check if user is signed in with Google
  bool isSignedIn() {
    return _googleSignIn.currentUser != null;
  }

  // Get current Google user
  GoogleSignInAccount? getCurrentGoogleUser() {
    return _googleSignIn.currentUser;
  }

  // Handle authentication errors
  void _handleAuthError(
    BuildContext context,
    FirebaseAuthException e,
    bool isMounted,
  ) {
    String errorMessage = '';

    switch (e.code) {
      case 'account-exists-with-different-credential':
        errorMessage = 'An account already exists with this email address.';
        break;
      case 'invalid-credential':
        errorMessage = 'The credential is malformed or has expired.';
        break;
      case 'operation-not-allowed':
        errorMessage = 'Google sign-in is not enabled.';
        break;
      case 'user-disabled':
        errorMessage = 'This user account has been disabled.';
        break;
      case 'user-not-found':
        errorMessage = 'No user found with this email address.';
        break;
      case 'wrong-password':
        errorMessage = 'Wrong password provided.';
        break;
      case 'invalid-verification-code':
        errorMessage = 'The verification code is invalid.';
        break;
      case 'invalid-verification-id':
        errorMessage = 'The verification ID is invalid.';
        break;
      default:
        errorMessage = 'Authentication failed: ${e.message}';
    }

    if (isMounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }
}
