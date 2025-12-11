import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_router.dart';
import '../../core/services/supabase_service.dart';
import '../../data/providers/app_providers.dart';
import '../../data/providers/admin_providers.dart';
import '../../data/providers/transcript_provider.dart';
import '../../data/providers/audio_player_provider.dart';
import '../../data/providers/video_player_provider.dart';
import '../../data/repositories/reports_repository.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/mini_player.dart';

/// Enhanced Player Screen with chapters, notes, speed controls
class PlayerScreen extends ConsumerStatefulWidget {
  final String dropId;

  const PlayerScreen({super.key, required this.dropId});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with SingleTickerProviderStateMixin {
  bool _isCompleted = false;
  bool _completionDialogShown = false; // Track if dialog was shown this session
  bool _showFullDescription = false;
  // ignore: unused_field
  bool _isFullscreen = false;
  int _currentChapterIndex = 0;
  int _currentTranscriptIndex = 0;
  final List<String> _userNotes = [];
  final TextEditingController _noteController = TextEditingController();
  final ScrollController _transcriptScrollController = ScrollController();

  // Tab state for bottom panel
  int _selectedTabIndex = -1; // -1 means closed

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if already completed from user state
      final user = ref.read(userProvider);
      if (user.completedDropIds.contains(widget.dropId)) {
        setState(() => _isCompleted = true);
      }

      ref.read(userProvider.notifier).startDrop(widget.dropId);
      // Get the drop and start playing
      final drops = ref.read(knowledgeDropsProvider);
      final drop = drops.firstWhere(
        (d) => d.id == widget.dropId,
        orElse: () => drops.first,
      );

      // Use appropriate player based on content type
      if (drop.contentType == ContentType.video) {
        final videoService = ref.read(videoPlayerProvider.notifier);
        final currentDrop = ref.read(videoPlayerProvider).currentDrop;
        if (currentDrop?.id != drop.id) {
          videoService.playDrop(drop);
        }
      } else {
        final audioService = ref.read(audioPlayerProvider.notifier);
        final currentDrop = ref.read(audioPlayerProvider).currentDrop;
        if (currentDrop?.id != drop.id) {
          audioService.playDrop(drop);
        }
      }

      // Set mini player
      ref.read(miniPlayerProvider.notifier).setDrop(drop);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _noteController.dispose();
    _transcriptScrollController.dispose();
    // Don't dispose players - they're global now
    super.dispose();
  }

  /// Get the current drop
  KnowledgeDrop get _currentDrop {
    final drops = ref.read(knowledgeDropsProvider);
    return drops.firstWhere(
      (d) => d.id == widget.dropId,
      orElse: () => drops.first,
    );
  }

  /// Check if current drop is video
  bool get _isVideo => _currentDrop.contentType == ContentType.video;

  // Getters that use appropriate provider based on content type
  bool get _isPlaying => _isVideo
      ? ref.read(videoPlayerProvider).isPlaying
      : ref.read(audioPlayerProvider).isPlaying;

  double get _progress => _isVideo
      ? ref.read(videoPlayerProvider).progress
      : ref.read(audioPlayerProvider).progress;

  double get _playbackSpeed => _isVideo
      ? ref.read(videoPlayerProvider).playbackSpeed
      : ref.read(audioPlayerProvider).playbackSpeed;

  Duration get _duration => _isVideo
      ? ref.read(videoPlayerProvider).duration
      : ref.read(audioPlayerProvider).duration;

  bool get _isLoadingMedia => _isVideo
      ? ref.read(videoPlayerProvider).isLoading
      : ref.read(audioPlayerProvider).isLoading;

  String? get _mediaError => _isVideo
      ? ref.read(videoPlayerProvider).error
      : ref.read(audioPlayerProvider).error;

  bool get _useRealMedia => _mediaError == null && !_isLoadingMedia;

  void _togglePlayPause() {
    HapticFeedback.lightImpact();
    if (_isVideo) {
      ref.read(videoPlayerProvider.notifier).togglePlayPause();
    } else {
      ref.read(audioPlayerProvider.notifier).togglePlayPause();
    }
  }

  /// Get current time in seconds based on progress
  double get _currentTimeSeconds {
    if (_duration.inSeconds > 0) {
      return _progress * _duration.inSeconds;
    }
    return _progress * _currentDrop.durationSeconds;
  }

  void _updateCurrentChapter() {
    final transcript = ref.read(transcriptProvider(widget.dropId));
    if (transcript == null || transcript.chapters.isEmpty) return;

    final currentTime = _currentTimeSeconds;
    final newIndex = transcript.chapterIndexAt(currentTime);

    if (newIndex >= 0 && newIndex != _currentChapterIndex) {
      setState(() => _currentChapterIndex = newIndex);
    }

    // Also update transcript index
    final segmentIndex = transcript.segmentIndexAt(currentTime);
    if (segmentIndex >= 0 && segmentIndex != _currentTranscriptIndex) {
      setState(() => _currentTranscriptIndex = segmentIndex);
      _autoScrollTranscript(segmentIndex);
    }
  }

  void _autoScrollTranscript(int index) {
    if (_selectedTabIndex != 1 || !_transcriptScrollController.hasClients)
      return;

    // Scroll to keep current segment visible
    final itemHeight = 80.0; // Approximate height of each segment
    final targetOffset = (index * itemHeight) - 100; // Offset to show context

    _transcriptScrollController.animateTo(
      targetOffset.clamp(
        0.0,
        _transcriptScrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _seekToChapter(int index) {
    HapticFeedback.selectionClick();
    final transcript = ref.read(transcriptProvider(widget.dropId));
    if (transcript == null || transcript.chapters.isEmpty) return;

    final chapter = transcript.chapters[index];

    // Use appropriate provider to seek
    _seekToPosition(Duration(seconds: chapter.startTime.round()));

    setState(() {
      _currentChapterIndex = index;
    });
  }

  void _changeSpeed(double speed) {
    HapticFeedback.selectionClick();
    if (_isVideo) {
      ref.read(videoPlayerProvider.notifier).setSpeed(speed);
    } else {
      ref.read(audioPlayerProvider.notifier).setSpeed(speed);
    }
    Navigator.pop(context);
  }

  void _addNote() {
    if (_noteController.text.trim().isNotEmpty) {
      setState(() {
        _userNotes.add(_noteController.text.trim());
        _noteController.clear();
      });
      HapticFeedback.mediumImpact();
    }
  }

  void _skip(double amount) {
    HapticFeedback.lightImpact();
    final currentDuration = _duration.inMilliseconds > 0
        ? _duration
        : Duration(seconds: _currentDrop.durationSeconds);

    // Calculate skip in milliseconds
    final skipMs = (amount * currentDuration.inMilliseconds).round();
    if (_isVideo) {
      ref
          .read(videoPlayerProvider.notifier)
          .skip(Duration(milliseconds: skipMs));
    } else {
      ref
          .read(audioPlayerProvider.notifier)
          .skip(Duration(milliseconds: skipMs));
    }
  }

  void _replay() {
    HapticFeedback.mediumImpact();
    // Seek to beginning and play (no XP reward since already completed)
    if (_isVideo) {
      ref.read(videoPlayerProvider.notifier).seek(Duration.zero);
      ref.read(videoPlayerProvider.notifier).play();
    } else {
      ref.read(audioPlayerProvider.notifier).seek(Duration.zero);
      ref.read(audioPlayerProvider.notifier).play();
    }
  }

  /// Helper to seek to a position using appropriate provider
  void _seekToPosition(Duration position) {
    if (_isVideo) {
      ref.read(videoPlayerProvider.notifier).seek(position);
    } else {
      ref.read(audioPlayerProvider.notifier).seek(position);
    }
  }

  /// Helper to seek to a progress value using appropriate provider
  void _seekToProgress(double progress) {
    if (_isVideo) {
      ref.read(videoPlayerProvider.notifier).seekToProgress(progress);
    } else {
      ref.read(audioPlayerProvider.notifier).seekToProgress(progress);
    }
  }

  void _markCompleted() {
    if (_isCompleted || _completionDialogShown) return;

    final drops = ref.read(knowledgeDropsProvider);
    final drop = drops.firstWhere((d) => d.id == widget.dropId);

    ref.read(userProvider.notifier).completeDrop(widget.dropId, drop.xpReward);

    setState(() {
      _isCompleted = true;
      _completionDialogShown = true;
    });
    _showCompletionDialog(drop);
  }

  void _showCompletionDialog(KnowledgeDrop drop) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: AppColors.surface.withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.flash_1, color: AppColors.accent, size: 40),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Knowledge Unlocked',
                style: AppTypography.headingSmall.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '+${drop.xpReward} XP',
                style: AppTypography.headingMedium.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'You\'ve completed "${drop.title}"',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Done',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeedPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.85),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Playback Speed',
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Horizontal speed selector
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0].map((
                        speed,
                      ) {
                        final isSelected = _playbackSpeed == speed;
                        return GestureDetector(
                          onTap: () => _changeSpeed(speed),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.surfaceElevated.withValues(
                                      alpha: 0.6,
                                    ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent
                                    : AppColors.border.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '${speed}x',
                              style: AppTypography.labelMedium.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context, KnowledgeDrop drop) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.85),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.border.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Share option
                    ListTile(
                      leading: Icon(
                        Iconsax.share,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      title: Text('Share', style: AppTypography.bodyMedium),
                      trailing: Icon(
                        Iconsax.arrow_right_3_copy,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showShareOptions(drop);
                      },
                    ),
                    // Add to queue option
                    ListTile(
                      leading: Icon(
                        Iconsax.music_playlist,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      title: Text(
                        'Add to Queue',
                        style: AppTypography.bodyMedium,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text('Added to queue'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    // Sleep timer option
                    ListTile(
                      leading: Icon(
                        Iconsax.timer_1,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      title: Text(
                        'Sleep Timer',
                        style: AppTypography.bodyMedium,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showSleepTimerPicker();
                      },
                    ),
                    // Report issue option
                    ListTile(
                      leading: Icon(
                        Iconsax.flag,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      title: Text(
                        'Report Issue',
                        style: AppTypography.bodyMedium,
                      ),
                      trailing: Icon(
                        Iconsax.arrow_right_3_copy,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showReportIssueSheet(drop);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSleepTimerPicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.85),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.border.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Sleep Timer',
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _buildTimerOption('Off', null),
                        _buildTimerOption('15 min', 15),
                        _buildTimerOption('30 min', 30),
                        _buildTimerOption('45 min', 45),
                        _buildTimerOption('1 hour', 60),
                        _buildTimerOption('End of drop', -1),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerOption(String label, int? minutes) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        HapticFeedback.selectionClick();
        if (minutes != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                minutes == -1
                    ? 'Playback will stop at end of drop'
                    : 'Sleep timer set for $label',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showShareOptions(KnowledgeDrop drop) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.85),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.border.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Share',
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      drop.title,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Share options grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildShareOption(
                          icon: Iconsax.copy,
                          label: 'Copy Link',
                          onTap: () {
                            Navigator.pop(context);
                            Clipboard.setData(
                              ClipboardData(
                                text:
                                    'Check out "${drop.title}" on Spera!\n\nhttps://spera.app/drop/${drop.id}',
                              ),
                            );
                            HapticFeedback.mediumImpact();
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      Iconsax.tick_circle,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Link copied to clipboard'),
                                  ],
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                        ),
                        _buildShareOption(
                          icon: Iconsax.message,
                          label: 'Message',
                          onTap: () async {
                            Navigator.pop(context);
                            HapticFeedback.lightImpact();
                            final shareText =
                                '🎧 Just listened to "${drop.title}" on Spera!\n\n${drop.description}\n\nCheck it out: https://spera.app/drop/${drop.id}';
                            await SharePlus.instance.share(
                              ShareParams(text: shareText),
                            );
                          },
                        ),
                        _buildShareOption(
                          icon: Iconsax.document_text,
                          label: 'Quote',
                          onTap: () {
                            Navigator.pop(context);
                            _showShareQuoteSheet(drop);
                          },
                        ),
                        _buildShareOption(
                          icon: Iconsax.export_1,
                          label: 'More',
                          onTap: () async {
                            Navigator.pop(context);
                            HapticFeedback.lightImpact();
                            final shareText =
                                '🎧 "${drop.title}" on Spera\n\n${drop.description}\n\n📱 https://spera.app/drop/${drop.id}';
                            await SharePlus.instance.share(
                              ShareParams(text: shareText),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Social share buttons
                    Text(
                      'Share to',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        _buildSocialShareButton(
                          label: 'Twitter / X',
                          color: const Color(0xFF000000),
                          icon: Icons.alternate_email,
                          onTap: () async {
                            Navigator.pop(context);
                            final text = Uri.encodeComponent(
                              '🎧 Just listened to "${drop.title}" on @SperaApp!\n\nHighly recommend this knowledge drop.',
                            );
                            final url = Uri.parse(
                              'https://twitter.com/intent/tweet?text=$text',
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _buildSocialShareButton(
                          label: 'LinkedIn',
                          color: const Color(0xFF0A66C2),
                          icon: Icons.work_outline,
                          onTap: () async {
                            Navigator.pop(context);
                            final url = Uri.parse(
                              'https://www.linkedin.com/sharing/share-offsite/?url=https://spera.app/drop/${drop.id}',
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialShareButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareQuoteSheet(KnowledgeDrop drop) {
    final transcript = ref.read(transcriptProvider(widget.dropId));
    final quotes =
        transcript?.segments
            .where((s) => s.text.length > 50 && s.text.length < 200)
            .take(5)
            .toList() ??
        [];

    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.85),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.border.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Share a Quote',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Select a highlight to share',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (quotes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xl,
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Iconsax.document,
                              size: 40,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'No quotes available yet',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: quotes.length,
                        itemBuilder: (context, index) {
                          final quote = quotes[index];
                          return GestureDetector(
                            onTap: () async {
                              Navigator.pop(context);
                              HapticFeedback.mediumImpact();
                              final shareText =
                                  '"${quote.text}"\n\n— From "${drop.title}" on Spera\n\n🎧 https://spera.app/drop/${drop.id}';
                              await SharePlus.instance.share(
                                ShareParams(text: shareText),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated.withValues(
                                  alpha: 0.6,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.border.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Iconsax.quote_up,
                                        size: 14,
                                        color: AppColors.accent,
                                      ),
                                      const Spacer(),
                                      Icon(
                                        Iconsax.export_1,
                                        size: 14,
                                        color: AppColors.textTertiary,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    quote.text,
                                    style: AppTypography.bodySmall.copyWith(
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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

  void _showReportIssueSheet(KnowledgeDrop drop) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.85),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.lg,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.border.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Iconsax.flag, color: AppColors.warning, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Report Issue',
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Help us improve "${drop.title}"',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Issue type options
                    Text(
                      'What\'s the issue?',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildReportOption(
                      icon: Iconsax.sound,
                      title: 'Audio Problem',
                      subtitle: 'Quality, sync, or playback issues',
                      onTap: () => _submitReport(drop, 'audio_problem'),
                    ),
                    _buildReportOption(
                      icon: Iconsax.document_text,
                      title: 'Incorrect Transcript',
                      subtitle: 'Errors in the text transcription',
                      onTap: () => _submitReport(drop, 'transcript_error'),
                    ),
                    _buildReportOption(
                      icon: Iconsax.info_circle,
                      title: 'Inaccurate Information',
                      subtitle: 'Factual errors or outdated content',
                      onTap: () => _submitReport(drop, 'inaccurate_info'),
                    ),
                    _buildReportOption(
                      icon: Iconsax.danger,
                      title: 'Inappropriate Content',
                      subtitle: 'Content that violates guidelines',
                      onTap: () => _submitReport(drop, 'inappropriate'),
                    ),
                    _buildReportOption(
                      icon: Iconsax.message_question,
                      title: 'Other Issue',
                      subtitle: 'Something else not listed above',
                      onTap: () => _showDetailedReportSheet(drop),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceHover.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Iconsax.arrow_right_3_copy,
              size: 14,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _submitReport(KnowledgeDrop drop, String issueType) {
    Navigator.pop(context);
    HapticFeedback.mediumImpact();

    // Create and save report to Supabase
    final userId = SupabaseService.currentUser?.id;
    if (userId != null) {
      final report = UserReport(
        id: const Uuid().v4(),
        userId: userId,
        dropId: drop.id,
        dropTitle: drop.title,
        issueType: issueType,
        createdAt: DateTime.now(),
        status: ReportStatus.pending,
      );

      ref.read(supabaseReportsNotifierProvider.notifier).addReport(report);
    }

    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Iconsax.tick_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Thanks for reporting! We\'ll review this soon.'),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showDetailedReportSheet(KnowledgeDrop drop) {
    Navigator.pop(context);
    final reportController = TextEditingController();

    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.85),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.lg,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.border.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Describe the Issue',
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.3),
                        ),
                      ),
                      child: TextField(
                        controller: reportController,
                        maxLines: 4,
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Tell us what went wrong...',
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (reportController.text.trim().isNotEmpty) {
                            // Save to Supabase
                            final userId = SupabaseService.currentUser?.id;
                            if (userId != null) {
                              final report = UserReport(
                                id: const Uuid().v4(),
                                userId: userId,
                                dropId: drop.id,
                                dropTitle: drop.title,
                                issueType: 'other',
                                description: reportController.text.trim(),
                                createdAt: DateTime.now(),
                                status: ReportStatus.pending,
                              );

                              ref
                                  .read(
                                    supabaseReportsNotifierProvider.notifier,
                                  )
                                  .addReport(report);
                            }

                            Navigator.pop(context);
                            HapticFeedback.mediumImpact();
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      Iconsax.tick_circle,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Report submitted. Thanks for your feedback!',
                                      ),
                                    ),
                                  ],
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Submit Report',
                          style: AppTypography.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drops = ref.watch(knowledgeDropsProvider);
    final user = ref.watch(userProvider);

    final drop = drops.firstWhere(
      (d) => d.id == widget.dropId,
      orElse: () => drops.first,
    );

    // Watch appropriate player state based on content type
    final isVideo = drop.contentType == ContentType.video;
    if (isVideo) {
      ref.watch(videoPlayerProvider);
    } else {
      ref.watch(audioPlayerProvider);
    }

    // Update chapter index when progress changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateCurrentChapter();
        // Check for completion only if:
        // 1. This drop is currently loaded
        // 2. Progress is at or near completion
        // 3. Not already marked completed
        // 4. Content has actually been playing (duration > 0)
        final currentDropId = isVideo
            ? ref.read(videoPlayerProvider).currentDrop?.id
            : ref.read(audioPlayerProvider).currentDrop?.id;
        final isCurrentDrop = currentDropId == widget.dropId;
        final hasPlayedContent =
            _duration.inSeconds > 0 ||
            (_progress > 0.1); // At least 10% progress
        if (isCurrentDrop &&
            _progress >= 0.99 &&
            !_isCompleted &&
            !_completionDialogShown &&
            hasPlayedContent) {
          _markCompleted();
        }
      }
    });

    final isBookmarked = user.isBookmarked(drop.id);

    // Get related drops (same category, excluding current)
    final relatedDrops = drops
        .where((d) => d.category == drop.category && d.id != drop.id)
        .take(3)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(context, drop, isBookmarked),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Visualization
                    _buildVisualization(drop)
                        .animate()
                        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                        .scale(begin: const Offset(0.95, 0.95)),
                    const SizedBox(height: AppSpacing.lg),

                    // Title and metadata
                    _buildTitleSection(
                      drop,
                    ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                    const SizedBox(height: AppSpacing.sm),

                    // Progress and controls
                    _buildProgressSection(
                      drop,
                    ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                    const SizedBox(height: AppSpacing.sm),

                    // Play controls
                    _buildPlayControls().animate().fadeIn(
                      duration: 400.ms,
                      delay: 300.ms,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Related drops
                    if (relatedDrops.isNotEmpty) ...[
                      _buildRelatedDrops(
                        relatedDrops,
                      ).animate().fadeIn(duration: 500.ms, delay: 350.ms),
                    ],

                    // NotebookLLM Attribution
                    _buildAttribution().animate().fadeIn(
                      duration: 400.ms,
                      delay: 400.ms,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),

            // Bottom Tab Bar + Content Panel
            _buildBottomTabSection(drop),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    KnowledgeDrop drop,
    bool isBookmarked,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Iconsax.arrow_down_1_copy, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          // Speed indicator
          GestureDetector(
            onTap: _showSpeedPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_playbackSpeed}x',
                style: AppTypography.labelSmall.copyWith(
                  color: _playbackSpeed != 1.0
                      ? AppColors.accent
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: Icon(
              isBookmarked ? Iconsax.bookmark : Iconsax.bookmark_copy,
              color: isBookmarked ? AppColors.accent : null,
              size: 22,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(userProvider.notifier).toggleBookmark(drop.id);
            },
          ),
          IconButton(
            icon: Icon(Iconsax.more_square_copy, size: 22),
            onPressed: () => _showMoreOptions(context, drop),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualization(KnowledgeDrop drop) {
    final categoryColor = _getCategoryColor(drop.category);
    final hasVideo = drop.contentType == ContentType.video;

    // Always show audio-style visualization (premium experience)
    return Column(
      children: [
        Center(
          child: SizedBox(
            width: 250,
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        categoryColor.withValues(alpha: 0.0),
                        categoryColor.withValues(
                          alpha: _isPlaying ? 0.1 : 0.05,
                        ),
                      ],
                    ),
                  ),
                ),
                // Animated rings when playing
                if (_isPlaying)
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(200, 200),
                        painter: _WaveformPainter(
                          progress: _animationController.value,
                          color: categoryColor,
                        ),
                      );
                    },
                  ),
                // Background circle
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.surfaceElevated, AppColors.surface],
                    ),
                    border: Border.all(
                      color: categoryColor.withValues(
                        alpha: _isPlaying ? 0.4 : 0.2,
                      ),
                      width: 2,
                    ),
                    boxShadow: _isPlaying
                        ? [
                            BoxShadow(
                              color: categoryColor.withValues(alpha: 0.3),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                ),
                // Category icon or video icon
                Icon(
                  hasVideo
                      ? Iconsax.video_play
                      : _getCategoryIcon(drop.category),
                  size: 48,
                  color: categoryColor,
                ),
              ],
            ),
          ),
        ),
        // Watch Video button - only for video content
        if (hasVideo) ...[
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: () => _openVideoPlayer(drop),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.video, size: 16, color: AppColors.background),
                  const SizedBox(width: 8),
                  Text(
                    'WATCH',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.background,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _openVideoPlayer(KnowledgeDrop drop) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VideoPlayerSheet(drop: drop),
    );
  }

  Widget _buildTitleSection(KnowledgeDrop drop) {
    final categoryColor = _getCategoryColor(drop.category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          drop.title,
          style: AppTypography.headingSmall.copyWith(
            height: 1.2,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Metadata row - compact
        Row(
          children: [
            // Category badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                drop.category.title,
                style: AppTypography.labelSmall.copyWith(
                  color: categoryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Iconsax.clock, size: 12, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Text(
              drop.formattedDuration,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const Spacer(),
            Icon(Iconsax.flash_1, size: 12, color: AppColors.accent),
            const SizedBox(width: 4),
            Text(
              '+${drop.xpReward} XP',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Description with expand/collapse
        GestureDetector(
          onTap: () =>
              setState(() => _showFullDescription = !_showFullDescription),
          child: AnimatedCrossFade(
            firstChild: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    drop.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (drop.description.length > 100) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Iconsax.arrow_down_1_copy,
                    size: 14,
                    color: AppColors.accent,
                  ),
                ],
              ],
            ),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drop.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Iconsax.arrow_up_2_copy,
                      size: 14,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Show less',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            crossFadeState: _showFullDescription
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(KnowledgeDrop drop) {
    // Use real duration if available, otherwise use drop metadata
    final totalDuration = _useRealMedia && _duration.inSeconds > 0
        ? _duration
        : Duration(seconds: drop.durationSeconds);

    final elapsed = Duration(
      seconds: (totalDuration.inSeconds * _progress).round(),
    );

    return Column(
      children: [
        // Loading indicator
        if (_isLoadingMedia) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Loading media...',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Media status indicator (for demo mode)
        if (_mediaError != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.info_circle,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _mediaError!,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Time display - above slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(elapsed),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
              Text(
                _formatDuration(totalDuration),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // Modern progress slider
        SizedBox(
          height: 32,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              final thumbPosition = trackWidth * _progress.clamp(0.0, 1.0);

              return GestureDetector(
                onHorizontalDragUpdate: (details) {
                  final newProgress = (details.localPosition.dx / trackWidth)
                      .clamp(0.0, 1.0);
                  _seekToProgress(newProgress);
                },
                onTapDown: (details) {
                  final newProgress = (details.localPosition.dx / trackWidth)
                      .clamp(0.0, 1.0);
                  _seekToProgress(newProgress);
                },
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Background track
                        Container(
                          height: 4,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Active track with gradient
                        Container(
                          height: 4,
                          width: thumbPosition,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.accent.withValues(alpha: 0.7),
                                AppColors.accent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Thumb
                        Positioned(
                          left: thumbPosition - 8,
                          top: -6,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayControls() {
    // Show replay button when completed
    if (_isCompleted && !_isPlaying && _progress >= 0.99) {
      return Column(
        children: [
          // Completed badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withValues(alpha: 0.2),
                  AppColors.success.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.tick_circle,
                    color: AppColors.success,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Completed!',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Replay controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                icon: Iconsax.backward_15_seconds,
                onTap: () => _skip(-0.05),
                size: 48,
              ),
              const SizedBox(width: AppSpacing.xl),

              // Replay button
              _buildMainButton(
                icon: Iconsax.refresh,
                onTap: _replay,
                isPlaying: false,
                isReplay: true,
              ),
              const SizedBox(width: AppSpacing.xl),

              _buildControlButton(
                icon: Iconsax.forward_15_seconds,
                onTap: () => _skip(0.05),
                size: 48,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Replay without earning XP',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(
          icon: Iconsax.backward_15_seconds,
          onTap: () => _skip(-0.05),
          size: 48,
        ),
        const SizedBox(width: AppSpacing.xl),

        // Play/Pause
        _buildMainButton(
          icon: _isPlaying ? Iconsax.pause : Iconsax.play,
          onTap: _togglePlayPause,
          isPlaying: _isPlaying,
        ),
        const SizedBox(width: AppSpacing.xl),

        _buildControlButton(
          icon: Iconsax.forward_15_seconds,
          onTap: () => _skip(0.05),
          size: 48,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 44,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: size * 0.45),
        ),
      ),
    );
  }

  Widget _buildMainButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isPlaying = false,
    bool isReplay = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          gradient: isReplay
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.accent,
                    AppColors.accent.withValues(alpha: 0.85),
                  ],
                ),
          color: isReplay
              ? AppColors.surfaceElevated.withValues(alpha: 0.6)
              : null,
          shape: BoxShape.circle,
          border: isReplay
              ? Border.all(
                  color: AppColors.accent.withValues(alpha: 0.6),
                  width: 1.5,
                )
              : null,
          boxShadow: isReplay
              ? null
              : [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Icon(
          icon,
          color: isReplay ? AppColors.accent : Colors.white,
          size: 32,
        ),
      ),
    );
  }

  IconData _getSourceIcon(SourceType type) {
    return switch (type) {
      SourceType.book => Iconsax.book,
      SourceType.article => Iconsax.document_text,
      SourceType.paper => Iconsax.document,
      SourceType.video => Iconsax.video,
      SourceType.podcast => Iconsax.microphone_2,
      SourceType.website => Iconsax.global,
      SourceType.course => Iconsax.teacher,
      SourceType.other => Iconsax.document_1,
    };
  }

  Widget _buildAttribution() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Iconsax.magic_star,
                    size: 12,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Powered by ',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'NotebookLLM',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomTabSection(KnowledgeDrop drop) {
    final transcript = ref.watch(transcriptProvider(widget.dropId));
    final chapters = transcript?.chapters ?? [];
    final hasSources = drop.sources != null && drop.sources!.isNotEmpty;

    // Tab items
    final tabs = [
      (icon: Iconsax.menu_1, label: 'Chapters', count: chapters.length),
      (
        icon: Iconsax.document_text_1,
        label: 'Transcript',
        count: transcript?.segments.length ?? 0,
      ),
      (icon: Iconsax.note_2, label: 'Notes', count: _userNotes.length),
      if (hasSources)
        (icon: Iconsax.book_1, label: 'Sources', count: drop.sources!.length),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Content Panel (shows when tab is selected)
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          height: _selectedTabIndex >= 0 ? 280 : 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: _selectedTabIndex >= 0 ? 1.0 : 0.0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              offset: _selectedTabIndex >= 0
                  ? Offset.zero
                  : const Offset(0, 0.3),
              child: _selectedTabIndex >= 0
                  ? Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          top: BorderSide(
                            color: AppColors.border.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Panel header with close
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated.withValues(
                                alpha: 0.5,
                              ),
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.border.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  tabs[_selectedTabIndex].icon,
                                  size: 14,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  tabs[_selectedTabIndex].label,
                                  style: AppTypography.labelSmall.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedTabIndex = -1),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceHover,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Iconsax.close_square,
                                      size: 16,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Panel content
                          Expanded(child: _buildTabContent(drop, transcript)),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),

        // Tab Bar
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(
              top: BorderSide(color: AppColors.border.withValues(alpha: 0.2)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: tabs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tab = entry.value;
                  final isSelected = _selectedTabIndex == index;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedTabIndex = _selectedTabIndex == index
                            ? -1
                            : index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tab.icon,
                            size: 18,
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.textTertiary,
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            Text(
                              tab.label,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (tab.count > 0 && !isSelected) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceHover,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${tab.count}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textTertiary,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(KnowledgeDrop drop, Transcript? transcript) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildChaptersContent(transcript);
      case 1:
        return _buildTranscriptContent(transcript);
      case 2:
        return _buildNotesContent();
      case 3:
        return _buildSourcesContent(drop);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildChaptersContent(Transcript? transcript) {
    final chapters = transcript?.chapters ?? [];

    if (chapters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.menu_1, size: 32, color: AppColors.textTertiary),
            const SizedBox(height: 8),
            Text(
              'No chapters available',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        final isActive = index == _currentChapterIndex;
        final isPast = index < _currentChapterIndex;

        return InkWell(
          onTap: () => _seekToChapter(index),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isActive ? AppColors.accent.withValues(alpha: 0.08) : null,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.15),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.accent
                        : isPast
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.surfaceHover,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: isPast && !isActive
                        ? Icon(
                            Iconsax.tick_circle,
                            size: 14,
                            color: AppColors.success,
                          )
                        : Text(
                            '${index + 1}',
                            style: AppTypography.labelSmall.copyWith(
                              color: isActive
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    chapter.title,
                    style: AppTypography.bodySmall.copyWith(
                      color: isActive
                          ? AppColors.accent
                          : AppColors.textPrimary,
                      fontWeight: isActive ? FontWeight.w600 : null,
                    ),
                  ),
                ),
                Text(
                  chapter.formattedStartTime,
                  style: AppTypography.labelSmall.copyWith(
                    color: isActive ? AppColors.accent : AppColors.textTertiary,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTranscriptContent(Transcript? transcript) {
    final segments = transcript?.segments ?? [];

    if (segments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.document_text_1,
              size: 32,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 8),
            Text(
              'Transcript unavailable',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _transcriptScrollController,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      itemCount: segments.length,
      itemBuilder: (context, index) {
        final segment = segments[index];
        final isActive = index == _currentTranscriptIndex;

        return GestureDetector(
          onTap: () => _seekToPosition(
            Duration(milliseconds: (segment.startTime * 1000).round()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isActive ? AppColors.accent.withValues(alpha: 0.08) : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.accent.withValues(alpha: 0.2)
                        : AppColors.surfaceHover,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatTime(segment.startTime),
                    style: AppTypography.labelSmall.copyWith(
                      color: isActive
                          ? AppColors.accent
                          : AppColors.textTertiary,
                      fontSize: 10,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    segment.text,
                    style: AppTypography.bodySmall.copyWith(
                      color: isActive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotesContent() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          // Add note input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceHover,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    style: AppTypography.bodySmall,
                    maxLines: 3,
                    minLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Add a note...',
                      hintStyle: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (value) => _addNote(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addNote,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Iconsax.add, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Notes list
          Expanded(
            child: _userNotes.isEmpty
                ? Center(
                    child: Text(
                      'No notes yet',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _userNotes.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHover,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Iconsax.quote_up,
                              size: 12,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _userNotes[index],
                                style: AppTypography.bodySmall,
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _userNotes.removeAt(index)),
                              child: Icon(
                                Iconsax.trash,
                                size: 14,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcesContent(KnowledgeDrop drop) {
    final sources = drop.sources ?? [];

    if (sources.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.book_1, size: 32, color: AppColors.textTertiary),
            const SizedBox(height: 8),
            Text(
              'No sources available',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      itemCount: sources.length,
      itemBuilder: (context, index) {
        final source = sources[index];

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Icon(
                    _getSourceIcon(source.type),
                    size: 14,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.title,
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (source.author != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        source.author!,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHover,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            source.type.label,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        if (source.url != null) ...[
                          const SizedBox(width: 6),
                          Icon(Iconsax.link_1, size: 12, color: Colors.blue),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(double seconds) {
    final mins = (seconds ~/ 60);
    final secs = (seconds % 60).round();
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildRelatedDrops(List<KnowledgeDrop> relatedDrops) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Iconsax.discover_1,
                color: AppColors.accent,
                size: 14,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Up Next',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...relatedDrops.map(
          (drop) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: GestureDetector(
              onTap: () {
                final dropId = drop.id;
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    AppRouter.goToPlayer(context, dropId);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          drop.category,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(drop.category),
                        color: _getCategoryColor(drop.category),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
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
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                drop.formattedDuration,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textTertiary,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '+${drop.xpReward} XP',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.play,
                        color: AppColors.accent,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 60),
      ],
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

  IconData _getCategoryIcon(ContentCategory category) {
    return switch (category) {
      ContentCategory.thinkingTools => Iconsax.candle,
      ContentCategory.realWorldProblems => Iconsax.chart_2,
      ContentCategory.skillUnlocks => Iconsax.lamp_on,
      ContentCategory.decisionFrameworks => Iconsax.path,
      ContentCategory.temporal => Iconsax.clock,
    };
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;

  _WaveformPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 3; i++) {
      final radius = 60 + (i * 30) + (progress * 30);
      final opacity = (1 - (i * 0.3) - progress * 0.3).clamp(0.0, 1.0);
      paint.color = color.withValues(alpha: opacity * 0.4);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) => true;
}

/// Fullscreen video player widget
class _FullscreenVideoPlayer extends ConsumerStatefulWidget {
  final KnowledgeDrop drop;
  final VoidCallback onExitFullscreen;

  const _FullscreenVideoPlayer({
    required this.drop,
    required this.onExitFullscreen,
  });

  @override
  ConsumerState<_FullscreenVideoPlayer> createState() =>
      _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState
    extends ConsumerState<_FullscreenVideoPlayer> {
  bool _showControls = true;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _hideControlsAfterDelay();
  }

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isDragging) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _hideControlsAfterDelay();
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final videoState = ref.watch(videoPlayerProvider);
    final videoService = ref.read(videoPlayerProvider.notifier);
    final controller = videoState.controller;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          widget.onExitFullscreen();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video
              if (controller != null && videoState.isInitialized)
                Center(
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                )
              else
                Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),

              // Controls overlay
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.0, 0.2, 0.8, 1.0],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        children: [
                          // Top bar
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: widget.onExitFullscreen,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.sm,
                                      ),
                                    ),
                                    child: Icon(
                                      Iconsax.arrow_left,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    widget.drop.title,
                                    style: AppTypography.headingSmall.copyWith(
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // Center play/pause button
                          GestureDetector(
                            onTap: () => videoService.togglePlayPause(),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                videoState.isPlaying
                                    ? Iconsax.pause
                                    : Iconsax.play_copy,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Bottom controls
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // Progress slider
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 4,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 14,
                                    ),
                                    activeTrackColor: AppColors.accent,
                                    inactiveTrackColor: Colors.white.withValues(
                                      alpha: 0.3,
                                    ),
                                    thumbColor: AppColors.accent,
                                    overlayColor: AppColors.accent.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                  child: Slider(
                                    value:
                                        videoState.duration.inMilliseconds > 0
                                        ? (videoState.position.inMilliseconds /
                                                  videoState
                                                      .duration
                                                      .inMilliseconds)
                                              .clamp(0.0, 1.0)
                                        : 0.0,
                                    onChanged: (value) {
                                      setState(() => _isDragging = true);
                                      final position = Duration(
                                        milliseconds:
                                            (value *
                                                    videoState
                                                        .duration
                                                        .inMilliseconds)
                                                .round(),
                                      );
                                      videoService.seek(position);
                                    },
                                    onChangeEnd: (value) {
                                      setState(() => _isDragging = false);
                                      _hideControlsAfterDelay();
                                    },
                                  ),
                                ),

                                // Time labels below slider
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(videoState.position),
                                        style: AppTypography.labelSmall
                                            .copyWith(color: Colors.white),
                                      ),
                                      Text(
                                        _formatDuration(videoState.duration),
                                        style: AppTypography.labelSmall
                                            .copyWith(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Speed and fullscreen controls
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Speed selector
                                    GestureDetector(
                                      onTap: () {
                                        final speeds = [
                                          0.5,
                                          0.75,
                                          1.0,
                                          1.25,
                                          1.5,
                                          1.75,
                                          2.0,
                                        ];
                                        final currentIndex = speeds.indexOf(
                                          videoState.playbackSpeed,
                                        );
                                        final nextIndex =
                                            (currentIndex + 1) % speeds.length;
                                        videoService.setSpeed(
                                          speeds[nextIndex],
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.5,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.sm,
                                          ),
                                        ),
                                        child: Text(
                                          '${videoState.playbackSpeed}x',
                                          style: AppTypography.labelMedium
                                              .copyWith(color: Colors.white),
                                        ),
                                      ),
                                    ),

                                    // Exit fullscreen button
                                    GestureDetector(
                                      onTap: widget.onExitFullscreen,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.5,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.sm,
                                          ),
                                        ),
                                        child: Icon(
                                          Iconsax.maximize_2,
                                          color: Colors.white,
                                          size: 20,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Video Player Sheet - Bold, Minimal, Premium
class _VideoPlayerSheet extends ConsumerStatefulWidget {
  final KnowledgeDrop drop;

  const _VideoPlayerSheet({required this.drop});

  @override
  ConsumerState<_VideoPlayerSheet> createState() => _VideoPlayerSheetState();
}

class _VideoPlayerSheetState extends ConsumerState<_VideoPlayerSheet> {
  @override
  Widget build(BuildContext context) {
    final videoState = ref.watch(videoPlayerProvider);
    final controller = videoState.controller;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Video content
          Expanded(
            child: controller != null && videoState.isInitialized
                ? GestureDetector(
                    onTap: () {
                      ref.read(videoPlayerProvider.notifier).togglePlayPause();
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Video
                        Center(
                          child: AspectRatio(
                            aspectRatio: controller.value.aspectRatio,
                            child: VideoPlayer(controller),
                          ),
                        ),

                        // Play/pause overlay
                        AnimatedOpacity(
                          opacity: videoState.isPlaying ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              videoState.isPlaying
                                  ? Iconsax.pause
                                  : Iconsax.play,
                              color: Colors.black,
                              size: 32,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: videoState.isLoading
                        ? CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Iconsax.video,
                                color: Colors.white.withValues(alpha: 0.5),
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Video unavailable',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                  ),
          ),

          // Bottom controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Progress bar
                  if (controller != null && videoState.isInitialized)
                    Column(
                      children: [
                        // Progress slider
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14,
                            ),
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            thumbColor: Colors.white,
                            overlayColor: Colors.white.withValues(alpha: 0.1),
                          ),
                          child: Slider(
                            value: videoState.progress.clamp(0.0, 1.0),
                            onChanged: (value) {
                              ref
                                  .read(videoPlayerProvider.notifier)
                                  .seekToProgress(value);
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Time display
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(
                                Duration(
                                  seconds:
                                      (videoState.progress *
                                              videoState.duration.inSeconds)
                                          .round(),
                                ),
                              ),
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            Text(
                              _formatDuration(videoState.duration),
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    widget.drop.title,
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
