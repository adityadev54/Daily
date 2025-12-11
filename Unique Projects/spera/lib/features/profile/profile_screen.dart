import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_router.dart';
import '../../data/providers/app_providers.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/models/models.dart';

/// Profile Screen - Clean, minimal design
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final authState = ref.watch(authProvider);
    final allDrops = ref.watch(knowledgeDropsProvider);

    final completedDrops = allDrops
        .where((d) => user.completedDropIds.contains(d.id))
        .toList();

    // Get display name from auth if available
    final displayName =
        authState.user?.userMetadata?['display_name'] as String? ??
        authState.user?.email?.split('@').first ??
        user.displayName;

    final email = authState.user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: AppColors.background,
            title: const Text('Profile'),
            titleTextStyle: AppTypography.headingSmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
            actions: [
              IconButton(
                icon: const Icon(Iconsax.setting_2, size: 20),
                onPressed: () => AppRouter.goToSettings(context),
              ),
              const SizedBox(width: 4),
            ],
          ),

          // Profile Header - Centered design
          SliverToBoxAdapter(
            child: _ProfileHeader(
              user: user,
              displayName: displayName,
              email: email,
            ).animate().fadeIn(duration: 400.ms),
          ),

          // Stats Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.lg,
                AppSpacing.screenPadding,
                0,
              ),
              child: _StatsRow(user: user),
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          ),

          // Progress Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: _ProgressSection(user: user),
            ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
          ),

          // Completed Section
          if (completedDrops.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: _SectionTitle(
                  title: 'completed',
                  count: completedDrops.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final drop = completedDrops[index];
                  return _CompletedItem(drop: drop);
                }, childCount: completedDrops.length),
              ),
            ),
          ],

          // Empty state
          if (completedDrops.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding * 2),
                child: Column(
                  children: [
                    Icon(
                      Iconsax.book_1,
                      size: 40,
                      color: AppColors.textTertiary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No completed drops yet',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Start learning to track progress',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Sign Out
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: _SignOutRow(onSignOut: () => _handleSignOut(context, ref)),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final shouldSignOut = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.logout,
                      color: AppColors.error,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Sign out?', style: AppTypography.headingSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Your progress is saved to your account.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Sign Out',
                                style: AppTypography.labelMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
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
    );

    if (shouldSignOut == true) {
      await ref.read(authProvider.notifier).signOut();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }
}

/// Profile header - Centered avatar design
class _ProfileHeader extends StatelessWidget {
  final User user;
  final String displayName;
  final String email;

  const _ProfileHeader({
    required this.user,
    required this.displayName,
    required this.email,
  });

  Color _getRankColor(UserRank rank) {
    return switch (rank) {
      UserRank.observer => AppColors.rankObserver,
      UserRank.analyst => AppColors.rankAnalyst,
      UserRank.strategist => AppColors.rankStrategist,
      UserRank.architect => AppColors.rankArchitect,
    };
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = _getRankColor(user.rank);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rankColor.withValues(alpha: 0.1),
              border: Border.all(
                color: rankColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                displayName.isNotEmpty
                    ? displayName.substring(0, 1).toUpperCase()
                    : 'U',
                style: AppTypography.headingLarge.copyWith(
                  color: rankColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Name
          Text(
            displayName,
            style: AppTypography.headingSmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),

          // Email
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.sm),

          // Rank pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.medal_star, size: 14, color: rankColor),
                const SizedBox(width: 6),
                Text(
                  user.rank.title,
                  style: AppTypography.labelSmall.copyWith(
                    color: rankColor,
                    fontWeight: FontWeight.w500,
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

/// Stats row - Clean inline stats
class _StatsRow extends StatelessWidget {
  final User user;

  const _StatsRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              value: user.xp.toString(),
              label: 'XP',
              icon: Iconsax.flash_1,
              color: AppColors.accent,
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: AppColors.border.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _StatItem(
              value: user.currentStreak.toString(),
              label: 'streak',
              icon: Iconsax.lamp_charge,
              color: AppColors.warning,
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: AppColors.border.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _StatItem(
              value: user.totalCompleted.toString(),
              label: 'completed',
              icon: Iconsax.tick_circle,
              color: AppColors.success,
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: AppColors.border.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _StatItem(
              value: user.requestTokens.toString(),
              label: 'tokens',
              icon: Iconsax.coin_1,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// Progress section - XP to next rank
class _ProgressSection extends StatelessWidget {
  final User user;

  const _ProgressSection({required this.user});

  Color _getRankColor(UserRank rank) {
    return switch (rank) {
      UserRank.observer => AppColors.rankObserver,
      UserRank.analyst => AppColors.rankAnalyst,
      UserRank.strategist => AppColors.rankStrategist,
      UserRank.architect => AppColors.rankArchitect,
    };
  }

  @override
  Widget build(BuildContext context) {
    final nextRank = user.rank.nextRank;
    final hasNextRank = nextRank != null;
    final rankColor = _getRankColor(user.rank);

    if (!hasNextRank) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.rankArchitect.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.rankArchitect.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(Iconsax.crown_1, color: AppColors.rankArchitect, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Maximum rank achieved',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.rankArchitect,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'progress to ${nextRank.title.toLowerCase()}',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              '${user.xpToNextRank} XP left',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Progress bar
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: user.progressToNextRank.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: rankColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // Percentage
        Text(
          '${(user.progressToNextRank * 100).toInt()}%',
          style: AppTypography.labelSmall.copyWith(
            color: rankColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Section title
class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const _SectionTitle({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

/// Completed item - Minimal list item
class _CompletedItem extends StatelessWidget {
  final KnowledgeDrop drop;

  const _CompletedItem({required this.drop});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Type icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              drop.contentType == ContentType.audio
                  ? Iconsax.headphone
                  : Iconsax.video_play,
              color: AppColors.success,
              size: 16,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drop.title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  drop.category.title,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Check
          Icon(Iconsax.tick_circle, color: AppColors.success, size: 18),
        ],
      ),
    );
  }
}

/// Sign out row
class _SignOutRow extends StatelessWidget {
  final VoidCallback onSignOut;

  const _SignOutRow({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSignOut,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(Iconsax.logout, color: AppColors.error, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Sign out',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
            const Spacer(),
            Icon(
              Iconsax.arrow_right_3,
              color: AppColors.textTertiary,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
