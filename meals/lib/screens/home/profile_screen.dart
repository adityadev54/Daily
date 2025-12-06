import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/pantry_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/ai_provider.dart';
import '../../providers/health_provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/constants/app_strings.dart';
import '../../widgets/common/selectable_chip.dart';
import '../../data/models/user_preferences.dart';
import '../../data/models/user_api_key.dart';
import '../../services/notification_service.dart';
import '../admin/admin_screen.dart';
import '../feedback/feedback_screen.dart';
import '../shopping/shopping_list_screen.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../medications/medications_screen.dart';
import '../pantry/pantry_screen.dart';
import '../budget/budget_screen.dart';
import '../settings/changelog_screen.dart';
import '../subscription/subscription_screen.dart';
import '../health/health_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTabIndex = 0;
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = authProvider.user;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'User',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        themeProvider.isDarkMode ? Iconsax.sun_1 : Iconsax.moon,
                        size: 22,
                      ),
                      onPressed: () => themeProvider.toggleTheme(),
                    ),
                    IconButton(
                      icon: const Icon(Iconsax.setting_2, size: 22),
                      onPressed: () => _showSettingsSheet(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Custom Tab Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildTabItem(context, 0, 'Overview'),
                      _buildTabItem(context, 1, 'Preferences'),
                      _buildTabItem(context, 2, 'Account'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _selectedTabIndex = index);
                  },
                  children: [
                    _buildOverviewTab(context),
                    _buildPreferencesTab(context),
                    _buildAccountTab(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, int index, String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
                ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
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

  Widget _buildOverviewTab(BuildContext context) {
    final theme = Theme.of(context);
    final shoppingProvider = context.watch<ShoppingProvider>();
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final medicationProvider = context.watch<MedicationProvider>();
    final pantryProvider = context.watch<PantryProvider>();
    final budgetProvider = context.watch<BudgetProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        // Premium Banner
        _buildPremiumBanner(context),
        const SizedBox(height: 28),

        // Your Kitchen Section
        Text(
          'Your Kitchen',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.secondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildKitchenRow(
          context,
          icon: Iconsax.shopping_cart,
          title: 'Shopping List',
          value: '${shoppingProvider.uncheckedCount}',
          subtitle: 'items to buy',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ShoppingListScreen())),
        ),
        _buildKitchenRow(
          context,
          icon: Iconsax.heart,
          title: 'Saved Recipes',
          value: '${bookmarkProvider.count}',
          subtitle: 'recipes',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const BookmarksScreen())),
        ),
        _buildKitchenRow(
          context,
          icon: Iconsax.box_1,
          title: 'Pantry',
          value: '${pantryProvider.itemCount}',
          subtitle: pantryProvider.expiringCount > 0
              ? '${pantryProvider.expiringCount} expiring'
              : 'items',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PantryScreen())),
        ),
        _buildKitchenRow(
          context,
          icon: Iconsax.wallet_2,
          title: 'Budget',
          value:
              '${budgetProvider.currencySymbol}${budgetProvider.weeklySpending.toStringAsFixed(0)}',
          subtitle:
              'of ${budgetProvider.currencySymbol}${budgetProvider.weeklyBudget.toStringAsFixed(0)}',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const BudgetScreen())),
          isLast: true,
        ),
        const SizedBox(height: 28),

        // Health Section
        Text(
          'Health',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.secondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Consumer<HealthProvider>(
          builder: (context, healthProvider, _) => _buildSimpleRow(
            context,
            icon: Iconsax.heart_tick,
            title: Platform.isAndroid ? 'Samsung Health' : 'Apple Health',
            subtitle: healthProvider.isAuthorized
                ? 'Connected'
                : 'Not connected',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HealthDashboardScreen()),
            ),
          ),
        ),
        _buildSimpleRow(
          context,
          icon: Iconsax.health,
          title: 'Medications',
          subtitle: '${medicationProvider.activeCount} active',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const MedicationsScreen())),
          isLast: true,
        ),
        const SizedBox(height: 28),

        // More Section
        Text(
          'More',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.secondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildSimpleRow(
          context,
          icon: Iconsax.magic_star,
          title: "What's New",
          subtitle: 'v2.0.0',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ChangelogScreen())),
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildPremiumBanner(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Iconsax.crown5,
                color: isDark ? Colors.black : Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to Premium',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Unlock all features',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Iconsax.arrow_right_3,
              size: 18,
              color: theme.colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        leading: Icon(icon, size: 22),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Iconsax.arrow_right_3,
              size: 16,
              color: theme.colorScheme.secondary,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildKitchenRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        leading: Icon(icon, size: 22),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Iconsax.arrow_right_3,
              size: 16,
              color: theme.colorScheme.secondary,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildPreferencesTab(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final preferences = authProvider.preferences;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        _buildPreferenceSection(
          context,
          title: 'Household',
          child: _buildHouseholdSelector(context, authProvider, preferences),
        ),
        const SizedBox(height: 20),
        _buildPreferenceSection(
          context,
          title: 'Cooking Experience',
          child: _buildCookingExperienceSelector(
            context,
            authProvider,
            preferences,
          ),
        ),
        const SizedBox(height: 20),
        _buildPreferenceSection(
          context,
          title: 'Diet Type',
          child: _buildDietTypeSelector(context, authProvider, preferences),
        ),
        const SizedBox(height: 20),
        _buildPreferenceSection(
          context,
          title: 'Allergies',
          child: _buildAllergiesSelector(context, authProvider, preferences),
        ),
        const SizedBox(height: 20),
        _buildPreferenceSection(
          context,
          title: 'Nutrition Goals',
          child: _buildNutritionGoalsSelector(
            context,
            authProvider,
            preferences,
          ),
        ),
        const SizedBox(height: 20),
        _buildPreferenceSection(
          context,
          title: 'Favorite Cuisines',
          child: _buildCuisineSelector(context, authProvider, preferences),
        ),
        const SizedBox(height: 20),
        _buildPreferenceSection(
          context,
          title: 'Disliked Ingredients',
          child: _buildDislikesSelector(context, authProvider, preferences),
        ),
        const SizedBox(height: 20),
        _buildPreferenceSection(
          context,
          title: 'Preferred Store',
          child: _buildStoreSelector(context, authProvider, preferences),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPreferenceSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.secondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildAccountTab(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        // Account Section
        Text(
          'Account',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.secondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildAccountRow(
          context,
          icon: Iconsax.user_edit,
          title: 'Edit Profile',
          onTap: () => _showEditNameDialog(context, authProvider),
        ),
        _buildAccountRow(
          context,
          icon: Iconsax.lock,
          title: 'Change Password',
          onTap: () => _showChangePasswordDialog(context, authProvider),
        ),
        _buildAccountRow(
          context,
          icon: Iconsax.crown,
          title: 'Subscription',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
        ),
        _buildAccountRow(
          context,
          icon: Iconsax.magic_star,
          title: 'Chef AI',
          onTap: () => _showApiKeysDialog(context),
          isLast: true,
        ),
        const SizedBox(height: 28),

        // Support Section
        Text(
          'Support',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.secondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildAccountRow(
          context,
          icon: Iconsax.message_favorite,
          title: 'Send Feedback',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const FeedbackScreen())),
        ),
        _buildAccountRow(
          context,
          icon: Iconsax.document,
          title: 'Privacy Policy',
          onTap: () {},
        ),
        _buildAccountRow(
          context,
          icon: Iconsax.document_text,
          title: 'Terms of Service',
          onTap: () {},
          isLast: true,
        ),
        const SizedBox(height: 28),

        // Danger Zone
        _buildAccountRow(
          context,
          icon: Iconsax.logout,
          title: 'Logout',
          onTap: () => _showLogoutDialog(context, authProvider),
          isDestructive: true,
          isLast: true,
        ),
        const SizedBox(height: 32),

        // Version
        Center(
          child: Text(
            'Meals v2.0.0',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAccountRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isDestructive ? theme.colorScheme.error : null;

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        leading: Icon(icon, size: 22, color: color),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        trailing: isDestructive
            ? null
            : Icon(
                Iconsax.arrow_right_3,
                size: 16,
                color: theme.colorScheme.secondary,
              ),
        onTap: onTap,
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = context.read<ThemeProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Colors.black : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                themeProvider.isDarkMode ? Iconsax.sun_1 : Iconsax.moon,
              ),
              title: Text(
                themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
              ),
              onTap: () {
                themeProvider.toggleTheme();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.notification),
              title: const Text('Notifications'),
              subtitle: FutureBuilder<bool>(
                future: NotificationService().getNotificationsEnabled(),
                builder: (context, snapshot) {
                  final isEnabled = snapshot.data ?? false;
                  return Text(
                    isEnabled ? 'Enabled' : 'Disabled',
                    style: TextStyle(
                      fontSize: 12,
                      color: isEnabled
                          ? Colors.green
                          : (isDark ? Colors.white54 : Colors.black45),
                    ),
                  );
                },
              ),
              trailing: Icon(
                Iconsax.arrow_right_3,
                size: 16,
                color: theme.colorScheme.secondary,
              ),
              onTap: () {
                Navigator.pop(context);
                _showNotificationPreferencesDialog(context);
              },
            ),
            // Admin Panel - only shown to admin users
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (auth.isAdmin) {
                  return ListTile(
                    leading: const Icon(
                      Iconsax.shield_tick,
                      color: Colors.green,
                    ),
                    title: const Text('Admin Panel'),
                    trailing: Icon(
                      Iconsax.arrow_right_3,
                      size: 16,
                      color: theme.colorScheme.secondary,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminScreen(),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHouseholdSelector(
    BuildContext context,
    AuthProvider authProvider,
    UserPreferences? preferences,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final householdSize = preferences?.householdSize ?? 1;

    return Row(
      children: [
        Expanded(
          child: Text(
            '$householdSize ${householdSize == 1 ? 'person' : 'people'}',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        IconButton(
          onPressed: householdSize > 1
              ? () async {
                  if (authProvider.user != null) {
                    final newPrefs =
                        (preferences ??
                                UserPreferences(userId: authProvider.user!.id!))
                            .copyWith(householdSize: householdSize - 1);
                    await authProvider.updatePreferences(newPrefs);
                  }
                }
              : null,
          icon: Icon(
            Iconsax.minus_cirlce,
            color: householdSize > 1
                ? theme.colorScheme.primary
                : (isDark ? Colors.white24 : Colors.black12),
          ),
        ),
        Text(
          '$householdSize',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: householdSize < 10
              ? () async {
                  if (authProvider.user != null) {
                    final newPrefs =
                        (preferences ??
                                UserPreferences(userId: authProvider.user!.id!))
                            .copyWith(householdSize: householdSize + 1);
                    await authProvider.updatePreferences(newPrefs);
                  }
                }
              : null,
          icon: Icon(
            Iconsax.add_circle,
            color: householdSize < 10
                ? theme.colorScheme.primary
                : (isDark ? Colors.white24 : Colors.black12),
          ),
        ),
      ],
    );
  }

  Widget _buildCookingExperienceSelector(
    BuildContext context,
    AuthProvider authProvider,
    UserPreferences? preferences,
  ) {
    final selectedExperience = preferences?.cookingExperience ?? 'Intermediate';
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppStrings.cookingExperienceLevels.map((level) {
        return SelectableChip(
          label: level,
          isSelected: selectedExperience == level,
          onTap: () async {
            if (authProvider.user != null) {
              final newPrefs =
                  (preferences ??
                          UserPreferences(userId: authProvider.user!.id!))
                      .copyWith(cookingExperience: level);
              await authProvider.updatePreferences(newPrefs);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildDietTypeSelector(
    BuildContext context,
    AuthProvider authProvider,
    UserPreferences? preferences,
  ) {
    final selectedDiet = preferences?.dietType ?? 'None';
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppStrings.dietTypes.map((diet) {
        return SelectableChip(
          label: diet,
          isSelected: selectedDiet == diet,
          onTap: () async {
            if (authProvider.user != null) {
              final newPrefs =
                  (preferences ??
                          UserPreferences(userId: authProvider.user!.id!))
                      .copyWith(dietType: diet);
              await authProvider.updatePreferences(newPrefs);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildAllergiesSelector(
    BuildContext context,
    AuthProvider authProvider,
    UserPreferences? preferences,
  ) {
    final selectedAllergies = preferences?.allergies ?? [];
    return ChipGroup(
      items: AppStrings.commonAllergies,
      selectedItems: selectedAllergies,
      onItemToggle: (allergy) async {
        if (authProvider.user != null) {
          final currentAllergies = List<String>.from(selectedAllergies);
          currentAllergies.contains(allergy)
              ? currentAllergies.remove(allergy)
              : currentAllergies.add(allergy);
          final newPrefs =
              (preferences ?? UserPreferences(userId: authProvider.user!.id!))
                  .copyWith(allergies: currentAllergies);
          await authProvider.updatePreferences(newPrefs);
        }
      },
    );
  }

  Widget _buildNutritionGoalsSelector(
    BuildContext context,
    AuthProvider authProvider,
    UserPreferences? preferences,
  ) {
    final selectedGoals = preferences?.nutritionGoals ?? [];
    return ChipGroup(
      items: AppStrings.nutritionGoals,
      selectedItems: selectedGoals,
      onItemToggle: (goal) async {
        if (authProvider.user != null) {
          final currentGoals = List<String>.from(selectedGoals);
          currentGoals.contains(goal)
              ? currentGoals.remove(goal)
              : currentGoals.add(goal);
          final newPrefs =
              (preferences ?? UserPreferences(userId: authProvider.user!.id!))
                  .copyWith(nutritionGoals: currentGoals);
          await authProvider.updatePreferences(newPrefs);
        }
      },
    );
  }

  Widget _buildCuisineSelector(
    BuildContext context,
    AuthProvider authProvider,
    UserPreferences? preferences,
  ) {
    final selectedCuisines = preferences?.cuisinePreferences ?? [];
    return ChipGroup(
      items: AppStrings.cuisineTypes,
      selectedItems: selectedCuisines,
      onItemToggle: (cuisine) async {
        if (authProvider.user != null) {
          final currentCuisines = List<String>.from(selectedCuisines);
          currentCuisines.contains(cuisine)
              ? currentCuisines.remove(cuisine)
              : currentCuisines.add(cuisine);
          final newPrefs =
              (preferences ?? UserPreferences(userId: authProvider.user!.id!))
                  .copyWith(cuisinePreferences: currentCuisines);
          await authProvider.updatePreferences(newPrefs);
        }
      },
    );
  }

  Widget _buildDislikesSelector(
    BuildContext context,
    AuthProvider authProvider,
    UserPreferences? preferences,
  ) {
    final selectedDislikes = preferences?.dislikedIngredients ?? [];
    return ChipGroup(
      items: AppStrings.commonDislikes,
      selectedItems: selectedDislikes,
      onItemToggle: (item) async {
        if (authProvider.user != null) {
          final currentDislikes = List<String>.from(selectedDislikes);
          currentDislikes.contains(item)
              ? currentDislikes.remove(item)
              : currentDislikes.add(item);
          final newPrefs =
              (preferences ?? UserPreferences(userId: authProvider.user!.id!))
                  .copyWith(dislikedIngredients: currentDislikes);
          await authProvider.updatePreferences(newPrefs);
        }
      },
    );
  }

  Widget _buildStoreSelector(
    BuildContext context,
    AuthProvider authProvider,
    UserPreferences? preferences,
  ) {
    final selectedStore = preferences?.preferredStore ?? 'Any';
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppStrings.preferredStores.map((store) {
        return SelectableChip(
          label: store,
          isSelected: selectedStore == store,
          onTap: () async {
            if (authProvider.user != null) {
              final newPrefs =
                  (preferences ??
                          UserPreferences(userId: authProvider.user!.id!))
                      .copyWith(preferredStore: store);
              await authProvider.updatePreferences(newPrefs);
            }
          },
        );
      }).toList(),
    );
  }

  void _showEditNameDialog(BuildContext context, AuthProvider authProvider) {
    final controller = TextEditingController(text: authProvider.user?.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Enter your name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await authProvider.updateName(controller.text.trim());
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name updated successfully'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (currentPasswordController.text.isNotEmpty &&
                  newPasswordController.text.length >= 6) {
                final success = await authProvider.changePassword(
                  currentPasswordController.text,
                  newPasswordController.text,
                );
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Password changed successfully'
                            : 'Failed to change password. Check your current password.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await authProvider.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showApiKeysDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final aiProvider = context.read<AIProvider>();
    final authProvider = context.read<AuthProvider>();
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isSubscribed = authProvider.isSubscribed;
          final hasOwnKey = aiProvider.hasOwnApiKey;
          final isUsingSharedKey = aiProvider.isUsingSharedKey;
          final hasAccess = aiProvider.hasApiKey;

          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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

                    // Header with Chef AI branding
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Iconsax.magic_star5,
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chef AI',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  'Intelligent meal discovery',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasAccess)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: Colors.green[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Subscription-based Chef AI toggle (for subscribers)
                    if (isSubscribed) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      const Color(0xFF2D1B4E),
                                      const Color(0xFF1A1A2E),
                                    ]
                                  : [
                                      const Color(0xFFF5F0FF),
                                      const Color(0xFFEDE7F6),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.purple.withOpacity(0.3)
                                  : Colors.purple.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Iconsax.crown1,
                                    size: 20,
                                    color: Colors.amber[600],
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Premium Chef AI',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                        ),
                                        Text(
                                          'Use our API for unlimited AI features',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: isDark
                                                    ? Colors.white60
                                                    : Colors.black54,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: isUsingSharedKey,
                                    onChanged: (value) async {
                                      await aiProvider.toggleUseSharedKey(
                                        value,
                                      );
                                      setModalState(() {});
                                    },
                                    activeColor: Colors.purple,
                                  ),
                                ],
                              ),
                              if (isUsingSharedKey) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.white.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Iconsax.tick_circle,
                                        size: 18,
                                        color: Colors.green[600],
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'You\'re using Premium Chef AI',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: isDark
                                                    ? Colors.white70
                                                    : Colors.black87,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: isDark ? Colors.white12 : Colors.black12,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'or use your own key',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: isDark ? Colors.white12 : Colors.black12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      // Non-subscriber message
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.amber.withOpacity(0.1)
                                : Colors.amber.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.amber.withOpacity(0.3)
                                  : Colors.amber.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.crown1,
                                size: 20,
                                color: Colors.amber[700],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Want hassle-free AI?',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Subscribe to use Chef AI without needing your own API key',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.black54,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const SubscriptionScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[700],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Subscribe',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Your Own API Key Section (BYOK)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Iconsax.key,
                                  size: 18,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isSubscribed
                                          ? 'Your API Keys'
                                          : 'Your API Key',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                    ),
                                    Text(
                                      isSubscribed
                                          ? 'Add multiple keys & switch providers'
                                          : 'Bring your own key (BYOK)',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black54,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSubscribed && aiProvider.apiKeyCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${aiProvider.apiKeyCount} key${aiProvider.apiKeyCount > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                )
                              else if (hasOwnKey)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    aiProvider.currentProviderName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // For subscribers: Show multi-key management
                          if (isSubscribed) ...[
                            // Show existing keys with switch capability
                            if (aiProvider.allApiKeys.isNotEmpty) ...[
                              ...aiProvider.allApiKeys.map((key) {
                                final isActive =
                                    aiProvider.currentProviderType ==
                                    key.provider;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: GestureDetector(
                                    onTap: () async {
                                      await aiProvider.switchProvider(
                                        key.provider,
                                      );
                                      setModalState(() {});
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? (isDark
                                                  ? Colors.blue.withOpacity(
                                                      0.15,
                                                    )
                                                  : Colors.blue.withOpacity(
                                                      0.1,
                                                    ))
                                            : (isDark
                                                  ? Colors.white.withOpacity(
                                                      0.05,
                                                    )
                                                  : Colors.grey[100]),
                                        borderRadius: BorderRadius.circular(12),
                                        border: isActive
                                            ? Border.all(
                                                color: Colors.blue.withOpacity(
                                                  0.5,
                                                ),
                                                width: 1.5,
                                              )
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? Colors.blue
                                                  : (isDark
                                                        ? Colors.white
                                                              .withOpacity(0.1)
                                                        : Colors.grey[200]),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              isActive
                                                  ? Iconsax.tick_circle5
                                                  : Iconsax.cpu,
                                              size: 16,
                                              color: isActive
                                                  ? Colors.white
                                                  : (isDark
                                                        ? Colors.white70
                                                        : Colors.black54),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  key.provider.displayName,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark
                                                        ? Colors.white
                                                        : Colors.black87,
                                                  ),
                                                ),
                                                Text(
                                                  key.maskedKey,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontFamily: 'monospace',
                                                    color: isDark
                                                        ? Colors.white54
                                                        : Colors.black45,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isActive)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(
                                                  0.2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Active',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.blue[600],
                                                ),
                                              ),
                                            ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () async {
                                              await aiProvider.removeApiKey(
                                                provider: key.provider,
                                              );
                                              setModalState(() {});
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      '${key.provider.displayName} key removed',
                                                    ),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                  ),
                                                );
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Icon(
                                                Iconsax.trash,
                                                size: 16,
                                                color: Colors.red[400],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                            ],

                            // Add new key section
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.03)
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.05),
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Add New Key',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: controller,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Paste your API key...',
                                      hintStyle: TextStyle(
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black38,
                                        fontSize: 14,
                                      ),
                                      filled: true,
                                      fillColor: isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                      prefixIcon: Icon(
                                        Iconsax.key,
                                        size: 18,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black45,
                                      ),
                                    ),
                                    obscureText: true,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Auto-detects: OpenAI, Gemini, OpenRouter, DeepSeek',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black38,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (controller.text.trim().isNotEmpty) {
                                          final key = controller.text.trim();
                                          final detectedProvider =
                                              AIProviderExtension.detectFromKey(
                                                key,
                                              );
                                          await aiProvider.setApiKey(
                                            key,
                                            provider: detectedProvider,
                                          );
                                          setModalState(() {});
                                          controller.clear();
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '${detectedProvider?.displayName ?? 'Unknown'} key added',
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDark
                                            ? Colors.white
                                            : Colors.black,
                                        foregroundColor: isDark
                                            ? Colors.black
                                            : Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Add Key',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Non-subscriber: Single key mode
                            if (hasOwnKey) ...[
                              // Show masked key and remove button
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '••••••••••••••••',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'monospace',
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Provider: ${aiProvider.currentProviderName}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white54
                                                  : Colors.black45,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        await aiProvider.removeApiKey();
                                        setModalState(() {});
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('API key removed'),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Iconsax.trash,
                                          size: 18,
                                          color: Colors.red[400],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              // Show input field for new key
                              TextField(
                                controller: controller,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Paste your API key...',
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Iconsax.key,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45,
                                  ),
                                ),
                                obscureText: true,
                              ),
                              const SizedBox(height: 8),
                              // Supported providers hint
                              Text(
                                'Supports: OpenAI, Gemini, OpenRouter, DeepSeek',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (controller.text.trim().isNotEmpty) {
                                      final key = controller.text.trim();
                                      final detectedProvider =
                                          AIProviderExtension.detectFromKey(
                                            key,
                                          );
                                      await aiProvider.setApiKey(
                                        key,
                                        provider: detectedProvider,
                                      );
                                      setModalState(() {});
                                      controller.clear();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'API key saved (${detectedProvider?.displayName ?? 'Unknown'})',
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark
                                        ? Colors.white
                                        : Colors.black,
                                    foregroundColor: isDark
                                        ? Colors.black
                                        : Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Save Key',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Bottom safe area
                    SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 16,
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

  void _showNotificationPreferencesDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
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
                            Iconsax.notification,
                            size: 22,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notifications',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              Text(
                                'Choose what alerts you want to receive',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Master toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FutureBuilder<bool>(
                      future: NotificationService().getNotificationsEnabled(),
                      builder: (context, snapshot) {
                        final isEnabled = snapshot.data ?? false;
                        return _buildNotificationToggle(
                          context,
                          isDark,
                          icon: Iconsax.notification_bing,
                          title: 'Push Notifications',
                          subtitle: 'Enable all notifications',
                          value: isEnabled,
                          isMaster: true,
                          onChanged: (value) async {
                            if (value) {
                              final hasPermission = await NotificationService()
                                  .requestPermission();
                              if (hasPermission) {
                                await NotificationService()
                                    .setNotificationsEnabled(true);
                                setModalState(() {});
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Please enable notifications in device Settings',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }
                              }
                            } else {
                              await NotificationService()
                                  .setNotificationsEnabled(false);
                              setModalState(() {});
                            }
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Divider(
                      color: isDark
                          ? Colors.white12
                          : Colors.black.withOpacity(0.06),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Category label
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'NOTIFICATION TYPES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Meal Reminders
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FutureBuilder<List<bool>>(
                      future: Future.wait([
                        NotificationService().getNotificationsEnabled(),
                        NotificationService().getMealRemindersEnabled(),
                      ]),
                      builder: (context, snapshot) {
                        final masterEnabled = snapshot.data?[0] ?? false;
                        final isEnabled = snapshot.data?[1] ?? true;
                        return _buildNotificationToggle(
                          context,
                          isDark,
                          icon: Iconsax.clock,
                          title: 'Meal Reminders',
                          subtitle:
                              'Get notified when it\'s time to prepare meals',
                          value: isEnabled && masterEnabled,
                          enabled: masterEnabled,
                          onChanged: (value) async {
                            await NotificationService().setMealRemindersEnabled(
                              value,
                            );
                            setModalState(() {});
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Expiry Alerts
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FutureBuilder<List<bool>>(
                      future: Future.wait([
                        NotificationService().getNotificationsEnabled(),
                        NotificationService().getExpiryAlertsEnabled(),
                      ]),
                      builder: (context, snapshot) {
                        final masterEnabled = snapshot.data?[0] ?? false;
                        final isEnabled = snapshot.data?[1] ?? true;
                        return _buildNotificationToggle(
                          context,
                          isDark,
                          icon: Iconsax.calendar_remove,
                          title: 'Expiry Alerts',
                          subtitle:
                              'Get alerts when pantry items are about to expire',
                          value: isEnabled && masterEnabled,
                          enabled: masterEnabled,
                          onChanged: (value) async {
                            await NotificationService().setExpiryAlertsEnabled(
                              value,
                            );
                            setModalState(() {});
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Low Stock Alerts
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FutureBuilder<List<bool>>(
                      future: Future.wait([
                        NotificationService().getNotificationsEnabled(),
                        NotificationService().getLowStockAlertsEnabled(),
                      ]),
                      builder: (context, snapshot) {
                        final masterEnabled = snapshot.data?[0] ?? false;
                        final isEnabled = snapshot.data?[1] ?? true;
                        return _buildNotificationToggle(
                          context,
                          isDark,
                          icon: Iconsax.box_remove,
                          title: 'Low Stock Alerts',
                          subtitle:
                              'Get notified when pantry items are running low',
                          value: isEnabled && masterEnabled,
                          enabled: masterEnabled,
                          onChanged: (value) async {
                            await NotificationService()
                                .setLowStockAlertsEnabled(value);
                            setModalState(() {});
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Info text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.info_circle,
                            size: 18,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You can also manage notifications in your device settings.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom safe area
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationToggle(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    bool enabled = true,
    bool isMaster = false,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: enabled ? () => onChanged(!value) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isMaster
              ? (value
                    ? (isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05))
                    : (isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.02)))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isMaster
              ? Border.all(
                  color: value
                      ? (isDark ? Colors.white24 : Colors.black12)
                      : (isDark
                            ? Colors.white10
                            : Colors.black.withOpacity(0.04)),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: enabled
                    ? (isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05))
                    : (isDark
                          ? Colors.white.withOpacity(0.03)
                          : Colors.black.withOpacity(0.02)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: enabled
                    ? (isDark ? Colors.white70 : Colors.black54)
                    : (isDark ? Colors.white24 : Colors.black12),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: enabled
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark ? Colors.white38 : Colors.black26),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: enabled
                          ? (isDark ? Colors.white54 : Colors.black54)
                          : (isDark ? Colors.white24 : Colors.black12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Custom toggle
            Container(
              width: 50,
              height: 30,
              decoration: BoxDecoration(
                color: value && enabled
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05)),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    left: value && enabled ? 22 : 2,
                    top: 2,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: value && enabled
                            ? (isDark ? Colors.black : Colors.white)
                            : (isDark ? Colors.white24 : Colors.black12),
                        shape: BoxShape.circle,
                        boxShadow: value && enabled
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
