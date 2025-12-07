import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/receipt.dart';
import '../services/database_service.dart';
import '../widgets/custom_card.dart';
import 'item_detail_screen.dart';

class DyingSoonScreen extends StatefulWidget {
  const DyingSoonScreen({super.key});

  @override
  State<DyingSoonScreen> createState() => _DyingSoonScreenState();
}

class _DyingSoonScreenState extends State<DyingSoonScreen> {
  final DatabaseService _db = DatabaseService();
  List<Receipt> _expiringItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);

    try {
      final items = await _db.getExpiringWarranties(days: 90);
      setState(() {
        _expiringItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Dying Soon')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expiringItems.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadItems,
              color: isDark ? Colors.white : Colors.black,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildUrgentSection()),
                  SliverToBoxAdapter(child: _buildUpcomingSection()),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                ),
              ),
              child: Icon(
                LucideIcons.checkCircle,
                size: 40,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text('All Clear', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'No warranties expiring in the next 90 days',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final urgentCount = _expiringItems
        .where((r) => r.daysUntilWarrantyExpiry <= 14)
        .length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: TetherCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  child: const Icon(LucideIcons.timer, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_expiringItems.length} warranties expiring',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'in the next 90 days',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (urgentCount > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertTriangle, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$urgentCount item${urgentCount > 1 ? 's' : ''} expiring within 14 days',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUrgentSection() {
    final urgentItems = _expiringItems
        .where((r) => r.daysUntilWarrantyExpiry <= 14)
        .toList();
    if (urgentItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Urgent (14 days or less)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 12),
        ...urgentItems.map(
          (receipt) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: _ExpiringItemCard(
              receipt: receipt,
              isUrgent: true,
              onTap: () => _openDetails(receipt),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildUpcomingSection() {
    final upcomingItems = _expiringItems
        .where((r) => r.daysUntilWarrantyExpiry > 14)
        .toList();
    if (upcomingItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Upcoming (15-90 days)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 12),
        ...upcomingItems.map(
          (receipt) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: _ExpiringItemCard(
              receipt: receipt,
              isUrgent: false,
              onTap: () => _openDetails(receipt),
            ),
          ),
        ),
      ],
    );
  }

  void _openDetails(Receipt receipt) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ItemDetailScreen(receipt: receipt)),
    );
    if (result == true) {
      _loadItems();
    }
  }
}

class _ExpiringItemCard extends StatelessWidget {
  final Receipt receipt;
  final bool isUrgent;
  final VoidCallback? onTap;

  const _ExpiringItemCard({
    required this.receipt,
    required this.isUrgent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daysLeft = receipt.daysUntilWarrantyExpiry;

    return TetherCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Image or icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: receipt.imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.file(
                      File(receipt.imagePath!),
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    LucideIcons.receipt,
                    size: 22,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.black.withValues(alpha: 0.4),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receipt.itemName,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Expires ${DateFormat('MMM dd, yyyy').format(receipt.warrantyExpiry!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: isUrgent ? 0.15 : 0.08)
                  : Colors.black.withValues(alpha: isUrgent ? 0.1 : 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  daysLeft <= 0 ? 'Today' : '$daysLeft',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (daysLeft > 0)
                  Text('days', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
