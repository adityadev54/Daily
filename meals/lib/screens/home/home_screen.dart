import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/pantry_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/ai_provider.dart';
import '../../widgets/common/custom_bottom_nav_bar.dart';
import 'meal_plan_screen.dart';
import 'meals_screen.dart';
import 'profile_screen.dart';
import '../meals/discover_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MealPlanScreen(),
    MealsScreen(),
    DiscoverScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final mealProvider = context.read<MealProvider>();
    final authProvider = context.read<AuthProvider>();
    final shoppingProvider = context.read<ShoppingProvider>();
    final bookmarkProvider = context.read<BookmarkProvider>();
    final medicationProvider = context.read<MedicationProvider>();
    final pantryProvider = context.read<PantryProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final aiProvider = context.read<AIProvider>();

    await mealProvider.loadMeals();
    if (authProvider.user != null) {
      final userId = authProvider.user!.id!;
      await mealProvider.loadMealPlan(userId);
      await shoppingProvider.loadItems(userId);
      await bookmarkProvider.loadBookmarks(userId);
      await medicationProvider.loadMedications(userId);
      await pantryProvider.loadItems(userId);
      await budgetProvider.loadData(userId);

      // Initialize AI provider with user data
      await aiProvider.initForUser(
        userId,
        isSubscriber: authProvider.isSubscribed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
