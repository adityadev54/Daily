import 'meal.dart';

class MealPlan {
  final int? id;
  final int userId;
  final int mealId;
  final int dayOfWeek; // 0-6 (Monday-Sunday)
  final String mealType; // breakfast, lunch, dinner, snack
  final String weekStartDate;
  final Meal? meal;

  MealPlan({
    this.id,
    required this.userId,
    required this.mealId,
    required this.dayOfWeek,
    required this.mealType,
    required this.weekStartDate,
    this.meal,
  });

  factory MealPlan.fromMap(Map<String, dynamic> map, {Meal? meal}) {
    return MealPlan(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      mealId: map['meal_id'] as int,
      dayOfWeek: map['day_of_week'] as int,
      mealType: map['meal_type'] as String,
      weekStartDate: map['week_start_date'] as String,
      meal: meal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'meal_id': mealId,
      'day_of_week': dayOfWeek,
      'meal_type': mealType,
      'week_start_date': weekStartDate,
    };
  }

  MealPlan copyWith({
    int? id,
    int? userId,
    int? mealId,
    int? dayOfWeek,
    String? mealType,
    String? weekStartDate,
    Meal? meal,
  }) {
    return MealPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mealId: mealId ?? this.mealId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      mealType: mealType ?? this.mealType,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      meal: meal ?? this.meal,
    );
  }
}
