import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _feedbackController = TextEditingController();
  String _selectedCategory = 'General';
  int _rating = 0;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'General', 'icon': Iconsax.message_question},
    {'name': 'Bug Report', 'icon': Iconsax.warning_2},
    {'name': 'Feature Request', 'icon': Iconsax.lamp_charge},
    {'name': 'Meal Suggestions', 'icon': Iconsax.reserve},
    {'name': 'AI Quality', 'icon': Iconsax.magic_star},
    {'name': 'UI/UX', 'icon': Iconsax.paintbucket},
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Send Feedback')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white12
                      : theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Iconsax.message_favorite,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'We value your feedback!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Help us improve by sharing your thoughts',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Rating Section
            Text(
              'How are you enjoying the app?',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            _buildRatingSelector(context, theme, isDark),
            const SizedBox(height: 28),

            // Category Selection
            Text('Feedback Category', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            _buildCategorySelector(context, theme, isDark),
            const SizedBox(height: 28),

            // Feedback Text
            Text('Your Feedback', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            TextField(
              controller: _feedbackController,
              maxLines: 6,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: _getHintText(),
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Quick Feedback Chips
            Text('Quick feedback:', style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _getQuickFeedbackOptions().map((option) {
                return ActionChip(
                  label: Text(option, style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    final current = _feedbackController.text;
                    _feedbackController.text = current.isEmpty
                        ? option
                        : '$current\n$option';
                    _feedbackController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _feedbackController.text.length),
                    );
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _canSubmit() ? _submitFeedback : null,
                icon: _isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Iconsax.send_1),
                label: Text(_isSubmitting ? 'Sending...' : 'Submit Feedback'),
              ),
            ),
            const SizedBox(height: 16),

            // Privacy note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.03)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.shield_tick,
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your feedback is stored locally and helps improve the app',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontSize: 11,
                      ),
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

  Widget _buildRatingSelector(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isSelected = _rating >= starIndex;

        return GestureDetector(
          onTap: () => setState(() => _rating = starIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? Iconsax.star1 : Iconsax.star,
                size: 36,
                color: isSelected
                    ? Colors.amber
                    : (isDark ? Colors.white24 : Colors.black26),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCategorySelector(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: _categories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          final isSelected = _selectedCategory == category['name'];
          final isLast = index == _categories.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: () =>
                    setState(() => _selectedCategory = category['name']),
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? const Radius.circular(12) : Radius.zero,
                  bottom: isLast ? const Radius.circular(12) : Radius.zero,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                              ? theme.colorScheme.primary.withOpacity(0.12)
                              : theme.colorScheme.primary.withOpacity(0.06))
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withOpacity(0.15)
                              : (isDark ? Colors.white10 : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          category['icon'],
                          size: 18,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          category['name'],
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : (isDark ? Colors.white12 : Colors.grey[200]),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : (isDark ? Colors.white24 : Colors.grey[300]!),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                size: 14,
                                color: theme.colorScheme.onPrimary,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 58,
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withOpacity(0.06),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _getHintText() {
    switch (_selectedCategory) {
      case 'Bug Report':
        return 'Please describe the issue you encountered...';
      case 'Feature Request':
        return 'What feature would you like to see?';
      case 'Meal Suggestions':
        return 'Any meal ideas or recipe improvements?';
      case 'AI Quality':
        return 'How can we improve AI-generated meals?';
      case 'UI/UX':
        return 'Any design or usability suggestions?';
      default:
        return 'Share your thoughts with us...';
    }
  }

  List<String> _getQuickFeedbackOptions() {
    switch (_selectedCategory) {
      case 'Bug Report':
        return ['App crashes', 'Slow loading', 'Data not saving', 'UI glitch'];
      case 'Feature Request':
        return [
          'Shopping list',
          'Recipe import',
          'Meal sharing',
          'Nutrition tracking',
        ];
      case 'Meal Suggestions':
        return [
          'More variety',
          'Healthier options',
          'Quick meals',
          'Budget meals',
        ];
      case 'AI Quality':
        return [
          'Better recipes',
          'More accurate nutrition',
          'Respect preferences',
          'Faster generation',
        ];
      case 'UI/UX':
        return [
          'Simpler navigation',
          'Better colors',
          'Larger text',
          'More icons',
        ];
      default:
        return ['Love it!', 'Easy to use', 'Great recipes', 'Needs work'];
    }
  }

  bool _canSubmit() {
    return !_isSubmitting &&
        _rating > 0 &&
        _feedbackController.text.trim().length >= 10;
  }

  Future<void> _submitFeedback() async {
    if (!_canSubmit()) return;

    setState(() => _isSubmitting = true);

    // Simulate API call (in real app, save to database or send to server)
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isSubmitting = false);

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.tick_circle,
              color: Colors.green,
              size: 40,
            ),
          ),
          title: const Text('Thank You!'),
          content: const Text(
            'Your feedback has been received. We appreciate you taking the time to help us improve!',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }
}
