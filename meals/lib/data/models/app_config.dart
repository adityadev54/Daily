/// App configuration keys stored in database
/// Allows admin to configure API keys without rebuilding
class AppConfig {
  final int? id;
  final String key;
  final String value;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppConfig({
    this.id,
    required this.key,
    required this.value,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppConfig.fromMap(Map<String, dynamic> map) {
    return AppConfig(
      id: map['id'] as int?,
      key: map['key'] as String,
      value: map['value'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'key': key,
      'value': value,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AppConfig copyWith({
    int? id,
    String? key,
    String? value,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppConfig(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Configuration keys used in the app
class ConfigKeys {
  // Stripe
  static const String stripePublishableKey = 'stripe_publishable_key';
  static const String stripeSecretKey = 'stripe_secret_key';
  static const String stripeMonthlyPriceId = 'stripe_monthly_price_id';
  static const String stripeYearlyPriceId = 'stripe_yearly_price_id';

  // AI (Chef AI shared key for subscribers)
  static const String chefAiApiKey = 'chef_ai_api_key';
  static const String chefAiProvider = 'chef_ai_provider';

  // App Settings
  static const String appVersion = 'app_version';
  static const String maintenanceMode = 'maintenance_mode';
}
