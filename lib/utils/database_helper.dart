import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:finflow/models/category.dart';
import 'package:finflow/utils/debug_logger.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finflow_v4.db'); // v4 to force fresh creation
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER DEFAULT 0';

    await db.execute(
      'CREATE TABLE transactions (id $idType, title $textType, description $textType, amount $realType, currencyCode $textType, date $textType, category $textType, categoryId $intType, isIncome $intType, accountId $intType, notes $textType, isRecurring $intType, recurrenceFrequency $textType, recurrenceEndDate $textType, attachmentPath $textType)',
    );
    await db.execute(
      'CREATE TABLE categories (id $idType, name $textType, type $textType, icon $textType, color $textType, budget_limit $realType DEFAULT 0.0)',
    );
    await db.execute(
      'CREATE TABLE budgets (id $idType, category $textType, amount $realType, period $textType)',
    );
    await db.execute(
      'CREATE TABLE savings_goals (id $idType, name $textType, target_amount $realType, saved_amount $realType, deadline $textType, icon $textType, color $textType)',
    );

    // Seed India-Specific Categories
    await _seedDatabase(db);
  }

  Future<void> _seedDatabase(Database db) async {
    // Income
    final income = [
      {'name': 'Salary', 'icon': 'account_balance_wallet', 'color': '0xFF00C853'},
      {'name': 'Business', 'icon': 'business_center', 'color': '0xFF43A047'},
      {'name': 'Bonus', 'icon': 'redeem', 'color': '0xFFFB8C00'},
      {'name': 'Gift', 'icon': 'card_giftcard', 'color': '0xFFEC407A'},
      {'name': 'Rent Income', 'icon': 'real_estate_agent', 'color': '0xFF26A69A'},
      {'name': 'Interest', 'icon': 'trending_up', 'color': '0xFF1E88E5'},
    ];
    for (var cat in income) {
      await db.insert('categories', {
        'name': cat['name'],
        'type': 'Income',
        'icon': cat['icon'],
        'color': cat['color'],
        'budget_limit': 0.0,
      });
    }
    // Expenses
    final expenses = [
      {'name': 'Groceries', 'icon': 'local_grocery_store', 'color': '0xFFFF7043'},
      {'name': 'Rent', 'icon': 'home_work', 'color': '0xFF26A69A'},
      {'name': 'Electricity', 'icon': 'electrical_services', 'color': '0xFF7E57C2'},
      {'name': 'Mobile/Wifi', 'icon': 'wifi', 'color': '0xFF5C6BC0'},
      {'name': 'Petrol/Fuel', 'icon': 'local_gas_station', 'color': '0xFFFFB300'},
      {'name': 'EMI', 'icon': 'credit_card', 'color': '0xFF546E7A'},
      {'name': 'School Fees', 'icon': 'school', 'color': '0xFF3949AB'},
      {'name': 'Medicine', 'icon': 'medical_services', 'color': '0xFFE53935'},
      {'name': 'Shopping', 'icon': 'shopping_bag', 'color': '0xFFD81B60'},
      {'name': 'Food/Dining', 'icon': 'restaurant', 'color': '0xFFFB8C00'},
      {'name': 'Travel', 'icon': 'directions_car', 'color': '0xFF1E88E5'},
      {'name': 'Maid', 'icon': 'cleaning_services', 'color': '0xFF8D6E63'},
      {'name': 'Repair', 'icon': 'build', 'color': '0xFF795548'},
    ];
    for (var cat in expenses) {
      await db.insert('categories', {
        'name': cat['name'],
        'type': 'Expense',
        'icon': cat['icon'],
        'color': cat['color'],
        'budget_limit': 0.0,
      });
    }
  }

  // --- TRANSACTIONS ---
  Future<int> insertTransaction(Map<String, dynamic> row) async {
    try {
      final db = await instance.database;
      return await db.insert('transactions', row);
    } catch (e) {
      logError('Database Error (insertTransaction)', error: e);
      return -1;
    }
  }

  Future<int> updateTransaction(Map<String, dynamic> row) async {
    try {
      final db = await instance.database;
      final id = row['id'];
      if (id == null) return -1;
      return await db.update(
        'transactions',
        row,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      logError('Database Error (updateTransaction)', error: e);
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      final db = await instance.database;
      return await db.query('transactions', orderBy: 'date DESC');
    } catch (e) {
      logError('Database Error (getTransactions)', error: e);
      return [];
    }
  }

  // --- CATEGORIES ---
  Future<int> insertCategory(Map<String, dynamic> row) async {
    try {
      final db = await instance.database;
      return await db.insert(
        'categories',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      logError('Database Error (insertCategory)', error: e);
      return -1;
    }
  }

  Future<int> updateCategory(Map<String, dynamic> row) async {
    try {
      final db = await instance.database;
      return await db.update(
        'categories',
        row,
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    } catch (e) {
      logError('Database Error (updateCategory)', error: e);
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final db = await instance.database;
      return await db.query('categories');
    } catch (e) {
      logError('Database Error (getCategories)', error: e);
      return [];
    }
  }

  // FIX: This method is needed for AddTransactionScreen
  Future<List<Map<String, dynamic>>> getCategoriesByType(String type) async {
    try {
      final db = await instance.database;
      return await db.query('categories', where: 'LOWER(type) = ?', whereArgs: [type.toLowerCase()]);
    } catch (e) {
      logError('Database Error (getCategoriesByType)', error: e);
      return [];
    }
  }

  // --- MODEL MAPPING HELPER ---
  Future<List<Category>> getAllCategoriesObjects() async {
    try {
      final data = await getCategories();
      return data.map((json) => Category.fromMap(json)).toList();
    } catch (e) {
      logError('Error mapping categories', error: e);
      return [];
    }
  }

  Future<int> newCategory(Category category) async {
    return await insertCategory(category.toMap());
  }

  Future<int> updateCategoryObject(Category category) async {
    return await updateCategory(category.toMap());
  }

  // FIX: This method is needed for Category Management
  Future<int> deleteCategory(int id) async {
    try {
      final db = await instance.database;
      return await db.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      logError('Database Error (deleteCategory)', error: e);
      return -1;
    }
  }

  // --- BUDGETS (Missing methods RESTORED) ---
  Future<int> insertBudget(Map<String, dynamic> row) async {
    try {
      final db = await instance.database;
      return await db.insert(
        'budgets',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      logError('Database Error (insertBudget)', error: e);
      return -1;
    }
  }

  // FIX: Error 'getBudgets' isn't defined
  Future<List<Map<String, dynamic>>> getBudgets() async {
    try {
      final db = await instance.database;
      return await db.query('budgets');
    } catch (e) {
      logError('Database Error (getBudgets)', error: e);
      return [];
    }
  }

  // FIX: Error 'deleteBudget' isn't defined
  Future<int> deleteBudget(int id) async {
    try {
      final db = await instance.database;
      return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      logError('Database Error (deleteBudget)', error: e);
      return -1;
    }
  }

  // FIX: Error 'updateBudget' isn't defined
  Future<int> updateBudget(Map<String, dynamic> row) async {
    try {
      final db = await instance.database;
      return await db.update(
        'budgets',
        row,
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    } catch (e) {
      logError('Database Error (updateBudget)', error: e);
      return -1;
    }
  }

  // --- SAVINGS & UTILS ---
  Future<int> insertSavingsGoal(Map<String, dynamic> row) async {
    try {
      final db = await instance.database;
      return await db.insert('savings_goals', row);
    } catch (e) {
      logError('Database Error (insertSavingsGoal)', error: e);
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getSavingsGoals() async {
    try {
      final db = await instance.database;
      return await db.query('savings_goals');
    } catch (e) {
      logError('Database Error (getSavingsGoals)', error: e);
      return [];
    }
  }

  Future<int> deleteSavingsGoal(int id) async {
    try {
      final db = await instance.database;
      return await db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      logError('Database Error (deleteSavingsGoal)', error: e);
      return -1;
    }
  }

  Future<void> clearAllData() async {
    try {
      final db = await instance.database;
      await db.delete('transactions');
      await db.delete('categories');
      await db.delete('budgets');
      await db.delete('savings_goals');
      await _seedDatabase(db);
    } catch (e) {
      logError('Database Error (clearAllData)', error: e);
    }
  }

  Future<List<Map<String, dynamic>>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await instance.database;
      return await db.query(
        'transactions',
        where: 'date BETWEEN ? AND ?',
        whereArgs: [
          startDate.millisecondsSinceEpoch,
          endDate.millisecondsSinceEpoch,
        ],
        orderBy: 'date DESC',
      );
    } catch (e) {
      logError('Database Error (getTransactionsByDateRange)', error: e);
      return [];
    }
  }

  Future<Set<String>> getAllTransactionSignatures() async {
    try {
      final db = await instance.database;
      final result = await db.query('transactions', columns: ['amount', 'date']);
      return result.map((row) => "${row['amount']}_${row['date']}").toSet();
    } catch (e) {
      logError('Database Error (getAllTransactionSignatures)', error: e);
      return {};
    }
  }
}
