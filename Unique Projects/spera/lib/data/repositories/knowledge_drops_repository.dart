import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/models.dart';

/// Repository for fetching knowledge drops from Supabase
class KnowledgeDropsRepository {
  final SupabaseClient _client;

  KnowledgeDropsRepository({SupabaseClient? client})
    : _client = client ?? SupabaseService.client;

  /// Fetch all active knowledge drops
  Future<List<KnowledgeDrop>> getActiveDrops() async {
    final response = await _client
        .from('knowledge_drops')
        .select()
        .eq('status', 'active')
        .order('created_at', ascending: false);

    return (response as List).map((json) => _mapToKnowledgeDrop(json)).toList();
  }

  /// Fetch all drops (including archived for admin/history)
  Future<List<KnowledgeDrop>> getAllDrops({bool includeVaulted = false}) async {
    var query = _client.from('knowledge_drops').select();

    if (!includeVaulted) {
      query = query.neq('status', 'vaulted');
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((json) => _mapToKnowledgeDrop(json)).toList();
  }

  /// Fetch a single drop by ID
  Future<KnowledgeDrop?> getDropById(String id) async {
    final response = await _client
        .from('knowledge_drops')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return _mapToKnowledgeDrop(response);
  }

  /// Fetch drops by category
  Future<List<KnowledgeDrop>> getDropsByCategory(
    ContentCategory category,
  ) async {
    final response = await _client
        .from('knowledge_drops')
        .select()
        .eq('status', 'active')
        .eq('category', category.name)
        .order('created_at', ascending: false);

    return (response as List).map((json) => _mapToKnowledgeDrop(json)).toList();
  }

  /// Fetch drops by IDs (for user's completed/in-progress)
  Future<List<KnowledgeDrop>> getDropsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final response = await _client
        .from('knowledge_drops')
        .select()
        .inFilter('id', ids);

    return (response as List).map((json) => _mapToKnowledgeDrop(json)).toList();
  }

  /// Fetch transcript for a drop
  Future<List<TranscriptSegment>> getTranscript(String dropId) async {
    final response = await _client
        .from('transcripts')
        .select()
        .eq('drop_id', dropId)
        .order('start_time', ascending: true);

    return (response as List)
        .map(
          (json) => TranscriptSegment(
            id: json['id'] as String,
            text: json['text'] as String,
            startTime: (json['start_time'] as num).toDouble(),
            endTime: (json['end_time'] as num).toDouble(),
            speaker: json['speaker'] as String?,
          ),
        )
        .toList();
  }

  /// Map database JSON to KnowledgeDrop model
  KnowledgeDrop _mapToKnowledgeDrop(Map<String, dynamic> json) {
    return KnowledgeDrop(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      contentType: ContentType.values.firstWhere(
        (e) => e.name == json['content_type'],
        orElse: () => ContentType.audio,
      ),
      category: ContentCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ContentCategory.thinkingTools,
      ),
      difficulty: ContentDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => ContentDifficulty.foundational,
      ),
      status: ContentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ContentStatus.active,
      ),
      durationSeconds: json['duration_seconds'] as int,
      contentUrl: json['content_url'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      skills: List<String>.from(json['skills'] ?? []),
      useCases: List<String>.from(json['use_cases'] ?? []),
      xpReward: json['xp_reward'] as int? ?? 50,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Provider for the repository
final knowledgeDropsRepositoryProvider = Provider<KnowledgeDropsRepository>((
  ref,
) {
  return KnowledgeDropsRepository();
});

/// Provider for active knowledge drops from Supabase
final supabaseKnowledgeDropsProvider = FutureProvider<List<KnowledgeDrop>>((
  ref,
) async {
  final repository = ref.read(knowledgeDropsRepositoryProvider);
  return repository.getActiveDrops();
});

/// Provider for a single drop by ID
final supabaseDropByIdProvider = FutureProvider.family<KnowledgeDrop?, String>((
  ref,
  id,
) async {
  final repository = ref.read(knowledgeDropsRepositoryProvider);
  return repository.getDropById(id);
});

/// Provider for transcript
final supabaseTranscriptProvider =
    FutureProvider.family<List<TranscriptSegment>, String>((ref, dropId) async {
      final repository = ref.read(knowledgeDropsRepositoryProvider);
      return repository.getTranscript(dropId);
    });
