import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';

/// What's New - Clean changelog with timeline design
class WhatsNewScreen extends StatelessWidget {
  const WhatsNewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App bar
          SliverAppBar(
            expandedHeight: 56,
            floating: true,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: const Icon(
                Iconsax.arrow_left_2_copy,
                size: 20,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "What's New",
              style: AppTypography.headingSmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            centerTitle: false,
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),

                  // Current version highlight
                  const _CurrentVersionCard(),
                  const SizedBox(height: AppSpacing.xl),

                  // Timeline
                  const _ChangelogTimeline(),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// CURRENT VERSION CARD
// ============================================

class _CurrentVersionCard extends StatelessWidget {
  const _CurrentVersionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'v1.0.0',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'CURRENT',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Dec 2024',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'First Release',
                style: AppTypography.headingSmall.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'The initial version of Spera with audio studies, transcripts, chapters, and more.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.05, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

// ============================================
// CHANGELOG TIMELINE
// ============================================

class _ChangelogTimeline extends StatelessWidget {
  const _ChangelogTimeline();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Changelog',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // v1.0.0 Release
        _VersionSection(
          version: '1.0.0',
          date: 'December 2024',
          isLatest: true,
          changes: const [
            _ChangeItem(
              type: _ChangeType.feature,
              title: 'Audio Studies',
              description:
                  'Listen to curated knowledge drops with full playback controls',
            ),
            _ChangeItem(
              type: _ChangeType.feature,
              title: 'Video Content',
              description: 'Watch educational content with custom player',
            ),
            _ChangeItem(
              type: _ChangeType.feature,
              title: 'Chapters & Transcripts',
              description:
                  'Navigate content easily with chapters and full transcripts',
            ),
            _ChangeItem(
              type: _ChangeType.feature,
              title: 'Mini Player',
              description: 'Continue listening while browsing the app',
            ),
            _ChangeItem(
              type: _ChangeType.feature,
              title: 'Notes',
              description: 'Take personal notes on any drop',
            ),
            _ChangeItem(
              type: _ChangeType.feature,
              title: 'Sources',
              description: 'See where content comes from with cited sources',
            ),
            _ChangeItem(
              type: _ChangeType.feature,
              title: 'Share',
              description: 'Share drops or quotes with friends',
            ),
            _ChangeItem(
              type: _ChangeType.improvement,
              title: 'Premium Design',
              description: 'Clean dark theme with faded gold accent',
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================
// VERSION SECTION
// ============================================

class _VersionSection extends StatelessWidget {
  final String version;
  final String date;
  final bool isLatest;
  final List<_ChangeItem> changes;

  const _VersionSection({
    required this.version,
    required this.date,
    required this.changes,
    this.isLatest = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Version header
        Row(
          children: [
            // Timeline dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isLatest ? AppColors.accent : AppColors.textTertiary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'v$version',
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '·',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              date,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Changes list with timeline line
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line
            Container(
              width: 10,
              child: Center(
                child: Container(
                  width: 1,
                  height: changes.length * 72.0,
                  color: AppColors.border.withValues(alpha: 0.3),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Changes
            Expanded(
              child: Column(
                children: changes
                    .asMap()
                    .entries
                    .map(
                      (entry) =>
                          _ChangeCard(item: entry.value, index: entry.key),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }
}

// ============================================
// CHANGE CARD
// ============================================

enum _ChangeType { feature, improvement, fix }

class _ChangeItem {
  final _ChangeType type;
  final String title;
  final String description;

  const _ChangeItem({
    required this.type,
    required this.title,
    required this.description,
  });
}

class _ChangeCard extends StatelessWidget {
  final _ChangeItem item;
  final int index;

  const _ChangeCard({required this.item, required this.index});

  Color get _typeColor {
    switch (item.type) {
      case _ChangeType.feature:
        return AppColors.accent;
      case _ChangeType.improvement:
        return const Color(0xFF3B82F6);
      case _ChangeType.fix:
        return AppColors.success;
    }
  }

  IconData get _typeIcon {
    switch (item.type) {
      case _ChangeType.feature:
        return Iconsax.add_circle;
      case _ChangeType.improvement:
        return Iconsax.arrow_up_2;
      case _ChangeType.fix:
        return Iconsax.tick_circle;
    }
  }

  String get _typeLabel {
    switch (item.type) {
      case _ChangeType.feature:
        return 'NEW';
      case _ChangeType.improvement:
        return 'IMPROVED';
      case _ChangeType.fix:
        return 'FIXED';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _typeColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(_typeIcon, size: 14, color: _typeColor),
              ),
              const SizedBox(width: 10),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _typeColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            _typeLabel,
                            style: AppTypography.labelSmall.copyWith(
                              color: _typeColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(
          duration: 250.ms,
          delay: Duration(milliseconds: 150 + index * 40),
        )
        .slideX(
          begin: 0.03,
          end: 0,
          duration: 250.ms,
          delay: Duration(milliseconds: 150 + index * 40),
          curve: Curves.easeOut,
        );
  }
}
