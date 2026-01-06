import 'package:finflow/models/category.dart';
import 'package:finflow/utils/database_helper.dart';

class CategoryService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Get all categories
  Future<List<Category>> getAllCategories() async {
    final categoryMaps = await _databaseHelper.getCategories();
    return categoryMaps.map((map) => Category.fromMap(map)).toList();
  }

  // Get categories by type (income/expense)
  Future<List<Category>> getCategoriesByType(String type) async {
    final categoryMaps = await _databaseHelper.getCategoriesByType(type);
    return categoryMaps.map((map) => Category.fromMap(map)).toList();
  }

  // Add a new category
  Future<int> addCategory(Category category) async {
    return await _databaseHelper.insertCategory(category.toMap());
  }

  // Update an existing category
  Future<int> updateCategory(Category category) async {
    return await _databaseHelper.updateCategory(category.toMap());
  }

  // Delete a category
  Future<bool> deleteCategory(int categoryId) async {
    // Check if category has transactions by querying the transactions table
    final db = await _databaseHelper.database;
    final result = await db.query(
      'transactions',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
    
    if (result.isNotEmpty) {
      return false; // Cannot delete category with transactions
    }
    
    final deleteResult = await _databaseHelper.deleteCategory(categoryId);
    return deleteResult > 0;
  }

  // Initialize default categories if database is empty
  Future<void> initializeDefaultCategories() async {
    final existingCategories = await getAllCategories();
    if (existingCategories.isEmpty) {
      final defaultCategories = [
        Category(name: 'Food', icon: 'fastfood', color: 'FF5722', type: 'expense'),
        Category(name: 'Salary', icon: 'attach_money', color: '4CAF50', type: 'income'),
        Category(name: 'Housing', icon: 'home', color: '2196F3', type: 'expense'),
        Category(name: 'Bills', icon: 'receipt', color: '9C27B0', type: 'expense'),
        Category(name: 'Travel', icon: 'directions_bus', color: 'FF9800', type: 'expense'),
        Category(name: 'Shopping', icon: 'shopping_bag', color: 'E91E63', type: 'expense'),
        Category(name: 'Misc', icon: 'category', color: '795548', type: 'expense'),
      ];

      for (final category in defaultCategories) {
        await addCategory(category);
      }
    }
  }
}
