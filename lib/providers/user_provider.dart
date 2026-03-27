import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finflow/models/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  UserProvider() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        await _loadUserFromFirestore(firebaseUser);
      }
    } catch (e) {
      // Error initializing user
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      // Error checking auth status
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
        _currentUser = UserModel(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
          email: firebaseUser.email ?? '',
          isPremium: false,
        );

        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(_currentUser!.toMap());
      }
    } catch (e) {
      // Error loading user from Firestore
      _currentUser = UserModel(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
        email: firebaseUser.email ?? '',
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
}
