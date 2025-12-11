import 'enums.dart';

/// Represents a knowledge request from a user
/// The core magic of Spera - intent-aware knowledge deployment
class KnowledgeRequest {
  final String id;
  final String userId;

  /// The user's description of their need
  /// Could be: a problem, a skill they want, a situation
  final String description;

  /// Type of request
  final RequestType type;

  /// Current status
  final RequestStatus status;

  /// If matched to existing content
  final String? matchedDropId;

  /// If generated, the new content ID
  final String? generatedDropId;

  /// When requested
  final DateTime createdAt;

  /// When status last changed
  final DateTime updatedAt;

  /// Estimated time until delivery (if processing)
  final Duration? estimatedDelivery;

  /// Optional context tags extracted from request
  final List<String> extractedTags;

  const KnowledgeRequest({
    required this.id,
    required this.userId,
    required this.description,
    required this.type,
    required this.status,
    this.matchedDropId,
    this.generatedDropId,
    required this.createdAt,
    required this.updatedAt,
    this.estimatedDelivery,
    required this.extractedTags,
  });

  /// Whether the request has been fulfilled
  bool get isFulfilled =>
      status == RequestStatus.delivered || status == RequestStatus.matched;

  /// The drop ID (either matched or generated)
  String? get dropId => matchedDropId ?? generatedDropId;

  /// Copy with modifications
  KnowledgeRequest copyWith({
    String? id,
    String? userId,
    String? description,
    RequestType? type,
    RequestStatus? status,
    String? matchedDropId,
    String? generatedDropId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Duration? estimatedDelivery,
    List<String>? extractedTags,
  }) {
    return KnowledgeRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      matchedDropId: matchedDropId ?? this.matchedDropId,
      generatedDropId: generatedDropId ?? this.generatedDropId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      extractedTags: extractedTags ?? this.extractedTags,
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'description': description,
      'type': type.name,
      'status': status.name,
      'matchedDropId': matchedDropId,
      'generatedDropId': generatedDropId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'estimatedDeliveryMinutes': estimatedDelivery?.inMinutes,
      'extractedTags': extractedTags,
    };
  }

  /// From JSON
  factory KnowledgeRequest.fromJson(Map<String, dynamic> json) {
    return KnowledgeRequest(
      id: json['id'] as String,
      userId: json['userId'] as String,
      description: json['description'] as String,
      type: RequestType.values.byName(json['type'] as String),
      status: RequestStatus.values.byName(json['status'] as String),
      matchedDropId: json['matchedDropId'] as String?,
      generatedDropId: json['generatedDropId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      estimatedDelivery: json['estimatedDeliveryMinutes'] != null
          ? Duration(minutes: json['estimatedDeliveryMinutes'] as int)
          : null,
      extractedTags: List<String>.from(json['extractedTags'] as List),
    );
  }

  /// Create a new request
  factory KnowledgeRequest.create({
    required String id,
    required String userId,
    required String description,
    required RequestType type,
  }) {
    return KnowledgeRequest(
      id: id,
      userId: userId,
      description: description,
      type: type,
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      extractedTags: [],
    );
  }
}

/// Type of knowledge request
enum RequestType {
  problem('Request a Solution', 'Describe a real problem you\'re facing'),
  skill('Deploy Knowledge', 'Tell us what skill you want to develop'),
  situation('Get Unstuck', 'Explain the situation you\'re stuck in');

  const RequestType(this.title, this.subtitle);

  final String title;
  final String subtitle;
}
