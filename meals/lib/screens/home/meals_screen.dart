import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/meal_provider.dart';
import '../../data/models/meal.dart';
import '../meals/meal_detail_screen.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _selectedMealType = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mealProvider = context.watch<MealProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, isDark, mealProvider),
              _buildSearchBar(context, isDark, mealProvider),
              _buildMealTypeFilter(context, isDark, mealProvider),
              const SizedBox(height: 8),
              Expanded(
                child: mealProvider.isLoading
                    ? _buildLoadingState(isDark)
                    : mealProvider.filteredMeals.isEmpty
                    ? _buildEmptyState(context, isDark)
                    : _buildMealGrid(context, isDark, mealProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    MealProvider mealProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Meals',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${mealProvider.allMeals.length} recipes saved',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          // Nutrition summary icon
          GestureDetector(
            onTap: () => _showNutritionSheet(context, isDark, mealProvider),
            child: Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Iconsax.chart_21,
                size: 20,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          // Stats badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.reserve,
                  size: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                const SizedBox(width: 6),
                Text(
                  '${mealProvider.filteredMeals.length}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    bool isDark,
    MealProvider mealProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: _isSearching
              ? Border.all(
                  color: isDark ? Colors.white30 : Colors.black26,
                  width: 1.5,
                )
              : null,
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: 'Search by name, cuisine, or ingredient...',
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 15,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(
                Iconsax.search_normal,
                size: 20,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44),
            suffixIcon: _searchController.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      mealProvider.searchMeals('');
                      setState(() {});
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 44),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: (value) {
            mealProvider.searchMeals(value);
            setState(() {});
          },
          onTap: () => setState(() => _isSearching = true),
          onEditingComplete: () {
            _searchFocus.unfocus();
            setState(() => _isSearching = false);
          },
        ),
      ),
    );
  }

  Widget _buildMealTypeFilter(
    BuildContext context,
    bool isDark,
    MealProvider mealProvider,
  ) {
    final mealTypes = [
      {'key': '', 'label': 'All', 'icon': Iconsax.category},
      {'key': 'breakfast', 'label': 'Breakfast', 'icon': Iconsax.sun_1},
      {'key': 'lunch', 'label': 'Lunch', 'icon': Iconsax.sun},
      {'key': 'dinner', 'label': 'Dinner', 'icon': Iconsax.moon},
      {'key': 'snack', 'label': 'Snack', 'icon': Iconsax.coffee},
    ];

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: mealTypes.length,
        itemBuilder: (context, index) {
          final type = mealTypes[index];
          final isSelected = _selectedMealType == type['key'];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMealType = type['key'] as String;
                  mealProvider.filterByMealType(
                    _selectedMealType.isEmpty ? null : _selectedMealType,
                  );
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.04)),
                  borderRadius: BorderRadius.circular(22),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: isDark
                              ? Colors.white12
                              : Colors.black.withOpacity(0.06),
                        ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type['icon'] as IconData,
                      size: 16,
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.white)
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      type['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? Colors.black : Colors.white)
                            : (isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showNutritionSheet(
    BuildContext context,
    bool isDark,
    MealProvider mealProvider,
  ) {
    final meals = mealProvider.filteredMeals;

    // Calculate totals
    int totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;
    int mealsWithNutrition = 0;
    int mealsWithProtein = 0;
    int mealsWithCarbs = 0;
    int mealsWithFat = 0;
    int mealsWithFiber = 0;

    for (final meal in meals) {
      if (meal.calories != null) {
        totalCalories += meal.calories!;
        mealsWithNutrition++;
      }
      if (meal.protein != null) {
        totalProtein += meal.protein!;
        mealsWithProtein++;
      }
      if (meal.carbs != null) {
        totalCarbs += meal.carbs!;
        mealsWithCarbs++;
      }
      if (meal.fat != null) {
        totalFat += meal.fat!;
        mealsWithFat++;
      }
      if (meal.fiber != null) {
        totalFiber += meal.fiber!;
        mealsWithFiber++;
      }
    }

    // Calculate averages
    final avgCalories = mealsWithNutrition > 0
        ? (totalCalories / mealsWithNutrition).round()
        : 0;
    final avgHealthScore = meals.isNotEmpty
        ? (meals.map((m) => m.healthScore).reduce((a, b) => a + b) /
                  meals.length)
              .round()
        : 0;

    final hasAnyNutritionData =
        mealsWithNutrition > 0 ||
        mealsWithProtein > 0 ||
        mealsWithCarbs > 0 ||
        mealsWithFat > 0 ||
        mealsWithFiber > 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Iconsax.chart_21,
                      size: 22,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nutrition Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${meals.length} meals • Health Score $avgHealthScore',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Health score badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getHealthScoreColor(
                        avgHealthScore,
                      ).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$avgHealthScore',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getHealthScoreColor(avgHealthScore),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Divider(
              color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
              height: 1,
            ),

            if (!hasAnyNutritionData)
              // No nutrition data message
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Iconsax.document_text,
                      size: 48,
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No nutrition data available',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add nutrition info to your meals\nto see the summary here',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // Stats content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Main macro row
                    Row(
                      children: [
                        Expanded(
                          child: _buildNutritionStat(
                            isDark,
                            'Calories',
                            _formatNumber(totalCalories),
                            'kcal total',
                            Iconsax.flash_1,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNutritionStat(
                            isDark,
                            'Avg/Meal',
                            '$avgCalories',
                            'kcal',
                            Iconsax.chart_2,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Macronutrient cards
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MACRONUTRIENTS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildMacroItem(
                                isDark,
                                'Protein',
                                totalProtein.toStringAsFixed(1),
                                'g',
                                Colors.red,
                                mealsWithProtein,
                              ),
                              _buildMacroItem(
                                isDark,
                                'Carbs',
                                totalCarbs.toStringAsFixed(1),
                                'g',
                                Colors.amber,
                                mealsWithCarbs,
                              ),
                              _buildMacroItem(
                                isDark,
                                'Fat',
                                totalFat.toStringAsFixed(1),
                                'g',
                                Colors.purple,
                                mealsWithFat,
                              ),
                              _buildMacroItem(
                                isDark,
                                'Fiber',
                                totalFiber.toStringAsFixed(1),
                                'g',
                                Colors.green,
                                mealsWithFiber,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Info text
                    Text(
                      mealsWithNutrition == meals.length
                          ? 'Showing data for all ${meals.length} meals'
                          : 'Data available for $mealsWithNutrition of ${meals.length} meals',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionStat(
    bool isDark,
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(
    bool isDark,
    String label,
    String value,
    String unit,
    Color color,
    int mealsWithData,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                TextSpan(
                  text: unit,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          if (mealsWithData > 0)
            Text(
              '($mealsWithData)',
              style: TextStyle(
                fontSize: 9,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return '$number';
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading meals...',
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final hasSearch = _searchController.text.isNotEmpty;
    final hasFilter = _selectedMealType.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasSearch || hasFilter
                    ? Iconsax.search_status
                    : Iconsax.reserve,
                size: 48,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasSearch || hasFilter ? 'No matches found' : 'No meals yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch || hasFilter
                  ? 'Try adjusting your search or filters'
                  : 'Discover new recipes and save\nthem to your collection',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasSearch || hasFilter) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _selectedMealType = '');
                  context.read<MealProvider>().searchMeals('');
                  context.read<MealProvider>().filterByMealType(null);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Clear filters',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMealGrid(
    BuildContext context,
    bool isDark,
    MealProvider mealProvider,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: mealProvider.filteredMeals.length,
      itemBuilder: (context, index) {
        final meal = mealProvider.filteredMeals[index];
        return _buildMealCard(context, isDark, meal);
      },
    );
  }

  Widget _buildMealCard(BuildContext context, bool isDark, Meal meal) {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => MealDetailScreen(meal: meal)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    meal.imageUrl != null && meal.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: meal.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: isDark ? Colors.white10 : Colors.grey[200],
                              child: Center(
                                child: Icon(
                                  Iconsax.image,
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black12,
                                  size: 32,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: isDark ? Colors.white10 : Colors.grey[200],
                              child: Center(
                                child: Icon(
                                  Iconsax.gallery_slash,
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black12,
                                  size: 32,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: isDark ? Colors.white10 : Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Iconsax.reserve,
                                color: isDark ? Colors.white24 : Colors.black12,
                                size: 32,
                              ),
                            ),
                          ),
                    // Meal type badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withOpacity(0.7)
                              : Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getMealTypeEmoji(meal.mealType),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    // Cuisine badge
                    if (meal.cuisine != null && meal.cuisine!.isNotEmpty)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withOpacity(0.7)
                                : Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            meal.cuisine!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            meal.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Health score indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _getHealthScoreColor(
                              meal.healthScore,
                            ).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${meal.healthScore}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getHealthScoreColor(meal.healthScore),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (meal.calories != null) ...[
                          Icon(
                            Iconsax.flash_1,
                            size: 12,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${meal.calories} cal',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                        if (meal.prepTime != null) ...[
                          if (meal.calories != null) const SizedBox(width: 10),
                          Icon(
                            Iconsax.clock,
                            size: 12,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${meal.prepTime}m',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMealTypeEmoji(String mealType) {
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

  Color _getHealthScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}
