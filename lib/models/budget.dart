class Budget {
  final int? id;
  final String category;
  final double amount;
  final DateTime startDate; // Start date of the budget period (e.g., start of the month)
  final DateTime endDate;   // End date of the budget period (e.g., end of the month)

  Budget({
    this.id,
    required this.category,
    required this.amount,
    required this.startDate,
    required this.endDate,
  });

  // Factory constructor to create a Budget from a Map (e.g., from DB)
  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id']?.toInt(),
      category: map['category'] as String,
      amount: map['budgetLimit'] as double,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate'] as int),
    );
  }

  // Method to convert a Budget to a Map (e.g., for DB insertion)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'budgetLimit': amount,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
    };
  }
}
