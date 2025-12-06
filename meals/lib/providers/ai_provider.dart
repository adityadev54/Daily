import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../data/models/user_api_key.dart';
import '../data/repositories/auth_repository.dart';

class AIProvider extends ChangeNotifier {
  final AIService _aiService = AIService();
  final AuthRepository _authRepo = AuthRepository();

  // Shared API key for subscribers (configure this securely)
  static const String _sharedApiKey = 'YOUR_SHARED_API_KEY_HERE';
  static const AIProviderType _sharedProviderType = AIProviderType.openRouter;

  int? _currentUserId;
  UserApiKey? _userApiKey;
  bool _isSubscriber = false;

  // Multi-key support (for subscribers)
  List<ProviderApiKey> _allApiKeys = [];
  AIProviderType? _activeProvider;

  bool _isGenerating = false;
  List<GeneratedMeal> _generatedMeals = [];
  String? _error;

  bool get isGenerating => _isGenerating;
  List<GeneratedMeal> get generatedMeals => _generatedMeals;
  String? get error => _error;
  bool get hasGeneratedMeals => _generatedMeals.isNotEmpty;

  // API key access checks
  bool get hasOwnApiKey {
    if (_isSubscriber && _allApiKeys.isNotEmpty) return true;
    return _userApiKey?.hasOwnKey ?? false;
  }

  bool get isUsingSharedKey => _userApiKey?.useSharedKey ?? false;
  bool get hasApiKey => hasOwnApiKey || (isUsingSharedKey && _isSubscriber);
  bool get isSubscriber => _isSubscriber;
  UserApiKey? get userApiKey => _userApiKey;

  // Multi-key getters
  List<ProviderApiKey> get allApiKeys => _allApiKeys;
  int get apiKeyCount => _allApiKeys.length;

  /// Get the current provider being used
  AIProviderType? get currentProviderType {
    if (_isSubscriber && _activeProvider != null) return _activeProvider;
    return _userApiKey?.aiProvider;
  }

  String get currentProviderName =>
      currentProviderType?.displayName ?? 'Not set';

  /// Get list of providers that have keys configured
  List<AIProviderType> get configuredProviders =>
      _allApiKeys.map((k) => k.provider).toList();

  /// Check if a specific provider has a key configured
  bool hasKeyForProvider(AIProviderType provider) =>
      _allApiKeys.any((k) => k.provider == provider);

  /// Initialize provider for a specific user
  Future<void> initForUser(int userId, {bool isSubscriber = false}) async {
    _currentUserId = userId;
    _isSubscriber = isSubscriber;
    await _loadUserApiKey();
    if (_isSubscriber) {
      await _loadAllApiKeys();
    }
  }

  /// Load user's API key settings from database
  Future<void> _loadUserApiKey() async {
    if (_currentUserId == null) return;

    _userApiKey = await _authRepo.getUserApiKey(_currentUserId!);
    _activeProvider = _userApiKey?.activeProviderType;
    _updateServiceApiKey();
    notifyListeners();
  }

  /// Load all API keys for subscriber
  Future<void> _loadAllApiKeys() async {
    if (_currentUserId == null) return;

    _allApiKeys = await _authRepo.getAllUserApiKeys(_currentUserId!);

    // Set active provider if not set but we have keys
    if (_activeProvider == null && _allApiKeys.isNotEmpty) {
      _activeProvider = _allApiKeys.first.provider;
    }

    _updateServiceApiKey();
    notifyListeners();
  }

  /// Update the AI service with the appropriate API key and provider
  void _updateServiceApiKey() {
    // For subscribers with multi-key support
    if (_isSubscriber && _allApiKeys.isNotEmpty && _activeProvider != null) {
      final activeKey = _allApiKeys.firstWhere(
        (k) => k.provider == _activeProvider,
        orElse: () => _allApiKeys.first,
      );
      _aiService.setApiKey(activeKey.apiKey);
      _aiService.setProvider(activeKey.provider);
      return;
    }

    // Legacy single-key support
    if (_userApiKey?.hasOwnKey == true && _userApiKey?.aiProvider != null) {
      _aiService.setApiKey(_userApiKey!.apiKey!);
      _aiService.setProvider(_userApiKey!.aiProvider!);
    } else if (_userApiKey?.useSharedKey == true && _isSubscriber) {
      _aiService.setApiKey(_sharedApiKey);
      _aiService.setProvider(_sharedProviderType);
    } else {
      _aiService.setApiKey('');
    }
  }

  /// Set user's own API key with auto-detected or specified provider
  /// For non-subscribers: single key mode
  /// For subscribers: adds to multi-key collection
  Future<void> setApiKey(String apiKey, {AIProviderType? provider}) async {
    if (_currentUserId == null) return;

    // Auto-detect provider from key if not specified
    final detectedProvider =
        provider ??
        AIProviderExtension.detectFromKey(apiKey) ??
        AIProviderType.openRouter;

    if (_isSubscriber) {
      // Multi-key mode for subscribers
      final now = DateTime.now();
      final newKey = ProviderApiKey(
        userId: _currentUserId!,
        provider: detectedProvider,
        apiKey: apiKey,
        createdAt: now,
        updatedAt: now,
      );

      await _authRepo.saveProviderApiKey(newKey);
      await _loadAllApiKeys();

      // Set as active if no active provider
      if (_activeProvider == null) {
        await switchProvider(detectedProvider);
      }
    } else {
      // Single-key mode for non-subscribers
      final now = DateTime.now();
      final newApiKey = UserApiKey(
        userId: _currentUserId!,
        apiKey: apiKey,
        provider: detectedProvider.name,
        useSharedKey: _userApiKey?.useSharedKey ?? false,
        createdAt: _userApiKey?.createdAt ?? now,
        updatedAt: now,
      );

      await _authRepo.saveUserApiKey(newApiKey);
      _userApiKey = newApiKey;
      _updateServiceApiKey();
    }

    _error = null;
    notifyListeners();
  }

  /// Remove user's API key
  /// For non-subscribers: removes single key
  /// For subscribers: removes specific provider's key
  Future<void> removeApiKey({AIProviderType? provider}) async {
    if (_currentUserId == null) return;

    if (_isSubscriber && provider != null) {
      // Remove specific provider key
      await _authRepo.removeProviderApiKey(_currentUserId!, provider);
      await _loadAllApiKeys();

      // Switch to another provider if we removed the active one
      if (_activeProvider == provider && _allApiKeys.isNotEmpty) {
        await switchProvider(_allApiKeys.first.provider);
      } else if (_allApiKeys.isEmpty) {
        _activeProvider = null;
        _updateServiceApiKey();
      }
    } else {
      // Legacy single-key removal
      await _authRepo.removeUserApiKey(_currentUserId!);
      _userApiKey = _userApiKey?.copyWith(
        apiKey: null,
        provider: null,
        updatedAt: DateTime.now(),
      );
      _updateServiceApiKey();
    }

    notifyListeners();
  }

  /// Switch to a different provider (for subscribers with multiple keys)
  Future<void> switchProvider(AIProviderType provider) async {
    if (_currentUserId == null) return;

    // Check if we have a key for this provider
    if (!hasKeyForProvider(provider)) {
      _error = 'No API key configured for ${provider.displayName}';
      notifyListeners();
      return;
    }

    _activeProvider = provider;
    await _authRepo.setActiveProvider(_currentUserId!, provider);
    _updateServiceApiKey();
    _error = null;
    notifyListeners();
  }

  /// Toggle use of shared API key (for subscribers only)
  Future<void> toggleUseSharedKey(bool useShared) async {
    if (_currentUserId == null || !_isSubscriber) return;

    await _authRepo.toggleUseSharedKey(_currentUserId!, useShared);

    final now = DateTime.now();
    if (_userApiKey != null) {
      _userApiKey = _userApiKey!.copyWith(
        useSharedKey: useShared,
        updatedAt: now,
      );
    } else {
      _userApiKey = UserApiKey(
        userId: _currentUserId!,
        useSharedKey: useShared,
        createdAt: now,
        updatedAt: now,
      );
    }

    _updateServiceApiKey();
    notifyListeners();
  }

  /// Update subscriber status
  void setSubscriberStatus(bool isSubscriber) {
    _isSubscriber = isSubscriber;
    if (isSubscriber && _currentUserId != null) {
      _loadAllApiKeys();
    }
    _updateServiceApiKey();
    notifyListeners();
  }

  /// Discover new meals based on user preferences
  Future<List<GeneratedMeal>> discoverMeals({
    required String dietType,
    required List<String> allergies,
    required List<String> cuisinePreferences,
    int householdSize = 1,
    String cookingExperience = 'Intermediate',
    List<String> nutritionGoals = const [],
    List<String> dislikedIngredients = const [],
    int count = 5,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      _generatedMeals = await _aiService.discoverMeals(
        dietType: dietType,
        allergies: allergies,
        cuisinePreferences: cuisinePreferences,
        householdSize: householdSize,
        cookingExperience: cookingExperience,
        nutritionGoals: nutritionGoals,
        dislikedIngredients: dislikedIngredients,
        count: count,
      );

      if (_generatedMeals.isEmpty) {
        _error = 'Could not generate meals. Please try again.';
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _generatedMeals = [];
    }

    _isGenerating = false;
    notifyListeners();
    return _generatedMeals;
  }

  /// Discover meals for a specific meal type
  Future<List<GeneratedMeal>> discoverMealsByType({
    required String mealType,
    required String dietType,
    required List<String> allergies,
    required List<String> cuisinePreferences,
    int householdSize = 1,
    String cookingExperience = 'Intermediate',
    List<String> nutritionGoals = const [],
    List<String> dislikedIngredients = const [],
    int count = 3,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      _generatedMeals = await _aiService.discoverMealsByType(
        mealType: mealType,
        dietType: dietType,
        allergies: allergies,
        cuisinePreferences: cuisinePreferences,
        householdSize: householdSize,
        cookingExperience: cookingExperience,
        nutritionGoals: nutritionGoals,
        dislikedIngredients: dislikedIngredients,
        count: count,
      );

      if (_generatedMeals.isEmpty) {
        _error = 'Could not generate meals. Please try again.';
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _generatedMeals = [];
    }

    _isGenerating = false;
    notifyListeners();
    return _generatedMeals;
  }

  /// Discover meals with a custom prompt
  Future<List<GeneratedMeal>> discoverMealsWithPrompt({
    required String prompt,
    required String dietType,
    required List<String> allergies,
    int householdSize = 1,
    int count = 3,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      _generatedMeals = await _aiService.discoverMealsWithPrompt(
        prompt: prompt,
        dietType: dietType,
        allergies: allergies,
        householdSize: householdSize,
        count: count,
      );

      if (_generatedMeals.isEmpty) {
        _error = 'Could not generate meals. Please try again.';
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _generatedMeals = [];
    }

    _isGenerating = false;
    notifyListeners();
    return _generatedMeals;
  }

  void clearGeneratedMeals() {
    _generatedMeals = [];
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Send a raw prompt to the AI and get response (for personalization, etc.)
  Future<String?> sendPrompt(String prompt) async {
    if (!hasApiKey) return null;
    try {
      return await _aiService.sendRawPrompt(prompt);
    } catch (e) {
      debugPrint('AIProvider sendPrompt error: $e');
      return null;
    }
  }
}
