import '../database/database_helper.dart';
import '../models/budget.dart';

class BudgetRepository {
  final DatabaseHelper _db = DatabaseHelper();

  // Budget Settings
  Future<BudgetSettings?> getBudgetSettings(int userId) async {
    try {
      final db = await _db.database;
      final results = await db.query(
        'budget_settings',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      if (results.isEmpty) return null;
      return BudgetSettings.fromMap(results.first);
    } catch (e) {
      return null;
    }
  }

  Future<bool> saveBudgetSettings(BudgetSettings settings) async {
    try {
      final db = await _db.database;

      // Check if settings exist
      final existing = await getBudgetSettings(settings.userId);

      if (existing != null) {
        await db.update(
          'budget_settings',
          settings.toMap(),
          where: 'user_id = ?',
          whereArgs: [settings.userId],
        );
      } else {
        await db.insert('budget_settings', settings.toMap());
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // Budget Entries
  Future<List<BudgetEntry>> getEntries(
    int userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await _db.database;

      String where = 'user_id = ?';
      List<dynamic> whereArgs = [userId];

      if (startDate != null) {
        where += ' AND date >= ?';
        whereArgs.add(startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        where += ' AND date <= ?';
        whereArgs.add(endDate.toIso8601String().split('T')[0]);
      }

      final results = await db.query(
        'budget_entries',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'date DESC',
      );
      return results.map((map) => BudgetEntry.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<BudgetEntry>> getWeeklyEntries(int userId) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return getEntries(userId, startDate: weekStart, endDate: weekEnd);
  }

  Future<List<BudgetEntry>> getMonthlyEntries(int userId) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    return getEntries(userId, startDate: monthStart, endDate: monthEnd);
  }

  Future<int?> addEntry(BudgetEntry entry) async {
    try {
      final db = await _db.database;
      return await db.insert('budget_entries', entry.toMap());
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateEntry(BudgetEntry entry) async {
    try {
      if (entry.id == null) return false;
      final db = await _db.database;
      await db.update(
        'budget_entries',
        entry.toMap(),
        where: 'id = ?',
        whereArgs: [entry.id],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteEntry(int id) async {
    try {
      final db = await _db.database;
      await db.delete('budget_entries', where: 'id = ?', whereArgs: [id]);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Statistics
  Future<double> getWeeklySpending(int userId) async {
    final entries = await getWeeklyEntries(userId);
    double total = 0;
    for (final entry in entries) {
      total += entry.amount;
    }
    return total;
  }

  Future<double> getMonthlySpending(int userId) async {
    final entries = await getMonthlyEntries(userId);
    double total = 0;
    for (final entry in entries) {
      total += entry.amount;
    }
    return total;
  }

  Future<Map<String, double>> getSpendingByCategory(
    int userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final entries = await getEntries(
      userId,
      startDate: startDate,
      endDate: endDate,
    );
    final Map<String, double> byCategory = {};

    for (final entry in entries) {
      final category = entry.category ?? 'Other';
      byCategory[category] = (byCategory[category] ?? 0) + entry.amount;
    }

    return byCategory;
  }

  Future<double> getDailyAverage(int userId, {int days = 30}) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    final entries = await getEntries(userId, startDate: startDate);

    if (entries.isEmpty) return 0;

    final total = entries.fold(0.0, (sum, entry) => sum + entry.amount);
    return total / days;
  }
}
