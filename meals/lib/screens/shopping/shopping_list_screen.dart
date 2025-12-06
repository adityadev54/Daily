import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../data/models/shopping_item.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _addItemController = TextEditingController();
  bool _showChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadItems());
  }

  void _loadItems() {
    final authProvider = context.read<AuthProvider>();
    final shoppingProvider = context.read<ShoppingProvider>();
    if (authProvider.user != null) {
      shoppingProvider.loadItems(authProvider.user!.id!);
    }
  }

  @override
  void dispose() {
    _addItemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shoppingProvider = context.watch<ShoppingProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          if (shoppingProvider.totalCount > 0)
            PopupMenuButton<String>(
              icon: const Icon(Iconsax.more),
              onSelected: (value) async {
                if (authProvider.user == null) return;
                switch (value) {
                  case 'toggle_checked':
                    setState(() => _showChecked = !_showChecked);
                    break;
                  case 'clear_checked':
                    await shoppingProvider.clearCheckedItems(
                      authProvider.user!.id!,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Checked items cleared'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                    break;
                  case 'clear_all':
                    _showClearAllDialog(
                      context,
                      shoppingProvider,
                      authProvider.user!.id!,
                    );
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle_checked',
                  child: Row(
                    children: [
                      Icon(
                        _showChecked ? Iconsax.eye_slash : Iconsax.eye,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(_showChecked ? 'Hide checked' : 'Show checked'),
                    ],
                  ),
                ),
                if (shoppingProvider.checkedCount > 0)
                  const PopupMenuItem(
                    value: 'clear_checked',
                    child: Row(
                      children: [
                        Icon(Iconsax.broom, size: 20),
                        SizedBox(width: 12),
                        Text('Clear checked'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Iconsax.trash, size: 20),
                      SizedBox(width: 12),
                      Text('Clear all'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: shoppingProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats bar
                if (shoppingProvider.totalCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.02),
                    ),
                    child: Row(
                      children: [
                        _buildStatItem(
                          context,
                          '${shoppingProvider.uncheckedCount}',
                          'remaining',
                          Iconsax.shopping_cart,
                        ),
                        const SizedBox(width: 24),
                        _buildStatItem(
                          context,
                          '${shoppingProvider.checkedCount}',
                          'completed',
                          Iconsax.tick_circle,
                        ),
                        const Spacer(),
                        if (shoppingProvider.uncheckedCount > 0)
                          Text(
                            '${((shoppingProvider.checkedCount / shoppingProvider.totalCount) * 100).round()}% done',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                      ],
                    ),
                  ),

                // Shopping list
                Expanded(
                  child: shoppingProvider.groupedItems.isEmpty
                      ? _buildEmptyState(context)
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 100),
                          children: _buildCategoryLists(
                            context,
                            shoppingProvider,
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context),
        icon: const Icon(Iconsax.add),
        label: const Text('Add Item'),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.secondary),
        const SizedBox(width: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.shopping_cart,
                size: 48,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your shopping list is empty',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add items manually or generate from your meal plan',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategoryLists(
    BuildContext context,
    ShoppingProvider shoppingProvider,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categories = shoppingProvider.groupedItems.keys.toList()..sort();

    return categories.map((category) {
      final items = shoppingProvider.groupedItems[category]!;
      final visibleItems = _showChecked
          ? items
          : items.where((i) => !i.isChecked).toList();

      if (visibleItems.isEmpty) return const SizedBox.shrink();

      final categoryIcon = _getCategoryIcon(category);
      final checkedInCategory = items.where((i) => i.isChecked).length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  categoryIcon,
                  size: 18,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  category,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white12
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$checkedInCategory/${items.length}',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
          ...visibleItems.map(
            (item) => _buildShoppingItem(context, item, shoppingProvider),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildShoppingItem(
    BuildContext context,
    ShoppingItem item,
    ShoppingProvider shoppingProvider,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.read<AuthProvider>();

    return Dismissible(
      key: Key('item_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error,
        child: const Icon(Iconsax.trash, color: Colors.white),
      ),
      onDismissed: (_) {
        if (authProvider.user != null) {
          shoppingProvider.deleteItem(item.id!, authProvider.user!.id!);
        }
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => shoppingProvider.toggleItem(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: item.isChecked
                          ? theme.colorScheme.primary
                          : (isDark ? Colors.white24 : Colors.black26),
                      width: 2,
                    ),
                    color: item.isChecked
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                  ),
                  child: item.isChecked
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      decoration: item.isChecked
                          ? TextDecoration.lineThrough
                          : null,
                      color: item.isChecked
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (item.quantity != null && item.quantity!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white12
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.quantity!,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Fruits':
        return Iconsax.lovely;
      case 'Vegetables':
        return Iconsax.tree;
      case 'Meat':
        return Iconsax.reserve;
      case 'Seafood':
        return Iconsax.driver;
      case 'Dairy & Eggs':
        return Iconsax.milk;
      case 'Grains & Bread':
        return Iconsax.cake;
      case 'Pantry':
        return Iconsax.box_1;
      case 'Condiments':
        return Iconsax.blend;
      case 'Frozen':
        return Iconsax.sun_fog;
      case 'Beverages':
        return Iconsax.coffee;
      case 'Snacks':
        return Iconsax.star;
      default:
        return Iconsax.shopping_bag;
    }
  }

  void _showAddItemDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final shoppingProvider = context.read<ShoppingProvider>();
    _addItemController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Item', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _addItemController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Item name (e.g., Milk, Eggs)',
                prefixIcon: Icon(Iconsax.add),
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (value) =>
                  _addItem(context, value, authProvider, shoppingProvider),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _addItem(
                context,
                _addItemController.text,
                authProvider,
                shoppingProvider,
              ),
              child: const Text('Add to List'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _addItem(
    BuildContext context,
    String name,
    AuthProvider authProvider,
    ShoppingProvider shoppingProvider,
  ) async {
    if (name.trim().isEmpty || authProvider.user == null) return;

    final item = ShoppingItem(
      userId: authProvider.user!.id!,
      name: name.trim(),
      category: ShoppingItem.detectCategory(name.trim()),
    );

    await shoppingProvider.addItem(item);
    _addItemController.clear();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} added to list'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showClearAllDialog(
    BuildContext context,
    ShoppingProvider shoppingProvider,
    int userId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Items'),
        content: const Text(
          'Are you sure you want to clear all items from your shopping list?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await shoppingProvider.clearAllItems(userId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Shopping list cleared'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
