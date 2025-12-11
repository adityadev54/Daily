import 'enums.dart';

/// Represents a user in Spera
/// Tracks progression, requests, and unlocked content
class User {
  final String id;
  final String displayName;
  final String? avatarUrl;

  /// Total XP earned (Intelligence XP)
  final int xp;

  /// Request tokens available
  final int requestTokens;

  /// IDs of completed knowledge drops
  final List<String> completedDropIds;

  /// IDs of drops currently in progress
  final List<String> inProgressDropIds;

  /// IDs of bookmarked drops
  final List<String> bookmarkedDropIds;

  /// When user joined
  final DateTime createdAt;

  /// Last active
  final DateTime lastActiveAt;

  /// Streak information
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastStreakDate;

  const User({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.xp,
    required this.requestTokens,
    required this.completedDropIds,
    required this.inProgressDropIds,
    required this.bookmarkedDropIds,
    required this.createdAt,
    required this.lastActiveAt,
    required this.currentStreak,
    required this.longestStreak,
    this.lastStreakDate,
  });

  /// Current rank based on XP
  UserRank get rank => UserRank.fromXp(xp);

  /// XP needed to reach next rank
  int? get xpToNextRank {
    final next = rank.nextRank;
    if (next == null) return null;
    return next.xpThreshold - xp;
  }

  /// Progress percentage to next rank (0.0 - 1.0)
  double get progressToNextRank {
    final next = rank.nextRank;
    if (next == null) return 1.0;

    final currentThreshold = rank.xpThreshold;
    final nextThreshold = next.xpThreshold;
    final xpInCurrentRank = xp - currentThreshold;
    final xpNeededForNext = nextThreshold - currentThreshold;

    return xpInCurrentRank / xpNeededForNext;
  }

  /// Total drops completed
  int get totalCompleted => completedDropIds.length;

  /// Whether user has completed a specific drop
  bool hasCompleted(String dropId) => completedDropIds.contains(dropId);

  /// Whether a drop is in progress
  bool isInProgress(String dropId) => inProgressDropIds.contains(dropId);

  /// Whether a drop is bookmarked
  bool isBookmarked(String dropId) => bookmarkedDropIds.contains(dropId);

  /// Copy with modifications
  User copyWith({
    String? id,
    String? displayName,
    String? avatarUrl,
    int? xp,
    int? requestTokens,
    List<String>? completedDropIds,
    List<String>? inProgressDropIds,
    List<String>? bookmarkedDropIds,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastStreakDate,
  }) {
    return User(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      xp: xp ?? this.xp,
      requestTokens: requestTokens ?? this.requestTokens,
      completedDropIds: completedDropIds ?? this.completedDropIds,
      inProgressDropIds: inProgressDropIds ?? this.inProgressDropIds,
      bookmarkedDropIds: bookmarkedDropIds ?? this.bookmarkedDropIds,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastStreakDate: lastStreakDate ?? this.lastStreakDate,
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'xp': xp,
      'requestTokens': requestTokens,
      'completedDropIds': completedDropIds,
      'inProgressDropIds': inProgressDropIds,
      'bookmarkedDropIds': bookmarkedDropIds,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastStreakDate': lastStreakDate?.toIso8601String(),
    };
  }

  /// From JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      xp: json['xp'] as int,
      requestTokens: json['requestTokens'] as int,
      completedDropIds: List<String>.from(json['completedDropIds'] as List),
      inProgressDropIds: List<String>.from(json['inProgressDropIds'] as List),
      bookmarkedDropIds: List<String>.from(json['bookmarkedDropIds'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
      currentStreak: json['currentStreak'] as int,
      longestStreak: json['longestStreak'] as int,
      lastStreakDate: json['lastStreakDate'] != null
          ? DateTime.parse(json['lastStreakDate'] as String)
          : null,
    );
  }

  /// Create a new user with default values
  factory User.create({
    required String id,
    required String displayName,
    String? avatarUrl,
  }) {
    return User(
      id: id,
      displayName: displayName,
      avatarUrl: avatarUrl,
      xp: 0,
      requestTokens: 3, // Start with 3 request tokens
      completedDropIds: [],
      inProgressDropIds: [],
      bookmarkedDropIds: [],
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
      currentStreak: 0,
      longestStreak: 0,
    );
  }
}
