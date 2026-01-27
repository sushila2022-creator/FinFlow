import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/transaction.dart';
import '../models/category.dart';

class DBProvider {
  DBProvider._();
  static final DBProvider db = DBProvider._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  Future<Database> initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "FinanceTracker.db");
    return await openDatabase(
      path,
      version: 1,
      onOpen: (db) {},
      onCreate: (Database db, int version) async {
        await db.execute(
          "CREATE TABLE Account ("
          "id INTEGER PRIMARY KEY,"
          "name TEXT,"
          "balance REAL,"
          "currencyCode TEXT"
          ")",
        );

        await db.execute(
          "CREATE TABLE Category ("
          "id INTEGER PRIMARY KEY,"
          "name TEXT,"
          "icon TEXT"
          ")",
        );

        await db.execute(
          "CREATE TABLE \"Transaction\" ("
          "id INTEGER PRIMARY KEY,"
          "description TEXT,"
          "amount REAL,"
          "currencyCode TEXT,"
          "date TEXT,"
          "categoryId INTEGER,"
          "accountId INTEGER,"
          "notes TEXT,"
          "FOREIGN KEY (categoryId) REFERENCES Category(id),"
          "FOREIGN KEY (accountId) REFERENCES Account(id)"
          ")",
        );

        await db.execute(
          "CREATE TABLE Budget ("
          "id INTEGER PRIMARY KEY,"
          "category TEXT,"
          "amount REAL,"
          "startDate INTEGER,"
          "endDate INTEGER"
          ")",
        );
      },
    );
  }

  // Category CRUD
  Future<int> newCategory(Category newCategory) async {
    final db = await database;
    var res = await db.insert("Category", newCategory.toMap());
    return res;
  }

  Future<Category?> getCategory(int id) async {
    final db = await database;
    var res = await db.query("Category", where: "id = ?", whereArgs: [id]);
    return res.isNotEmpty ? Category.fromMap(res.first) : null;
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    var res = await db.query("Category");
    List<Category> list = res.isNotEmpty
        ? res.map((c) => Category.fromMap(c)).toList()
        : [];
    return list;
  }

  Future<int> updateCategory(Category newCategory) async {
    final db = await database;
    var res = await db.update(
      "Category",
      newCategory.toMap(),
      where: "id = ?",
      whereArgs: [newCategory.id],
    );
    return res;
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    var res = await db.delete("Category", where: "id = ?", whereArgs: [id]);
    return res;
  }

  // Transaction CRUD
  Future<int> newTransaction(Transaction newTransaction) async {
    final db = await database;
    var res = await db.insert("\"Transaction\"", newTransaction.toMap());
    return res;
  }

  Future<Transaction?> getTransaction(int id) async {
    final db = await database;
    var res = await db.query(
      "\"Transaction\"",
      where: "id = ?",
      whereArgs: [id],
    );
    return res.isNotEmpty ? Transaction.fromMap(res.first) : null;
  }

  Future<List<Transaction>> getAllTransactions() async {
    final db = await database;
    var res = await db.query("\"Transaction\"");
    List<Transaction> list = res.isNotEmpty
        ? res.map((c) => Transaction.fromMap(c)).toList()
        : [];
    return list;
  }

  Future<int> updateTransaction(Transaction newTransaction) async {
    final db = await database;
    var res = await db.update(
      "\"Transaction\"",
      newTransaction.toMap(),
      where: "id = ?",
      whereArgs: [newTransaction.id],
    );
    return res;
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    var res = await db.delete(
      "\"Transaction\"",
      where: "id = ?",
      whereArgs: [id],
    );
    return res;
  }
}
