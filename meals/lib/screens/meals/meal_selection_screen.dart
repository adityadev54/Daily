import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../data/models/meal.dart';
import '../../providers/meal_provider.dart';

class MealSelectionScreen extends StatefulWidget {
  final String mealType;

  const MealSelectionScreen({super.key, required this.mealType});

  @override
  State<MealSelectionScreen> createState() => _MealSelectionScreenState();
}

class _MealSelectionScreenState extends State<MealSelectionScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<Meal> _getFilteredMeals(MealProvider mealProvider) {
    final meals = mealProvider.getMealsByType(widget.mealType);

    if (_searchQuery.isEmpty) {
      return meals;
    }

    return meals.where((meal) {
      final nameLower = meal.name.toLowerCase();
      final descLower = meal.description?.toLowerCase() ?? '';
      final queryLower = _searchQuery.toLowerCase();
      return nameLower.contains(queryLower) || descLower.contains(queryLower);
    }).toList();
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

  String _getMealTypeLabel(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      case 'snack':
        return 'Snack';
      default:
        return mealType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mealProvider = context.watch<MealProvider>();
    final filteredMeals = _getFilteredMeals(mealProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context, isDark, filteredMeals.length),
              // Search Bar
              _buildSearchBar(context, isDark),
              // Content
              Expanded(
                child: mealProvider.isLoading
                    ? _buildLoadingState(isDark)
                    : filteredMeals.isEmpty
                    ? _buildEmptyState(context, isDark)
                    : _buildMealsList(context, isDark, filteredMeals),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, int mealCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getMealTypeIcon(widget.mealType),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Select ${_getMealTypeLabel(widget.mealType)}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Choose a meal to add to your plan',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          // Meal count badge
          if (mealCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$mealCount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(_isSearchFocused ? 0.12 : 0.08)
              : Colors.black.withOpacity(_isSearchFocused ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isSearchFocused
                ? (isDark ? Colors.white24 : Colors.black12)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: 'Search meals...',
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 16,
            ),
            prefixIcon: Icon(
              Iconsax.search_normal,
              color: _isSearchFocused
                  ? (isDark ? Colors.white70 : Colors.black54)
                  : (isDark ? Colors.white38 : Colors.black26),
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Icon(
                      Iconsax.close_circle5,
                      color: isDark ? Colors.white38 : Colors.black26,
                      size: 20,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: (query) => setState(() => _searchQuery = query),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading meals...',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final hasSearch = _searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasSearch ? Iconsax.search_normal : Iconsax.reserve,
                size: 48,
                color: isDark ? Colors.white24 : Colors.black12,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasSearch
                  ? 'No results found'
                  : 'No ${_getMealTypeLabel(widget.mealType).toLowerCase()} meals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Try a different search term'
                  : 'Add some ${widget.mealType} meals first',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasSearch) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
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
                    'Clear Search',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54,
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

  Widget _buildMealsList(BuildContext context, bool isDark, List<Meal> meals) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];
        return _buildMealCard(context, isDark, meal);
      },
    );
  }

  Widget _buildMealCard(BuildContext context, bool isDark, Meal meal) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(meal.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 110,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(19),
              ),
              child: SizedBox(
                width: 110,
                height: 110,
                child: meal.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: meal.imageUrl!,
                        fit: BoxFit.cover,
                        width: 110,
                        height: 110,
                        placeholder: (_, __) => Container(
                          width: 110,
                          height: 110,
                          color: isDark
                              ? const Color(0xFF1C1C1E)
                              : Colors.grey[200],
                          child: Center(
                            child: Icon(
                              Iconsax.reserve,
                              color: isDark ? Colors.white24 : Colors.black12,
                              size: 24,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 110,
                          height: 110,
                          color: isDark
                              ? const Color(0xFF1C1C1E)
                              : Colors.grey[200],
                          child: Center(
                            child: Icon(
                              Iconsax.reserve,
                              color: isDark ? Colors.white24 : Colors.black12,
                              size: 24,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        width: 110,
                        height: 110,
                        color: isDark
                            ? const Color(0xFF1C1C1E)
                            : Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Iconsax.reserve,
                            color: isDark ? Colors.white24 : Colors.black12,
                            size: 24,
                          ),
                        ),
                      ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    Text(
                      meal.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Stats row
                    Row(
                      children: [
                        if (meal.calories != null) ...[
                          Icon(Iconsax.flash_1, size: 13, color: Colors.orange),
                          const SizedBox(width: 3),
                          Text(
                            '${meal.calories} cal',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black38,
                            ),
                          ),
                        ],
                        if (meal.calories != null && meal.prepTime != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '•',
                              style: TextStyle(
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                            ),
                          ),
                        if (meal.prepTime != null) ...[
                          Icon(Iconsax.timer_1, size: 13, color: Colors.blue),
                          const SizedBox(width: 3),
                          Text(
                            '${meal.prepTime}m',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.black45,
                            ),
                          ),
                        ],
                        if (meal.cuisine != null &&
                            meal.cuisine!.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '•',
                              style: TextStyle(
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              meal.cuisine!,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : Colors.black38,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Select indicator
            Container(
              margin: const EdgeInsets.only(right: 12),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Iconsax.add,
                size: 16,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
