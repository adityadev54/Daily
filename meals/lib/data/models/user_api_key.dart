/// Supported AI providers for BYOK (Bring Your Own Key)
enum AIProviderType { openRouter, openAI, gemini, deepSeek }

extension AIProviderExtension on AIProviderType {
  String get displayName {
    switch (this) {
      case AIProviderType.openRouter:
        return 'OpenRouter';
      case AIProviderType.openAI:
        return 'ChatGPT';
      case AIProviderType.gemini:
        return 'Gemini';
      case AIProviderType.deepSeek:
        return 'DeepSeek';
    }
  }

  String get baseUrl {
    switch (this) {
      case AIProviderType.openRouter:
        return 'https://openrouter.ai/api/v1/chat/completions';
      case AIProviderType.openAI:
        return 'https://api.openai.com/v1/chat/completions';
      case AIProviderType.gemini:
        return 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
      case AIProviderType.deepSeek:
        return 'https://api.deepseek.com/v1/chat/completions';
    }
  }

  String get defaultModel {
    switch (this) {
      case AIProviderType.openRouter:
        return 'meta-llama/llama-3.2-3b-instruct:free';
      case AIProviderType.openAI:
        return 'gpt-4o-mini';
      case AIProviderType.gemini:
        return 'gemini-pro';
      case AIProviderType.deepSeek:
        return 'deepseek-chat';
    }
  }

  String get keyPrefix {
    switch (this) {
      case AIProviderType.openRouter:
        return 'sk-or-';
      case AIProviderType.openAI:
        return 'sk-';
      case AIProviderType.gemini:
        return 'AI';
      case AIProviderType.deepSeek:
        return 'sk-';
    }
  }

  static AIProviderType? detectFromKey(String key) {
    if (key.startsWith('sk-or-')) return AIProviderType.openRouter;
    if (key.startsWith('AIza')) return AIProviderType.gemini;
    if (key.startsWith('sk-')) {
      // Could be OpenAI or DeepSeek - default to OpenAI
      return AIProviderType.openAI;
    }
    return null;
  }
}

/// Model for storing a single provider's API key (for multi-key support)
class ProviderApiKey {
  final int? id;
  final int userId;
  final AIProviderType provider;
  final String apiKey;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProviderApiKey({
    this.id,
    required this.userId,
    required this.provider,
    required this.apiKey,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProviderApiKey.fromMap(Map<String, dynamic> map) {
    return ProviderApiKey(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      provider: AIProviderType.values.firstWhere(
        (p) => p.name == map['provider'],
        orElse: () => AIProviderType.openRouter,
      ),
      apiKey: map['api_key'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'provider': provider.name,
      'api_key': apiKey,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get masked key for display
  String get maskedKey {
    if (apiKey.length <= 8) return '••••••••';
    return '${apiKey.substring(0, 4)}••••${apiKey.substring(apiKey.length - 4)}';
  }
}

/// Model for storing user-specific API keys (legacy single-key + settings)
class UserApiKey {
  final int? id;
  final int userId;
  final String? apiKey;
  final String? provider; // 'openRouter', 'openAI', 'gemini', 'deepSeek'
  final String? activeProvider; // For multi-key: currently active provider
  final bool useSharedKey;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserApiKey({
    this.id,
    required this.userId,
    this.apiKey,
    this.provider,
    this.activeProvider,
    this.useSharedKey = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if user has their own API key
  bool get hasOwnKey => apiKey != null && apiKey!.isNotEmpty;

  /// Check if user has any valid API key access (own key or shared key enabled)
  bool get hasApiAccess => hasOwnKey || useSharedKey;

  /// Get the AIProviderType enum from stored string
  AIProviderType? get aiProvider {
    if (provider == null) return null;
    try {
      return AIProviderType.values.firstWhere(
        (p) => p.name == provider,
        orElse: () => AIProviderType.openRouter,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get the active provider type (for multi-key mode)
  AIProviderType? get activeProviderType {
    if (activeProvider == null) return aiProvider;
    try {
      return AIProviderType.values.firstWhere((p) => p.name == activeProvider);
    } catch (_) {
      return aiProvider;
    }
  }

  factory UserApiKey.fromMap(Map<String, dynamic> map) {
    return UserApiKey(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      apiKey:
          map['openrouter_key']
              as String?, // Keep column name for compatibility
      provider: map['provider'] as String?,
      activeProvider: map['active_provider'] as String?,
      useSharedKey: (map['use_shared_key'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'openrouter_key': apiKey, // Keep column name for compatibility
      'provider': provider,
      'active_provider': activeProvider,
      'use_shared_key': useSharedKey ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserApiKey copyWith({
    int? id,
    int? userId,
    String? apiKey,
    String? provider,
    String? activeProvider,
    bool? useSharedKey,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserApiKey(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      apiKey: apiKey ?? this.apiKey,
      provider: provider ?? this.provider,
      activeProvider: activeProvider ?? this.activeProvider,
      useSharedKey: useSharedKey ?? this.useSharedKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
