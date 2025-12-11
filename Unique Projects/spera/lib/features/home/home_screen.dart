import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_router.dart';
import '../../data/providers/app_providers.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/widgets.dart';

/// Home Screen - The main feed
/// Shows: New Drops, Thinking Tools, Real-World Problems, Skill Unlocks, Temporal
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final newDrops = ref.watch(newDropsProvider);
    final temporalDrops = ref.watch(temporalDropsProvider);
    final thinkingDrops = ref.watch(
      dropsByCategoryProvider(ContentCategory.thinkingTools),
    );
    final problemDrops = ref.watch(
      dropsByCategoryProvider(ContentCategory.realWorldProblems),
    );
    final skillDrops = ref.watch(
      dropsByCategoryProvider(ContentCategory.skillUnlocks),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: AppColors.background,
            title: Text(
              'Spera',
              style: AppTypography.headingMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              // XP indicator
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: _QuickStats(user: user),
              ),
            ],
          ),

          // Welcome message
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                AppSpacing.lg,
              ),
              child: Text(
                'Deploy knowledge. Upgrade thinking.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut),
          ),

          // Temporal Content (if any) - Limited time, shown first with urgency
          if (temporalDrops.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: SectionHeader(
                  title: 'Limited Time',
                  subtitle: 'Expiring soon',
                  trailing: _TimerIcon(),
                  onSeeAll: () => AppRouter.goToTemporalDrops(context),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
            ),
            SliverToBoxAdapter(
              child: HorizontalScrollList(
                height: 200,
                children: temporalDrops
                    .map(
                      (drop) => DropCard(
                        drop: drop,
                        isCompact: true,
                        onTap: () => AppRouter.goToPlayer(context, drop.id),
                      ),
                    )
                    .toList(),
              ).animate().fadeIn(duration: 500.ms, delay: 150.ms),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.sectionGap),
            ),
          ],

          // New Drops
          if (newDrops.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: SectionHeader(
                  title: 'New Drops',
                  subtitle: 'Fresh knowledge',
                  onSeeAll: () => AppRouter.goToNewDrops(context),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
            ),
            SliverToBoxAdapter(
              child: HorizontalScrollList(
                height: 200,
                children: newDrops
                    .take(5)
                    .map(
                      (drop) => DropCard(
                        drop: drop,
                        isCompact: true,
                        onTap: () => AppRouter.goToPlayer(context, drop.id),
                      ),
                    )
                    .toList(),
              ).animate().fadeIn(duration: 500.ms, delay: 250.ms),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.sectionGap),
            ),
          ],

          // Thinking Tools
          if (thinkingDrops.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: SectionHeader(
                  title: 'Thinking Tools',
                  subtitle: 'Frameworks for better thinking',
                  onSeeAll: () => AppRouter.goToCategory(
                    context,
                    ContentCategory.thinkingTools,
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final drop = thinkingDrops[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: DropCard(
                      drop: drop,
                      onTap: () => AppRouter.goToPlayer(context, drop.id),
                    ),
                  );
                }, childCount: thinkingDrops.take(2).length),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          ],

          // Real-World Problems
          if (problemDrops.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: SectionHeader(
                  title: 'Real-World Problems',
                  subtitle: 'Case studies and solutions',
                  onSeeAll: () => AppRouter.goToCategory(
                    context,
                    ContentCategory.realWorldProblems,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: HorizontalScrollList(
                height: 200,
                children: problemDrops
                    .map(
                      (drop) => DropCard(
                        drop: drop,
                        isCompact: true,
                        onTap: () => AppRouter.goToPlayer(context, drop.id),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.sectionGap),
            ),
          ],

          // Skill Unlocks
          if (skillDrops.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: SectionHeader(
                  title: 'Skill Unlocks',
                  subtitle: 'Practical execution guidance',
                  onSeeAll: () => AppRouter.goToCategory(
                    context,
                    ContentCategory.skillUnlocks,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final drop = skillDrops[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: DropCard(
                      drop: drop,
                      onTap: () => AppRouter.goToPlayer(context, drop.id),
                    ),
                  );
                }, childCount: skillDrops.take(2).length),
              ),
            ),
          ],

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  final User user;

  const _QuickStats({required this.user});

  @override
  Widget build(BuildContext context) {
    final isActive = user.currentStreak > 0;

    return GestureDetector(
      onTap: () => AppRouter.goToStreaks(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.flash_1,
            color: isActive ? AppColors.accent : AppColors.textTertiary,
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            '${user.currentStreak}',
            style: AppTypography.labelMedium.copyWith(
              color: isActive ? AppColors.textPrimary : AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Icon(Iconsax.clock, color: AppColors.categoryTemporal, size: 16);
  }
}
