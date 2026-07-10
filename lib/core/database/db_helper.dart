import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/drink_log_model.dart';
import '../models/daily_summary_model.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hydrio.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: _createDB,
      );
    }

    final dbPath = await databaseFactory.getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE drink_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount_ml INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        day_key TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_summary (
        day_key TEXT PRIMARY KEY,
        target_ml INTEGER NOT NULL,
        total_ml INTEGER NOT NULL,
        completion_pct REAL NOT NULL,
        status TEXT NOT NULL
      )
    ''');
  }

  // --- Drink Log Operations ---

  Future<int> insertDrinkLog(DrinkLog log) async {
    final db = await instance.database;
    return await db.insert('drink_log', log.toMap());
  }

  Future<int> deleteDrinkLog(int id) async {
    final db = await instance.database;
    return await db.delete(
      'drink_log',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<DrinkLog>> getDrinkLogsForDay(String dayKey) async {
    final db = await instance.database;
    final maps = await db.query(
      'drink_log',
      where: 'day_key = ?',
      whereArgs: [dayKey],
      orderBy: 'timestamp ASC',
    );

    return maps.map((map) => DrinkLog.fromMap(map)).toList();
  }

  Future<List<DrinkLog>> getAllDrinkLogs() async {
    final db = await instance.database;
    final maps = await db.query('drink_log', orderBy: 'timestamp DESC');
    return maps.map((map) => DrinkLog.fromMap(map)).toList();
  }

  // --- Daily Summary Operations ---

  Future<int> upsertDailySummary(DailySummary summary) async {
    final db = await instance.database;
    return await db.insert(
      'daily_summary',
      summary.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DailySummary?> getDailySummary(String dayKey) async {
    final db = await instance.database;
    final maps = await db.query(
      'daily_summary',
      where: 'day_key = ?',
      whereArgs: [dayKey],
    );

    if (maps.isNotEmpty) {
      return DailySummary.fromMap(maps.first);
    }
    return null;
  }

  Future<List<DailySummary>> getAllDailySummaries() async {
    final db = await instance.database;
    final maps = await db.query('daily_summary', orderBy: 'day_key DESC');
    return maps.map((map) => DailySummary.fromMap(map)).toList();
  }

  Future<int> deleteDailySummary(String dayKey) async {
    final db = await instance.database;
    return await db.delete(
      'daily_summary',
      where: 'day_key = ?',
      whereArgs: [dayKey],
    );
  }

  // --- Database Maintenance ---

  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('drink_log');
    await db.delete('daily_summary');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
