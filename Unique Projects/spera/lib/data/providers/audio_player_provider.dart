import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../models/models.dart';
import '../../shared/widgets/mini_player.dart';

/// Global audio player state
class AudioPlayerState {
  final KnowledgeDrop? currentDrop;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double playbackSpeed;
  final bool isLoading;
  final String? error;

  const AudioPlayerState({
    this.currentDrop,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playbackSpeed = 1.0,
    this.isLoading = false,
    this.error,
  });

  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  AudioPlayerState copyWith({
    KnowledgeDrop? currentDrop,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? playbackSpeed,
    bool? isLoading,
    String? error,
  }) {
    return AudioPlayerState(
      currentDrop: currentDrop ?? this.currentDrop,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Global audio player service that persists across screens
class AudioPlayerService extends Notifier<AudioPlayerState> {
  late AudioPlayer _player;

  @override
  AudioPlayerState build() {
    _player = AudioPlayer();
    _setupListeners();

    // Dispose player when provider is disposed
    ref.onDispose(() {
      _player.dispose();
    });

    return const AudioPlayerState();
  }

  AudioPlayer get player => _player;

  void _setupListeners() {
    _player.positionStream.listen((position) {
      state = state.copyWith(position: position);
      // Sync with mini player
      ref.read(miniPlayerProvider.notifier).setProgress(state.progress);
    });

    _player.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });

    _player.playerStateStream.listen((playerState) {
      state = state.copyWith(isPlaying: playerState.playing);
      // Sync with mini player
      if (state.currentDrop != null) {
        if (playerState.playing) {
          // Keep mini player in sync
        }
      }

      if (playerState.processingState == ProcessingState.completed) {
        state = state.copyWith(isPlaying: false);
      }
    });
  }

  /// Load and play a drop
  Future<void> playDrop(KnowledgeDrop drop) async {
    // If same drop, just toggle play/pause
    if (state.currentDrop?.id == drop.id) {
      togglePlayPause();
      return;
    }

    state = state.copyWith(
      currentDrop: drop,
      isLoading: true,
      error: null,
      position: Duration.zero,
    );

    // Update mini player
    ref.read(miniPlayerProvider.notifier).setDrop(drop);

    final url = drop.contentUrl;

    // Check if URL is playable
    if (_isValidAudioUrl(url)) {
      try {
        await _player.setUrl(url);
        await _player.setSpeed(state.playbackSpeed);
        state = state.copyWith(isLoading: false);
        await _player.play();
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          error: 'Demo mode - simulated playback',
        );
        // Start simulated playback
        _simulatePlayback(drop);
      }
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'Demo mode - simulated playback',
        duration: Duration(seconds: drop.durationSeconds),
      );
      // Start simulated playback for demo URLs
      _simulatePlayback(drop);
    }
  }

  bool _isValidAudioUrl(String url) {
    final audioExtensions = ['.mp3', '.wav', '.m4a', '.aac', '.ogg', '.flac'];
    final isAudioFile = audioExtensions.any(
      (ext) => url.toLowerCase().contains(ext),
    );
    final isNotExample = !url.contains('example.com');
    final isNotNotebook = !url.contains('notebooklm.google.com');
    return isAudioFile && isNotExample && isNotNotebook;
  }

  /// Simulated playback for demo/invalid URLs
  Future<void> _simulatePlayback(KnowledgeDrop drop) async {
    state = state.copyWith(
      isPlaying: true,
      duration: Duration(seconds: drop.durationSeconds),
    );

    while (state.isPlaying && state.position < state.duration) {
      await Future.delayed(
        Duration(milliseconds: (100 / state.playbackSpeed).round()),
      );
      if (state.isPlaying) {
        final newPosition =
            state.position +
            Duration(milliseconds: (100 * state.playbackSpeed).round());
        state = state.copyWith(position: newPosition);
        ref.read(miniPlayerProvider.notifier).setProgress(state.progress);

        if (newPosition >= state.duration) {
          state = state.copyWith(isPlaying: false);
          break;
        }
      }
    }
  }

  void togglePlayPause() {
    if (state.error != null) {
      // Simulated playback
      if (state.isPlaying) {
        state = state.copyWith(isPlaying: false);
      } else {
        state = state.copyWith(isPlaying: true);
        if (state.currentDrop != null) {
          _simulatePlayback(state.currentDrop!);
        }
      }
    } else {
      // Real audio
      if (state.isPlaying) {
        _player.pause();
      } else {
        _player.play();
      }
    }
  }

  void play() {
    if (state.error != null && state.currentDrop != null) {
      state = state.copyWith(isPlaying: true);
      _simulatePlayback(state.currentDrop!);
    } else {
      _player.play();
    }
  }

  void pause() {
    if (state.error != null) {
      state = state.copyWith(isPlaying: false);
    } else {
      _player.pause();
    }
  }

  Future<void> seek(Duration position) async {
    if (state.error != null) {
      // Simulated - just update position
      state = state.copyWith(position: position);
      ref.read(miniPlayerProvider.notifier).setProgress(state.progress);
    } else {
      await _player.seek(position);
    }
  }

  Future<void> seekToProgress(double progress) async {
    final targetPosition = Duration(
      milliseconds: (progress * state.duration.inMilliseconds).round(),
    );
    await seek(targetPosition);
  }

  Future<void> setSpeed(double speed) async {
    state = state.copyWith(playbackSpeed: speed);
    if (state.error == null) {
      await _player.setSpeed(speed);
    }
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
    _player.stop();
    state = state.copyWith(isPlaying: false, position: Duration.zero);
  }
}

/// Global audio player provider
final audioPlayerProvider =
    NotifierProvider<AudioPlayerService, AudioPlayerState>(
      AudioPlayerService.new,
    );
