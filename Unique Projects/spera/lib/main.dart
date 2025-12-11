import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/constants/app_router.dart';
import 'core/services/supabase_service.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseService.initialize();

  runApp(const ProviderScope(child: SperaApp()));
}

/// Spera - Knowledge Deployment System
///
/// A request-driven education and real-world problem-solving platform
/// where users unlock short, high-impact audio/video knowledge drops.
class SperaApp extends ConsumerStatefulWidget {
  const SperaApp({super.key});

  @override
  ConsumerState<SperaApp> createState() => _SperaAppState();
}

class _SperaAppState extends ConsumerState<SperaApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter(ref);
  }

  void _updateSystemUI(ThemeMode themeMode) {
    final isDark = themeMode == ThemeMode.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state to trigger rebuilds on auth changes
    ref.listen(authProvider, (previous, next) {
      // Refresh router when auth state changes
      _router.refresh();
    });

    // Watch theme mode
    final themeMode = ref.watch(themeModeProvider);

    // Update system UI when theme changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSystemUI(themeMode);
    });

    return MaterialApp.router(
      title: 'Spera',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Router
      routerConfig: _router,
    );
  }
}
