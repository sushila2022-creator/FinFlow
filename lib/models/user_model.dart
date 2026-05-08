import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finflow/utils/app_config.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final bool _isPremium;
  final DateTime? premiumExpiry;
  final String? purchaseToken;
  final DateTime? premiumGrantedAt;
  final String? premiumSource;
  final String? productId;
  final int smsTransactionCount;

  /// Returns true if the user is a premium member or if testing mode is enabled.
  bool get isPremium => _isPremium || AppConfig.isTestingMode;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    bool isPremium = false,
    this.premiumExpiry,
    this.purchaseToken,
    this.premiumGrantedAt,
    this.premiumSource,
    this.productId,
    this.smsTransactionCount = 0,
  }) : _isPremium = isPremium;

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      isPremium: map['isPremium'] ?? false,
      premiumExpiry: map['premiumExpiry'] is Timestamp
          ? (map['premiumExpiry'] as Timestamp).toDate()
          : (map['premiumExpiry'] is String
                ? DateTime.tryParse(map['premiumExpiry'])
                : null),
      purchaseToken: map['purchaseToken'],
      premiumGrantedAt: map['premiumGrantedAt'] is Timestamp
          ? (map['premiumGrantedAt'] as Timestamp).toDate()
          : null,
      premiumSource: map['premiumSource'],
      productId: map['productId'],
      smsTransactionCount: map['smsTransactionCount'] ?? 0,
    );
  }

  factory UserModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;
    return UserModel(
      uid: snapshot.id,
      name: data?['name'] ?? '',
      email: data?['email'] ?? '',
      isPremium: data?['isPremium'] ?? false,
      premiumExpiry: data?['premiumExpiry'] is Timestamp
          ? (data!['premiumExpiry'] as Timestamp).toDate()
          : (data != null && data['premiumExpiry'] is String
                ? DateTime.tryParse(data['premiumExpiry'])
                : null),
      purchaseToken: data?['purchaseToken'],
      premiumGrantedAt: data?['premiumGrantedAt'] is Timestamp
          ? (data!['premiumGrantedAt'] as Timestamp).toDate()
          : null,
      premiumSource: data?['premiumSource'],
      productId: data?['productId'],
      smsTransactionCount: data?['smsTransactionCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'isPremium': _isPremium,
      'smsTransactionCount': smsTransactionCount,
      if (premiumExpiry != null)
        'premiumExpiry': premiumExpiry!.toIso8601String(),
      if (purchaseToken != null) 'purchaseToken': purchaseToken,
      if (premiumGrantedAt != null)
        'premiumGrantedAt': premiumGrantedAt!.toIso8601String(),
      if (premiumSource != null) 'premiumSource': premiumSource,
      if (productId != null) 'productId': productId,
    };
  }

  /// Check if the premium subscription is currently active
  bool get isPremiumActive =>
      isPremium &&
      (premiumExpiry == null || premiumExpiry!.isAfter(DateTime.now()));

  /// Get remaining days of premium subscription
  int get premiumRemainingDays {
    if (!isPremiumActive || premiumExpiry == null) return 0;
    return premiumExpiry!.difference(DateTime.now()).inDays;
  }

  /// Get remaining SMS transactions for free users
  int get remainingSmsTransactions {
    if (isPremiumActive) return -1; // Unlimited
    return (15 - smsTransactionCount).clamp(0, 15);
  }

  /// Check if user has reached SMS limit
  bool get hasReachedSmsLimit {
    if (isPremiumActive) return false;
    return smsTransactionCount >= 15;
  }

  /// Check if user can access AI insights
  bool get canUseAiInsights => isPremiumActive;

  /// Check if user can access advanced reports
  bool get canUseAdvancedReports => isPremiumActive;

  /// Check if user has secure backup
  bool get hasSecureBackup => isPremiumActive;

  /// Check if user should see ads
  bool get shouldShowAds => !isPremiumActive;

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    bool? isPremium,
    DateTime? premiumExpiry,
    String? purchaseToken,
    DateTime? premiumGrantedAt,
    String? premiumSource,
    String? productId,
    int? smsTransactionCount,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      isPremium: isPremium ?? _isPremium,
      premiumExpiry: premiumExpiry ?? this.premiumExpiry,
      purchaseToken: purchaseToken ?? this.purchaseToken,
      premiumGrantedAt: premiumGrantedAt ?? this.premiumGrantedAt,
      premiumSource: premiumSource ?? this.premiumSource,
      productId: productId ?? this.productId,
      smsTransactionCount: smsTransactionCount ?? this.smsTransactionCount,
    );
  }
}
