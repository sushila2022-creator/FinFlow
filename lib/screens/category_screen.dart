import 'package:flutter/material.dart';
import 'package:finflow/models/category.dart';
import 'package:finflow/services/category_service.dart';
import 'package:finflow/utils/utility.dart' as utility;

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final CategoryService _categoryService = CategoryService();
  List<Category> _categories = [];
  bool _isLoading = true;
  String _filterType = 'all'; // 'all', 'income', 'expense'

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      if (_filterType == 'all') {
        _categories = await _categoryService.getAllCategories();
      } else {
        _categories = await _categoryService.getCategoriesByType(_filterType);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addCategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCategoryScreen(),
      ),
    );

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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (!context.mounted) return false;

    if (confirmed == true) {
      final success = await _categoryService.deleteCategory(category.id!);
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
            content: Text('Cannot delete ${category.name} - it has transactions'),
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
        title: const Text('Manage Categories'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterType = value;
                _loadCategories();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Categories'),
              ),
              const PopupMenuItem(
                value: 'income',
                child: Text('Income Only'),
              ),
              const PopupMenuItem(
                value: 'expense',
                child: Text('Expenses Only'),
              ),
            ],
          ),
        ],
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
    // Look up icon by category name from categoryIcons map, fallback to Icons.category
    final iconData = utility.categoryIcons[category.name.toLowerCase()] ?? Icons.category;

    return ListTile(
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
  final CategoryService _categoryService = CategoryService();

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
    if (_formKey.currentState!.validate()) {
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
          await _categoryService.addCategory(category);
        } else {
          // Update existing category
          await _categoryService.updateCategory(category);
        }
        if (!mounted) return;

        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving category: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null ? 'Add Category' : 'Edit Category'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveCategory,
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
                  helperText: 'Enter color in HEX format without # (e.g., FF5722 for orange)',
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
    final colorHex = _colorController.text.trim();
    Color iconColor = utility.stringToColor(colorHex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Icon',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          height: 350,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: utility.categoryIcons.length,
            itemBuilder: (context, index) {
              final iconEntry = utility.categoryIcons.entries.elementAt(index);
              final isSelected = _iconController.text == iconEntry.key;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _iconController.text = iconEntry.key;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? iconColor.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: iconColor, width: 2.5)
                        : Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ] : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        iconEntry.value,
                        size: 32,
                        color: isSelected ? iconColor : Colors.grey.shade600,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        iconEntry.key,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? iconColor : Colors.grey.shade500,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: iconColor.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  utility.getIconData(_iconController.text.trim()) ?? Icons.category,
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Icon',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _iconController.text.isEmpty ? 'None selected' : _iconController.text.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (_iconController.text.isNotEmpty)
                Icon(
                  Icons.check_circle,
                  color: iconColor,
                  size: 20,
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
              style: TextStyle(
                color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
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
        const Text(
          'Category Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                selectedColor: Colors.red.withValues(alpha: 0.2),
                backgroundColor: Colors.grey.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  color: _selectedType == 'expense' ? Colors.red : Colors.grey,
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
                selectedColor: Colors.green.withValues(alpha: 0.2),
                backgroundColor: Colors.grey.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  color: _selectedType == 'income' ? Colors.green : Colors.grey,
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
      return const Text('Icon not found', style: TextStyle(color: Colors.red));
    }

    final colorHex = _colorController.text.trim();
    final iconColor = utility.stringToColor(colorHex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Icon Preview:'),
        const SizedBox(height: 8),
        Center(
          child: Icon(
            iconData,
            size: 64,
            color: iconColor,
          ),
        ),
      ],
    );
  }
}
