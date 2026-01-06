import 'package:finflow/models/categorization_rule.dart';

class CategorizationService {
  final List<CategorizationRule> _rules = [
    CategorizationRule(keyword: 'coffee', categoryId: 1),
    CategorizationRule(keyword: 'starbucks', categoryId: 1),
    CategorizationRule(keyword: 'salary', categoryId: 2),
    CategorizationRule(keyword: 'rent', categoryId: 3),
    CategorizationRule(keyword: 'electricity', categoryId: 4),
    CategorizationRule(keyword: 'groceries', categoryId: 1),
  ];

  List<CategorizationRule> getRules() {
    return _rules;
  }

  void addRule(CategorizationRule rule) {
    _rules.insert(0, rule);
  }

  Future<int?> getCategoryIdFromDescription(String description) async {
    final lowerCaseDescription = description.toLowerCase();
    for (final rule in _rules) {
      if (lowerCaseDescription.contains(rule.keyword.toLowerCase())) {
        return rule.categoryId;
      }
    }
    return null;
  }
}
