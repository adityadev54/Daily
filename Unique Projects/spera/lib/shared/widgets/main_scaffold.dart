import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_router.dart';
import 'custom_nav_bar.dart';
import 'mini_player.dart';

/// Main scaffold with bottom navigation and mini player
class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/discover')) return 1;
    if (location.startsWith('/request')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final miniPlayerState = ref.watch(miniPlayerProvider);

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini Player floating above navbar
          if (miniPlayerState.currentDrop != null)
            MiniPlayer(
              onTap: () {
                if (miniPlayerState.currentDrop != null) {
                  AppRouter.goToPlayer(
                    context,
                    miniPlayerState.currentDrop!.id,
                  );
                }
              },
            ),
          // Navigation bar
          CustomNavBar(
            currentIndex: selectedIndex,
            onTap: (index) => AppRouter.goToTab(context, index),
          ),
        ],
      ),
    );
  }
}
