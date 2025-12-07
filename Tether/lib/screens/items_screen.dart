import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/receipt.dart';
import '../services/database_service.dart';
import '../widgets/custom_card.dart';
import 'item_detail_screen.dart';

class ItemsScreen extends StatefulWidget {
  final bool showExpiredOnly;

  const ItemsScreen({super.key, this.showExpiredOnly = false});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final DatabaseService _db = DatabaseService();
  List<Receipt> _receipts = [];
  bool _isLoading = true;
  ItemCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);

    try {
      List<Receipt> items;
      if (widget.showExpiredOnly) {
        items = await _db.getExpiredWarranties();
      } else if (_selectedCategory != null) {
        items = await _db.getReceiptsByCategory(_selectedCategory!);
      } else {
        items = await _db.getAllReceipts();
      }
      setState(() {
        _receipts = items;
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
      appBar: AppBar(
        title: Text(
          widget.showExpiredOnly ? 'Expired Warranties' : 'All Items',
        ),
      ),
      body: Column(
        children: [
          if (!widget.showExpiredOnly) _buildCategoryFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _receipts.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadItems,
                    color: isDark ? Colors.white : Colors.black,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _receipts.length,
                      itemBuilder: (context, index) {
                        final receipt = _receipts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ItemCard(
                            receipt: receipt,
                            onTap: () => _openDetails(receipt),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isSelected: _selectedCategory == null,
            onTap: () {
              setState(() => _selectedCategory = null);
              _loadItems();
            },
          ),
          const SizedBox(width: 8),
          ...ItemCategory.values.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: category.displayName,
                isSelected: _selectedCategory == category,
                onTap: () {
                  setState(() => _selectedCategory = category);
                  _loadItems();
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.receipt,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            widget.showExpiredOnly ? 'No expired warranties' : 'No items yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            widget.showExpiredOnly
                ? 'Your warranties are still active'
                : 'Scan your first receipt to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : Colors.black)
              : Colors.transparent,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: isSelected ? 1 : 0.2)
                : Colors.black.withValues(alpha: isSelected ? 1 : 0.1),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.white : Colors.black),
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Receipt receipt;
  final VoidCallback? onTap;

  const _ItemCard({required this.receipt, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TetherCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Image or icon
          Container(
            width: 56,
            height: 56,
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
                    _getCategoryIcon(receipt.category),
                    size: 24,
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
                  receipt.storeName ?? receipt.category.displayName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(receipt.purchaseDate),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (receipt.price != null)
                Text(
                  '\$${receipt.price!.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              const SizedBox(height: 4),
              _StatusBadge(receipt: receipt),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(ItemCategory category) {
    switch (category) {
      case ItemCategory.electronics:
        return LucideIcons.smartphone;
      case ItemCategory.clothing:
        return LucideIcons.shirt;
      case ItemCategory.appliances:
        return LucideIcons.refrigerator;
      case ItemCategory.furniture:
        return LucideIcons.armchair;
      case ItemCategory.automotive:
        return LucideIcons.car;
      case ItemCategory.other:
        return LucideIcons.receipt;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final Receipt receipt;

  const _StatusBadge({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String text;
    bool isUrgent = false;

    if (receipt.warrantyExpired) {
      text = 'Expired';
    } else if (receipt.isWarrantyExpiringSoon) {
      text = '${receipt.daysUntilWarrantyExpiry}d left';
      isUrgent = true;
    } else if (receipt.warrantyExpiry != null) {
      text = receipt.warrantyStatus;
    } else {
      text = 'No warranty';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: isUrgent ? 0.15 : 0.08)
            : Colors.black.withValues(alpha: isUrgent ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: isUrgent ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
