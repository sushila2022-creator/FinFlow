import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/database_helper.dart';

class AddTransactionScreen extends StatefulWidget {
  final Map<String, dynamic>? transactionToEdit;
  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;
  bool _isExpense = true;
  bool _isRecurring = false;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    if (widget.transactionToEdit != null) {
      _amountController.text = widget.transactionToEdit!['amount'].toString();
      _descController.text = widget.transactionToEdit!['note'] ?? '';
      _selectedDate = DateTime.parse(widget.transactionToEdit!['date']);
      _selectedCategory = widget.transactionToEdit!['category'];
      _isRecurring = widget.transactionToEdit!['is_recurring'] == 1;
      if (widget.transactionToEdit!.containsKey('type')) {
        _isExpense = widget.transactionToEdit!['type'] == 'Expense';
      } else if (_selectedCategory != null) {
        // Determine _isExpense from category type
        _determineExpenseFromCategory();
      } else {
        // Default to expense if no type or category
        _isExpense = true;
      }
      _loadCategories();
    } else {
      _loadCategories();
    }
  }

  void _determineExpenseFromCategory() async {
    final categories = await DatabaseHelper.instance.getCategories();
    final cat = categories.firstWhere((c) => c['name'] == _selectedCategory);
    _isExpense = cat['type'] == 'Expense';
    _loadCategories();
  }

  void _loadCategories() async {
    final data = await DatabaseHelper.instance.getCategoriesByType(_isExpense ? 'Expense' : 'Income');
    setState(() {
      _categories = data;
      if (_selectedCategory != null && !_categories.any((c) => c['name'] == _selectedCategory)) {
        _selectedCategory = null;
      }
    });
  }

  void _addCategory() {
    TextEditingController nameCtrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('Add Category'),
      content: TextField(controller: nameCtrl, decoration: InputDecoration(hintText: 'Name')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(onPressed: () async {
          if (nameCtrl.text.isEmpty) return;
          if (_categories.any((c) => c['name'].toLowerCase() == nameCtrl.text.toLowerCase())) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Category "${nameCtrl.text}" already exists')),
            );
            return;
          }
          await DatabaseHelper.instance.insertCategory({
            'name': nameCtrl.text, 'type': _isExpense ? 'Expense' : 'Income',
            'icon': 'category', 'color': '0xFF9E9E9E'
          });
          if (!mounted) return;
          Navigator.pop(context);
          _loadCategories();
          setState(() {
            _selectedCategory = nameCtrl.text;
          });
        }, child: Text('Add'))
      ],
    ));
  }

  void _saveTransaction() async {
    if (_amountController.text.isEmpty || _selectedCategory == null) return;
    final row = {
      'amount': double.tryParse(_amountController.text) ?? 0,
      'category': _selectedCategory,
      'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'note': _descController.text,
      'is_recurring': _isRecurring ? 1 : 0
    };
    if (widget.transactionToEdit != null) {
      row['id'] = widget.transactionToEdit!['id'];
      await DatabaseHelper.instance.updateTransaction(row);
      if (!mounted) return;
    } else {
      await DatabaseHelper.instance.insertTransaction(row);
      if (!mounted) return;
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.transactionToEdit != null ? 'Edit Transaction' : 'Add Transaction'), actions: [
        IconButton(icon: Icon(Icons.save), onPressed: _saveTransaction)
      ]),
      body: ListView(padding: EdgeInsets.all(16), children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ChoiceChip(label: Text('Income'), selected: !_isExpense, onSelected: (v) => setState(() { _isExpense = !v; _loadCategories(); })),
          SizedBox(width: 10),
          ChoiceChip(label: Text('Expense'), selected: _isExpense, onSelected: (v) => setState(() { _isExpense = v; _loadCategories(); })),
        ]),
        TextField(controller: _descController, decoration: InputDecoration(labelText: 'Description')),
        TextField(controller: _amountController, decoration: InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
        Row(children: [
          Expanded(child: DropdownButtonFormField(
            value: _selectedCategory, // ignore: deprecated_member_use
            items: _categories.map((c) => DropdownMenuItem(value: c['name'].toString(), child: Text(c['name']))).toList(),
            onChanged: (v) => setState(() => _selectedCategory = v),
            hint: Text('Category'),
          )),
          IconButton(icon: Icon(Icons.add_circle, color: Colors.blue), onPressed: _addCategory)
        ]),
        ListTile(title: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)), trailing: Icon(Icons.calendar_today), onTap: () async {
          DateTime? d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
          if (d != null) setState(() => _selectedDate = d);
        }),
        SwitchListTile(title: Text('Recurring'), value: _isRecurring, onChanged: (v) => setState(() => _isRecurring = v)),
      ]),
    );
  }
}
