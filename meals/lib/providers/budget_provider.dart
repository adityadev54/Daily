import 'package:flutter/foundation.dart';
import '../data/models/budget.dart';
import '../data/repositories/budget_repository.dart';

class BudgetProvider with ChangeNotifier {
  final BudgetRepository _repository = BudgetRepository();

  BudgetSettings? _settings;
  List<BudgetEntry> _entries = [];
  double _weeklySpending = 0;
  double _monthlySpending = 0;
  Map<String, double> _categorySpending = {};
  bool _isLoading = false;

  BudgetSettings? get settings => _settings;
  List<BudgetEntry> get entries => _entries;
  double get weeklySpending => _weeklySpending;
  double get monthlySpending => _monthlySpending;
  Map<String, double> get categorySpending => _categorySpending;
  bool get isLoading => _isLoading;

  double get weeklyBudget => _settings?.weeklyBudget ?? 100.0;
  String get currency => _settings?.currency ?? 'USD';
  String get currencySymbol => _settings?.currencySymbol ?? '\$';

  /// Budget remaining this week
  double get weeklyRemaining => weeklyBudget - _weeklySpending;

  /// Weekly budget progress (0.0 to 1.0+)
  double get weeklyProgress =>
      weeklyBudget > 0 ? _weeklySpending / weeklyBudget : 0;

  /// Is over budget?
  bool get isOverBudget => _weeklySpending > weeklyBudget;

  /// Daily budget (weekly / 7)
  double get dailyBudget => weeklyBudget / 7;

  /// Estimated daily remaining for the week
  double get dailyRemaining {
    final now = DateTime.now();
    final daysLeft = 7 - now.weekday + 1;
    return daysLeft > 0 ? weeklyRemaining / daysLeft : 0;
  }

  Future<void> loadData(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _settings = await _repository.getBudgetSettings(userId);
      _entries = await _repository.getWeeklyEntries(userId);
      _weeklySpending = await _repository.getWeeklySpending(userId);
      _monthlySpending = await _repository.getMonthlySpending(userId);
      _categorySpending = await _repository.getSpendingByCategory(userId);
    } catch (e) {
      debugPrint('Error loading budget data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveSettings(BudgetSettings settings) async {
    final success = await _repository.saveBudgetSettings(settings);
    if (success) {
      _settings = settings;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> addEntry(BudgetEntry entry) async {
    final id = await _repository.addEntry(entry);
    if (id != null) {
      final newEntry = BudgetEntry(
        id: id,
        userId: entry.userId,
        amount: entry.amount,
        category: entry.category,
        description: entry.description,
        mealId: entry.mealId,
        date: entry.date,
        createdAt: entry.createdAt,
      );
      _entries.insert(0, newEntry);
      _weeklySpending += entry.amount;
      _monthlySpending += entry.amount;

      final category = entry.category ?? 'Other';
      _categorySpending[category] =
          (_categorySpending[category] ?? 0) + entry.amount;

      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteEntry(int id) async {
    final entry = _entries.firstWhere((e) => e.id == id);
    final success = await _repository.deleteEntry(id);
    if (success) {
      _entries.removeWhere((e) => e.id == id);
      _weeklySpending -= entry.amount;
      _monthlySpending -= entry.amount;

      final category = entry.category ?? 'Other';
      _categorySpending[category] =
          (_categorySpending[category] ?? 0) - entry.amount;
      if (_categorySpending[category]! <= 0) {
        _categorySpending.remove(category);
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  /// Quick add expense
  Future<bool> addQuickExpense(
    int userId,
    double amount,
    String? category,
    String? description,
  ) async {
    final entry = BudgetEntry(
      userId: userId,
      amount: amount,
      category: category ?? 'Groceries',
      description: description,
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );
    return addEntry(entry);
  }

  /// Get spending status message
  String get statusMessage {
    if (isOverBudget) {
      return 'Over budget by ${currencySymbol}${(_weeklySpending - weeklyBudget).toStringAsFixed(2)}';
    }
    if (weeklyProgress > 0.8) {
      return 'Almost at budget limit';
    }
    if (weeklyProgress > 0.5) {
      return 'On track for the week';
    }
    return 'Plenty of budget remaining';
  }

  void clear() {
    _settings = null;
    _entries = [];
    _weeklySpending = 0;
    _monthlySpending = 0;
    _categorySpending = {};
    notifyListeners();
  }
}
