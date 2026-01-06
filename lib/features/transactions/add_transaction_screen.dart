import 'package:finflow/models/transaction.dart'; // Corrected import path
import 'package:finflow/providers/currency_provider.dart'; // Added import for CurrencyProvider
import 'package:finflow/providers/transaction_provider.dart'; // Corrected import path
import 'package:finflow/services/categorization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:provider/provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction; // Make transaction nullable and final

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _categorizationService = CategorizationService();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedCategory;
  bool _isCategoryAutoSuggested = false;
  DateTime? _selectedDate;
  Transaction? _editingTransaction;
  bool _isRecurring = false;
  String? _recurrenceFrequency = 'Daily';
  DateTime? _recurrenceEndDate;

  final Map<String, int> _categoryMap = {
    'Food': 1,
    'Income': 2,
    'Housing': 3,
    'Bills': 4,
    'Misc': 5,
  };

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_autoCategorize);

    // Set default date to current DateTime
    _selectedDate = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Transaction) {
        _editingTransaction = args;
        _descriptionController.text = _editingTransaction!.description;
        _amountController.text = _editingTransaction!.amount.abs().toString();
        _selectedCategory = _categoryMap.entries
            .firstWhere((element) => element.value == _editingTransaction!.categoryId, orElse: () => _categoryMap.entries.first)
            .key;
        _selectedDate = _editingTransaction!.date;
        _noteController.text = _editingTransaction!.notes ?? '';
        _isRecurring = _editingTransaction!.isRecurring;
        _recurrenceFrequency = _editingTransaction!.recurrenceFrequency;
        _recurrenceEndDate = _editingTransaction!.recurrenceEndDate;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_autoCategorize);
    _descriptionController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double? _evaluateExpression(String expression) {
    try {
      final parser = Parser();
      final exp = parser.parse(expression);
      final cm = ContextModel();
      final result = exp.evaluate(EvaluationType.REAL, cm);
      return result.toDouble();
    } catch (e) {
      return null;
    }
  }



  void _autoCategorize() async {
    final description = _descriptionController.text;
    final categoryId = await _categorizationService.getCategoryIdFromDescription(description);
    if (categoryId != null) {
      final categoryName = _categoryMap.entries.firstWhere((element) => element.value == categoryId, orElse: () => _categoryMap.entries.first).key;
      if (_selectedCategory != categoryName) {
        setState(() {
          _selectedCategory = categoryName;
          _isCategoryAutoSuggested = true;
        });
      }
    } else {
      setState(() {
        _isCategoryAutoSuggested = false;
      });
    }
  }

  Future<void> _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final description = _descriptionController.text;
      final amountText = _amountController.text;
      final note = _noteController.text.isEmpty ? null : _noteController.text;
      double? amount = double.tryParse(amountText) ?? _evaluateExpression(amountText);

      if (amount == null || _selectedCategory == null || _selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields.')),
        );
        return;
      }

      // Determine transaction type based on category
      final String transactionType = _selectedCategory == 'Income' ? 'income' : 'expense';

      final transaction = Transaction(
        id: _editingTransaction?.id ?? DateTime.now().millisecondsSinceEpoch,
        description: description,
        amount: amount.abs(),
        date: _selectedDate!,
        categoryId: _categoryMap[_selectedCategory]!,
        categoryName: _selectedCategory!,
        type: transactionType,
        accountId: _editingTransaction?.accountId ?? 1, // Add a default accountId
        currencyCode: _editingTransaction?.currencyCode ?? 'USD', // Add a default currencyCode
        notes: note,
        isRecurring: _isRecurring,
        recurrenceFrequency: _isRecurring ? _recurrenceFrequency : null,
        recurrenceEndDate: _isRecurring ? _recurrenceEndDate : null,
      );

      if (_editingTransaction == null) {
        transactionProvider.addTransaction(transaction);
      } else {
        transactionProvider.updateTransaction(transaction);
      }

      Navigator.of(context).pop();
    }
  }

  void _showCalculatorKeypad() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CalculatorKeypad(
        onKeyPressed: _onKeyPressed,
        onDone: () => Navigator.of(context).pop(),
        onBackspace: _backspace,
        onClear: _clearAmount,
      ),
    );
  }

  void _onKeyPressed(String key) {
    setState(() {
      if (key == '=') {
        final result = _evaluateExpression(_amountController.text);
        if (result != null) {
          _amountController.text = result.toStringAsFixed(2);
        }
      } else {
        _amountController.text += key;
      }
    });
  }

  void _backspace() {
    setState(() {
      _amountController.text = _amountController.text.isNotEmpty ? _amountController.text.substring(0, _amountController.text.length - 1) : '';
    });
  }

  void _clearAmount() {
    setState(() {
      _amountController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_editingTransaction == null ? 'Add Transaction' : 'Edit Transaction'),
        backgroundColor: theme.primaryColor,
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _descriptionController,
                  labelText: 'Description',
                  icon: Icons.description,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Consumer<CurrencyProvider>(
                  builder: (context, currencyProvider, child) {
                    final currencySymbol = currencyProvider.currentCurrencySymbol;
                    return _buildTextField(
                      controller: _amountController,
                      labelText: 'Amount',
                      prefixText: currencySymbol,
                      readOnly: true,
                      onTap: _showCalculatorKeypad,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null && _evaluateExpression(value) == null) {
                          return 'Please enter a valid number or expression';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdown(),
                const SizedBox(height: 16),
                _buildDatePicker(theme),
                const SizedBox(height: 16),
                _buildRecurringSwitch(),
                if (_isRecurring) ...[
                  const SizedBox(height: 16),
                  _buildRecurrenceDropdown(),
                  const SizedBox(height: 16),
                  _buildRecurrenceEndDatePicker(theme),
                ],
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _noteController,
                  labelText: 'Note (Optional)',
                  icon: Icons.note,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    IconData? icon,
    String? prefixText,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLines = 1,
    VoidCallback? onEditingComplete,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: icon != null ? Icon(icon) : null,
        prefixText: prefixText,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
      ),
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      onEditingComplete: onEditingComplete,
      readOnly: readOnly,
      onTap: onTap,
    );
  }

  Widget _buildDropdown() {
    // Safety check: ensure _selectedCategory is valid
    String? effectiveSelectedCategory = _selectedCategory;
    if (effectiveSelectedCategory != null && !_categoryMap.containsKey(effectiveSelectedCategory)) {
      effectiveSelectedCategory = _categoryMap.keys.first;
    }

    if (_categoryMap.isEmpty) {
      return const Text('No categories available');
    }

    return DropdownButtonFormField<String>(
      initialValue: effectiveSelectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: const Icon(Icons.category),
        suffixIcon: _isCategoryAutoSuggested ? const Icon(Icons.lightbulb_outline) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
      ),
      items: _categoryMap.keys.map((String category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
          _isCategoryAutoSuggested = false;
        });
      },
      validator: (value) => value == null ? 'Please select a category' : null,
    );
  }

  Widget _buildDatePicker(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _presentDatePicker,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Date',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              child: Text(
                _selectedDate == null
                    ? 'No Date Chosen'
                    : DateFormat.yMd().format(_selectedDate!),
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecurringSwitch() {
    return SwitchListTile(
      title: const Text('Recurring Transaction'),
      value: _isRecurring,
      onChanged: (value) {
        setState(() {
          _isRecurring = value;
        });
      },
    );
  }

  Widget _buildRecurrenceDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _recurrenceFrequency,
      decoration: InputDecoration(
        labelText: 'Frequency',
        prefixIcon: const Icon(Icons.repeat),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
      ),
      items: ['Daily', 'Weekly', 'Monthly'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _recurrenceFrequency = value;
        });
      },
    );
  }

  Future<void> _presentRecurrenceEndDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _recurrenceEndDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _recurrenceEndDate = pickedDate;
      });
    }
  }

  Widget _buildRecurrenceEndDatePicker(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _presentRecurrenceEndDatePicker,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'End Date',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              child: Text(
                _recurrenceEndDate == null
                    ? 'No Date Chosen'
                    : DateFormat.yMd().format(_recurrenceEndDate!),
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CalculatorKeypad extends StatelessWidget {
  final Function(String) onKeyPressed;
  final VoidCallback onDone;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  const CalculatorKeypad({
    super.key,
    required this.onKeyPressed,
    required this.onDone,
    required this.onBackspace,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['7', '8', '9', '/'],
      ['4', '5', '6', '*'],
      ['1', '2', '3', '-'],
      ['C', '0', '=', '+'],
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      color: Colors.grey.shade200,
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.8,
              ),
              itemCount: 16,
              itemBuilder: (context, index) {
                final row = index ~/ 4;
                final col = index % 4;
                final key = keys[row][col];
                final isOperator = ['/', '*', '-', '+'].contains(key);
                if (key == 'C') {
                  return IconButton(
                    onPressed: onBackspace,
                    onLongPress: onClear,
                    icon: const Icon(Icons.backspace_outlined),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.shade200,
                      foregroundColor: Colors.black,
                      iconSize: 24,
                      padding: const EdgeInsets.all(16),
                    ),
                  );
                }
                return ElevatedButton(
                  onPressed: () => onKeyPressed(key),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOperator ? Colors.teal : Colors.white,
                    foregroundColor: isOperator ? Colors.white : Colors.black,
                    elevation: isOperator ? 0 : 2,
                    padding: const EdgeInsets.all(16),
                    textStyle: const TextStyle(fontSize: 24),
                  ),
                  child: Text(key),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 30),
              ),
              child: const Text('DONE'),
            ),
          ],
        ),
      ),
    );
  }
}
