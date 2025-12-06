/// User's health profile for personalized nutrition
class HealthProfile {
  final int? id;
  final int userId;
  final double? height; // in cm
  final double? weight; // in kg
  final int? birthYear;
  final String? sex; // 'male', 'female', 'other'
  final String
  activityLevel; // 'sedentary', 'light', 'moderate', 'active', 'very_active'
  final String? goal; // 'lose', 'maintain', 'gain'
  final double? targetWeight;
  final bool syncWithHealth; // sync weight from Samsung Health / Apple Health

  HealthProfile({
    this.id,
    required this.userId,
    this.height,
    this.weight,
    this.birthYear,
    this.sex,
    this.activityLevel = 'moderate',
    this.goal = 'maintain',
    this.targetWeight,
    this.syncWithHealth = true,
  });

  /// Calculate age from birth year
  int? get age {
    if (birthYear == null) return null;
    return DateTime.now().year - birthYear!;
  }

  /// Calculate BMI
  double? get bmi {
    if (height == null || weight == null || height == 0) return null;
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  /// Get BMI category
  String? get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return null;
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }

  /// Calculate Basal Metabolic Rate (BMR) using Mifflin-St Jeor equation
  double? get bmr {
    if (weight == null || height == null || age == null || sex == null) {
      return null;
    }

    // Mifflin-St Jeor Equation
    if (sex == 'male') {
      return (10 * weight!) + (6.25 * height!) - (5 * age!) + 5;
    } else {
      return (10 * weight!) + (6.25 * height!) - (5 * age!) - 161;
    }
  }

  /// Get activity multiplier
  double get activityMultiplier {
    switch (activityLevel) {
      case 'sedentary':
        return 1.2; // Little or no exercise
      case 'light':
        return 1.375; // Light exercise 1-3 days/week
      case 'moderate':
        return 1.55; // Moderate exercise 3-5 days/week
      case 'active':
        return 1.725; // Heavy exercise 6-7 days/week
      case 'very_active':
        return 1.9; // Very heavy exercise, physical job
      default:
        return 1.55;
    }
  }

  /// Calculate Total Daily Energy Expenditure (TDEE)
  double? get tdee {
    final bmrValue = bmr;
    if (bmrValue == null) return null;
    return bmrValue * activityMultiplier;
  }

  /// Calculate daily calorie target based on goal
  int? get dailyCalorieTarget {
    final tdeeValue = tdee;
    if (tdeeValue == null) return null;

    switch (goal) {
      case 'lose':
        return (tdeeValue - 500).round(); // ~0.5kg/week loss
      case 'gain':
        return (tdeeValue + 300).round(); // Lean gain
      case 'maintain':
      default:
        return tdeeValue.round();
    }
  }

  /// Calculate macro targets based on calorie target
  Map<String, int>? get macroTargets {
    final calories = dailyCalorieTarget;
    if (calories == null) return null;

    // Balanced macro split: 30% protein, 40% carbs, 30% fat
    // Adjusted based on goal
    double proteinPercent, carbPercent, fatPercent;

    switch (goal) {
      case 'lose':
        // Higher protein for muscle retention during deficit
        proteinPercent = 0.35;
        carbPercent = 0.35;
        fatPercent = 0.30;
        break;
      case 'gain':
        // Higher carbs for energy and muscle building
        proteinPercent = 0.30;
        carbPercent = 0.45;
        fatPercent = 0.25;
        break;
      case 'maintain':
      default:
        proteinPercent = 0.30;
        carbPercent = 0.40;
        fatPercent = 0.30;
    }

    return {
      'protein': ((calories * proteinPercent) / 4).round(), // 4 cal/g
      'carbs': ((calories * carbPercent) / 4).round(), // 4 cal/g
      'fat': ((calories * fatPercent) / 9).round(), // 9 cal/g
    };
  }

  /// Water intake recommendation (ml)
  int? get waterTarget {
    if (weight == null) return 2500; // Default 2.5L
    // ~35ml per kg of body weight
    return (weight! * 35).round();
  }

  /// Check if profile is complete enough for calculations
  bool get isComplete {
    return height != null && weight != null && birthYear != null && sex != null;
  }

  factory HealthProfile.fromMap(Map<String, dynamic> map) {
    return HealthProfile(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      height: (map['height'] as num?)?.toDouble(),
      weight: (map['weight'] as num?)?.toDouble(),
      birthYear: map['birth_year'] as int?,
      sex: map['sex'] as String?,
      activityLevel: map['activity_level'] as String? ?? 'moderate',
      goal: map['goal'] as String? ?? 'maintain',
      targetWeight: (map['target_weight'] as num?)?.toDouble(),
      syncWithHealth: (map['sync_with_health'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'height': height,
      'weight': weight,
      'birth_year': birthYear,
      'sex': sex,
      'activity_level': activityLevel,
      'goal': goal,
      'target_weight': targetWeight,
      'sync_with_health': syncWithHealth ? 1 : 0,
    };
  }

  HealthProfile copyWith({
    int? id,
    int? userId,
    double? height,
    double? weight,
    int? birthYear,
    String? sex,
    String? activityLevel,
    String? goal,
    double? targetWeight,
    bool? syncWithHealth,
  }) {
    return HealthProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      birthYear: birthYear ?? this.birthYear,
      sex: sex ?? this.sex,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      targetWeight: targetWeight ?? this.targetWeight,
      syncWithHealth: syncWithHealth ?? this.syncWithHealth,
    );
  }
}
