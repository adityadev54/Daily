import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/supabase_service.dart';
import '../../data/providers/app_providers.dart';
import '../../data/providers/admin_providers.dart';
import '../../data/models/models.dart';

/// Request Screen - Clean, focused design
class RequestScreen extends ConsumerStatefulWidget {
  const RequestScreen({super.key});

  @override
  ConsumerState<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends ConsumerState<RequestScreen> {
  RequestType? _selectedType;
  final _descriptionController = TextEditingController();
  final _sourcesController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _sourcesController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _selectType(RequestType type) {
    setState(() => _selectedType = type);
    // Focus on text field after selection
    Future.delayed(const Duration(milliseconds: 100), () {
      _focusNode.requestFocus();
    });
  }

  void _submitRequest() async {
    if (_selectedType == null || _descriptionController.text.trim().isEmpty) {
      return;
    }

    final user = ref.read(userProvider);
    final userNotifier = ref.read(userProvider.notifier);

    // Get the actual Supabase user ID
    final supabaseUserId = SupabaseService.currentUser?.id;
    if (supabaseUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to submit a request')),
      );
      return;
    }

    // Check if user has tokens
    if (user.requestTokens <= 0) {
      _showNoTokensSheet();
      return;
    }

    setState(() => _isSubmitting = true);

    // Use a request token
    userNotifier.useRequestToken();

    // Create the request with Supabase user ID
    // Combine description with sources if provided
    String fullDescription = _descriptionController.text.trim();
    if (_sourcesController.text.trim().isNotEmpty) {
      fullDescription += '\n\nSources: ${_sourcesController.text.trim()}';
    }

    final request = KnowledgeRequest.create(
      id: const Uuid().v4(),
      userId: supabaseUserId,
      description: fullDescription,
      type: _selectedType!,
    );

    // Save to Supabase
    final success = await ref
        .read(supabaseRequestsNotifierProvider.notifier)
        .addRequest(request);

    setState(() => _isSubmitting = false);

    // Show result
    if (mounted) {
      if (success) {
        // Also add to local state for immediate UI update
        ref.read(knowledgeRequestsProvider.notifier).addRequest(request);
        _showSuccessSheet();
        _resetForm();
      } else {
        // Refund the token if failed
        userNotifier.addRequestTokens(1);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _resetForm() {
    setState(() {
      _selectedType = null;
      _descriptionController.clear();
      _sourcesController.clear();
    });
  }

  void _showNoTokensSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.coin_1, color: AppColors.warning, size: 24),
            ),
            const SizedBox(height: 16),
            Text('No tokens remaining', style: AppTypography.headingSmall),
            const SizedBox(height: 8),
            Text(
              'Complete knowledge drops to earn more request tokens.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Got it',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.tick_circle,
                color: AppColors.success,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text('Request submitted', style: AppTypography.headingSmall),
            const SizedBox(height: 8),
            Text(
              'We\'ll notify you when your knowledge is ready.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Done',
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final pendingRequestsAsync = ref.watch(supabaseRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: AppColors.background,
            title: const Text('Request'),
            titleTextStyle: AppTypography.headingSmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
            actions: [
              _TokenIndicator(tokens: user.requestTokens),
              const SizedBox(width: 16),
            ],
          ),

          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                0,
                AppSpacing.screenPadding,
                AppSpacing.lg,
              ),
              child: Text(
                'What knowledge do you need?',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),
          ),

          // Request Types
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'type',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...RequestType.values.map(
                    (type) => _TypeOption(
                      type: type,
                      isSelected: _selectedType == type,
                      onTap: () => _selectType(type),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 50.ms),
          ),

          // Description Input
          if (_selectedType != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'describe',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.5),
                        ),
                      ),
                      child: TextField(
                        controller: _descriptionController,
                        focusNode: _focusNode,
                        maxLines: 4,
                        maxLength: 500,
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          hintText: _getHintText(),
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          counterStyle: AppTypography.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Sources field (optional)
                    Text(
                      'sources (optional)',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.5),
                        ),
                      ),
                      child: TextField(
                        controller: _sourcesController,
                        maxLines: 2,
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Links to articles, videos, books, etc.',
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add sources to help us create better content for you',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Submit button
                    GestureDetector(
                      onTap:
                          _descriptionController.text.trim().isEmpty ||
                              _isSubmitting
                          ? null
                          : _submitRequest,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _descriptionController.text.trim().isEmpty
                              ? AppColors.surface
                              : AppColors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: _isSubmitting
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Submit request',
                                  style: AppTypography.labelMedium.copyWith(
                                    color:
                                        _descriptionController.text
                                            .trim()
                                            .isEmpty
                                        ? AppColors.textTertiary
                                        : Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),
            ),

          // Pending Requests from Supabase
          ...pendingRequestsAsync.when(
            loading: () => [
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ],
            error: (_, __) => [],
            data: (allRequests) {
              final pendingRequests = allRequests
                  .where(
                    (r) =>
                        r.status == RequestStatus.pending ||
                        r.status == RequestStatus.processing,
                  )
                  .toList();

              if (pendingRequests.isEmpty) return <Widget>[];

              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      AppSpacing.xl,
                      AppSpacing.screenPadding,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'pending',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            pendingRequests.length.toString(),
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final request = pendingRequests[index];
                      return _PendingItem(request: request);
                    }, childCount: pendingRequests.length),
                  ),
                ),
              ];
            },
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  String _getHintText() {
    return switch (_selectedType) {
      RequestType.problem =>
        'e.g., How do I negotiate a raise when budget is tight?',
      RequestType.skill =>
        'e.g., I want to learn how to read financial statements.',
      RequestType.situation =>
        'e.g., I need to give feedback to a colleague who isn\'t performing.',
      null => '',
    };
  }
}

/// Token indicator - Minimal display
class _TokenIndicator extends StatelessWidget {
  final int tokens;

  const _TokenIndicator({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Iconsax.coin_1, color: AppColors.success, size: 16),
        const SizedBox(width: 4),
        Text(
          '$tokens',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Type option - Clean selection row
class _TypeOption extends StatelessWidget {
  final RequestType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    return switch (type) {
      RequestType.problem => Iconsax.cpu,
      RequestType.skill => Iconsax.lamp_on,
      RequestType.situation => Iconsax.message_question,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withValues(alpha: 0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _icon,
                color: isSelected ? AppColors.accent : AppColors.textTertiary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                  ),
                  Text(
                    type.subtitle,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.accent : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.border.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Pending item - Minimal list item
class _PendingItem extends StatelessWidget {
  final KnowledgeRequest request;

  const _PendingItem({required this.request});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.description,
                  style: AppTypography.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(request.createdAt),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
