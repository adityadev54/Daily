/// Represents a segment of transcript with timing information
class TranscriptSegment {
  /// Unique identifier
  final String id;

  /// The text content of this segment
  final String text;

  /// Start time in seconds
  final double startTime;

  /// End time in seconds
  final double endTime;

  /// Optional speaker label (for multi-speaker content)
  final String? speaker;

  const TranscriptSegment({
    required this.id,
    required this.text,
    required this.startTime,
    required this.endTime,
    this.speaker,
  });

  /// Duration of this segment
  Duration get duration =>
      Duration(milliseconds: ((endTime - startTime) * 1000).round());

  /// Check if a given time (in seconds) falls within this segment
  bool containsTime(double timeInSeconds) {
    return timeInSeconds >= startTime && timeInSeconds < endTime;
  }

  /// Progress within this segment (0.0 to 1.0)
  double progressAt(double timeInSeconds) {
    if (timeInSeconds <= startTime) return 0.0;
    if (timeInSeconds >= endTime) return 1.0;
    return (timeInSeconds - startTime) / (endTime - startTime);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'startTime': startTime,
    'endTime': endTime,
    'speaker': speaker,
  };

  factory TranscriptSegment.fromJson(Map<String, dynamic> json) {
    return TranscriptSegment(
      id: json['id'] as String,
      text: json['text'] as String,
      startTime: (json['startTime'] as num).toDouble(),
      endTime: (json['endTime'] as num).toDouble(),
      speaker: json['speaker'] as String?,
    );
  }
}

/// Represents a chapter/section of audio content
class AudioChapter {
  /// Chapter title
  final String title;

  /// Optional description
  final String? description;

  /// Start time in seconds
  final double startTime;

  /// End time in seconds
  final double endTime;

  const AudioChapter({
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
  });

  /// Duration of this chapter
  Duration get duration =>
      Duration(milliseconds: ((endTime - startTime) * 1000).round());

  /// Formatted start time (e.g., "2:30")
  String get formattedStartTime {
    final minutes = (startTime ~/ 60);
    final seconds = (startTime % 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Check if a given time (in seconds) falls within this chapter
  bool containsTime(double timeInSeconds) {
    return timeInSeconds >= startTime && timeInSeconds < endTime;
  }

  /// Progress within this chapter (0.0 to 1.0)
  double progressAt(double timeInSeconds) {
    if (timeInSeconds <= startTime) return 0.0;
    if (timeInSeconds >= endTime) return 1.0;
    return (timeInSeconds - startTime) / (endTime - startTime);
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'startTime': startTime,
    'endTime': endTime,
  };

  factory AudioChapter.fromJson(Map<String, dynamic> json) {
    return AudioChapter(
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: (json['startTime'] as num).toDouble(),
      endTime: (json['endTime'] as num).toDouble(),
    );
  }
}

/// Full transcript with all segments
class Transcript {
  final List<TranscriptSegment> segments;
  final List<AudioChapter> chapters;

  const Transcript({required this.segments, this.chapters = const []});

  /// Get the segment at a given time
  TranscriptSegment? segmentAt(double timeInSeconds) {
    for (final segment in segments) {
      if (segment.containsTime(timeInSeconds)) {
        return segment;
      }
    }
    return null;
  }

  /// Get the chapter at a given time
  AudioChapter? chapterAt(double timeInSeconds) {
    for (final chapter in chapters) {
      if (chapter.containsTime(timeInSeconds)) {
        return chapter;
      }
    }
    return null;
  }

  /// Get index of segment at a given time
  int segmentIndexAt(double timeInSeconds) {
    for (int i = 0; i < segments.length; i++) {
      if (segments[i].containsTime(timeInSeconds)) {
        return i;
      }
    }
    return -1;
  }

  /// Get index of chapter at a given time
  int chapterIndexAt(double timeInSeconds) {
    for (int i = 0; i < chapters.length; i++) {
      if (chapters[i].containsTime(timeInSeconds)) {
        return i;
      }
    }
    return -1;
  }

  /// Full text of the transcript
  String get fullText => segments.map((s) => s.text).join(' ');

  /// Total duration based on last segment
  double get totalDuration => segments.isNotEmpty ? segments.last.endTime : 0.0;

  Map<String, dynamic> toJson() => {
    'segments': segments.map((s) => s.toJson()).toList(),
    'chapters': chapters.map((c) => c.toJson()).toList(),
  };

  factory Transcript.fromJson(Map<String, dynamic> json) {
    return Transcript(
      segments: (json['segments'] as List)
          .map((s) => TranscriptSegment.fromJson(s as Map<String, dynamic>))
          .toList(),
      chapters: json['chapters'] != null
          ? (json['chapters'] as List)
                .map((c) => AudioChapter.fromJson(c as Map<String, dynamic>))
                .toList()
          : [],
    );
  }

  /// Empty transcript
  static const empty = Transcript(segments: [], chapters: []);
}
