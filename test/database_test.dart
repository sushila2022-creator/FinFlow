import 'package:flutter_test/flutter_test.dart';
import 'package:finflow/utils/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize FFI for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Database Helper Tests', () {
    test('Categories table should exist and have correct schema', () async {
      // Create a fresh database helper instance for this test
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;

      try {
        // Check if categories table exists
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='categories'",
        );

        expect(tables.length, 1);
        expect(tables.first['name'], 'categories');

        // Check if categories table has the correct columns
        final columns = await db.rawQuery("PRAGMA table_info(categories)");

        final columnNames = columns.map((c) => c['name'] as String).toList();
        expect(columnNames, containsAll(['id', 'name', 'icon', 'color', 'type']));

        // Check column types
        final idColumn = columns.firstWhere((c) => c['name'] == 'id');
        final nameColumn = columns.firstWhere((c) => c['name'] == 'name');
        final iconColumn = columns.firstWhere((c) => c['name'] == 'icon');
        final colorColumn = columns.firstWhere((c) => c['name'] == 'color');
        final typeColumn = columns.firstWhere((c) => c['name'] == 'type');

        expect(idColumn['type'], 'INTEGER');
        expect(nameColumn['type'], 'TEXT');
        expect(iconColumn['type'], 'TEXT');
        expect(colorColumn['type'], 'TEXT');
        expect(typeColumn['type'], 'TEXT');
      } finally {
        await db.close();
      }
    });
  });
}
