import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'meals.db');

    return await openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new preference columns
      await db.execute(
        'ALTER TABLE user_preferences ADD COLUMN household_size INTEGER DEFAULT 1',
      );
      await db.execute(
        'ALTER TABLE user_preferences ADD COLUMN cooking_experience TEXT DEFAULT "Intermediate"',
      );
      await db.execute(
        'ALTER TABLE user_preferences ADD COLUMN preferred_store TEXT DEFAULT "Any"',
      );
      await db.execute(
        'ALTER TABLE user_preferences ADD COLUMN nutrition_goals TEXT',
      );
      await db.execute(
        'ALTER TABLE user_preferences ADD COLUMN disliked_ingredients TEXT',
      );
    }
    if (oldVersion < 3) {
      // Bookmarks table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS bookmarks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          meal_id INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (meal_id) REFERENCES meals (id) ON DELETE CASCADE,
          UNIQUE(user_id, meal_id)
        )
      ''');

      // Shopping list table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS shopping_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          category TEXT,
          quantity TEXT,
          is_checked INTEGER DEFAULT 0,
          meal_id INTEGER,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      // Medications table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS medications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          dosage TEXT,
          frequency TEXT NOT NULL,
          times TEXT NOT NULL,
          with_food INTEGER DEFAULT 0,
          notes TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      // Medication logs table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS medication_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          medication_id INTEGER NOT NULL,
          taken_at TEXT NOT NULL,
          skipped INTEGER DEFAULT 0,
          FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
        )
      ''');

      // Add store_address to preferences
      await db.execute(
        'ALTER TABLE user_preferences ADD COLUMN store_address TEXT',
      );
    }
    if (oldVersion < 4) {
      // Add nutrition fields to meals table
      await db.execute('ALTER TABLE meals ADD COLUMN cook_time INTEGER');
      await db.execute('ALTER TABLE meals ADD COLUMN difficulty TEXT');
      await db.execute('ALTER TABLE meals ADD COLUMN protein REAL');
      await db.execute('ALTER TABLE meals ADD COLUMN carbs REAL');
      await db.execute('ALTER TABLE meals ADD COLUMN fat REAL');
      await db.execute('ALTER TABLE meals ADD COLUMN fiber REAL');
      await db.execute('ALTER TABLE meals ADD COLUMN sugar REAL');
      await db.execute('ALTER TABLE meals ADD COLUMN sodium REAL');
      await db.execute(
        'ALTER TABLE meals ADD COLUMN servings INTEGER DEFAULT 1',
      );
      await db.execute('ALTER TABLE meals ADD COLUMN tags TEXT');
      await db.execute('ALTER TABLE meals ADD COLUMN image_search_term TEXT');

      // Pantry items table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pantry_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          category TEXT,
          quantity TEXT,
          unit TEXT,
          expiry_date TEXT,
          is_low INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      // Budget table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budget_entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          category TEXT,
          description TEXT,
          meal_id INTEGER,
          date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      // Budget settings table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budget_settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER UNIQUE NOT NULL,
          weekly_budget REAL DEFAULT 100.0,
          currency TEXT DEFAULT 'USD',
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 5) {
      // Health profile table for personalized nutrition
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
    }
    if (oldVersion < 6) {
      // Add subscription fields to users
      await db.execute(
        'ALTER TABLE users ADD COLUMN is_subscribed INTEGER DEFAULT 0',
      );
      await db.execute('ALTER TABLE users ADD COLUMN subscription_expiry TEXT');
      await db.execute(
        'ALTER TABLE users ADD COLUMN chef_ai_enabled INTEGER DEFAULT 0',
      );

      // User API keys table (per-user API key storage)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_api_keys (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER UNIQUE NOT NULL,
          openrouter_key TEXT,
          provider TEXT,
          use_shared_key INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        is_subscribed INTEGER DEFAULT 0,
        subscription_expiry TEXT,
        chef_ai_enabled INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // User preferences table
    await db.execute('''
      CREATE TABLE user_preferences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER UNIQUE NOT NULL,
        diet_type TEXT DEFAULT 'None',
        allergies TEXT,
        cuisine_preferences TEXT,
        household_size INTEGER DEFAULT 1,
        cooking_experience TEXT DEFAULT 'Intermediate',
        preferred_store TEXT DEFAULT 'Any',
        nutrition_goals TEXT,
        disliked_ingredients TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Meals table
    await db.execute('''
      CREATE TABLE meals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        image_url TEXT,
        calories INTEGER,
        prep_time INTEGER,
        cook_time INTEGER,
        difficulty TEXT,
        meal_type TEXT NOT NULL,
        cuisine TEXT,
        diet_type TEXT,
        ingredients TEXT,
        instructions TEXT,
        protein REAL,
        carbs REAL,
        fat REAL,
        fiber REAL,
        sugar REAL,
        sodium REAL,
        servings INTEGER DEFAULT 1,
        tags TEXT,
        image_search_term TEXT
      )
    ''');

    // Meal plan table
    await db.execute('''
      CREATE TABLE meal_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        meal_id INTEGER NOT NULL,
        day_of_week INTEGER NOT NULL,
        meal_type TEXT NOT NULL,
        week_start_date TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (meal_id) REFERENCES meals (id) ON DELETE CASCADE
      )
    ''');

    // Bookmarks table
    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        meal_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (meal_id) REFERENCES meals (id) ON DELETE CASCADE,
        UNIQUE(user_id, meal_id)
      )
    ''');

    // Shopping list table
    await db.execute('''
      CREATE TABLE shopping_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        category TEXT,
        quantity TEXT,
        is_checked INTEGER DEFAULT 0,
        meal_id INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Medications table
    await db.execute('''
      CREATE TABLE medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        dosage TEXT,
        frequency TEXT NOT NULL,
        times TEXT NOT NULL,
        with_food INTEGER DEFAULT 0,
        notes TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Medication logs table
    await db.execute('''
      CREATE TABLE medication_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        taken_at TEXT NOT NULL,
        skipped INTEGER DEFAULT 0,
        FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
      )
    ''');

    // Pantry items table
    await db.execute('''
      CREATE TABLE pantry_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        category TEXT,
        quantity TEXT,
        unit TEXT,
        expiry_date TEXT,
        is_low INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Budget entries table
    await db.execute('''
      CREATE TABLE budget_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        category TEXT,
        description TEXT,
        meal_id INTEGER,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Budget settings table
    await db.execute('''
      CREATE TABLE budget_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER UNIQUE NOT NULL,
        weekly_budget REAL DEFAULT 100.0,
        currency TEXT DEFAULT 'USD',
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Health profile table for personalized nutrition
    await db.execute('''
      CREATE TABLE health_profiles (
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

    // User API keys table (per-user API key storage)
    await db.execute('''
      CREATE TABLE user_api_keys (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER UNIQUE NOT NULL,
        openrouter_key TEXT,
        provider TEXT,
        use_shared_key INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Insert sample meals
    await _insertSampleMeals(db);
  }

  Future<void> _insertSampleMeals(Database db) async {
    final meals = [
      // Breakfast meals
      {
        'name': 'Avocado Toast',
        'description':
            'Creamy avocado on toasted sourdough with cherry tomatoes',
        'image_url':
            'https://images.unsplash.com/photo-1541519227354-08fa5d50c44d?w=400',
        'calories': 320,
        'prep_time': 10,
        'meal_type': 'breakfast',
        'cuisine': 'American',
        'diet_type': 'Vegetarian',
        'ingredients':
            'Sourdough bread, Avocado, Cherry tomatoes, Olive oil, Salt, Pepper',
        'instructions':
            'Toast bread. Mash avocado and spread on toast. Top with tomatoes and seasonings.',
      },
      {
        'name': 'Greek Yogurt Parfait',
        'description': 'Layered yogurt with granola and fresh berries',
        'image_url':
            'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400',
        'calories': 280,
        'prep_time': 5,
        'meal_type': 'breakfast',
        'cuisine': 'American',
        'diet_type': 'Vegetarian',
        'ingredients': 'Greek yogurt, Granola, Mixed berries, Honey',
        'instructions':
            'Layer yogurt, granola, and berries in a glass. Drizzle with honey.',
      },
      {
        'name': 'Scrambled Eggs',
        'description': 'Fluffy scrambled eggs with herbs and cheese',
        'image_url':
            'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400',
        'calories': 250,
        'prep_time': 8,
        'meal_type': 'breakfast',
        'cuisine': 'American',
        'diet_type': 'Vegetarian',
        'ingredients': 'Eggs, Butter, Milk, Cheese, Chives, Salt, Pepper',
        'instructions':
            'Whisk eggs with milk. Cook in butter over low heat, stirring constantly.',
      },
      {
        'name': 'Oatmeal Bowl',
        'description': 'Warm oatmeal with banana, almonds, and maple syrup',
        'image_url':
            'https://images.unsplash.com/photo-1517673400267-0251440c45dc?w=400',
        'calories': 350,
        'prep_time': 10,
        'meal_type': 'breakfast',
        'cuisine': 'American',
        'diet_type': 'Vegan',
        'ingredients':
            'Rolled oats, Almond milk, Banana, Almonds, Maple syrup, Cinnamon',
        'instructions':
            'Cook oats with almond milk. Top with sliced banana, almonds, and maple syrup.',
      },
      {
        'name': 'Smoothie Bowl',
        'description':
            'Thick berry smoothie topped with fresh fruits and seeds',
        'image_url':
            'https://images.unsplash.com/photo-1590301157890-4810ed352733?w=400',
        'calories': 290,
        'prep_time': 7,
        'meal_type': 'breakfast',
        'cuisine': 'American',
        'diet_type': 'Vegan',
        'ingredients':
            'Frozen berries, Banana, Almond milk, Chia seeds, Granola',
        'instructions':
            'Blend frozen berries and banana with a little almond milk. Top with seeds and granola.',
      },
      // Lunch meals
      {
        'name': 'Caesar Salad',
        'description': 'Crisp romaine with parmesan and homemade croutons',
        'image_url':
            'https://images.unsplash.com/photo-1550304943-4f24f54ddde9?w=400',
        'calories': 380,
        'prep_time': 15,
        'meal_type': 'lunch',
        'cuisine': 'Italian',
        'diet_type': 'Vegetarian',
        'ingredients':
            'Romaine lettuce, Parmesan cheese, Croutons, Caesar dressing, Lemon',
        'instructions':
            'Chop romaine, toss with dressing, top with parmesan and croutons.',
      },
      {
        'name': 'Grilled Chicken Wrap',
        'description': 'Seasoned chicken with fresh vegetables in a tortilla',
        'image_url':
            'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=400',
        'calories': 450,
        'prep_time': 20,
        'meal_type': 'lunch',
        'cuisine': 'American',
        'diet_type': 'None',
        'ingredients':
            'Chicken breast, Tortilla, Lettuce, Tomato, Onion, Ranch dressing',
        'instructions':
            'Grill seasoned chicken. Slice and wrap with vegetables in tortilla.',
      },
      {
        'name': 'Quinoa Buddha Bowl',
        'description':
            'Nutritious bowl with quinoa, roasted vegetables, and tahini',
        'image_url':
            'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
        'calories': 420,
        'prep_time': 25,
        'meal_type': 'lunch',
        'cuisine': 'Mediterranean',
        'diet_type': 'Vegan',
        'ingredients': 'Quinoa, Sweet potato, Chickpeas, Kale, Tahini, Lemon',
        'instructions':
            'Cook quinoa. Roast vegetables. Assemble bowl and drizzle with tahini dressing.',
      },
      {
        'name': 'Tomato Soup',
        'description': 'Classic creamy tomato soup with fresh basil',
        'image_url':
            'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400',
        'calories': 220,
        'prep_time': 30,
        'meal_type': 'lunch',
        'cuisine': 'American',
        'diet_type': 'Vegetarian',
        'ingredients': 'Tomatoes, Onion, Garlic, Vegetable broth, Cream, Basil',
        'instructions':
            'Sauté onion and garlic. Add tomatoes and broth. Simmer, blend, and add cream.',
      },
      {
        'name': 'Turkey Sandwich',
        'description': 'Sliced turkey with lettuce, tomato, and mustard',
        'image_url':
            'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400',
        'calories': 380,
        'prep_time': 10,
        'meal_type': 'lunch',
        'cuisine': 'American',
        'diet_type': 'None',
        'ingredients':
            'Turkey breast, Whole wheat bread, Lettuce, Tomato, Mustard, Mayo',
        'instructions':
            'Layer turkey and vegetables on bread. Add condiments and serve.',
      },
      // Dinner meals
      {
        'name': 'Grilled Salmon',
        'description': 'Fresh salmon fillet with lemon herb butter',
        'image_url':
            'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400',
        'calories': 480,
        'prep_time': 25,
        'meal_type': 'dinner',
        'cuisine': 'American',
        'diet_type': 'None',
        'ingredients': 'Salmon fillet, Butter, Lemon, Garlic, Dill, Asparagus',
        'instructions':
            'Season salmon. Grill until cooked through. Top with herb butter.',
      },
      {
        'name': 'Chicken Stir Fry',
        'description':
            'Tender chicken with colorful vegetables in savory sauce',
        'image_url':
            'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400',
        'calories': 420,
        'prep_time': 20,
        'meal_type': 'dinner',
        'cuisine': 'Chinese',
        'diet_type': 'None',
        'ingredients':
            'Chicken breast, Bell peppers, Broccoli, Soy sauce, Ginger, Garlic, Rice',
        'instructions':
            'Stir fry chicken, add vegetables, and toss with sauce. Serve over rice.',
      },
      {
        'name': 'Pasta Primavera',
        'description': 'Penne pasta with seasonal vegetables and parmesan',
        'image_url':
            'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=400',
        'calories': 450,
        'prep_time': 25,
        'meal_type': 'dinner',
        'cuisine': 'Italian',
        'diet_type': 'Vegetarian',
        'ingredients':
            'Penne pasta, Zucchini, Bell pepper, Cherry tomatoes, Olive oil, Parmesan',
        'instructions':
            'Cook pasta. Sauté vegetables. Toss together with olive oil and parmesan.',
      },
      {
        'name': 'Beef Tacos',
        'description':
            'Seasoned ground beef in corn tortillas with fresh toppings',
        'image_url':
            'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=400',
        'calories': 520,
        'prep_time': 25,
        'meal_type': 'dinner',
        'cuisine': 'Mexican',
        'diet_type': 'None',
        'ingredients':
            'Ground beef, Corn tortillas, Lettuce, Tomato, Cheese, Sour cream, Salsa',
        'instructions':
            'Brown beef with taco seasoning. Fill tortillas with meat and toppings.',
      },
      {
        'name': 'Vegetable Curry',
        'description': 'Creamy coconut curry with mixed vegetables and rice',
        'image_url':
            'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=400',
        'calories': 400,
        'prep_time': 35,
        'meal_type': 'dinner',
        'cuisine': 'Indian',
        'diet_type': 'Vegan',
        'ingredients':
            'Coconut milk, Curry paste, Chickpeas, Spinach, Potato, Basmati rice',
        'instructions':
            'Sauté vegetables, add curry paste and coconut milk. Simmer and serve with rice.',
      },
      // Snacks
      {
        'name': 'Hummus & Veggies',
        'description': 'Creamy hummus with fresh vegetable sticks',
        'image_url':
            'https://images.unsplash.com/photo-1578861256505-74760f573a6b?w=400',
        'calories': 180,
        'prep_time': 5,
        'meal_type': 'snack',
        'cuisine': 'Mediterranean',
        'diet_type': 'Vegan',
        'ingredients': 'Hummus, Carrots, Celery, Cucumber, Bell pepper',
        'instructions':
            'Cut vegetables into sticks. Serve with hummus for dipping.',
      },
      {
        'name': 'Apple & Peanut Butter',
        'description': 'Sliced apple with creamy peanut butter',
        'image_url':
            'https://images.unsplash.com/photo-1568702846914-96b305d2uj0c0f?w=400',
        'calories': 200,
        'prep_time': 3,
        'meal_type': 'snack',
        'cuisine': 'American',
        'diet_type': 'Vegan',
        'ingredients': 'Apple, Peanut butter',
        'instructions': 'Slice apple and serve with peanut butter for dipping.',
      },
      {
        'name': 'Trail Mix',
        'description': 'Mixed nuts, seeds, and dried fruits',
        'image_url':
            'https://images.unsplash.com/photo-1478145046317-39f10e56b5e9?w=400',
        'calories': 250,
        'prep_time': 2,
        'meal_type': 'snack',
        'cuisine': 'American',
        'diet_type': 'Vegan',
        'ingredients':
            'Almonds, Cashews, Pumpkin seeds, Dried cranberries, Dark chocolate chips',
        'instructions':
            'Mix all ingredients together. Store in an airtight container.',
      },
      {
        'name': 'Cheese & Crackers',
        'description': 'Assorted cheese with whole grain crackers',
        'image_url':
            'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=400',
        'calories': 220,
        'prep_time': 5,
        'meal_type': 'snack',
        'cuisine': 'American',
        'diet_type': 'Vegetarian',
        'ingredients': 'Cheddar cheese, Brie, Whole grain crackers, Grapes',
        'instructions':
            'Arrange cheese and crackers on a plate. Add grapes for garnish.',
      },
    ];

    for (final meal in meals) {
      await db.insert('meals', meal);
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
