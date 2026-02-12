import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sensor_data.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'sensor_data.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Accelerometer table
    await db.execute('''
      CREATE TABLE accelerometer_buffer (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        x REAL NOT NULL,
        y REAL NOT NULL,
        z REAL NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    // Gyroscope table
    await db.execute('''
      CREATE TABLE gyroscope_buffer (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        x REAL NOT NULL,
        y REAL NOT NULL,
        z REAL NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    // Proximity table
    await db.execute('''
      CREATE TABLE proximity_buffer (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        proximity_state INTEGER NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    // GPS table
    await db.execute('''
      CREATE TABLE gps_buffer (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        speed REAL,
        accuracy REAL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  // Accelerometer operations
  Future<void> insertAccelerometerData(AccelerometerData data) async {
    final db = await database;
    await db.insert(
      'accelerometer_buffer',
      data.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllAccelerometerData() async {
    final db = await database;
    return await db.query('accelerometer_buffer');
  }

  Future<void> deleteAccelerometerData(List<int> ids) async {
    final db = await database;
    await db.delete(
      'accelerometer_buffer',
      where: 'id IN (${ids.map((e) => '?').join(',')})',
      whereArgs: ids,
    );
  }

  // Gyroscope operations
  Future<void> insertGyroscopeData(GyroscopeData data) async {
    final db = await database;
    await db.insert(
      'gyroscope_buffer',
      data.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllGyroscopeData() async {
    final db = await database;
    return await db.query('gyroscope_buffer');
  }

  Future<void> deleteGyroscopeData(List<int> ids) async {
    final db = await database;
    await db.delete(
      'gyroscope_buffer',
      where: 'id IN (${ids.map((e) => '?').join(',')})',
      whereArgs: ids,
    );
  }

  // Proximity operations
  Future<void> insertProximityData(ProximityData data) async {
    final db = await database;
    await db.insert(
      'proximity_buffer',
      data.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllProximityData() async {
    final db = await database;
    return await db.query('proximity_buffer');
  }

  Future<void> deleteProximityData(List<int> ids) async {
    final db = await database;
    await db.delete(
      'proximity_buffer',
      where: 'id IN (${ids.map((e) => '?').join(',')})',
      whereArgs: ids,
    );
  }

  // GPS operations
  Future<void> insertGPSData(GPSData data) async {
    final db = await database;
    await db.insert(
      'gps_buffer',
      data.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllGPSData() async {
    final db = await database;
    return await db.query('gps_buffer');
  }

  Future<void> deleteGPSData(List<int> ids) async {
    final db = await database;
    await db.delete(
      'gps_buffer',
      where: 'id IN (${ids.map((e) => '?').join(',')})',
      whereArgs: ids,
    );
  }
}
