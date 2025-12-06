import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../data/models/meal_plan.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_provider.dart';
import '../../core/constants/app_strings.dart';
import '../meals/meal_selection_screen.dart';
import '../meals/meal_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll to today after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    final todayIndex = DateTime.now().weekday - 1;
    if (todayIndex >= 0 && todayIndex <= 6 && _scrollController.hasClients) {
      // Each day card is approximately 160 width + 12 margin
      final offset = (todayIndex * 172.0) - 20;
      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mealProvider = context.watch<MealProvider>();
    final authProvider = context.watch<AuthProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, isDark, mealProvider, authProvider),
              Expanded(
                child: mealProvider.isLoading
                    ? _buildLoadingState(isDark)
                    : _buildWeekView(
                        context,
                        isDark,
                        mealProvider,
                        authProvider,
                      ),
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
    AuthProvider authProvider,
  ) {
    // Calculate total meals planned and weekly calories
    int mealsPlanned = 0;
    int totalWeeklyCalories = 0;
    for (int i = 0; i < 7; i++) {
      for (final type in ['breakfast', 'lunch', 'dinner', 'snack']) {
        final mealPlan = mealProvider.getMealForDayAndType(i, type);
        if (mealPlan != null) {
          mealsPlanned++;
          totalWeeklyCalories += mealPlan.meal?.calories ?? 0;
        }
      }
    }

    // Format calories for display
    String formattedCalories = totalWeeklyCalories >= 1000
        ? '${(totalWeeklyCalories / 1000).toStringAsFixed(1)}k'
        : '$totalWeeklyCalories';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meal Plan',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mealProvider.getWeekDateRange(),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              // Stats badges
              if (mealsPlanned > 0)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$mealsPlanned meals',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
                            Iconsax.flash_1,
                            size: 12,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$formattedCalories cal',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Week navigation
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  mealProvider.goToPreviousWeek();
                  if (authProvider.user != null) {
                    await mealProvider.loadMealPlan(authProvider.user!.id!);
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 22,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    mealProvider.goToCurrentWeek();
                    if (authProvider.user != null) {
                      await mealProvider.loadMealPlan(authProvider.user!.id!);
                    }
                    _scrollToToday();
                  },
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.calendar_1,
                            size: 16,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Jump to Today',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  mealProvider.goToNextWeek();
                  if (authProvider.user != null) {
                    await mealProvider.loadMealPlan(authProvider.user!.id!);
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
            'Loading meal plan...',
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView(
    BuildContext context,
    bool isDark,
    MealProvider mealProvider,
    AuthProvider authProvider,
  ) {
    final now = DateTime.now();
    final weekStart = mealProvider.selectedWeek;

    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      itemCount: 7,
      itemBuilder: (context, dayIndex) {
        final dayDate = weekStart.add(Duration(days: dayIndex));
        final isToday =
            dayDate.day == now.day &&
            dayDate.month == now.month &&
            dayDate.year == now.year;

        return _buildDayColumn(
          context,
          isDark,
          dayIndex,
          dayDate,
          isToday,
          mealProvider,
          authProvider,
        );
      },
    );
  }

  Widget _buildDayColumn(
    BuildContext context,
    bool isDark,
    int dayIndex,
    DateTime dayDate,
    bool isToday,
    MealProvider mealProvider,
    AuthProvider authProvider,
  ) {
    final mealTypes = [
      {'key': 'breakfast', 'emoji': '🌅', 'label': 'Breakfast'},
      {'key': 'lunch', 'emoji': '☀️', 'label': 'Lunch'},
      {'key': 'dinner', 'emoji': '🌙', 'label': 'Dinner'},
      {'key': 'snack', 'emoji': '🍪', 'label': 'Snack'},
    ];

    return Container(
      width: 160,
      margin: EdgeInsets.only(right: dayIndex < 6 ? 12 : 0),
      child: Column(
        children: [
          // Day header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isToday
                  ? (isDark ? Colors.white : Colors.black)
                  : (isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.03)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  AppStrings.weekDays[dayIndex].substring(0, 3),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isToday
                        ? (isDark ? Colors.black54 : Colors.white70)
                        : (isDark ? Colors.white54 : Colors.black45),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dayDate.day.toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isToday
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark ? Colors.white : Colors.black),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Meal slots
          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mealTypes.length,
              itemBuilder: (context, index) {
                final type = mealTypes[index];
                final mealPlan = mealProvider.getMealForDayAndType(
                  dayIndex,
                  type['key'] as String,
                );
                return _buildCompactMealSlot(
                  context,
                  isDark,
                  dayIndex,
                  type['key'] as String,
                  type['emoji'] as String,
                  type['label'] as String,
                  mealPlan,
                  mealProvider,
                  authProvider,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMealSlot(
    BuildContext context,
    bool isDark,
    int dayIndex,
    String mealType,
    String emoji,
    String label,
    MealPlan? mealPlan,
    MealProvider mealProvider,
    AuthProvider authProvider,
  ) {
    final hasMeal = mealPlan?.meal != null;

    return GestureDetector(
      onTap: () async {
        if (hasMeal) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MealDetailScreen(meal: mealPlan!.meal!),
            ),
          );
        } else {
          final result = await Navigator.of(context).push<int>(
            MaterialPageRoute(
              builder: (_) => MealSelectionScreen(mealType: mealType),
            ),
          );

          if (result != null && authProvider.user != null) {
            await mealProvider.addMealToPlan(
              userId: authProvider.user!.id!,
              mealId: result,
              dayOfWeek: dayIndex,
              mealType: mealType,
            );
          }
        }
      },
      onLongPress: hasMeal
          ? () => _showRemoveDialog(
              context,
              mealPlan!,
              mealProvider,
              authProvider,
            )
          : null,
      child: Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: hasMeal
              ? (isDark ? Colors.white.withOpacity(0.06) : Colors.white)
              : (isDark
                    ? Colors.white.withOpacity(0.03)
                    : Colors.black.withOpacity(0.02)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasMeal
                ? (isDark ? Colors.white12 : Colors.black.withOpacity(0.06))
                : (isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
          ),
        ),
        child: hasMeal
            ? _buildFilledCompactSlot(isDark, emoji, mealPlan!)
            : _buildEmptyCompactSlot(isDark, emoji, label),
      ),
    );
  }

  Widget _buildEmptyCompactSlot(bool isDark, String emoji, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white38 : Colors.black26,
          ),
        ),
        const SizedBox(height: 4),
        Icon(
          Icons.add_rounded,
          size: 16,
          color: isDark ? Colors.white24 : Colors.black12,
        ),
      ],
    );
  }

  Widget _buildFilledCompactSlot(bool isDark, String emoji, MealPlan mealPlan) {
    final meal = mealPlan.meal!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          if (meal.imageUrl != null && meal.imageUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: meal.imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(color: isDark ? Colors.white10 : Colors.grey[200]),
              errorWidget: (_, __, ___) => Container(
                color: isDark ? Colors.white10 : Colors.grey[200],
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
            )
          else
            Container(
              color: isDark ? Colors.white10 : Colors.grey[200],
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
          ),
          // Content
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  meal.name,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (meal.calories != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${meal.calories} cal',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Emoji badge
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(
    BuildContext context,
    MealPlan mealPlan,
    MealProvider mealProvider,
    AuthProvider authProvider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.trash, size: 28, color: Colors.red[400]),
            ),
            const SizedBox(height: 16),
            Text(
              'Remove Meal?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Remove "${mealPlan.meal?.name}" from your meal plan?',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      if (authProvider.user != null && mealPlan.id != null) {
                        await mealProvider.removeMealFromPlan(
                          mealPlan.id!,
                          authProvider.user!.id!,
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.red[400],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Remove',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
