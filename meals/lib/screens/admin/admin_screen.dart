import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pantry_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../services/notification_service.dart';
import '../../services/stripe_service.dart';
import '../../data/repositories/config_repository.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  // Use the shared admin user ID from AuthProvider
  static bool isAdmin(int? userId) => userId == AuthProvider.adminUserId;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _notificationService = NotificationService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();

    // Security check
    if (!authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(child: Text('You do not have admin privileges.')),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        appBar: AppBar(
          backgroundColor: isDark ? Colors.black : Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Iconsax.arrow_left,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Admin Panel',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Admin Info Card
                    _buildInfoCard(
                      context,
                      theme,
                      isDark,
                      'Admin Account',
                      authProvider.user?.name ?? 'Unknown',
                      authProvider.user?.email ?? '',
                      Iconsax.user_octagon,
                    ),
                    const SizedBox(height: 24),

                    // Section: User Management
                    _buildSectionHeader(theme, 'User Management'),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      context,
                      theme,
                      isDark,
                      icon: Iconsax.profile_2user,
                      title: 'View All Users',
                      subtitle: 'Manage registered users',
                      onTap: () => _showUsersDialog(context),
                    ),
                    const SizedBox(height: 8),
                    _buildActionCard(
                      context,
                      theme,
                      isDark,
                      icon: Iconsax.user_add,
                      title: 'Create Test User',
                      subtitle: 'Add a test account for debugging',
                      onTap: () => _createTestUser(context),
                    ),
                    const SizedBox(height: 24),

                    // Section: Data Management
                    _buildSectionHeader(theme, 'Data Management'),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      context,
                      theme,
                      isDark,
                      icon: Iconsax.box,
                      title: 'Clear Pantry Data',
                      subtitle: 'Remove all pantry items',
                      onTap: () => _confirmClearData(
                        context,
                        'Pantry',
                        () => _clearPantryData(context),
                      ),
                      isDestructive: true,
                    ),
                    const SizedBox(height: 8),
                    _buildActionCard(
                      context,
                      theme,
                      isDark,
                      icon: Iconsax.dollar_circle,
                      title: 'Clear Budget Data',
                      subtitle: 'Remove all budget entries',
                      onTap: () => _confirmClearData(
                        context,
                        'Budget',
                        () => _clearBudgetData(context),
                      ),
                      isDestructive: true,
                    ),
                    const SizedBox(height: 8),
                    _buildActionCard(
                      context,
                      theme,
                      isDark,
                      icon: Iconsax.shopping_cart,
                      title: 'Clear Shopping Lists',
                      subtitle: 'Remove all shopping list items',
                      onTap: () => _confirmClearData(
                        context,
                        'Shopping Lists',
                        () => _clearShoppingData(context),
                      ),
                      isDestructive: true,
                    ),
                    const SizedBox(height: 8),
                    _buildActionCard(
                      context,
                      theme,
                      isDark,
                      icon: Iconsax.bookmark,
                      title: 'Clear Bookmarks',
                      subtitle: 'Remove all saved recipes',
                      onTap: () => _confirmClearData(
                        context,
                        'Bookmarks',
                        () => _clearBookmarkData(context),
                      ),
                      isDestructive: true,
                    ),
                    const SizedBox(height: 24),

                    // Section: Notifications
                    _buildSectionHeader(theme, 'Notifications'),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      context,
                      theme,
                      isDark,
                      icon: Iconsax.notification,
                      title: 'Send Test Notification',
                      subtitle: 'Test push notification system',
                      onTap: () => _sendTestNotification(context),
                    ),
                    const SizedBox(height: 8),
                    _buildActionCard(
                      context,
                      theme,
                      isDark,
                      icon: Iconsax.notification_bing,
                      title: 'Clear All Notifications',
                      subtitle: 'Cancel pending notifications',
                      onTap: () => _clearNotifications(context),
                    ),
                    const SizedBox(height: 24),

                    // Section: Payment Settings
                    _buildSectionHeader(theme, 'Payment Settings'),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      context,
                      theme,
                      isDark,
                      icon: Iconsax.card,
                      title: 'Stripe Configuration',
                      subtitle: 'Manage Stripe API keys',
                      onTap: () => _showStripeConfigDialog(context),
                    ),
                    const SizedBox(height: 8),
                    _buildActionCard(
                      context,
                      theme,
                      isDark,
                      icon: Iconsax.dollar_square,
                      title: 'Subscription Plans',
                      subtitle: 'Configure price IDs',
                      onTap: () => _showPricingConfigDialog(context),
                    ),
                    const SizedBox(height: 8),
                    _buildActionCard(
                      context,
                      theme,
                      isDark,
                      icon: Iconsax.tick_circle,
                      title: 'Test Stripe Config',
                      subtitle: 'Verify configuration is saved',
                      onTap: () => _testStripeConfig(context),
                    ),
                    const SizedBox(height: 24),

                    // Section: AI Settings
                    _buildSectionHeader(theme, 'AI Settings'),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      context,
                      theme,
                      isDark,
                      icon: Iconsax.cpu,
                      title: 'Chef AI Configuration',
                      subtitle: 'Set shared AI API key for subscribers',
                      onTap: () => _showChefAiConfigDialog(context),
                    ),
                    const SizedBox(height: 24),

                    // Section: Debug Info
                    _buildSectionHeader(theme, 'Debug Info'),
                    const SizedBox(height: 12),
                    _buildDebugInfoCard(context, theme, isDark),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    String label,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
        ),
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
            child: Icon(icon, color: isDark ? Colors.white : Colors.black),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Admin',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    ThemeData theme,
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? Colors.red
        : (isDark ? Colors.white : Colors.black);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.03)
              : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDestructive
                ? Colors.red.withOpacity(0.3)
                : (isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDestructive
                          ? Colors.red.withOpacity(0.7)
                          : theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Iconsax.arrow_right_3,
              size: 16,
              color: isDestructive
                  ? Colors.red.withOpacity(0.5)
                  : theme.colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugInfoCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final authProvider = context.read<AuthProvider>();
    final pantryProvider = context.read<PantryProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final shoppingProvider = context.read<ShoppingProvider>();
    final bookmarkProvider = context.read<BookmarkProvider>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDebugRow(theme, 'User ID', '${authProvider.user?.id ?? "N/A"}'),
          _buildDebugRow(
            theme,
            'Pantry Items',
            '${pantryProvider.allItems.length}',
          ),
          _buildDebugRow(
            theme,
            'Budget Entries',
            '${budgetProvider.entries.length}',
          ),
          _buildDebugRow(
            theme,
            'Shopping Items',
            '${shoppingProvider.items.length}',
          ),
          _buildDebugRow(
            theme,
            'Bookmarks',
            '${bookmarkProvider.bookmarks.length}',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDebugRow(
    ThemeData theme,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showUsersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('User Management'),
        content: const Text(
          'Full user management will be available in a future update. '
          'Currently, users are stored locally on each device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _createTestUser(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Create Test User'),
        content: const Text(
          'Test user creation will be available when backend integration is complete.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _confirmClearData(
    BuildContext context,
    String dataType,
    VoidCallback onConfirm,
  ) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear $dataType Data?'),
        content: Text(
          'This will permanently delete all $dataType data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.secondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearPantryData(BuildContext context) async {
    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    final pantryProvider = context.read<PantryProvider>();

    if (authProvider.user?.id != null) {
      // Clear all items
      for (final item in List.from(pantryProvider.allItems)) {
        await pantryProvider.deleteItem(item.id!);
      }
    }

    setState(() => _isLoading = false);
    if (context.mounted) {
      _showSuccessSnackBar(context, 'Pantry data cleared');
    }
  }

  Future<void> _clearBudgetData(BuildContext context) async {
    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    final budgetProvider = context.read<BudgetProvider>();

    if (authProvider.user?.id != null) {
      for (final entry in List.from(budgetProvider.entries)) {
        await budgetProvider.deleteEntry(entry.id!);
      }
    }

    setState(() => _isLoading = false);
    if (context.mounted) {
      _showSuccessSnackBar(context, 'Budget data cleared');
    }
  }

  Future<void> _clearShoppingData(BuildContext context) async {
    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    final shoppingProvider = context.read<ShoppingProvider>();

    if (authProvider.user?.id != null) {
      final userId = authProvider.user!.id!;
      for (final item in List.from(shoppingProvider.items)) {
        await shoppingProvider.deleteItem(item.id!, userId);
      }
    }

    setState(() => _isLoading = false);
    if (context.mounted) {
      _showSuccessSnackBar(context, 'Shopping lists cleared');
    }
  }

  Future<void> _clearBookmarkData(BuildContext context) async {
    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    final bookmarkProvider = context.read<BookmarkProvider>();

    if (authProvider.user?.id != null) {
      final userId = authProvider.user!.id!;
      for (final bookmark in List.from(bookmarkProvider.bookmarks)) {
        await bookmarkProvider.removeBookmark(userId, bookmark.mealId);
      }
    }

    setState(() => _isLoading = false);
    if (context.mounted) {
      _showSuccessSnackBar(context, 'Bookmarks cleared');
    }
  }

  Future<void> _sendTestNotification(BuildContext context) async {
    await _notificationService.initialize();

    final hasPermission = await _notificationService.hasPermission();
    if (!hasPermission) {
      final granted = await _notificationService.requestPermission();
      if (!granted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Notification permission denied'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }
    }

    await _notificationService.setNotificationsEnabled(true);
    await _notificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Test Notification',
      body: 'This is a test notification from the Admin Panel!',
      payload: 'admin_test',
    );

    if (context.mounted) {
      _showSuccessSnackBar(context, 'Test notification sent');
    }
  }

  Future<void> _clearNotifications(BuildContext context) async {
    await _notificationService.cancelAllNotifications();
    if (context.mounted) {
      _showSuccessSnackBar(context, 'All notifications cleared');
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ============ STRIPE CONFIGURATION ============

  void _showStripeConfigDialog(BuildContext context) async {
    final configRepo = ConfigRepository();
    final currentPublishableKey = await configRepo.getStripePublishableKey();
    final currentSecretKey = await configRepo.getStripeSecretKey();

    final publishableController = TextEditingController(
      text: currentPublishableKey ?? '',
    );
    final secretController = TextEditingController(
      text: currentSecretKey ?? '',
    );

    if (!context.mounted) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Iconsax.card, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Stripe Configuration'),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configure your Stripe API keys. These are required for payment processing.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 20),
                _buildConfigTextField(
                  context,
                  controller: publishableController,
                  label: 'Publishable Key',
                  hint: 'pk_live_...',
                  icon: Iconsax.key,
                ),
                const SizedBox(height: 16),
                _buildConfigTextField(
                  context,
                  controller: secretController,
                  label: 'Secret Key',
                  hint: 'sk_live_...',
                  icon: Iconsax.lock,
                  isSecret: true,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.warning_2,
                        color: Colors.orange,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Never share your secret key. In production, use environment variables.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final publishable = publishableController.text.trim();
              final secret = secretController.text.trim();

              bool success = true;
              if (publishable.isNotEmpty) {
                final result = await configRepo.setStripePublishableKey(
                  publishable,
                );
                debugPrint('Admin: Save publishable key result: $result');
                success = success && result;
              }
              if (secret.isNotEmpty) {
                final result = await configRepo.setStripeSecretKey(secret);
                debugPrint('Admin: Save secret key result: $result');
                success = success && result;
              }

              // Re-initialize Stripe with new key
              if (publishable.isNotEmpty) {
                final initResult = await StripeService().initialize();
                debugPrint('Admin: Stripe initialize result: $initResult');
              }

              if (context.mounted) {
                Navigator.pop(context);
                _showSuccessSnackBar(
                  context,
                  success
                      ? 'Stripe configuration saved'
                      : 'Error saving configuration',
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPricingConfigDialog(BuildContext context) async {
    final configRepo = ConfigRepository();
    final currentMonthlyId = await configRepo.getStripeMonthlyPriceId();
    final currentYearlyId = await configRepo.getStripeYearlyPriceId();

    final monthlyController = TextEditingController(
      text: currentMonthlyId ?? '',
    );
    final yearlyController = TextEditingController(text: currentYearlyId ?? '');

    if (!context.mounted) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Iconsax.dollar_square, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Subscription Plans'),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the Stripe Price IDs for your subscription plans. Create these in your Stripe Dashboard.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 20),
                _buildConfigTextField(
                  context,
                  controller: monthlyController,
                  label: 'Monthly Plan Price ID',
                  hint: 'price_...',
                  icon: Iconsax.calendar_1,
                ),
                const SizedBox(height: 16),
                _buildConfigTextField(
                  context,
                  controller: yearlyController,
                  label: 'Yearly Plan Price ID',
                  hint: 'price_...',
                  icon: Iconsax.calendar,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final monthly = monthlyController.text.trim();
              final yearly = yearlyController.text.trim();

              if (monthly.isNotEmpty) {
                await configRepo.setStripeMonthlyPriceId(monthly);
              }
              if (yearly.isNotEmpty) {
                await configRepo.setStripeYearlyPriceId(yearly);
              }

              if (context.mounted) {
                Navigator.pop(context);
                _showSuccessSnackBar(context, 'Price IDs saved');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChefAiConfigDialog(BuildContext context) async {
    final configRepo = ConfigRepository();
    final currentApiKey = await configRepo.getChefAiApiKey();
    final currentProvider = await configRepo.getChefAiProvider();

    final apiKeyController = TextEditingController(text: currentApiKey ?? '');
    String selectedProvider = currentProvider ?? 'openai';

    if (!context.mounted) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Iconsax.cpu, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              const Text('Chef AI Configuration'),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configure the shared AI API key for the Chef AI feature. Subscribers without their own BYOK keys will use this.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'AI Provider',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedProvider,
                        isExpanded: true,
                        dropdownColor: isDark
                            ? const Color(0xFF2A2A2A)
                            : Colors.white,
                        items: const [
                          DropdownMenuItem(
                            value: 'openai',
                            child: Text('OpenAI'),
                          ),
                          DropdownMenuItem(
                            value: 'gemini',
                            child: Text('Google Gemini'),
                          ),
                          DropdownMenuItem(
                            value: 'openrouter',
                            child: Text('OpenRouter'),
                          ),
                          DropdownMenuItem(
                            value: 'deepseek',
                            child: Text('DeepSeek'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedProvider = value);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildConfigTextField(
                    context,
                    controller: apiKeyController,
                    label: 'API Key',
                    hint: 'Enter your API key...',
                    icon: Iconsax.key,
                    isSecret: true,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final apiKey = apiKeyController.text.trim();

                if (apiKey.isNotEmpty) {
                  await configRepo.setChefAiApiKey(apiKey);
                }
                await configRepo.setChefAiProvider(selectedProvider);

                if (context.mounted) {
                  Navigator.pop(context);
                  _showSuccessSnackBar(context, 'Chef AI configuration saved');
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isSecret = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isSecret,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _testStripeConfig(BuildContext context) async {
    final configRepo = ConfigRepository();
    final stripeService = StripeService();

    final publishableKey = await configRepo.getStripePublishableKey();
    final secretKey = await configRepo.getStripeSecretKey();
    final monthlyPriceId = await configRepo.getStripeMonthlyPriceId();
    final yearlyPriceId = await configRepo.getStripeYearlyPriceId();
    final isConfigured = await stripeService.isConfigured();

    if (!context.mounted) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isConfigured ? Iconsax.tick_circle : Iconsax.warning_2,
              color: isConfigured ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 12),
            Text(isConfigured ? 'Config OK' : 'Config Issue'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConfigStatusRow(
                'Publishable Key',
                publishableKey != null && publishableKey.isNotEmpty,
                publishableKey != null
                    ? '${publishableKey.substring(0, 7)}...${publishableKey.substring(publishableKey.length - 4)}'
                    : 'Not set',
              ),
              const SizedBox(height: 8),
              _buildConfigStatusRow(
                'Secret Key',
                secretKey != null && secretKey.isNotEmpty,
                secretKey != null
                    ? '${secretKey.substring(0, 7)}...${secretKey.substring(secretKey.length - 4)}'
                    : 'Not set',
              ),
              const SizedBox(height: 8),
              _buildConfigStatusRow(
                'Monthly Price ID',
                monthlyPriceId != null && monthlyPriceId.isNotEmpty,
                monthlyPriceId ?? 'Not set',
              ),
              const SizedBox(height: 8),
              _buildConfigStatusRow(
                'Yearly Price ID',
                yearlyPriceId != null && yearlyPriceId.isNotEmpty,
                yearlyPriceId ?? 'Not set',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isConfigured ? Colors.green : Colors.orange)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isConfigured ? Iconsax.tick_circle : Iconsax.info_circle,
                      color: isConfigured ? Colors.green : Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isConfigured
                            ? 'Stripe is ready for payments'
                            : 'Please set all required keys',
                        style: TextStyle(
                          color: isConfigured ? Colors.green : Colors.orange,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigStatusRow(String label, bool isSet, String value) {
    return Row(
      children: [
        Icon(
          isSet ? Iconsax.tick_circle : Iconsax.close_circle,
          color: isSet ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
