import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme, isDark),
              _buildSearchBar(theme, isDark),
              _buildTabBar(theme, isDark),
              const SizedBox(height: 8),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _selectedTabIndex = index);
                  },
                  children: [
                    _buildCommunityTab(theme, isDark),
                    _buildCirclesTab(theme, isDark),
                    _buildSeasonalTab(theme, isDark),
                    _buildAIToolsTab(theme, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Discover',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.notification, size: 22),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: GestureDetector(
        onTap: () => _showSearchSheet(context, isDark),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Iconsax.search_normal,
                size: 20,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 12),
              Text(
                'Search recipes, creators, ingredients',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildTabItem(0, 'Community', isDark),
            _buildTabItem(1, 'Circles', isDark),
            _buildTabItem(2, 'Seasonal', isDark),
            _buildTabItem(3, 'AI Tools', isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label, bool isDark) {
    final theme = Theme.of(context);
    final isSelected = _selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTabIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.white.withOpacity(0.1) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black)
                    : theme.colorScheme.secondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== COMMUNITY TAB ====================
  Widget _buildCommunityTab(ThemeData theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.only(top: 20),
      children: [
        _buildSectionTitle('Featured Creators', theme),
        const SizedBox(height: 12),
        _buildCreatorsRow(isDark),
        const SizedBox(height: 28),

        _buildSectionTitle('Trending This Week', theme),
        const SizedBox(height: 12),
        _buildTrendingRecipes(theme, isDark),
        const SizedBox(height: 28),

        _buildSectionTitle('Recent from Community', theme),
        const SizedBox(height: 12),
        ..._buildCommunityPosts(theme, isDark),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Text(
              'See all',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorsRow(bool isDark) {
    final creators = [
      _Creator('Maria C.', 'Italian', '👩‍🍳', true),
      _Creator('Chef Raj', 'Indian', '👨‍🍳', true),
      _Creator('Emma G.', 'Healthy', '🌱', false),
      _Creator('Tom K.', 'BBQ', '🔥', false),
      _Creator('Lisa W.', 'Baking', '🧁', true),
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: creators.length,
        itemBuilder: (context, index) {
          final creator = creators[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.04),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          creator.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    if (creator.isVerified)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? Colors.black : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  creator.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingRecipes(ThemeData theme, bool isDark) {
    final recipes = [
      _TrendingRecipe('Creamy Tuscan Chicken', '32 min', 4.8, '🍗'),
      _TrendingRecipe('Spicy Thai Basil Noodles', '25 min', 4.9, '🍜'),
      _TrendingRecipe('Lemon Herb Salmon', '28 min', 4.7, '🐟'),
    ];

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          recipe.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Iconsax.bookmark,
                      size: 20,
                      color: theme.colorScheme.secondary,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  recipe.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Iconsax.clock,
                      size: 14,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      recipe.time,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Iconsax.star1, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      recipe.rating.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildCommunityPosts(ThemeData theme, bool isDark) {
    final posts = [
      _CommunityPost(
        creator: 'Maria Chen',
        avatar: '👩‍🍳',
        title: 'Finally perfected my grandmother\'s pasta recipe',
        likes: 234,
        comments: 45,
        timeAgo: '2h ago',
      ),
      _CommunityPost(
        creator: 'Chef Raj',
        avatar: '👨‍🍳',
        title: 'Quick tip: Toast your spices before grinding',
        likes: 567,
        comments: 89,
        timeAgo: '4h ago',
      ),
      _CommunityPost(
        creator: 'Emma Green',
        avatar: '🌱',
        title: 'Zero waste cooking: Using vegetable scraps',
        likes: 189,
        comments: 32,
        timeAgo: '6h ago',
      ),
    ];

    return posts.map((post) => _buildPostCard(post, theme, isDark)).toList();
  }

  Widget _buildPostCard(_CommunityPost post, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    post.avatar,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.creator,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      post.timeAgo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Iconsax.more, size: 20, color: theme.colorScheme.secondary),
            ],
          ),
          const SizedBox(height: 12),
          Text(post.title, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Iconsax.heart, size: 18, color: theme.colorScheme.secondary),
              const SizedBox(width: 6),
              Text(
                '${post.likes}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 20),
              Icon(
                Iconsax.message,
                size: 18,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                '${post.comments}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
              const Spacer(),
              Icon(
                Iconsax.send_2,
                size: 18,
                color: theme.colorScheme.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== CIRCLES TAB ====================
  Widget _buildCirclesTab(ThemeData theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.only(top: 20),
      children: [
        _buildSectionTitle('Your Circles', theme),
        const SizedBox(height: 12),
        ..._buildYourCircles(theme, isDark),
        const SizedBox(height: 28),

        _buildSectionTitle('Discover Circles', theme),
        const SizedBox(height: 12),
        ..._buildDiscoverCircles(theme, isDark),
        const SizedBox(height: 100),
      ],
    );
  }

  List<Widget> _buildYourCircles(ThemeData theme, bool isDark) {
    final circles = [
      _Circle('Weeknight Dinners', '12.8K members', Iconsax.clock, 234),
      _Circle('Bread Bakers', '4.5K members', Iconsax.cake, 89),
    ];

    return circles
        .map((c) => _buildCircleCard(c, theme, isDark, true))
        .toList();
  }

  List<Widget> _buildDiscoverCircles(ThemeData theme, bool isDark) {
    final circles = [
      _Circle('Meal Prep Sunday', '8.2K members', Iconsax.calendar_1, 156),
      _Circle('Budget Cooking', '15.3K members', Iconsax.wallet_2, 312),
      _Circle('Plant Based', '6.7K members', Iconsax.tree, 98),
      _Circle('Fermentation', '2.3K members', Iconsax.magicpen, 45),
    ];

    return circles
        .map((c) => _buildCircleCard(c, theme, isDark, false))
        .toList();
  }

  Widget _buildCircleCard(
    _Circle circle,
    ThemeData theme,
    bool isDark,
    bool joined,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              circle.icon,
              size: 22,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  circle.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        circle.members,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${circle.activeNow}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (joined)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Joined',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                side: BorderSide(
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Join',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== SEASONAL TAB ====================
  Widget _buildSeasonalTab(ThemeData theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.only(top: 20),
      children: [
        _buildSectionTitle('In Season Now', theme),
        const SizedBox(height: 12),
        _buildSeasonalIngredients(theme, isDark),
        const SizedBox(height: 28),

        _buildSectionTitle('Seasonal Recipes', theme),
        const SizedBox(height: 12),
        ..._buildSeasonalRecipes(theme, isDark),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSeasonalIngredients(ThemeData theme, bool isDark) {
    final ingredients = [
      _Ingredient('Meyer Lemon', '🍋', 45),
      _Ingredient('Butternut Squash', '🎃', 62),
      _Ingredient('Pomegranate', '🍎', 38),
      _Ingredient('Brussels Sprouts', '🥬', 54),
    ];

    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: ingredients.length,
        itemBuilder: (context, index) {
          final ing = ingredients[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(ing.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 6),
                Text(
                  ing.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${ing.recipes} recipes',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSeasonalRecipes(ThemeData theme, bool isDark) {
    final recipes = [
      _SeasonalRecipe(
        'Roasted Butternut Squash Soup',
        '40 min',
        'Comfort food perfect for cold days',
      ),
      _SeasonalRecipe(
        'Pomegranate Glazed Chicken',
        '35 min',
        'Sweet and savory winter dish',
      ),
      _SeasonalRecipe(
        'Meyer Lemon Pasta',
        '25 min',
        'Bright and fresh citrus flavor',
      ),
    ];

    return recipes
        .map((r) => _buildSeasonalRecipeCard(r, theme, isDark))
        .toList();
  }

  Widget _buildSeasonalRecipeCard(
    _SeasonalRecipe recipe,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recipe.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Iconsax.clock,
                      size: 14,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      recipe.time,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Iconsax.arrow_right_3,
            size: 20,
            color: theme.colorScheme.secondary,
          ),
        ],
      ),
    );
  }

  // ==================== AI TOOLS TAB ====================
  Widget _buildAIToolsTab(ThemeData theme, bool isDark) {
    final authProvider = context.watch<AuthProvider>();
    final isSubscribed = authProvider.isSubscribed;

    return ListView(
      padding: const EdgeInsets.only(top: 20),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Smart tools to help you cook better, plan smarter, and reduce waste.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ),
        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildAIToolCard(
                      theme,
                      isDark,
                      icon: Iconsax.magic_star,
                      title: 'Recipe Generator',
                      description: 'Create from ingredients',
                      isSubscribed: isSubscribed,
                      onTap: () => _openAITool('generator'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAIToolCard(
                      theme,
                      isDark,
                      icon: Iconsax.camera,
                      title: 'Photo to Recipe',
                      description: 'Scan any dish',
                      isSubscribed: isSubscribed,
                      onTap: () => _openAITool('photo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildAIToolCard(
                      theme,
                      isDark,
                      icon: Iconsax.calendar_tick,
                      title: 'Meal Planner',
                      description: 'Weekly plans',
                      isSubscribed: isSubscribed,
                      onTap: () => _openAITool('planner'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAIToolCard(
                      theme,
                      isDark,
                      icon: Iconsax.shopping_bag,
                      title: 'Smart Shopping',
                      description: 'Auto-generate lists',
                      isSubscribed: isSubscribed,
                      onTap: () => _openAITool('shopping'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildAIToolCard(
                      theme,
                      isDark,
                      icon: Iconsax.chart_21,
                      title: 'Nutrition Info',
                      description: 'Detailed breakdowns',
                      isSubscribed: isSubscribed,
                      onTap: () => _openAITool('nutrition'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAIToolCard(
                      theme,
                      isDark,
                      icon: Iconsax.refresh,
                      title: 'Substitutions',
                      description: 'Find alternatives',
                      isSubscribed: isSubscribed,
                      onTap: () => _openAITool('substitute'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (!isSubscribed) ...[
          const SizedBox(height: 32),
          _buildUpgradeCard(theme, isDark),
        ],

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildAIToolCard(
    ThemeData theme,
    bool isDark, {
    required IconData icon,
    required String title,
    required String description,
    required bool isSubscribed,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const Spacer(),
                if (!isSubscribed)
                  Icon(
                    Iconsax.lock,
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeCard(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.crown_1,
            size: 32,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          const SizedBox(height: 12),
          Text(
            'Unlock AI Tools',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Get unlimited access to all AI features',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'View Plans',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAITool(String tool) {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isSubscribed) {
      return;
    }
  }

  void _showSearchSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          final theme = Theme.of(context);
          return Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search recipes, creators, ingredients...',
                      prefixIcon: Icon(
                        Iconsax.search_normal,
                        color: theme.colorScheme.secondary,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      Text(
                        'Recent Searches',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRecentSearch('pasta recipes', theme, isDark),
                      _buildRecentSearch('quick dinner ideas', theme, isDark),
                      _buildRecentSearch('chicken breast', theme, isDark),
                      const SizedBox(height: 24),
                      Text(
                        'Popular Searches',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildSearchChip('30 min meals', theme, isDark),
                          _buildSearchChip('healthy dinner', theme, isDark),
                          _buildSearchChip('one pot', theme, isDark),
                          _buildSearchChip('vegetarian', theme, isDark),
                          _buildSearchChip('meal prep', theme, isDark),
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
    );
  }

  Widget _buildRecentSearch(String text, ThemeData theme, bool isDark) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Iconsax.clock,
        size: 20,
        color: theme.colorScheme.secondary,
      ),
      title: Text(text),
      trailing: Icon(
        Iconsax.arrow_up_2,
        size: 18,
        color: theme.colorScheme.secondary,
      ),
      onTap: () {
        _searchController.text = text;
      },
    );
  }

  Widget _buildSearchChip(String text, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// Data classes
class _Creator {
  final String name;
  final String specialty;
  final String emoji;
  final bool isVerified;

  _Creator(this.name, this.specialty, this.emoji, this.isVerified);
}

class _TrendingRecipe {
  final String name;
  final String time;
  final double rating;
  final String emoji;

  _TrendingRecipe(this.name, this.time, this.rating, this.emoji);
}

class _CommunityPost {
  final String creator;
  final String avatar;
  final String title;
  final int likes;
  final int comments;
  final String timeAgo;

  _CommunityPost({
    required this.creator,
    required this.avatar,
    required this.title,
    required this.likes,
    required this.comments,
    required this.timeAgo,
  });
}

class _Circle {
  final String name;
  final String members;
  final IconData icon;
  final int activeNow;

  _Circle(this.name, this.members, this.icon, this.activeNow);
}

class _Ingredient {
  final String name;
  final String emoji;
  final int recipes;

  _Ingredient(this.name, this.emoji, this.recipes);
}

class _SeasonalRecipe {
  final String name;
  final String time;
  final String description;

  _SeasonalRecipe(this.name, this.time, this.description);
}
