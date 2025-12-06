import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/app_config.dart';

/// Repository for app-wide configuration settings
/// These are admin-controlled settings stored in the database
class ConfigRepository {
  final DatabaseHelper _db = DatabaseHelper();

  /// Initialize config table
  Future<void> initializeConfigTable() async {
    final db = await _db.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_config (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  /// Get a config value by key
  Future<String?> getValue(String key) async {
    try {
      final db = await _db.database;
      await initializeConfigTable();

      final results = await db.query(
        'app_config',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [key],
      );

      debugPrint(
        'ConfigRepository: getValue($key) found ${results.length} results',
      );
      if (results.isEmpty) return null;
      return results.first['value'] as String?;
    } catch (e) {
      debugPrint('ConfigRepository: getValue($key) error - $e');
      return null;
    }
  }

  /// Get a config with full details
  Future<AppConfig?> getConfig(String key) async {
    try {
      final db = await _db.database;
      await initializeConfigTable();

      final results = await db.query(
        'app_config',
        where: 'key = ?',
        whereArgs: [key],
      );

      if (results.isEmpty) return null;
      return AppConfig.fromMap(results.first);
    } catch (e) {
      return null;
    }
  }

  /// Set a config value
  Future<bool> setValue(String key, String value, {String? description}) async {
    try {
      final db = await _db.database;
      await initializeConfigTable();

      final now = DateTime.now().toIso8601String();

      // Check if exists
      final existing = await db.query(
        'app_config',
        where: 'key = ?',
        whereArgs: [key],
      );

      if (existing.isEmpty) {
        await db.insert('app_config', {
          'key': key,
          'value': value,
          'description': description,
          'created_at': now,
          'updated_at': now,
        });
        debugPrint('ConfigRepository: Inserted new config: $key');
      } else {
        await db.update(
          'app_config',
          {
            'value': value,
            'description': description ?? existing.first['description'],
            'updated_at': now,
          },
          where: 'key = ?',
          whereArgs: [key],
        );
        debugPrint('ConfigRepository: Updated config: $key');
      }

      return true;
    } catch (e) {
      debugPrint('ConfigRepository: setValue($key) error - $e');
      return false;
    }
  }

  /// Delete a config
  Future<bool> deleteConfig(String key) async {
    try {
      final db = await _db.database;
      await initializeConfigTable();

      await db.delete('app_config', where: 'key = ?', whereArgs: [key]);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get all configs
  Future<List<AppConfig>> getAllConfigs() async {
    try {
      final db = await _db.database;
      await initializeConfigTable();

      final results = await db.query('app_config', orderBy: 'key ASC');
      return results.map((map) => AppConfig.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get configs by prefix (e.g., all stripe_ configs)
  Future<Map<String, String>> getConfigsByPrefix(String prefix) async {
    try {
      final db = await _db.database;
      await initializeConfigTable();

      final results = await db.query(
        'app_config',
        where: 'key LIKE ?',
        whereArgs: ['$prefix%'],
      );

      return {
        for (final row in results) row['key'] as String: row['value'] as String,
      };
    } catch (e) {
      return {};
    }
  }

  // ============ STRIPE SPECIFIC HELPERS ============

  /// Get Stripe publishable key
  Future<String?> getStripePublishableKey() async {
    return getValue(ConfigKeys.stripePublishableKey);
  }

  /// Set Stripe publishable key
  Future<bool> setStripePublishableKey(String key) async {
    return setValue(
      ConfigKeys.stripePublishableKey,
      key,
      description: 'Stripe publishable key for client-side operations',
    );
  }

  /// Get Stripe secret key (use carefully!)
  Future<String?> getStripeSecretKey() async {
    return getValue(ConfigKeys.stripeSecretKey);
  }

  /// Set Stripe secret key
  Future<bool> setStripeSecretKey(String key) async {
    return setValue(
      ConfigKeys.stripeSecretKey,
      key,
      description: 'Stripe secret key for server-side operations',
    );
  }

  /// Get Stripe price IDs
  Future<String?> getStripeMonthlyPriceId() async {
    return getValue(ConfigKeys.stripeMonthlyPriceId);
  }

  Future<bool> setStripeMonthlyPriceId(String priceId) async {
    return setValue(
      ConfigKeys.stripeMonthlyPriceId,
      priceId,
      description: 'Stripe Price ID for monthly subscription',
    );
  }

  Future<String?> getStripeYearlyPriceId() async {
    return getValue(ConfigKeys.stripeYearlyPriceId);
  }

  Future<bool> setStripeYearlyPriceId(String priceId) async {
    return setValue(
      ConfigKeys.stripeYearlyPriceId,
      priceId,
      description: 'Stripe Price ID for yearly subscription',
    );
  }

  /// Check if Stripe is configured
  Future<bool> isStripeConfigured() async {
    try {
      final publishableKey = await getStripePublishableKey();
      debugPrint(
        'ConfigRepository: Stripe publishable key = ${publishableKey != null ? "SET (${publishableKey.length} chars)" : "NULL"}',
      );
      return publishableKey != null && publishableKey.isNotEmpty;
    } catch (e) {
      debugPrint('ConfigRepository: Error checking Stripe config - $e');
      return false;
    }
  }

  /// Get all Stripe configuration
  Future<Map<String, String?>> getStripeConfig() async {
    return {
      'publishableKey': await getStripePublishableKey(),
      'secretKey': await getStripeSecretKey(),
      'monthlyPriceId': await getStripeMonthlyPriceId(),
      'yearlyPriceId': await getStripeYearlyPriceId(),
    };
  }

  // ============ CHEF AI HELPERS ============

  /// Get Chef AI API key (shared key for subscribers)
  Future<String?> getChefAiApiKey() async {
    return getValue(ConfigKeys.chefAiApiKey);
  }

  /// Set Chef AI API key
  Future<bool> setChefAiApiKey(String key) async {
    return setValue(
      ConfigKeys.chefAiApiKey,
      key,
      description: 'Shared AI API key for Chef AI feature',
    );
  }

  /// Get Chef AI provider
  Future<String?> getChefAiProvider() async {
    return getValue(ConfigKeys.chefAiProvider);
  }

  /// Set Chef AI provider
  Future<bool> setChefAiProvider(String provider) async {
    return setValue(
      ConfigKeys.chefAiProvider,
      provider,
      description:
          'AI provider for Chef AI (openai, gemini, openrouter, deepseek)',
    );
  }
}
