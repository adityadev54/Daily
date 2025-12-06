class Meal {
  final int? id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int? calories;
  final int? prepTime;
  final int? cookTime;
  final String? difficulty;
  final String mealType;
  final String? cuisine;
  final String? dietType;
  final String? ingredients;
  final String? instructions;
  // Nutrition fields (per serving)
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fiber;
  final double? sugar;
  final double? sodium;
  final int? servings;
  // Tags and search term
  final String? tags;
  final String? imageSearchTerm;

  Meal({
    this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.calories,
    this.prepTime,
    this.cookTime,
    this.difficulty,
    required this.mealType,
    this.cuisine,
    this.dietType,
    this.ingredients,
    this.instructions,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
    this.servings,
    this.tags,
    this.imageSearchTerm,
  });

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      calories: map['calories'] as int?,
      prepTime: map['prep_time'] as int?,
      cookTime: map['cook_time'] as int?,
      difficulty: map['difficulty'] as String?,
      mealType: map['meal_type'] as String,
      cuisine: map['cuisine'] as String?,
      dietType: map['diet_type'] as String?,
      ingredients: map['ingredients'] as String?,
      instructions: map['instructions'] as String?,
      protein: map['protein'] != null
          ? (map['protein'] as num).toDouble()
          : null,
      carbs: map['carbs'] != null ? (map['carbs'] as num).toDouble() : null,
      fat: map['fat'] != null ? (map['fat'] as num).toDouble() : null,
      fiber: map['fiber'] != null ? (map['fiber'] as num).toDouble() : null,
      sugar: map['sugar'] != null ? (map['sugar'] as num).toDouble() : null,
      sodium: map['sodium'] != null ? (map['sodium'] as num).toDouble() : null,
      servings: map['servings'] as int?,
      tags: map['tags'] as String?,
      imageSearchTerm: map['image_search_term'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'calories': calories,
      'prep_time': prepTime,
      'cook_time': cookTime,
      'difficulty': difficulty,
      'meal_type': mealType,
      'cuisine': cuisine,
      'diet_type': dietType,
      'ingredients': ingredients,
      'instructions': instructions,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'servings': servings,
      'tags': tags,
      'image_search_term': imageSearchTerm,
    };
  }

  List<String> get ingredientsList {
    if (ingredients == null || ingredients!.isEmpty) return [];
    return ingredients!.split(',').map((s) => s.trim()).toList();
  }

  List<String> get tagsList {
    if (tags == null || tags!.isEmpty) return [];
    return tags!.split(',').map((s) => s.trim()).toList();
  }

  /// Calculate health score based on nutrition values (0-100)
  int get healthScore {
    if (calories == null) return 50; // Default score if no data

    int score = 50; // Start with neutral score

    // Protein (higher is better for most meals)
    if (protein != null) {
      if (protein! >= 20)
        score += 10;
      else if (protein! >= 10)
        score += 5;
    }

    // Fiber (higher is better)
    if (fiber != null) {
      if (fiber! >= 8)
        score += 15;
      else if (fiber! >= 5)
        score += 10;
      else if (fiber! >= 3)
        score += 5;
    }

    // Sugar (lower is better)
    if (sugar != null) {
      if (sugar! <= 5)
        score += 10;
      else if (sugar! <= 10)
        score += 5;
      else if (sugar! > 20)
        score -= 10;
    }

    // Fat balance (moderate is good)
    if (fat != null && calories != null) {
      final fatCaloriePercent = (fat! * 9 / calories!) * 100;
      if (fatCaloriePercent >= 20 && fatCaloriePercent <= 35)
        score += 10;
      else if (fatCaloriePercent > 40)
        score -= 5;
    }

    // Calories (reasonable range based on meal type)
    if (calories != null) {
      final isReasonable = switch (mealType.toLowerCase()) {
        'breakfast' => calories! >= 200 && calories! <= 500,
        'lunch' => calories! >= 300 && calories! <= 700,
        'dinner' => calories! >= 400 && calories! <= 800,
        'snack' => calories! >= 50 && calories! <= 300,
        _ => calories! >= 200 && calories! <= 700,
      };
      if (isReasonable) score += 5;
    }

    return score.clamp(0, 100);
  }

  /// Get health score label
  String get healthScoreLabel {
    final score = healthScore;
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Poor';
  }

  Meal copyWith({
    int? id,
    String? name,
    String? description,
    String? imageUrl,
    int? calories,
    int? prepTime,
    int? cookTime,
    String? difficulty,
    String? mealType,
    String? cuisine,
    String? dietType,
    String? ingredients,
    String? instructions,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sugar,
    double? sodium,
    int? servings,
    String? tags,
    String? imageSearchTerm,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      calories: calories ?? this.calories,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      difficulty: difficulty ?? this.difficulty,
      mealType: mealType ?? this.mealType,
      cuisine: cuisine ?? this.cuisine,
      dietType: dietType ?? this.dietType,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      sodium: sodium ?? this.sodium,
      servings: servings ?? this.servings,
      tags: tags ?? this.tags,
      imageSearchTerm: imageSearchTerm ?? this.imageSearchTerm,
    );
  }
}
