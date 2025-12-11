import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../data/providers/app_providers.dart';

/// Streaks Screen - Shows streak details, calendar, and milestones
class StreaksScreen extends ConsumerWidget {
  const StreaksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: const Icon(Iconsax.arrow_left_2_copy, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Streaks',
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            centerTitle: false,
          ),

          // Main Content
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Streak Hero Card
                _StreakHeroCard(
                  currentStreak: user.currentStreak,
                  longestStreak: user.longestStreak,
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: AppSpacing.xl),

                // Week View
                _WeekView(
                  currentStreak: user.currentStreak,
                  lastStreakDate: user.lastStreakDate,
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                const SizedBox(height: AppSpacing.xl),

                // Stats Row
                _StatsRow(
                  totalCompleted: user.totalCompleted,
                  currentStreak: user.currentStreak,
                  longestStreak: user.longestStreak,
                ).animate().fadeIn(duration: 400.ms, delay: 150.ms),

                const SizedBox(height: AppSpacing.xl),

                // Milestones
                Text(
                  'Milestones',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                const SizedBox(height: AppSpacing.md),
                _MilestonesList(
                  currentStreak: user.currentStreak,
                ).animate().fadeIn(duration: 400.ms, delay: 250.ms),

                const SizedBox(height: AppSpacing.xl),

                // Tips Section
                _TipsCard().animate().fadeIn(duration: 400.ms, delay: 300.ms),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakHeroCard extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;

  const _StreakHeroCard({
    required this.currentStreak,
    required this.longestStreak,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentStreak > 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 32,
        horizontal: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Flame icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.accent.withValues(alpha: 0.1)
                  : AppColors.surfaceHover,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.flash_1,
              color: isActive ? AppColors.accent : AppColors.textTertiary,
              size: 36,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Current streak number
          Text(
            '$currentStreak',
            style: AppTypography.displayLarge.copyWith(
              color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 56,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currentStreak == 1 ? 'day streak' : 'day streak',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w400,
            ),
          ),

          if (currentStreak > 0 && currentStreak == longestStreak) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.crown_1, color: AppColors.success, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Personal best',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeekView extends StatelessWidget {
  final int currentStreak;
  final DateTime? lastStreakDate;

  const _WeekView({required this.currentStreak, this.lastStreakDate});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    // Calculate which days have streaks
    final streakDays = <DateTime>{};
    if (lastStreakDate != null && currentStreak > 0) {
      for (int i = 0; i < currentStreak && i < 7; i++) {
        streakDays.add(
          DateTime(
            lastStreakDate!.year,
            lastStreakDate!.month,
            lastStreakDate!.day - i,
          ),
        );
      }
    }

    // Get start of current week (Monday)
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Week',
          style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final date = startOfWeek.add(Duration(days: index));
            final isToday = date == today;
            final hasStreak = streakDays.contains(date);
            final isPast = date.isBefore(today);
            final isFuture = date.isAfter(today);

            return _DayCircle(
              day: weekDays[index],
              isToday: isToday,
              hasStreak: hasStreak,
              isPast: isPast,
              isFuture: isFuture,
            );
          }),
        ),
      ],
    );
  }
}

class _DayCircle extends StatelessWidget {
  final String day;
  final bool isToday;
  final bool hasStreak;
  final bool isPast;
  final bool isFuture;

  const _DayCircle({
    required this.day,
    required this.isToday,
    required this.hasStreak,
    required this.isPast,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Color borderColor;

    if (hasStreak) {
      bgColor = AppColors.accent;
      textColor = Colors.white;
      borderColor = AppColors.accent;
    } else if (isToday) {
      bgColor = Colors.transparent;
      textColor = AppColors.textPrimary;
      borderColor = AppColors.accent.withValues(alpha: 0.5);
    } else if (isPast) {
      bgColor = AppColors.surfaceElevated;
      textColor = AppColors.textTertiary;
      borderColor = AppColors.border.withValues(alpha: 0.2);
    } else {
      bgColor = Colors.transparent;
      textColor = AppColors.textTertiary;
      borderColor = AppColors.border.withValues(alpha: 0.15);
    }

    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Center(
            child: hasStreak
                ? Icon(Iconsax.tick_circle, color: Colors.white, size: 16)
                : Text(
                    day,
                    style: AppTypography.labelSmall.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        if (isToday)
          Text(
            'Today',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: 9,
            ),
          )
        else
          const SizedBox(height: 11),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int totalCompleted;
  final int currentStreak;
  final int longestStreak;

  const _StatsRow({
    required this.totalCompleted,
    required this.currentStreak,
    required this.longestStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(label: 'Completed', value: '$totalCompleted'),
          ),
          Container(
            width: 1,
            height: 36,
            color: AppColors.border.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _StatItem(label: 'Best Streak', value: '$longestStreak'),
          ),
          Container(
            width: 1,
            height: 36,
            color: AppColors.border.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _StatItem(
              label: 'This Month',
              value: '${_getMonthlyCount()}',
            ),
          ),
        ],
      ),
    );
  }

  int _getMonthlyCount() {
    // Placeholder - would calculate from actual data
    return totalCompleted > 10 ? 10 : totalCompleted;
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headingSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _MilestonesList extends StatelessWidget {
  final int currentStreak;

  const _MilestonesList({required this.currentStreak});

  @override
  Widget build(BuildContext context) {
    final milestones = [
      (days: 3, title: 'Getting Started', icon: Iconsax.star_1),
      (days: 7, title: 'Week Warrior', icon: Iconsax.medal_star),
      (days: 14, title: 'Two Week Titan', icon: Iconsax.shield_tick),
      (days: 30, title: 'Monthly Master', icon: Iconsax.crown_1),
      (days: 60, title: 'Knowledge Keeper', icon: Iconsax.book),
      (days: 100, title: 'Century Club', icon: Iconsax.cup),
    ];

    return Column(
      children: milestones.map((milestone) {
        final isAchieved = currentStreak >= milestone.days;
        final isNext =
            !isAchieved &&
            (milestones.indexOf(milestone) == 0 ||
                currentStreak >=
                    milestones[milestones.indexOf(milestone) - 1].days);

        return _MilestoneItem(
          days: milestone.days,
          title: milestone.title,
          icon: milestone.icon,
          isAchieved: isAchieved,
          isNext: isNext,
          currentStreak: currentStreak,
        );
      }).toList(),
    );
  }
}

class _MilestoneItem extends StatelessWidget {
  final int days;
  final String title;
  final IconData icon;
  final bool isAchieved;
  final bool isNext;
  final int currentStreak;

  const _MilestoneItem({
    required this.days,
    required this.title,
    required this.icon,
    required this.isAchieved,
    required this.isNext,
    required this.currentStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAchieved
              ? AppColors.accent.withValues(alpha: 0.3)
              : AppColors.border.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isAchieved
                  ? AppColors.accent.withValues(alpha: 0.1)
                  : AppColors.surfaceHover,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isAchieved ? AppColors.accent : AppColors.textTertiary,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isAchieved
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                Text(
                  '$days days',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (isAchieved)
            Icon(Iconsax.tick_circle, color: AppColors.accent, size: 18)
          else if (isNext) ...[
            Text(
              '${days - currentStreak} left',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ] else
            Icon(Iconsax.lock_1, color: AppColors.textTertiary, size: 16),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Iconsax.info_circle, color: AppColors.textTertiary, size: 16),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Complete at least one drop every day to maintain your streak.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
