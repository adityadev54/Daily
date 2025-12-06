import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../data/models/budget.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBudget();
    });
  }

  Future<void> _loadBudget() async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    final budgetProvider = context.read<BudgetProvider>();

    if (authProvider.user != null) {
      await budgetProvider.loadData(authProvider.user!.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Budget'),
          actions: [
            IconButton(
              icon: const Icon(Iconsax.setting_2, size: 22),
              onPressed: () => _showSettingsDialog(context),
            ),
          ],
        ),
        body: Consumer<BudgetProvider>(
          builder: (context, budgetProvider, child) {
            if (budgetProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: _loadBudget,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                children: [
                  // Weekly Overview
                  _buildWeeklyOverview(context, theme, isDark, budgetProvider),
                  const SizedBox(height: 28),

                  // Quick Stats
                  _buildQuickStats(context, theme, isDark, budgetProvider),
                  const SizedBox(height: 28),

                  // Category Breakdown
                  if (budgetProvider.categorySpending.isNotEmpty) ...[
                    Text(
                      'By Category',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.secondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryBreakdown(
                      context,
                      theme,
                      isDark,
                      budgetProvider,
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Recent Expenses
                  Text(
                    'Recent',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.secondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRecentExpenses(context, theme, isDark, budgetProvider),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddExpenseDialog(context),
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
          child: const Icon(Iconsax.add),
        ),
      ),
    );
  }

  Widget _buildWeeklyOverview(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    BudgetProvider provider,
  ) {
    final progress = provider.weeklyProgress.clamp(0.0, 1.0);
    final isOverBudget = provider.isOverBudget;
    final isWarning = progress > 0.8 && !isOverBudget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Amount display
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${provider.currencySymbol}${provider.weeklySpending.toStringAsFixed(2)}',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 8),
              child: Text(
                '/ ${provider.currencySymbol}${provider.weeklyBudget.toStringAsFixed(0)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'spent this week',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 20),

        // Progress bar
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isOverBudget
                      ? Colors.red
                      : isWarning
                      ? Colors.orange
                      : (isDark ? Colors.white : Colors.black),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Status
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              provider.statusMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isOverBudget
                    ? Colors.red
                    : isWarning
                    ? Colors.orange
                    : theme.colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    BudgetProvider provider,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            context,
            label: 'Remaining',
            value:
                '${provider.currencySymbol}${provider.weeklyRemaining.abs().toStringAsFixed(0)}',
            isNegative: provider.isOverBudget,
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
        ),
        Expanded(
          child: _buildStatItem(
            context,
            label: 'Daily Target',
            value:
                '${provider.currencySymbol}${provider.dailyRemaining.toStringAsFixed(0)}',
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
        ),
        Expanded(
          child: _buildStatItem(
            context,
            label: 'This Month',
            value:
                '${provider.currencySymbol}${provider.monthlySpending.toStringAsFixed(0)}',
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    bool isNegative = false,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isNegative ? Colors.red : null,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    BudgetProvider provider,
  ) {
    final categories = provider.categorySpending;
    final total = categories.values.fold(0.0, (sum, val) => sum + val);
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedCategories.map((entry) {
        final percent = total > 0 ? entry.value / total : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  entry.key,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percent,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : Colors.black,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 60,
                child: Text(
                  '${provider.currencySymbol}${entry.value.toStringAsFixed(0)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentExpenses(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    BudgetProvider provider,
  ) {
    final entries = provider.entries;

    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Iconsax.receipt,
              size: 40,
              color: theme.colorScheme.secondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No expenses yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: entries.take(10).map((entry) {
        return Dismissible(
          key: Key('expense_${entry.id}'),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: Icon(
              Iconsax.trash,
              color: Colors.red.withValues(alpha: 0.7),
            ),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => provider.deleteEntry(entry.id!),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: Icon(_getCategoryIcon(entry.category), size: 22),
              title: Text(
                entry.description ?? entry.category ?? 'Expense',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                _formatDate(entry.date),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
              trailing: Text(
                '-${provider.currencySymbol}${entry.amount.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.red[400],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getCategoryIcon(String? category) {
    return switch (category?.toLowerCase()) {
      'groceries' => Iconsax.shopping_cart,
      'dining out' => Iconsax.reserve,
      'takeout' => Iconsax.box,
      'snacks' => Iconsax.cake,
      'beverages' => Iconsax.coffee,
      'kitchen supplies' => Iconsax.home_2,
      _ => Iconsax.receipt,
    };
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';

    return '${date.month}/${date.day}';
  }

  Future<void> _showSettingsDialog(BuildContext context) async {
    final budgetProvider = context.read<BudgetProvider>();
    final authProvider = context.read<AuthProvider>();

    final budgetController = TextEditingController(
      text: budgetProvider.weeklyBudget.toStringAsFixed(0),
    );
    String selectedCurrency = budgetProvider.currency;

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
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
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
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Settings',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Weekly Budget',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: budgetController,
                    decoration: InputDecoration(
                      prefixText: budgetProvider.currencySymbol,
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Currency',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCurrency,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: BudgetSettings.currencies
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedCurrency = v!),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () async {
                        final budget =
                            double.tryParse(budgetController.text) ?? 100;

                        if (authProvider.user != null) {
                          final settings = BudgetSettings(
                            userId: authProvider.user!.id!,
                            weeklyBudget: budget,
                            currency: selectedCurrency,
                          );
                          await budgetProvider.saveSettings(settings);
                        }

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
                        'Save',
                        style: TextStyle(fontWeight: FontWeight.w600),
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

  Future<void> _showAddExpenseDialog(BuildContext context) async {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'Groceries';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          final budgetProvider = context.read<BudgetProvider>();

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
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
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Add Expense',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Amount',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      prefixText: budgetProvider.currencySymbol,
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Category',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: BudgetEntry.categories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedCategory = v!),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Note (optional)',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      hintText: 'What was this for?',
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () async {
                        final amount = double.tryParse(amountController.text);
                        if (amount == null || amount <= 0) return;

                        final authProvider = context.read<AuthProvider>();
                        if (authProvider.user == null) return;

                        await budgetProvider.addQuickExpense(
                          authProvider.user!.id!,
                          amount,
                          selectedCategory,
                          descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                        );

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
                        'Add',
                        style: TextStyle(fontWeight: FontWeight.w600),
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
