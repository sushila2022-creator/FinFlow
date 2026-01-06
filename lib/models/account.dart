class Account {
  int? id;
  String name;
  double balance;
  String currencyCode;

  Account({
    this.id,
    required this.name,
    required this.balance,
    required this.currencyCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'currencyCode': currencyCode,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      balance: map['balance'],
      currencyCode: map['currencyCode'],
    );
  }
}
