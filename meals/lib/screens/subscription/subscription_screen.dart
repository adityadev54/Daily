import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../common/webview_screen.dart';
import '../../services/stripe_service.dart';
import '../../providers/auth_provider.dart';
import '../../data/repositories/auth_repository.dart';
import 'payment_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int _selectedPlanIndex = 1;

  void _openInAppBrowser(BuildContext context, String url, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewScreen(url: url, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: () => _handleRestore(context),
              child: Text(
                'Restore',
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Header
                      Text(
                        'Premium',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unlock the full experience',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Features
                      _buildFeatureRow(
                        context,
                        icon: Iconsax.magic_star,
                        title: 'Unlimited AI Recipes',
                        subtitle: 'Generate personalized recipes anytime',
                      ),
                      _buildFeatureRow(
                        context,
                        icon: Iconsax.chart_2,
                        title: 'Advanced Nutrition',
                        subtitle: 'Detailed macros and health insights',
                      ),
                      _buildFeatureRow(
                        context,
                        icon: Iconsax.calendar_tick,
                        title: 'Smart Meal Plans',
                        subtitle: 'AI-powered weekly planning',
                      ),
                      _buildFeatureRow(
                        context,
                        icon: Iconsax.box,
                        title: 'Pantry Integration',
                        subtitle: 'Recipes from what you have',
                      ),
                      _buildFeatureRow(
                        context,
                        icon: Iconsax.share,
                        title: 'Recipe Sharing',
                        subtitle: 'Share with family and friends',
                        isLast: true,
                      ),
                      const SizedBox(height: 32),

                      // Plans
                      _buildPlanCard(
                        context,
                        index: 0,
                        title: 'Monthly',
                        price: '\$4.99',
                        period: 'per month',
                      ),
                      const SizedBox(height: 12),
                      _buildPlanCard(
                        context,
                        index: 1,
                        title: 'Yearly',
                        price: '\$29.99',
                        period: 'per year',
                        badge: 'Save 50%',
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom section
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () => _handleSubscribe(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : Colors.black,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Start 7-Day Free Trial',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedPlanIndex == 0
                          ? 'Then \$4.99/month • Cancel anytime'
                          : 'Then \$29.99/year • Cancel anytime',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _openInAppBrowser(
                            context,
                            'https://getmovingmeals.cloud/legal/privacy',
                            'Privacy Policy',
                          ),
                          child: Text(
                            'Privacy',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '•',
                            style: TextStyle(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _openInAppBrowser(
                            context,
                            'https://getmovingmeals.cloud/legal/terms',
                            'Terms of Service',
                          ),
                          child: Text(
                            'Terms',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
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
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
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
      child: Row(
        children: [
          Icon(icon, size: 22, color: isDark ? Colors.white : Colors.black),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
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
          Icon(
            Iconsax.tick_circle5,
            size: 20,
            color: isDark ? Colors.white : Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required int index,
    required String title,
    required String price,
    required String period,
    String? badge,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _selectedPlanIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.03))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : (isDark
                      ? Colors.white24
                      : Colors.black.withValues(alpha: 0.12)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? Colors.white38 : Colors.black38),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Row(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white : Colors.black,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: isDark ? Colors.black : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  period,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubscribe(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      _showError(context, 'Please sign in to subscribe');
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final stripeService = StripeService();

    // Check if Stripe is configured
    debugPrint('Subscription: Checking if Stripe is configured...');
    final isConfigured = await stripeService.isConfigured();
    debugPrint('Subscription: isConfigured = $isConfigured');

    if (!context.mounted) return;
    Navigator.pop(context); // Remove loading

    if (!isConfigured) {
      _showError(
        context,
        'Payment system is not configured. Please contact support.',
      );
      return;
    }

    // Determine plan
    final plan = _selectedPlanIndex == 0
        ? SubscriptionPlan.monthly
        : SubscriptionPlan.yearly;

    // Show loading again for subscription setup
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Setting up payment...'),
              ],
            ),
          ),
        ),
      ),
    );

    // Prepare subscription (creates subscription and returns client secret)
    final result = await stripeService.prepareSubscription(
      email: user.email,
      name: user.name,
      userId: user.id.toString(),
      plan: plan,
    );

    if (!context.mounted) return;
    Navigator.pop(context); // Remove loading

    if (!result.success) {
      _showError(context, result.error ?? 'Could not initialize payment.');
      return;
    }

    final clientSecret = result.clientSecret;
    if (clientSecret == null) {
      _showError(context, 'Could not initialize payment. Please try again.');
      return;
    }

    // Navigate to custom payment screen
    final planName = plan == SubscriptionPlan.monthly ? 'Monthly' : 'Yearly';
    final planPrice = plan == SubscriptionPlan.monthly ? '\$4.99' : '\$39.99';
    final planPeriod = plan == SubscriptionPlan.monthly
        ? 'per month'
        : 'per year';

    if (!context.mounted) return;

    final paymentSuccess = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          clientSecret: clientSecret,
          planName: planName,
          planPrice: planPrice,
          planPeriod: planPeriod,
          onSuccess: () {
            Navigator.pop(context, true);
          },
          onCancel: () {
            Navigator.pop(context, false);
          },
        ),
      ),
    );

    if (paymentSuccess == true && context.mounted) {
      // Update user subscription status in database
      final authRepo = AuthRepository();
      final expiryDate = plan == SubscriptionPlan.monthly
          ? DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(const Duration(days: 365));

      await authRepo.updateSubscription(
        user.id!,
        isSubscribed: true,
        expiryDate: expiryDate,
      );

      // Reload user
      await authProvider.refreshUser();

      if (context.mounted) {
        _showSuccessDialog(context, plan);
      }
    }
  }

  void _showSuccessDialog(BuildContext context, SubscriptionPlan plan) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final planName = plan == SubscriptionPlan.monthly ? 'Monthly' : 'Yearly';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.tick_circle,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome to Premium!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your $planName subscription is now active.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enjoy unlimited AI recipes and all premium features!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close subscription screen
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Start Exploring'),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.warning_2, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _handleRestore(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('No purchases to restore'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
