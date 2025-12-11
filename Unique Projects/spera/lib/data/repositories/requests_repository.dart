import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/models.dart';

/// Repository for managing knowledge requests in Supabase
class RequestsRepository {
  final SupabaseClient _client;

  RequestsRepository({SupabaseClient? client})
    : _client = client ?? SupabaseService.client;

  /// Table name
  static const String _table = 'knowledge_requests';

  /// Create a new knowledge request
  Future<KnowledgeRequest?> createRequest(KnowledgeRequest request) async {
    try {
      // Map to actual table columns:
      // question = description, context = type, priority = 'normal'
      final data = {
        'user_id': request.userId,
        'question': request.description,
        'context': request.type.name,
        'priority': 'normal',
        'status': request.status.name,
      };

      debugPrint('Creating request with data: $data');

      final response = await _client
          .from(_table)
          .insert(data)
          .select()
          .single();
      debugPrint('Request created successfully: $response');
      return _fromJson(response);
    } catch (e, stack) {
      debugPrint('Error creating request: $e');
      debugPrint('Stack: $stack');
      return null;
    }
  }

  /// Get all requests (for admin)
  Future<List<KnowledgeRequest>> getAllRequests() async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((json) => _fromJson(json)).toList();
    } catch (e) {
      print('Error fetching requests: $e');
      return [];
    }
  }

  /// Get requests by user ID
  Future<List<KnowledgeRequest>> getRequestsByUser(String userId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => _fromJson(json)).toList();
    } catch (e) {
      print('Error fetching user requests: $e');
      return [];
    }
  }

  /// Update request status
  Future<bool> updateRequestStatus(
    String requestId,
    RequestStatus newStatus, {
    String? matchedDropId,
  }) async {
    try {
      final data = {
        'status': newStatus.name,
        if (newStatus == RequestStatus.processing)
          'processed_at': DateTime.now().toIso8601String(),
        if (newStatus == RequestStatus.delivered)
          'delivered_at': DateTime.now().toIso8601String(),
        if (matchedDropId != null) 'matched_drop_id': matchedDropId,
      };

      await _client.from(_table).update(data).eq('id', requestId);
      return true;
    } catch (e) {
      debugPrint('Error updating request status: $e');
      return false;
    }
  }

  /// Delete a request
  Future<bool> deleteRequest(String requestId) async {
    try {
      await _client.from(_table).delete().eq('id', requestId);
      return true;
    } catch (e) {
      print('Error deleting request: $e');
      return false;
    }
  }

  /// Stream of all requests (real-time updates for admin)
  Stream<List<KnowledgeRequest>> watchAllRequests() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => _fromJson(json)).toList());
  }

  /// Convert JSON to KnowledgeRequest
  /// Maps actual table columns to our model:
  /// question -> description, context -> type
  KnowledgeRequest _fromJson(Map<String, dynamic> json) {
    return KnowledgeRequest(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      description: json['question'] as String? ?? '',
      type: RequestType.values.firstWhere(
        (t) => t.name == json['context'],
        orElse: () => RequestType.problem,
      ),
      status: RequestStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => RequestStatus.pending,
      ),
      matchedDropId: json['matched_drop_id'] as String?,
      generatedDropId: null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : DateTime.parse(json['created_at'] as String),
      estimatedDelivery: null,
      extractedTags: [],
    );
  }
}
