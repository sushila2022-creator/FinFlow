class SavingsGoal {
  final int? id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;

  SavingsGoal({
    this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.targetDate,
  });

  // Factory constructor to create a SavingsGoal from a Map (e.g., from DB)
  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id']?.toInt(),
      name: map['name'] as String,
      targetAmount: map['targetAmount'] as double,
      currentAmount: map['currentAmount'] as double,
      targetDate: DateTime.fromMillisecondsSinceEpoch(map['targetDate'] as int),
    );
  }

  // Method to convert a SavingsGoal to a Map (e.g., for DB insertion)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate.millisecondsSinceEpoch,
    };
  }
}
