/// User rank in Spera's progression system
/// Professional, not childish - based on mastery
enum UserRank {
  observer('Observer', 'Beginning your journey'),
  analyst('Analyst', 'Developing analytical thinking'),
  strategist('Strategist', 'Mastering strategic decision-making'),
  architect('Architect', 'Architecting complex solutions');

  const UserRank(this.title, this.description);

  final String title;
  final String description;

  /// XP threshold to reach this rank
  int get xpThreshold {
    return switch (this) {
      UserRank.observer => 0,
      UserRank.analyst => 1000,
      UserRank.strategist => 5000,
      UserRank.architect => 15000,
    };
  }

  /// Next rank in progression (null if at max)
  UserRank? get nextRank {
    return switch (this) {
      UserRank.observer => UserRank.analyst,
      UserRank.analyst => UserRank.strategist,
      UserRank.strategist => UserRank.architect,
      UserRank.architect => null,
    };
  }

  /// Get rank from XP amount
  static UserRank fromXp(int xp) {
    if (xp >= UserRank.architect.xpThreshold) return UserRank.architect;
    if (xp >= UserRank.strategist.xpThreshold) return UserRank.strategist;
    if (xp >= UserRank.analyst.xpThreshold) return UserRank.analyst;
    return UserRank.observer;
  }
}

/// Content type for knowledge drops
enum ContentType {
  audio('Audio', 'Listen'),
  video('Video', 'Watch');

  const ContentType(this.label, this.action);

  final String label;
  final String action;
}

/// Content category - each serves the core mission
enum ContentCategory {
  thinkingTools('Thinking Tools', 'Frameworks for better thinking'),
  realWorldProblems('Real-World Problems', 'Case breakdowns and solutions'),
  skillUnlocks('Skill Unlocks', 'Execution guidance'),
  decisionFrameworks('Decision Frameworks', 'Make better choices'),
  temporal('Limited Time', 'Available for a limited period');

  const ContentCategory(this.title, this.description);

  final String title;
  final String description;
}

/// Content difficulty level
enum ContentDifficulty {
  foundational('Foundational', 1),
  intermediate('Intermediate', 2),
  advanced('Advanced', 3),
  expert('Expert', 4);

  const ContentDifficulty(this.label, this.level);

  final String label;
  final int level;

  /// XP multiplier for this difficulty
  double get xpMultiplier {
    return switch (this) {
      ContentDifficulty.foundational => 1.0,
      ContentDifficulty.intermediate => 1.5,
      ContentDifficulty.advanced => 2.0,
      ContentDifficulty.expert => 3.0,
    };
  }
}

/// Content lifecycle status
enum ContentStatus {
  active('Active', 'Currently available'),
  comingSoon('Coming Soon', 'In production, available soon'),
  archived('Archived', 'Hidden, retrievable by request'),
  vaulted('Vaulted', 'Permanently removed');

  const ContentStatus(this.label, this.description);

  final String label;
  final String description;
}

/// Knowledge request status
enum RequestStatus {
  pending('Pending', 'Request received'),
  processing('Processing', 'Being generated'),
  matched('Matched', 'Found existing content'),
  delivered('Delivered', 'Available in your feed'),
  failed('Failed', 'Could not fulfill request');

  const RequestStatus(this.label, this.description);

  final String label;
  final String description;
}

/// Feed section types for home screen
enum FeedSection {
  newDrops('New Drops', 'Fresh knowledge just deployed'),
  thinkingTools('Thinking Tools', 'Frameworks for better thinking'),
  realWorldProblems('Real-World Problems', 'Case studies and solutions'),
  skillUnlocks('Skill Unlocks', 'Practical execution guidance'),
  temporal('Limited Time', 'Expiring soon');

  const FeedSection(this.title, this.subtitle);

  final String title;
  final String subtitle;
}

/// Source type for content attribution
enum SourceType {
  book('Book'),
  article('Article'),
  paper('Research Paper'),
  video('Video'),
  podcast('Podcast'),
  website('Website'),
  course('Course'),
  other('Other');

  const SourceType(this.label);

  final String label;
}

/// Content source - for NotebookLLM attribution
class ContentSource {
  final String title;
  final String? author;
  final SourceType type;
  final String? url;
  final String? description;

  const ContentSource({
    required this.title,
    this.author,
    required this.type,
    this.url,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'author': author,
    'type': type.name,
    'url': url,
    'description': description,
  };

  factory ContentSource.fromJson(Map<String, dynamic> json) => ContentSource(
    title: json['title'] as String,
    author: json['author'] as String?,
    type: SourceType.values.byName(json['type'] as String),
    url: json['url'] as String?,
    description: json['description'] as String?,
  );
}
