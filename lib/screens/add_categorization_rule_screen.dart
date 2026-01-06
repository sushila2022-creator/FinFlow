import 'package:flutter/material.dart';
import 'package:finflow/models/categorization_rule.dart';

class AddCategorizationRuleScreen extends StatefulWidget {
  final Function(CategorizationRule) onRuleAdded;

  const AddCategorizationRuleScreen({super.key, required this.onRuleAdded});

  @override
  AddCategorizationRuleScreenState createState() =>
      AddCategorizationRuleScreenState();
}

class AddCategorizationRuleScreenState
    extends State<AddCategorizationRuleScreen> {
  final _formKey = GlobalKey<FormState>();
  String _keyword = '';
  int _categoryId = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Categorization Rule'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Keyword'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a keyword';
                  }
                  return null;
                },
                onSaved: (value) {
                  _keyword = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Category ID'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category ID';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onSaved: (value) {
                  _categoryId = int.parse(value!);
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    widget.onRuleAdded(
                      CategorizationRule(
                        keyword: _keyword,
                        categoryId: _categoryId,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: Text('Add Rule'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
