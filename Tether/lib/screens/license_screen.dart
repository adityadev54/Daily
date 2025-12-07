import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/custom_card.dart';

class LicenseScreen extends StatelessWidget {
  const LicenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Licenses')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // App info header
          TetherCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    LucideIcons.link,
                    size: 32,
                    color: theme.scaffoldBackgroundColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tether',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '© 2025 Tether. All rights reserved.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Open Source Licenses header
          Text(
            'Open Source Licenses',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tether is built with the following open source packages:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),

          // License items
          _LicenseItem(
            name: 'Flutter',
            author: 'Google',
            license: 'BSD-3-Clause',
            description:
                'UI toolkit for building natively compiled applications',
          ),
          _LicenseItem(
            name: 'sqflite',
            author: 'tekartik',
            license: 'BSD-2-Clause',
            description: 'SQLite plugin for Flutter',
          ),
          _LicenseItem(
            name: 'Google ML Kit',
            author: 'Google',
            license: 'Apache-2.0',
            description: 'On-device machine learning for text recognition',
          ),
          _LicenseItem(
            name: 'flutter_local_notifications',
            author: 'Michael Bui',
            license: 'BSD-3-Clause',
            description: 'Cross-platform local notifications',
          ),
          _LicenseItem(
            name: 'Lucide Icons',
            author: 'Lucide Contributors',
            license: 'ISC',
            description: 'Beautiful & consistent icon toolkit',
          ),
          _LicenseItem(
            name: 'image_picker',
            author: 'Flutter Team',
            license: 'Apache-2.0',
            description: 'Image selection from gallery and camera',
          ),
          _LicenseItem(
            name: 'shared_preferences',
            author: 'Flutter Team',
            license: 'BSD-3-Clause',
            description: 'Persistent key-value storage',
          ),
          _LicenseItem(
            name: 'url_launcher',
            author: 'Flutter Team',
            license: 'BSD-3-Clause',
            description: 'Launch URLs in browser or apps',
          ),
          _LicenseItem(
            name: 'intl',
            author: 'Dart Team',
            license: 'BSD-3-Clause',
            description: 'Internationalization and localization',
          ),
          _LicenseItem(
            name: 'uuid',
            author: 'Yulian Kuncheff',
            license: 'MIT',
            description: 'RFC4122 UUID generator',
          ),

          const SizedBox(height: 24),

          // View all Flutter licenses
          GestureDetector(
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'Tether',
                applicationVersion: '1.0.0',
                applicationIcon: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    LucideIcons.link,
                    size: 48,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              );
            },
            child: TetherCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.fileText,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'View All Flutter Licenses',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _LicenseItem extends StatelessWidget {
  final String name;
  final String author;
  final String license;
  final String description;

  const _LicenseItem({
    required this.name,
    required this.author,
    required this.license,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TetherCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    license,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'by $author',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
