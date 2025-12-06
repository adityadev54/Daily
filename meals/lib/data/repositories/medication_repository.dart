import '../database/database_helper.dart';
import '../models/medication.dart';

class MedicationRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Get all medications for a user
  Future<List<Medication>> getMedications(int userId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'medications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'is_active DESC, name ASC',
    );
    return maps.map((map) => Medication.fromMap(map)).toList();
  }

  // Get active medications only
  Future<List<Medication>> getActiveMedications(int userId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'medications',
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [userId],
      orderBy: 'times ASC, name ASC',
    );
    return maps.map((map) => Medication.fromMap(map)).toList();
  }

  // Get medications that should be taken with food
  Future<List<Medication>> getMedicationsWithFood(int userId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'medications',
      where: 'user_id = ? AND is_active = 1 AND with_food = 1',
      whereArgs: [userId],
    );
    return maps.map((map) => Medication.fromMap(map)).toList();
  }

  // Get medications for a specific time of day
  Future<List<Medication>> getMedicationsForTimeOfDay(
    int userId,
    String timeOfDay,
  ) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'medications',
      where: 'user_id = ? AND is_active = 1 AND times = ?',
      whereArgs: [userId, timeOfDay],
    );
    return maps.map((map) => Medication.fromMap(map)).toList();
  }

  // Add a medication
  Future<int> addMedication(Medication medication) async {
    final db = await _databaseHelper.database;
    final map = medication.toMap();
    map.remove('id');
    return await db.insert('medications', map);
  }

  // Update a medication
  Future<int> updateMedication(Medication medication) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'medications',
      medication.toMap(),
      where: 'id = ?',
      whereArgs: [medication.id],
    );
  }

  // Toggle medication active status
  Future<void> toggleMedicationActive(int medicationId, bool isActive) async {
    final db = await _databaseHelper.database;
    await db.update(
      'medications',
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [medicationId],
    );
  }

  // Delete a medication
  Future<int> deleteMedication(int medicationId) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'medications',
      where: 'id = ?',
      whereArgs: [medicationId],
    );
  }

  // Get medication count
  Future<int> getMedicationCount(int userId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM medications WHERE user_id = ? AND is_active = 1',
      [userId],
    );
    return result.first['count'] as int;
  }
}
