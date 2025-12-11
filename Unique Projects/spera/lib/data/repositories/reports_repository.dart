import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';

/// Report status enum
enum ReportStatus { pending, reviewed, resolved, dismissed }

/// User report model
class UserReport {
  final String id;
  final String userId;
  final String dropId;
  final String dropTitle;
  final String issueType;
  final String? description;
  final DateTime createdAt;
  final ReportStatus status;
  final String? adminNotes;

  const UserReport({
    required this.id,
    required this.userId,
    required this.dropId,
    required this.dropTitle,
    required this.issueType,
    this.description,
    required this.createdAt,
    required this.status,
    this.adminNotes,
  });

  UserReport copyWith({
    String? id,
    String? userId,
    String? dropId,
    String? dropTitle,
    String? issueType,
    String? description,
    DateTime? createdAt,
    ReportStatus? status,
    String? adminNotes,
  }) {
    return UserReport(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dropId: dropId ?? this.dropId,
      dropTitle: dropTitle ?? this.dropTitle,
      issueType: issueType ?? this.issueType,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'drop_id': dropId,
      'drop_title': dropTitle,
      'issue_type': issueType,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'status': status.name,
      'admin_notes': adminNotes,
    };
  }

  factory UserReport.fromJson(Map<String, dynamic> json) {
    return UserReport(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      dropId: json['drop_id'] as String,
      dropTitle: json['drop_title'] as String,
      issueType: json['issue_type'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: ReportStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ReportStatus.pending,
      ),
      adminNotes: json['admin_notes'] as String?,
    );
  }
}

/// Repository for managing user reports in Supabase
class ReportsRepository {
  final SupabaseClient _client;

  ReportsRepository({SupabaseClient? client})
    : _client = client ?? SupabaseService.client;

  /// Table name
  static const String _table = 'user_reports';

  /// Create a new report
  Future<UserReport?> createReport(UserReport report) async {
    try {
      await _client.from(_table).insert(report.toJson());
      return report;
    } catch (e) {
      debugPrint('Error creating report: $e');
      return null;
    }
  }

  /// Get all reports (for admin)
  Future<List<UserReport>> getAllReports() async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserReport.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching reports: $e');
      return [];
    }
  }

  /// Get reports by status
  Future<List<UserReport>> getReportsByStatus(ReportStatus status) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('status', status.name)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserReport.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching reports by status: $e');
      return [];
    }
  }

  /// Update report status
  Future<bool> updateReportStatus(
    String reportId,
    ReportStatus newStatus, {
    String? adminNotes,
  }) async {
    try {
      final data = {
        'status': newStatus.name,
        if (adminNotes != null) 'admin_notes': adminNotes,
      };

      await _client.from(_table).update(data).eq('id', reportId);
      return true;
    } catch (e) {
      debugPrint('Error updating report status: $e');
      return false;
    }
  }

  /// Delete a report
  Future<bool> deleteReport(String reportId) async {
    try {
      await _client.from(_table).delete().eq('id', reportId);
      return true;
    } catch (e) {
      debugPrint('Error deleting report: $e');
      return false;
    }
  }

  /// Stream of all reports (real-time updates for admin)
  Stream<List<UserReport>> watchAllReports() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => UserReport.fromJson(json)).toList());
  }

  /// Get count of pending reports
  Future<int> getPendingReportsCount() async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('status', ReportStatus.pending.name);

      return (response as List).length;
    } catch (e) {
      debugPrint('Error fetching pending reports count: $e');
      return 0;
    }
  }
}
