import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/receipt.dart';
import '../services/database_service.dart';
import '../widgets/custom_card.dart';
import 'scan_screen.dart';
import 'items_screen.dart';
import 'dying_soon_screen.dart';
import 'returns_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'item_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  List<Receipt> _receipts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final receipts = await _db.getAllReceipts();
    setState(() {
      _receipts = receipts;
      _isLoading = false;
    });
  }

  List<Receipt> get _urgentItems {
    final now = DateTime.now();
    return _receipts.where((r) {
      if (r.warrantyExpiry != null) {
        final daysLeft = r.warrantyExpiry!.difference(now).inDays;
        return daysLeft >= 0 && daysLeft <= 30;
      }
      if (r.returnDeadline != null) {
        final daysLeft = r.returnDeadline!.difference(now).inDays;
        return daysLeft >= 0 && daysLeft <= 7;
      }
      return false;
    }).toList()..sort((a, b) {
      final aDays =
          a.warrantyExpiry?.difference(now).inDays ??
          a.returnDeadline?.difference(now).inDays ??
          999;
      final bDays =
          b.warrantyExpiry?.difference(now).inDays ??
          b.returnDeadline?.difference(now).inDays ??
          999;
      return aDays.compareTo(bDays);
    });
  }

  int get _activeWarranties => _receipts
      .where((r) => r.warrantyExpiry != null && !r.warrantyExpired)
      .length;
  int get _pendingReturns => _receipts
      .where((r) => r.returnDeadline != null && !r.returnWindowClosed)
      .length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: CustomScrollView(
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tether',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Row(
                              children: [
                                _IconButton(
                                  icon: LucideIcons.search,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SearchScreen(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _IconButton(
                                  icon: LucideIcons.settings,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SettingsScreen(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Stats Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                        child: _StatsCard(
                          totalItems: _receipts.length,
                          activeWarranties: _activeWarranties,
                          pendingReturns: _pendingReturns,
                          onItemsTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ItemsScreen(),
                            ),
                          ),
                          onWarrantiesTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DyingSoonScreen(),
                            ),
                          ),
                          onReturnsTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReturnsScreen(),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Urgent Section
                    if (_urgentItems.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.alertCircle,
                                size: 18,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Needs Attention',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            if (index >= _urgentItems.length || index >= 3) {
                              return null;
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _UrgentItem(
                                receipt: _urgentItems[index],
                                onTap: () =>
                                    _openItemDetail(_urgentItems[index]),
                              ),
                            );
                          }, childCount: _urgentItems.length.clamp(0, 3)),
                        ),
                      ),
                    ],

                    // Empty State
                    if (_receipts.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(48),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.receipt,
                                  size: 48,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No receipts yet',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Scan your first receipt to start\ntracking warranties and returns',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Bottom padding
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
      ),
      floatingActionButton: _ScanFab(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScanScreen()),
          );
          if (result == true) _loadData();
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _openItemDetail(Receipt receipt) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ItemDetailScreen(receipt: receipt)),
    ).then((_) => _loadData());
  }
}

// Minimal icon button
class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

// Unified stats card
class _StatsCard extends StatelessWidget {
  final int totalItems;
  final int activeWarranties;
  final int pendingReturns;
  final VoidCallback onItemsTap;
  final VoidCallback onWarrantiesTap;
  final VoidCallback onReturnsTap;

  const _StatsCard({
    required this.totalItems,
    required this.activeWarranties,
    required this.pendingReturns,
    required this.onItemsTap,
    required this.onWarrantiesTap,
    required this.onReturnsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TetherCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Main tap area - All items
          GestureDetector(
            onTap: onItemsTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.05,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      LucideIcons.receipt,
                      size: 22,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$totalItems Items',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'View all receipts',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          ),
          // Divider
          Container(
            height: 1,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
          ),
          // Bottom row with warranties and returns
          Row(
            children: [
              Expanded(
                child: _StatButton(
                  icon: LucideIcons.shield,
                  value: '$activeWarranties',
                  label: 'Warranties',
                  onTap: onWarrantiesTap,
                  showBorder: true,
                ),
              ),
              Container(
                width: 1,
                height: 70,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
              ),
              Expanded(
                child: _StatButton(
                  icon: LucideIcons.rotateCcw,
                  value: '$pendingReturns',
                  label: 'Returns',
                  onTap: onReturnsTap,
                  showBorder: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Stat button for bottom row
class _StatButton extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;
  final bool showBorder;

  const _StatButton({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
    required this.showBorder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Urgent item card
class _UrgentItem extends StatelessWidget {
  final Receipt receipt;
  final VoidCallback onTap;

  const _UrgentItem({required this.receipt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    final isReturn =
        receipt.returnDeadline != null &&
        receipt.returnDeadline!.isAfter(now) &&
        receipt.returnDeadline!.difference(now).inDays <= 7;

    final daysLeft = isReturn
        ? receipt.returnDeadline!.difference(now).inDays
        : receipt.warrantyExpiry?.difference(now).inDays ?? 0;

    final urgencyText = daysLeft == 0
        ? 'Today'
        : daysLeft == 1
        ? '1 day left'
        : '$daysLeft days left';

    return GestureDetector(
      onTap: onTap,
      child: TetherCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isReturn
                    ? Colors.orange.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isReturn ? LucideIcons.rotateCcw : LucideIcons.shieldAlert,
                size: 18,
                color: isReturn ? Colors.orange : Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receipt.itemName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isReturn ? 'Return window' : 'Warranty',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: daysLeft <= 3
                    ? Colors.red.withValues(alpha: 0.1)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                urgencyText,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: daysLeft <= 3
                      ? Colors.red
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Clean floating action button
class _ScanFab extends StatelessWidget {
  final VoidCallback onTap;

  const _ScanFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.scan,
              size: 20,
              color: theme.scaffoldBackgroundColor,
            ),
            const SizedBox(width: 10),
            Text(
              'Add Receipt',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.scaffoldBackgroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
