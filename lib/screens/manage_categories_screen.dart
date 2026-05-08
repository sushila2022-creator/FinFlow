import 'package:flutter/material.dart';
import 'package:finflow/models/category.dart';
import 'package:finflow/providers/category_provider.dart';
import 'package:provider/provider.dart';

import 'package:finflow/utils/app_theme.dart';
import 'package:finflow/screens/category_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:finflow/utils/utility.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _addCategory() async {
    final TextEditingController nameController = TextEditingController();
    String selectedType = 'expense';

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
                  onChanged: (val) {
                    setState(() {});
                  },
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
                  'Preview:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.getCategoryColor(
                            nameController.text.trim(),
                            isIncome: selectedType == 'income',
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          AppTheme.getCategoryIcon(nameController.text.trim()),
                          color: AppTheme.getCategoryColor(
                            nameController.text.trim(),
                            isIncome: selectedType == 'income',
                          ),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          nameController.text.isEmpty
                              ? 'Category Name'
                              : nameController.text.trim(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
                    'icon': 'category', // Auto-mapped dynamically
                  });
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      try {
        final newCategory = Category(
          name: result['name']!,
          icon: result['icon']!,
          color: '2196F3', // Default blue color
          type: result['type']!,
          budgetLimit: 0.0, // Default budget limit
        );

        final categoryProvider = context.read<CategoryProvider>();
        await categoryProvider.addCategory(newCategory);
        
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${newCategory.name} added successfully')),
        );
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
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, child) {
          if (categoryProvider.isLoading && !categoryProvider.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final categories = categoryProvider.categories;
          
          if (categories.isEmpty) {
            return const Center(
              child: Text(
                'No categories found. Tap + to add your first category.',
                textAlign: TextAlign.center,
              ),
            );
          }
          
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryTile(category);
            },
          );
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
                    hintText: 'Enter budget limit',
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
                  'Preview:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.getCategoryColor(
                            nameController.text.trim(),
                            isIncome: selectedType == 'income',
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          AppTheme.getCategoryIcon(nameController.text.trim()),
                          color: AppTheme.getCategoryColor(
                            nameController.text.trim(),
                            isIncome: selectedType == 'income',
                          ),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          nameController.text.isEmpty
                              ? 'Category Name'
                              : nameController.text.trim(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
                    'icon': 'category', // Auto-mapped using Magic visual 
                  });
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

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

        final categoryProvider = context.read<CategoryProvider>();
        await categoryProvider.updateCategory(updatedCategory);
        
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${updatedCategory.name} updated successfully'),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating category: $e')));
      }
    }
  }

  Widget _buildCategoryTile(Category category) {
    // Force all categories to use the AppTheme Magic Visual system,
    // so it perfectly matches the Add Transaction screen.
    final color = AppTheme.getCategoryColor(
      category.name,
      isIncome: category.type.toLowerCase() == 'income',
    );

    final iconData = AppTheme.getCategoryIcon(category.name);

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(iconData, color: color, size: 24),
      ),
      title: Text(category.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
      subtitle: Text(
        "${category.type[0].toUpperCase()}${category.type.substring(1)} Category",
        style: GoogleFonts.plusJakartaSans(fontSize: 11),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryDetailScreen(
              categoryName: category.name,
              isIncome: category.type.toLowerCase() == 'income',
            ),
          ),
        );
      },
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

              if (confirmed == true) {
                if (!mounted) return;
                try {
                  final categoryProvider = context.read<CategoryProvider>();
                  await categoryProvider.deleteCategory(category.id.toString());
                  
                  if (mounted) {
                    showSnackBar(context, 'Category "${category.name}" deleted');
                  }
                } catch (e) {
                  if (mounted) {
                    showErrorSnackBar(context, 'Failed to delete category: $e');
                  }
                }
              }
            },
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
