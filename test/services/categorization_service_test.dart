import 'package:finflow/models/categorization_rule.dart';
import 'package:finflow/services/categorization_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategorizationService', () {
    late CategorizationService categorizationService;

    setUp(() {
      categorizationService = CategorizationService();
    });

    test('should return categoryId from rule if keyword matches', () async {
      final categoryId = await categorizationService.getCategoryIdFromDescription('bought a coffee');
      expect(categoryId, 1);
    });

    test('should return null if no rule matches', () async {
      final categoryId = await categorizationService.getCategoryIdFromDescription('some transaction');
      expect(categoryId, null);
    });

    test('should add a new rule and use it for categorization', () async {
      final newRule = CategorizationRule(keyword: 'new rule', categoryId: 10);
      categorizationService.addRule(newRule);

      final categoryId = await categorizationService.getCategoryIdFromDescription('this is a new rule');
      expect(categoryId, 10);
    });

    test('should return correct categoryId when multiple rules match', () async {
      final newRule1 = CategorizationRule(keyword: 'rule1', categoryId: 11);
      final newRule2 = CategorizationRule(keyword: 'rule2', categoryId: 12);
      categorizationService.addRule(newRule1);
      categorizationService.addRule(newRule2);

      final categoryId = await categorizationService.getCategoryIdFromDescription('this is rule1 and rule2');
      expect(categoryId, 11);
    });
  });
}
