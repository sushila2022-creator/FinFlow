import 'package:flutter/foundation.dart';

/// IAP REMOVED - ALL FEATURES ARE FREE
enum IAPStatus {
  available,
  unavailable,
  loading,
  purchased,
  restored,
  failed,
  pending,
}

typedef IAPStatusCallback = void Function(IAPStatus status, String? message);

/// In-App Purchase Service Disabled - App is 100% Free
class IAPService extends ChangeNotifier {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  // All methods do nothing - purchases are completely disabled
  Future<bool> initialize() async {
    return false;
  }

  Future<List> fetchProducts() async {
    return [];
  }

  Future<bool> purchaseProduct(dynamic productDetails) async {
    return false;
  }

  Future<bool> restorePurchases() async {
    return false;
  }

  Future<bool> hasActiveSubscription() async {
    return true;
  }

  void setOnStatusChanged(IAPStatusCallback callback) {
    // No status changes
  }

  // Dummy getters
  bool get isAvailable => false;
  bool get isInitialized => false;
  List get products => [];
  bool get isLoadingProducts => false;
  IAPStatus get status => IAPStatus.unavailable;
  static const String premiumMonthlyProductId = '';
  static const String premiumYearlyProductId = '';

  dynamic getProductById(String id) {
    return null;
  }
}
