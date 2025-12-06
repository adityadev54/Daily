class User {
  final int? id;
  final String name;
  final String email;
  final String passwordHash;
  final bool isSubscribed;
  final DateTime? subscriptionExpiry;
  final bool chefAiEnabled;
  final DateTime createdAt;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.isSubscribed = false,
    this.subscriptionExpiry,
    this.chefAiEnabled = false,
    required this.createdAt,
  });

  /// Check if subscription is active (subscribed and not expired)
  bool get hasActiveSubscription {
    if (!isSubscribed) return false;
    if (subscriptionExpiry == null) return true; // Lifetime subscription
    return subscriptionExpiry!.isAfter(DateTime.now());
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      isSubscribed: (map['is_subscribed'] as int?) == 1,
      subscriptionExpiry: map['subscription_expiry'] != null
          ? DateTime.parse(map['subscription_expiry'] as String)
          : null,
      chefAiEnabled: (map['chef_ai_enabled'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password_hash': passwordHash,
      'is_subscribed': isSubscribed ? 1 : 0,
      'subscription_expiry': subscriptionExpiry?.toIso8601String(),
      'chef_ai_enabled': chefAiEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? passwordHash,
    bool? isSubscribed,
    DateTime? subscriptionExpiry,
    bool? chefAiEnabled,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      chefAiEnabled: chefAiEnabled ?? this.chefAiEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
