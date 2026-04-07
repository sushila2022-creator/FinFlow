import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:finflow/providers/user_provider.dart';
import 'package:finflow/utils/debug_logger.dart';

/// Enumeration for IAP connection and purchase states
enum IAPStatus {
  available,
  unavailable,
  loading,
  purchased,
  restored,
  failed,
  pending,
}

/// Callback type for IAP status updates
typedef IAPStatusCallback = void Function(IAPStatus status, String? message);

/// Response from the verifyPurchase Cloud Function
class VerifyPurchaseResponse {
  final bool success;
  final String message;
  final String? premiumExpiry;
  final String? productId;

  VerifyPurchaseResponse({
    required this.success,
    required this.message,
    this.premiumExpiry,
    this.productId,
  });

  factory VerifyPurchaseResponse.fromMap(Map<String, dynamic> data) {
    return VerifyPurchaseResponse(
      success: data['success'] as bool? ?? false,
      message: data['message'] as String? ?? 'Unknown response',
      premiumExpiry: data['premiumExpiry'] as String?,
      productId: data['productId'] as String?,
    );
  }
}

/// Service class for handling Google Play In-App Purchases
///
/// This service manages:
/// - Connection to Google Play Billing
/// - Product/subscription fetching
/// - Purchase flow handling
/// - Purchase verification via Cloud Functions (secure server-side verification)
/// - Restore purchases
class IAPService extends ChangeNotifier {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  bool _isAvailable = false;
  bool _isConnecting = false;
  bool _isInitialized = false;
  String? _connectionError;

  List<ProductDetails> _products = [];
  bool _isLoadingProducts = false;
  String? _productError;

  PurchaseDetails? _currentPurchase;
  IAPStatus _status = IAPStatus.loading;
  String? _statusMessage;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  IAPStatusCallback? _onStatusChanged;

  // Product IDs - configure these to match your Google Play Console setup
  static const String premiumMonthlyProductId = 'finflow_premium_monthly';
  static const String premiumYearlyProductId = 'finflow_premium_yearly';

  // For testing, you can use Google's test product IDs
  // static const String premiumMonthlyProductId = 'android.test.purchased';

  // Getters
  bool get isAvailable => _isAvailable;
  bool get isConnecting => _isConnecting;
  bool get isInitialized => _isInitialized;
  String? get connectionError => _connectionError;
  List<ProductDetails> get products => _products;
  bool get isLoadingProducts => _isLoadingProducts;
  String? get productError => _productError;
  PurchaseDetails? get currentPurchase => _currentPurchase;
  IAPStatus get status => _status;
  String? get statusMessage => _statusMessage;

  /// Initialize the IAP service and connect to Google Play
  Future<bool> initialize() async {
    if (_isInitialized) return _isAvailable;

    _isConnecting = true;
    _status = IAPStatus.loading;
    _notifyStatus('Connecting to Google Play...');
    notifyListeners();

    try {
      // Check if In-App Purchases are available on this device
      final bool isAvailable = await _inAppPurchase.isAvailable();
      _isAvailable = isAvailable;
      _connectionError = isAvailable
          ? null
          : 'In-App Purchases not available on this device';

      if (isAvailable) {
        // Set up the purchase stream listener
        _setupPurchaseStream();

        _status = IAPStatus.available;
        _notifyStatus('Ready to purchase');
        logDebug('IAP Service: Connected successfully');
      } else {
        _status = IAPStatus.unavailable;
        _notifyStatus('In-App Purchases not available');
        logDebug('IAP Service: Not available');
      }
    } catch (e) {
      _isAvailable = false;
      _connectionError = e.toString();
      _status = IAPStatus.unavailable;
      _notifyStatus('Connection failed: ${e.toString()}');
      logError('IAP Service: Connection error', error: e);
    } finally {
      _isConnecting = false;
      _isInitialized = true;
      notifyListeners();
    }

    return _isAvailable;
  }

  /// Set up the purchase stream listener
  void _setupPurchaseStream() {
    _subscription?.cancel();
    _subscription = _inAppPurchase.purchaseStream.listen(
      (List<PurchaseDetails> purchaseDetailsList) {
        _handlePurchaseUpdates(purchaseDetailsList);
      },
      onDone: () {
        _subscription?.cancel();
      },
      onError: (Object error) {
        logError('IAP Service: Purchase stream error', error: error);
        _status = IAPStatus.failed;
        _notifyStatus('Purchase error: ${error.toString()}');
        notifyListeners();
      },
    );
  }

  /// Handle purchase updates from the stream
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      _currentPurchase = purchaseDetails;

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _status = IAPStatus.pending;
          _notifyStatus('Purchase pending...');
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _status = purchaseDetails.status == PurchaseStatus.purchased
              ? IAPStatus.purchased
              : IAPStatus.restored;
          _notifyStatus(
            purchaseDetails.status == PurchaseStatus.purchased
                ? 'Purchase successful!'
                : 'Purchase restored!',
          );

          // Verify and process the purchase using Cloud Functions
          _verifyAndProcessPurchase(purchaseDetails);
          break;

        case PurchaseStatus.error:
          _status = IAPStatus.failed;
          final String errorMessage =
              purchaseDetails.error?.message ?? 'Purchase failed';
          _notifyStatus(errorMessage);

          // Handle pending purchases that failed
          if (purchaseDetails.pendingCompletePurchase) {
            _inAppPurchase.completePurchase(purchaseDetails);
          }
          break;

        case PurchaseStatus.canceled:
          _status = IAPStatus.failed;
          _notifyStatus('Purchase cancelled');
          if (purchaseDetails.pendingCompletePurchase) {
            _inAppPurchase.completePurchase(purchaseDetails);
          }
          break;
      }

      notifyListeners();
    }
  }

  /// Verify purchase using Cloud Functions and process
  Future<void> _verifyAndProcessPurchase(
    PurchaseDetails purchaseDetails,
  ) async {
    try {
      // Verify purchase with Cloud Functions (secure server-side verification)
      final bool isVerified = await _verifyPurchaseWithCloudFunction(
        purchaseDetails,
      );

      if (isVerified) {
        // Premium status has been updated by the Cloud Function
        // Just need to complete the purchase
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }

        // Refresh user data in UserProvider
        try {
          final userProvider = UserProvider();
          await userProvider.refreshUser();
        } catch (e) {
          logError('IAP Service: Could not refresh user provider', error: e);
        }

        logDebug('Premium access granted to user ${_auth.currentUser?.uid}');
      } else {
        logDebug('IAP Service: Purchase verification failed');
        _status = IAPStatus.failed;
        _notifyStatus('Purchase verification failed');

        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    } on FirebaseFunctionsException catch (e) {
      logError('IAP Service: Cloud Function error: ${e.code} - ${e.message}');
      _status = IAPStatus.failed;
      _notifyStatus('Verification failed: ${e.message}');

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    } catch (e) {
      logError('IAP Service: Error processing purchase', error: e);
      _status = IAPStatus.failed;
      _notifyStatus('Error processing purchase: ${e.toString()}');

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }

    notifyListeners();
  }

  /// Verify purchase with Cloud Functions (secure server-side verification)
  ///
  /// This calls the verifyPurchase Cloud Function which:
  /// 1. Validates the purchase token with Google Play Developer API
  /// 2. Updates the user's Firestore document with premium status
  /// 3. Returns the verification result
  Future<bool> _verifyPurchaseWithCloudFunction(
    PurchaseDetails purchaseDetails,
  ) async {
    // Check if we have the necessary verification data
    if (purchaseDetails.verificationData.serverVerificationData.isEmpty) {
      logDebug('IAP Service: No verification data available');
      return false;
    }

    // Check if the purchase is for a valid product
    final bool isValidProduct = [
      premiumMonthlyProductId,
      premiumYearlyProductId,
    ].contains(purchaseDetails.productID);

    if (!isValidProduct) {
      logDebug('IAP Service: Invalid product ID: ${purchaseDetails.productID}');
      return false;
    }

    try {
      // Call the Cloud Function to verify the purchase
      final HttpsCallable callable = _functions.httpsCallable('verifyPurchase');

      final result = await callable.call({
        'purchaseToken':
            purchaseDetails.verificationData.serverVerificationData,
        'productId': purchaseDetails.productID,
      });

      if (result.data != null) {
        final response = VerifyPurchaseResponse.fromMap(
          result.data as Map<String, dynamic>,
        );

        if (response.success) {
          logDebug(
            'Purchase verified successfully. Premium expiry: ${response.premiumExpiry}',
          );
          return true;
        } else {
          logDebug('Purchase verification failed: ${response.message}');
          return false;
        }
      }

      return false;
    } catch (e) {
      logError('Error calling verifyPurchase Cloud Function', error: e);
      rethrow;
    }
  }

  /// Fetch available products from Google Play
  Future<List<ProductDetails>> fetchProducts() async {
    if (!_isAvailable) {
      _productError = 'IAP not available';
      notifyListeners();
      return [];
    }

    _isLoadingProducts = true;
    _productError = null;
    notifyListeners();

    try {
      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(<String>{
            premiumMonthlyProductId,
            premiumYearlyProductId,
          });

      if (response.error != null) {
        _productError = response.error!.message;
        logError('Error fetching products: $_productError');
      }

      _products = response.productDetails.toList();

      // Sort products - monthly first, then yearly
      _products.sort((a, b) {
        if (a.id == premiumMonthlyProductId) return -1;
        if (b.id == premiumMonthlyProductId) return 1;
        return 0;
      });

      logDebug('Fetched ${_products.length} products');
      return _products;
    } catch (e) {
      _productError = e.toString();
      logError('Exception fetching products', error: e);
      return [];
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  /// Initiate a purchase for a product
  Future<bool> purchaseProduct(ProductDetails productDetails) async {
    if (!_isAvailable) {
      _notifyStatus('IAP not available');
      return false;
    }

    _status = IAPStatus.loading;
    _notifyStatus('Starting purchase...');
    notifyListeners();

    try {
      // Create a purchase parameter
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
        applicationUserName: _auth.currentUser?.uid,
      );

      // Start the purchase flow for non-consumable (subscriptions are non-consumable)
      final bool purchaseStarted = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!purchaseStarted) {
        _status = IAPStatus.failed;
        _notifyStatus('Could not start purchase flow');
        notifyListeners();
        return false;
      }

      return true;
    } catch (e) {
      _status = IAPStatus.failed;
      _notifyStatus('Purchase error: ${e.toString()}');
      notifyListeners();
      return false;
    }
  }

  /// Restore purchases (for subscriptions, this queries past purchases)
  Future<bool> restorePurchases() async {
    if (!_isAvailable) {
      _notifyStatus('IAP not available');
      return false;
    }

    _status = IAPStatus.loading;
    _notifyStatus('Checking for existing purchases...');
    notifyListeners();

    try {
      // restorePurchases will trigger purchase updates for past purchases
      // On Android, this will show a dialog to the user
      await _inAppPurchase.restorePurchases();
      return true;
    } catch (e) {
      _status = IAPStatus.failed;
      _notifyStatus('Restore failed: ${e.toString()}');
      notifyListeners();
      return false;
    }
  }

  /// Check if user has an active subscription by checking past purchases
  /// Note: This requires restorePurchases to be called first to get updates
  Future<bool> hasActiveSubscription() async {
    // Check local state first
    if (_status == IAPStatus.purchased || _status == IAPStatus.restored) {
      return true;
    }

    // We can't directly query past purchases in the new API
    // Instead, we trigger restorePurchases and wait for the stream update
    // For simplicity, we'll just return false and let the UI handle restore
    return false;
  }

  /// Set callback for status changes
  void setOnStatusChanged(IAPStatusCallback callback) {
    _onStatusChanged = callback;
  }

  void _notifyStatus(String message) {
    _statusMessage = message;
    _onStatusChanged?.call(_status, message);
  }

  /// Dispose of resources
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Reset the service state
  void reset() {
    _status = IAPStatus.loading;
    _statusMessage = null;
    _currentPurchase = null;
    notifyListeners();
  }

  /// Get product by ID
  ProductDetails? getProductById(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }
}
