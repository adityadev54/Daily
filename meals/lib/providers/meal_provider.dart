import 'package:flutter/material.dart';
import '../../data/models/meal.dart';
import '../../data/models/meal_plan.dart';
import '../../data/repositories/meal_repository.dart';

class MealProvider extends ChangeNotifier {
  final MealRepository _mealRepository = MealRepository();

  List<Meal> _allMeals = [];
  List<Meal> _filteredMeals = [];
  List<MealPlan> _weekPlan = [];
  bool _isLoading = false;
  String? _error;
  DateTime _selectedWeek = DateTime.now();

  List<Meal> get allMeals => _allMeals;
  List<Meal> get filteredMeals => _filteredMeals;
  List<MealPlan> get weekPlan => _weekPlan;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedWeek => _selectedWeek;

  String get currentWeekStart =>
      _mealRepository.getWeekStartDate(_selectedWeek);

  Future<void> loadMeals() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allMeals = await _mealRepository.getAllMeals();
      _filteredMeals = _allMeals;
      _error = null;
    } catch (e) {
      _error = 'Failed to load meals';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMealPlan(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _weekPlan = await _mealRepository.getMealPlan(userId, currentWeekStart);
      _error = null;
    } catch (e) {
      _error = 'Failed to load meal plan';
    }

    _isLoading = false;
    notifyListeners();
  }

  void filterByMealType(String? mealType) {
    if (mealType == null || mealType.isEmpty) {
      _filteredMeals = _allMeals;
    } else {
      _filteredMeals = _allMeals
          .where(
            (meal) => meal.mealType.toLowerCase() == mealType.toLowerCase(),
          )
          .toList();
    }
    notifyListeners();
  }

  void filterByDietType(String? dietType) {
    if (dietType == null || dietType.isEmpty || dietType == 'None') {
      _filteredMeals = _allMeals;
    } else {
      _filteredMeals = _allMeals
          .where((meal) => meal.dietType == dietType)
          .toList();
    }
    notifyListeners();
  }

  void filterByCuisine(String? cuisine) {
    if (cuisine == null || cuisine.isEmpty) {
      _filteredMeals = _allMeals;
    } else {
      _filteredMeals = _allMeals
          .where((meal) => meal.cuisine == cuisine)
          .toList();
    }
    notifyListeners();
  }

  void searchMeals(String query) {
    if (query.isEmpty) {
      _filteredMeals = _allMeals;
    } else {
      _filteredMeals = _allMeals.where((meal) {
        final nameLower = meal.name.toLowerCase();
        final descLower = meal.description?.toLowerCase() ?? '';
        final queryLower = query.toLowerCase();
        return nameLower.contains(queryLower) || descLower.contains(queryLower);
      }).toList();
    }
    notifyListeners();
  }

  List<Meal> getMealsByType(String mealType) {
    return _allMeals
        .where((meal) => meal.mealType.toLowerCase() == mealType.toLowerCase())
        .toList();
  }

  Future<bool> addMeal(Meal meal) async {
    final id = await _mealRepository.insertMeal(meal);
    if (id != null) {
      final newMeal = Meal(
        id: id,
        name: meal.name,
        description: meal.description,
        mealType: meal.mealType,
        calories: meal.calories,
        prepTime: meal.prepTime,
        cuisine: meal.cuisine,
        dietType: meal.dietType,
        ingredients: meal.ingredients,
        instructions: meal.instructions,
        imageUrl: meal.imageUrl,
      );
      _allMeals.add(newMeal);
      _filteredMeals = _allMeals;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteMeal(int id) async {
    final success = await _mealRepository.deleteMeal(id);
    if (success) {
      _allMeals.removeWhere((meal) => meal.id == id);
      _filteredMeals = _allMeals;
      notifyListeners();
    }
    return success;
  }

  Future<bool> addMealToPlan({
    required int userId,
    required int mealId,
    required int dayOfWeek,
    required String mealType,
  }) async {
    final success = await _mealRepository.addMealToPlan(
      userId: userId,
      mealId: mealId,
      dayOfWeek: dayOfWeek,
      mealType: mealType,
      weekStartDate: currentWeekStart,
    );

    if (success) {
      await loadMealPlan(userId);
    }

    return success;
  }

  Future<bool> removeMealFromPlan(int mealPlanId, int userId) async {
    final success = await _mealRepository.removeMealFromPlan(mealPlanId);

    if (success) {
      await loadMealPlan(userId);
    }

    return success;
  }

  Future<bool> clearWeekPlan(int userId) async {
    final success = await _mealRepository.clearWeekPlan(
      userId,
      currentWeekStart,
    );

    if (success) {
      _weekPlan = [];
      notifyListeners();
    }

    return success;
  }

  void setSelectedWeek(DateTime date) {
    _selectedWeek = date;
    notifyListeners();
  }

  void goToNextWeek() {
    _selectedWeek = _selectedWeek.add(const Duration(days: 7));
    notifyListeners();
  }

  void goToPreviousWeek() {
    _selectedWeek = _selectedWeek.subtract(const Duration(days: 7));
    notifyListeners();
  }

  void goToCurrentWeek() {
    _selectedWeek = DateTime.now();
    notifyListeners();
  }

  List<MealPlan> getMealsForDay(int dayOfWeek) {
    return _weekPlan.where((plan) => plan.dayOfWeek == dayOfWeek).toList();
  }

  MealPlan? getMealForDayAndType(int dayOfWeek, String mealType) {
    try {
      return _weekPlan.firstWhere(
        (plan) =>
            plan.dayOfWeek == dayOfWeek &&
            plan.mealType == mealType.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  String getWeekDateRange() {
    final start = _selectedWeek.subtract(
      Duration(days: _selectedWeek.weekday - 1),
    );
    final end = start.add(const Duration(days: 6));

    final startStr = '${_monthName(start.month)} ${start.day}';
    final endStr = '${_monthName(end.month)} ${end.day}';

    return '$startStr - $endStr';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  void resetFilters() {
    _filteredMeals = _allMeals;
    notifyListeners();
  }
}
