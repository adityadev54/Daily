import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../data/models/pantry_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pantry_provider.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPantry();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPantry() async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    final pantryProvider = context.read<PantryProvider>();

    if (authProvider.user != null) {
      await pantryProvider.loadItems(authProvider.user!.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Iconsax.arrow_left,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    if (_isSearching)
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: 'Search items...',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            border: InputBorder.none,
                          ),
                          onChanged: (value) => setState(() {}),
                        ),
                      )
                    else
                      Expanded(
                        child: Text(
                          'Pantry',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(
                        _isSearching
                            ? Iconsax.close_circle
                            : Iconsax.search_normal,
                        color: isDark ? Colors.white : Colors.black,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSearching = !_isSearching;
                          if (!_isSearching) _searchController.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tab Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: isDark ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: isDark ? Colors.black : Colors.white,
                    unselectedLabelColor: isDark
                        ? Colors.white54
                        : Colors.black54,
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    dividerColor: Colors.transparent,
                    indicatorPadding: const EdgeInsets.all(4),
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Low Stock'),
                      Tab(text: 'Expiring'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Content
              Expanded(
                child: Consumer<PantryProvider>(
                  builder: (context, pantryProvider, child) {
                    if (pantryProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAllItemsTab(
                          context,
                          theme,
                          isDark,
                          pantryProvider,
                        ),
                        _buildLowStockTab(
                          context,
                          theme,
                          isDark,
                          pantryProvider,
                        ),
                        _buildExpiringTab(
                          context,
                          theme,
                          isDark,
                          pantryProvider,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddItemDialog(context),
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          child: const Icon(Iconsax.add),
        ),
      ),
    );
  }

  Widget _buildAllItemsTab(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    PantryProvider provider,
  ) {
    final items = provider.allItems;
    final filteredItems = _searchController.text.isEmpty
        ? items
        : items
              .where(
                (i) => i.name.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ),
              )
              .toList();

    if (filteredItems.isEmpty) {
      return _buildEmptyState(
        context,
        theme,
        isDark,
        Iconsax.box,
        'Your pantry is empty',
        'Add items to track what you have at home',
      );
    }

    // Group by category
    final grouped = <String, List<PantryItem>>{};
    for (final item in filteredItems) {
      final category = item.category ?? 'Other';
      grouped.putIfAbsent(category, () => []).add(item);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final category = grouped.keys.elementAt(index);
        final categoryItems = grouped[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: 20),
            _buildCategoryHeader(theme, isDark, category, categoryItems.length),
            const SizedBox(height: 12),
            ...categoryItems.map(
              (item) => _buildItemCard(context, theme, isDark, item),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLowStockTab(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    PantryProvider provider,
  ) {
    final items = provider.lowStockItems;

    if (items.isEmpty) {
      return _buildEmptyState(
        context,
        theme,
        isDark,
        Iconsax.tick_circle,
        'All stocked up!',
        'No items are running low',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildItemCard(
          context,
          theme,
          isDark,
          items[index],
          showLowBadge: true,
        );
      },
    );
  }

  Widget _buildExpiringTab(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    PantryProvider provider,
  ) {
    final items = provider.expiringItems;

    if (items.isEmpty) {
      return _buildEmptyState(
        context,
        theme,
        isDark,
        Iconsax.calendar_tick,
        'Nothing expiring soon',
        'All your items are fresh',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildItemCard(
          context,
          theme,
          isDark,
          items[index],
          showExpiry: true,
        );
      },
    );
  }

  Widget _buildCategoryHeader(
    ThemeData theme,
    bool isDark,
    String category,
    int count,
  ) {
    return Row(
      children: [
        Icon(
          _getCategoryIcon(category),
          size: 16,
          color: isDark ? Colors.white : Colors.black,
        ),
        const SizedBox(width: 8),
        Text(
          category,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    PantryItem item, {
    bool showLowBadge = false,
    bool showExpiry = false,
  }) {
    return Dismissible(
      key: Key('pantry_${item.id}'),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Iconsax.trash, color: Colors.white, size: 20),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        context.read<PantryProvider>().deleteItem(item.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} removed'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _showEditItemDialog(context, item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getCategoryIcon(item.category),
                  color: isDark ? Colors.white70 : Colors.black54,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (item.quantity != null)
                          Text(
                            '${item.quantity}${item.unit != null ? ' ${item.unit}' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        if ((showExpiry || showLowBadge) &&
                            item.quantity != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '•',
                              style: TextStyle(
                                color: theme.colorScheme.secondary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        if (showExpiry && item.expiryDate != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: item.isExpired
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.isExpired
                                  ? 'Expired'
                                  : _formatDate(item.expiryDate!),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: item.isExpired
                                    ? Colors.red
                                    : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if ((showLowBadge || item.isLow) && !showExpiry)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Low',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  item.isLow ? Iconsax.warning_25 : Iconsax.warning_2,
                  color: item.isLow
                      ? Colors.orange
                      : (isDark ? Colors.white24 : Colors.black26),
                  size: 20,
                ),
                onPressed: () {
                  context.read<PantryProvider>().toggleLowStock(item.id!);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
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

  IconData _getCategoryIcon(String? category) {
    return switch (category?.toLowerCase()) {
      'produce' => Iconsax.tree,
      'dairy' => Iconsax.milk,
      'meat & seafood' => Iconsax.setting_4,
      'grains & pasta' => Iconsax.menu_board,
      'canned goods' => Iconsax.box,
      'condiments' => Iconsax.drop,
      'spices' => Iconsax.flash_1,
      'snacks' => Iconsax.cake,
      'beverages' => Iconsax.coffee,
      'frozen' => Iconsax.cloud,
      'bakery' => Iconsax.cake,
      _ => Iconsax.box,
    };
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 7) return 'In $diff days';

    return '${date.month}/${date.day}';
  }

  Future<void> _showAddItemDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    String? selectedCategory = 'Other';
    String? selectedUnit;
    DateTime? expiryDate;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? Colors.black : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Add Item',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Item Name',
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: quantityController,
                          decoration: InputDecoration(
                            labelText: 'Qty',
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedUnit,
                          decoration: InputDecoration(
                            labelText: 'Unit',
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: PantryItem.units
                              .map(
                                (unit) => DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => selectedUnit = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: PantryItem.categories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedCategory = v),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 7),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => expiryDate = date);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.calendar,
                            size: 20,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              expiryDate != null
                                  ? 'Expires: ${expiryDate!.month}/${expiryDate!.day}/${expiryDate!.year}'
                                  : 'Set expiry date',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: expiryDate != null
                                    ? null
                                    : (isDark
                                          ? Colors.white54
                                          : Colors.black54),
                              ),
                            ),
                          ),
                          if (expiryDate != null)
                            GestureDetector(
                              onTap: () => setState(() => expiryDate = null),
                              child: Icon(
                                Iconsax.close_circle,
                                size: 18,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) return;

                        final authProvider = context.read<AuthProvider>();
                        final pantryProvider = context.read<PantryProvider>();

                        if (authProvider.user == null) return;

                        final now = DateTime.now();
                        final item = PantryItem(
                          userId: authProvider.user!.id!,
                          name: nameController.text.trim(),
                          category: selectedCategory,
                          quantity: quantityController.text.trim().isEmpty
                              ? null
                              : quantityController.text.trim(),
                          unit: selectedUnit,
                          expiryDate: expiryDate,
                          createdAt: now,
                          updatedAt: now,
                        );

                        await pantryProvider.addItem(item);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : Colors.black,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Add Item',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showEditItemDialog(
    BuildContext context,
    PantryItem item,
  ) async {
    final nameController = TextEditingController(text: item.name);
    final quantityController = TextEditingController(text: item.quantity ?? '');
    String? selectedCategory = item.category;
    String? selectedUnit = item.unit;
    DateTime? expiryDate = item.expiryDate;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? Colors.black : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Edit Item',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Item Name',
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: quantityController,
                          decoration: InputDecoration(
                            labelText: 'Qty',
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedUnit,
                          decoration: InputDecoration(
                            labelText: 'Unit',
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: PantryItem.units
                              .map(
                                (unit) => DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => selectedUnit = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: PantryItem.categories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedCategory = v),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            expiryDate ??
                            DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => expiryDate = date);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.calendar,
                            size: 20,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              expiryDate != null
                                  ? 'Expires: ${expiryDate!.month}/${expiryDate!.day}/${expiryDate!.year}'
                                  : 'Set expiry date',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: expiryDate != null
                                    ? null
                                    : (isDark
                                          ? Colors.white54
                                          : Colors.black54),
                              ),
                            ),
                          ),
                          if (expiryDate != null)
                            GestureDetector(
                              onTap: () => setState(() => expiryDate = null),
                              child: Icon(
                                Iconsax.close_circle,
                                size: 18,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) return;

                        final pantryProvider = context.read<PantryProvider>();

                        final updatedItem = item.copyWith(
                          name: nameController.text.trim(),
                          category: selectedCategory,
                          quantity: quantityController.text.trim().isEmpty
                              ? null
                              : quantityController.text.trim(),
                          unit: selectedUnit,
                          expiryDate: expiryDate,
                          updatedAt: DateTime.now(),
                        );

                        await pantryProvider.updateItem(updatedItem);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : Colors.black,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
