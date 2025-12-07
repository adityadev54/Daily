import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/custom_card.dart';

class WhatsNewScreen extends StatelessWidget {
  const WhatsNewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("What's New")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Current version header
          TetherCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    LucideIcons.sparkles,
                    size: 28,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Version 1.0.0',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Initial Release',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Version 1.0.0 features
          _VersionSection(
            version: '1.0.0',
            date: 'December 2025',
            isLatest: true,
            features: const [
              _FeatureEntry(
                icon: LucideIcons.scan,
                title: 'Smart Receipt Scanning',
                description:
                    'Scan receipts with your camera and automatically extract key details using on-device OCR.',
                isNew: true,
              ),
              _FeatureEntry(
                icon: LucideIcons.shield,
                title: 'Warranty Tracking',
                description:
                    'Track warranty expiration dates and get notified 14 and 7 days before they expire.',
                isNew: true,
              ),
              _FeatureEntry(
                icon: LucideIcons.rotateCcw,
                title: 'Return Window Alerts',
                description:
                    'Never miss a return deadline with 3-day and 1-day reminders.',
                isNew: true,
              ),
              _FeatureEntry(
                icon: LucideIcons.search,
                title: 'Full-Text Search',
                description:
                    'Search through all your receipts by item name, store, or any extracted text.',
                isNew: true,
              ),
              _FeatureEntry(
                icon: LucideIcons.wrench,
                title: 'Part Finder Links',
                description:
                    'When warranties expire, easily find replacement parts on eBay and Amazon.',
                isNew: true,
              ),
              _FeatureEntry(
                icon: LucideIcons.moon,
                title: 'Dark Mode',
                description:
                    'Automatic dark mode support that follows your system settings.',
                isNew: true,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Coming soon section
          Text(
            'Coming Soon',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          _ComingSoonItem(
            icon: LucideIcons.cloud,
            title: 'Cloud Backup',
            description: 'Sync your receipts across devices',
          ),
          _ComingSoonItem(
            icon: LucideIcons.folderOpen,
            title: 'Smart Folders',
            description: 'Auto-organize receipts by store or category',
          ),
          _ComingSoonItem(
            icon: LucideIcons.share2,
            title: 'Export & Share',
            description: 'Export receipts as PDF or share directly',
          ),
          _ComingSoonItem(
            icon: LucideIcons.dollarSign,
            title: 'Spending Insights',
            description: 'Track spending patterns over time',
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _VersionSection extends StatelessWidget {
  final String version;
  final String date;
  final bool isLatest;
  final List<_FeatureEntry> features;

  const _VersionSection({
    required this.version,
    required this.date,
    required this.isLatest,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Version $version',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isLatest) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'LATEST',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.scaffoldBackgroundColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 16),
        ...features,
      ],
    );
  }
}

class _FeatureEntry extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isNew;

  const _FeatureEntry({
    required this.icon,
    required this.title,
    required this.description,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TetherCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'NEW',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 9,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ComingSoonItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TetherCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
