import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/receipt.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, 'tether.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE receipts(
        id TEXT PRIMARY KEY,
        itemName TEXT NOT NULL,
        storeName TEXT,
        transactionId TEXT,
        barcode TEXT,
        purchaseDate TEXT NOT NULL,
        warrantyExpiry TEXT,
        returnDeadline TEXT,
        price REAL,
        imagePath TEXT,
        extractedText TEXT,
        category INTEGER NOT NULL,
        isNewPurchase INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Create index for faster queries
    await db.execute('CREATE INDEX idx_warranty ON receipts(warrantyExpiry)');
    await db.execute('CREATE INDEX idx_return ON receipts(returnDeadline)');
    await db.execute(
      'CREATE INDEX idx_extracted_text ON receipts(extractedText)',
    );
  }

  // Insert receipt
  Future<void> insertReceipt(Receipt receipt) async {
    final db = await database;
    await db.insert(
      'receipts',
      receipt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all receipts
  Future<List<Receipt>> getAllReceipts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'receipts',
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Receipt.fromMap(maps[i]));
  }

  // Get receipt by ID
  Future<Receipt?> getReceiptById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'receipts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Receipt.fromMap(maps.first);
  }

  // Update receipt
  Future<void> updateReceipt(Receipt receipt) async {
    final db = await database;
    await db.update(
      'receipts',
      receipt.toMap(),
      where: 'id = ?',
      whereArgs: [receipt.id],
    );
  }

  // Delete receipt
  Future<void> deleteReceipt(String id) async {
    final db = await database;
    await db.delete('receipts', where: 'id = ?', whereArgs: [id]);
  }

  // Get receipts with expiring warranty (next 30 days)
  Future<List<Receipt>> getExpiringWarranties({int days = 30}) async {
    final db = await database;
    final now = DateTime.now();
    final future = now.add(Duration(days: days));

    final List<Map<String, dynamic>> maps = await db.query(
      'receipts',
      where:
          'warrantyExpiry IS NOT NULL AND warrantyExpiry >= ? AND warrantyExpiry <= ?',
      whereArgs: [now.toIso8601String(), future.toIso8601String()],
      orderBy: 'warrantyExpiry ASC',
    );
    return List.generate(maps.length, (i) => Receipt.fromMap(maps[i]));
  }

  // Get receipts with expiring return window (next 7 days)
  Future<List<Receipt>> getExpiringReturns({int days = 7}) async {
    final db = await database;
    final now = DateTime.now();
    final future = now.add(Duration(days: days));

    final List<Map<String, dynamic>> maps = await db.query(
      'receipts',
      where:
          'returnDeadline IS NOT NULL AND returnDeadline >= ? AND returnDeadline <= ?',
      whereArgs: [now.toIso8601String(), future.toIso8601String()],
      orderBy: 'returnDeadline ASC',
    );
    return List.generate(maps.length, (i) => Receipt.fromMap(maps[i]));
  }

  // Get expired warranties
  Future<List<Receipt>> getExpiredWarranties() async {
    final db = await database;
    final now = DateTime.now();

    final List<Map<String, dynamic>> maps = await db.query(
      'receipts',
      where: 'warrantyExpiry IS NOT NULL AND warrantyExpiry < ?',
      whereArgs: [now.toIso8601String()],
      orderBy: 'warrantyExpiry DESC',
    );
    return List.generate(maps.length, (i) => Receipt.fromMap(maps[i]));
  }

  // Search receipts by text (OCR text search)
  Future<List<Receipt>> searchReceipts(String query) async {
    final db = await database;
    final searchQuery = '%${query.toLowerCase()}%';

    final List<Map<String, dynamic>> maps = await db.query(
      'receipts',
      where:
          'LOWER(itemName) LIKE ? OR LOWER(storeName) LIKE ? OR LOWER(extractedText) LIKE ? OR LOWER(transactionId) LIKE ?',
      whereArgs: [searchQuery, searchQuery, searchQuery, searchQuery],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Receipt.fromMap(maps[i]));
  }

  // Get receipts by category
  Future<List<Receipt>> getReceiptsByCategory(ItemCategory category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'receipts',
      where: 'category = ?',
      whereArgs: [category.index],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Receipt.fromMap(maps[i]));
  }

  // Get counts for dashboard
  Future<Map<String, int>> getCounts() async {
    final db = await database;
    final now = DateTime.now();
    final in30Days = now.add(const Duration(days: 30));
    final in7Days = now.add(const Duration(days: 7));

    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM receipts',
    );
    final expiringWarrantiesResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM receipts WHERE warrantyExpiry IS NOT NULL AND warrantyExpiry >= ? AND warrantyExpiry <= ?',
      [now.toIso8601String(), in30Days.toIso8601String()],
    );
    final expiringReturnsResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM receipts WHERE returnDeadline IS NOT NULL AND returnDeadline >= ? AND returnDeadline <= ?',
      [now.toIso8601String(), in7Days.toIso8601String()],
    );
    final expiredResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM receipts WHERE warrantyExpiry IS NOT NULL AND warrantyExpiry < ?',
      [now.toIso8601String()],
    );

    return {
      'total': Sqflite.firstIntValue(totalResult) ?? 0,
      'expiringWarranties':
          Sqflite.firstIntValue(expiringWarrantiesResult) ?? 0,
      'expiringReturns': Sqflite.firstIntValue(expiringReturnsResult) ?? 0,
      'expired': Sqflite.firstIntValue(expiredResult) ?? 0,
    };
  }
}
