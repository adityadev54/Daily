import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/database/database_helper.dart';
import '../data/models/health_profile.dart';
import '../data/models/meal.dart';

/// Daily nutrition summary combining health data and meal tracking
class NutritionSummary {
  final int caloriesConsumed;
  final int caloriesBurned;
  final int caloriesTarget;
  final int proteinConsumed;
  final int proteinTarget;
  final int carbsConsumed;
  final int carbsTarget;
  final int fatConsumed;
  final int fatTarget;
  final double waterConsumed; // liters
  final double waterTarget; // liters
  final int steps;
  final int stepsGoal;
  final DateTime lastSynced;

  NutritionSummary({
    required this.caloriesConsumed,
    required this.caloriesBurned,
    required this.caloriesTarget,
    required this.proteinConsumed,
    required this.proteinTarget,
    required this.carbsConsumed,
    required this.carbsTarget,
    required this.fatConsumed,
    required this.fatTarget,
    required this.waterConsumed,
    required this.waterTarget,
    required this.steps,
    required this.stepsGoal,
    required this.lastSynced,
  });

  /// Net calories (consumed - burned from activity)
  int get netCalories => caloriesConsumed - caloriesBurned;

  /// Remaining calories for the day
  int get caloriesRemaining =>
      caloriesTarget - caloriesConsumed + caloriesBurned;

  /// Progress percentages
  double get caloriesProgress => caloriesTarget > 0
      ? (caloriesConsumed / caloriesTarget).clamp(0.0, 1.5)
      : 0;
  double get proteinProgress =>
      proteinTarget > 0 ? (proteinConsumed / proteinTarget).clamp(0.0, 1.5) : 0;
  double get carbsProgress =>
      carbsTarget > 0 ? (carbsConsumed / carbsTarget).clamp(0.0, 1.5) : 0;
  double get fatProgress =>
      fatTarget > 0 ? (fatConsumed / fatTarget).clamp(0.0, 1.5) : 0;
  double get waterProgress =>
      waterTarget > 0 ? (waterConsumed / waterTarget).clamp(0.0, 1.5) : 0;
  double get stepsProgress =>
      stepsGoal > 0 ? (steps / stepsGoal).clamp(0.0, 1.5) : 0;
}

/// Provider for Samsung Health / Apple Health integration with personalized nutrition
class HealthProvider extends ChangeNotifier {
  final Health _health = Health();
  final DatabaseHelper _db = DatabaseHelper();

  bool _isConfigured = false;
  bool _isAuthorized = false;
  bool _isLoading = false;
  bool _isHealthConnectAvailable = false;
  String? _error;

  // Health profile for personalization
  HealthProfile? _healthProfile;

  // Today's nutrition summary
  NutritionSummary? _todayNutrition;

  // Raw health data
  int? _todaySteps;
  double? _todayCaloriesBurned;
  double? _todayWaterIntake;
  double? _latestWeight;
  int? _latestHeartRate;
  int? _lastNightSleep;

  // Getters
  bool get isConfigured => _isConfigured;
  bool get isAuthorized => _isAuthorized;
  bool get isLoading => _isLoading;
  bool get isHealthConnectAvailable => _isHealthConnectAvailable;
  String? get error => _error;
  HealthProfile? get healthProfile => _healthProfile;
  NutritionSummary? get todayNutrition => _todayNutrition;

  // Individual metrics getters
  int get todaySteps => _todaySteps ?? 0;
  double get todayCaloriesBurned => _todayCaloriesBurned ?? 0;
  double get todayWaterIntake => _todayWaterIntake ?? 0;
  double? get latestWeight => _latestWeight;
  int? get latestHeartRate => _latestHeartRate;
  int? get lastNightSleep => _lastNightSleep;

  // Check if profile is set up
  bool get hasProfile => _healthProfile?.isComplete ?? false;

  String get healthServiceName =>
      Platform.isIOS ? 'Apple Health' : 'Samsung Health';

  // Health data types we want to access
  static const List<HealthDataType> _readTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
    HealthDataType.HEART_RATE,
    HealthDataType.WATER,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,
    HealthDataType.NUTRITION,
  ];

  static const List<HealthDataType> _writeTypes = [
    HealthDataType.NUTRITION,
    HealthDataType.WATER,
    HealthDataType.WEIGHT,
  ];

  /// Initialize the health plugin
  Future<void> configure() async {
    if (_isConfigured) return;

    try {
      _isLoading = true;
      notifyListeners();

      await _health.configure();
      _isConfigured = true;

      if (Platform.isAndroid) {
        _isHealthConnectAvailable = await _health.isHealthConnectAvailable();
      } else {
        _isHealthConnectAvailable = true;
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to configure health plugin: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ensure health_profiles table exists (for migration)
  Future<void> _ensureTableExists() async {
    try {
      final db = await _db.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS health_profiles (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER UNIQUE NOT NULL,
          height REAL,
          weight REAL,
          birth_year INTEGER,
          sex TEXT,
          activity_level TEXT DEFAULT 'moderate',
          goal TEXT DEFAULT 'maintain',
          target_weight REAL,
          sync_with_health INTEGER DEFAULT 1,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
    } catch (e) {
      debugPrint('Error ensuring table exists: $e');
    }
  }

  /// Load health profile from database
  Future<void> loadHealthProfile(int userId) async {
    try {
      await _ensureTableExists();
      final db = await _db.database;
      final results = await db.query(
        'health_profiles',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      if (results.isNotEmpty) {
        _healthProfile = HealthProfile.fromMap(results.first);
      } else {
        // Create empty profile
        _healthProfile = HealthProfile(userId: userId);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading health profile: $e');
    }
  }

  /// Save health profile to database
  Future<bool> saveHealthProfile(HealthProfile profile) async {
    try {
      await _ensureTableExists();
      final db = await _db.database;
      final data = profile.toMap();
      data['updated_at'] = DateTime.now().toIso8601String();

      int? insertedId;

      if (profile.id != null) {
        await db.update(
          'health_profiles',
          data,
          where: 'id = ?',
          whereArgs: [profile.id],
        );
        insertedId = profile.id;
      } else {
        final existing = await db.query(
          'health_profiles',
          where: 'user_id = ?',
          whereArgs: [profile.userId],
        );

        if (existing.isNotEmpty) {
          await db.update(
            'health_profiles',
            data,
            where: 'user_id = ?',
            whereArgs: [profile.userId],
          );
          insertedId = existing.first['id'] as int?;
        } else {
          insertedId = await db.insert('health_profiles', data);
        }
      }

      // Reload profile from database to get the correct id
      _healthProfile = profile.copyWith(id: insertedId);

      debugPrint(
        'Saved health profile: id=${_healthProfile?.id}, isComplete=${_healthProfile?.isComplete}',
      );

      await _updateNutritionSummary();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving health profile: $e');
      return false;
    }
  }

  /// Request authorization for health data access
  Future<bool> requestAuthorization() async {
    if (!_isConfigured) await configure();

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (Platform.isAndroid) {
        await Permission.activityRecognition.request();
      }

      final types = [..._readTypes, ..._writeTypes];
      final permissions = [
        ...List.filled(_readTypes.length, HealthDataAccess.READ),
        ...List.filled(_writeTypes.length, HealthDataAccess.READ_WRITE),
      ];

      _isAuthorized = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );

      if (_isAuthorized) {
        // Fetch initial data after authorization
        await fetchHealthData();
      } else {
        _error = 'Health permissions were denied';
      }

      return _isAuthorized;
    } catch (e) {
      _error = 'Failed to request authorization: $e';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch all health data and update nutrition summary
  Future<void> fetchHealthData() async {
    if (!_isAuthorized) return;

    try {
      _isLoading = true;
      notifyListeners();

      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final yesterdayEvening = midnight.subtract(const Duration(hours: 12));

      // Fetch steps
      _todaySteps = await _health.getTotalStepsInInterval(midnight, now);

      // Fetch health data
      final healthData = await _health.getHealthDataFromTypes(
        types: _readTypes,
        startTime: midnight,
        endTime: now,
      );

      // Fetch sleep data (from yesterday evening)
      final sleepData = await _health.getHealthDataFromTypes(
        types: [
          HealthDataType.SLEEP_ASLEEP,
          HealthDataType.SLEEP_DEEP,
          HealthDataType.SLEEP_LIGHT,
          HealthDataType.SLEEP_REM,
        ],
        startTime: yesterdayEvening,
        endTime: now,
      );

      final allData = _health.removeDuplicates([...healthData, ...sleepData]);

      _todayCaloriesBurned = 0;
      _todayWaterIntake = 0;
      _lastNightSleep = 0;

      for (final point in allData) {
        final value = point.value;

        switch (point.type) {
          case HealthDataType.ACTIVE_ENERGY_BURNED:
            if (value is NumericHealthValue) {
              _todayCaloriesBurned =
                  (_todayCaloriesBurned ?? 0) + value.numericValue;
            }
            break;
          case HealthDataType.WEIGHT:
            if (value is NumericHealthValue) {
              _latestWeight = value.numericValue.toDouble();
              // Sync weight to profile if enabled
              if (_healthProfile?.syncWithHealth == true &&
                  _latestWeight != null) {
                _healthProfile = _healthProfile!.copyWith(
                  weight: _latestWeight,
                );
              }
            }
            break;
          case HealthDataType.HEIGHT:
            if (value is NumericHealthValue &&
                _healthProfile?.syncWithHealth == true) {
              final heightCm =
                  value.numericValue.toDouble() * 100; // Convert m to cm
              _healthProfile = _healthProfile?.copyWith(height: heightCm);
            }
            break;
          case HealthDataType.HEART_RATE:
            if (value is NumericHealthValue) {
              _latestHeartRate = value.numericValue.round();
            }
            break;
          case HealthDataType.WATER:
            if (value is NumericHealthValue) {
              _todayWaterIntake = (_todayWaterIntake ?? 0) + value.numericValue;
            }
            break;
          case HealthDataType.SLEEP_ASLEEP:
          case HealthDataType.SLEEP_DEEP:
          case HealthDataType.SLEEP_LIGHT:
          case HealthDataType.SLEEP_REM:
            if (value is NumericHealthValue) {
              _lastNightSleep =
                  (_lastNightSleep ?? 0) + value.numericValue.round();
            }
            break;
          default:
            break;
        }
      }

      await _updateNutritionSummary();
      _error = null;
    } catch (e) {
      _error = 'Failed to fetch health data: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Alias for fetchHealthData for backward compatibility
  Future<void> fetchTodaySummary() => fetchHealthData();

  /// Update nutrition summary with current data
  Future<void> _updateNutritionSummary({
    int? caloriesConsumed,
    int? proteinConsumed,
    int? carbsConsumed,
    int? fatConsumed,
  }) async {
    final profile = _healthProfile;

    // Default targets if no profile
    int caloriesTarget = 2000;
    int proteinTarget = 50;
    int carbsTarget = 250;
    int fatTarget = 65;
    double waterTarget = 2.5;

    if (profile != null && profile.isComplete) {
      caloriesTarget = profile.dailyCalorieTarget ?? 2000;
      final macros = profile.macroTargets;
      if (macros != null) {
        proteinTarget = macros['protein'] ?? 50;
        carbsTarget = macros['carbs'] ?? 250;
        fatTarget = macros['fat'] ?? 65;
      }
      waterTarget = (profile.waterTarget ?? 2500) / 1000;
    }

    _todayNutrition = NutritionSummary(
      caloriesConsumed:
          caloriesConsumed ?? _todayNutrition?.caloriesConsumed ?? 0,
      caloriesBurned: (_todayCaloriesBurned ?? 0).round(),
      caloriesTarget: caloriesTarget,
      proteinConsumed: proteinConsumed ?? _todayNutrition?.proteinConsumed ?? 0,
      proteinTarget: proteinTarget,
      carbsConsumed: carbsConsumed ?? _todayNutrition?.carbsConsumed ?? 0,
      carbsTarget: carbsTarget,
      fatConsumed: fatConsumed ?? _todayNutrition?.fatConsumed ?? 0,
      fatTarget: fatTarget,
      waterConsumed: _todayWaterIntake ?? 0,
      waterTarget: waterTarget,
      steps: _todaySteps ?? 0,
      stepsGoal: 10000,
      lastSynced: DateTime.now(),
    );

    notifyListeners();
  }

  /// Update consumed nutrition from meals
  void updateConsumedNutrition({
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
  }) {
    _updateNutritionSummary(
      caloriesConsumed: calories,
      proteinConsumed: protein,
      carbsConsumed: carbs,
      fatConsumed: fat,
    );
  }

  /// Sync a meal to health platform
  Future<bool> syncMealToHealth(Meal meal) async {
    if (!_isAuthorized) return false;

    try {
      final now = DateTime.now();
      final success = await _health.writeMeal(
        mealType: _getMealType(meal.mealType),
        startTime: now.subtract(const Duration(minutes: 30)),
        endTime: now,
        caloriesConsumed: meal.calories?.toDouble(),
        carbohydrates: meal.carbs,
        protein: meal.protein,
        fatTotal: meal.fat,
        fiber: meal.fiber,
        sugar: meal.sugar,
        sodium: meal.sodium,
        name: meal.name,
        recordingMethod: RecordingMethod.manual,
      );

      if (success) {
        await fetchHealthData();
      }
      return success;
    } catch (e) {
      debugPrint('Error syncing meal: $e');
      return false;
    }
  }

  /// Log water intake
  Future<bool> logWater(double liters) async {
    if (!_isAuthorized) return false;

    try {
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(minutes: 1));
      final success = await _health.writeHealthData(
        value: liters,
        type: HealthDataType.WATER,
        startTime: startTime,
        endTime: now,
        unit: HealthDataUnit.LITER,
      );

      if (success) {
        await fetchHealthData();
      }
      return success;
    } catch (e) {
      debugPrint('Error logging water: $e');
      return false;
    }
  }

  /// Log weight
  Future<bool> logWeight(double kg) async {
    if (!_isAuthorized) return false;

    try {
      final now = DateTime.now();
      final success = await _health.writeHealthData(
        value: kg,
        type: HealthDataType.WEIGHT,
        startTime: now,
        endTime: now,
        unit: HealthDataUnit.KILOGRAM,
      );

      if (success) {
        _latestWeight = kg;
        if (_healthProfile?.syncWithHealth == true) {
          _healthProfile = _healthProfile!.copyWith(weight: kg);
        }
        await fetchHealthData();
      }
      return success;
    } catch (e) {
      debugPrint('Error logging weight: $e');
      return false;
    }
  }

  /// Get activity level description based on steps
  String getActivityLevelFromSteps(int averageSteps) {
    if (averageSteps < 3000) return 'sedentary';
    if (averageSteps < 5000) return 'light';
    if (averageSteps < 8000) return 'moderate';
    if (averageSteps < 12000) return 'active';
    return 'very_active';
  }

  /// Get recommended meals based on remaining calories and macros
  Map<String, dynamic> getMealRecommendationCriteria() {
    final nutrition = _todayNutrition;
    if (nutrition == null) {
      return {'maxCalories': 600, 'minProtein': 20};
    }

    final remainingCalories = nutrition.caloriesRemaining;
    final remainingProtein =
        nutrition.proteinTarget - nutrition.proteinConsumed;

    return {
      'maxCalories': remainingCalories > 0 ? remainingCalories ~/ 2 : 400,
      'minProtein': remainingProtein > 0 ? remainingProtein ~/ 3 : 15,
      'remainingCalories': remainingCalories,
      'remainingProtein': remainingProtein,
      'remainingCarbs': nutrition.carbsTarget - nutrition.carbsConsumed,
      'remainingFat': nutrition.fatTarget - nutrition.fatConsumed,
    };
  }

  /// Disconnect health services
  Future<void> disconnect() async {
    try {
      await _health.revokePermissions();
      _isAuthorized = false;
      _todayNutrition = null;
      _todaySteps = null;
      _todayCaloriesBurned = null;
      _todayWaterIntake = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
  }

  MealType _getMealType(String? type) {
    switch (type?.toLowerCase()) {
      case 'breakfast':
        return MealType.BREAKFAST;
      case 'lunch':
        return MealType.LUNCH;
      case 'dinner':
        return MealType.DINNER;
      case 'snack':
        return MealType.SNACK;
      default:
        return MealType.UNKNOWN;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
