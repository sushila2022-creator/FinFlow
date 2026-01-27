import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Transaction {
  final String id;
  final String title;
  final String description;
  final double amount;
  final String currencyCode;
  final DateTime date;
  final String category;
  final int categoryId;
  final bool isIncome;
  final int accountId;
  final String? notes;
  final bool isRecurring;
  final String? recurrenceFrequency;
  final DateTime? recurrenceEndDate;
  final String? attachmentPath;

  Transaction({
    String? id,
    this.title = '',
    required this.description,
    required this.amount,
    required this.currencyCode,
    required this.date,
    required this.category,
    required this.categoryId,
    required this.isIncome,
    required this.accountId,
    this.notes,
    this.isRecurring = false,
    this.recurrenceFrequency,
    this.recurrenceEndDate,
    this.attachmentPath,
    String? categoryName, // Legacy parameter alias for category
    String? type, // Legacy parameter alias for isIncome
  }) : id = id ?? const Uuid().v4();

  // Legacy constructor for backward compatibility with old code
  Transaction.legacy({
    String? id,
    this.title = '',
    required this.description,
    required String categoryName,
    required this.amount,
    required this.currencyCode,
    required this.date,
    required this.categoryId,
    required String type,
    required this.accountId,
    this.notes,
    this.isRecurring = false,
    this.recurrenceFrequency,
    this.recurrenceEndDate,
    this.attachmentPath,
  }) : id = id ?? const Uuid().v4(),
       category = categoryName,
       isIncome = type == 'income';

  // Getters for compatibility
  String get type => isIncome ? 'income' : 'expense';
  String get categoryName => category;

  // toJson for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'currencyCode': currencyCode,
      'date': date.toIso8601String(),
      'category': category,
      'categoryId': categoryId,
      'isIncome': isIncome,
      'accountId': accountId,
      'notes': notes,
      'isRecurring': isRecurring,
      'recurrenceFrequency': recurrenceFrequency,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'attachmentPath': attachmentPath,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // fromJson for Firestore - handles both Firestore Timestamp and String dates
  factory Transaction.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();

      // Handle Firestore Timestamp
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      }

      // Handle String (ISO8601)
      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          return DateTime.now();
        }
      }

      // Handle DateTime directly
      if (dateValue is DateTime) {
        return dateValue;
      }

      return DateTime.now();
    }

    return Transaction(
      id: json['id'] ?? '',
      title: json['title'] ?? json['description'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      currencyCode: json['currencyCode'] ?? 'INR',
      date: parseDate(json['date']),
      category: json['category'] ?? 'Misc',
      categoryId: json['categoryId'] ?? 0,
      isIncome: json['isIncome'] ?? false,
      accountId: json['accountId'] ?? 1,
      notes: json['notes'],
      isRecurring: json['isRecurring'] ?? false,
      recurrenceFrequency: json['recurrenceFrequency'],
      recurrenceEndDate: parseDate(json['recurrenceEndDate']),
      attachmentPath: json['attachmentPath'],
    );
  }

  // toMap for local database compatibility
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'currencyCode': currencyCode,
      'date': date.toIso8601String(),
      'category': category,
      'categoryId': categoryId,
      'isIncome': isIncome ? 1 : 0,
      'accountId': accountId,
      'notes': notes,
      'isRecurring': isRecurring ? 1 : 0,
      'recurrenceFrequency': recurrenceFrequency,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'attachmentPath': attachmentPath,
    };
  }

  // fromMap for local database compatibility
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] ?? '',
      title: map['title'] ?? map['description'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      currencyCode: map['currencyCode'] ?? 'INR',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      category: map['category'] ?? map['categoryName'] ?? 'Misc',
      categoryId: map['categoryId'] ?? 0,
      isIncome:
          map['isIncome'] == 1 ||
          map['isIncome'] == true ||
          (map['type'] ?? '') == 'income',
      accountId: map['accountId'] ?? 1,
      notes: map['notes'],
      isRecurring: map['isRecurring'] == 1,
      recurrenceFrequency: map['recurrenceFrequency'],
      recurrenceEndDate: map['recurrenceEndDate'] != null
          ? DateTime.parse(map['recurrenceEndDate'])
          : null,
      attachmentPath: map['attachmentPath'],
    );
  }

  Transaction copyWith({
    String? id,
    String? description,
    double? amount,
    String? currencyCode,
    DateTime? date,
    String? category,
    int? categoryId,
    bool? isIncome,
    int? accountId,
    String? notes,
    bool? isRecurring,
    String? recurrenceFrequency,
    DateTime? recurrenceEndDate,
    String? attachmentPath,
  }) {
    return Transaction(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      date: date ?? this.date,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      isIncome: isIncome ?? this.isIncome,
      accountId: accountId ?? this.accountId,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceFrequency: recurrenceFrequency ?? this.recurrenceFrequency,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      attachmentPath: attachmentPath ?? this.attachmentPath,
    );
  }
}
