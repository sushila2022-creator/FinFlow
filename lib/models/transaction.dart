class Transaction {
  int? id;
  String description;
  double amount;
  String currencyCode;
  DateTime date;
  int categoryId;
  String categoryName;
  String type; // 'income' or 'expense'
  int accountId;
  String? notes;
  bool isRecurring;
  String? recurrenceFrequency;
  DateTime? recurrenceEndDate;
  String? attachmentPath;

  Transaction({
    this.id,
    required this.description,
    required this.categoryName,
    required this.amount,
    required this.currencyCode,
    required this.date,
    required this.categoryId,
    required this.type,
    required this.accountId,
    this.notes,
    this.isRecurring = false,
    this.recurrenceFrequency,
    this.recurrenceEndDate,
    this.attachmentPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'currencyCode': currencyCode,
      'date': date.toIso8601String(),
      'categoryId': categoryId,
      'categoryName': categoryName,
      'type': type,
      'accountId': accountId,
      'notes': notes,
      'isRecurring': isRecurring ? 1 : 0,
      'recurrenceFrequency': recurrenceFrequency,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'attachmentPath': attachmentPath,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      description: map['description'],
      amount: map['amount'],
      currencyCode: map['currencyCode'],
      date: DateTime.parse(map['date']),
      categoryId: map['categoryId'],
      categoryName: map['categoryName'],
      type: map['type'] ?? 'income', // Default to income for backward compatibility
      accountId: map['accountId'],
      notes: map['notes'],
      isRecurring: map['isRecurring'] == 1,
      recurrenceFrequency: map['recurrenceFrequency'],
      recurrenceEndDate: map['recurrenceEndDate'] != null
          ? DateTime.parse(map['recurrenceEndDate'])
          : null,
      attachmentPath: map['attachmentPath'],
    );
  }
}
