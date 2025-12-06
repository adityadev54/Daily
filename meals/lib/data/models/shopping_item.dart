class ShoppingItem {
  final int? id;
  final int userId;
  final String name;
  final String? category;
  final String? quantity;
  final bool isChecked;
  final int? mealId;
  final DateTime createdAt;

  ShoppingItem({
    this.id,
    required this.userId,
    required this.name,
    this.category,
    this.quantity,
    this.isChecked = false,
    this.mealId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      category: map['category'] as String?,
      quantity: map['quantity'] as String?,
      isChecked: (map['is_checked'] as int?) == 1,
      mealId: map['meal_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'is_checked': isChecked ? 1 : 0,
      'meal_id': mealId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ShoppingItem copyWith({
    int? id,
    int? userId,
    String? name,
    String? category,
    String? quantity,
    bool? isChecked,
    int? mealId,
    DateTime? createdAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      isChecked: isChecked ?? this.isChecked,
      mealId: mealId ?? this.mealId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Category detection from ingredient name
  static String detectCategory(String ingredient) {
    final lower = ingredient.toLowerCase();

    // Produce
    if (_matchesAny(lower, [
      'apple',
      'banana',
      'orange',
      'lemon',
      'lime',
      'berry',
      'grape',
      'mango',
      'peach',
      'pear',
      'melon',
      'fruit',
    ])) {
      return 'Fruits';
    }
    if (_matchesAny(lower, [
      'lettuce',
      'spinach',
      'kale',
      'tomato',
      'onion',
      'garlic',
      'carrot',
      'celery',
      'pepper',
      'cucumber',
      'broccoli',
      'potato',
      'mushroom',
      'avocado',
      'corn',
      'vegetable',
      'zucchini',
      'eggplant',
    ])) {
      return 'Vegetables';
    }

    // Proteins
    if (_matchesAny(lower, [
      'chicken',
      'beef',
      'pork',
      'turkey',
      'lamb',
      'meat',
      'steak',
      'ground',
    ])) {
      return 'Meat';
    }
    if (_matchesAny(lower, [
      'salmon',
      'tuna',
      'fish',
      'shrimp',
      'seafood',
      'cod',
      'tilapia',
    ])) {
      return 'Seafood';
    }

    // Dairy
    if (_matchesAny(lower, [
      'milk',
      'cheese',
      'yogurt',
      'butter',
      'cream',
      'egg',
      'dairy',
    ])) {
      return 'Dairy & Eggs';
    }

    // Grains
    if (_matchesAny(lower, [
      'bread',
      'pasta',
      'rice',
      'noodle',
      'flour',
      'oat',
      'cereal',
      'tortilla',
      'grain',
      'quinoa',
    ])) {
      return 'Grains & Bread';
    }

    // Pantry
    if (_matchesAny(lower, [
      'oil',
      'vinegar',
      'sauce',
      'salt',
      'pepper',
      'spice',
      'sugar',
      'honey',
      'syrup',
      'broth',
      'stock',
      'can',
      'bean',
      'chickpea',
      'lentil',
    ])) {
      return 'Pantry';
    }

    // Condiments
    if (_matchesAny(lower, [
      'ketchup',
      'mustard',
      'mayo',
      'dressing',
      'salsa',
      'soy sauce',
      'hot sauce',
    ])) {
      return 'Condiments';
    }

    // Frozen
    if (_matchesAny(lower, ['frozen', 'ice cream'])) {
      return 'Frozen';
    }

    // Beverages
    if (_matchesAny(lower, [
      'juice',
      'water',
      'soda',
      'coffee',
      'tea',
      'wine',
      'beer',
      'drink',
    ])) {
      return 'Beverages';
    }

    // Snacks
    if (_matchesAny(lower, [
      'chip',
      'cracker',
      'nut',
      'snack',
      'granola',
      'chocolate',
      'candy',
    ])) {
      return 'Snacks';
    }

    return 'Other';
  }

  static bool _matchesAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
}
