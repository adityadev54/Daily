import '../database/database_helper.dart';
import '../models/pantry_item.dart';

class PantryRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<List<PantryItem>> getPantryItems(int userId) async {
    try {
      final db = await _db.database;
      final results = await db.query(
        'pantry_items',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'category, name',
      );
      return results.map((map) => PantryItem.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<PantryItem>> getPantryItemsByCategory(
    int userId,
    String category,
  ) async {
    try {
      final db = await _db.database;
      final results = await db.query(
        'pantry_items',
        where: 'user_id = ? AND category = ?',
        whereArgs: [userId, category],
        orderBy: 'name',
      );
      return results.map((map) => PantryItem.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<PantryItem>> getLowStockItems(int userId) async {
    try {
      final db = await _db.database;
      final results = await db.query(
        'pantry_items',
        where: 'user_id = ? AND is_low = 1',
        whereArgs: [userId],
        orderBy: 'name',
      );
      return results.map((map) => PantryItem.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<PantryItem>> getExpiringItems(
    int userId, {
    int withinDays = 7,
  }) async {
    try {
      final db = await _db.database;
      final now = DateTime.now();
      final futureDate = now.add(Duration(days: withinDays));

      final results = await db.query(
        'pantry_items',
        where:
            'user_id = ? AND expiry_date IS NOT NULL AND expiry_date <= ? AND expiry_date >= ?',
        whereArgs: [
          userId,
          futureDate.toIso8601String(),
          now.toIso8601String(),
        ],
        orderBy: 'expiry_date',
      );
      return results.map((map) => PantryItem.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<int?> addItem(PantryItem item) async {
    try {
      final db = await _db.database;
      return await db.insert('pantry_items', item.toMap());
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateItem(PantryItem item) async {
    try {
      if (item.id == null) return false;
      final db = await _db.database;
      await db.update(
        'pantry_items',
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteItem(int id) async {
    try {
      final db = await _db.database;
      await db.delete('pantry_items', where: 'id = ?', whereArgs: [id]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleLowStock(int id, bool isLow) async {
    try {
      final db = await _db.database;
      await db.update(
        'pantry_items',
        {
          'is_low': isLow ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<PantryItem>> searchItems(int userId, String query) async {
    try {
      final db = await _db.database;
      final results = await db.query(
        'pantry_items',
        where: 'user_id = ? AND name LIKE ?',
        whereArgs: [userId, '%$query%'],
        orderBy: 'name',
      );
      return results.map((map) => PantryItem.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Add multiple items from a shopping list (when bought)
  Future<void> addItemsFromShopping(int userId, List<String> items) async {
    final now = DateTime.now();
    for (final item in items) {
      final pantryItem = PantryItem(
        userId: userId,
        name: item,
        category: _guessCategory(item),
        createdAt: now,
        updatedAt: now,
      );
      await addItem(pantryItem);
    }
  }

  String? _guessCategory(String itemName) {
    final lower = itemName.toLowerCase();

    if (_matchesAny(lower, [
      'milk',
      'cheese',
      'butter',
      'yogurt',
      'cream',
      'egg',
    ])) {
      return 'Dairy';
    }
    if (_matchesAny(lower, [
      'chicken',
      'beef',
      'pork',
      'fish',
      'salmon',
      'shrimp',
      'meat',
    ])) {
      return 'Meat & Seafood';
    }
    if (_matchesAny(lower, [
      'apple',
      'banana',
      'tomato',
      'onion',
      'carrot',
      'lettuce',
      'fruit',
      'vegetable',
    ])) {
      return 'Produce';
    }
    if (_matchesAny(lower, [
      'rice',
      'pasta',
      'bread',
      'flour',
      'oats',
      'noodle',
    ])) {
      return 'Grains & Pasta';
    }
    if (_matchesAny(lower, ['can', 'beans', 'soup', 'sauce', 'tomato paste'])) {
      return 'Canned Goods';
    }
    if (_matchesAny(lower, [
      'salt',
      'pepper',
      'spice',
      'herb',
      'cinnamon',
      'cumin',
    ])) {
      return 'Spices';
    }
    if (_matchesAny(lower, [
      'ketchup',
      'mustard',
      'mayo',
      'soy sauce',
      'oil',
      'vinegar',
    ])) {
      return 'Condiments';
    }
    if (_matchesAny(lower, ['frozen', 'ice cream'])) {
      return 'Frozen';
    }

    return 'Other';
  }

  bool _matchesAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
}
