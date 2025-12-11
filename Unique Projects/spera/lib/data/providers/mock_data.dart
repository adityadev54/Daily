import '../models/models.dart';

/// Mock data for development and testing
/// This simulates what the backend would provide
class MockData {
  MockData._();

  /// Current user
  static final User currentUser = User(
    id: 'user_001',
    displayName: 'Aditya',
    xp: 2450,
    requestTokens: 5,
    completedDropIds: ['drop_001', 'drop_002', 'drop_003'],
    inProgressDropIds: ['drop_004'],
    bookmarkedDropIds: ['drop_005', 'drop_006'],
    createdAt: DateTime.now().subtract(const Duration(days: 45)),
    lastActiveAt: DateTime.now(),
    currentStreak: 7,
    longestStreak: 14,
    lastStreakDate: DateTime.now(),
  );

  /// Sample knowledge drops
  static final List<KnowledgeDrop> knowledgeDrops = [
    // Thinking Tools
    KnowledgeDrop(
      id: 'drop_001',
      title: 'First Principles Thinking',
      description:
          'Learn to break down complex problems to their fundamental truths and reason up from there. This mental model, used by innovators like Elon Musk, helps you escape conventional thinking traps.',
      contentType: ContentType.audio,
      category: ContentCategory.thinkingTools,
      difficulty: ContentDifficulty.foundational,
      status: ContentStatus.active,
      durationSeconds: 846,
      contentUrl:
          'https://archive.org/download/rethinking-rockets-cost-65-million-dollars/Rethinking%20Rockets%20Cost%2065%20Million%20Dollars.m4a',
      tags: ['thinking', 'problem-solving', 'fundamentals'],
      skills: ['Critical Thinking', 'Analysis'],
      useCases: ['Product decisions', 'Career choices', 'System design'],
      xpReward: 50,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    KnowledgeDrop(
      id: 'drop_002',
      title: 'Inversion Mental Model',
      description:
          'Instead of asking how to succeed, ask what would guarantee failure—then avoid it. Charlie Munger\'s favorite technique for bulletproofing decisions and uncovering blind spots.',
      contentType: ContentType.audio,
      category: ContentCategory.thinkingTools,
      difficulty: ContentDifficulty.intermediate,
      status: ContentStatus.active,
      durationSeconds: 652, // 10:52
      contentUrl:
          'https://archive.org/download/charlie-munger-power-of-inversion-thinking/Charlie%20Munger%20Power%20of%20Inversion%20Thinking.m4a',
      tags: ['mental-models', 'risk', 'strategy'],
      skills: ['Strategic Thinking', 'Risk Assessment'],
      useCases: ['Business planning', 'Investment decisions'],
      xpReward: 75,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    KnowledgeDrop(
      id: 'drop_003',
      title: 'Second-Order Thinking',
      description:
          'Most people only consider first-order consequences. Learn to think two, three, even four steps ahead. This separates strategic thinkers from everyone else.',
      contentType: ContentType.video,
      category: ContentCategory.thinkingTools,
      difficulty: ContentDifficulty.intermediate,
      status: ContentStatus.active,
      durationSeconds: 420,
      contentUrl:
          'https://archive.org/download/slaying-ai-inefficiency/Slaying%20AI%20Inefficiency.mp4',
      thumbnailUrl: 'https://picsum.photos/seed/thinking/400/225',
      tags: ['thinking', 'consequences', 'strategy'],
      skills: ['Long-term Thinking', 'Consequence Analysis'],
      useCases: ['Policy decisions', 'System changes', 'Hiring'],
      xpReward: 100,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),

    // Real-World Problems
    KnowledgeDrop(
      id: 'drop_004',
      title: 'AI Exponential Growth & Global Policy Race',
      description:
          'AI capabilities are doubling every 6 months. Understand what this exponential curve means for your career, your industry, and how governments worldwide are scrambling to respond.',
      contentType: ContentType.audio,
      category: ContentCategory.realWorldProblems,
      difficulty: ContentDifficulty.advanced,
      status: ContentStatus.active,
      durationSeconds: 849,
      contentUrl:
          'https://archive.org/download/ai-exponential-growth-and-global-policy-race/AI%20Exponential%20Growth%20and%20Global%20Policy%20Race.m4a',
      tags: ['AI', 'policy', 'technology', 'global'],
      skills: ['Tech Literacy', 'Strategic Thinking'],
      useCases: ['Tech decisions', 'Career planning', 'Policy analysis'],
      xpReward: 80,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      sources: [
        ContentSource(
          title: 'The AI Revolution: Our Immortality or Extinction',
          author: 'Tim Urban',
          type: SourceType.article,
          url:
              'https://waitbutwhy.com/2015/01/artificial-intelligence-revolution-1.html',
          description: 'Deep dive into AI\'s exponential trajectory',
        ),
        ContentSource(
          title: 'Governing AI: A Blueprint for the Future',
          author: 'OECD',
          type: SourceType.paper,
          description: 'International AI governance frameworks',
        ),
        ContentSource(
          title: 'State of AI Report 2024',
          author: 'Nathan Benaich & Air Street Capital',
          type: SourceType.paper,
          url: 'https://www.stateof.ai/',
          description: 'Annual comprehensive AI progress report',
        ),
      ],
    ),
    KnowledgeDrop(
      id: 'drop_005',
      title: 'Managing Up: The Hidden Skill',
      description:
          'Your relationship with your manager is the single biggest factor in your career trajectory. Learn the art of managing up—aligning priorities, building trust, and becoming indispensable.',
      contentType: ContentType.audio,
      category: ContentCategory.realWorldProblems,
      difficulty: ContentDifficulty.intermediate,
      status: ContentStatus.comingSoon,
      durationSeconds: 290,
      contentUrl: 'https://example.com/audio/managing-up.mp3',
      tags: ['leadership', 'workplace', 'communication'],
      skills: ['Leadership', 'Communication'],
      useCases: ['Performance reviews', 'Getting resources', 'Career growth'],
      xpReward: 75,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),

    // Skill Unlocks
    KnowledgeDrop(
      id: 'drop_006',
      title: 'Deep Work Protocol',
      description:
          'Cal Newport\'s framework for achieving flow state on demand. Learn to structure your day, eliminate distractions, and produce work that matters in half the time.',
      contentType: ContentType.audio,
      category: ContentCategory.skillUnlocks,
      difficulty: ContentDifficulty.foundational,
      status: ContentStatus.comingSoon,
      durationSeconds: 356,
      contentUrl: 'https://example.com/audio/deep-work.mp3',
      tags: ['productivity', 'focus', 'habits'],
      skills: ['Focus', 'Productivity'],
      useCases: ['Complex projects', 'Learning', 'Creative work'],
      xpReward: 60,
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    KnowledgeDrop(
      id: 'drop_007',
      title: 'The Art of Asking Questions',
      description:
          'Great questions unlock great answers. Master the Socratic method, learn interview techniques from top journalists, and discover how the right question can change everything.',
      contentType: ContentType.video,
      category: ContentCategory.skillUnlocks,
      difficulty: ContentDifficulty.intermediate,
      status: ContentStatus.active,
      durationSeconds: 445,
      contentUrl:
          'https://archive.org/download/art-of-effective-questions/Art%20of%20Effective%20Questions.mp4',
      thumbnailUrl: 'https://picsum.photos/seed/questions/400/225',
      tags: ['communication', 'discovery', 'interviews'],
      skills: ['Communication', 'Critical Thinking'],
      useCases: ['Interviews', 'Research', 'Problem diagnosis'],
      xpReward: 90,
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      sources: [
        ContentSource(
          title: 'A More Beautiful Question',
          author: 'Warren Berger',
          type: SourceType.book,
          description:
              'The power of inquiry to spark breakthrough ideas and fuel change.',
        ),
        ContentSource(
          title: 'The Art of Powerful Questions',
          author: 'Eric Vogt, Juanita Brown, David Isaacs',
          type: SourceType.paper,
          url:
              'https://umanitoba.ca/faculties/health_sciences/medicine/education/media/art_of_powerful_questions.pdf',
          description:
              'Catalyzing insight, innovation, and action through strategic questioning.',
        ),
        ContentSource(
          title: 'Socratic Questioning',
          author: 'Stanford Encyclopedia of Philosophy',
          type: SourceType.article,
          url: 'https://plato.stanford.edu/entries/socrates/',
          description:
              'The foundational method of philosophical inquiry through questions.',
        ),
      ],
    ),

    // Decision Frameworks
    KnowledgeDrop(
      id: 'drop_008',
      title: 'The Eisenhower Matrix',
      description:
          'Dwight Eisenhower ran WWII and the presidency with this simple 2x2 matrix. Learn to ruthlessly prioritize by urgency vs. importance—and finally escape the tyranny of the urgent.',
      contentType: ContentType.audio,
      category: ContentCategory.decisionFrameworks,
      difficulty: ContentDifficulty.foundational,
      status: ContentStatus.comingSoon,
      durationSeconds: 198,
      contentUrl: 'https://example.com/audio/eisenhower.mp3',
      tags: ['prioritization', 'time-management', 'decisions'],
      skills: ['Prioritization', 'Decision Making'],
      useCases: ['Daily planning', 'Project management', 'Life decisions'],
      xpReward: 45,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
    KnowledgeDrop(
      id: 'drop_009',
      title: 'Reversible vs Irreversible Decisions',
      description:
          'Jeff Bezos\' Type 1 vs Type 2 decision framework. Know when to move fast and break things, and when to slow down and deliberate. Most people get this backwards.',
      contentType: ContentType.audio,
      category: ContentCategory.decisionFrameworks,
      difficulty: ContentDifficulty.intermediate,
      status: ContentStatus.active,
      durationSeconds: 813,
      contentUrl:
          'https://archive.org/download/how-to-master-irreversible-life-decisions/How%20to%20Master%20Irreversible%20Life%20Decisions.m4a',
      tags: ['decisions', 'speed', 'risk'],
      skills: ['Decision Making', 'Risk Assessment'],
      useCases: ['Business decisions', 'Career moves', 'Investments'],
      xpReward: 70,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      sources: [
        ContentSource(
          title: '2016 Letter to Shareholders',
          author: 'Jeff Bezos',
          type: SourceType.article,
          description: 'Original Type 1 vs Type 2 decision framework',
        ),
        ContentSource(
          title: 'Thinking in Bets',
          author: 'Annie Duke',
          type: SourceType.book,
          description: 'Decision making under uncertainty',
        ),
        ContentSource(
          title: 'The Psychology of Decision Making',
          author: 'Harvard Business Review',
          type: SourceType.article,
          description: 'Research on reversibility and commitment',
        ),
      ],
    ),

    // Temporal Content (Limited Time)
    KnowledgeDrop(
      id: 'drop_010',
      title: '2024 AI Index: Progress & Peril',
      description:
          'Stanford\'s annual AI Index cuts through the hype with hard data. What actually changed in AI this year? What should you be paying attention to? We break down the key findings.',
      contentType: ContentType.video,
      category: ContentCategory.temporal,
      difficulty: ContentDifficulty.intermediate,
      status: ContentStatus.active,
      durationSeconds: 380,
      contentUrl:
          'https://archive.org/download/2024-ai-index-progress-peril/2024%20AI%20Index%20Progress%20%26%20Peril.mp4',
      thumbnailUrl: 'https://picsum.photos/seed/ai-index/400/225',
      tags: ['AI', 'technology', 'trends', '2024'],
      skills: ['Tech Literacy', 'Strategic Thinking'],
      useCases: ['Tech decisions', 'Career planning', 'Product strategy'],
      xpReward: 120,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      expiresAt: DateTime.now().add(const Duration(days: 3)),
    ),
    KnowledgeDrop(
      id: 'drop_011',
      title: 'Risk Budgeting & Robust Institutional Finance',
      description:
          'When markets panic, most investors panic with them. Learn how endowments and pension funds use risk budgeting to stay rational when everyone else loses their minds.',
      contentType: ContentType.audio,
      category: ContentCategory.temporal,
      difficulty: ContentDifficulty.advanced,
      status: ContentStatus.active,
      durationSeconds: 1031,
      contentUrl:
          'https://archive.org/download/risk-budgeting-and-robust-institutional-finance/Risk%20Budgeting%20and%20Robust%20Institutional%20Finance.m4a',
      tags: ['finance', 'decisions', 'risk'],
      skills: ['Financial Thinking', 'Emotional Regulation'],
      useCases: ['Investment decisions', 'Business planning'],
      xpReward: 150,
      createdAt: DateTime.now().subtract(const Duration(hours: 18)),
      expiresAt: DateTime.now().add(const Duration(days: 5)),
      requiredRank: UserRank.analyst,
    ),

    // Advanced Content
    KnowledgeDrop(
      id: 'drop_012',
      title: 'Systems Thinking Masterclass',
      description:
          'Everything is connected. Learn to see the feedback loops, emergent behaviors, and leverage points that drive complex systems—from markets to organizations to ecosystems.',
      contentType: ContentType.video,
      category: ContentCategory.thinkingTools,
      difficulty: ContentDifficulty.advanced,
      status: ContentStatus.comingSoon,
      durationSeconds: 890,
      contentUrl: 'https://example.com/video/systems-thinking.mp4',
      thumbnailUrl: 'https://picsum.photos/seed/systems/400/225',
      tags: ['systems', 'complexity', 'thinking'],
      skills: ['Systems Thinking', 'Analysis'],
      useCases: ['Organization design', 'Product strategy', 'Policy'],
      xpReward: 200,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      requiredRank: UserRank.strategist,
    ),
  ];

  /// Sample knowledge requests
  static final List<KnowledgeRequest> knowledgeRequests = [
    KnowledgeRequest(
      id: 'req_001',
      userId: 'user_001',
      description:
          'How do I handle a difficult conversation with a direct report who isn\'t performing?',
      type: RequestType.problem,
      status: RequestStatus.processing,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      estimatedDelivery: const Duration(hours: 24),
      extractedTags: ['leadership', 'difficult-conversations', 'management'],
    ),
    KnowledgeRequest(
      id: 'req_002',
      userId: 'user_001',
      description: 'I want to learn how to read financial statements.',
      type: RequestType.skill,
      status: RequestStatus.matched,
      matchedDropId: 'drop_financial_001',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      extractedTags: ['finance', 'analysis', 'business'],
    ),
  ];
}
