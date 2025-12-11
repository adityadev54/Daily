import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_router.dart';
import '../../data/providers/app_providers.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/widgets.dart';

/// Category List Screen - Shows all drops in a specific category
class CategoryListScreen extends ConsumerWidget {
  final ContentCategory category;

  const CategoryListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drops = ref.watch(dropsByCategoryProvider(category));
    final activeDrops = drops
        .where((d) => d.status == ContentStatus.active)
        .toList();

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2_copy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(category.title, style: AppTypography.headingMedium),
      ),
      body: activeDrops.isEmpty
          ? EmptyState(
              icon: Iconsax.document,
              title: 'No drops yet',
              subtitle: 'Check back later for new content',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: activeDrops.length,
              itemBuilder: (context, index) {
                final drop = activeDrops[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: DropCard(
                    drop: drop,
                    onTap: () => AppRouter.goToPlayer(context, drop.id),
                  ),
                ).animate().fadeIn(
                  duration: 300.ms,
                  delay: Duration(milliseconds: index * 50),
                );
              },
            ),
    );
  }
}

/// New Drops Screen - Shows all new/recent drops
class NewDropsScreen extends ConsumerWidget {
  const NewDropsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drops = ref.watch(newDropsProvider);

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2_copy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('New Drops', style: AppTypography.headingMedium),
      ),
      body: drops.isEmpty
          ? EmptyState(
              icon: Iconsax.document,
              title: 'No new drops',
              subtitle: 'Check back later for new content',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: drops.length,
              itemBuilder: (context, index) {
                final drop = drops[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: DropCard(
                    drop: drop,
                    onTap: () => AppRouter.goToPlayer(context, drop.id),
                  ),
                ).animate().fadeIn(
                  duration: 300.ms,
                  delay: Duration(milliseconds: index * 50),
                );
              },
            ),
    );
  }
}

/// Temporal Drops Screen - Shows time-limited drops
class TemporalDropsScreen extends ConsumerWidget {
  const TemporalDropsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drops = ref.watch(temporalDropsProvider);

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Time-Limited', style: AppTypography.headingMedium),
      ),
      body: drops.isEmpty
          ? EmptyState(
              icon: Iconsax.timer_1,
              title: 'No time-limited drops',
              subtitle: 'Time-sensitive content will appear here',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: drops.length,
              itemBuilder: (context, index) {
                final drop = drops[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: DropCard(
                    drop: drop,
                    onTap: () => AppRouter.goToPlayer(context, drop.id),
                  ),
                ).animate().fadeIn(
                  duration: 300.ms,
                  delay: Duration(milliseconds: index * 50),
                );
              },
            ),
    );
  }
}
