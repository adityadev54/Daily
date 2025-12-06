import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../data/models/meal.dart';
import '../../data/models/user_preferences.dart';
import '../../providers/ai_provider.dart';
import 'dart:convert';

class PersonalizeMealDialog extends StatefulWidget {
  final Meal meal;
  final UserPreferences? preferences;

  const PersonalizeMealDialog({
    super.key,
    required this.meal,
    this.preferences,
  });

  @override
  State<PersonalizeMealDialog> createState() => _PersonalizeMealDialogState();
}

class _PersonalizeMealDialogState extends State<PersonalizeMealDialog> {
  bool _isLoading = false;
  String? _error;
  Meal? _personalizedMeal;

  // Personalization options
  String _portionSize = 'same';
  bool _makeHealthier = false;
  bool _reduceTime = false;
  String _customRequest = '';

  final List<String> _selectedSubstitutions = [];

  final Map<String, List<String>> _commonSubstitutions = {
    'Make it dairy-free': ['milk', 'cheese', 'butter', 'cream', 'yogurt'],
    'Make it gluten-free': ['flour', 'bread', 'pasta', 'wheat'],
    'Make it vegetarian': ['chicken', 'beef', 'pork', 'fish', 'meat'],
    'Make it vegan': ['egg', 'honey', 'milk', 'cheese', 'butter'],
    'Reduce sodium': ['salt', 'soy sauce'],
    'Lower carbs': ['rice', 'pasta', 'bread', 'potato'],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.magic_star, color: Colors.purple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personalize Recipe',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.meal.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Iconsax.close_circle),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? _buildLoadingView(theme)
                : _personalizedMeal != null
                ? _buildResultView(theme, isDark)
                : _buildOptionsView(theme, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 20),
          Text(
            'AI is personalizing your recipe...',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a moment',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsView(ThemeData theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.warning_2, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Portion Size
        Text(
          'Portion Size',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildOptionChip(
              theme,
              isDark,
              'Smaller',
              'smaller',
              _portionSize,
              (v) => setState(() => _portionSize = v),
            ),
            const SizedBox(width: 8),
            _buildOptionChip(
              theme,
              isDark,
              'Same',
              'same',
              _portionSize,
              (v) => setState(() => _portionSize = v),
            ),
            const SizedBox(width: 8),
            _buildOptionChip(
              theme,
              isDark,
              'Larger',
              'larger',
              _portionSize,
              (v) => setState(() => _portionSize = v),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Quick Options
        Text(
          'Quick Options',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildToggleOption(
          theme,
          isDark,
          'Make it healthier',
          'Lower calories, more nutrients',
          Iconsax.health,
          _makeHealthier,
          (v) => setState(() => _makeHealthier = v),
        ),
        const SizedBox(height: 12),
        _buildToggleOption(
          theme,
          isDark,
          'Reduce prep time',
          'Simpler, faster cooking',
          Iconsax.timer_1,
          _reduceTime,
          (v) => setState(() => _reduceTime = v),
        ),
        const SizedBox(height: 24),

        // Substitutions
        Text(
          'Dietary Substitutions',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _commonSubstitutions.keys.map((sub) {
            final isSelected = _selectedSubstitutions.contains(sub);
            return FilterChip(
              label: Text(sub),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSubstitutions.add(sub);
                  } else {
                    _selectedSubstitutions.remove(sub);
                  }
                });
              },
              selectedColor: theme.colorScheme.primary.withOpacity(0.2),
              checkmarkColor: theme.colorScheme.primary,
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Custom Request
        Text(
          'Custom Request (optional)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          maxLines: 3,
          onChanged: (v) => _customRequest = v,
          decoration: InputDecoration(
            hintText: 'E.g., "Add more vegetables", "Make it spicier"...',
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Generate Button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Iconsax.magic_star),
            label: const Text('Personalize Recipe'),
            onPressed: _personalize,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.purple,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildResultView(ThemeData theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Success message
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Iconsax.tick_circle, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recipe Personalized!',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'Review the changes below',
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
        const SizedBox(height: 20),

        // Changes summary
        if (_personalizedMeal!.calories != widget.meal.calories ||
            _personalizedMeal!.prepTime != widget.meal.prepTime) ...[
          Text(
            'Changes',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildChangeRow(
            theme,
            isDark,
            'Calories',
            '${widget.meal.calories ?? "N/A"}',
            '${_personalizedMeal!.calories ?? "N/A"}',
          ),
          _buildChangeRow(
            theme,
            isDark,
            'Prep Time',
            '${widget.meal.prepTime ?? "N/A"} min',
            '${_personalizedMeal!.prepTime ?? "N/A"} min',
          ),
          if (_personalizedMeal!.protein != null)
            _buildChangeRow(
              theme,
              isDark,
              'Protein',
              '${widget.meal.protein?.toStringAsFixed(1) ?? "N/A"}g',
              '${_personalizedMeal!.protein?.toStringAsFixed(1) ?? "N/A"}g',
            ),
          const SizedBox(height: 20),
        ],

        // Updated ingredients
        Text(
          'Updated Ingredients',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _personalizedMeal!.ingredients ?? 'No ingredients',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 20),

        // Updated instructions
        Text(
          'Updated Instructions',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _personalizedMeal!.instructions ?? 'No instructions',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 24),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _personalizedMeal = null;
                    _error = null;
                  });
                },
                child: const Text('Try Again'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _personalizedMeal),
                child: const Text('Apply Changes'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildOptionChip(
    ThemeData theme,
    bool isDark,
    String label,
    String value,
    String currentValue,
    void Function(String) onSelect,
  ) {
    final isSelected = value == currentValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.15)
                : isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? theme.colorScheme.primary : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption(
    ThemeData theme,
    bool isDark,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    void Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildChangeRow(
    ThemeData theme,
    bool isDark,
    String label,
    String oldValue,
    String newValue,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text(
            oldValue,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Iconsax.arrow_right_3, size: 16),
          const SizedBox(width: 8),
          Text(
            newValue,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _personalize() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get AI Provider
      final aiProvider = context.read<AIProvider>();

      if (!aiProvider.hasApiKey) {
        throw Exception(
          'Please set up your API key in Profile → Chef AI first',
        );
      }

      // Build personalization prompt
      final prompt = _buildPersonalizationPrompt();

      // Call AI to personalize
      final result = await _makePersonalizationRequest(aiProvider, prompt);

      if (result != null) {
        setState(() {
          _personalizedMeal = result;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to personalize recipe');
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _buildPersonalizationPrompt() {
    final buffer = StringBuffer();
    buffer.writeln(
      'Personalize this recipe based on the following requirements:',
    );
    buffer.writeln();
    buffer.writeln('ORIGINAL RECIPE:');
    buffer.writeln('Name: ${widget.meal.name}');
    buffer.writeln('Description: ${widget.meal.description ?? "N/A"}');
    buffer.writeln('Calories: ${widget.meal.calories ?? "N/A"}');
    buffer.writeln('Prep Time: ${widget.meal.prepTime ?? "N/A"} minutes');
    buffer.writeln('Ingredients: ${widget.meal.ingredients ?? "N/A"}');
    buffer.writeln('Instructions: ${widget.meal.instructions ?? "N/A"}');
    buffer.writeln();
    buffer.writeln('PERSONALIZATION REQUIREMENTS:');

    // Portion size
    if (_portionSize == 'smaller') {
      buffer.writeln('- Reduce portion size by 25-30%');
    } else if (_portionSize == 'larger') {
      buffer.writeln('- Increase portion size by 25-30%');
    }

    // Quick options
    if (_makeHealthier) {
      buffer.writeln(
        '- Make it healthier: reduce calories, increase fiber/protein, reduce sugar/fat',
      );
    }
    if (_reduceTime) {
      buffer.writeln(
        '- Reduce preparation time: simplify steps, use quicker cooking methods',
      );
    }

    // Substitutions
    for (final sub in _selectedSubstitutions) {
      final items = _commonSubstitutions[sub] ?? [];
      buffer.writeln('- $sub: substitute ingredients like ${items.join(", ")}');
    }

    // Custom request
    if (_customRequest.isNotEmpty) {
      buffer.writeln('- Custom: $_customRequest');
    }

    // User preferences
    if (widget.preferences != null) {
      if (widget.preferences!.allergies.isNotEmpty) {
        buffer.writeln(
          '- MUST AVOID (allergies): ${widget.preferences!.allergies.join(", ")}',
        );
      }
      if (widget.preferences!.dislikedIngredients.isNotEmpty) {
        buffer.writeln(
          '- Avoid if possible: ${widget.preferences!.dislikedIngredients.join(", ")}',
        );
      }
    }

    buffer.writeln();
    buffer.writeln('Respond with ONLY a valid JSON object (no other text):');
    buffer.writeln('{');
    buffer.writeln('  "name": "Updated Recipe Name",');
    buffer.writeln('  "description": "Updated description",');
    buffer.writeln('  "calories": 350,');
    buffer.writeln('  "prep_time": 20,');
    buffer.writeln('  "protein": 25.0,');
    buffer.writeln('  "carbs": 30.0,');
    buffer.writeln('  "fat": 12.0,');
    buffer.writeln('  "fiber": 5.0,');
    buffer.writeln(
      '  "ingredients": "ingredient 1, ingredient 2, ingredient 3",',
    );
    buffer.writeln('  "instructions": "Step 1... Step 2... Step 3..."');
    buffer.writeln('}');

    return buffer.toString();
  }

  Future<Meal?> _makePersonalizationRequest(
    AIProvider aiProvider,
    String prompt,
  ) async {
    try {
      final response = await aiProvider.sendPrompt(prompt);

      if (response == null) return null;

      // Parse the JSON response
      final startIndex = response.indexOf('{');
      final endIndex = response.lastIndexOf('}');

      if (startIndex == -1 || endIndex == -1) return null;

      final jsonStr = response.substring(startIndex, endIndex + 1);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Create updated meal preserving original ID and other fields
      return widget.meal.copyWith(
        name: json['name'] as String? ?? widget.meal.name,
        description: json['description'] as String? ?? widget.meal.description,
        calories: json['calories'] as int? ?? widget.meal.calories,
        prepTime: json['prep_time'] as int? ?? widget.meal.prepTime,
        protein: (json['protein'] as num?)?.toDouble() ?? widget.meal.protein,
        carbs: (json['carbs'] as num?)?.toDouble() ?? widget.meal.carbs,
        fat: (json['fat'] as num?)?.toDouble() ?? widget.meal.fat,
        fiber: (json['fiber'] as num?)?.toDouble() ?? widget.meal.fiber,
        ingredients: json['ingredients'] as String? ?? widget.meal.ingredients,
        instructions:
            json['instructions'] as String? ?? widget.meal.instructions,
      );
    } catch (e) {
      debugPrint('Error parsing AI response: $e');
      return null;
    }
  }
}
