import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
//refrencing dbhelperfile
class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  Database? _database;
//creating database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "food_ordering.db");

    return await openDatabase(
      path,
      version: 2, // Incremented the version
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE FoodItems (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            cost REAL,
            selected INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE OrderPlans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            items TEXT,
            target_cost REAL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE FoodItems ADD COLUMN selected INTEGER DEFAULT 0');
        }
      },
    );
  }

 //inserting food items
  Future<void> insertFoodItem(Map<String, dynamic> foodItem) async {
    final db = await database;
    final item = {
      ...foodItem,
      'selected': (foodItem['selected'] == true) ? 1 : 0,
    };
    await db.insert('FoodItems', item);
  }
//getting food items 
  Future<List<Map<String, dynamic>>> getFoodItems() async {
    final db = await database;
    final items = await db.query('FoodItems');
    return items.map((item) {
      return {
        ...item,
        'selected': (item['selected'] as int) == 1,
      };
    }).toList();
  }
//editing food items 
  Future<void> insertOrderPlan(Map<String, dynamic> orderPlan) async {
    final db = await database;
    await db.insert('OrderPlans', orderPlan);
  }
//getting order plans
  Future<List<Map<String, dynamic>>> getOrderPlans(String date) async {
    final db = await database;
    return await db.query(
      'OrderPlans',
      where: 'date = ?',
      whereArgs: [date],
    );
  }
//edting/updating food items
  Future<void> updateFoodItem(int id, Map<String, dynamic> updatedData) async {
    final db = await database;
    final updatedItem = {
      ...updatedData,
      'selected': (updatedData['selected'] == true) ? 1 : 0,
    };
    await db.update(
      'FoodItems',
      updatedItem,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
//deleting food items
  Future<void> deleteFoodItem(int id) async {
    final db = await database;
    await db.delete(
      'FoodItems',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
//deleting order plans 
  Future<void> deleteAllOrderPlans() async {
    final db = await database;
    await db.delete('OrderPlans');
  }
}
