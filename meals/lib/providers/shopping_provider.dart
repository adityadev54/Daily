import 'package:flutter/foundation.dart';
import '../data/models/shopping_item.dart';
import '../data/repositories/shopping_repository.dart';

class ShoppingProvider extends ChangeNotifier {
  final ShoppingRepository _repository = ShoppingRepository();

  List<ShoppingItem> _items = [];
  Map<String, List<ShoppingItem>> _groupedItems = {};
  bool _isLoading = false;

  List<ShoppingItem> get items => _items;
  Map<String, List<ShoppingItem>> get groupedItems => _groupedItems;
  bool get isLoading => _isLoading;

  int get totalCount => _items.length;
  int get checkedCount => _items.where((i) => i.isChecked).length;
  int get uncheckedCount => _items.where((i) => !i.isChecked).length;

  Future<void> loadItems(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _repository.getShoppingItems(userId);
      _groupedItems = await _repository.getShoppingItemsByCategory(userId);
    } catch (e) {
      debugPrint('Error loading shopping items: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addItem(ShoppingItem item) async {
    try {
      await _repository.addShoppingItem(item);
      await loadItems(item.userId);
    } catch (e) {
      debugPrint('Error adding shopping item: $e');
    }
  }

  Future<void> addItemsFromIngredients(
    int userId,
    List<String> ingredients,
    int? mealId,
  ) async {
    try {
      await _repository.addShoppingItemsFromIngredients(
        userId,
        ingredients,
        mealId,
      );
      await loadItems(userId);
    } catch (e) {
      debugPrint('Error adding ingredients to shopping list: $e');
    }
  }

  Future<void> toggleItem(ShoppingItem item) async {
    try {
      await _repository.toggleItemChecked(item.id!, !item.isChecked);
      // Update local state immediately for responsiveness
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[index] = item.copyWith(isChecked: !item.isChecked);
        _updateGroupedItems();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling shopping item: $e');
    }
  }

  Future<void> deleteItem(int itemId, int userId) async {
    try {
      await _repository.deleteShoppingItem(itemId);
      _items.removeWhere((i) => i.id == itemId);
      _updateGroupedItems();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting shopping item: $e');
    }
  }

  Future<void> clearCheckedItems(int userId) async {
    try {
      await _repository.clearCheckedItems(userId);
      _items.removeWhere((i) => i.isChecked);
      _updateGroupedItems();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing checked items: $e');
    }
  }

  Future<void> clearAllItems(int userId) async {
    try {
      await _repository.clearAllItems(userId);
      _items.clear();
      _groupedItems.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing all items: $e');
    }
  }

  void _updateGroupedItems() {
    _groupedItems.clear();
    for (final item in _items) {
      final category = item.category ?? 'Other';
      _groupedItems.putIfAbsent(category, () => []);
      _groupedItems[category]!.add(item);
    }
  }
}
