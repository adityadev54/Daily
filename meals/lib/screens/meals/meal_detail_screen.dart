import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/meal.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../providers/medication_provider.dart';
import 'edit_meal_screen.dart';
import 'personalize_meal_dialog.dart';

class MealDetailScreen extends StatefulWidget {
  final Meal meal;

  const MealDetailScreen({super.key, required this.meal});

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen>
    with SingleTickerProviderStateMixin {
  late Meal meal;
  late ScrollController _scrollController;
  double _scrollOffset = 0;
  int _selectedTab = 0; // 0: Overview, 1: Ingredients, 2: Steps

  // Map common ingredients to emoji icons for visual appeal
  static const Map<String, String> _ingredientIcons = {
    // Proteins
    'chicken': '🍗',
    'beef': '🥩',
    'pork': '🥓',
    'fish': '🐟',
    'salmon': '🐟',
    'tuna': '🐟',
    'shrimp': '🦐',
    'egg': '🥚',
    'eggs': '🥚',
    'tofu': '🧈',
    // Vegetables
    'tomato': '🍅',
    'tomatoes': '🍅',
    'onion': '🧅',
    'onions': '🧅',
    'garlic': '🧄',
    'carrot': '🥕',
    'carrots': '🥕',
    'broccoli': '🥦',
    'lettuce': '🥬',
    'spinach': '🥬',
    'pepper': '🌶️',
    'peppers': '🌶️',
    'cucumber': '🥒',
    'corn': '🌽',
    'potato': '🥔',
    'potatoes': '🥔',
    'mushroom': '🍄',
    'mushrooms': '🍄',
    'avocado': '🥑',
    'eggplant': '🍆',
    // Fruits
    'apple': '🍎',
    'banana': '🍌',
    'orange': '🍊',
    'lemon': '🍋',
    'lime': '🍋',
    'strawberry': '🍓',
    'blueberry': '🫐',
    'grape': '🍇',
    'mango': '🥭',
    'peach': '🍑',
    'pineapple': '🍍',
    'coconut': '🥥',
    'cherry': '🍒',
    // Dairy
    'milk': '🥛',
    'cheese': '🧀',
    'butter': '🧈',
    'yogurt': '🥛',
    'cream': '🥛',
    // Grains & Carbs
    'rice': '🍚',
    'bread': '🍞',
    'pasta': '🍝',
    'noodles': '🍜',
    'flour': '🌾',
    'oats': '🌾',
    // Others
    'oil': '🫒',
    'olive': '🫒',
    'salt': '🧂',
    'honey': '🍯',
    'sugar': '🍬',
    'chocolate': '🍫',
    'coffee': '☕',
    'tea': '🍵',
    'water': '💧',
    'wine': '🍷',
    'beer': '🍺',
    'nuts': '🥜',
    'peanut': '🥜',
    'almond': '🥜',
  };

  static const String _defaultIngredientIcon = '🥄';

  String _getIngredientIcon(String ingredient) {
    final lower = ingredient.toLowerCase();
    for (final entry in _ingredientIcons.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return _defaultIngredientIcon;
  }

  @override
  void initState() {
    super.initState();
    meal = widget.meal;
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateMeal(Meal updatedMeal) {
    setState(() {
      meal = updatedMeal;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final medicationProvider = context.watch<MedicationProvider>();

    // Get medication reminders for this meal
    final mealReminders = medicationProvider.getMealReminders(meal.mealType);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _scrollOffset > 200
          ? (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Hero Image
                SliverToBoxAdapter(child: _buildHeroImage(context, isDark)),
                // Content
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -32),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black : Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Handle bar
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(top: 12),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white24 : Colors.black12,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Title & Tags
                          _buildTitleSection(
                            context,
                            isDark,
                            authProvider,
                            bookmarkProvider,
                          ),
                          const SizedBox(height: 20),
                          // Quick Stats
                          _buildQuickStats(context, isDark),
                          const SizedBox(height: 24),
                          // Medication reminder
                          if (mealReminders.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: _buildMedicationReminder(
                                context,
                                isDark,
                                mealReminders,
                              ),
                            ),
                          if (mealReminders.isNotEmpty)
                            const SizedBox(height: 24),
                          // Action Buttons
                          _buildActionButtons(context, isDark, authProvider),
                          const SizedBox(height: 28),
                          // Tab Selector
                          _buildTabSelector(context, isDark),
                          const SizedBox(height: 20),
                          // Tab Content
                          _buildTabContent(context, isDark),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Floating Header
            _buildFloatingHeader(
              context,
              isDark,
              authProvider,
              bookmarkProvider,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: 340,
      width: screenWidth,
      child: Stack(
        fit: StackFit.expand,
        children: [
          meal.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: meal.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => _buildPlaceholderImage(isDark),
                )
              : _buildPlaceholderImage(isDark),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.reserve,
              size: 64,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 8),
            Text(
              'No image',
              style: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingHeader(
    BuildContext context,
    bool isDark,
    AuthProvider authProvider,
    BookmarkProvider bookmarkProvider,
  ) {
    final isScrolled = _scrollOffset > 200;
    final isBookmarked = authProvider.user != null && meal.id != null
        ? bookmarkProvider.isBookmarked(meal.id!)
        : false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: isScrolled
          ? (isDark ? Colors.black : Colors.white)
          : Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Back button
              _buildHeaderButton(
                context,
                isDark,
                Icons.arrow_back_ios_new,
                () => Navigator.pop(context),
                isScrolled: isScrolled,
              ),
              const SizedBox(width: 8),
              // Title (show when scrolled)
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isScrolled ? 1.0 : 0.0,
                  child: Text(
                    meal.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // Action buttons
              _buildHeaderButton(
                context,
                isDark,
                Iconsax.edit_2,
                () => _editMeal(context),
                isScrolled: isScrolled,
              ),
              const SizedBox(width: 8),
              _buildHeaderButton(
                context,
                isDark,
                isBookmarked ? Iconsax.heart5 : Iconsax.heart,
                () => _toggleBookmark(context, authProvider, bookmarkProvider),
                isScrolled: isScrolled,
                isActive: isBookmarked,
              ),
              const SizedBox(width: 8),
              _buildHeaderButton(
                context,
                isDark,
                Iconsax.export_1,
                () => _shareMeal(),
                isScrolled: isScrolled,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton(
    BuildContext context,
    bool isDark,
    IconData icon,
    VoidCallback onTap, {
    bool isScrolled = false,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isScrolled
              ? (isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05))
              : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive
              ? Colors.red
              : (isScrolled
                    ? (isDark ? Colors.white : Colors.black)
                    : Colors.white),
        ),
      ),
    );
  }

  Widget _buildTitleSection(
    BuildContext context,
    bool isDark,
    AuthProvider authProvider,
    BookmarkProvider bookmarkProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meal.name,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          // Tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (meal.mealType.isNotEmpty)
                _buildTag(
                  context,
                  isDark,
                  meal.mealType,
                  _getMealTypeIcon(meal.mealType),
                ),
              if (meal.cuisine != null && meal.cuisine!.isNotEmpty)
                _buildTag(context, isDark, meal.cuisine!, '🌍'),
              if (meal.dietType != null && meal.dietType != 'None')
                _buildTag(context, isDark, meal.dietType!, '🥗'),
              if (meal.difficulty != null)
                _buildTag(context, isDark, meal.difficulty!, '📊'),
            ],
          ),
          if (meal.description != null && meal.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              meal.description!,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getMealTypeIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '🌅';
      case 'lunch':
        return '☀️';
      case 'dinner':
        return '🌙';
      case 'snack':
        return '🍪';
      default:
        return '🍽️';
    }
  }

  Widget _buildTag(
    BuildContext context,
    bool isDark,
    String label,
    String icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (meal.calories != null)
            Expanded(
              child: _buildStatCard(
                context,
                isDark,
                Iconsax.flash_1,
                '${meal.calories}',
                'Calories',
                Colors.orange,
              ),
            ),
          if (meal.calories != null) const SizedBox(width: 12),
          if (meal.prepTime != null)
            Expanded(
              child: _buildStatCard(
                context,
                isDark,
                Iconsax.timer_1,
                '${meal.prepTime}m',
                'Prep',
                Colors.blue,
              ),
            ),
          if (meal.prepTime != null) const SizedBox(width: 12),
          if (meal.cookTime != null)
            Expanded(
              child: _buildStatCard(
                context,
                isDark,
                Iconsax.timer_start,
                '${meal.cookTime}m',
                'Cook',
                Colors.green,
              ),
            ),
          if (meal.cookTime != null) const SizedBox(width: 12),
          if (meal.servings != null)
            Expanded(
              child: _buildStatCard(
                context,
                isDark,
                Iconsax.profile_2user,
                '${meal.servings}',
                'Servings',
                Colors.purple,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    bool isDark,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationReminder(
    BuildContext context,
    bool isDark,
    List<String> reminders,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.health, color: Colors.orange, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medication Reminder',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Take with this meal: ${reminders.join(", ")}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    bool isDark,
    AuthProvider authProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Add to shopping list
          Expanded(
            child: _buildActionButton(
              context,
              isDark,
              Iconsax.shopping_cart,
              'Add to List',
              () => _addToShoppingList(context, authProvider),
            ),
          ),
          const SizedBox(width: 12),
          // Find store
          Expanded(
            child: _buildActionButton(
              context,
              isDark,
              Iconsax.location,
              'Find Store',
              () => _openMapsToStore(context, authProvider),
            ),
          ),
          const SizedBox(width: 12),
          // AI Personalize
          Expanded(
            child: _buildActionButton(
              context,
              isDark,
              Iconsax.magic_star,
              'AI Adjust',
              () => _personalizeMeal(context, authProvider),
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    bool isDark,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary
              ? (isDark ? Colors.white : Colors.black)
              : (isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isPrimary
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isPrimary
                    ? (isDark ? Colors.black : Colors.white)
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector(BuildContext context, bool isDark) {
    final tabs = ['Overview', 'Ingredients', 'Instructions'];
    final ingredients = meal.ingredientsList;
    final steps = _parseInstructions(meal.instructions ?? '');

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTab == index;
          String badge = '';
          if (index == 1 && ingredients.isNotEmpty) {
            badge = '${ingredients.length}';
          } else if (index == 2 && steps.isNotEmpty) {
            badge = '${steps.length}';
          }

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tabs[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? Colors.black : Colors.white)
                              : (isDark ? Colors.white54 : Colors.black54),
                        ),
                      ),
                      if (badge.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                      ? Colors.black.withOpacity(0.2)
                                      : Colors.white.withOpacity(0.2))
                                : (isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? (isDark ? Colors.black54 : Colors.white70)
                                  : (isDark ? Colors.white38 : Colors.black38),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, bool isDark) {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab(context, isDark);
      case 1:
        return _buildIngredientsTab(context, isDark);
      case 2:
        return _buildInstructionsTab(context, isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOverviewTab(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health Score
          _buildHealthScoreCard(context, isDark),
          const SizedBox(height: 20),
          // Nutrition
          _buildNutritionCard(context, isDark),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard(BuildContext context, bool isDark) {
    final score = meal.healthScore;
    final label = meal.healthScoreLabel;
    final color = _getHealthScoreColor(score);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Iconsax.health, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health Score',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500,
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
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Color _getHealthScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  Widget _buildNutritionCard(BuildContext context, bool isDark) {
    final hasNutrition =
        meal.protein != null ||
        meal.carbs != null ||
        meal.fat != null ||
        meal.fiber != null;

    if (!hasNutrition) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.chart_2,
                  size: 20,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Nutrition Facts',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Macro grid
          Row(
            children: [
              if (meal.protein != null)
                Expanded(
                  child: _buildMacroItem(
                    isDark,
                    'Protein',
                    meal.protein!,
                    'g',
                    Colors.blue,
                  ),
                ),
              if (meal.carbs != null)
                Expanded(
                  child: _buildMacroItem(
                    isDark,
                    'Carbs',
                    meal.carbs!,
                    'g',
                    Colors.orange,
                  ),
                ),
              if (meal.fat != null)
                Expanded(
                  child: _buildMacroItem(
                    isDark,
                    'Fat',
                    meal.fat!,
                    'g',
                    Colors.purple,
                  ),
                ),
              if (meal.fiber != null)
                Expanded(
                  child: _buildMacroItem(
                    isDark,
                    'Fiber',
                    meal.fiber!,
                    'g',
                    Colors.green,
                  ),
                ),
            ],
          ),
          if (meal.sugar != null || meal.sodium != null) ...[
            const SizedBox(height: 16),
            Divider(
              color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (meal.sugar != null)
                  Expanded(
                    child: _buildMacroItem(
                      isDark,
                      'Sugar',
                      meal.sugar!,
                      'g',
                      Colors.pink,
                    ),
                  ),
                if (meal.sodium != null)
                  Expanded(
                    child: _buildMacroItem(
                      isDark,
                      'Sodium',
                      meal.sodium!,
                      'mg',
                      Colors.grey,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMacroItem(
    bool isDark,
    String label,
    double value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          '${value.toStringAsFixed(1)}$unit',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsTab(BuildContext context, bool isDark) {
    final ingredients = meal.ingredientsList;
    if (ingredients.isEmpty) {
      return _buildEmptyTabState(isDark, 'No ingredients listed');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: ingredients.asMap().entries.map((entry) {
          final ingredient = entry.value;
          return _buildIngredientItem(context, isDark, ingredient);
        }).toList(),
      ),
    );
  }

  Widget _buildIngredientItem(
    BuildContext context,
    bool isDark,
    String ingredient,
  ) {
    final icon = _getIngredientIcon(ingredient);
    final parts = _parseIngredient(ingredient);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parts['name']!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                if (parts['quantity']!.isNotEmpty)
                  Text(
                    parts['quantity']!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Iconsax.tick_circle,
            size: 22,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
        ],
      ),
    );
  }

  Map<String, String> _parseIngredient(String ingredient) {
    final regex = RegExp(
      r'^([\d½¼¾⅓⅔⅛]+\s*(?:g|kg|ml|l|oz|cup|cups|tbsp|tsp|tablespoon|teaspoon|pound|lb)?\s*)(.+)$',
      caseSensitive: false,
    );
    final match = regex.firstMatch(ingredient.trim());

    if (match != null) {
      return {
        'quantity': match.group(1)?.trim() ?? '',
        'name': match.group(2)?.trim() ?? ingredient,
      };
    }

    return {'quantity': '', 'name': ingredient};
  }

  Widget _buildInstructionsTab(BuildContext context, bool isDark) {
    final steps = _parseInstructions(meal.instructions ?? '');
    if (steps.isEmpty || (steps.length == 1 && steps[0].isEmpty)) {
      return _buildEmptyTabState(isDark, 'No instructions available');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isLast = index == steps.length - 1;
          return _buildInstructionStep(
            context,
            isDark,
            index + 1,
            step,
            isLast,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInstructionStep(
    BuildContext context,
    bool isDark,
    int stepNumber,
    String instruction,
    bool isLast,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step number with line
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$stepNumber',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Step content
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.05),
                ),
              ),
              child: Text(
                instruction,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: isDark
                      ? Colors.white.withOpacity(0.85)
                      : Colors.black.withOpacity(0.75),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTabState(bool isDark, String message) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Iconsax.document,
              size: 48,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _parseInstructions(String instructions) {
    if (instructions.isEmpty) return [];

    List<String> steps = [];

    final numberedPattern = RegExp(
      r'(?:^|\n)\s*(?:\d+[.)\s]|Step\s*\d+[:\s])',
      caseSensitive: false,
    );

    if (numberedPattern.hasMatch(instructions)) {
      steps = instructions
          .split(RegExp(r'\n\s*(?=\d+[.)\s]|Step\s*\d+)', caseSensitive: false))
          .map(
            (s) => s
                .replaceFirst(
                  RegExp(
                    r'^\s*\d+[.)\s]*|^Step\s*\d+[:\s]*',
                    caseSensitive: false,
                  ),
                  '',
                )
                .trim(),
          )
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (instructions.contains('\n')) {
      steps = instructions
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else {
      steps = instructions
          .split(RegExp(r'(?<=[.!?])\s+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return steps.isEmpty ? [instructions] : steps;
  }

  // Action Methods
  Future<void> _toggleBookmark(
    BuildContext context,
    AuthProvider authProvider,
    BookmarkProvider bookmarkProvider,
  ) async {
    if (authProvider.user == null || meal.id == null) return;

    final newState = await bookmarkProvider.toggleBookmark(
      authProvider.user!.id!,
      meal.id!,
      meal,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newState ? 'Added to favorites' : 'Removed from favorites',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: newState ? Colors.green : null,
        ),
      );
    }
  }

  Future<void> _addToShoppingList(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    if (authProvider.user == null) return;

    final shoppingProvider = context.read<ShoppingProvider>();
    final ingredients = meal.ingredientsList;

    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No ingredients to add'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await shoppingProvider.addItemsFromIngredients(
      authProvider.user!.id!,
      ingredients,
      meal.id,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${ingredients.length} ingredients added to list'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _openMapsToStore(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    String storeName = 'grocery store';

    if (authProvider.preferences != null &&
        authProvider.preferences!.preferredStore != 'Any') {
      storeName = authProvider.preferences!.preferredStore;
    }

    final query = Uri.encodeComponent('$storeName near me');
    final mapsUrl = Uri.parse('https://www.google.com/maps/search/$query');

    try {
      if (await canLaunchUrl(mapsUrl)) {
        await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open maps'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _shareMeal() {
    final buffer = StringBuffer();
    buffer.writeln('🍽️ ${meal.name}');
    buffer.writeln();

    if (meal.description != null && meal.description!.isNotEmpty) {
      buffer.writeln(meal.description);
      buffer.writeln();
    }

    if (meal.calories != null || meal.prepTime != null) {
      if (meal.calories != null) buffer.write('🔥 ${meal.calories} cal');
      if (meal.prepTime != null) {
        if (meal.calories != null) buffer.write(' • ');
        buffer.write('⏱️ ${meal.prepTime} min');
      }
      buffer.writeln();
      buffer.writeln();
    }

    final ingredients = meal.ingredientsList;
    if (ingredients.isNotEmpty) {
      buffer.writeln('📝 Ingredients:');
      for (final ing in ingredients) {
        buffer.writeln('• $ing');
      }
      buffer.writeln();
    }

    if (meal.instructions != null && meal.instructions!.isNotEmpty) {
      buffer.writeln('👨‍🍳 Instructions:');
      buffer.writeln(meal.instructions);
    }

    buffer.writeln();
    buffer.writeln('Shared from Meals App');

    Share.share(buffer.toString(), subject: meal.name);
  }

  Future<void> _editMeal(BuildContext context) async {
    final result = await Navigator.push<Meal>(
      context,
      MaterialPageRoute(builder: (context) => EditMealScreen(meal: meal)),
    );

    if (result != null) {
      _updateMeal(result);
    }
  }

  Future<void> _personalizeMeal(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final result = await showModalBottomSheet<Meal>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PersonalizeMealDialog(
        meal: meal,
        preferences: authProvider.preferences,
      ),
    );

    if (result != null) {
      _updateMeal(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe personalized!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
