class Category {
  int? id;
  String name;
  String icon;
  String color;
  String type; // 'income' or 'expense'
  double budgetLimit;

  Category({this.id, required this.name, required this.icon, required this.color, required this.type, this.budgetLimit = 0.0});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
      'budget_limit': budgetLimit,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      color: map['color'],
      type: map['type'],
      budgetLimit: (map['budget_limit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
