import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finflow/utils/debug_logger.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      await _saveUserToFirestore(
        uid: userCredential.user!.uid,
        email: googleUser.email,
        name: googleUser.displayName ?? 'Google User',
        photoUrl: googleUser.photoUrl,
        provider: 'google',
      );

      logDebug('Google sign-in successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      logError('Google sign-in failed', error: e);
      rethrow;
    }
  }

  Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        oauthCredential,
      );

      await _saveUserToFirestore(
        uid: userCredential.user!.uid,
        email: appleCredential.email ?? '',
        name:
            appleCredential.givenName != null &&
                appleCredential.familyName != null
            ? '${appleCredential.givenName} ${appleCredential.familyName}'
            : 'Apple User',
        provider: 'apple',
      );

      logDebug('Apple sign-in successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      logError('Apple sign-in failed', error: e);
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> _saveUserToFirestore({
    required String uid,
    required String email,
    required String name,
    String? photoUrl,
    String? provider,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'provider': provider,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      logDebug('User data saved to Firestore: $uid');
    } catch (e) {
      logError('Failed to save user data to Firestore', error: e);
      // Don't fail the login if Firestore write fails
    }
  }

  String getFriendlyErrorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'network-request-failed':
          return 'Network error. Please check your internet connection';
        case 'operation-not-allowed':
          return 'Sign-in method is not enabled';
        case 'user-not-found':
          return 'No account found with this email';
        case 'wrong-password':
          return 'Incorrect password';
        case 'invalid-email':
          return 'Invalid email address';
        case 'user-disabled':
          return 'This account has been disabled';
        case 'too-many-requests':
          return 'Too many login attempts. Please try again later.';
        default:
          return e.message ?? 'Authentication failed';
      }
    }
    return 'An error occurred. Please try again.';
  }
}
