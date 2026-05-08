import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finflow/models/category.dart';
import 'package:finflow/utils/database_helper.dart';
import 'package:finflow/utils/debug_logger.dart';

class CategoryProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Category> _categories = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _hasError = false;
  StreamSubscription<QuerySnapshot>? _categorySubscription;
  StreamSubscription<User?>? _authStateSubscription;
  Timer? _loadingTimeoutTimer;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get hasError => _hasError;
  bool get hasCategories => _categories.isNotEmpty;

  static const int _fetchTimeoutSeconds = 10;

  CategoryProvider() {
    _authStateSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _startCategoryListener(user);
      } else {
        _cleanup();
      }
    });
  }

  List<Category> getDefaultCategories() {
    return [
      Category(
        id: 'default_food',
        name: 'Food',
        icon: 'restaurant',
        color: '#F44336',
        type: 'expense',
        budgetLimit: 0.0,
      ),
      Category(
        id: 'default_transport',
        name: 'Transport',
        icon: 'directions_car',
        color: '#2196F3',
        type: 'expense',
        budgetLimit: 0.0,
      ),
      Category(
        id: 'default_shopping',
        name: 'Shopping',
        icon: 'shopping_bag',
        color: '#9C27B0',
        type: 'expense',
        budgetLimit: 0.0,
      ),
      Category(
        id: 'default_bills',
        name: 'Bills',
        icon: 'receipt',
        color: '#FF9800',
        type: 'expense',
        budgetLimit: 0.0,
      ),
      Category(
        id: 'default_entertainment',
        name: 'Entertainment',
        icon: 'movie',
        color: '#4CAF50',
        type: 'expense',
        budgetLimit: 0.0,
      ),
      Category(
        id: 'default_health',
        name: 'Health',
        icon: 'health_and_safety',
        color: '#00BCD4',
        type: 'expense',
        budgetLimit: 0.0,
      ),
      Category(
        id: 'default_salary',
        name: 'Salary',
        icon: 'work',
        color: '#4CAF50',
        type: 'income',
        budgetLimit: 0.0,
      ),
      Category(
        id: 'default_freelance',
        name: 'Freelance',
        icon: 'laptop',
        color: '#2196F3',
        type: 'income',
        budgetLimit: 0.0,
      ),
      Category(
        id: 'default_investment',
        name: 'Investment',
        icon: 'trending_up',
        color: '#FFC107',
        type: 'income',
        budgetLimit: 0.0,
      ),
    ];
  }

  void _cleanup() {
    _categorySubscription?.cancel();
    _categorySubscription = null;
    _loadingTimeoutTimer?.cancel();
    _categories = [];
    _isInitialized = false;
    _isLoading = false;
    _hasError = false;
    notifyListeners();
  }

  Future<void> _startCategoryListener(User user) async {
    _categorySubscription?.cancel();
    _loadingTimeoutTimer?.cancel();

    _isLoading = true;
    _hasError = false;
    notifyListeners();

    // Setup timeout to prevent infinite loading
    _loadingTimeoutTimer = Timer(
      const Duration(seconds: _fetchTimeoutSeconds),
      () {
        if (_isLoading) {
          logDebug(
            'Category fetch timed out after $_fetchTimeoutSeconds seconds, using fallback',
            tag: 'CategoryProvider',
          );
          _handleFetchFailure();
        }
      },
    );

    try {
      // Check if categories exist in Firestore with timeout
      final snapshot = await _firestore
          .collection('categories')
          .where('userId', isEqualTo: user.uid)
          .get()
          .timeout(const Duration(seconds: _fetchTimeoutSeconds));

      if (snapshot.docs.isEmpty) {
        logDebug(
          'No categories in Firestore, checking local database...',
          tag: 'CategoryProvider',
        );

        // Try migrate local categories first
        final localCategories = await _dbHelper.getAllCategoriesObjects();

        if (localCategories.isEmpty) {
          logDebug(
            'No local categories found, creating default categories',
            tag: 'CategoryProvider',
          );
          await _createDefaultCategories(user.uid);
        } else {
          await _migrateLocalToFirestore(user.uid);
        }
      }

      // Start realtime listener
      _categorySubscription = _firestore
          .collection('categories')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen(
            (snapshot) {
              _loadingTimeoutTimer?.cancel();

              _categories = snapshot.docs.map((doc) {
                final data = doc.data();
                return Category(
                  id: doc.id,
                  name: data['name'] ?? 'Unnamed',
                  icon: data['icon'] ?? 'category',
                  color: data['color'] ?? '#4285F4',
                  type: data['type'] ?? 'expense',
                  budgetLimit: (data['budgetLimit'] as num?)?.toDouble() ?? 0.0,
                );
              }).toList();

              // Safety check - if still empty after fetch, use defaults
              if (_categories.isEmpty) {
                logDebug(
                  'Categories still empty after fetch, using default categories',
                  tag: 'CategoryProvider',
                );
                _categories = getDefaultCategories();
              }

              _isLoading = false;
              _isInitialized = true;
              _hasError = false;
              notifyListeners();
            },
            onError: (e) {
              logError(
                'Category listener failed',
                tag: 'CategoryProvider',
                error: e,
              );
              _handleFetchFailure();
            },
          );
    } catch (e) {
      logError(
        'Failed to initialize categories',
        tag: 'CategoryProvider',
        error: e,
      );
      _handleFetchFailure();
    }
  }

  void _handleFetchFailure() {
    _loadingTimeoutTimer?.cancel();

    // Fallback to local database first
    _loadLocalCategories();

    // If still empty, use default categories
    if (_categories.isEmpty) {
      logDebug('Using default categories as fallback', tag: 'CategoryProvider');
      _categories = getDefaultCategories();
    }

    _isLoading = false;
    _isInitialized = true;
    _hasError = true;
    notifyListeners();
  }

  Future<void> _loadLocalCategories() async {
    try {
      final localCategories = await _dbHelper.getAllCategoriesObjects();
      if (localCategories.isNotEmpty) {
        _categories = localCategories;
        logDebug(
          'Loaded ${_categories.length} categories from local database',
          tag: 'CategoryProvider',
        );
      }
    } catch (e) {
      logError(
        'Failed to load local categories',
        tag: 'CategoryProvider',
        error: e,
      );
    }
  }

  Future<void> _createDefaultCategories(String userId) async {
    try {
      final defaults = getDefaultCategories();
      for (final cat in defaults) {
        await _firestore.collection('categories').add({
          'userId': userId,
          'name': cat.name,
          'icon': cat.icon,
          'color': cat.color,
          'type': cat.type,
          'budgetLimit': cat.budgetLimit,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      logDebug(
        'Created ${defaults.length} default categories in Firestore',
        tag: 'CategoryProvider',
      );
    } catch (e) {
      logError(
        'Failed to create default categories',
        tag: 'CategoryProvider',
        error: e,
      );
    }
  }

  Future<void> _migrateLocalToFirestore(String userId) async {
    try {
      final localCategories = await _dbHelper.getAllCategoriesObjects();
      for (final cat in localCategories) {
        await _firestore.collection('categories').add({
          'userId': userId,
          'name': cat.name,
          'icon': cat.icon,
          'color': cat.color,
          'type': cat.type,
          'budgetLimit': cat.budgetLimit,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      logDebug(
        'Successfully migrated ${localCategories.length} categories to Firestore',
        tag: 'CategoryProvider',
      );
    } catch (e) {
      logError(
        'Failed to migrate categories',
        tag: 'CategoryProvider',
        error: e,
      );
    }
  }

  Future<void> addCategory(Category category) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('categories').add({
        'userId': user.uid,
        'name': category.name,
        'icon': category.icon,
        'color': category.color,
        'type': category.type,
        'budgetLimit': category.budgetLimit,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logError('Failed to add category', tag: 'CategoryProvider', error: e);
      rethrow;
    }
  }

  Future<void> updateCategory(Category category) async {
    if (category.id == null) return;

    try {
      await _firestore
          .collection('categories')
          .doc(category.id.toString())
          .update({
            'name': category.name,
            'icon': category.icon,
            'color': category.color,
            'type': category.type,
            'budgetLimit': category.budgetLimit,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      logError('Failed to update category', tag: 'CategoryProvider', error: e);
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _firestore.collection('categories').doc(id).delete();
    } catch (e) {
      logError('Failed to delete category', tag: 'CategoryProvider', error: e);
      rethrow;
    }
  }

  Future<void> retryFetch() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _startCategoryListener(user);
    }
  }

  @override
  void dispose() {
    _categorySubscription?.cancel();
    _authStateSubscription?.cancel();
    _loadingTimeoutTimer?.cancel();
    super.dispose();
  }
}
