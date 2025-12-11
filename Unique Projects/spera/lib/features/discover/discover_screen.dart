import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_router.dart';
import '../../data/providers/app_providers.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/widgets.dart';

/// Discover Screen - Browse all content by category
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  ContentCategory? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allDrops = ref.watch(knowledgeDropsProvider);

    // Filter drops based on search and category
    List<KnowledgeDrop> filteredDrops = allDrops
        .where((drop) => drop.status == ContentStatus.active)
        .toList();

    if (_selectedCategory != null) {
      filteredDrops = filteredDrops
          .where((drop) => drop.category == _selectedCategory)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredDrops = filteredDrops.where((drop) {
        return drop.title.toLowerCase().contains(query) ||
            drop.description.toLowerCase().contains(query) ||
            drop.tags.any((tag) => tag.toLowerCase().contains(query)) ||
            drop.skills.any((skill) => skill.toLowerCase().contains(query));
      }).toList();
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: AppColors.background,
            title: const Text('Discover'),
            titleTextStyle: AppTypography.headingSmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                AppSpacing.md,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.3),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Search knowledge...',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    prefixIcon: Icon(
                      Iconsax.search_normal_1_copy,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Iconsax.close_circle, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Category Filters
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Row(
                children: [
                  _CategoryChip(
                    label: 'All',
                    isSelected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ...ContentCategory.values.map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: _CategoryChip(
                        label: category.title,
                        isSelected: _selectedCategory == category,
                        onTap: () =>
                            setState(() => _selectedCategory = category),
                        color: _getCategoryColor(category),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

          // Results
          if (filteredDrops.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: Iconsax.search_normal_1,
                title: 'No results found',
                subtitle: 'Try adjusting your search or filters',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final drop = filteredDrops[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: DropCard(
                      drop: drop,
                      onTap: () => AppRouter.goToPlayer(context, drop.id),
                    ),
                  ).animate().fadeIn(
                    duration: 400.ms,
                    delay: Duration(milliseconds: 50 * index),
                  );
                }, childCount: filteredDrops.length),
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Color _getCategoryColor(ContentCategory category) {
    return switch (category) {
      ContentCategory.thinkingTools => AppColors.categoryThinking,
      ContentCategory.realWorldProblems => AppColors.categoryProblems,
      ContentCategory.skillUnlocks => AppColors.categorySkills,
      ContentCategory.decisionFrameworks => AppColors.accent,
      ContentCategory.temporal => AppColors.categoryTemporal,
    };
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.accent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? chipColor.withValues(alpha: 0.3)
                : AppColors.border.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? chipColor : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
