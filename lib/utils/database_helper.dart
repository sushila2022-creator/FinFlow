import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
      'CREATE TABLE transactions (id $idType, amount $realType, category $textType, date $textType, note $textType, is_recurring $intType)',
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
      'Salary',
      'Business',
      'Bonus',
      'Gift',
      'Rent Income',
      'Interest',
    ];
    for (var name in income) {
      await db.insert('categories', {
        'name': name,
        'type': 'Income',
        'icon': 'attach_money',
        'color': '0xFF4CAF50',
        'budget_limit': 0.0,
      });
    }
    // Expenses
    final expenses = [
      'Groceries',
      'Rent',
      'Electricity',
      'Mobile/Wifi',
      'Petrol/Fuel',
      'EMI',
      'School Fees',
      'Medicine',
      'Shopping',
      'Food/Dining',
      'Travel',
      'Maid',
      'Repair',
    ];
    for (var name in expenses) {
      await db.insert('categories', {
        'name': name,
        'type': 'Expense',
        'icon': 'shopping_cart',
        'color': '0xFFF44336',
        'budget_limit': 0.0,
      });
    }
  }

  // --- TRANSACTIONS ---
  Future<int> insertTransaction(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('transactions', row);
  }

  Future<int> updateTransaction(Map<String, dynamic> row) async {
    final db = await instance.database;
    final id = row['id'];
    if (id == null) throw ArgumentError('Transaction id cannot be null');
    return await db.update(
      'transactions',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await instance.database;
    return await db.query('transactions', orderBy: 'date DESC');
  }

  // --- CATEGORIES ---
  Future<int> insertCategory(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert(
      'categories',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateCategory(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'categories',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<List<Map<String, dynamic>>> getCategories() async =>
      (await instance.database).query('categories');

  // FIX: This method is needed for AddTransactionScreen
  Future<List<Map<String, dynamic>>> getCategoriesByType(String type) async {
    final db = await instance.database;
    return await db.query('categories', where: 'type = ?', whereArgs: [type]);
  }

  // FIX: This method is needed for Category Management
  Future<int> deleteCategory(int id) async => (await instance.database).delete(
    'categories',
    where: 'id = ?',
    whereArgs: [id],
  );

  // --- BUDGETS (Missing methods RESTORED) ---
  Future<int> insertBudget(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert(
      'budgets',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // FIX: Error 'getBudgets' isn't defined
  Future<List<Map<String, dynamic>>> getBudgets() async {
    final db = await instance.database;
    return await db.query('budgets');
  }

  // FIX: Error 'deleteBudget' isn't defined
  Future<int> deleteBudget(int id) async {
    final db = await instance.database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // FIX: Error 'updateBudget' isn't defined
  Future<int> updateBudget(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'budgets',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  // --- SAVINGS & UTILS ---
  Future<int> insertSavingsGoal(Map<String, dynamic> row) async =>
      (await instance.database).insert('savings_goals', row);
  Future<List<Map<String, dynamic>>> getSavingsGoals() async =>
      (await instance.database).query('savings_goals');
  Future<int> deleteSavingsGoal(int id) async => (await instance.database)
      .delete('savings_goals', where: 'id = ?', whereArgs: [id]);

  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('transactions');
    await db.delete('categories');
    await db.delete('budgets');
    await db.delete('savings_goals');
    await _seedDatabase(db);
  }

  Future<Set<String>> getAllTransactionSignatures() async {
    final db = await instance.database;
    final result = await db.query('transactions', columns: ['amount', 'date']);
    return result.map((row) => "${row['amount']}_${row['date']}").toSet();
  }
}
