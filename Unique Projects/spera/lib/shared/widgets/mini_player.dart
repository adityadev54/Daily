import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/models.dart';
import '../../data/providers/audio_player_provider.dart';
import '../../data/providers/video_player_provider.dart';

/// Mini player state
class MiniPlayerState {
  final KnowledgeDrop? currentDrop;
  final bool isPlaying;
  final double progress;

  const MiniPlayerState({
    this.currentDrop,
    this.isPlaying = false,
    this.progress = 0.0,
  });

  MiniPlayerState copyWith({
    KnowledgeDrop? currentDrop,
    bool? isPlaying,
    double? progress,
  }) {
    return MiniPlayerState(
      currentDrop: currentDrop ?? this.currentDrop,
      isPlaying: isPlaying ?? this.isPlaying,
      progress: progress ?? this.progress,
    );
  }
}

/// Mini player notifier
class MiniPlayerNotifier extends Notifier<MiniPlayerState> {
  @override
  MiniPlayerState build() => const MiniPlayerState();

  void setDrop(KnowledgeDrop drop) {
    state = state.copyWith(currentDrop: drop, isPlaying: true, progress: 0.0);
  }

  void togglePlayPause() {
    state = state.copyWith(isPlaying: !state.isPlaying);
  }

  void setProgress(double progress) {
    state = state.copyWith(progress: progress);
  }

  void clear() {
    state = const MiniPlayerState();
  }
}

final miniPlayerProvider =
    NotifierProvider<MiniPlayerNotifier, MiniPlayerState>(
      MiniPlayerNotifier.new,
    );

/// Mini Player Bar - Compact Spotify/Apple Music style design
class MiniPlayer extends ConsumerWidget {
  final VoidCallback onTap;

  const MiniPlayer({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(miniPlayerProvider);
    // Watch both audio and video player states
    final audioState = ref.watch(audioPlayerProvider);
    final videoState = ref.watch(videoPlayerProvider);

    if (state.currentDrop == null) {
      return const SizedBox.shrink();
    }

    final drop = state.currentDrop!;
    final isVideo = drop.contentType == ContentType.video;
    final categoryColor = _getCategoryColor(drop.category);
    // Use appropriate player's isPlaying for accurate state
    final isPlaying = isVideo ? videoState.isPlaying : audioState.isPlaying;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: AppColors.background.withValues(alpha: 0.7),
              child: Stack(
                children: [
                  // Progress bar at bottom edge
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: LinearProgressIndicator(
                      value: state.progress,
                      minHeight: 2,
                      backgroundColor: AppColors.surface.withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation(AppColors.accent),
                    ),
                  ),
                  // Content - centered vertically
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          // Content type thumbnail
                          _buildThumbnail(
                            drop,
                            categoryColor,
                            isVideo,
                            videoState.controller,
                          ),
                          const SizedBox(width: 12),
                          // Title and description
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  drop.title,
                                  style: AppTypography.labelMedium.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  drop.description,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textTertiary,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Skip backward button
                          _buildControlButton(
                            context,
                            icon: Iconsax.backward_15_seconds,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              if (isVideo) {
                                ref
                                    .read(videoPlayerProvider.notifier)
                                    .skip(const Duration(seconds: -15));
                              } else {
                                ref
                                    .read(audioPlayerProvider.notifier)
                                    .skip(const Duration(seconds: -15));
                              }
                            },
                            size: 32,
                            iconSize: 16,
                          ),
                          const SizedBox(width: 4),
                          // Play/Pause button
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              if (isVideo) {
                                ref
                                    .read(videoPlayerProvider.notifier)
                                    .togglePlayPause();
                              } else {
                                ref
                                    .read(audioPlayerProvider.notifier)
                                    .togglePlayPause();
                              }
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.textPrimary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPlaying
                                    ? Iconsax.pause_copy
                                    : Iconsax.play_copy,
                                color: AppColors.background,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Skip forward button
                          _buildControlButton(
                            context,
                            icon: Iconsax.forward_15_seconds,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              if (isVideo) {
                                ref
                                    .read(videoPlayerProvider.notifier)
                                    .skip(const Duration(seconds: 15));
                              } else {
                                ref
                                    .read(audioPlayerProvider.notifier)
                                    .skip(const Duration(seconds: 15));
                              }
                            },
                            size: 32,
                            iconSize: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(
    KnowledgeDrop drop,
    Color categoryColor,
    bool isVideo,
    VideoPlayerController? videoController,
  ) {
    if (isVideo &&
        videoController != null &&
        videoController.value.isInitialized) {
      // Video: show live preview with proper aspect ratio
      final videoAspect = videoController.value.aspectRatio;
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Live video preview - properly centered and cropped
            Center(
              child: AspectRatio(
                aspectRatio: videoAspect > 0 ? videoAspect : 16 / 9,
                child: VideoPlayer(videoController),
              ),
            ),
            // Video icon overlay
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Icon(Iconsax.video, color: Colors.white, size: 8),
              ),
            ),
          ],
        ),
      );
    } else if (isVideo) {
      // Video not initialized yet: show placeholder
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: categoryColor.withValues(alpha: 0.3),
        ),
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(categoryColor),
            ),
          ),
        ),
      );
    } else {
      // Audio: show waveform-style visualization
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [categoryColor, categoryColor.withValues(alpha: 0.7)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final heights = [8.0, 14.0, 18.0, 12.0, 15.0];
            return Container(
              width: 3,
              height: heights[index],
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        ),
      );
    }
  }

  Widget _buildControlButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    double size = 32,
    double iconSize = 16,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: iconSize,
        ),
      ),
    );
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
}
