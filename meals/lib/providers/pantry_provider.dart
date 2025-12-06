import 'package:flutter/foundation.dart';
import '../data/models/pantry_item.dart';
import '../data/repositories/pantry_repository.dart';

class PantryProvider with ChangeNotifier {
  final PantryRepository _repository = PantryRepository();

  List<PantryItem> _items = [];
  List<PantryItem> _lowStockItems = [];
  List<PantryItem> _expiringItems = [];
  bool _isLoading = false;
  String? _selectedCategory;

  List<PantryItem> get items => _selectedCategory == null
      ? _items
      : _items.where((i) => i.category == _selectedCategory).toList();
  List<PantryItem> get allItems => _items;
  List<PantryItem> get lowStockItems => _lowStockItems;
  List<PantryItem> get expiringItems => _expiringItems;
  bool get isLoading => _isLoading;
  String? get selectedCategory => _selectedCategory;

  /// Total item count
  int get itemCount => _items.length;

  /// Count of expiring items
  int get expiringCount => _expiringItems.length;

  /// Count of low stock items
  int get lowStockCount => _lowStockItems.length;

  /// Get items grouped by category
  Map<String, List<PantryItem>> get itemsByCategory {
    final Map<String, List<PantryItem>> grouped = {};
    for (final item in _items) {
      final category = item.category ?? 'Other';
      grouped.putIfAbsent(category, () => []).add(item);
    }
    return grouped;
  }

  /// Get count of items needing attention
  int get attentionCount => _lowStockItems.length + _expiringItems.length;

  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> loadItems(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _repository.getPantryItems(userId);
      _lowStockItems = await _repository.getLowStockItems(userId);
      _expiringItems = await _repository.getExpiringItems(userId);
    } catch (e) {
      debugPrint('Error loading pantry items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addItem(PantryItem item) async {
    final id = await _repository.addItem(item);
    if (id != null) {
      final newItem = item.copyWith(id: id);
      _items.add(newItem);
      _sortItems();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> updateItem(PantryItem item) async {
    final success = await _repository.updateItem(item);
    if (success) {
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[index] = item;
        _sortItems();
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  Future<bool> deleteItem(int id) async {
    final success = await _repository.deleteItem(id);
    if (success) {
      _items.removeWhere((i) => i.id == id);
      _lowStockItems.removeWhere((i) => i.id == id);
      _expiringItems.removeWhere((i) => i.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> toggleLowStock(int id) async {
    final item = _items.firstWhere((i) => i.id == id);
    final newIsLow = !item.isLow;

    final success = await _repository.toggleLowStock(id, newIsLow);
    if (success) {
      final index = _items.indexWhere((i) => i.id == id);
      if (index != -1) {
        _items[index] = item.copyWith(
          isLow: newIsLow,
          updatedAt: DateTime.now(),
        );

        if (newIsLow) {
          _lowStockItems.add(_items[index]);
        } else {
          _lowStockItems.removeWhere((i) => i.id == id);
        }
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  Future<List<PantryItem>> search(int userId, String query) async {
    if (query.isEmpty) return _items;
    return await _repository.searchItems(userId, query);
  }

  /// Add items from shopping list when bought
  Future<void> addFromShopping(int userId, List<String> items) async {
    await _repository.addItemsFromShopping(userId, items);
    await loadItems(userId);
  }

  /// Check if an ingredient is in pantry
  bool hasIngredient(String ingredient) {
    final lower = ingredient.toLowerCase();
    return _items.any(
      (item) =>
          item.name.toLowerCase().contains(lower) ||
          lower.contains(item.name.toLowerCase()),
    );
  }

  /// Get missing ingredients for a meal
  List<String> getMissingIngredients(List<String> ingredients) {
    return ingredients.where((ing) => !hasIngredient(ing)).toList();
  }

  void _sortItems() {
    _items.sort((a, b) {
      // First by category
      final catCompare = (a.category ?? 'ZZZ').compareTo(b.category ?? 'ZZZ');
      if (catCompare != 0) return catCompare;
      // Then by name
      return a.name.compareTo(b.name);
    });
  }

  void clear() {
    _items = [];
    _lowStockItems = [];
    _expiringItems = [];
    _selectedCategory = null;
    notifyListeners();
  }
}
