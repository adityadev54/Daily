import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/requests_repository.dart';
import '../repositories/reports_repository.dart';
import '../models/models.dart';

// ============================================
// REPOSITORIES
// ============================================

/// Provider for requests repository
final requestsRepositoryProvider = Provider<RequestsRepository>((ref) {
  return RequestsRepository();
});

/// Provider for reports repository
final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository();
});

// ============================================
// REQUESTS PROVIDERS
// ============================================

/// Provider for all knowledge requests from Supabase
final supabaseRequestsProvider = FutureProvider<List<KnowledgeRequest>>((
  ref,
) async {
  final repository = ref.watch(requestsRepositoryProvider);
  return repository.getAllRequests();
});

/// Provider for user's requests from Supabase
final userRequestsProvider =
    FutureProvider.family<List<KnowledgeRequest>, String>((ref, userId) async {
      final repository = ref.watch(requestsRepositoryProvider);
      return repository.getRequestsByUser(userId);
    });

/// Stream provider for real-time requests updates (admin)
final requestsStreamProvider = StreamProvider<List<KnowledgeRequest>>((ref) {
  final repository = ref.watch(requestsRepositoryProvider);
  return repository.watchAllRequests();
});

/// Notifier for managing requests state with Supabase
class SupabaseRequestsNotifier extends AsyncNotifier<List<KnowledgeRequest>> {
  @override
  Future<List<KnowledgeRequest>> build() async {
    final repository = ref.watch(requestsRepositoryProvider);
    return repository.getAllRequests();
  }

  /// Add a new request
  Future<bool> addRequest(KnowledgeRequest request) async {
    final repository = ref.read(requestsRepositoryProvider);
    final result = await repository.createRequest(request);
    if (result != null) {
      state = AsyncValue.data([...state.value ?? [], result]);
      return true;
    }
    return false;
  }

  /// Update request status
  Future<bool> updateStatus(
    String requestId,
    RequestStatus newStatus, {
    String? dropId,
  }) async {
    final repository = ref.read(requestsRepositoryProvider);
    final success = await repository.updateRequestStatus(
      requestId,
      newStatus,
      matchedDropId: dropId,
    );
    if (success) {
      // Refresh the state
      ref.invalidateSelf();
    }
    return success;
  }

  /// Delete a request
  Future<bool> deleteRequest(String requestId) async {
    final repository = ref.read(requestsRepositoryProvider);
    final success = await repository.deleteRequest(requestId);
    if (success) {
      state = AsyncValue.data(
        (state.value ?? []).where((r) => r.id != requestId).toList(),
      );
    }
    return success;
  }

  /// Refresh requests
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final supabaseRequestsNotifierProvider =
    AsyncNotifierProvider<SupabaseRequestsNotifier, List<KnowledgeRequest>>(
      SupabaseRequestsNotifier.new,
    );

// ============================================
// REPORTS PROVIDERS
// ============================================

/// Provider for all reports from Supabase
final supabaseReportsProvider = FutureProvider<List<UserReport>>((ref) async {
  final repository = ref.watch(reportsRepositoryProvider);
  return repository.getAllReports();
});

/// Stream provider for real-time reports updates (admin)
final reportsStreamProvider = StreamProvider<List<UserReport>>((ref) {
  final repository = ref.watch(reportsRepositoryProvider);
  return repository.watchAllReports();
});

/// Notifier for managing reports state with Supabase
class SupabaseReportsNotifier extends AsyncNotifier<List<UserReport>> {
  @override
  Future<List<UserReport>> build() async {
    final repository = ref.watch(reportsRepositoryProvider);
    return repository.getAllReports();
  }

  /// Add a new report
  Future<bool> addReport(UserReport report) async {
    final repository = ref.read(reportsRepositoryProvider);
    final result = await repository.createReport(report);
    if (result != null) {
      state = AsyncValue.data([result, ...state.value ?? []]);
      return true;
    }
    return false;
  }

  /// Update report status
  Future<bool> updateStatus(
    String reportId,
    ReportStatus newStatus, {
    String? adminNotes,
  }) async {
    final repository = ref.read(reportsRepositoryProvider);
    final success = await repository.updateReportStatus(
      reportId,
      newStatus,
      adminNotes: adminNotes,
    );
    if (success) {
      ref.invalidateSelf();
    }
    return success;
  }

  /// Delete a report
  Future<bool> deleteReport(String reportId) async {
    final repository = ref.read(reportsRepositoryProvider);
    final success = await repository.deleteReport(reportId);
    if (success) {
      state = AsyncValue.data(
        (state.value ?? []).where((r) => r.id != reportId).toList(),
      );
    }
    return success;
  }

  /// Refresh reports
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final supabaseReportsNotifierProvider =
    AsyncNotifierProvider<SupabaseReportsNotifier, List<UserReport>>(
      SupabaseReportsNotifier.new,
    );

/// Provider for pending reports count
final pendingReportsCountProvider = FutureProvider<int>((ref) async {
  final reports = ref.watch(supabaseReportsProvider);
  return reports.when(
    data: (data) => data.where((r) => r.status == ReportStatus.pending).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for pending requests count
final pendingRequestsCountProvider = FutureProvider<int>((ref) async {
  final requests = ref.watch(supabaseRequestsProvider);
  return requests.when(
    data: (data) => data
        .where(
          (r) =>
              r.status == RequestStatus.pending ||
              r.status == RequestStatus.processing,
        )
        .length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
