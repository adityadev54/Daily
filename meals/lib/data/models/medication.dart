class Medication {
  final int? id;
  final int userId;
  final String name;
  final String? dosage;
  final String frequency; // daily, twice_daily, weekly, as_needed
  final String times; // morning, afternoon, evening, night (required by DB)
  final bool withFood;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;

  Medication({
    this.id,
    required this.userId,
    required this.name,
    this.dosage,
    this.frequency = 'daily',
    this.times = 'morning',
    this.withFood = false,
    this.notes,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      dosage: map['dosage'] as String?,
      frequency: map['frequency'] as String? ?? 'daily',
      times: map['times'] as String? ?? 'morning',
      withFood: (map['with_food'] as int?) == 1,
      notes: map['notes'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'times': times,
      'with_food': withFood ? 1 : 0,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Medication copyWith({
    int? id,
    int? userId,
    String? name,
    String? dosage,
    String? frequency,
    String? times,
    bool? withFood,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Medication(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      times: times ?? this.times,
      withFood: withFood ?? this.withFood,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get frequencyDisplay {
    switch (frequency) {
      case 'daily':
        return 'Once daily';
      case 'twice_daily':
        return 'Twice daily';
      case 'three_times':
        return 'Three times daily';
      case 'weekly':
        return 'Weekly';
      case 'as_needed':
        return 'As needed';
      default:
        return frequency;
    }
  }

  String get timesDisplay {
    switch (times) {
      case 'morning':
        return '🌅 Morning';
      case 'afternoon':
        return '☀️ Afternoon';
      case 'evening':
        return '🌆 Evening';
      case 'night':
        return '🌙 Night';
      default:
        return times;
    }
  }

  // Check if medication should be taken with meals
  String? getMealReminder(String mealType) {
    if (!withFood) return null;

    final time = times.toLowerCase();
    if (time == 'morning' && mealType.toLowerCase() == 'breakfast') {
      return 'Take $name with this meal';
    }
    if (time == 'afternoon' && mealType.toLowerCase() == 'lunch') {
      return 'Take $name with this meal';
    }
    if ((time == 'evening' || time == 'night') &&
        mealType.toLowerCase() == 'dinner') {
      return 'Take $name with this meal';
    }
    return null;
  }
}
