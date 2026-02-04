import 'package:flutter/material.dart';
import 'package:finflow/models/category.dart';
import 'package:finflow/providers/db_provider.dart';
import 'package:finflow/utils/utility.dart' as utility;
import 'package:finflow/utils/app_theme.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final DBProvider _dbProvider = DBProvider.db;
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
      _categories = await _dbProvider.getAllCategories();
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
    final TextEditingController nameController = TextEditingController();
    String selectedType = 'expense';
    String selectedIcon = 'category';

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'Enter category name',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Category Type:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'expense',
                      label: Text('Expense'),
                    ),
                    ButtonSegment<String>(
                      value: 'income',
                      label: Text('Income'),
                    ),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() => selectedType = newSelection.first);
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Icon:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: utility.selectableIcons.length,
                    itemBuilder: (context, index) {
                      final iconEntry = utility.selectableIcons[index];
                      final isSelected = iconEntry.key == selectedIcon;
                      return InkWell(
                        onTap: () {
                          setState(() => selectedIcon = iconEntry.key);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.2)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(
                                    color: Theme.of(context).primaryColor,
                                  )
                                : null,
                          ),
                          child: Icon(iconEntry.value, size: 24),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.pop(context, {
                    'name': nameController.text.trim(),
                    'type': selectedType,
                    'icon': selectedIcon,
                  });
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        final newCategory = Category(
          name: result['name']!,
          icon: result['icon']!,
          color: '2196F3', // Default blue color
          type: result['type']!,
          budgetLimit: 0.0, // Default budget limit
        );

        await _dbProvider.newCategory(newCategory);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${newCategory.name} added successfully')),
        );
        _loadCategories();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding category: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
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
                return _buildCategoryTile(category);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        tooltip: 'Add Category',
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _editCategory(Category category) async {
    final TextEditingController nameController = TextEditingController(
      text: category.name,
    );
    final TextEditingController budgetController = TextEditingController(
      text: category.budgetLimit.toString(),
    );
    String selectedType = category.type;
    String selectedIcon = category.icon;

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'Enter category name',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: budgetController,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Budget Limit',
                    hintText: 'Enter budget limit (0 for no limit)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Category Type:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'expense',
                      label: Text('Expense'),
                    ),
                    ButtonSegment<String>(
                      value: 'income',
                      label: Text('Income'),
                    ),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() => selectedType = newSelection.first);
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Icon:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: utility.selectableIcons.length,
                    itemBuilder: (context, index) {
                      final iconEntry = utility.selectableIcons[index];
                      final isSelected = iconEntry.key == selectedIcon;
                      return InkWell(
                        onTap: () {
                          setState(() => selectedIcon = iconEntry.key);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.2)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(
                                    color: Theme.of(context).primaryColor,
                                  )
                                : null,
                          ),
                          child: Icon(iconEntry.value, size: 24),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  final budgetLimit =
                      double.tryParse(budgetController.text) ?? 0.0;
                  Navigator.pop(context, {
                    'name': nameController.text.trim(),
                    'budgetLimit': budgetLimit,
                    'type': selectedType,
                    'icon': selectedIcon,
                  });
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        final updatedCategory = Category(
          id: category.id,
          name: result['name']!,
          icon: result['icon']!,
          color: category.color, // Keep existing color
          type: result['type']!,
          budgetLimit: result['budgetLimit']!,
        );

        await _dbProvider.updateCategory(updatedCategory);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${updatedCategory.name} updated successfully'),
          ),
        );
        _loadCategories();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating category: $e')));
      }
    }
  }

  Widget _buildCategoryTile(Category category) {
    final color = utility.stringToColor(category.color);
    final iconData = utility.getIconData(category.icon) ?? Icons.category;

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.2),
        child: Icon(iconData, color: color),
      ),
      title: Text(category.name),
      subtitle: Text(
        "${category.type[0].toUpperCase()}${category.type.substring(1)} Category",
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editCategory(category),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await _dbProvider.deleteCategory(category.id!);
              _loadCategories();
            },
          ),
        ],
      ),
    );
  }
}
