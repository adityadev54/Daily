import '../database/database_helper.dart';
import '../models/bookmark.dart';
import '../models/meal.dart';

class BookmarkRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Get all bookmarks for a user
  Future<List<Bookmark>> getBookmarks(int userId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'bookmarks',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Bookmark.fromMap(map)).toList();
  }

  // Get all bookmarked meals for a user
  Future<List<Meal>> getBookmarkedMeals(int userId) async {
    final db = await _databaseHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT m.* FROM meals m
      INNER JOIN bookmarks b ON m.id = b.meal_id
      WHERE b.user_id = ?
      ORDER BY b.created_at DESC
    ''',
      [userId],
    );
    return maps.map((map) => Meal.fromMap(map)).toList();
  }

  // Check if a meal is bookmarked
  Future<bool> isBookmarked(int userId, int mealId) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'bookmarks',
      where: 'user_id = ? AND meal_id = ?',
      whereArgs: [userId, mealId],
    );
    return result.isNotEmpty;
  }

  // Add a bookmark
  Future<int> addBookmark(int userId, int mealId) async {
    final db = await _databaseHelper.database;

    // Check if already bookmarked
    final existing = await db.query(
      'bookmarks',
      where: 'user_id = ? AND meal_id = ?',
      whereArgs: [userId, mealId],
    );

    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    return await db.insert('bookmarks', {
      'user_id': userId,
      'meal_id': mealId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Remove a bookmark
  Future<int> removeBookmark(int userId, int mealId) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'bookmarks',
      where: 'user_id = ? AND meal_id = ?',
      whereArgs: [userId, mealId],
    );
  }

  // Toggle bookmark
  Future<bool> toggleBookmark(int userId, int mealId) async {
    final isCurrentlyBookmarked = await isBookmarked(userId, mealId);
    if (isCurrentlyBookmarked) {
      await removeBookmark(userId, mealId);
      return false;
    } else {
      await addBookmark(userId, mealId);
      return true;
    }
  }

  // Get bookmark count for a user
  Future<int> getBookmarkCount(int userId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM bookmarks WHERE user_id = ?',
      [userId],
    );
    return result.first['count'] as int;
  }
}
