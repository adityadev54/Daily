class UserPreferences {
  final int? id;
  final int userId;
  final String dietType;
  final List<String> allergies;
  final List<String> cuisinePreferences;
  // New preferences
  final int householdSize;
  final String cookingExperience;
  final String preferredStore;
  final List<String> nutritionGoals;
  final List<String> dislikedIngredients;

  UserPreferences({
    this.id,
    required this.userId,
    this.dietType = 'None',
    this.allergies = const [],
    this.cuisinePreferences = const [],
    this.householdSize = 1,
    this.cookingExperience = 'Intermediate',
    this.preferredStore = 'Any',
    this.nutritionGoals = const [],
    this.dislikedIngredients = const [],
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      dietType: map['diet_type'] as String? ?? 'None',
      allergies:
          (map['allergies'] as String?)
              ?.split(',')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      cuisinePreferences:
          (map['cuisine_preferences'] as String?)
              ?.split(',')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      householdSize: map['household_size'] as int? ?? 1,
      cookingExperience: map['cooking_experience'] as String? ?? 'Intermediate',
      preferredStore: map['preferred_store'] as String? ?? 'Any',
      nutritionGoals:
          (map['nutrition_goals'] as String?)
              ?.split(',')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      dislikedIngredients:
          (map['disliked_ingredients'] as String?)
              ?.split(',')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'diet_type': dietType,
      'allergies': allergies.join(','),
      'cuisine_preferences': cuisinePreferences.join(','),
      'household_size': householdSize,
      'cooking_experience': cookingExperience,
      'preferred_store': preferredStore,
      'nutrition_goals': nutritionGoals.join(','),
      'disliked_ingredients': dislikedIngredients.join(','),
    };
  }

  UserPreferences copyWith({
    int? id,
    int? userId,
    String? dietType,
    List<String>? allergies,
    List<String>? cuisinePreferences,
    int? householdSize,
    String? cookingExperience,
    String? preferredStore,
    List<String>? nutritionGoals,
    List<String>? dislikedIngredients,
  }) {
    return UserPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dietType: dietType ?? this.dietType,
      allergies: allergies ?? this.allergies,
      cuisinePreferences: cuisinePreferences ?? this.cuisinePreferences,
      householdSize: householdSize ?? this.householdSize,
      cookingExperience: cookingExperience ?? this.cookingExperience,
      preferredStore: preferredStore ?? this.preferredStore,
      nutritionGoals: nutritionGoals ?? this.nutritionGoals,
      dislikedIngredients: dislikedIngredients ?? this.dislikedIngredients,
    );
  }
}
