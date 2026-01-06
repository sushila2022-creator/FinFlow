import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'finance_tracker.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT,
        amount REAL,
        currencyCode TEXT,
        date TEXT,
        categoryId INTEGER,
        categoryName TEXT,
        type TEXT,
        accountId INTEGER,
        notes TEXT,
        isRecurring INTEGER,
        recurrenceFrequency TEXT,
        recurrenceEndDate TEXT,
        attachmentPath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        icon TEXT,
        color TEXT,
        type TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transactions ADD COLUMN attachmentPath TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE transactions ADD COLUMN type TEXT');
    }
  }

  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    // The insert method returns the id of the inserted row.
    return await db.insert('transactions', transaction,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await database;
    return await db.query('transactions', orderBy: 'date DESC');
  }

  Future<int> updateTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction,
      where: 'id = ?',
      whereArgs: [transaction['id']],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Category CRUD operations
  Future<int> insertCategory(Map<String, dynamic> category) async {
    final db = await database;
    return await db.insert('categories', category,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return await db.query('categories', orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> getCategoriesByType(String type) async {
    final db = await database;
    return await db.query('categories', where: 'type = ?', whereArgs: [type], orderBy: 'name ASC');
  }

  Future<int> updateCategory(Map<String, dynamic> category) async {
    final db = await database;
    return await db.update(
      'categories',
      category,
      where: 'id = ?',
      whereArgs: [category['id']],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> hasTransactionsForCategory(int categoryId) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
    return result.isNotEmpty;
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
