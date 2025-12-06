class PantryItem {
  final int? id;
  final int userId;
  final String name;
  final String? category;
  final String? quantity;
  final String? unit;
  final DateTime? expiryDate;
  final bool isLow;
  final DateTime createdAt;
  final DateTime updatedAt;

  PantryItem({
    this.id,
    required this.userId,
    required this.name,
    this.category,
    this.quantity,
    this.unit,
    this.expiryDate,
    this.isLow = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PantryItem.fromMap(Map<String, dynamic> map) {
    return PantryItem(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      category: map['category'] as String?,
      quantity: map['quantity'] as String?,
      unit: map['unit'] as String?,
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'] as String)
          : null,
      isLow: (map['is_low'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'expiry_date': expiryDate?.toIso8601String(),
      'is_low': isLow ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PantryItem copyWith({
    int? id,
    int? userId,
    String? name,
    String? category,
    String? quantity,
    String? unit,
    DateTime? expiryDate,
    bool? isLow,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PantryItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      isLow: isLow ?? this.isLow,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 3 && daysUntilExpiry >= 0;
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  /// Common pantry categories
  static const List<String> categories = [
    'Produce',
    'Dairy',
    'Meat & Seafood',
    'Grains & Pasta',
    'Canned Goods',
    'Condiments',
    'Spices',
    'Snacks',
    'Beverages',
    'Frozen',
    'Bakery',
    'Other',
  ];

  /// Common units
  static const List<String> units = [
    'pieces',
    'g',
    'kg',
    'ml',
    'L',
    'cups',
    'tbsp',
    'tsp',
    'oz',
    'lb',
    'cans',
    'bottles',
    'packages',
  ];
}
