import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../data/providers/app_providers.dart';
import '../../data/providers/admin_providers.dart';
import '../../data/repositories/reports_repository.dart';
import '../../data/models/models.dart';
import '../../core/services/supabase_service.dart';

/// Admin email for access control
const String _adminEmail = 'appdev827@gmail.com';

/// Admin Dashboard Screen - Professional minimal design
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = SupabaseService.currentUser?.email;

    // Verify admin access
    if (currentUserEmail != _adminEmail) {
      return _AccessDeniedScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: const Icon(Iconsax.arrow_left_2_copy, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Admin',
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Iconsax.refresh_circle_copy, size: 20),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.invalidate(supabaseRequestsProvider);
                  ref.invalidate(supabaseReportsProvider);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Tab Selector
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.sm,
              ),
              child: _TabSelector(
                selectedIndex: _selectedTab,
                onChanged: (index) => setState(() => _selectedTab = index),
              ),
            ),
          ),

          // Content based on selected tab
          if (_selectedTab == 0) ..._buildOverviewTab(ref),
          if (_selectedTab == 1) ..._buildDropsTab(ref),
          if (_selectedTab == 2) ..._buildRequestsTab(ref),
          if (_selectedTab == 3) ..._buildReportsTab(ref),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  List<Widget> _buildOverviewTab(WidgetRef ref) {
    final drops = ref.watch(knowledgeDropsProvider);
    final requestsAsync = ref.watch(supabaseRequestsProvider);
    final reportsAsync = ref.watch(supabaseReportsProvider);

    final pendingRequests =
        requestsAsync.whenOrNull(
          data: (r) => r.where((x) => x.status == RequestStatus.pending).length,
        ) ??
        0;

    final pendingReports =
        reportsAsync.whenOrNull(
          data: (r) => r.where((x) => x.status == ReportStatus.pending).length,
        ) ??
        0;

    return [
      // Stats
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview',
                style: AppTypography.headingSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Stats Grid
              _StatsGrid(
                drops: drops.length,
                requests: pendingRequests,
                reports: pendingReports,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Recent Activity
              Text(
                'Recent Requests',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),

      // Recent requests list
      requestsAsync.when(
        loading: () => const SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (error, __) => SliverToBoxAdapter(
          child: _EmptyState(
            icon: Iconsax.info_circle,
            title: 'Table not set up',
            subtitle: 'Run the SQL migration',
          ),
        ),
        data: (requests) {
          final recent = requests.take(3).toList();
          if (recent.isEmpty) {
            return SliverToBoxAdapter(
              child: _EmptyState(
                icon: Iconsax.message_text,
                title: 'No requests yet',
                subtitle: 'Requests will appear here',
              ),
            );
          }
          return SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _RequestItem(request: recent[index]),
                childCount: recent.length,
              ),
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _buildRequestsTab(WidgetRef ref) {
    final requestsAsync = ref.watch(supabaseRequestsProvider);

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Text(
            'All Requests',
            style: AppTypography.headingSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      requestsAsync.when(
        loading: () => const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (error, __) => SliverFillRemaining(
          child: _EmptyState(
            icon: Iconsax.info_circle,
            title: 'Table not set up',
            subtitle: 'Run the SQL migration first',
          ),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return SliverFillRemaining(
              child: _EmptyState(
                icon: Iconsax.message_text,
                title: 'No requests',
                subtitle: 'User requests will appear here',
              ),
            );
          }
          return SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _RequestItem(request: requests[index]),
                childCount: requests.length,
              ),
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _buildReportsTab(WidgetRef ref) {
    final reportsAsync = ref.watch(supabaseReportsProvider);

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Text(
            'All Reports',
            style: AppTypography.headingSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      reportsAsync.when(
        loading: () => const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (error, __) => SliverFillRemaining(
          child: _EmptyState(
            icon: Iconsax.info_circle,
            title: 'Table not set up',
            subtitle: 'Run the SQL migration first',
          ),
        ),
        data: (reports) {
          if (reports.isEmpty) {
            return SliverFillRemaining(
              child: _EmptyState(
                icon: Iconsax.flag,
                title: 'No reports',
                subtitle: 'Issue reports will appear here',
              ),
            );
          }
          return SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ReportItem(report: reports[index]),
                childCount: reports.length,
              ),
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _buildDropsTab(WidgetRef ref) {
    final drops = ref.watch(knowledgeDropsProvider);

    return [
      // Header with add button
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Drops',
                style: AppTypography.headingSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showAddDropSheet(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.add, size: 18, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text(
                        'Add Drop',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Drops count
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Text(
            '${drops.length} drops total',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
      ),

      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

      // Drops list
      if (drops.isEmpty)
        SliverFillRemaining(
          child: _EmptyState(
            icon: Iconsax.document,
            title: 'No drops',
            subtitle: 'Add your first knowledge drop',
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _DropItem(
                drop: drops[index],
                onEdit: () => _showEditDropSheet(context, drops[index]),
              ),
              childCount: drops.length,
            ),
          ),
        ),
    ];
  }

  void _showAddDropSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddEditDropSheet(),
    );
  }

  void _showEditDropSheet(BuildContext context, KnowledgeDrop drop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditDropSheet(drop: drop),
    );
  }
}

// ============================================
// ACCESS DENIED SCREEN
// ============================================

class _AccessDeniedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.lock, size: 28, color: AppColors.error),
              ),
              const SizedBox(height: 20),
              Text(
                'Access Denied',
                style: AppTypography.headingSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You don\'t have permission to access the admin panel.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// TAB SELECTOR
// ============================================

class _TabSelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _TabSelector({required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tabs = ['Overview', 'Drops', 'Requests', 'Reports'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(index);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: AppTypography.labelSmall.copyWith(
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                      fontWeight: isSelected
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ============================================
// STATS GRID
// ============================================

class _StatsGrid extends StatelessWidget {
  final int drops;
  final int requests;
  final int reports;

  const _StatsGrid({
    required this.drops,
    required this.requests,
    required this.reports,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              label: 'Drops',
              value: '$drops',
              color: AppColors.accent,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.border.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _StatItem(
              label: 'Requests',
              value: '$requests',
              color: Colors.blue,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.border.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _StatItem(
              label: 'Reports',
              value: '$reports',
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headingMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

// ============================================
// EMPTY STATE
// ============================================

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// REQUEST ITEM
// ============================================

class _RequestItem extends ConsumerWidget {
  final KnowledgeRequest request;

  const _RequestItem({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              _StatusBadge(status: request.status),
              const Spacer(),
              Text(
                _formatTime(request.createdAt),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Description
          Text(
            request.description,
            style: AppTypography.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // Type and actions
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHover,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  request.type.title,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              if (request.status == RequestStatus.pending)
                _ActionButton(
                  label: 'Process',
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    await ref
                        .read(supabaseRequestsNotifierProvider.notifier)
                        .updateStatus(request.id, RequestStatus.processing);
                    ref.invalidate(supabaseRequestsProvider);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _StatusBadge extends StatelessWidget {
  final RequestStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case RequestStatus.pending:
        color = AppColors.warning;
        break;
      case RequestStatus.processing:
        color = Colors.blue;
        break;
      case RequestStatus.matched:
      case RequestStatus.delivered:
        color = AppColors.success;
        break;
      case RequestStatus.failed:
        color = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ============================================
// REPORT ITEM
// ============================================

class _ReportItem extends ConsumerWidget {
  final UserReport report;

  const _ReportItem({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              _ReportStatusBadge(status: report.status),
              const Spacer(),
              Text(
                _formatTime(report.createdAt),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Issue type
          Text(
            _getIssueLabel(report.issueType),
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),

          // Drop title
          Text(
            report.dropTitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          if (report.description != null) ...[
            const SizedBox(height: 8),
            Text(
              report.description!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 10),

          // Actions
          if (report.status == ReportStatus.pending)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionButton(
                  label: 'Dismiss',
                  isSecondary: true,
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await ref
                        .read(supabaseReportsNotifierProvider.notifier)
                        .updateStatus(report.id, ReportStatus.dismissed);
                    ref.invalidate(supabaseReportsProvider);
                  },
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  label: 'Resolve',
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    await ref
                        .read(supabaseReportsNotifierProvider.notifier)
                        .updateStatus(report.id, ReportStatus.resolved);
                    ref.invalidate(supabaseReportsProvider);
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _getIssueLabel(String type) {
    switch (type) {
      case 'audio_problem':
        return 'Audio Problem';
      case 'transcript_error':
        return 'Transcript Error';
      case 'inaccurate_info':
        return 'Inaccurate Information';
      case 'inappropriate_content':
        return 'Inappropriate Content';
      default:
        return 'Other Issue';
    }
  }
}

class _ReportStatusBadge extends StatelessWidget {
  final ReportStatus status;

  const _ReportStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case ReportStatus.pending:
        color = AppColors.warning;
        break;
      case ReportStatus.reviewed:
        color = Colors.blue;
        break;
      case ReportStatus.resolved:
        color = AppColors.success;
        break;
      case ReportStatus.dismissed:
        color = AppColors.textTertiary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ============================================
// ACTION BUTTON
// ============================================

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isSecondary;

  const _ActionButton({
    required this.label,
    required this.onTap,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSecondary
              ? AppColors.surfaceHover
              : AppColors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSecondary ? AppColors.textSecondary : AppColors.accent,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ============================================
// DROP ITEM
// ============================================

class _DropItem extends StatelessWidget {
  final KnowledgeDrop drop;
  final VoidCallback onEdit;

  const _DropItem({required this.drop, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(drop.category),
                  size: 20,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drop.title,
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDuration(drop.durationSeconds),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              _DropStatusBadge(status: drop.status),
            ],
          ),
          const SizedBox(height: 10),

          // Description
          Text(
            drop.description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // Category and actions
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  drop.category.title,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.accent,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHover,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  drop.difficulty.label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onEdit();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHover,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Iconsax.edit_2,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(ContentCategory category) {
    switch (category) {
      case ContentCategory.thinkingTools:
        return Iconsax.lamp_on;
      case ContentCategory.realWorldProblems:
        return Iconsax.global;
      case ContentCategory.skillUnlocks:
        return Iconsax.key;
      case ContentCategory.decisionFrameworks:
        return Iconsax.routing;
      case ContentCategory.temporal:
        return Iconsax.timer_1;
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}

class _DropStatusBadge extends StatelessWidget {
  final ContentStatus status;

  const _DropStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case ContentStatus.active:
        color = AppColors.success;
        break;
      case ContentStatus.archived:
        color = AppColors.textTertiary;
        break;
      case ContentStatus.vaulted:
        color = AppColors.warning;
        break;
      case ContentStatus.comingSoon:
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ============================================
// ADD/EDIT DROP SHEET
// ============================================

class _AddEditDropSheet extends ConsumerStatefulWidget {
  final KnowledgeDrop? drop;

  const _AddEditDropSheet({this.drop});

  @override
  ConsumerState<_AddEditDropSheet> createState() => _AddEditDropSheetState();
}

class _AddEditDropSheetState extends ConsumerState<_AddEditDropSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _contentUrlController;
  late TextEditingController _durationController;
  late ContentCategory _selectedCategory;
  late ContentDifficulty _selectedDifficulty;
  late ContentStatus _selectedStatus;
  bool _isLoading = false;

  bool get isEditing => widget.drop != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.drop?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.drop?.description ?? '',
    );
    _contentUrlController = TextEditingController(
      text: widget.drop?.contentUrl ?? '',
    );
    _durationController = TextEditingController(
      text: widget.drop?.durationSeconds.toString() ?? '300',
    );
    _selectedCategory = widget.drop?.category ?? ContentCategory.thinkingTools;
    _selectedDifficulty =
        widget.drop?.difficulty ?? ContentDifficulty.foundational;
    _selectedStatus = widget.drop?.status ?? ContentStatus.active;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentUrlController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Drop' : 'Add New Drop',
                  style: AppTypography.headingSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Iconsax.close_circle,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                0,
                AppSpacing.screenPadding,
                bottomPadding + AppSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  _buildLabel('Title'),
                  _buildTextField(_titleController, 'Enter drop title'),
                  const SizedBox(height: AppSpacing.md),

                  // Description
                  _buildLabel('Description'),
                  _buildTextField(
                    _descriptionController,
                    'Enter description',
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Content URL
                  _buildLabel('Content URL'),
                  _buildTextField(_contentUrlController, 'Audio/Video URL'),
                  const SizedBox(height: AppSpacing.md),

                  // Duration
                  _buildLabel('Duration (seconds)'),
                  _buildTextField(
                    _durationController,
                    '300',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Category
                  _buildLabel('Category'),
                  _buildDropdown<ContentCategory>(
                    value: _selectedCategory,
                    items: ContentCategory.values,
                    itemLabel: (c) => c.title,
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Difficulty
                  _buildLabel('Difficulty'),
                  _buildDropdown<ContentDifficulty>(
                    value: _selectedDifficulty,
                    items: ContentDifficulty.values,
                    itemLabel: (d) => d.label,
                    onChanged: (v) => setState(() => _selectedDifficulty = v!),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Status
                  _buildLabel('Status'),
                  _buildDropdown<ContentStatus>(
                    value: _selectedStatus,
                    items: ContentStatus.values,
                    itemLabel: (s) => s.name,
                    onChanged: (v) => setState(() => _selectedStatus = v!),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Save button
                  GestureDetector(
                    onTap: _isLoading ? null : _saveDrop,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isEditing ? 'Update Drop' : 'Create Drop',
                                style: AppTypography.labelLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Info text
                  Text(
                    'Note: Drops are currently stored locally. Supabase integration for drops management coming soon.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: AppTypography.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surfaceElevated,
          style: AppTypography.bodyMedium,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<void> _saveDrop() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Implement Supabase save when knowledge_drops table is set up
    // For now, show a message
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Drop updated (local only for now)'
                : 'Drop created (local only for now)',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
