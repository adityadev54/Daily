import '../database/database_helper.dart';
import '../models/meal.dart';
import '../models/meal_plan.dart';

class MealRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<List<Meal>> getAllMeals() async {
    try {
      final db = await _db.database;
      final results = await db.query('meals');
      return results.map((map) => Meal.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Meal>> getMealsByType(String mealType) async {
    try {
      final db = await _db.database;
      final results = await db.query(
        'meals',
        where: 'meal_type = ?',
        whereArgs: [mealType.toLowerCase()],
      );
      return results.map((map) => Meal.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Meal>> getMealsByDietType(String dietType) async {
    try {
      final db = await _db.database;
      final results = await db.query(
        'meals',
        where: 'diet_type = ?',
        whereArgs: [dietType],
      );
      return results.map((map) => Meal.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Meal>> getMealsByCuisine(String cuisine) async {
    try {
      final db = await _db.database;
      final results = await db.query(
        'meals',
        where: 'cuisine = ?',
        whereArgs: [cuisine],
      );
      return results.map((map) => Meal.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Meal>> searchMeals(String query) async {
    try {
      final db = await _db.database;
      final results = await db.query(
        'meals',
        where: 'name LIKE ? OR description LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
      );
      return results.map((map) => Meal.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Meal?> getMealById(int id) async {
    try {
      final db = await _db.database;
      final results = await db.query('meals', where: 'id = ?', whereArgs: [id]);
      if (results.isEmpty) return null;
      return Meal.fromMap(results.first);
    } catch (e) {
      return null;
    }
  }

  Future<int?> insertMeal(Meal meal) async {
    try {
      final db = await _db.database;
      final id = await db.insert('meals', meal.toMap());
      return id;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteMeal(int id) async {
    try {
      final db = await _db.database;
      await db.delete('meals', where: 'id = ?', whereArgs: [id]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateMeal(Meal meal) async {
    try {
      if (meal.id == null) return false;
      final db = await _db.database;
      await db.update(
        'meals',
        meal.toMap(),
        where: 'id = ?',
        whereArgs: [meal.id],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<MealPlan>> getMealPlan(int userId, String weekStartDate) async {
    try {
      final db = await _db.database;
      final results = await db.rawQuery(
        '''
        SELECT mp.*, m.name, m.description, m.image_url, m.calories, 
               m.prep_time, m.cuisine, m.diet_type, m.ingredients, m.instructions
        FROM meal_plans mp
        JOIN meals m ON mp.meal_id = m.id
        WHERE mp.user_id = ? AND mp.week_start_date = ?
        ORDER BY mp.day_of_week, 
          CASE mp.meal_type 
            WHEN 'breakfast' THEN 1 
            WHEN 'lunch' THEN 2 
            WHEN 'dinner' THEN 3 
            WHEN 'snack' THEN 4 
          END
      ''',
        [userId, weekStartDate],
      );

      return results.map((map) {
        final meal = Meal(
          id: map['meal_id'] as int,
          name: map['name'] as String,
          description: map['description'] as String?,
          imageUrl: map['image_url'] as String?,
          calories: map['calories'] as int?,
          prepTime: map['prep_time'] as int?,
          mealType: map['meal_type'] as String,
          cuisine: map['cuisine'] as String?,
          dietType: map['diet_type'] as String?,
          ingredients: map['ingredients'] as String?,
          instructions: map['instructions'] as String?,
        );
        return MealPlan.fromMap(map, meal: meal);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> addMealToPlan({
    required int userId,
    required int mealId,
    required int dayOfWeek,
    required String mealType,
    required String weekStartDate,
  }) async {
    try {
      final db = await _db.database;

      // Remove existing meal of same type for that day
      await db.delete(
        'meal_plans',
        where:
            'user_id = ? AND day_of_week = ? AND meal_type = ? AND week_start_date = ?',
        whereArgs: [userId, dayOfWeek, mealType.toLowerCase(), weekStartDate],
      );

      await db.insert('meal_plans', {
        'user_id': userId,
        'meal_id': mealId,
        'day_of_week': dayOfWeek,
        'meal_type': mealType.toLowerCase(),
        'week_start_date': weekStartDate,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeMealFromPlan(int mealPlanId) async {
    try {
      final db = await _db.database;
      await db.delete('meal_plans', where: 'id = ?', whereArgs: [mealPlanId]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> clearWeekPlan(int userId, String weekStartDate) async {
    try {
      final db = await _db.database;
      await db.delete(
        'meal_plans',
        where: 'user_id = ? AND week_start_date = ?',
        whereArgs: [userId, weekStartDate],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  String getWeekStartDate(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }
}
