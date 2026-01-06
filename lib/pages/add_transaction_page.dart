import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  AddTransactionPageState createState() => AddTransactionPageState();
}

class AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  List<Category> _categories = [];
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _categories = [
      Category(id: 1, name: 'Food', icon: 'fastfood', color: 'FF5722', type: 'expense'),
      Category(id: 2, name: 'Salary', icon: 'attach_money', color: '4CAF50', type: 'income'),
      Category(id: 3, name: 'Housing', icon: 'home', color: '2196F3', type: 'expense'),
      Category(id: 4, name: 'Bills', icon: 'receipt', color: '9C27B0', type: 'expense'),
      Category(id: 5, name: 'Travel', icon: 'directions_bus', color: 'FF9800', type: 'expense'),
      Category(id: 6, name: 'Shopping', icon: 'shopping_bag', color: 'E91E63', type: 'expense'),
      Category(id: 7, name: 'Misc', icon: 'category', color: '795548', type: 'expense'),
    ];
    if (_categories.isNotEmpty) {
      _selectedCategory = _categories.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTransaction,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
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
              DropdownButtonFormField<Category>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              ListTile(
                title: Text('Date: ${DateFormat.yMd().format(_selectedDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              const SizedBox(height: 20),
              _imageFile == null
                  ? TextButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Add Attachment'),
                      onPressed: _pickImage,
                    )
                  : Image.file(File(_imageFile!.path)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? selectedImage = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = selectedImage;
    });
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      String? attachmentPath;
      if (_imageFile != null) {
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String fileName = path.basename(_imageFile!.path);
        attachmentPath = path.join(appDir.path, fileName);
        await _imageFile!.saveTo(attachmentPath);
      }

      // Check if widget is still mounted before using context
      if (!mounted) return;

      // Determine transaction type based on category
      final String transactionType = _selectedCategory!.id == 2 ? 'income' : 'expense';
      
      final newTransaction = Transaction(
        description: _titleController.text,
        amount: double.parse(_amountController.text),
        currencyCode: 'USD',
        date: _selectedDate,
        categoryId: _selectedCategory!.id!,
        categoryName: _selectedCategory!.name,
        type: transactionType,
        accountId: 1, // Default account
        notes: _notesController.text,
        attachmentPath: attachmentPath,
      );
      Provider.of<TransactionProvider>(context, listen: false)
          .addTransaction(newTransaction);
      Navigator.pop(context);
    }
  }
}
