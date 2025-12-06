class BudgetEntry {
  final int? id;
  final int userId;
  final double amount;
  final String? category;
  final String? description;
  final int? mealId;
  final DateTime date;
  final DateTime createdAt;

  BudgetEntry({
    this.id,
    required this.userId,
    required this.amount,
    this.category,
    this.description,
    this.mealId,
    required this.date,
    required this.createdAt,
  });

  factory BudgetEntry.fromMap(Map<String, dynamic> map) {
    return BudgetEntry(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String?,
      description: map['description'] as String?,
      mealId: map['meal_id'] as int?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'amount': amount,
      'category': category,
      'description': description,
      'meal_id': mealId,
      'date': date.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Common expense categories
  static const List<String> categories = [
    'Groceries',
    'Dining Out',
    'Takeout',
    'Snacks',
    'Beverages',
    'Kitchen Supplies',
    'Other',
  ];
}

class BudgetSettings {
  final int? id;
  final int userId;
  final double weeklyBudget;
  final String currency;

  BudgetSettings({
    this.id,
    required this.userId,
    this.weeklyBudget = 100.0,
    this.currency = 'USD',
  });

  factory BudgetSettings.fromMap(Map<String, dynamic> map) {
    return BudgetSettings(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      weeklyBudget: (map['weekly_budget'] as num?)?.toDouble() ?? 100.0,
      currency: map['currency'] as String? ?? 'USD',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'weekly_budget': weeklyBudget,
      'currency': currency,
    };
  }

  BudgetSettings copyWith({
    int? id,
    int? userId,
    double? weeklyBudget,
    String? currency,
  }) {
    return BudgetSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weeklyBudget: weeklyBudget ?? this.weeklyBudget,
      currency: currency ?? this.currency,
    );
  }

  /// Common currencies
  static const List<String> currencies = [
    'USD',
    'EUR',
    'GBP',
    'CAD',
    'AUD',
    'INR',
    'JPY',
    'CNY',
  ];

  /// Get currency symbol
  String get currencySymbol {
    return switch (currency) {
      'USD' => '\$',
      'EUR' => '€',
      'GBP' => '£',
      'CAD' => 'C\$',
      'AUD' => 'A\$',
      'INR' => '₹',
      'JPY' => '¥',
      'CNY' => '¥',
      _ => '\$',
    };
  }
}
