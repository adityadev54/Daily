import '../database/database_helper.dart';
import '../models/shopping_item.dart';

class ShoppingRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Get all shopping items for a user
  Future<List<ShoppingItem>> getShoppingItems(int userId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'shopping_items',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'category ASC, name ASC',
    );
    return maps.map((map) => ShoppingItem.fromMap(map)).toList();
  }

  // Get shopping items grouped by category
  Future<Map<String, List<ShoppingItem>>> getShoppingItemsByCategory(
    int userId,
  ) async {
    final items = await getShoppingItems(userId);
    final grouped = <String, List<ShoppingItem>>{};

    for (final item in items) {
      final category = item.category ?? 'Other';
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(item);
    }

    return grouped;
  }

  // Add a shopping item
  Future<int> addShoppingItem(ShoppingItem item) async {
    final db = await _databaseHelper.database;
    final map = item.toMap();
    map.remove('id');
    return await db.insert('shopping_items', map);
  }

  // Add multiple shopping items (bulk add from meal ingredients)
  Future<void> addShoppingItemsFromIngredients(
    int userId,
    List<String> ingredients,
    int? mealId,
  ) async {
    final db = await _databaseHelper.database;
    final batch = db.batch();

    for (final ingredient in ingredients) {
      // Check if item already exists
      final existing = await db.query(
        'shopping_items',
        where: 'user_id = ? AND LOWER(name) = LOWER(?)',
        whereArgs: [userId, ingredient.trim()],
      );

      if (existing.isEmpty) {
        final category = ShoppingItem.detectCategory(ingredient);
        batch.insert('shopping_items', {
          'user_id': userId,
          'name': ingredient.trim(),
          'category': category,
          'is_checked': 0,
          'meal_id': mealId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }

    await batch.commit(noResult: true);
  }

  // Update shopping item (toggle checked, etc.)
  Future<int> updateShoppingItem(ShoppingItem item) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'shopping_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // Toggle item checked status
  Future<void> toggleItemChecked(int itemId, bool isChecked) async {
    final db = await _databaseHelper.database;
    await db.update(
      'shopping_items',
      {'is_checked': isChecked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  // Delete a shopping item
  Future<int> deleteShoppingItem(int itemId) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'shopping_items',
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  // Clear all checked items
  Future<int> clearCheckedItems(int userId) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'shopping_items',
      where: 'user_id = ? AND is_checked = 1',
      whereArgs: [userId],
    );
  }

  // Clear all items
  Future<int> clearAllItems(int userId) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'shopping_items',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // Get unchecked items count
  Future<int> getUncheckedCount(int userId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM shopping_items WHERE user_id = ? AND is_checked = 0',
      [userId],
    );
    return result.first['count'] as int;
  }
}
