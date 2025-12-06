import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../data/models/community.dart';

class CommunityDiscoverScreen extends StatefulWidget {
  const CommunityDiscoverScreen({super.key});

  @override
  State<CommunityDiscoverScreen> createState() =>
      _CommunityDiscoverScreenState();
}

class _CommunityDiscoverScreenState extends State<CommunityDiscoverScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  // Mock data - will be replaced with real backend data
  final List<RecipeChapter> _recipes = [];
  final List<KitchenCircle> _circles = [];
  final List<IngredientSpotlight> _spotlights = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMockData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMockData() {
    // Mock users
    final mockUser1 = CommunityUser(
      id: 1,
      username: 'chef_maria',
      displayName: 'Maria Kitchen',
      avatarUrl: null,
      bio: 'Home cook & food lover',
      recipeCount: 45,
      followersCount: 1234,
      joinedAt: DateTime.now().subtract(const Duration(days: 365)),
      badges: ['verified', 'top_chef'],
    );

    final mockUser2 = CommunityUser(
      id: 2,
      username: 'healthy_bites',
      displayName: 'Sam Health',
      avatarUrl: null,
      bio: 'Nutrition focused recipes',
      recipeCount: 28,
      followersCount: 892,
      joinedAt: DateTime.now().subtract(const Duration(days: 200)),
      badges: ['nutritionist'],
    );

    final mockUser3 = CommunityUser(
      id: 3,
      username: 'quick_meals',
      displayName: 'Alex Quick',
      avatarUrl: null,
      bio: '15-min recipes for busy people',
      recipeCount: 67,
      followersCount: 2341,
      joinedAt: DateTime.now().subtract(const Duration(days: 500)),
      badges: ['top_chef', 'speed_demon'],
    );

    // Mock recipes
    _recipes.addAll([
      RecipeChapter(
        id: 1,
        author: mockUser1,
        title: 'Creamy Tuscan Chicken',
        description:
            'A restaurant-quality dish you can make at home in 30 minutes',
        steps: [
          ChapterStep(
            order: 0,
            type: 'before',
            title: 'Fresh Ingredients',
            description: 'Everything ready to go',
          ),
          ChapterStep(
            order: 1,
            type: 'process',
            title: 'Searing the Chicken',
            description: 'Golden brown on each side',
            timerSeconds: 300,
          ),
          ChapterStep(
            order: 2,
            type: 'result',
            title: 'Final Dish',
            description: 'Creamy, flavorful perfection!',
          ),
        ],
        tags: ['italian', 'creamy', 'chicken', 'dinner'],
        cuisine: 'Italian',
        prepTime: 10,
        cookTime: 25,
        servings: 4,
        difficulty: 'medium',
        nutrition: NutritionInfo(
          calories: 420,
          protein: 35,
          carbs: 12,
          fat: 28,
        ),
        ingredients: [
          RecipeIngredient(name: 'Chicken breast', quantity: 4, unit: 'pieces'),
          RecipeIngredient(
            name: 'Sun-dried tomatoes',
            quantity: 0.5,
            unit: 'cup',
          ),
          RecipeIngredient(name: 'Spinach', quantity: 2, unit: 'cups'),
          RecipeIngredient(name: 'Heavy cream', quantity: 1, unit: 'cup'),
          RecipeIngredient(name: 'Parmesan', quantity: 0.5, unit: 'cup'),
        ],
        likesCount: 342,
        commentsCount: 28,
        savesCount: 156,
        cookCount: 89,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      RecipeChapter(
        id: 2,
        author: mockUser2,
        title: 'Power Green Smoothie Bowl',
        description: 'Start your day with this nutrient-packed bowl',
        steps: [
          ChapterStep(
            order: 0,
            type: 'before',
            title: 'Prep the Greens',
            description: 'Fresh spinach and kale',
          ),
          ChapterStep(
            order: 1,
            type: 'process',
            title: 'Blend it Up',
            description: 'Until smooth and creamy',
          ),
          ChapterStep(
            order: 2,
            type: 'result',
            title: 'Beautiful Bowl',
            description: 'Topped with fresh fruits and granola',
          ),
          ChapterStep(
            order: 3,
            type: 'tip',
            title: 'Pro Tip',
            description: 'Freeze banana for extra thickness',
          ),
        ],
        tags: ['healthy', 'breakfast', 'vegan', 'smoothie'],
        cuisine: 'International',
        prepTime: 5,
        cookTime: 0,
        servings: 1,
        difficulty: 'easy',
        nutrition: NutritionInfo(calories: 280, protein: 8, carbs: 45, fat: 6),
        likesCount: 567,
        commentsCount: 45,
        savesCount: 234,
        cookCount: 178,
        isLiked: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      RecipeChapter(
        id: 3,
        author: mockUser3,
        title: '15-Min Garlic Shrimp Pasta',
        description: 'Quick weeknight dinner that tastes gourmet',
        steps: [
          ChapterStep(
            order: 0,
            type: 'before',
            title: 'Quick Prep',
            description: 'Everything measured and ready',
          ),
          ChapterStep(
            order: 1,
            type: 'process',
            title: 'Sauté the Garlic',
            description: 'Golden and fragrant',
            timerSeconds: 120,
          ),
          ChapterStep(
            order: 2,
            type: 'failed_attempt',
            title: 'Oops Moment',
            description: 'First try: burnt garlic. Lesson learned!',
          ),
          ChapterStep(
            order: 3,
            type: 'result',
            title: 'Perfect Plate',
            description: 'Restaurant-worthy in 15 minutes',
          ),
        ],
        tags: ['quick', 'seafood', 'pasta', 'garlic'],
        cuisine: 'Italian',
        prepTime: 5,
        cookTime: 10,
        servings: 2,
        difficulty: 'easy',
        nutrition: NutritionInfo(
          calories: 520,
          protein: 28,
          carbs: 58,
          fat: 18,
        ),
        remixes: [
          RecipeRemix(
            id: 1,
            originalRecipeId: 3,
            author: mockUser2,
            title: 'Zucchini Noodle Version',
            remixType: 'healthy',
            description: 'Low carb alternative',
            likesCount: 45,
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ],
        likesCount: 892,
        commentsCount: 67,
        savesCount: 445,
        cookCount: 312,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);

    // Mock circles
    _circles.addAll([
      KitchenCircle(
        id: 1,
        name: 'Busy Parents',
        description: 'Quick, kid-friendly meals for busy families',
        memberCount: 12453,
        recipeCount: 2341,
        tags: ['quick', 'family', 'kids'],
        activeChallenge: WeeklyChallenge(
          id: 1,
          title: 'One-Pan Wonders',
          description: 'Share your best one-pan family meal',
          ingredient: 'chicken',
          participantCount: 234,
          submissionCount: 89,
          startDate: DateTime.now().subtract(const Duration(days: 3)),
          endDate: DateTime.now().add(const Duration(days: 4)),
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
      ),
      KitchenCircle(
        id: 2,
        name: 'Budget Bites',
        description: 'Delicious meals under \$10',
        memberCount: 8921,
        recipeCount: 1567,
        tags: ['budget', 'cheap', 'student'],
        isJoined: true,
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
      ),
      KitchenCircle(
        id: 3,
        name: 'Keto Warriors',
        description: 'Low-carb, high-fat recipes',
        memberCount: 6234,
        recipeCount: 987,
        tags: ['keto', 'low-carb', 'healthy'],
        createdAt: DateTime.now().subtract(const Duration(days: 150)),
      ),
      KitchenCircle(
        id: 4,
        name: 'Plant Power',
        description: 'Vegan and vegetarian recipes',
        memberCount: 15678,
        recipeCount: 3421,
        tags: ['vegan', 'vegetarian', 'plant-based'],
        activeChallenge: WeeklyChallenge(
          id: 2,
          title: 'Protein-Packed Plants',
          description: 'High protein vegan dishes',
          participantCount: 456,
          submissionCount: 123,
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 6)),
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 400)),
      ),
    ]);

    // Mock spotlights
    _spotlights.addAll([
      IngredientSpotlight(
        id: 1,
        name: 'Avocado',
        description: 'Creamy, nutritious, and versatile',
        isSeasonal: true,
        season: 'Summer',
        recipeCount: 456,
      ),
      IngredientSpotlight(
        id: 2,
        name: 'Pumpkin',
        description: 'Fall favorite for sweet and savory',
        isSeasonal: true,
        season: 'Fall',
        recipeCount: 234,
      ),
      IngredientSpotlight(
        id: 3,
        name: 'Chickpeas',
        description: 'Protein-rich legume for any cuisine',
        isSeasonal: false,
        recipeCount: 567,
      ),
    ]);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF8F8F8),
        body: SafeArea(
          child: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildAppBar(isDark),
              _buildSearchBar(isDark),
              _buildTabBar(isDark),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildForYouTab(isDark),
                _buildCirclesTab(isDark),
                _buildSpotlightTab(isDark),
              ],
            ),
          ),
        ),
        floatingActionButton: _buildCreateButton(isDark),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      floating: true,
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8F8F8),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark ? Colors.white : Colors.black,
          size: 20,
        ),
      ),
      title: Text(
        'Kitchen Stories',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // TODO: Notifications
          },
          icon: Icon(
            Iconsax.notification,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        IconButton(
          onPressed: () {
            // TODO: Profile
          },
          icon: Icon(Iconsax.user, color: isDark ? Colors.white : Colors.black),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: GestureDetector(
          onTap: () {
            // TODO: Open search screen
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.search_normal,
                  size: 20,
                  color: isDark ? Colors.white54 : Colors.grey.shade500,
                ),
                const SizedBox(width: 12),
                Text(
                  'Search recipes, ingredients, chefs...',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: isDark ? Colors.white : Colors.black,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.grey.shade500,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          indicatorColor: isDark ? Colors.white : Colors.black,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: 'For You'),
            Tab(text: 'Circles'),
            Tab(text: 'Spotlight'),
          ],
        ),
        isDark: isDark,
      ),
    );
  }

  Widget _buildForYouTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [
        // AI Pack Promo Card
        _buildAIPackCard(isDark),
        const SizedBox(height: 20),

        // Currently Cooking Section
        _buildCookingNowSection(isDark),
        const SizedBox(height: 24),

        // Recipe Feed
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Taste-Matched For You',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Recipe Cards
        ..._recipes.map((recipe) => _buildRecipeCard(recipe, isDark)),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildAIPackCard(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF2C2C2E), const Color(0xFF1C1C1E)]
                : [const Color(0xFF667EEA), const Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'AI TOOLS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Unlock AI Chef',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Generate recipes, meal plans, and get personalized suggestions',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Explore',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF667EEA),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Iconsax.magic_star,
                size: 30,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCookingNowSection(bool isDark) {
    // Mock data for people cooking now
    final cookingNow = [
      {'name': 'Maria', 'recipe': 'Pasta Carbonara', 'step': 3, 'total': 5},
      {'name': 'John', 'recipe': 'Thai Curry', 'step': 2, 'total': 4},
      {'name': 'Sarah', 'recipe': 'Chocolate Cake', 'step': 1, 'total': 6},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Cooking Right Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const Spacer(),
              Text(
                '${cookingNow.length} active',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cookingNow.length,
            itemBuilder: (context, index) {
              final item = cookingNow[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      child: Text(
                        item['name'].toString()[0],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['recipe'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value:
                                        (item['step'] as int) /
                                        (item['total'] as int),
                                    backgroundColor: isDark
                                        ? Colors.white12
                                        : Colors.grey.shade200,
                                    valueColor: const AlwaysStoppedAnimation(
                                      Colors.green,
                                    ),
                                    minHeight: 3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Step ${item['step']}/${item['total']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeCard(RecipeChapter recipe, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.shade100,
                    backgroundImage: recipe.author.avatarUrl != null
                        ? NetworkImage(recipe.author.avatarUrl!)
                        : null,
                    child: recipe.author.avatarUrl == null
                        ? Text(
                            recipe.author.displayName[0],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              recipe.author.displayName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            if (recipe.author.badges.contains('verified')) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified,
                                size: 14,
                                color: Colors.blue.shade400,
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _getTimeAgo(recipe.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white54
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: More options
                    },
                    icon: Icon(
                      Icons.more_horiz,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Recipe Journey Steps (Swipeable)
            SizedBox(
              height: 240,
              child: PageView.builder(
                itemCount: recipe.steps.length,
                itemBuilder: (context, index) {
                  final step = recipe.steps[index];
                  return _buildStepCard(
                    step,
                    index,
                    recipe.steps.length,
                    isDark,
                  );
                },
              ),
            ),

            // Recipe Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  if (recipe.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      recipe.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Tags & Time
                  Row(
                    children: [
                      _buildInfoChip(
                        Iconsax.clock,
                        '${recipe.totalTime} min',
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        Iconsax.flash_1,
                        recipe.difficulty.capitalize(),
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      if (recipe.remixes.isNotEmpty)
                        _buildInfoChip(
                          Iconsax.repeat,
                          '${recipe.remixes.length} remix',
                          isDark,
                          highlight: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Engagement Row
                  Row(
                    children: [
                      _buildEngagementButton(
                        recipe.isLiked ? Iconsax.heart5 : Iconsax.heart,
                        recipe.likesCount.toString(),
                        isDark,
                        isActive: recipe.isLiked,
                        activeColor: Colors.red,
                      ),
                      const SizedBox(width: 20),
                      _buildEngagementButton(
                        Iconsax.message,
                        recipe.commentsCount.toString(),
                        isDark,
                      ),
                      const SizedBox(width: 20),
                      _buildEngagementButton(
                        recipe.isSaved ? Iconsax.bookmark5 : Iconsax.bookmark,
                        recipe.savesCount.toString(),
                        isDark,
                        isActive: recipe.isSaved,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.play,
                              size: 14,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Cook Along',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(ChapterStep step, int index, int total, bool isDark) {
    Color typeColor;
    String typeLabel;
    IconData typeIcon;

    switch (step.type) {
      case 'before':
        typeColor = Colors.blue;
        typeLabel = 'BEFORE';
        typeIcon = Iconsax.box;
        break;
      case 'process':
        typeColor = Colors.orange;
        typeLabel = 'PROCESS';
        typeIcon = Iconsax.timer_1;
        break;
      case 'result':
        typeColor = Colors.green;
        typeLabel = 'RESULT';
        typeIcon = Iconsax.tick_circle;
        break;
      case 'failed_attempt':
        typeColor = Colors.red;
        typeLabel = 'OOPS';
        typeIcon = Iconsax.warning_2;
        break;
      case 'tip':
        typeColor = Colors.purple;
        typeLabel = 'TIP';
        typeIcon = Iconsax.lamp_on;
        break;
      default:
        typeColor = Colors.grey;
        typeLabel = 'STEP';
        typeIcon = Iconsax.note;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Placeholder for image
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.image,
                  size: 48,
                  color: isDark ? Colors.white24 : Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  step.title ?? 'Step ${index + 1}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
                if (step.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    step.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),

          // Type Badge
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: typeColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(typeIcon, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    typeLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Page Indicator
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${index + 1}/$total',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Timer if available
          if (step.timerSeconds != null)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.timer_1, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${(step.timerSeconds! / 60).round()} min',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String text,
    bool isDark, {
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.purple.withValues(alpha: 0.1)
            : (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: highlight
                ? Colors.purple
                : (isDark ? Colors.white70 : Colors.grey.shade700),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: highlight
                  ? Colors.purple
                  : (isDark ? Colors.white70 : Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementButton(
    IconData icon,
    String count,
    bool isDark, {
    bool isActive = false,
    Color? activeColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 22,
          color: isActive
              ? (activeColor ?? (isDark ? Colors.white : Colors.black))
              : (isDark ? Colors.white54 : Colors.grey.shade600),
        ),
        const SizedBox(width: 6),
        Text(
          count,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildCirclesTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [
        // Your Circles
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Your Circles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _circles.where((c) => c.isJoined).length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildJoinCircleCard(isDark);
              }
              final joinedCircles = _circles.where((c) => c.isJoined).toList();
              return _buildCircleCard(
                joinedCircles[index - 1],
                isDark,
                compact: true,
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // Discover Circles
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Discover Circles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),

        ..._circles
            .where((c) => !c.isJoined)
            .map((circle) => _buildCircleCard(circle, isDark)),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildJoinCircleCard(bool isDark) {
    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Iconsax.add,
              color: isDark ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Join Circle',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleCard(
    KitchenCircle circle,
    bool isDark, {
    bool compact = false,
  }) {
    if (compact) {
      return Container(
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  circle.name.split(' ').map((w) => w[0]).take(2).join(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              circle.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (circle.activeChallenge != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '🔥 Active',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      circle.name.split(' ').map((w) => w[0]).take(2).join(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        circle.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatCount(circle.memberCount)} members • ${_formatCount(circle.recipeCount)} recipes',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: circle.isJoined
                        ? (isDark ? Colors.white12 : Colors.grey.shade200)
                        : (isDark ? Colors.white : Colors.black),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    circle.isJoined ? 'Joined' : 'Join',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: circle.isJoined
                          ? (isDark ? Colors.white70 : Colors.grey.shade700)
                          : (isDark ? Colors.black : Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            if (circle.description != null) ...[
              const SizedBox(height: 12),
              Text(
                circle.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            ],
            if (circle.activeChallenge != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            circle.activeChallenge!.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            '${circle.activeChallenge!.daysRemaining} days left • ${circle.activeChallenge!.participantCount} participating',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpotlightTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [
        // Seasonal Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text('🍂', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text(
                'Seasonal Ingredients',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _spotlights.where((s) => s.isSeasonal).length,
            itemBuilder: (context, index) {
              final seasonal = _spotlights
                  .where((s) => s.isSeasonal)
                  .toList()[index];
              return _buildSpotlightCard(seasonal, isDark);
            },
          ),
        ),
        const SizedBox(height: 24),

        // Trending Ingredients
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'What Can I Make With...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Tap an ingredient to discover community recipes',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Ingredient Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildIngredientChip('🥑 Avocado', 456, isDark),
              _buildIngredientChip('🍗 Chicken', 892, isDark),
              _buildIngredientChip('🧀 Cheese', 567, isDark),
              _buildIngredientChip('🥚 Eggs', 734, isDark),
              _buildIngredientChip('🍝 Pasta', 623, isDark),
              _buildIngredientChip('🥦 Broccoli', 234, isDark),
              _buildIngredientChip('🍤 Shrimp', 345, isDark),
              _buildIngredientChip('🥔 Potato', 512, isDark),
              _buildIngredientChip('🍅 Tomato', 678, isDark),
              _buildIngredientChip('🧄 Garlic', 890, isDark),
            ],
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSpotlightCard(IngredientSpotlight spotlight, bool isDark) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Icon(
                  Iconsax.image,
                  size: 40,
                  color: isDark ? Colors.white24 : Colors.grey.shade400,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spotlight.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${spotlight.recipeCount} recipes',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientChip(String label, int count, bool isDark) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to ingredient recipes
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton(bool isDark) {
    return FloatingActionButton.extended(
      onPressed: () {
        // TODO: Navigate to create recipe screen
      },
      backgroundColor: isDark ? Colors.white : Colors.black,
      icon: Icon(Iconsax.add, color: isDark ? Colors.black : Colors.white),
      label: Text(
        'Share Recipe',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.black : Colors.white,
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${(diff.inDays / 7).floor()}w ago';
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _TabBarDelegate(this.tabBar, {required this.isDark});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: isDark ? Colors.black : const Color(0xFFF8F8F8),
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
