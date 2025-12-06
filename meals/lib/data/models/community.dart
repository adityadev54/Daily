/// Community Models for Recipe Sharing Platform
/// These models support the "Kitchen Stories" concept with recipe journeys,
/// remixes, circles, and taste-based matching.

class CommunityUser {
  final int id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final TasteProfile? tasteProfile;
  final int recipeCount;
  final int followersCount;
  final int followingCount;
  final List<String> badges;
  final DateTime joinedAt;

  CommunityUser({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.tasteProfile,
    this.recipeCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.badges = const [],
    required this.joinedAt,
  });

  factory CommunityUser.fromJson(Map<String, dynamic> json) {
    return CommunityUser(
      id: json['id'],
      username: json['username'],
      displayName: json['display_name'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      tasteProfile: json['taste_profile'] != null
          ? TasteProfile.fromJson(json['taste_profile'])
          : null,
      recipeCount: json['recipe_count'] ?? 0,
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      badges: List<String>.from(json['badges'] ?? []),
      joinedAt: DateTime.parse(json['joined_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'display_name': displayName,
    'avatar_url': avatarUrl,
    'bio': bio,
    'taste_profile': tasteProfile?.toJson(),
    'recipe_count': recipeCount,
    'followers_count': followersCount,
    'following_count': followingCount,
    'badges': badges,
    'joined_at': joinedAt.toIso8601String(),
  };
}

/// Taste Profile for flavor-based matching
class TasteProfile {
  final int spiceLevel; // 1-5
  final int sweetnessLevel; // 1-5
  final List<String> favoriteCuisines;
  final List<String> dietaryPreferences;
  final List<String> dislikedIngredients;
  final List<String> favoriteIngredients;

  TasteProfile({
    this.spiceLevel = 3,
    this.sweetnessLevel = 3,
    this.favoriteCuisines = const [],
    this.dietaryPreferences = const [],
    this.dislikedIngredients = const [],
    this.favoriteIngredients = const [],
  });

  factory TasteProfile.fromJson(Map<String, dynamic> json) {
    return TasteProfile(
      spiceLevel: json['spice_level'] ?? 3,
      sweetnessLevel: json['sweetness_level'] ?? 3,
      favoriteCuisines: List<String>.from(json['favorite_cuisines'] ?? []),
      dietaryPreferences: List<String>.from(json['dietary_preferences'] ?? []),
      dislikedIngredients: List<String>.from(
        json['disliked_ingredients'] ?? [],
      ),
      favoriteIngredients: List<String>.from(
        json['favorite_ingredients'] ?? [],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'spice_level': spiceLevel,
    'sweetness_level': sweetnessLevel,
    'favorite_cuisines': favoriteCuisines,
    'dietary_preferences': dietaryPreferences,
    'disliked_ingredients': dislikedIngredients,
    'favorite_ingredients': favoriteIngredients,
  };

  double matchScore(TasteProfile other) {
    double score = 0;

    // Spice and sweetness similarity
    score += (5 - (spiceLevel - other.spiceLevel).abs()) * 5;
    score += (5 - (sweetnessLevel - other.sweetnessLevel).abs()) * 5;

    // Cuisine overlap
    final cuisineOverlap = favoriteCuisines
        .where((c) => other.favoriteCuisines.contains(c))
        .length;
    score += cuisineOverlap * 10;

    // Dietary compatibility
    final dietOverlap = dietaryPreferences
        .where((d) => other.dietaryPreferences.contains(d))
        .length;
    score += dietOverlap * 15;

    return score;
  }
}

/// Recipe Chapter - The cooking journey
class RecipeChapter {
  final int id;
  final CommunityUser author;
  final String title;
  final String? description;
  final List<ChapterStep> steps; // Before → Process → Result
  final List<String> tags;
  final String? cuisine;
  final int prepTime; // minutes
  final int cookTime; // minutes
  final int servings;
  final String difficulty; // easy, medium, hard
  final NutritionInfo? nutrition;
  final List<RecipeIngredient> ingredients;
  final int? originalRecipeId; // If this is a remix
  final List<RecipeRemix> remixes;
  final int likesCount;
  final int commentsCount;
  final int savesCount;
  final int cookCount; // How many people cooked this
  final bool isLiked;
  final bool isSaved;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RecipeChapter({
    required this.id,
    required this.author,
    required this.title,
    this.description,
    required this.steps,
    this.tags = const [],
    this.cuisine,
    this.prepTime = 0,
    this.cookTime = 0,
    this.servings = 2,
    this.difficulty = 'medium',
    this.nutrition,
    this.ingredients = const [],
    this.originalRecipeId,
    this.remixes = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.savesCount = 0,
    this.cookCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    required this.createdAt,
    this.updatedAt,
  });

  int get totalTime => prepTime + cookTime;

  bool get isRemix => originalRecipeId != null;

  factory RecipeChapter.fromJson(Map<String, dynamic> json) {
    return RecipeChapter(
      id: json['id'],
      author: CommunityUser.fromJson(json['author']),
      title: json['title'],
      description: json['description'],
      steps: (json['steps'] as List)
          .map((s) => ChapterStep.fromJson(s))
          .toList(),
      tags: List<String>.from(json['tags'] ?? []),
      cuisine: json['cuisine'],
      prepTime: json['prep_time'] ?? 0,
      cookTime: json['cook_time'] ?? 0,
      servings: json['servings'] ?? 2,
      difficulty: json['difficulty'] ?? 'medium',
      nutrition: json['nutrition'] != null
          ? NutritionInfo.fromJson(json['nutrition'])
          : null,
      ingredients:
          (json['ingredients'] as List?)
              ?.map((i) => RecipeIngredient.fromJson(i))
              .toList() ??
          [],
      originalRecipeId: json['original_recipe_id'],
      remixes:
          (json['remixes'] as List?)
              ?.map((r) => RecipeRemix.fromJson(r))
              .toList() ??
          [],
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      savesCount: json['saves_count'] ?? 0,
      cookCount: json['cook_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      isSaved: json['is_saved'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'author': author.toJson(),
    'title': title,
    'description': description,
    'steps': steps.map((s) => s.toJson()).toList(),
    'tags': tags,
    'cuisine': cuisine,
    'prep_time': prepTime,
    'cook_time': cookTime,
    'servings': servings,
    'difficulty': difficulty,
    'nutrition': nutrition?.toJson(),
    'ingredients': ingredients.map((i) => i.toJson()).toList(),
    'original_recipe_id': originalRecipeId,
    'remixes': remixes.map((r) => r.toJson()).toList(),
    'likes_count': likesCount,
    'comments_count': commentsCount,
    'saves_count': savesCount,
    'cook_count': cookCount,
    'is_liked': isLiked,
    'is_saved': isSaved,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}

/// A step in the recipe journey
class ChapterStep {
  final int order;
  final String type; // 'before', 'process', 'result', 'failed_attempt', 'tip'
  final String? title;
  final String? description;
  final String? mediaUrl;
  final String mediaType; // 'image', 'video'
  final String? voiceNoteUrl;
  final int? timerSeconds;

  ChapterStep({
    required this.order,
    required this.type,
    this.title,
    this.description,
    this.mediaUrl,
    this.mediaType = 'image',
    this.voiceNoteUrl,
    this.timerSeconds,
  });

  factory ChapterStep.fromJson(Map<String, dynamic> json) {
    return ChapterStep(
      order: json['order'],
      type: json['type'],
      title: json['title'],
      description: json['description'],
      mediaUrl: json['media_url'],
      mediaType: json['media_type'] ?? 'image',
      voiceNoteUrl: json['voice_note_url'],
      timerSeconds: json['timer_seconds'],
    );
  }

  Map<String, dynamic> toJson() => {
    'order': order,
    'type': type,
    'title': title,
    'description': description,
    'media_url': mediaUrl,
    'media_type': mediaType,
    'voice_note_url': voiceNoteUrl,
    'timer_seconds': timerSeconds,
  };
}

/// Recipe Ingredient
class RecipeIngredient {
  final String name;
  final double quantity;
  final String unit;
  final String? notes;
  final bool isOptional;
  final List<String>? substitutes;

  RecipeIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
    this.notes,
    this.isOptional = false,
    this.substitutes,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'],
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'],
      notes: json['notes'],
      isOptional: json['is_optional'] ?? false,
      substitutes: json['substitutes'] != null
          ? List<String>.from(json['substitutes'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'notes': notes,
    'is_optional': isOptional,
    'substitutes': substitutes,
  };
}

/// Nutrition Information
class NutritionInfo {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
  final double? sugar;
  final double? sodium;

  NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      calories: json['calories'],
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      fiber: json['fiber']?.toDouble(),
      sugar: json['sugar']?.toDouble(),
      sodium: json['sodium']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
    'sugar': sugar,
    'sodium': sodium,
  };
}

/// Recipe Remix - A variation of an original recipe
class RecipeRemix {
  final int id;
  final int originalRecipeId;
  final CommunityUser author;
  final String title;
  final String remixType; // 'vegan', 'budget', 'quick', 'healthy', 'custom'
  final String? description;
  final String? thumbnailUrl;
  final int likesCount;
  final DateTime createdAt;

  RecipeRemix({
    required this.id,
    required this.originalRecipeId,
    required this.author,
    required this.title,
    required this.remixType,
    this.description,
    this.thumbnailUrl,
    this.likesCount = 0,
    required this.createdAt,
  });

  factory RecipeRemix.fromJson(Map<String, dynamic> json) {
    return RecipeRemix(
      id: json['id'],
      originalRecipeId: json['original_recipe_id'],
      author: CommunityUser.fromJson(json['author']),
      title: json['title'],
      remixType: json['remix_type'],
      description: json['description'],
      thumbnailUrl: json['thumbnail_url'],
      likesCount: json['likes_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'original_recipe_id': originalRecipeId,
    'author': author.toJson(),
    'title': title,
    'remix_type': remixType,
    'description': description,
    'thumbnail_url': thumbnailUrl,
    'likes_count': likesCount,
    'created_at': createdAt.toIso8601String(),
  };
}

/// Kitchen Circle - Micro community
class KitchenCircle {
  final int id;
  final String name;
  final String? description;
  final String? iconUrl;
  final String? coverUrl;
  final int memberCount;
  final int recipeCount;
  final bool isJoined;
  final List<String> tags;
  final WeeklyChallenge? activeChallenge;
  final DateTime createdAt;

  KitchenCircle({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    this.coverUrl,
    this.memberCount = 0,
    this.recipeCount = 0,
    this.isJoined = false,
    this.tags = const [],
    this.activeChallenge,
    required this.createdAt,
  });

  factory KitchenCircle.fromJson(Map<String, dynamic> json) {
    return KitchenCircle(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconUrl: json['icon_url'],
      coverUrl: json['cover_url'],
      memberCount: json['member_count'] ?? 0,
      recipeCount: json['recipe_count'] ?? 0,
      isJoined: json['is_joined'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      activeChallenge: json['active_challenge'] != null
          ? WeeklyChallenge.fromJson(json['active_challenge'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'icon_url': iconUrl,
    'cover_url': coverUrl,
    'member_count': memberCount,
    'recipe_count': recipeCount,
    'is_joined': isJoined,
    'tags': tags,
    'active_challenge': activeChallenge?.toJson(),
    'created_at': createdAt.toIso8601String(),
  };
}

/// Weekly Challenge within a Circle
class WeeklyChallenge {
  final int id;
  final String title;
  final String? description;
  final String? ingredient; // Featured ingredient
  final int participantCount;
  final int submissionCount;
  final DateTime startDate;
  final DateTime endDate;

  WeeklyChallenge({
    required this.id,
    required this.title,
    this.description,
    this.ingredient,
    this.participantCount = 0,
    this.submissionCount = 0,
    required this.startDate,
    required this.endDate,
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  int get daysRemaining {
    return endDate.difference(DateTime.now()).inDays;
  }

  factory WeeklyChallenge.fromJson(Map<String, dynamic> json) {
    return WeeklyChallenge(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      ingredient: json['ingredient'],
      participantCount: json['participant_count'] ?? 0,
      submissionCount: json['submission_count'] ?? 0,
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'ingredient': ingredient,
    'participant_count': participantCount,
    'submission_count': submissionCount,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
  };
}

/// Comment on a recipe
class RecipeComment {
  final int id;
  final CommunityUser author;
  final String content;
  final String? imageUrl;
  final int likesCount;
  final bool isLiked;
  final List<RecipeComment> replies;
  final DateTime createdAt;

  RecipeComment({
    required this.id,
    required this.author,
    required this.content,
    this.imageUrl,
    this.likesCount = 0,
    this.isLiked = false,
    this.replies = const [],
    required this.createdAt,
  });

  factory RecipeComment.fromJson(Map<String, dynamic> json) {
    return RecipeComment(
      id: json['id'],
      author: CommunityUser.fromJson(json['author']),
      content: json['content'],
      imageUrl: json['image_url'],
      likesCount: json['likes_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      replies:
          (json['replies'] as List?)
              ?.map((r) => RecipeComment.fromJson(r))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'author': author.toJson(),
    'content': content,
    'image_url': imageUrl,
    'likes_count': likesCount,
    'is_liked': isLiked,
    'replies': replies.map((r) => r.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
  };
}

/// Cook-Along Session - Live cooking status
class CookAlongSession {
  final int id;
  final int recipeId;
  final CommunityUser user;
  final int currentStep;
  final String status; // 'preparing', 'cooking', 'completed', 'paused'
  final DateTime startedAt;
  final DateTime? completedAt;

  CookAlongSession({
    required this.id,
    required this.recipeId,
    required this.user,
    this.currentStep = 0,
    this.status = 'preparing',
    required this.startedAt,
    this.completedAt,
  });

  factory CookAlongSession.fromJson(Map<String, dynamic> json) {
    return CookAlongSession(
      id: json['id'],
      recipeId: json['recipe_id'],
      user: CommunityUser.fromJson(json['user']),
      currentStep: json['current_step'] ?? 0,
      status: json['status'] ?? 'preparing',
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'recipe_id': recipeId,
    'user': user.toJson(),
    'current_step': currentStep,
    'status': status,
    'started_at': startedAt.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
  };
}

/// Ingredient Spotlight - Featured ingredient
class IngredientSpotlight {
  final int id;
  final String name;
  final String? imageUrl;
  final String? description;
  final bool isSeasonal;
  final String? season;
  final int recipeCount;
  final List<RecipeChapter> featuredRecipes;

  IngredientSpotlight({
    required this.id,
    required this.name,
    this.imageUrl,
    this.description,
    this.isSeasonal = false,
    this.season,
    this.recipeCount = 0,
    this.featuredRecipes = const [],
  });

  factory IngredientSpotlight.fromJson(Map<String, dynamic> json) {
    return IngredientSpotlight(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image_url'],
      description: json['description'],
      isSeasonal: json['is_seasonal'] ?? false,
      season: json['season'],
      recipeCount: json['recipe_count'] ?? 0,
      featuredRecipes:
          (json['featured_recipes'] as List?)
              ?.map((r) => RecipeChapter.fromJson(r))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image_url': imageUrl,
    'description': description,
    'is_seasonal': isSeasonal,
    'season': season,
    'recipe_count': recipeCount,
    'featured_recipes': featuredRecipes.map((r) => r.toJson()).toList(),
  };
}
