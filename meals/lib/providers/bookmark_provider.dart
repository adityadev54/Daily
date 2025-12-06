import 'package:flutter/foundation.dart';
import '../data/models/bookmark.dart';
import '../data/models/meal.dart';
import '../data/repositories/bookmark_repository.dart';

class BookmarkProvider extends ChangeNotifier {
  final BookmarkRepository _repository = BookmarkRepository();

  List<Bookmark> _bookmarks = [];
  List<Meal> _bookmarkedMeals = [];
  final Set<int> _bookmarkedMealIds = {};
  bool _isLoading = false;

  List<Bookmark> get bookmarks => _bookmarks;
  List<Meal> get bookmarkedMeals => _bookmarkedMeals;
  bool get isLoading => _isLoading;
  int get count => _bookmarks.length;

  bool isBookmarked(int mealId) => _bookmarkedMealIds.contains(mealId);

  Future<void> loadBookmarks(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _bookmarks = await _repository.getBookmarks(userId);
      _bookmarkedMeals = await _repository.getBookmarkedMeals(userId);
      _bookmarkedMealIds.clear();
      _bookmarkedMealIds.addAll(_bookmarks.map((b) => b.mealId));
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> toggleBookmark(int userId, int mealId, [Meal? meal]) async {
    try {
      final isNowBookmarked = await _repository.toggleBookmark(userId, mealId);

      if (isNowBookmarked) {
        _bookmarkedMealIds.add(mealId);
        if (meal != null) {
          _bookmarkedMeals.insert(0, meal);
        }
      } else {
        _bookmarkedMealIds.remove(mealId);
        _bookmarkedMeals.removeWhere((m) => m.id == mealId);
      }

      notifyListeners();
      return isNowBookmarked;
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
      return false;
    }
  }

  Future<void> addBookmark(int userId, int mealId, [Meal? meal]) async {
    try {
      await _repository.addBookmark(userId, mealId);
      _bookmarkedMealIds.add(mealId);
      if (meal != null && !_bookmarkedMeals.any((m) => m.id == mealId)) {
        _bookmarkedMeals.insert(0, meal);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding bookmark: $e');
    }
  }

  Future<void> removeBookmark(int userId, int mealId) async {
    try {
      await _repository.removeBookmark(userId, mealId);
      _bookmarkedMealIds.remove(mealId);
      _bookmarkedMeals.removeWhere((m) => m.id == mealId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing bookmark: $e');
    }
  }
}
