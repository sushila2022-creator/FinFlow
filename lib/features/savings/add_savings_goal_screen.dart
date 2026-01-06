import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finflow/utils/database_helper.dart'; // Corrected import path
import 'package:finflow/models/savings_goal.dart'; // Corrected import path

class AddSavingsGoalScreen extends StatefulWidget {
  const AddSavingsGoalScreen({super.key});

  @override
  State<AddSavingsGoalScreen> createState() => _AddSavingsGoalScreenState();
}

class _AddSavingsGoalScreenState extends State<AddSavingsGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  DateTime _selectedTargetDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectTargetDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTargetDate,
      firstDate: DateTime.now(), // Target date should be in the future
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedTargetDate) {
      setState(() {
        _selectedTargetDate = picked;
      });
    }
  }

  Future<void> _saveSavingsGoal() async {
    if (_formKey.currentState!.validate()) {
      final targetAmount = double.tryParse(_targetAmountController.text);
      if (targetAmount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid target amount')),
        );
        return;
      }

      final savingsGoal = SavingsGoal(
        name: _nameController.text,
        targetAmount: targetAmount,
        targetDate: _selectedTargetDate,
      );

      try {
        // Capture context before the async gap
        final BuildContext dialogContext = context;
        await DatabaseHelper.instance.insertSavingsGoal(savingsGoal.toMap());
        // Guard against using context after the widget may have been disposed
        // Check if the widget is still mounted
        if (dialogContext.mounted) {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            const SnackBar(content: Text('Savings goal saved successfully!')),
          );
          Navigator.of(dialogContext).pop(); // Close the screen after saving
        }
      } catch (e) {
        // Guard against using context after the widget may have been disposed
        // Check if the widget is still mounted AND if the context is still valid
        // The 'mounted' property of the State object should be checked before accessing context.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save savings goal: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Savings Goal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Goal Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a goal name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Target Amount Field
              TextFormField(
                controller: _targetAmountController,
                decoration: const InputDecoration(
                  labelText: 'Target Amount',
                  prefixText: '₹ ', // Currency symbol
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a target amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Target Date Field
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Target Date',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(
                        text: DateFormat('yyyy-MM-dd').format(_selectedTargetDate),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectTargetDate(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _saveSavingsGoal,
                child: const Text('Save Goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
