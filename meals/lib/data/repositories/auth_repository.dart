import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../database/database_helper.dart';
import '../models/user.dart';
import '../models/user_preferences.dart';
import '../models/user_api_key.dart';

class AuthRepository {
  final DatabaseHelper _db = DatabaseHelper();

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<User?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final db = await _db.database;

      // Check if email already exists
      final existing = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email.toLowerCase()],
      );

      if (existing.isNotEmpty) {
        return null;
      }

      final passwordHash = _hashPassword(password);
      final now = DateTime.now();

      final userId = await db.insert('users', {
        'name': name,
        'email': email.toLowerCase(),
        'password_hash': passwordHash,
        'created_at': now.toIso8601String(),
      });

      // Create default preferences
      await db.insert('user_preferences', {
        'user_id': userId,
        'diet_type': 'None',
        'allergies': '',
        'cuisine_preferences': '',
      });

      return User(
        id: userId,
        name: name,
        email: email.toLowerCase(),
        passwordHash: passwordHash,
        createdAt: now,
      );
    } catch (e) {
      return null;
    }
  }

  Future<User?> login({required String email, required String password}) async {
    try {
      final db = await _db.database;
      final passwordHash = _hashPassword(password);

      final results = await db.query(
        'users',
        where: 'email = ? AND password_hash = ?',
        whereArgs: [email.toLowerCase(), passwordHash],
      );

      if (results.isEmpty) {
        return null;
      }

      return User.fromMap(results.first);
    } catch (e) {
      return null;
    }
  }

  Future<User?> getUserById(int id) async {
    try {
      final db = await _db.database;
      final results = await db.query('users', where: 'id = ?', whereArgs: [id]);

      if (results.isEmpty) {
        return null;
      }

      return User.fromMap(results.first);
    } catch (e) {
      return null;
    }
  }

  Future<UserPreferences?> getUserPreferences(int userId) async {
    try {
      final db = await _db.database;
      final results = await db.query(
        'user_preferences',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      if (results.isEmpty) {
        return UserPreferences(userId: userId);
      }

      return UserPreferences.fromMap(results.first);
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateUserPreferences(UserPreferences preferences) async {
    try {
      final db = await _db.database;

      final existing = await db.query(
        'user_preferences',
        where: 'user_id = ?',
        whereArgs: [preferences.userId],
      );

      if (existing.isEmpty) {
        await db.insert('user_preferences', preferences.toMap());
      } else {
        await db.update(
          'user_preferences',
          preferences.toMap(),
          where: 'user_id = ?',
          whereArgs: [preferences.userId],
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateUserName(int userId, String name) async {
    try {
      final db = await _db.database;
      await db.update(
        'users',
        {'name': name},
        where: 'id = ?',
        whereArgs: [userId],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changePassword(
    int userId,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final db = await _db.database;
      final currentHash = _hashPassword(currentPassword);

      final results = await db.query(
        'users',
        where: 'id = ? AND password_hash = ?',
        whereArgs: [userId, currentHash],
      );

      if (results.isEmpty) {
        return false;
      }

      final newHash = _hashPassword(newPassword);
      await db.update(
        'users',
        {'password_hash': newHash},
        where: 'id = ?',
        whereArgs: [userId],
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAccount(int userId) async {
    try {
      final db = await _db.database;
      await db.delete('users', where: 'id = ?', whereArgs: [userId]);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============ API KEY MANAGEMENT ============

  /// Get user's API key settings
  Future<UserApiKey?> getUserApiKey(int userId) async {
    try {
      final db = await _db.database;

      // Ensure table exists
      await _ensureApiKeyTableExists(db);

      final results = await db.query(
        'user_api_keys',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      if (results.isEmpty) {
        return null;
      }

      return UserApiKey.fromMap(results.first);
    } catch (e) {
      return null;
    }
  }

  /// Save or update user's API key
  Future<bool> saveUserApiKey(UserApiKey apiKey) async {
    try {
      final db = await _db.database;

      // Ensure table exists
      await _ensureApiKeyTableExists(db);

      final existing = await db.query(
        'user_api_keys',
        where: 'user_id = ?',
        whereArgs: [apiKey.userId],
      );

      final now = DateTime.now().toIso8601String();

      if (existing.isEmpty) {
        await db.insert('user_api_keys', {
          'user_id': apiKey.userId,
          'openrouter_key': apiKey.apiKey,
          'provider': apiKey.provider,
          'use_shared_key': apiKey.useSharedKey ? 1 : 0,
          'created_at': now,
          'updated_at': now,
        });
      } else {
        await db.update(
          'user_api_keys',
          {
            'openrouter_key': apiKey.apiKey,
            'provider': apiKey.provider,
            'use_shared_key': apiKey.useSharedKey ? 1 : 0,
            'updated_at': now,
          },
          where: 'user_id = ?',
          whereArgs: [apiKey.userId],
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove user's own API key (but keep the record)
  Future<bool> removeUserApiKey(int userId) async {
    try {
      final db = await _db.database;

      // Ensure table exists
      await _ensureApiKeyTableExists(db);

      await db.update(
        'user_api_keys',
        {
          'openrouter_key': null,
          'provider': null,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Toggle shared key usage for subscriber
  Future<bool> toggleUseSharedKey(int userId, bool useShared) async {
    try {
      final db = await _db.database;

      // Ensure table exists
      await _ensureApiKeyTableExists(db);

      final existing = await db.query(
        'user_api_keys',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      final now = DateTime.now().toIso8601String();

      if (existing.isEmpty) {
        await db.insert('user_api_keys', {
          'user_id': userId,
          'openrouter_key': null,
          'use_shared_key': useShared ? 1 : 0,
          'created_at': now,
          'updated_at': now,
        });
      } else {
        await db.update(
          'user_api_keys',
          {'use_shared_key': useShared ? 1 : 0, 'updated_at': now},
          where: 'user_id = ?',
          whereArgs: [userId],
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ensure the API key table exists (for existing databases)
  Future<void> _ensureApiKeyTableExists(dynamic db) async {
    // Create user_api_keys table with all columns
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_api_keys (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER UNIQUE NOT NULL,
          openrouter_key TEXT,
          provider TEXT,
          active_provider TEXT,
          use_shared_key INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
    } catch (_) {}

    // Check existing columns and add missing ones
    try {
      final columns = await db.rawQuery("PRAGMA table_info(user_api_keys)");
      final columnNames = columns.map((c) => c['name'] as String).toSet();

      if (!columnNames.contains('provider')) {
        await db.execute('ALTER TABLE user_api_keys ADD COLUMN provider TEXT');
      }
      if (!columnNames.contains('active_provider')) {
        await db.execute(
          'ALTER TABLE user_api_keys ADD COLUMN active_provider TEXT',
        );
      }
    } catch (_) {}

    // Create provider_api_keys table for multi-key support
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS provider_api_keys (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          provider TEXT NOT NULL,
          api_key TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          UNIQUE(user_id, provider),
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
    } catch (_) {}
  }

  // ============ MULTI-KEY MANAGEMENT (for subscribers) ============

  /// Get all API keys for a user (for multi-key support)
  Future<List<ProviderApiKey>> getAllUserApiKeys(int userId) async {
    try {
      final db = await _db.database;
      await _ensureApiKeyTableExists(db);

      final results = await db.query(
        'provider_api_keys',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'provider ASC',
      );

      return results.map((r) => ProviderApiKey.fromMap(r)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Save or update a specific provider's API key
  Future<bool> saveProviderApiKey(ProviderApiKey apiKey) async {
    try {
      final db = await _db.database;
      await _ensureApiKeyTableExists(db);

      final existing = await db.query(
        'provider_api_keys',
        where: 'user_id = ? AND provider = ?',
        whereArgs: [apiKey.userId, apiKey.provider.name],
      );

      final now = DateTime.now().toIso8601String();

      if (existing.isEmpty) {
        await db.insert('provider_api_keys', {
          'user_id': apiKey.userId,
          'provider': apiKey.provider.name,
          'api_key': apiKey.apiKey,
          'created_at': now,
          'updated_at': now,
        });
      } else {
        await db.update(
          'provider_api_keys',
          {'api_key': apiKey.apiKey, 'updated_at': now},
          where: 'user_id = ? AND provider = ?',
          whereArgs: [apiKey.userId, apiKey.provider.name],
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove a specific provider's API key
  Future<bool> removeProviderApiKey(int userId, AIProviderType provider) async {
    try {
      final db = await _db.database;
      await _ensureApiKeyTableExists(db);

      await db.delete(
        'provider_api_keys',
        where: 'user_id = ? AND provider = ?',
        whereArgs: [userId, provider.name],
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get a specific provider's API key
  Future<ProviderApiKey?> getProviderApiKey(
    int userId,
    AIProviderType provider,
  ) async {
    try {
      final db = await _db.database;
      await _ensureApiKeyTableExists(db);

      final results = await db.query(
        'provider_api_keys',
        where: 'user_id = ? AND provider = ?',
        whereArgs: [userId, provider.name],
      );

      if (results.isEmpty) return null;
      return ProviderApiKey.fromMap(results.first);
    } catch (e) {
      return null;
    }
  }

  /// Set the active provider for a user
  Future<bool> setActiveProvider(int userId, AIProviderType provider) async {
    try {
      final db = await _db.database;
      await _ensureApiKeyTableExists(db);

      final existing = await db.query(
        'user_api_keys',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      final now = DateTime.now().toIso8601String();

      if (existing.isEmpty) {
        await db.insert('user_api_keys', {
          'user_id': userId,
          'active_provider': provider.name,
          'created_at': now,
          'updated_at': now,
        });
      } else {
        await db.update(
          'user_api_keys',
          {'active_provider': provider.name, 'updated_at': now},
          where: 'user_id = ?',
          whereArgs: [userId],
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // ============ SUBSCRIPTION MANAGEMENT ============

  /// Update user subscription status
  Future<bool> updateSubscription(
    int userId, {
    required bool isSubscribed,
    DateTime? expiryDate,
  }) async {
    try {
      final db = await _db.database;

      // Ensure columns exist
      await _ensureSubscriptionColumnsExist(db);

      await db.update(
        'users',
        {
          'is_subscribed': isSubscribed ? 1 : 0,
          'subscription_expiry': expiryDate?.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Enable/disable Chef AI for user
  Future<bool> toggleChefAi(int userId, bool enabled) async {
    try {
      final db = await _db.database;

      // Ensure columns exist
      await _ensureSubscriptionColumnsExist(db);

      await db.update(
        'users',
        {'chef_ai_enabled': enabled ? 1 : 0},
        where: 'id = ?',
        whereArgs: [userId],
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ensure subscription columns exist (for existing databases)
  Future<void> _ensureSubscriptionColumnsExist(dynamic db) async {
    try {
      await db.execute(
        'ALTER TABLE users ADD COLUMN is_subscribed INTEGER DEFAULT 0',
      );
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE users ADD COLUMN subscription_expiry TEXT');
    } catch (_) {}
    try {
      await db.execute(
        'ALTER TABLE users ADD COLUMN chef_ai_enabled INTEGER DEFAULT 0',
      );
    } catch (_) {}
  }
}
