/// App string constants
class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'Meal Planner';

  // Auth
  static const String login = 'Login';
  static const String register = 'Register';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String name = 'Name';
  static const String forgotPassword = 'Forgot Password?';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String logout = 'Logout';

  // Validation
  static const String emailRequired = 'Email is required';
  static const String invalidEmail = 'Please enter a valid email';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort =
      'Password must be at least 6 characters';
  static const String passwordsDoNotMatch = 'Passwords do not match';
  static const String nameRequired = 'Name is required';

  // Meal Types
  static const String breakfast = 'Breakfast';
  static const String lunch = 'Lunch';
  static const String dinner = 'Dinner';
  static const String snack = 'Snack';

  // Days
  static const List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> weekDaysShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  // Preferences
  static const String preferences = 'Preferences';
  static const String dietaryPreferences = 'Dietary Preferences';
  static const String allergies = 'Allergies';
  static const String cuisinePreferences = 'Cuisine Preferences';

  // Diet types
  static const List<String> dietTypes = [
    'None',
    'Vegetarian',
    'Vegan',
    'Keto',
    'Paleo',
    'Mediterranean',
    'Low Carb',
    'Gluten Free',
  ];

  // Common allergies
  static const List<String> commonAllergies = [
    'Dairy',
    'Eggs',
    'Peanuts',
    'Tree Nuts',
    'Soy',
    'Wheat',
    'Fish',
    'Shellfish',
  ];

  // Cuisine types
  static const List<String> cuisineTypes = [
    'American',
    'Italian',
    'Mexican',
    'Chinese',
    'Japanese',
    'Indian',
    'Thai',
    'Mediterranean',
    'French',
    'Korean',
  ];

  // Cooking experience levels
  static const List<String> cookingExperienceLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Professional',
  ];

  // Preferred stores
  static const List<String> preferredStores = [
    'Any',
    'Whole Foods',
    'Trader Joe\'s',
    'Costco',
    'Walmart',
    'Kroger',
    'Safeway',
    'Target',
    'Aldi',
    'Local Market',
  ];

  // Nutrition goals
  static const List<String> nutritionGoals = [
    'High Protein',
    'Low Carb',
    'Low Fat',
    'High Fiber',
    'Low Sodium',
    'Low Sugar',
    'Calorie Control',
    'Muscle Building',
    'Weight Loss',
    'Heart Healthy',
  ];

  // Common disliked ingredients
  static const List<String> commonDislikes = [
    'Cilantro',
    'Olives',
    'Mushrooms',
    'Onions',
    'Tomatoes',
    'Bell Peppers',
    'Avocado',
    'Coconut',
    'Spicy Foods',
    'Seafood',
    'Liver',
    'Tofu',
    'Eggplant',
    'Brussels Sprouts',
    'Blue Cheese',
  ];

  // Messages
  static const String noMealsPlanned = 'No meals planned';
  static const String tapToAddMeal = 'Tap to add a meal';
  static const String mealAdded = 'Meal added successfully';
  static const String mealRemoved = 'Meal removed';
  static const String preferencesUpdated = 'Preferences updated';
}
