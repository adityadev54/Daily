import 'package:flutter/foundation.dart';
import '../data/models/medication.dart';
import '../data/repositories/medication_repository.dart';

class MedicationProvider extends ChangeNotifier {
  final MedicationRepository _repository = MedicationRepository();

  List<Medication> _medications = [];
  List<Medication> _activeMedications = [];
  List<Medication> _medicationsWithFood = [];
  bool _isLoading = false;

  List<Medication> get medications => _medications;
  List<Medication> get activeMedications => _activeMedications;
  List<Medication> get medicationsWithFood => _medicationsWithFood;
  bool get isLoading => _isLoading;
  int get activeCount => _activeMedications.length;

  Future<void> loadMedications(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _medications = await _repository.getMedications(userId);
      _activeMedications = await _repository.getActiveMedications(userId);
      _medicationsWithFood = await _repository.getMedicationsWithFood(userId);
    } catch (e) {
      debugPrint('Error loading medications: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addMedication(Medication medication) async {
    try {
      await _repository.addMedication(medication);
      await loadMedications(medication.userId);
    } catch (e) {
      debugPrint('Error adding medication: $e');
    }
  }

  Future<void> updateMedication(Medication medication) async {
    try {
      await _repository.updateMedication(medication);
      await loadMedications(medication.userId);
    } catch (e) {
      debugPrint('Error updating medication: $e');
    }
  }

  Future<void> toggleMedicationActive(
    int medicationId,
    bool isActive,
    int userId,
  ) async {
    try {
      await _repository.toggleMedicationActive(medicationId, isActive);
      // Update local state
      final index = _medications.indexWhere((m) => m.id == medicationId);
      if (index != -1) {
        _medications[index] = _medications[index].copyWith(isActive: isActive);
        _updateActiveLists();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling medication: $e');
    }
  }

  Future<void> deleteMedication(int medicationId, int userId) async {
    try {
      await _repository.deleteMedication(medicationId);
      _medications.removeWhere((m) => m.id == medicationId);
      _updateActiveLists();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting medication: $e');
    }
  }

  // Get medication reminders for a meal type
  List<String> getMealReminders(String mealType) {
    final reminders = <String>[];
    for (final med in _medicationsWithFood) {
      final reminder = med.getMealReminder(mealType);
      if (reminder != null) {
        reminders.add(reminder);
      }
    }
    return reminders;
  }

  // Get medications for specific time
  List<Medication> getMedicationsForTime(String timeOfDay) {
    return _activeMedications.where((m) => m.times == timeOfDay).toList();
  }

  void _updateActiveLists() {
    _activeMedications = _medications.where((m) => m.isActive).toList();
    _medicationsWithFood = _activeMedications.where((m) => m.withFood).toList();
  }
}
