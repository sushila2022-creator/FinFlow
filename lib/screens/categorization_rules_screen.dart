import 'package:flutter/material.dart';
import 'package:finflow/services/categorization_service.dart';
import 'add_categorization_rule_screen.dart';

class CategorizationRulesScreen extends StatefulWidget {
  const CategorizationRulesScreen({super.key});
  @override
  CategorizationRulesScreenState createState() =>
      CategorizationRulesScreenState();
}

class CategorizationRulesScreenState extends State<CategorizationRulesScreen> {
  final CategorizationService _categorizationService = CategorizationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Categorization Rules'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddCategorizationRuleScreen(
                    onRuleAdded: (rule) {
                      _categorizationService.addRule(rule);
                      setState(() {});
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _categorizationService.getRules().length,
        itemBuilder: (context, index) {
          final rule = _categorizationService.getRules()[index];
          return ListTile(
            title: Text(rule.keyword),
            subtitle: Text('Category ID: ${rule.categoryId}'),
          );
        },
      ),
    );
  }
}
