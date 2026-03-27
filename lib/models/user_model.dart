import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final bool isPremium;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.isPremium = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      isPremium: map['isPremium'] ?? false,
    );
  }

  factory UserModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;
    return UserModel(
      uid: snapshot.id,
      name: data?['name'] ?? '',
      email: data?['email'] ?? '',
      isPremium: data?['isPremium'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'name': name, 'email': email, 'isPremium': isPremium};
  }
}
