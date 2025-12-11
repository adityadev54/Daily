import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/supabase_service.dart';
import '../../data/providers/theme_provider.dart';
import 'whats_new_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../about/about_spera_screen.dart';

/// Admin email for access control
const String _adminEmail = 'appdev827@gmail.com';

/// Settings provider for app preferences
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class AppSettings {
  final bool notificationsEnabled;
  final bool autoPlayNext;
  final double playbackSpeed;
  final bool hapticFeedback;
  final bool showXpAnimations;
  final bool darkModeOnly; // Always dark for Spera
  final bool offlineMode;
  final int dailyGoalMinutes;

  const AppSettings({
    this.notificationsEnabled = true,
    this.autoPlayNext = true,
    this.playbackSpeed = 1.0,
    this.hapticFeedback = true,
    this.showXpAnimations = true,
    this.darkModeOnly = true,
    this.offlineMode = false,
    this.dailyGoalMinutes = 15,
  });

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? autoPlayNext,
    double? playbackSpeed,
    bool? hapticFeedback,
    bool? showXpAnimations,
    bool? darkModeOnly,
    bool? offlineMode,
    int? dailyGoalMinutes,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoPlayNext: autoPlayNext ?? this.autoPlayNext,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      showXpAnimations: showXpAnimations ?? this.showXpAnimations,
      darkModeOnly: darkModeOnly ?? this.darkModeOnly,
      offlineMode: offlineMode ?? this.offlineMode,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    _loadSettings();
    return const AppSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      notificationsEnabled: prefs.getBool('notificationsEnabled') ?? true,
      autoPlayNext: prefs.getBool('autoPlayNext') ?? true,
      playbackSpeed: prefs.getDouble('playbackSpeed') ?? 1.0,
      hapticFeedback: prefs.getBool('hapticFeedback') ?? true,
      showXpAnimations: prefs.getBool('showXpAnimations') ?? true,
      offlineMode: prefs.getBool('offlineMode') ?? false,
      dailyGoalMinutes: prefs.getInt('dailyGoalMinutes') ?? 15,
    );
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', state.notificationsEnabled);
    await prefs.setBool('autoPlayNext', state.autoPlayNext);
    await prefs.setDouble('playbackSpeed', state.playbackSpeed);
    await prefs.setBool('hapticFeedback', state.hapticFeedback);
    await prefs.setBool('showXpAnimations', state.showXpAnimations);
    await prefs.setBool('offlineMode', state.offlineMode);
    await prefs.setInt('dailyGoalMinutes', state.dailyGoalMinutes);
  }

  void setNotifications(bool value) {
    state = state.copyWith(notificationsEnabled: value);
    _saveSettings();
  }

  void setAutoPlayNext(bool value) {
    state = state.copyWith(autoPlayNext: value);
    _saveSettings();
  }

  void setPlaybackSpeed(double value) {
    state = state.copyWith(playbackSpeed: value);
    _saveSettings();
  }

  void setHapticFeedback(bool value) {
    state = state.copyWith(hapticFeedback: value);
    _saveSettings();
  }

  void setShowXpAnimations(bool value) {
    state = state.copyWith(showXpAnimations: value);
    _saveSettings();
  }

  void setOfflineMode(bool value) {
    state = state.copyWith(offlineMode: value);
    _saveSettings();
  }

  void setDailyGoal(int minutes) {
    state = state.copyWith(dailyGoalMinutes: minutes);
    _saveSettings();
  }
}

/// Settings Screen - Clean, professional design
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final currentEmail = SupabaseService.currentUser?.email;
    final isAdmin = currentEmail == _adminEmail;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(
            Iconsax.arrow_left_2_copy,
            size: 20,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: AppTypography.headingSmall.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          // Account Section
          _SectionHeader(title: 'Account'),
          _SettingsTile(
            icon: Iconsax.user,
            title: 'Profile',
            trailing: isAdmin
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ADMIN',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 9,
                      ),
                    ),
                  )
                : null,
            onTap: () {},
          ),

          const SizedBox(height: AppSpacing.lg),

          // Learning Section
          _SectionHeader(title: 'Learning'),
          _SettingsTile(
            icon: Iconsax.timer_1,
            title: 'Daily goal',
            value: '${settings.dailyGoalMinutes} min',
            onTap: () => _showDailyGoalDialog(context, ref),
          ),
          _SettingsTile(
            icon: Iconsax.forward,
            title: 'Playback speed',
            value: '${settings.playbackSpeed}x',
            onTap: () => _showPlaybackSpeedDialog(context, ref),
          ),
          _SettingsSwitch(
            icon: Iconsax.play,
            title: 'Auto-play next',
            value: settings.autoPlayNext,
            onChanged: settingsNotifier.setAutoPlayNext,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Preferences Section
          _SectionHeader(title: 'Preferences'),
          _SettingsTile(
            icon: Iconsax.moon,
            title: 'Appearance',
            value: _getThemeLabel(ref.watch(themeModeProvider)),
            onTap: () => _showThemeDialog(context, ref),
          ),
          _SettingsSwitch(
            icon: Iconsax.notification,
            title: 'Notifications',
            value: settings.notificationsEnabled,
            onChanged: settingsNotifier.setNotifications,
          ),
          _SettingsSwitch(
            icon: Iconsax.driver,
            title: 'Haptics',
            value: settings.hapticFeedback,
            onChanged: settingsNotifier.setHapticFeedback,
          ),
          _SettingsSwitch(
            icon: Iconsax.star_1,
            title: 'Progress animations',
            value: settings.showXpAnimations,
            onChanged: settingsNotifier.setShowXpAnimations,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Data Section
          _SectionHeader(title: 'Data'),
          _SettingsSwitch(
            icon: Iconsax.document_download,
            title: 'Offline mode',
            value: settings.offlineMode,
            onChanged: settingsNotifier.setOfflineMode,
          ),
          _SettingsTile(
            icon: Iconsax.trash,
            title: 'Clear cache',
            onTap: () => _showClearCacheDialog(context),
          ),

          const SizedBox(height: AppSpacing.lg),

          // About Section
          _SectionHeader(title: 'About'),
          _SettingsTile(
            icon: Iconsax.info_circle,
            title: 'About Spera',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutSperaScreen()),
            ),
          ),
          _SettingsTile(
            icon: Iconsax.lamp_charge,
            title: "What's New",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WhatsNewScreen()),
            ),
          ),
          _SettingsTile(
            icon: Iconsax.document,
            title: 'Terms of Service',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Iconsax.shield_tick,
            title: 'Privacy Policy',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Iconsax.message_question,
            title: 'Help & Support',
            onTap: () {},
          ),

          // Admin Section (if admin)
          if (isAdmin) ...[
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(title: 'Admin'),
            _SettingsTile(
              icon: Iconsax.setting_2,
              title: 'Dashboard',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Sign Out
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Sign Out',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Version
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              'Version 1.0.0',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showPlaybackSpeedDialog(BuildContext context, WidgetRef ref) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final currentSpeed = ref.read(settingsProvider).playbackSpeed;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Playback Speed',
                style: AppTypography.headingSmall.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ...speeds.map(
              (speed) => _SheetOption(
                title: '${speed}x',
                isSelected: speed == currentSpeed,
                onTap: () {
                  ref.read(settingsProvider.notifier).setPlaybackSpeed(speed);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDailyGoalDialog(BuildContext context, WidgetRef ref) {
    final goals = [5, 10, 15, 20, 30, 45, 60];
    final currentGoal = ref.read(settingsProvider).dailyGoalMinutes;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Daily Goal',
                style: AppTypography.headingSmall.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ...goals.map(
              (minutes) => _SheetOption(
                title: '$minutes min',
                isSelected: minutes == currentGoal,
                onTap: () {
                  ref.read(settingsProvider.notifier).setDailyGoal(minutes);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.read(themeModeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Appearance',
                style: AppTypography.headingSmall.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            _SheetOption(
              title: 'Dark',
              subtitle: 'Recommended',
              isSelected: currentTheme == ThemeMode.dark,
              onTap: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            _SheetOption(
              title: 'Light',
              isSelected: currentTheme == ThemeMode.light,
              onTap: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            _SheetOption(
              title: 'System',
              subtitle: 'Match device',
              isSelected: currentTheme == ThemeMode.system,
              onTap: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Clear Cache', style: AppTypography.headingSmall),
        content: Text(
          'This will remove all downloaded content. You\'ll need to download them again for offline use.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Cache cleared')));
            },
            child: Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ============================================
// SECTION HEADER
// ============================================

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.xs,
      ),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ============================================
// SETTINGS TILE (Navigation item)
// ============================================

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.value,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: 13,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
              if (value != null && value!.isNotEmpty) ...[
                Text(
                  value!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Icon(
                Iconsax.arrow_right_3_copy,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// SETTINGS SWITCH
// ============================================

class _SettingsSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitch({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: 6,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.accent,
              thumbColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? Colors.white
                    : AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// SHEET OPTION (for bottom sheets)
// ============================================

class _SheetOption extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _SheetOption({
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w400,
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Iconsax.tick_circle, size: 20, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
