import 'enums.dart';
import 'transcript.dart';

/// Represents a chapter marker in the content
class ContentChapter {
  final int number;
  final double start;
  final String title;
  final String? textPreview;

  const ContentChapter({
    required this.number,
    required this.start,
    required this.title,
    this.textPreview,
  });

  String get startFormatted {
    final minutes = start ~/ 60;
    final seconds = (start % 60).toInt();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  factory ContentChapter.fromJson(Map<String, dynamic> json) {
    return ContentChapter(
      number: json['number'] as int,
      start: (json['start'] as num).toDouble(),
      title: json['title'] as String,
      textPreview: json['text_preview'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'start': start,
    'title': title,
    'text_preview': textPreview,
  };
}

/// Represents a knowledge drop - the core content unit in Spera
/// Can be audio or video, always short, surgical, high-impact
class KnowledgeDrop {
  final String id;
  final String title;
  final String description;
  final ContentType contentType;
  final ContentCategory category;
  final ContentDifficulty difficulty;
  final ContentStatus status;

  /// Duration in seconds
  final int durationSeconds;

  /// URL to the content (audio/video)
  final String contentUrl;

  /// Optional thumbnail for video content
  final String? thumbnailUrl;

  /// Tags for filtering and matching
  final List<String> tags;

  /// Skills this drop develops
  final List<String> skills;

  /// Use cases this content applies to
  final List<String> useCases;

  /// XP awarded for completing this drop
  final int xpReward;

  /// When this content was created
  final DateTime createdAt;

  /// When this content expires (for temporal content)
  final DateTime? expiresAt;

  /// Required rank to access this content
  final UserRank? requiredRank;

  /// Related/prerequisite drops
  final List<String>? prerequisiteIds;
  final List<String>? relatedIds;

  /// Sources used to create this content (for NotebookLLM attribution)
  final List<ContentSource>? sources;

  /// Full transcript text
  final String? transcript;

  /// Timestamped transcript segments
  final List<TranscriptSegment>? transcriptSegments;

  /// Chapter markers
  final List<ContentChapter>? chapters;

  const KnowledgeDrop({
    required this.id,
    required this.title,
    required this.description,
    required this.contentType,
    required this.category,
    required this.difficulty,
    required this.status,
    required this.durationSeconds,
    required this.contentUrl,
    this.thumbnailUrl,
    required this.tags,
    required this.skills,
    required this.useCases,
    required this.xpReward,
    required this.createdAt,
    this.expiresAt,
    this.requiredRank,
    this.prerequisiteIds,
    this.relatedIds,
    this.sources,
    this.transcript,
    this.transcriptSegments,
    this.chapters,
  });

  /// Formatted duration string (e.g., "3:45")
  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Whether this content is temporal (has expiry)
  bool get isTemporal => expiresAt != null;

  /// Whether this content has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Time remaining until expiry
  Duration? get timeUntilExpiry {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Whether user can access based on rank
  bool canAccess(UserRank userRank) {
    if (requiredRank == null) return true;
    return userRank.index >= requiredRank!.index;
  }

  /// Copy with modifications
  KnowledgeDrop copyWith({
    String? id,
    String? title,
    String? description,
    ContentType? contentType,
    ContentCategory? category,
    ContentDifficulty? difficulty,
    ContentStatus? status,
    int? durationSeconds,
    String? contentUrl,
    String? thumbnailUrl,
    List<String>? tags,
    List<String>? skills,
    List<String>? useCases,
    int? xpReward,
    DateTime? createdAt,
    DateTime? expiresAt,
    UserRank? requiredRank,
    List<String>? prerequisiteIds,
    List<String>? relatedIds,
    List<ContentSource>? sources,
    String? transcript,
    List<TranscriptSegment>? transcriptSegments,
    List<ContentChapter>? chapters,
  }) {
    return KnowledgeDrop(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      contentType: contentType ?? this.contentType,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      contentUrl: contentUrl ?? this.contentUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      tags: tags ?? this.tags,
      skills: skills ?? this.skills,
      useCases: useCases ?? this.useCases,
      xpReward: xpReward ?? this.xpReward,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      requiredRank: requiredRank ?? this.requiredRank,
      prerequisiteIds: prerequisiteIds ?? this.prerequisiteIds,
      relatedIds: relatedIds ?? this.relatedIds,
      sources: sources ?? this.sources,
      transcript: transcript ?? this.transcript,
      transcriptSegments: transcriptSegments ?? this.transcriptSegments,
      chapters: chapters ?? this.chapters,
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'contentType': contentType.name,
      'category': category.name,
      'difficulty': difficulty.name,
      'status': status.name,
      'durationSeconds': durationSeconds,
      'contentUrl': contentUrl,
      'thumbnailUrl': thumbnailUrl,
      'tags': tags,
      'skills': skills,
      'useCases': useCases,
      'xpReward': xpReward,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'requiredRank': requiredRank?.name,
      'prerequisiteIds': prerequisiteIds,
      'relatedIds': relatedIds,
    };
  }

  /// From JSON
  factory KnowledgeDrop.fromJson(Map<String, dynamic> json) {
    return KnowledgeDrop(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      contentType: ContentType.values.byName(json['contentType'] as String),
      category: ContentCategory.values.byName(json['category'] as String),
      difficulty: ContentDifficulty.values.byName(json['difficulty'] as String),
      status: ContentStatus.values.byName(json['status'] as String),
      durationSeconds: json['durationSeconds'] as int,
      contentUrl: json['contentUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      tags: List<String>.from(json['tags'] as List),
      skills: List<String>.from(json['skills'] as List),
      useCases: List<String>.from(json['useCases'] as List),
      xpReward: json['xpReward'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      requiredRank: json['requiredRank'] != null
          ? UserRank.values.byName(json['requiredRank'] as String)
          : null,
      prerequisiteIds: json['prerequisiteIds'] != null
          ? List<String>.from(json['prerequisiteIds'] as List)
          : null,
      relatedIds: json['relatedIds'] != null
          ? List<String>.from(json['relatedIds'] as List)
          : null,
    );
  }
}
