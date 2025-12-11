import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';

/// About Spera - Minimal, personal "why I built this" screen
class AboutSperaScreen extends StatefulWidget {
  const AboutSperaScreen({super.key});

  @override
  State<AboutSperaScreen> createState() => _AboutSperaScreenState();
}

class _AboutSperaScreenState extends State<AboutSperaScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'v${packageInfo.version}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Minimal app bar
          SliverAppBar(
            expandedHeight: 56,
            floating: true,
            pinned: true,
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
              'About',
              style: AppTypography.headingSmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            centerTitle: false,
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),

                  // Logo and name
                  const _LogoSection(),
                  const SizedBox(height: AppSpacing.xxl),

                  // The story
                  const _StorySection(),
                  const SizedBox(height: AppSpacing.xxl),

                  // How it works (simple)
                  const _HowItWorksSection(),
                  const SizedBox(height: AppSpacing.xxl),

                  // Open source / transparency
                  const _TransparencySection(),
                  const SizedBox(height: AppSpacing.xxl),

                  // Footer
                  _FooterSection(appVersion: _appVersion),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// LOGO SECTION
// ============================================

class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    return Center(
          child: Column(
            children: [
              // Simple logo
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Iconsax.book_1,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Name
              Text(
                'Spera',
                style: AppTypography.displayMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Knowledge, simplified',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

// ============================================
// STORY SECTION - The "why"
// ============================================

class _StorySection extends StatelessWidget {
  const _StorySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Text(
          'Why we built this',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // The story - conversational, authentic
        Text(
          "We love learning. But we hate how hard it is to find quality content that respects our time.",
          style: AppTypography.headingSmall.copyWith(
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        Text(
          "Most educational content is either too shallow (clickbait), too long (2-hour podcasts), or locked behind paywalls. We wanted something different—depth without the fluff, available to everyone.",
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            height: 1.7,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        Text(
          "Spera is our attempt to make knowledge more accessible. Short, focused audio studies that actually teach you something—for free.",
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            height: 1.7,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Team signature
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Iconsax.people,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The Spera Team',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Curious minds, building together',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }
}

// ============================================
// HOW IT WORKS - Simple explanation
// ============================================

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How it works',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Simple steps
        _buildStep(
          number: '1',
          title: 'Research',
          description:
              'We find quality sources—books, papers, expert talks—on topics that matter.',
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildStep(
          number: '2',
          title: 'Synthesize',
          description:
              'Using NotebookLM, we distill hours of content into focused 10-15 minute studies.',
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildStep(
          number: '3',
          title: 'Share',
          description:
              'You get the insights, with sources cited, ready to apply.',
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  Widget _buildStep({
    required String number,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                number,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// TRANSPARENCY SECTION
// ============================================

class _TransparencySection extends StatelessWidget {
  const _TransparencySection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.star_1, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Accessible by Design',
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "Core features are free—browse, listen, learn. We believe quality knowledge should be accessible to everyone.",
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            "Premium features for power users help us keep the lights on and continue creating quality content. All content is properly sourced and attributed.",
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }
}

// ============================================
// FOOTER
// ============================================

class _FooterSection extends StatelessWidget {
  final String appVersion;

  const _FooterSection({required this.appVersion});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Links
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLink(
              icon: Iconsax.message_question,
              label: 'Feedback',
              onTap: () => _launchEmail(),
            ),
            const SizedBox(width: AppSpacing.lg),
            _buildLink(
              icon: Iconsax.document_text,
              label: 'Privacy',
              onTap: () => _launchPrivacy(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // Version and copyright
        Text(
          appVersion,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textDisabled,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Made with ☕ in pursuit of learning',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 400.ms);
  }

  Widget _buildLink({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _launchEmail() async {
    final uri = Uri.parse('mailto:feedback@spera.app?subject=Spera Feedback');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchPrivacy() async {
    final uri = Uri.parse('https://spera.app/privacy');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
