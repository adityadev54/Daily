import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'mock_data.dart';

/// Provider for the current user
final userProvider = NotifierProvider<UserNotifier, User>(UserNotifier.new);

class UserNotifier extends Notifier<User> {
  @override
  User build() => MockData.currentUser;

  /// Add XP to user
  void addXp(int amount) {
    state = state.copyWith(xp: state.xp + amount);
  }

  /// Mark a drop as completed
  void completeDrop(String dropId, int xpReward) {
    if (state.hasCompleted(dropId)) return;

    state = state.copyWith(
      completedDropIds: [...state.completedDropIds, dropId],
      inProgressDropIds: state.inProgressDropIds
          .where((id) => id != dropId)
          .toList(),
      xp: state.xp + xpReward,
    );
  }

  /// Start a drop
  void startDrop(String dropId) {
    if (state.isInProgress(dropId) || state.hasCompleted(dropId)) return;

    state = state.copyWith(
      inProgressDropIds: [...state.inProgressDropIds, dropId],
    );
  }

  /// Toggle bookmark
  void toggleBookmark(String dropId) {
    if (state.isBookmarked(dropId)) {
      state = state.copyWith(
        bookmarkedDropIds: state.bookmarkedDropIds
            .where((id) => id != dropId)
            .toList(),
      );
    } else {
      state = state.copyWith(
        bookmarkedDropIds: [...state.bookmarkedDropIds, dropId],
      );
    }
  }

  /// Use a request token
  bool useRequestToken() {
    if (state.requestTokens <= 0) return false;
    state = state.copyWith(requestTokens: state.requestTokens - 1);
    return true;
  }

  /// Add request tokens
  void addRequestTokens(int amount) {
    state = state.copyWith(requestTokens: state.requestTokens + amount);
  }
}

/// Provider for all knowledge drops
final knowledgeDropsProvider =
    NotifierProvider<KnowledgeDropsNotifier, List<KnowledgeDrop>>(
      KnowledgeDropsNotifier.new,
    );

class KnowledgeDropsNotifier extends Notifier<List<KnowledgeDrop>> {
  @override
  List<KnowledgeDrop> build() => MockData.knowledgeDrops;

  /// Get active drops only
  List<KnowledgeDrop> get activeDrops =>
      state.where((drop) => drop.status == ContentStatus.active).toList();

  /// Get drops by category
  List<KnowledgeDrop> byCategory(ContentCategory category) =>
      activeDrops.where((drop) => drop.category == category).toList();

  /// Get temporal (expiring) drops
  List<KnowledgeDrop> get temporalDrops =>
      activeDrops.where((drop) => drop.isTemporal && !drop.isExpired).toList();

  /// Get new drops (last 7 days)
  List<KnowledgeDrop> get newDrops {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return activeDrops.where((drop) => drop.createdAt.isAfter(weekAgo)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Search drops
  List<KnowledgeDrop> search(String query) {
    final lowerQuery = query.toLowerCase();
    return activeDrops.where((drop) {
      return drop.title.toLowerCase().contains(lowerQuery) ||
          drop.description.toLowerCase().contains(lowerQuery) ||
          drop.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
          drop.skills.any((skill) => skill.toLowerCase().contains(lowerQuery));
    }).toList();
  }
}

/// Provider for filtered drops by category
final dropsByCategoryProvider =
    Provider.family<List<KnowledgeDrop>, ContentCategory>((ref, category) {
      final drops = ref.watch(knowledgeDropsProvider);
      return drops
          .where(
            (drop) =>
                drop.status == ContentStatus.active &&
                drop.category == category,
          )
          .toList();
    });

/// Provider for new drops
final newDropsProvider = Provider<List<KnowledgeDrop>>((ref) {
  final drops = ref.watch(knowledgeDropsProvider);
  final weekAgo = DateTime.now().subtract(const Duration(days: 7));
  return drops
      .where(
        (drop) =>
            drop.status == ContentStatus.active &&
            drop.createdAt.isAfter(weekAgo),
      )
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

/// Provider for temporal drops
final temporalDropsProvider = Provider<List<KnowledgeDrop>>((ref) {
  final drops = ref.watch(knowledgeDropsProvider);
  return drops
      .where(
        (drop) =>
            drop.status == ContentStatus.active &&
            drop.isTemporal &&
            !drop.isExpired,
      )
      .toList()
    ..sort((a, b) {
      final aExpiry = a.expiresAt;
      final bExpiry = b.expiresAt;
      if (aExpiry == null) return 1;
      if (bExpiry == null) return -1;
      return aExpiry.compareTo(bExpiry);
    });
});

/// Provider for knowledge requests
final knowledgeRequestsProvider =
    NotifierProvider<KnowledgeRequestsNotifier, List<KnowledgeRequest>>(
      KnowledgeRequestsNotifier.new,
    );

class KnowledgeRequestsNotifier extends Notifier<List<KnowledgeRequest>> {
  @override
  List<KnowledgeRequest> build() => MockData.knowledgeRequests;

  /// Add a new request
  void addRequest(KnowledgeRequest request) {
    state = [...state, request];
  }

  /// Update request status
  void updateStatus(
    String requestId,
    RequestStatus newStatus, {
    String? dropId,
  }) {
    state = state.map((request) {
      if (request.id == requestId) {
        return request.copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
          matchedDropId: dropId,
        );
      }
      return request;
    }).toList();
  }

  /// Get pending requests
  List<KnowledgeRequest> get pendingRequests => state
      .where(
        (r) =>
            r.status == RequestStatus.pending ||
            r.status == RequestStatus.processing,
      )
      .toList();

  /// Get fulfilled requests
  List<KnowledgeRequest> get fulfilledRequests =>
      state.where((r) => r.isFulfilled).toList();
}

/// Provider for user's pending requests
final pendingRequestsProvider = Provider<List<KnowledgeRequest>>((ref) {
  final requests = ref.watch(knowledgeRequestsProvider);
  return requests
      .where(
        (r) =>
            r.status == RequestStatus.pending ||
            r.status == RequestStatus.processing,
      )
      .toList();
});

/// Selected drop for player - using Provider with a class to manage state
final selectedDropProvider =
    NotifierProvider<SelectedDropNotifier, KnowledgeDrop?>(
      SelectedDropNotifier.new,
    );

class SelectedDropNotifier extends Notifier<KnowledgeDrop?> {
  @override
  KnowledgeDrop? build() => null;

  void select(KnowledgeDrop? drop) => state = drop;
  void clear() => state = null;
}

/// Current navigation index
final navigationIndexProvider = NotifierProvider<NavigationIndexNotifier, int>(
  NavigationIndexNotifier.new,
);

class NavigationIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}
