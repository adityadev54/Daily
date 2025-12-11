import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../models/models.dart';
import '../../shared/widgets/mini_player.dart';

/// Global video player state
class VideoPlayerState {
  final KnowledgeDrop? currentDrop;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double playbackSpeed;
  final bool isLoading;
  final bool isInitialized;
  final String? error;
  final VideoPlayerController? controller;

  const VideoPlayerState({
    this.currentDrop,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playbackSpeed = 1.0,
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
    this.controller,
  });

  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  VideoPlayerState copyWith({
    KnowledgeDrop? currentDrop,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? playbackSpeed,
    bool? isLoading,
    bool? isInitialized,
    String? error,
    VideoPlayerController? controller,
    bool clearController = false,
  }) {
    return VideoPlayerState(
      currentDrop: currentDrop ?? this.currentDrop,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
      controller: clearController ? null : (controller ?? this.controller),
    );
  }
}

/// Global video player service that persists across screens
class VideoPlayerService extends Notifier<VideoPlayerState> {
  @override
  VideoPlayerState build() {
    ref.onDispose(() {
      state.controller?.dispose();
    });
    return const VideoPlayerState();
  }

  /// Load and play a video drop
  Future<void> playDrop(KnowledgeDrop drop) async {
    // If same drop, just toggle play/pause
    if (state.currentDrop?.id == drop.id && state.isInitialized) {
      togglePlayPause();
      return;
    }

    // Dispose old controller
    state.controller?.dispose();

    state = state.copyWith(
      currentDrop: drop,
      isLoading: true,
      isInitialized: false,
      error: null,
      position: Duration.zero,
      clearController: true,
    );

    // Update mini player
    ref.read(miniPlayerProvider.notifier).setDrop(drop);

    final url = drop.contentUrl;

    // Check if URL is valid video
    if (_isValidVideoUrl(url)) {
      try {
        final controller = VideoPlayerController.networkUrl(Uri.parse(url));
        await controller.initialize();
        await controller.setPlaybackSpeed(state.playbackSpeed);

        // Setup listener
        controller.addListener(() {
          if (controller.value.isInitialized) {
            final newPosition = controller.value.position;
            final newDuration = controller.value.duration;
            final isPlaying = controller.value.isPlaying;

            state = state.copyWith(
              position: newPosition,
              duration: newDuration,
              isPlaying: isPlaying,
            );

            // Sync with mini player
            ref.read(miniPlayerProvider.notifier).setProgress(state.progress);

            // Check for completion
            if (newPosition >= newDuration && newDuration > Duration.zero) {
              state = state.copyWith(isPlaying: false);
            }
          }
        });

        state = state.copyWith(
          controller: controller,
          isLoading: false,
          isInitialized: true,
          duration: controller.value.duration,
        );

        await controller.play();
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load video: $e',
        );
      }
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'Demo mode - video not available',
        duration: Duration(seconds: drop.durationSeconds),
      );
    }
  }

  bool _isValidVideoUrl(String url) {
    final videoExtensions = ['.mp4', '.mov', '.webm', '.mkv', '.avi', '.m4v'];
    final isVideoFile = videoExtensions.any(
      (ext) => url.toLowerCase().contains(ext),
    );
    final isNotExample = !url.contains('example.com');
    return isVideoFile && isNotExample;
  }

  void togglePlayPause() {
    final controller = state.controller;
    if (controller == null || !state.isInitialized) return;

    if (state.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
  }

  void play() {
    state.controller?.play();
  }

  void pause() {
    state.controller?.pause();
  }

  Future<void> seek(Duration position) async {
    await state.controller?.seekTo(position);
  }

  Future<void> seekToProgress(double progress) async {
    final targetPosition = Duration(
      milliseconds: (progress * state.duration.inMilliseconds).round(),
    );
    await seek(targetPosition);
  }

  Future<void> setSpeed(double speed) async {
    state = state.copyWith(playbackSpeed: speed);
    await state.controller?.setPlaybackSpeed(speed);
  }

  void skip(Duration amount) {
    final newPosition = state.position + amount;
    final clampedPosition = Duration(
      milliseconds: newPosition.inMilliseconds.clamp(
        0,
        state.duration.inMilliseconds,
      ),
    );
    seek(clampedPosition);
  }

  void stop() {
    state.controller?.pause();
    state.controller?.seekTo(Duration.zero);
    state = state.copyWith(isPlaying: false, position: Duration.zero);
  }
}

/// Global video player provider
final videoPlayerProvider =
    NotifierProvider<VideoPlayerService, VideoPlayerState>(
      VideoPlayerService.new,
    );
