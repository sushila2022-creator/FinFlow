import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:finflow/utils/database_helper.dart';
import 'package:finflow/models/transaction.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  // Use a local key for the form, as GlobalKey is not needed here and can cause issues.
  // If a GlobalKey is truly needed for external access, it should be managed at a higher level.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(); // Added title controller
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedTransactionType = 'Expense'; // Default to Expense

  final List<String> _categories = [
    'Food', 'Transport', 'Shopping', 'Utilities', 'Entertainment', 'Health', 'Other'
  ]; // Example categories

  @override
  void dispose() {
    _titleController.dispose(); // Dispose title controller
    _amountController.dispose();
    _categoryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text; // Get title from controller
      final amount = double.tryParse(_amountController.text);
      if (amount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid amount')),
        );
        return;
      }

      final transaction = Transaction(
        description: title,
        amount: _selectedTransactionType == 'Expense' ? -amount : amount,
        currencyCode: 'USD',
        date: _selectedDate,
        categoryId: 1,
        categoryName: _categoryController.text,
        type: _selectedTransactionType.toLowerCase(),
        accountId: 1,
        notes: _noteController.text.isEmpty ? null : _noteController.text,
      );

      try {
        await DatabaseHelper.instance.insertTransaction(transaction.toMap());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction saved successfully!')),
          );
        }
        // Check if the widget is still mounted before navigating
        if (mounted) {
          Navigator.of(context).pop(); // Close the screen after saving
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save transaction: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView( // Use ListView for scrollable content
            children: [
              // Title Field (Added)
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Transaction Type Toggle
              SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(value: 'Expense', label: Text('Expense'), icon: Icon(Icons.arrow_downward)),
                  ButtonSegment<String>(value: 'Income', label: Text('Income'), icon: Icon(Icons.arrow_upward)),
                ],
                selected: <String>{_selectedTransactionType},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedTransactionType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Amount Field
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(_selectedTransactionType == 'Expense' ? Icons.arrow_downward : Icons.arrow_upward),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Field
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

              // Date Field
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(
                        text: DateFormat('yyyy-MM-dd').format(_selectedDate),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Note Field
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _saveTransaction,
                child: const Text('Save Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
