import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finflow/utils/database_helper.dart'; // Corrected import path
import 'package:finflow/models/budget.dart'; // Corrected import path

class AddBudgetScreen extends StatefulWidget {
  const AddBudgetScreen({super.key});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedStartDate = DateTime.now();
  DateTime _selectedEndDate = DateTime.now();

  // Example categories, should ideally be fetched from a common source or defined elsewhere
  final List<String> _categories = [
    'Food', 'Transport', 'Shopping', 'Utilities', 'Entertainment', 'Health', 'Other'
  ];

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedStartDate) {
      setState(() {
        _selectedStartDate = picked;
        // Ensure end date is not before start date
        if (_selectedEndDate.isBefore(_selectedStartDate)) {
          _selectedEndDate = _selectedStartDate;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: _selectedStartDate, // End date cannot be before start date
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedEndDate) {
      setState(() {
        _selectedEndDate = picked;
      });
    }
  }

  Future<void> _saveBudget() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text);
      if (amount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid amount')),
        );
        return;
      }

      final budget = Budget(
        category: _categoryController.text,
        amount: amount,
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
      );

      try {
        await DatabaseHelper.instance.insertBudget(budget.toMap());
        // Check if the widget is still mounted before showing snackbar and popping
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget saved successfully!')),
          );
          Navigator.of(context).pop(); // Close the screen after saving
        }
      } catch (e) {
        // Also check mounted here for the catch block
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save budget: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Budget'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: _categoryController.text.isEmpty ? null : _categoryController.text,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _categoryController.text = newValue;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount Field
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Budget Amount',
                  prefixText: '₹ ', // Currency symbol
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a budget amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Start Date Field
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(
                        text: DateFormat('yyyy-MM-dd').format(_selectedStartDate),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectStartDate(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // End Date Field
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(
                        text: DateFormat('yyyy-MM-dd').format(_selectedEndDate),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectEndDate(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _saveBudget,
                child: const Text('Save Budget'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
