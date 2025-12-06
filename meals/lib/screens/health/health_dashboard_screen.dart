import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/models/meal.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/meal_provider.dart';
import 'health_profile_setup_screen.dart';

class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHealth();
    });
  }

  Future<void> _initializeHealth() async {
    final healthProvider = context.read<HealthProvider>();
    final authProvider = context.read<AuthProvider>();

    if (!healthProvider.isConfigured) {
      await healthProvider.configure();
    }

    // Load health profile for the current user
    final userId = authProvider.user?.id;
    if (userId != null && healthProvider.healthProfile == null) {
      await healthProvider.loadHealthProfile(userId);
    }
  }

  String get _healthServiceName =>
      Platform.isIOS ? 'Apple Health' : 'Samsung Health';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        title: Text(
          _healthServiceName,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          Consumer<HealthProvider>(
            builder: (context, provider, child) {
              if (!provider.isAuthorized) return const SizedBox();
              return IconButton(
                onPressed: provider.isLoading
                    ? null
                    : () => provider.fetchHealthData(),
                icon: provider.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      )
                    : Icon(
                        Icons.refresh_rounded,
                        color: isDark ? Colors.white : Colors.black,
                      ),
              );
            },
          ),
        ],
      ),
      body: Consumer<HealthProvider>(
        builder: (context, provider, child) {
          debugPrint(
            'HealthDashboard: isAuthorized=${provider.isAuthorized}, hasProfile=${provider.hasProfile}, profile=${provider.healthProfile?.isComplete}',
          );

          if (!provider.isHealthConnectAvailable && Platform.isAndroid) {
            return _buildHealthConnectRequired(isDark);
          }

          if (!provider.isAuthorized) {
            return _buildConnectPrompt(provider, isDark);
          }

          if (!provider.hasProfile) {
            return _buildProfileSetup(provider, isDark);
          }

          return _buildDashboard(provider, isDark);
        },
      ),
    );
  }

  Widget _buildHealthConnectRequired(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.health_and_safety_outlined,
                size: 48,
                color: isDark ? Colors.white54 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Health Connect Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Samsung Health syncs through Health Connect.\nPlease install it from Play Store.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectPrompt(HealthProvider provider, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.favorite_rounded,
                size: 48,
                color: isDark ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Connect $_healthServiceName',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Get personalized meal plans based on your\nhealth profile and activity level.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeatureItem(
                    Icons.restaurant_menu,
                    'Personalized calorie targets',
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    Icons.directions_walk,
                    'Activity-based recommendations',
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    Icons.pie_chart_outline,
                    'Macro tracking & balance',
                    isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: provider.isLoading
                    ? null
                    : () => provider.requestAuthorization(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: provider.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      )
                    : const Text(
                        'Connect Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSetup(HealthProvider provider, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.person_outline,
                size: 48,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Set Up Your Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'We need some info to calculate your\npersonalized nutrition targets.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HealthProfileSetupScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(HealthProvider provider, bool isDark) {
    final nutrition = provider.todayNutrition;
    final profile = provider.healthProfile;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Energy Balance Card
          _buildEnergyBalanceCard(nutrition, profile, isDark),
          const SizedBox(height: 20),

          // Macros Progress
          _buildMacrosCard(nutrition, isDark),
          const SizedBox(height: 20),

          // Activity & Water
          Row(
            children: [
              Expanded(child: _buildActivityCard(provider, isDark)),
              const SizedBox(width: 12),
              Expanded(child: _buildWaterCard(provider, isDark)),
            ],
          ),
          const SizedBox(height: 20),

          // Quick Actions
          _buildQuickActions(provider, isDark),
          const SizedBox(height: 20),

          // Today's Meals
          _buildTodaysMeals(provider, isDark),
          const SizedBox(height: 20),

          // Profile Summary
          _buildProfileCard(provider, isDark),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEnergyBalanceCard(
    NutritionSummary? nutrition,
    dynamic profile,
    bool isDark,
  ) {
    final consumed = nutrition?.caloriesConsumed ?? 0;
    final burned = nutrition?.caloriesBurned ?? 0;
    final target = nutrition?.caloriesTarget ?? 2000;
    final remaining = nutrition?.caloriesRemaining ?? target;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white : Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Energy Balance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Goal: $target kcal',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$remaining',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                    Text(
                      'kcal remaining',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: (consumed / target).clamp(0.0, 1.0),
                        strokeWidth: 8,
                        backgroundColor: isDark
                            ? Colors.black.withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          consumed > target
                              ? Colors.red.shade400
                              : Colors.greenAccent,
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${((consumed / target) * 100).round()}%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildEnergyItem(
                  'Consumed',
                  '$consumed',
                  Icons.restaurant,
                  Colors.greenAccent,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.1),
              ),
              Expanded(
                child: _buildEnergyItem(
                  'Burned',
                  '$burned',
                  Icons.local_fire_department,
                  Colors.orangeAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMacrosCard(NutritionSummary? nutrition, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Macros',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildMacroRow(
            'Protein',
            nutrition?.proteinConsumed ?? 0,
            nutrition?.proteinTarget ?? 50,
            'g',
            Colors.red.shade400,
            isDark,
          ),
          const SizedBox(height: 14),
          _buildMacroRow(
            'Carbs',
            nutrition?.carbsConsumed ?? 0,
            nutrition?.carbsTarget ?? 250,
            'g',
            Colors.amber.shade600,
            isDark,
          ),
          const SizedBox(height: 14),
          _buildMacroRow(
            'Fat',
            nutrition?.fatConsumed ?? 0,
            nutrition?.fatTarget ?? 65,
            'g',
            Colors.purple.shade400,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow(
    String label,
    int consumed,
    int target,
    String unit,
    Color color,
    bool isDark,
  ) {
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            Text(
              '$consumed / $target$unit',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(HealthProvider provider, bool isDark) {
    final steps = provider.todaySteps;
    final goal = 10000;
    final progress = (steps / goal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_walk,
                size: 18,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                'Steps',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$steps',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Text(
            '/ $goal',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterCard(HealthProvider provider, bool isDark) {
    final water = provider.todayWaterIntake;
    final goal = provider.healthProfile?.waterTarget != null
        ? provider.healthProfile!.waterTarget! / 1000
        : 2.5;
    final progress = (water / goal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop, size: 18, color: Colors.blue.shade400),
              const SizedBox(width: 6),
              Text(
                'Water',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${water.toStringAsFixed(1)}L',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Text(
            '/ ${goal.toStringAsFixed(1)}L',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(HealthProvider provider, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.water_drop_outlined,
            label: 'Log Water',
            onTap: () => _showWaterSheet(provider),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.monitor_weight_outlined,
            label: 'Log Weight',
            onTap: () => _showWeightSheet(provider),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white : Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isDark ? Colors.black : Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysMeals(HealthProvider provider, bool isDark) {
    return Consumer<MealProvider>(
      builder: (context, mealProvider, child) {
        final todayWeekday = DateTime.now().weekday - 1;
        final todayMeals = mealProvider.weekPlan
            .where(
              (plan) => plan.dayOfWeek == todayWeekday && plan.meal != null,
            )
            .map((plan) => plan.meal!)
            .toList();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today\'s Meals',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  if (todayMeals.isNotEmpty)
                    GestureDetector(
                      onTap: () => _syncAllMeals(todayMeals, provider),
                      child: Text(
                        'Sync All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (todayMeals.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.restaurant_menu_outlined,
                          size: 32,
                          color: isDark ? Colors.white38 : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No meals planned',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.white54
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...todayMeals.map(
                  (meal) => _buildMealItem(meal, provider, isDark),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMealItem(Meal meal, HealthProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                _getMealEmoji(meal.mealType),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${meal.calories ?? 0} kcal',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final success = await provider.syncMealToHealth(meal);
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(success ? 'Synced!' : 'Failed to sync'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Sync',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(HealthProvider provider, bool isDark) {
    final profile = provider.healthProfile;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HealthProfileSetupScreen(),
                    ),
                  );
                },
                child: Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildProfileStat(
                'BMR',
                '${profile?.bmr?.round() ?? '--'}',
                'kcal',
                isDark,
              ),
              _buildProfileStat(
                'TDEE',
                '${profile?.tdee?.round() ?? '--'}',
                'kcal',
                isDark,
              ),
              _buildProfileStat(
                'BMI',
                profile?.bmi?.toStringAsFixed(1) ?? '--',
                profile?.bmiCategory ?? '',
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                Icons.person_outline,
                profile?.sex?.capitalize ?? '--',
                isDark,
              ),
              _buildInfoChip(
                Icons.cake_outlined,
                '${profile?.age ?? '--'} yrs',
                isDark,
              ),
              _buildInfoChip(
                Icons.straighten,
                '${profile?.height?.round() ?? '--'} cm',
                isDark,
              ),
              _buildInfoChip(
                Icons.monitor_weight_outlined,
                '${profile?.weight?.round() ?? '--'} kg',
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStat(
    String label,
    String value,
    String unit,
    bool isDark,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Text(
            unit.isNotEmpty ? '$label ($unit)' : label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? Colors.white70 : Colors.grey.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  String _getMealEmoji(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '🍳';
      case 'lunch':
        return '🥗';
      case 'dinner':
        return '🍽️';
      case 'snack':
        return '🍎';
      default:
        return '🍴';
    }
  }

  Future<void> _syncAllMeals(List<Meal> meals, HealthProvider provider) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    int successCount = 0;

    for (final meal in meals) {
      final success = await provider.syncMealToHealth(meal);
      if (success) successCount++;
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Synced $successCount/${meals.length} meals'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showWaterSheet(HealthProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Log Water',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWaterOption(
                  sheetContext,
                  '250ml',
                  0.25,
                  provider,
                  isDark,
                ),
                _buildWaterOption(sheetContext, '500ml', 0.5, provider, isDark),
                _buildWaterOption(sheetContext, '1L', 1.0, provider, isDark),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterOption(
    BuildContext sheetContext,
    String label,
    double liters,
    HealthProvider provider,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () async {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        Navigator.pop(sheetContext);
        final success = await provider.logWater(liters);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(success ? 'Water logged!' : 'Failed'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.water_drop_outlined,
              size: 24,
              color: isDark ? Colors.white : Colors.black,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWeightSheet(HealthProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(
      text: provider.latestWeight?.toStringAsFixed(1) ?? '70.0',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Log Weight',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  suffix: Text(
                    'kg',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black,
                    ),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final weight = double.tryParse(controller.text);
                    if (weight != null) {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      Navigator.pop(sheetContext);
                      final success = await provider.logWeight(weight);
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Weight logged!' : 'Failed'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
