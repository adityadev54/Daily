import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user.dart';
import '../../data/models/user_preferences.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  // Admin user ID - has full access to all features
  static const int adminUserId = 1;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  UserPreferences? _preferences;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  UserPreferences? get preferences => _preferences;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Check if current user is admin
  bool get isAdmin => _user?.id == adminUserId;

  /// Check if user has active subscription (or is admin)
  bool get isSubscribed => isAdmin || (_user?.hasActiveSubscription ?? false);

  /// Check if Chef AI is enabled for user
  bool get isChefAiEnabled => _user?.chefAiEnabled ?? false;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId != null) {
        final user = await _authRepository.getUserById(userId);
        if (user != null) {
          _user = user;
          _preferences = await _authRepository.getUserPreferences(userId);
          _status = AuthStatus.authenticated;
        } else {
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.login(
        email: email,
        password: password,
      );

      if (user != null) {
        _user = user;
        _preferences = await _authRepository.getUserPreferences(user.id!);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', user.id!);

        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid email or password';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred. Please try again.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.register(
        name: name,
        email: email,
        password: password,
      );

      if (user != null) {
        _user = user;
        _preferences = await _authRepository.getUserPreferences(user.id!);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', user.id!);

        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Email already exists';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred. Please try again.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');

    _user = null;
    _preferences = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> updatePreferences(UserPreferences preferences) async {
    final success = await _authRepository.updateUserPreferences(preferences);
    if (success) {
      _preferences = preferences;
      notifyListeners();
    }
    return success;
  }

  Future<bool> updateName(String name) async {
    if (_user == null) return false;

    final success = await _authRepository.updateUserName(_user!.id!, name);
    if (success) {
      _user = _user!.copyWith(name: name);
      notifyListeners();
    }
    return success;
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (_user == null) return false;
    return await _authRepository.changePassword(
      _user!.id!,
      currentPassword,
      newPassword,
    );
  }

  Future<bool> deleteAccount() async {
    if (_user == null) return false;

    final success = await _authRepository.deleteAccount(_user!.id!);
    if (success) {
      await logout();
    }
    return success;
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ============ SUBSCRIPTION MANAGEMENT ============

  /// Update user's subscription status
  Future<bool> updateSubscription({
    required bool isSubscribed,
    DateTime? expiryDate,
  }) async {
    if (_user == null) return false;

    final success = await _authRepository.updateSubscription(
      _user!.id!,
      isSubscribed: isSubscribed,
      expiryDate: expiryDate,
    );

    if (success) {
      _user = _user!.copyWith(
        isSubscribed: isSubscribed,
        subscriptionExpiry: expiryDate,
      );
      notifyListeners();
    }

    return success;
  }

  /// Toggle Chef AI feature
  Future<bool> toggleChefAi(bool enabled) async {
    if (_user == null) return false;

    final success = await _authRepository.toggleChefAi(_user!.id!, enabled);

    if (success) {
      _user = _user!.copyWith(chefAiEnabled: enabled);
      notifyListeners();
    }

    return success;
  }

  /// Refresh user data from database
  Future<void> refreshUser() async {
    if (_user?.id == null) return;

    final updatedUser = await _authRepository.getUserById(_user!.id!);
    if (updatedUser != null) {
      _user = updatedUser;
      notifyListeners();
    }
  }
}
