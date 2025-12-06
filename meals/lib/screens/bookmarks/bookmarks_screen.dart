import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../widgets/common/meal_card.dart';
import '../../widgets/common/empty_state.dart';
import '../meals/meal_detail_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBookmarks());
  }

  void _loadBookmarks() {
    final authProvider = context.read<AuthProvider>();
    final bookmarkProvider = context.read<BookmarkProvider>();
    if (authProvider.user != null) {
      bookmarkProvider.loadBookmarks(authProvider.user!.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bookmarkProvider = context.watch<BookmarkProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Meals'),
        actions: [
          if (bookmarkProvider.count > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Iconsax.heart5,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${bookmarkProvider.count}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: bookmarkProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookmarkProvider.bookmarkedMeals.isEmpty
          ? const EmptyState(
              icon: Iconsax.heart,
              title: 'No saved meals yet',
              subtitle: 'Bookmark meals you love to find them here',
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.82,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: bookmarkProvider.bookmarkedMeals.length,
              itemBuilder: (context, index) {
                final meal = bookmarkProvider.bookmarkedMeals[index];
                return MealCard(
                  meal: meal,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MealDetailScreen(meal: meal),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
