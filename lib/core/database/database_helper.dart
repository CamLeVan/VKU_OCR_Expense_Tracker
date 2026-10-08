import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String _databaseName = "expense_tracker.db";
  static const int _databaseVersion = 1;

  // Table & Columns
  static const String tableExpenses = 'expenses';
  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnAmount = 'amount';
  static const String columnCategory = 'category';
  static const String columnDate = 'date';
  static const String columnImagePath = 'image_path';
  static const String columnCreatedAt = 'created_at';

  // Singleton instance
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableExpenses (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTitle TEXT NOT NULL,
        $columnAmount REAL NOT NULL,
        $columnCategory TEXT NOT NULL,
        $columnDate TEXT NOT NULL,
        $columnImagePath TEXT,
        $columnCreatedAt TEXT NOT NULL
      )
    ''');

    // Create index on date for faster range queries
    await db.execute('''
      CREATE INDEX idx_expenses_date ON $tableExpenses ($columnDate);
    ''');
  }

  // --- CRUD OPERATIONS ---

  /// Insert a new expense record into the local SQLite database
  Future<int> insertExpense(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(tableExpenses, row);
  }

  /// Retrieve all expenses sorted by date descending
  Future<List<Map<String, dynamic>>> queryAllExpenses() async {
    final db = await database;
    return await db.query(
      tableExpenses,
      orderBy: '$columnDate DESC',
    );
  }

  /// Retrieve an expense by ID
  Future<Map<String, dynamic>?> queryExpenseById(int id) async {
    final db = await database;
    final results = await db.query(
      tableExpenses,
      where: '$columnId = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  /// Update an existing expense record
  Future<int> updateExpense(int id, Map<String, dynamic> row) async {
    final db = await database;
    return await db.update(
      tableExpenses,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  /// Delete an expense record by ID
  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete(
      tableExpenses,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  /// Aggregate expenses grouped by category
  Future<List<Map<String, dynamic>>> queryCategoryTotals() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT $columnCategory, SUM($columnAmount) as total_amount
      FROM $tableExpenses
      GROUP BY $columnCategory
      ORDER BY total_amount DESC
    ''');
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
