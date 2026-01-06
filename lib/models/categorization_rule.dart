class CategorizationRule {
  int? id;
  String keyword;
  int categoryId;

  CategorizationRule({
    this.id,
    required this.keyword,
    required this.categoryId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'keyword': keyword,
      'categoryId': categoryId,
    };
  }

  factory CategorizationRule.fromMap(Map<String, dynamic> map) {
    return CategorizationRule(
      id: map['id'],
      keyword: map['keyword'],
      categoryId: map['categoryId'],
    );
  }
}
