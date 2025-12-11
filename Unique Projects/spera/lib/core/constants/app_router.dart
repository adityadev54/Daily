import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/home_screen.dart';
import '../../features/discover/discover_screen.dart';
import '../../features/request/request_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/player/player_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/discover/category_list_screen.dart';
import '../../features/streaks/streaks_screen.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/main_scaffold.dart';

/// App router configuration using GoRouter
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  /// Route paths
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/';
  static const String discover = '/discover';
  static const String request = '/request';
  static const String profile = '/profile';
  static const String player = '/player/:id';
  static const String settings = '/settings';
  static const String category = '/category/:type';
  static const String newDrops = '/new-drops';
  static const String temporalDrops = '/temporal';
  static const String streaks = '/streaks';

  /// Create router with ref for auth state
  static GoRouter createRouter(WidgetRef ref) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: home,
      redirect: (context, state) {
        final authState = ref.read(authProvider);
        final isAuthenticated = authState.isAuthenticated;
        final isAuthRoute =
            state.matchedLocation == login ||
            state.matchedLocation == signup ||
            state.matchedLocation == forgotPassword;

        // If not authenticated and not on auth route, redirect to login
        if (!isAuthenticated && !isAuthRoute) {
          return login;
        }

        // If authenticated and on auth route, redirect to home
        if (isAuthenticated && isAuthRoute) {
          return home;
        }

        return null;
      },
      routes: [
        // Auth routes
        GoRoute(
          path: login,
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: LoginScreen());
          },
        ),
        GoRoute(
          path: signup,
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const SignupScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeOutCubic)),
                      ),
                      child: child,
                    );
                  },
            );
          },
        ),
        GoRoute(
          path: forgotPassword,
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const ForgotPasswordScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeOutCubic)),
                      ),
                      child: child,
                    );
                  },
            );
          },
        ),

        // Shell route for bottom navigation
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            return MainScaffold(child: child);
          },
          routes: [
            GoRoute(
              path: home,
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: HomeScreen());
              },
            ),
            GoRoute(
              path: discover,
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: DiscoverScreen());
              },
            ),
            GoRoute(
              path: request,
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: RequestScreen());
              },
            ),
            GoRoute(
              path: profile,
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: ProfileScreen());
              },
            ),
          ],
        ),
        // Full-screen player route
        GoRoute(
          path: player,
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            final dropId = state.pathParameters['id']!;
            return CustomTransitionPage(
              key: state.pageKey,
              child: PlayerScreen(dropId: dropId),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeOutCubic)),
                      ),
                      child: child,
                    );
                  },
            );
          },
        ),
        // Settings route
        GoRoute(
          path: settings,
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeOutCubic)),
                      ),
                      child: child,
                    );
                  },
            );
          },
        ),
        // Category list route
        GoRoute(
          path: category,
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            final typeStr = state.pathParameters['type']!;
            final categoryType = ContentCategory.values.firstWhere(
              (c) => c.name == typeStr,
              orElse: () => ContentCategory.thinkingTools,
            );
            return CustomTransitionPage(
              key: state.pageKey,
              child: CategoryListScreen(category: categoryType),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeOutCubic)),
                      ),
                      child: child,
                    );
                  },
            );
          },
        ),
        // New drops route
        GoRoute(
          path: newDrops,
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const NewDropsScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeOutCubic)),
                      ),
                      child: child,
                    );
                  },
            );
          },
        ),
        // Temporal drops route
        GoRoute(
          path: temporalDrops,
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const TemporalDropsScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeOutCubic)),
                      ),
                      child: child,
                    );
                  },
            );
          },
        ),
        // Streaks route
        GoRoute(
          path: streaks,
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const StreaksScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeOutCubic)),
                      ),
                      child: child,
                    );
                  },
            );
          },
        ),
      ],
    );
  }

  /// Legacy router for backward compatibility (remove after full migration)
  static final GoRouter router = GoRouter(
    navigatorKey: GlobalKey<NavigatorState>(),
    initialLocation: login,
    routes: [
      GoRoute(
        path: login,
        pageBuilder: (context, state) {
          return const NoTransitionPage(child: LoginScreen());
        },
      ),
      GoRoute(
        path: signup,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const SignupScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: animation.drive(
                      Tween(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).chain(CurveTween(curve: Curves.easeOutCubic)),
                    ),
                    child: child,
                  );
                },
          );
        },
      ),
      GoRoute(
        path: forgotPassword,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const ForgotPasswordScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: animation.drive(
                      Tween(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).chain(CurveTween(curve: Curves.easeOutCubic)),
                    ),
                    child: child,
                  );
                },
          );
        },
      ),
      ShellRoute(
        navigatorKey: GlobalKey<NavigatorState>(),
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: home,
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: HomeScreen());
            },
          ),
          GoRoute(
            path: discover,
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: DiscoverScreen());
            },
          ),
          GoRoute(
            path: request,
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: RequestScreen());
            },
          ),
          GoRoute(
            path: profile,
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: ProfileScreen());
            },
          ),
        ],
      ),
      GoRoute(
        path: player,
        pageBuilder: (context, state) {
          final dropId = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: PlayerScreen(dropId: dropId),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: animation.drive(
                      Tween(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).chain(CurveTween(curve: Curves.easeOutCubic)),
                    ),
                    child: child,
                  );
                },
          );
        },
      ),
      GoRoute(
        path: settings,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const SettingsScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: animation.drive(
                      Tween(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).chain(CurveTween(curve: Curves.easeOutCubic)),
                    ),
                    child: child,
                  );
                },
          );
        },
      ),
    ],
  );

  /// Navigate to player with drop ID
  static void goToPlayer(BuildContext context, String dropId) {
    context.push('/player/$dropId');
  }

  /// Navigate to settings
  static void goToSettings(BuildContext context) {
    context.push(settings);
  }

  /// Navigate to category list
  static void goToCategory(BuildContext context, ContentCategory category) {
    context.push('/category/${category.name}');
  }

  /// Navigate to new drops list
  static void goToNewDrops(BuildContext context) {
    context.push(newDrops);
  }

  /// Navigate to temporal drops list
  static void goToTemporalDrops(BuildContext context) {
    context.push(temporalDrops);
  }

  /// Navigate to streaks page
  static void goToStreaks(BuildContext context) {
    context.push(streaks);
  }

  /// Navigate to tab by index
  static void goToTab(BuildContext context, int index) {
    final paths = [home, discover, request, profile];
    context.go(paths[index]);
  }
}
