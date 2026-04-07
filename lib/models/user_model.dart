import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final bool isPremium;
  final DateTime? premiumExpiry;
  final String? purchaseToken;
  final DateTime? premiumGrantedAt;
  final String? premiumSource;
  final String? productId;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.isPremium = false,
    this.premiumExpiry,
    this.purchaseToken,
    this.premiumGrantedAt,
    this.premiumSource,
    this.productId,
  });

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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'isPremium': isPremium,
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
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiry: premiumExpiry ?? this.premiumExpiry,
      purchaseToken: purchaseToken ?? this.purchaseToken,
      premiumGrantedAt: premiumGrantedAt ?? this.premiumGrantedAt,
      premiumSource: premiumSource ?? this.premiumSource,
      productId: productId ?? this.productId,
    );
  }
}
