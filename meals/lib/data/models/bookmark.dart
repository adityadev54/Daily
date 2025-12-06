class Bookmark {
  final int? id;
  final int userId;
  final int mealId;
  final DateTime createdAt;

  Bookmark({
    this.id,
    required this.userId,
    required this.mealId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      mealId: map['meal_id'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'meal_id': mealId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Bookmark copyWith({int? id, int? userId, int? mealId, DateTime? createdAt}) {
    return Bookmark(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mealId: mealId ?? this.mealId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
