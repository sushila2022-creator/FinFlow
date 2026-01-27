import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:finflow/utils/database_helper.dart';
import 'package:finflow/providers/transaction_provider.dart';
import 'package:finflow/providers/theme_provider.dart';
import 'package:finflow/providers/currency_provider.dart';
import 'package:finflow/utils/app_theme.dart';
import 'package:finflow/models/transaction.dart';

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
  String _transactionType = 'Expense';
  bool _isRecurring = false;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _displayCategories = [];
  final _formKey = GlobalKey<FormState>();
  File? _attachedImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.transactionToEdit != null) {
      _populateEditData();
    }
  }

  void _populateEditData() {
    final data = widget.transactionToEdit!;
    _amountController.text = data['amount'].toString();
    _descController.text = data['note'] ?? '';
    _selectedDate = DateTime.parse(data['date']);
    _selectedCategory = data['category'];
    _isRecurring = data['is_recurring'] == 1;
    if (data.containsKey('type')) {
      _transactionType = data['type'] ?? 'Expense';
    }
  }

  Future<void> _loadCategories() async {
    final type = _transactionType == 'Transfer'
        ? 'Expense'
        : _transactionType; // Treat Transfer like Expense for categories
    final data = await DatabaseHelper.instance.getCategoriesByType(type);

    if (!mounted) return;

    setState(() {
      _categories = data;
      // Take first 7 categories for display, add "More" as 8th
      _displayCategories = data.take(7).toList();
      if (_selectedCategory != null) {
        final matchingCategory = _categories.firstWhere(
          (c) => c['name'].toLowerCase() == _selectedCategory!.toLowerCase(),
          orElse: () => {},
        );
        _selectedCategory = matchingCategory.isNotEmpty
            ? matchingCategory['name']
            : null;
      }
    });
  }

  void _setTransactionType(String type) {
    setState(() {
      _transactionType = type;
      _selectedCategory = null;
    });
    _loadCategories();
  }

  Future<void> _pickImage() async {
    final isDarkMode = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode
          ? AppTheme.surfaceDark
          : AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Attach Receipt',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDarkMode
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(Icons.camera_alt, 'Camera', () async {
                  Navigator.pop(context);
                  final pickedFile = await _imagePicker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );
                  if (!mounted) return;
                  if (pickedFile != null) {
                    setState(() => _attachedImage = File(pickedFile.path));
                  }
                }),
                _buildAttachmentOption(
                  Icons.photo_library,
                  'Gallery',
                  () async {
                    Navigator.pop(context);
                    final pickedFile = await _imagePicker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (!mounted) return;
                    if (pickedFile != null) {
                      setState(() => _attachedImage = File(pickedFile.path));
                    }
                  },
                ),
                if (_attachedImage != null)
                  _buildAttachmentOption(Icons.delete, 'Remove', () {
                    Navigator.pop(context);
                    setState(() => _attachedImage = null);
                  }),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: const Color(0xFF0D9488), size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDarkMode
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final isDarkMode = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).isDarkMode;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.accentColor,
              surface: isDarkMode
                  ? AppTheme.surfaceDark
                  : AppTheme.surfaceLight,
            ),
          ),
          child: child!,
        );
      },
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showCreateCategoryBottomSheet() {
    final TextEditingController categoryNameController =
        TextEditingController();
    IconData selectedIcon = Icons.category;
    final isDarkMode = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode
          ? AppTheme.surfaceDark
          : AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Create Category',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: categoryNameController,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'Enter category name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDarkMode
                      ? const Color(0xFF374151)
                      : Colors.white,
                ),
                onChanged: (value) {
                  // Auto-assign icon based on name
                  setState(() {
                    selectedIcon = AppTheme.getCategoryIcon(value.trim());
                  });
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Preview',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF374151) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode
                        ? const Color(0xFF4B5563)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.getCategoryColor(
                          categoryNameController.text.trim(),
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        selectedIcon,
                        color: AppTheme.getCategoryColor(
                          categoryNameController.text.trim(),
                        ),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        categoryNameController.text.isEmpty
                            ? 'Category Name'
                            : categoryNameController.text,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = categoryNameController.text.trim();
                        if (name.isEmpty) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a category name'),
                                backgroundColor: AppTheme.expenseColor,
                              ),
                            );
                          }
                          return;
                        }

                        try {
                          await DatabaseHelper.instance.insertCategory({
                            'name': name,
                            'type': _transactionType == 'Transfer'
                                ? 'Expense'
                                : _transactionType,
                            'icon': selectedIcon.codePoint.toString(),
                            'color': AppTheme.getCategoryColor(
                              name,
                            ).toARGB32().toString(),
                            'budget_limit': 0.0,
                          });
                          if (!mounted) return;

                          // Refresh categories
                          await _loadCategories();
                          if (!mounted) return;
                          setState(() => _selectedCategory = name);

                          if (!mounted) return;
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Category "$name" created successfully',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          if (mounted) {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error creating category: $e'),
                                backgroundColor: AppTheme.expenseColor,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Create',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    final isDarkMode = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode
          ? AppTheme.surfaceDark
          : AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Category',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (_transactionType == 'Expense'
                                        ? AppTheme.expenseColor
                                        : AppTheme.accentColor)
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_categories.length} items',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _transactionType == 'Expense'
                                  ? AppTheme.expenseColor
                                  : AppTheme.accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected =
                              _selectedCategory == category['name'];
                          final categoryColor = AppTheme.getCategoryColor(
                            category['name'],
                          );

                          return AnimatedScale(
                            scale: isSelected ? 1.05 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = category['name'];
                                });
                                Navigator.pop(context);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (_transactionType == 'Expense'
                                                ? AppTheme.expenseColor
                                                : AppTheme.accentColor)
                                            .withValues(alpha: 0.15)
                                      : (isDarkMode
                                            ? const Color(0xFF3D3D3D)
                                            : Colors.white),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? (_transactionType == 'Expense'
                                              ? AppTheme.expenseColor
                                              : AppTheme.accentColor)
                                        : (isDarkMode
                                              ? Colors.transparent
                                              : const Color(0xFFE0E0E0)),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color:
                                            (_transactionType == 'Expense'
                                                    ? AppTheme.expenseColor
                                                    : AppTheme.accentColor)
                                                .withValues(alpha: 0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              categoryColor,
                                              categoryColor.withValues(
                                                alpha: 0.8,
                                              ),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: categoryColor.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          AppTheme.getCategoryIcon(
                                            category['name'],
                                          ),
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Flexible(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: Text(
                                          category['name'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? (_transactionType == 'Expense'
                                                      ? AppTheme.expenseColor
                                                      : AppTheme.accentColor)
                                                : (isDarkMode
                                                      ? AppTheme.textPrimaryDark
                                                      : AppTheme
                                                            .textPrimaryLight),
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _validateAndSave() {
    if (!_formKey.currentState!.validate()) return false;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a category'),
          backgroundColor: AppTheme.expenseColor,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _saveTransaction() async {
    if (!_validateAndSave()) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid amount'),
            backgroundColor: AppTheme.expenseColor,
          ),
        );
      }
      return;
    }

    final currencyProvider = Provider.of<CurrencyProvider>(
      context,
      listen: false,
    );
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );

    // Find category ID from local database (case-insensitive search)
    final allCategories = await DatabaseHelper.instance.getCategories();
    if (!mounted) return;
    final matchingCategory = allCategories.firstWhere(
      (c) => c['name'].toLowerCase() == _selectedCategory!.toLowerCase(),
      orElse: () => {'id': 0},
    );

    try {
      if (widget.transactionToEdit != null) {
        // Update existing transaction in Firestore
        final transactionId = widget.transactionToEdit!['id'];
        if (transactionId == null || transactionId.toString().isEmpty) {
          // Generate a new ID if missing
          final newId = DateTime.now().millisecondsSinceEpoch.toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transaction ID was missing, using new ID: $newId'),
              backgroundColor: AppTheme.accentColor,
            ),
          );

          final transaction = Transaction(
            id: newId,
            description: _descController.text,
            amount: amount,
            currencyCode: currencyProvider.currentCurrencyCode,
            date: _selectedDate,
            category: _selectedCategory!,
            categoryId: matchingCategory['id'] ?? 0,
            isIncome: _transactionType == 'Income',
            accountId: 1,
            notes: _descController.text,
            isRecurring: _isRecurring,
          );

          await transactionProvider.addTransaction(transaction);
        } else {
          final transaction = Transaction(
            id: transactionId,
            description: _descController.text,
            amount: amount,
            currencyCode: currencyProvider.currentCurrencyCode,
            date: _selectedDate,
            category: _selectedCategory!,
            categoryId: matchingCategory['id'] ?? 0,
            isIncome: _transactionType == 'Income',
            accountId: 1,
            notes: _descController.text,
            isRecurring: _isRecurring,
          );

          await transactionProvider.updateTransaction(transaction);
        }
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        // Add new transaction to Firestore
        final transaction = Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          description: _descController.text,
          amount: amount,
          currencyCode: currencyProvider.currentCurrencyCode,
          date: _selectedDate,
          category: _selectedCategory!,
          categoryId: matchingCategory['id'] ?? 0,
          isIncome: _transactionType == 'Income',
          accountId: 1,
          notes: _descController.text,
          isRecurring: _isRecurring,
        );

        await transactionProvider.addTransaction(transaction);
        if (!mounted) return;
        Navigator.pop(context);
      }
    } catch (e) {
      // Show error in UI, not just terminal
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.expenseColor,
            action: SnackBarAction(
              label: 'Details',
              textColor: Colors.white,
              onPressed: () {
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Error Details'),
                      content: Text(e.toString()),
                      actions: [
                        TextButton(
                          onPressed: () {
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    return Scaffold(
      backgroundColor: isDarkMode
          ? AppTheme.backgroundDark
          : AppTheme.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const Spacer(),
                    Text(
                      'Add Transaction',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 40), // Balance the close button
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Amount Section
                      const SizedBox(height: 32),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'AMOUNT',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode
                                    ? AppTheme.textSecondaryDark
                                    : AppTheme.textSecondaryLight,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  currencyProvider.currentCurrencySymbol,
                                  style: GoogleFonts.inter(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode
                                        ? AppTheme.textPrimaryDark
                                        : AppTheme.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 180,
                                  child: TextFormField(
                                    controller: _amountController,
                                    autofocus: true,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: isDarkMode
                                          ? AppTheme.textPrimaryDark
                                          : AppTheme.textPrimaryLight,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      hintStyle: GoogleFonts.inter(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        color: isDarkMode
                                            ? AppTheme.textSecondaryDark
                                            : AppTheme.textSecondaryLight,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter an amount';
                                      }
                                      if (double.tryParse(value) == null ||
                                          double.parse(value) <= 0) {
                                        return 'Please enter a valid amount';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Transaction Type Toggle
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF374151)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _setTransactionType('Expense'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _transactionType == 'Expense'
                                        ? const Color(0xFF0D9488)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.arrow_downward,
                                        color: _transactionType == 'Expense'
                                            ? Colors.white
                                            : (isDarkMode
                                                  ? AppTheme.textSecondaryDark
                                                  : AppTheme
                                                        .textSecondaryLight),
                                        size: 20,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Expense',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _transactionType == 'Expense'
                                              ? Colors.white
                                              : (isDarkMode
                                                    ? AppTheme.textSecondaryDark
                                                    : AppTheme
                                                          .textSecondaryLight),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _setTransactionType('Income'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _transactionType == 'Income'
                                        ? const Color(0xFF0D9488)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.arrow_upward,
                                        color: _transactionType == 'Income'
                                            ? Colors.white
                                            : (isDarkMode
                                                  ? AppTheme.textSecondaryDark
                                                  : AppTheme
                                                        .textSecondaryLight),
                                        size: 20,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Income',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _transactionType == 'Income'
                                              ? Colors.white
                                              : (isDarkMode
                                                    ? AppTheme.textSecondaryDark
                                                    : AppTheme
                                                          .textSecondaryLight),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Category',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? AppTheme.textPrimaryDark
                                  : AppTheme.textPrimaryLight,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _showCreateCategoryBottomSheet,
                                icon: const Icon(Icons.add, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                color: const Color(0xFF0D9488),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _showCategoryPicker,
                                child: Text(
                                  'See All',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0D9488),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.8,
                            ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount:
                            _displayCategories.length + 1, // +1 for "More"
                        itemBuilder: (context, index) {
                          if (index == _displayCategories.length) {
                            // "More" button
                            return _buildCategoryItem(
                              'More',
                              Icons.add,
                              const Color(0xFF6B7280),
                              isMore: true,
                            );
                          }

                          final category = _displayCategories[index];
                          final categoryColor = AppTheme.getCategoryColor(
                            category['name'],
                          );
                          final categoryIcon = AppTheme.getCategoryIcon(
                            category['name'],
                          );

                          return _buildCategoryItem(
                            category['name'],
                            categoryIcon,
                            categoryColor,
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Fields
                      Column(
                        children: [
                          // Date Field
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF374151)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDarkMode
                                    ? const Color(0xFF4B5563)
                                    : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: GestureDetector(
                              onTap: _selectDate,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: isDarkMode
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFF6B7280),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'DATE',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isDarkMode
                                                ? const Color(0xFF9CA3AF)
                                                : const Color(0xFF6B7280),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Today, ${DateFormat('MMM dd yyyy').format(_selectedDate)}',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isDarkMode
                                                ? AppTheme.textPrimaryDark
                                                : AppTheme.textPrimaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: isDarkMode
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFFD1D5DB),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Note Field
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF374151)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDarkMode
                                    ? const Color(0xFF4B5563)
                                    : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.notes,
                                  color: isDarkMode
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'NOTE',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isDarkMode
                                              ? const Color(0xFF9CA3AF)
                                              : const Color(0xFF6B7280),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      TextFormField(
                                        controller: _descController,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: isDarkMode
                                              ? AppTheme.textPrimaryDark
                                              : AppTheme.textPrimaryLight,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Add a note...',
                                          hintStyle: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: isDarkMode
                                                ? const Color(0xFF9CA3AF)
                                                : const Color(0xFF9CA3AF),
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a description';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Attachment Field
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? const Color(0xFF374151)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDarkMode
                                      ? const Color(0xFF4B5563)
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (_attachedImage != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _attachedImage!,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.receipt,
                                      color: isDarkMode
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF6B7280),
                                    ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ATTACHMENT',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: isDarkMode
                                                ? const Color(0xFF9CA3AF)
                                                : const Color(0xFF6B7280),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        Text(
                                          _attachedImage != null
                                              ? 'Image attached'
                                              : 'Tap to attach receipt',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: isDarkMode
                                                ? AppTheme.textPrimaryDark
                                                : AppTheme.textPrimaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? const Color(0xFF4B5563)
                                          : const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _attachedImage != null
                                          ? Icons.edit
                                          : Icons.attach_file,
                                      size: 16,
                                      color: isDarkMode
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Save Button
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? AppTheme.backgroundDark
                              : AppTheme.backgroundLight,
                          border: Border(
                            top: BorderSide(
                              color: isDarkMode
                                  ? const Color(0xFF4B5563)
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: _saveTransaction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            shadowColor: const Color(
                              0xFF0D9488,
                            ).withValues(alpha: 0.2),
                            elevation: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Save Transaction',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.check, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
    String name,
    IconData icon,
    Color color, {
    bool isMore = false,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final isSelected = _selectedCategory == name;

    return GestureDetector(
      onTap: isMore
          ? _showCategoryPicker
          : () => setState(() => _selectedCategory = name),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF0D9488)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF0D9488)
                  : (isDarkMode
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight),
            ),
          ),
        ],
      ),
    );
  }
}
