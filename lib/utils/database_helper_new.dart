import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;
  static const String dbName = 'FinFlow.db';
  static const String transactionsTable = 'transactions';
  static const String budgetsTable = 'budgets';
  static const String savingsGoalsTable = 'savings_goals';
  static const String settingsTable = 'settings';
  static const String categoriesTable = 'categories';
  static const int _databaseVersion = 3;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    final db = await openDatabase(
      path, 
      version: _databaseVersion, 
      onCreate: _createTables, 
      onUpgrade: _onUpgrade
    );
    
    await db.execute(
      'CREATE TABLE IF NOT EXISTS categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, icon TEXT, color TEXT, type TEXT)'
    );
    
    await _populateCategories(db);
    
    return db;
  }

  Future<void> _createTables(Database db, int version) async {
    // Create transactions table
    await db.execute('''
      CREATE TABLE $transactionsTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        currencyCode TEXT NOT NULL,
        date TEXT NOT NULL,
        categoryId INTEGER NOT NULL,
        accountId INTEGER NOT NULL,
        notes TEXT,
        isRecurring INTEGER NOT NULL DEFAULT 0,
        recurrenceFrequency TEXT,
        recurrenceEndDate TEXT
      )
    ''');
    
    // Create categories table
    await db.execute('''
      CREATE TABLE $categoriesTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        icon TEXT,
        color TEXT,
        type TEXT
      )
    ''');
    
    // Create budgets table
    await db.execute('''
      CREATE TABLE $budgetsTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        startDate INTEGER NOT NULL,
        endDate INTEGER NOT NULL
      )
    ''');
    
    // Create savings goals table
    await db.execute('''
      CREATE TABLE $savingsGoalsTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        targetAmount REAL NOT NULL,
        currentAmount REAL NOT NULL DEFAULT 0.0,
        targetDate INTEGER NOT NULL
      )
    ''');
    
    // Create settings table
    await db.execute('''
      CREATE TABLE $settingsTable(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS categories');
      await db.execute('''
        CREATE TABLE $categoriesTable(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          icon TEXT,
          color TEXT,
          type TEXT
        )
      ''');
    }
  }

  // Comprehensive category population method
  Future<void> _populateCategories(Database db) async {
    final existingCategories = await db.query(categoriesTable, limit: 1);
    if (existingCategories.isNotEmpty) {
      return;
    }

    final List<Map<String, dynamic>> categories = [
      // INCOME CATEGORIES
      {'name': 'Salary', 'icon': '💼', 'color': '#4CAF50', 'type': 'income'},
      {'name': 'Freelance', 'icon': '💻', 'color': '#4CAF50', 'type': 'income'},
      {'name': 'Business Income', 'icon': '🏢', 'color': '#4CAF50', 'type': 'income'},
      {'name': 'Investment Returns', 'icon': '📈', 'color': '#4CAF50', 'type': 'income'},
      {'name': 'Dividends', 'icon': '💰', 'color': '#4CAF50', 'type': 'income'},
      {'name': 'Interest Income', 'icon': '🏦', 'color': '#4CAF50', 'type': 'income'},
      {'name': 'Rental Income', 'icon': '🏠', 'color': '#4CAF50', 'type': 'income'},
      {'name': 'Bonus', 'icon': '🎁', 'color': '#4CAF50', 'type': 'income'},
      {'name': 'Tips', 'icon': '💵', 'color': '#4CAF50', 'type': 'income'},
      {'name': 'Tax Refund', 'icon': '📋', 'color': '#4CAF50', 'type': 'income'},
      {'name': 'Miscellaneous Income', 'icon': '💸', 'color': '#4CAF50', 'type': 'income'},

      // EXPENSE CATEGORIES - Food & Dining
      {'name': 'Groceries', 'icon': '🛒', 'color': '#9C27B0', 'type': 'expense'},
      {'name': 'Restaurant', 'icon': '🍽️', 'color': '#9C27B0', 'type': 'expense'},
      {'name': 'Fast Food', 'icon': '🍔', 'color': '#9C27B0', 'type': 'expense'},
      {'name': 'Coffee', 'icon': '☕', 'color': '#9C27B0', 'type': 'expense'},
      {'name': 'Snacks', 'icon': '🍿', 'color': '#9C27B0', 'type': 'expense'},

      // EXPENSE CATEGORIES - Transportation
      {'name': 'Car Payment', 'icon': '🚗', 'color': '#FF9800', 'type': 'expense'},
      {'name': 'Gas/Fuel', 'icon': '⛽', 'color': '#FF9800', 'type': 'expense'},
      {'name': 'Public Transportation', 'icon': '🚌', 'color': '#FF9800', 'type': 'expense'},
      {'name': 'Parking', 'icon': '🅿️', 'color': '#FF9800', 'type': 'expense'},
      {'name': 'Auto Maintenance', 'icon': '🔧', 'color': '#FF9800', 'type': 'expense'},
      {'name': 'Taxi/Uber', 'icon': '🚖', 'color': '#FF9800', 'type': 'expense'},

      // EXPENSE CATEGORIES - Shopping
      {'name': 'Clothing', 'icon': '👕', 'color': '#795548', 'type': 'expense'},
      {'name': 'Electronics', 'icon': '📱', 'color': '#795548', 'type': 'expense'},
      {'name': 'Personal Care', 'icon': '🧴', 'color': '#795548', 'type': 'expense'},
      {'name': 'Online Shopping', 'icon': '🛒', 'color': '#795548', 'type': 'expense'},

      // EXPENSE CATEGORIES - Housing & Utilities
      {'name': 'Rent/Mortgage', 'icon': '🏠', 'color': '#F44336', 'type': 'expense'},
      {'name': 'Electricity', 'icon': '💡', 'color': '#F44336', 'type': 'expense'},
      {'name': 'Water', 'icon': '💧', 'color': '#F44336', 'type': 'expense'},
      {'name': 'Gas', 'icon': '🔥', 'color': '#F44336', 'type': 'expense'},
      {'name': 'Internet', 'icon': '🌐', 'color': '#F44336', 'type': 'expense'},
      {'name': 'Phone/Mobile', 'icon': '📱', 'color': '#F44336', 'type': 'expense'},
      {'name': 'Home Maintenance', 'icon': '🔧', 'color': '#F44336', 'type': 'expense'},

      // EXPENSE CATEGORIES - Healthcare
      {'name': 'Doctor Visit', 'icon': '👩‍⚕️', 'color': '#E91E63', 'type': 'expense'},
      {'name': 'Medicine', 'icon': '💊', 'color': '#E91E63', 'type': 'expense'},
      {'name': 'Medical Insurance', 'icon': '🏥', 'color': '#E91E63', 'type': 'expense'},

      // EXPENSE CATEGORIES - Education
      {'name': 'Tuition', 'icon': '🎓', 'color': '#3F51B5', 'type': 'expense'},
      {'name': 'Books', 'icon': '📚', 'color': '#3F51B5', 'type': 'expense'},
      {'name': 'Online Courses', 'icon': '💻', 'color': '#3F51B5', 'type': 'expense'},

      // EXPENSE CATEGORIES - Entertainment
      {'name': 'Movies', 'icon': '🎬', 'color': '#00BCD4', 'type': 'expense'},
      {'name': 'Streaming Services', 'icon': '📺', 'color': '#00BCD4', 'type': 'expense'},
      {'name': 'Games', 'icon': '🎮', 'color': '#00BCD4', 'type': 'expense'},
      {'name': 'Gym', 'icon': '💪', 'color': '#00BCD4', 'type': 'expense'},
      {'name': 'Hobbies', 'icon': '🎨', 'color': '#00BCD4', 'type': 'expense'},

      // EXPENSE CATEGORIES - Insurance & Financial
      {'name': 'Life Insurance', 'icon': '🛡️', 'color': '#607D8B', 'type': 'expense'},
      {'name': 'Bank Fees', 'icon': '🏦', 'color': '#607D8B', 'type': 'expense'},

      // EXPENSE CATEGORIES - Travel
      {'name': 'Hotel', 'icon': '🏨', 'color': '#8BC34A', 'type': 'expense'},
      {'name': 'Flight', 'icon': '✈️', 'color': '#8BC34A', 'type': 'expense'},

      // EXPENSE CATEGORIES - Gifts & Donations
      {'name': 'Gifts', 'icon': '🎁', 'color': '#CDDC39', 'type': 'expense'},
      {'name': 'Charity', 'icon': '❤️', 'color': '#CDDC39', 'type': 'expense'},

      // EXPENSE CATEGORIES - Miscellaneous
      {'name': 'Miscellaneous', 'icon': '📦', 'color': '#9E9E9E', 'type': 'expense'},
      {'name': 'Pet Care', 'icon': '🐾', 'color': '#9E9E9E', 'type': 'expense'},
      {'name': 'Childcare', 'icon': '👶', 'color': '#9E9E9E', 'type': 'expense'},
    ];

    for (final category in categories) {
      await db.insert(categoriesTable, category);
    }
  }

  // ============ CATEGORY METHODS ============

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return await db.query(categoriesTable);
  }

  Future<List<Map<String, dynamic>>> getCategoriesByType(String type) async {
    final db = await database;
    return await db.query(categoriesTable, where: 'type = ?', whereArgs: [type]);
  }

  Future<int> insertCategory(Map<String, dynamic> category) async {
    final db = await database;
    return await db.insert(categoriesTable, category);
  }

  Future<int> updateCategory(int id, Map<String, dynamic> category) async {
    final db = await database;
    return await db.update(categoriesTable, category, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete(categoriesTable, where: 'id = ?', whereArgs: [id]);
  }

  // ============ BUDGET METHODS ============

  Future<int> insertBudget(Map<String, dynamic> budget) async {
    final db = await database;
    return await db.insert(budgetsTable, budget);
  }

  Future<List<Map<String, dynamic>>> getBudgets() async {
    final db = await database;
    return await db.query(budgetsTable);
  }

  Future<int> updateBudget(int id, Map<String, dynamic> budget) async {
    final db = await database;
    return await db.update(budgetsTable, budget, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteBudget(int id) async {
    final db = await database;
    return await db.delete(budgetsTable, where: 'id = ?', whereArgs: [id]);
  }

  // ============ SAVINGS GOAL METHODS ============

  Future<int> insertSavingsGoal(Map<String, dynamic> savingsGoal) async {
    final db = await database;
    return await db.insert(savingsGoalsTable, savingsGoal);
  }

  Future<List<Map<String, dynamic>>> getSavingsGoals() async {
    final db = await database;
    return await db.query(savingsGoalsTable);
  }

  Future<int> updateSavingsGoal(int id, Map<String, dynamic> savingsGoal) async {
    final db = await database;
    return await db.update(savingsGoalsTable, savingsGoal, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSavingsGoal(int id) async {
    final db = await database;
    return await db.delete(savingsGoalsTable, where: 'id = ?', whereArgs: [id]);
  }

  // ============ TRANSACTION METHODS ============

  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    return await db.insert(transactionsTable, transaction);
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await database;
    return await db.query(transactionsTable, orderBy: 'date DESC');
  }

  Future<int> updateTransaction(int id, Map<String, dynamic> transaction) async {
    final db = await database;
    return await db.update(transactionsTable, transaction, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(transactionsTable, where: 'id = ?', whereArgs: [id]);
  }

  // ============ SETTINGS METHODS ============

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      settingsTable,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(settingsTable, where: 'key = ?', whereArgs: [key]);
    if (result.isNotEmpty) {
      return result.first['value'] as String?;
    }
    return null;
  }

  // ============ UTILITY METHODS ============

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(transactionsTable);
    await db.delete(budgetsTable);
    await db.delete(savingsGoalsTable);
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
