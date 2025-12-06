import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/meal.dart';
import '../../data/repositories/meal_repository.dart';
import '../../services/image_service.dart';

class EditMealScreen extends StatefulWidget {
  final Meal meal;

  const EditMealScreen({super.key, required this.meal});

  @override
  State<EditMealScreen> createState() => _EditMealScreenState();
}

class _EditMealScreenState extends State<EditMealScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _ingredientsController;
  late TextEditingController _instructionsController;
  late TextEditingController _caloriesController;
  late TextEditingController _prepTimeController;
  late TextEditingController _cookTimeController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _fiberController;
  late TextEditingController _sugarController;
  late TextEditingController _servingsController;
  late TextEditingController _imageUrlController;

  String _selectedMealType = 'dinner';
  String _selectedDifficulty = 'Medium';
  String? _selectedCuisine;
  String? _selectedDietType;

  bool _isSaving = false;

  final List<String> _mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
  final List<String> _difficulties = ['Easy', 'Medium', 'Hard'];
  final List<String> _cuisines = [
    'American',
    'Asian',
    'Chinese',
    'French',
    'Greek',
    'Indian',
    'International',
    'Italian',
    'Japanese',
    'Korean',
    'Mediterranean',
    'Mexican',
    'Middle Eastern',
    'Thai',
    'Vietnamese',
  ];
  final List<String> _dietTypes = [
    'None',
    'Vegetarian',
    'Vegan',
    'Keto',
    'Paleo',
    'Gluten-Free',
    'Dairy-Free',
    'Low-Carb',
  ];

  @override
  void initState() {
    super.initState();
    final meal = widget.meal;
    _nameController = TextEditingController(text: meal.name);
    _descriptionController = TextEditingController(
      text: meal.description ?? '',
    );
    _ingredientsController = TextEditingController(
      text: meal.ingredients ?? '',
    );
    _instructionsController = TextEditingController(
      text: meal.instructions ?? '',
    );
    _caloriesController = TextEditingController(
      text: meal.calories?.toString() ?? '',
    );
    _prepTimeController = TextEditingController(
      text: meal.prepTime?.toString() ?? '',
    );
    _cookTimeController = TextEditingController(
      text: meal.cookTime?.toString() ?? '',
    );
    _proteinController = TextEditingController(
      text: meal.protein?.toString() ?? '',
    );
    _carbsController = TextEditingController(
      text: meal.carbs?.toString() ?? '',
    );
    _fatController = TextEditingController(text: meal.fat?.toString() ?? '');
    _fiberController = TextEditingController(
      text: meal.fiber?.toString() ?? '',
    );
    _sugarController = TextEditingController(
      text: meal.sugar?.toString() ?? '',
    );
    _servingsController = TextEditingController(
      text: meal.servings?.toString() ?? '1',
    );
    _imageUrlController = TextEditingController(text: meal.imageUrl ?? '');
    _selectedMealType = meal.mealType;
    _selectedDifficulty = _difficulties.contains(meal.difficulty)
        ? meal.difficulty!
        : 'Medium';
    // Handle cuisine that might not be in the list
    _selectedCuisine =
        (meal.cuisine != null && _cuisines.contains(meal.cuisine))
        ? meal.cuisine
        : null;
    // Handle diet type that might not be in the list
    _selectedDietType =
        (meal.dietType != null && _dietTypes.contains(meal.dietType))
        ? meal.dietType
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    _caloriesController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _sugarController.dispose();
    _servingsController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updatedMeal = Meal(
        id: widget.meal.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        calories: int.tryParse(_caloriesController.text),
        prepTime: int.tryParse(_prepTimeController.text),
        cookTime: int.tryParse(_cookTimeController.text),
        difficulty: _selectedDifficulty,
        mealType: _selectedMealType,
        cuisine: _selectedCuisine,
        dietType: _selectedDietType,
        ingredients: _ingredientsController.text.trim(),
        instructions: _instructionsController.text.trim(),
        protein: double.tryParse(_proteinController.text),
        carbs: double.tryParse(_carbsController.text),
        fat: double.tryParse(_fatController.text),
        fiber: double.tryParse(_fiberController.text),
        sugar: double.tryParse(_sugarController.text),
        servings: int.tryParse(_servingsController.text) ?? 1,
      );

      // Update in database if it has an ID
      if (updatedMeal.id != null) {
        final repo = MealRepository();
        await repo.updateMeal(updatedMeal);
      }

      if (mounted) {
        Navigator.pop(context, updatedMeal);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving meal: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Recipe'),
        actions: [
          TextButton.icon(
            icon: _isSaving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : const Icon(Iconsax.tick_circle, size: 20),
            label: const Text('Save'),
            onPressed: _isSaving ? null : _saveMeal,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Basic Info Section
            _buildSectionHeader(
              theme,
              'Basic Information',
              Iconsax.info_circle,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameController,
              label: 'Recipe Name',
              hint: 'Enter recipe name',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a recipe name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Brief description of the dish',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildImageSection(theme),
            const SizedBox(height: 24),

            // Type & Category Section
            _buildSectionHeader(theme, 'Category', Iconsax.category),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Meal Type',
                    value: _selectedMealType,
                    items: _mealTypes,
                    onChanged: (v) => setState(() => _selectedMealType = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'Difficulty',
                    value: _selectedDifficulty,
                    items: _difficulties,
                    onChanged: (v) => setState(() => _selectedDifficulty = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Cuisine',
                    value: _selectedCuisine,
                    items: _cuisines,
                    onChanged: (v) => setState(() => _selectedCuisine = v),
                    nullable: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'Diet Type',
                    value: _selectedDietType,
                    items: _dietTypes,
                    onChanged: (v) => setState(() => _selectedDietType = v),
                    nullable: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Time Section
            _buildSectionHeader(theme, 'Time', Iconsax.timer_1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _prepTimeController,
                    label: 'Prep Time (min)',
                    hint: '15',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _cookTimeController,
                    label: 'Cook Time (min)',
                    hint: '30',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _servingsController,
                    label: 'Servings',
                    hint: '4',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Nutrition Section
            _buildSectionHeader(
              theme,
              'Nutrition per Serving',
              Iconsax.chart_2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _caloriesController,
                    label: 'Calories',
                    hint: '350',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _proteinController,
                    label: 'Protein (g)',
                    hint: '25',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _carbsController,
                    label: 'Carbs (g)',
                    hint: '40',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _fatController,
                    label: 'Fat (g)',
                    hint: '15',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _fiberController,
                    label: 'Fiber (g)',
                    hint: '5',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _sugarController,
                    label: 'Sugar (g)',
                    hint: '8',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Ingredients Section
            _buildSectionHeader(theme, 'Ingredients', Iconsax.shopping_bag),
            const SizedBox(height: 8),
            Text(
              'Separate ingredients with commas',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _ingredientsController,
              label: 'Ingredients',
              hint: '200g chicken, 1 tbsp oil, 2 cloves garlic...',
              maxLines: 5,
            ),
            const SizedBox(height: 24),

            // Instructions Section
            _buildSectionHeader(theme, 'Instructions', Iconsax.book_1),
            const SizedBox(height: 8),
            Text(
              'Write each step on a new line',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _instructionsController,
              label: 'Instructions',
              hint: 'Step 1: Preheat oven...\nStep 2: Mix ingredients...',
              maxLines: 8,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final hasImage = _imageUrlController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Iconsax.image, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Recipe Image',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Image preview or placeholder
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
            ),
          ),
          child: hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: _imageUrlController.text,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Iconsax.image,
                                size: 40,
                                color: theme.colorScheme.secondary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Failed to load image',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Remove button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _imageUrlController.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Iconsax.close_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.image,
                        size: 40,
                        color: theme.colorScheme.secondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No image selected',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 12),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showImageSearchDialog(theme),
                icon: const Icon(Iconsax.search_normal, size: 18),
                label: const Text('Search Images'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _autoFindImage(),
                icon: const Icon(Iconsax.magic_star, size: 18),
                label: const Text('Auto Find'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _autoFindImage() async {
    final recipeName = _nameController.text.trim();
    if (recipeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a recipe name first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final imageService = ImageService();
      final imageUrl = await imageService.getFoodImage(recipeName);

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (imageUrl != null) {
          setState(() {
            _imageUrlController.text = imageUrl;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not find an image. Try searching manually.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showImageSearchDialog(ThemeData theme) async {
    final searchController = TextEditingController(
      text: _nameController.text.trim(),
    );
    List<String> searchResults = [];
    bool isSearching = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = theme.brightness == Brightness.dark;

          Future<void> performSearch() async {
            if (searchController.text.trim().isEmpty) return;

            setDialogState(() => isSearching = true);

            try {
              final imageService = ImageService();
              final results = await imageService.searchFoodImages(
                searchController.text.trim(),
                count: 12,
              );
              setDialogState(() {
                searchResults = results;
                isSearching = false;
              });
            } catch (e) {
              setDialogState(() => isSearching = false);
            }
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: isDark ? Colors.black : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search Food Images',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Search for free food images from Pexels',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Search bar
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                hintText: 'Search for food images...',
                                prefixIcon: const Icon(Iconsax.search_normal),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (_) => performSearch(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: isSearching ? null : performSearch,
                            child: isSearching
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Search'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Results
                Expanded(
                  child: searchResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Iconsax.search_normal,
                                size: 48,
                                color: theme.colorScheme.secondary.withOpacity(
                                  0.3,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isSearching
                                    ? 'Searching...'
                                    : 'Search for images above',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.2,
                              ),
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final imageUrl = searchResults[index];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _imageUrlController.text = imageUrl;
                                });
                                Navigator.pop(ctx);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.black12,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          color: isDark
                                              ? Colors.white10
                                              : Colors.grey[200],
                                          child: const Icon(Iconsax.image),
                                        ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Quick suggestions
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick searches:',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            [
                                  'Pasta',
                                  'Salad',
                                  'Chicken',
                                  'Soup',
                                  'Breakfast',
                                  'Dessert',
                                ]
                                .map(
                                  (suggestion) => ActionChip(
                                    label: Text(suggestion),
                                    onPressed: () {
                                      searchController.text = suggestion;
                                      performSearch();
                                    },
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool nullable = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
          ),
        ),
      ),
      items: [
        if (nullable)
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Not specified'),
          ),
        ...items.map(
          (item) => DropdownMenuItem(
            value: item,
            child: Text(item[0].toUpperCase() + item.substring(1)),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
