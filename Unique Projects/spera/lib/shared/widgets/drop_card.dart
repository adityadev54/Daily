import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/models.dart';

/// Knowledge Drop Card - the core content card
class DropCard extends StatelessWidget {
  final KnowledgeDrop drop;
  final VoidCallback onTap;
  final bool isCompact;

  const DropCard({
    super.key,
    required this.drop,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _CompactDropCard(drop: drop, onTap: onTap);
    }
    return _FullDropCard(drop: drop, onTap: onTap);
  }
}

class _FullDropCard extends StatelessWidget {
  final KnowledgeDrop drop;
  final VoidCallback onTap;

  const _FullDropCard({required this.drop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - same style for both audio and video
            _AudioHeader(drop: drop),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Duration row
                  Row(
                    children: [
                      _CategoryChip(category: drop.category),
                      const Spacer(),
                      _DurationBadge(duration: drop.formattedDuration),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Title
                  Text(
                    drop.title,
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Description
                  Text(
                    drop.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Bottom row: XP & Difficulty
                  Row(
                    children: [
                      _XpBadge(xp: drop.xpReward),
                      const SizedBox(width: AppSpacing.sm),
                      _DifficultyIndicator(difficulty: drop.difficulty),
                      if (drop.isTemporal) ...[
                        const Spacer(),
                        _ExpiryBadge(expiresAt: drop.expiresAt!),
                      ],
                    ],
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

class _CompactDropCard extends StatelessWidget {
  final KnowledgeDrop drop;
  final VoidCallback onTap;

  const _CompactDropCard({required this.drop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              height: 90,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _getCategoryColor(drop.category).withValues(alpha: 0.1),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Icon(
                      drop.contentType == ContentType.audio
                          ? Iconsax.headphone
                          : Iconsax.play_circle,
                      color: _getCategoryColor(drop.category),
                      size: 18,
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _DurationBadge(duration: drop.formattedDuration),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category label at top
                  Text(
                    drop.category.title,
                    style: AppTypography.labelSmall.copyWith(
                      color: _getCategoryColor(drop.category),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Title
                  Text(
                    drop.title,
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  // Bottom row with XP and difficulty
                  Row(
                    children: [
                      _XpBadge(xp: drop.xpReward, isSmall: true),
                      const Spacer(),
                      _DifficultyIndicator(difficulty: drop.difficulty),
                    ],
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

class _AudioHeader extends StatelessWidget {
  final KnowledgeDrop drop;

  const _AudioHeader({required this.drop});

  @override
  Widget build(BuildContext context) {
    final isVideo = drop.contentType == ContentType.video;
    return Container(
      height: 90,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _getCategoryColor(drop.category).withValues(alpha: 0.1),
      ),
      child: Center(
        child: Icon(
          isVideo ? Iconsax.play_circle : Iconsax.headphone,
          color: _getCategoryColor(drop.category),
          size: 28,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final ContentCategory category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _getCategoryColor(category).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        category.title,
        style: AppTypography.labelSmall.copyWith(
          color: _getCategoryColor(category),
          fontSize: 10,
        ),
      ),
    );
  }
}

class _DurationBadge extends StatelessWidget {
  final String duration;

  const _DurationBadge({required this.duration});

  @override
  Widget build(BuildContext context) {
    return Text(
      duration,
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textTertiary,
        fontSize: 11,
      ),
    );
  }
}

class _XpBadge extends StatelessWidget {
  final int xp;
  final bool isSmall;

  const _XpBadge({required this.xp, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Iconsax.flash, color: AppColors.accent, size: isSmall ? 14 : 16),
        const SizedBox(width: 2),
        Text(
          '+$xp XP',
          style:
              (isSmall ? AppTypography.labelSmall : AppTypography.labelMedium)
                  .copyWith(color: AppColors.accent),
        ),
      ],
    );
  }
}

class _DifficultyIndicator extends StatelessWidget {
  final ContentDifficulty difficulty;

  const _DifficultyIndicator({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final isActive = index < difficulty.level;
        return Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: isActive ? AppColors.textSecondary : AppColors.border,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _ExpiryBadge extends StatelessWidget {
  final DateTime expiresAt;

  const _ExpiryBadge({required this.expiresAt});

  String _formatTimeRemaining() {
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.inDays > 0) {
      return '${remaining.inDays}d left';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h left';
    } else {
      return '${remaining.inMinutes}m left';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Iconsax.clock, color: AppColors.categoryTemporal, size: 12),
        const SizedBox(width: 4),
        Text(
          _formatTimeRemaining(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.categoryTemporal,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

Color _getCategoryColor(ContentCategory category) {
  return switch (category) {
    ContentCategory.thinkingTools => AppColors.categoryThinking,
    ContentCategory.realWorldProblems => AppColors.categoryProblems,
    ContentCategory.skillUnlocks => AppColors.categorySkills,
    ContentCategory.decisionFrameworks => AppColors.accent,
    ContentCategory.temporal => AppColors.categoryTemporal,
  };
}
