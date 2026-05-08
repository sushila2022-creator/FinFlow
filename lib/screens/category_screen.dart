import 'package:flutter/material.dart';
import 'package:finflow/models/category.dart';
import '../utils/database_helper.dart';
import 'package:finflow/utils/utility.dart' as utility;
import 'package:finflow/utils/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      _categories = await _dbHelper.getAllCategoriesObjects();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading categories: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addCategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditCategoryScreen()),
    );
    if (!mounted) return;

    if (result == true) {
      _loadCategories();
    }
  }

  Future<void> _editCategory(Category category) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCategoryScreen(category: category),
      ),
    );
    if (!mounted) return;

    if (result == true) {
      _loadCategories();
    }
  }

  Future<bool> _deleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.plusJakartaSans(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (!context.mounted) return false;

    if (confirmed == true) {
      final result = await _dbHelper.deleteCategory(category.id!);
      final success = result > 0;
      if (!mounted) return false;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${category.name} deleted successfully')),
        );
        _loadCategories();
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot delete ${category.name} - it has transactions',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Categories',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? const Center(
              child: Text(
                'No categories found. Tap + to add your first category.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return Dismissible(
                  key: Key('category_${category.id}'),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      final result = await _deleteCategory(category);
                      return result;
                    }
                    return false;
                  },
                  child: _buildCategoryTile(category),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        tooltip: 'Add Category',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryTile(Category category) {
    final color = utility.stringToColor(category.color);
    // Look up icon by category name from AppTheme
    final iconData = AppTheme.getCategoryIcon(category.name);

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.2),
        child: Icon(iconData, color: color),
      ),
      title: Text(category.name),
      subtitle: Text(
        category.type == 'income' ? 'Income Category' : 'Expense Category',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _editCategory(category),
    );
  }
}

class AddEditCategoryScreen extends StatefulWidget {
  final Category? category;

  const AddEditCategoryScreen({super.key, this.category});

  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _iconController = TextEditingController();
  final _colorController = TextEditingController();
  String _selectedType = 'expense';
  bool _isSaving = false;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _iconController.text = widget.category!.icon;
      _colorController.text = widget.category!.color;
      _selectedType = widget.category!.type;
    } else {
      // Default values for new category
      _nameController.text = '';
      _iconController.text = 'category';
      _colorController.text = '2196F3'; // Default blue color
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (_isSaving) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final category = Category(
        id: widget.category?.id,
        name: _nameController.text.trim(),
        icon: _iconController.text.trim(),
        color: _colorController.text.trim(),
        type: _selectedType,
      );

      try {
        if (widget.category == null) {
          // Add new category
          await _dbHelper.newCategory(category);
        } else {
          // Update existing category
          await _dbHelper.updateCategoryObject(category);
        }
        if (!mounted) return;

        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving category: $e')));
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null ? 'Add Category' : 'Edit Category'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveCategory,
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
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildIconSelector(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Color (HEX without #)',
                  prefixIcon: Icon(Icons.color_lens),
                  helperText:
                      'Enter color in HEX format without # (e.g., FF5722 for orange)',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a color';
                  }
                  if (!RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(value.trim())) {
                    return 'Please enter a valid 6-digit HEX color';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildColorPreview(),
              const SizedBox(height: 24),
              _buildTypeSelector(),
              const SizedBox(height: 24),
              _buildIconPreview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.getCategoryColor(
              _nameController.text.trim(),
              isIncome: _selectedType == 'income',
            ).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.getCategoryColor(
                _nameController.text.trim(),
                isIncome: _selectedType == 'income',
              ).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.getCategoryColor(
                    _nameController.text.trim(),
                    isIncome: _selectedType == 'income',
                  ).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  AppTheme.getCategoryIcon(_nameController.text.trim()),
                  color: AppTheme.getCategoryColor(
                    _nameController.text.trim(),
                    isIncome: _selectedType == 'income',
                  ),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _nameController.text.isEmpty
                      ? 'Category Name'
                      : _nameController.text.trim(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorPreview() {
    final colorHex = _colorController.text.trim();
    if (colorHex.isEmpty || !RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(colorHex)) {
      return const SizedBox();
    }

    final color = utility.stringToColor(colorHex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Color Preview:'),
        const SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey),
          ),
          child: Center(
            child: Text(
              '#$colorHex',
              style: GoogleFonts.plusJakartaSans(
                color: color.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Type',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Expense'),
                selected: _selectedType == 'expense',
                onSelected: (selected) {
                  setState(() {
                    _selectedType = 'expense';
                  });
                },
                selectedColor: AppTheme.expenseColor.withValues(alpha: 0.2),
                backgroundColor: Colors.grey.withValues(alpha: 0.1),
                labelStyle: GoogleFonts.plusJakartaSans(
                  color: _selectedType == 'expense'
                      ? AppTheme.expenseColor
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Text('Income'),
                selected: _selectedType == 'income',
                onSelected: (selected) {
                  setState(() {
                    _selectedType = 'income';
                  });
                },
                selectedColor: AppTheme.incomeColor.withValues(alpha: 0.2),
                backgroundColor: Colors.grey.withValues(alpha: 0.1),
                labelStyle: GoogleFonts.plusJakartaSans(
                  color: _selectedType == 'income'
                      ? AppTheme.incomeColor
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconPreview() {
    final iconName = _iconController.text.trim();
    if (iconName.isEmpty) {
      return const SizedBox();
    }

    final iconData = utility.getIconData(iconName);
    if (iconData == null) {
      return Text(
        'Icon not found',
        style: GoogleFonts.plusJakartaSans(color: Colors.red),
      );
    }

    final colorHex = _colorController.text.trim();
    final iconColor = utility.stringToColor(colorHex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Icon Preview:'),
        const SizedBox(height: 8),
        Center(child: Icon(iconData, size: 64, color: iconColor)),
      ],
    );
  }
}
