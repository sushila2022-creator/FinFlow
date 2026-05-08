import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finflow/models/user_model.dart';
import 'package:finflow/utils/debug_logger.dart';

/// Optimized UserProvider with deferred async initialization
///
/// Performance optimizations:
/// 1. Starts with null user immediately (no waiting)
/// 2. Loads user data asynchronously after first frame
/// 3. Uses Future.microtask for non-blocking initialization
/// 4. Gracefully handles Firebase not being initialized
class UserProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  /// PREMIUM FOR ALL USERS - EVERYONE HAS FULL ACCESS
  bool get isPremiumUser => true;

  /// Testing mode - bypasses all premium locks when true
  /// Set this to true for development/testing environments
  static const bool isTestingMode = false;

  // Firestore stream subscription
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<User?>? _authStateSubscription;

  /// Initialize user provider
  /// Loads user data asynchronously without blocking UI
  UserProvider() {
    // Listen for auth state changes to re-initialize listener
    _authStateSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _startUserListener(user);
      } else {
        _cleanup();
      }
    });
  }

  void _cleanup() {
    _userSubscription?.cancel();
    _userSubscription = null;
    _currentUser = null;
    _isInitialized = false;
    notifyListeners();
  }

  void _startUserListener(User firebaseUser) {
    _userSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _userSubscription = _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .snapshots()
        .listen(
          (doc) async {
            if (doc.exists) {
              _currentUser = UserModel.fromSnapshot(doc);
            } else {
              // Create new user document if it doesn't exist
              final email = firebaseUser.email ?? '';
              final fallbackName = email.isNotEmpty
                  ? email.split('@')[0]
                  : 'User';

              _currentUser = UserModel(
                uid: firebaseUser.uid,
                name: firebaseUser.displayName ?? fallbackName,
                email: email,
                isPremium: false,
              );

              await _firestore
                  .collection('users')
                  .doc(firebaseUser.uid)
                  .set(_currentUser!.toMap());
            }

            _isLoading = false;
            _isInitialized = true;
            notifyListeners();
          },
          onError: (e) {
            logError('User listener failed', tag: 'UserProvider', error: e);
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        await _loadUserFromFirestore(firebaseUser);
      }
    } catch (e) {
      logError('Auth status check failed', tag: 'UserProvider', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserFromFirestore(User firebaseUser) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        _currentUser = UserModel.fromSnapshot(userDoc);
      } else {
        // Create new user document if it doesn't exist
        final email = firebaseUser.email ?? '';
        final fallbackName = email.isNotEmpty ? email.split('@')[0] : 'User';

        _currentUser = UserModel(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ?? fallbackName,
          email: email,
          isPremium: false,
        );

        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(_currentUser!.toMap());
      }
    } catch (e) {
      // Error loading user from Firestore - create local user object
      logError(
        'Failed to load user from Firestore',
        tag: 'UserProvider',
        error: e,
      );
      final email = firebaseUser.email ?? '';
      final fallbackName = email.isNotEmpty ? email.split('@')[0] : 'User';

      _currentUser = UserModel(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? fallbackName,
        email: email,
        isPremium: false,
      );
    }
  }

  Future<void> refreshUser() async {
    User? firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await _loadUserFromFirestore(firebaseUser);
    }
  }

  Future<void> updateUser(UserModel updatedUser) async {
    if (_currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .update(updatedUser.toMap());

      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update user profile');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to sign out');
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  void dispose() {
    _userSubscription?.cancel();
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
