import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('What\'s New'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.white10, Colors.white.withOpacity(0.05)]
                    : [
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.02),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  Iconsax.magic_star5,
                  size: 48,
                  color: isDark ? Colors.white : Colors.black,
                ),
                const SizedBox(height: 16),
                Text(
                  'Meals App',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 2.2.0',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Latest Release
          _buildVersionSection(
            context,
            version: '2.2.0',
            date: 'December 2025',
            isLatest: true,
            changes: [
              _ChangeItem(
                icon: Iconsax.key,
                title: 'Multi-Provider BYOK',
                description:
                    'Bring your own API key from OpenAI (ChatGPT), Google Gemini, OpenRouter, or DeepSeek. Auto-detects provider from key.',
                type: _ChangeType.feature,
              ),
              _ChangeItem(
                icon: Iconsax.crown1,
                title: 'Subscriber Multi-Key Support',
                description:
                    'Premium subscribers can add multiple API keys and switch between providers on the fly.',
                type: _ChangeType.feature,
              ),
              _ChangeItem(
                icon: Iconsax.shield_tick,
                title: 'Admin Full Access',
                description:
                    'Admin users now have automatic full subscriber access to all features.',
                type: _ChangeType.feature,
              ),
              _ChangeItem(
                icon: Iconsax.cpu,
                title: 'Chef AI Improvements',
                description:
                    'Redesigned Chef AI settings with cleaner UI and better provider management.',
                type: _ChangeType.improvement,
              ),
              _ChangeItem(
                icon: Iconsax.user,
                title: 'Per-User API Keys',
                description:
                    'API keys are now stored per-user in the database, not shared across users.',
                type: _ChangeType.improvement,
              ),
              _ChangeItem(
                icon: Iconsax.card,
                title: 'Profile Card Fix',
                description:
                    'Fixed overflow issue in profile cards when content is too long.',
                type: _ChangeType.fix,
              ),
            ],
          ),

          const SizedBox(height: 24),

          _buildVersionSection(
            context,
            version: '2.1.0',
            date: 'December 2025',
            changes: [
              _ChangeItem(
                icon: Iconsax.health,
                title: 'Medication Tracking',
                description:
                    'Track your medications with meal reminders. Get notified when to take medications with food.',
                type: _ChangeType.feature,
              ),
              _ChangeItem(
                icon: Iconsax.notification,
                title: 'Push Notifications',
                description:
                    'Real notifications for meal reminders, medication alerts, and low pantry stock.',
                type: _ChangeType.feature,
              ),
              _ChangeItem(
                icon: Iconsax.document,
                title: 'In-App Privacy & Terms',
                description:
                    'View Privacy Policy and Terms of Service directly in the app.',
                type: _ChangeType.feature,
              ),
              _ChangeItem(
                icon: Iconsax.box,
                title: 'Redesigned Pantry',
                description:
                    'Beautiful new pantry screen with improved organization and swipe-to-delete.',
                type: _ChangeType.improvement,
              ),
              _ChangeItem(
                icon: Iconsax.setting_2,
                title: 'Admin Panel',
                description:
                    'Debug tools and data management for app administrators.',
                type: _ChangeType.feature,
              ),
              _ChangeItem(
                icon: Iconsax.shopping_cart,
                title: 'Shopping List Fix',
                description:
                    'Fixed an issue where shopping list items were not being saved.',
                type: _ChangeType.fix,
              ),
              _ChangeItem(
                icon: Iconsax.health,
                title: 'Medications Fix',
                description:
                    'Fixed an issue where medications were not displaying after being added.',
                type: _ChangeType.fix,
              ),
            ],
          ),

          const SizedBox(height: 24),

          _buildVersionSection(
            context,
            version: '2.0.0',
            date: 'December 2025',
            changes: [
              _ChangeItem(
                icon: Iconsax.health,
                title: 'Health Score & Nutrition',
                description:
                    'Visual health meter with detailed per-serving nutrition table for each recipe.',
                type: _ChangeType.feature,
              ),
              _ChangeItem(
                icon: Iconsax.printer,
                title: 'Print Recipes',
                description:
                    'Copy recipes to clipboard in a formatted layout, ready for printing.',
                type: _ChangeType.feature,
              ),
              _ChangeItem(
                icon: Iconsax.edit,
                title: 'Edit Recipes',
                description:
                    'Full recipe editing with nutrition fields, images, and all meal details.',
                type: _ChangeType.feature,
              ),
              _ChangeItem(
                icon: Iconsax.image,
                title: 'Smart Image Search',
                description:
                    'Search and select food images directly in the app - no more copying URLs!',
                type: _ChangeType.feature,
              ),
              _ChangeItem(
                icon: Iconsax.box,
                title: 'Smart Pantry',
                description:
                    'Track ingredients on hand with expiration dates and low-stock alerts.',
                type: _ChangeType.feature,
              ),
              _ChangeItem(
                icon: Iconsax.wallet,
                title: 'Budget Management',
                description:
                    'Set weekly budgets, track spending, and see meal cost breakdowns.',
                type: _ChangeType.feature,
              ),
              _ChangeItem(
                icon: Iconsax.magic_star,
                title: 'AI Recipe Personalization',
                description:
                    'Customize any recipe with AI - adjust portions, dietary needs, difficulty, and more.',
                type: _ChangeType.feature,
              ),
              _ChangeItem(
                icon: Iconsax.discover,
                title: 'Enhanced Discover',
                description:
                    'Quick ideas, cuisine explorer, difficulty filter, and custom meal requests.',
                type: _ChangeType.improvement,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Previous versions
          _buildVersionSection(
            context,
            version: '1.5.0',
            date: 'November 2025',
            changes: [
              _ChangeItem(
                icon: Iconsax.share,
                title: 'Share Recipes',
                description:
                    'Share your favorite recipes with friends and family.',
                type: _ChangeType.feature,
              ),
              _ChangeItem(
                icon: Iconsax.location,
                title: 'Nearby Grocery Stores',
                description:
                    'Find grocery stores near you with map integration.',
                type: _ChangeType.feature,
              ),
              _ChangeItem(
                icon: Iconsax.bookmark,
                title: 'Bookmarks',
                description: 'Save your favorite meals for quick access.',
                type: _ChangeType.feature,
              ),
              _ChangeItem(
                icon: Iconsax.shopping_cart,
                title: 'Shopping List',
                description:
                    'Auto-generate shopping lists from your meal plan.',
                type: _ChangeType.feature,
              ),
            ],
          ),

          const SizedBox(height: 24),

          _buildVersionSection(
            context,
            version: '1.0.0',
            date: 'October 2025',
            changes: [
              _ChangeItem(
                icon: Iconsax.calendar,
                title: '7-Day Meal Planning',
                description:
                    'Plan your entire week with AI-powered meal suggestions.',
                type: _ChangeType.feature,
              ),
              _ChangeItem(
                icon: Iconsax.cpu,
                title: 'AI Meal Generation',
                description:
                    'Generate personalized meals based on your preferences.',
                type: _ChangeType.feature,
              ),
              _ChangeItem(
                icon: Iconsax.moon,
                title: 'Dark Mode',
                description:
                    'Beautiful dark theme for nighttime meal planning.',
                type: _ChangeType.feature,
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Footer
          Center(
            child: Text(
              'Made with ❤️ for home cooks',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildVersionSection(
    BuildContext context, {
    required String version,
    required String date,
    required List<_ChangeItem> changes,
    bool isLatest = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isLatest
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? Colors.white12 : Colors.black12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'v$version',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isLatest
                      ? (isDark ? Colors.black : Colors.white)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              date,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            if (isLatest) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.tick_circle5,
                      size: 14,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Latest',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.green[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        ...changes.map((change) => _buildChangeItem(context, change)),
      ],
    );
  }

  Widget _buildChangeItem(BuildContext context, _ChangeItem change) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final typeColor = switch (change.type) {
      _ChangeType.feature => Colors.blue,
      _ChangeType.improvement => Colors.green,
      _ChangeType.fix => Colors.orange,
    };

    final typeLabel = switch (change.type) {
      _ChangeType.feature => 'NEW',
      _ChangeType.improvement => 'IMPROVED',
      _ChangeType.fix => 'FIXED',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(change.icon, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        change.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        typeLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  change.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _ChangeType { feature, improvement, fix }

class _ChangeItem {
  final IconData icon;
  final String title;
  final String description;
  final _ChangeType type;

  const _ChangeItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.type,
  });
}
