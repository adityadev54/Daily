import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/models/health_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_provider.dart';

class HealthProfileSetupScreen extends StatefulWidget {
  const HealthProfileSetupScreen({super.key});

  @override
  State<HealthProfileSetupScreen> createState() =>
      _HealthProfileSetupScreenState();
}

class _HealthProfileSetupScreenState extends State<HealthProfileSetupScreen> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _birthYearController = TextEditingController();

  String? _selectedSex;
  String _selectedActivityLevel = 'moderate';
  String _selectedGoal = 'maintain';
  bool _syncWithHealth = true;

  bool _isLoading = false;

  final _activityLevels = {
    'sedentary': 'Sedentary (little or no exercise)',
    'light': 'Light (exercise 1-3 days/week)',
    'moderate': 'Moderate (exercise 3-5 days/week)',
    'active': 'Active (exercise 6-7 days/week)',
    'very_active': 'Very Active (hard exercise daily)',
  };

  final _goals = {
    'lose': 'Lose Weight',
    'maintain': 'Maintain Weight',
    'gain': 'Gain Muscle',
  };

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  void _loadExistingProfile() {
    final profile = context.read<HealthProvider>().healthProfile;
    if (profile != null) {
      if (profile.height != null) {
        _heightController.text = profile.height!.round().toString();
      }
      if (profile.weight != null) {
        _weightController.text = profile.weight!.toStringAsFixed(1);
      }
      if (profile.birthYear != null) {
        _birthYearController.text = profile.birthYear.toString();
      }
      setState(() {
        _selectedSex = profile.sex;
        _selectedActivityLevel = profile.activityLevel;
        _selectedGoal = profile.goal ?? 'maintain';
        _syncWithHealth = profile.syncWithHealth;
      });
    }
  }

  Future<void> _saveProfile() async {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    final birthYear = int.tryParse(_birthYearController.text);

    if (height == null ||
        weight == null ||
        birthYear == null ||
        _selectedSex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final healthProvider = context.read<HealthProvider>();

    final userId = authProvider.user?.id ?? 0;
    final existingProfile = healthProvider.healthProfile;

    final profile = HealthProfile(
      id: existingProfile?.id,
      userId: userId,
      height: height,
      weight: weight,
      birthYear: birthYear,
      sex: _selectedSex,
      activityLevel: _selectedActivityLevel,
      goal: _selectedGoal,
      syncWithHealth: _syncWithHealth,
    );

    final success = await healthProvider.saveHealthProfile(profile);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        title: Text(
          'Health Profile',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.blue.shade900.withValues(alpha: 0.3)
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.blue.shade800 : Colors.blue.shade100,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This info helps calculate your personalized daily calorie and macro targets.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.blue.shade300
                            : Colors.blue.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Basic Info Section
            _buildSectionTitle('Basic Information', isDark),
            const SizedBox(height: 16),

            // Sex Selection
            _buildLabel('Sex', isDark),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSelectionChip(
                    label: 'Male',
                    isSelected: _selectedSex == 'male',
                    onTap: () => setState(() => _selectedSex = 'male'),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSelectionChip(
                    label: 'Female',
                    isSelected: _selectedSex == 'female',
                    onTap: () => setState(() => _selectedSex = 'female'),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Birth Year
            _buildLabel('Birth Year', isDark),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _birthYearController,
              hint: 'e.g., 1990',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // Height
            _buildLabel('Height (cm)', isDark),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _heightController,
              hint: 'e.g., 175',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // Weight
            _buildLabel('Weight (kg)', isDark),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _weightController,
              hint: 'e.g., 70.5',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
              ],
              isDark: isDark,
            ),
            const SizedBox(height: 32),

            // Activity Level Section
            _buildSectionTitle('Activity Level', isDark),
            const SizedBox(height: 16),

            ..._activityLevels.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildRadioOption(
                  value: entry.key,
                  groupValue: _selectedActivityLevel,
                  label: entry.value,
                  onChanged: (val) =>
                      setState(() => _selectedActivityLevel = val!),
                  isDark: isDark,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Goal Section
            _buildSectionTitle('Goal', isDark),
            const SizedBox(height: 16),

            Row(
              children: _goals.entries.map((entry) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: entry.key != 'gain' ? 8 : 0,
                    ),
                    child: _buildGoalChip(
                      label: entry.value,
                      isSelected: _selectedGoal == entry.key,
                      onTap: () => setState(() => _selectedGoal = entry.key),
                      isDark: isDark,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Sync Settings
            _buildSectionTitle('Sync Settings', isDark),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sync with Samsung Health',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Auto-update weight from health data',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white60
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _syncWithHealth,
                    onChanged: (val) => setState(() => _syncWithHealth = val),
                    activeColor: isDark ? Colors.white : Colors.black,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Calculated Values Preview
            _buildCalculatedPreview(isDark),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white70 : Colors.grey.shade700,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(
        fontSize: 16,
        color: isDark ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.grey.shade400,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _buildSelectionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : Colors.black)
              : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.white24 : Colors.grey.shade300),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark ? Colors.white : Colors.black),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption({
    required String value,
    required String groupValue,
    required String label,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    final isSelected = value == groupValue;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : Colors.black)
              : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.white24 : Colors.grey.shade300),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : (isDark ? Colors.white38 : Colors.grey.shade400),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : (isDark ? Colors.white : Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : Colors.black)
              : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.white24 : Colors.grey.shade300),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark ? Colors.white : Colors.black),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalculatedPreview(bool isDark) {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    final birthYear = int.tryParse(_birthYearController.text);

    // Create a temporary profile to calculate values
    if (height != null &&
        weight != null &&
        birthYear != null &&
        _selectedSex != null) {
      final tempProfile = HealthProfile(
        userId: 0,
        height: height,
        weight: weight,
        birthYear: birthYear,
        sex: _selectedSex,
        activityLevel: _selectedActivityLevel,
        goal: _selectedGoal,
      );

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.green.shade900.withValues(alpha: 0.3)
              : Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.green.shade800 : Colors.green.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: isDark ? Colors.green.shade400 : Colors.green.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Your Personalized Targets',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.green.shade400
                        : Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPreviewStat(
                    'Daily Calories',
                    '${tempProfile.dailyCalorieTarget ?? 0}',
                    'kcal',
                    isDark,
                  ),
                ),
                Expanded(
                  child: _buildPreviewStat(
                    'BMI',
                    tempProfile.bmi?.toStringAsFixed(1) ?? '--',
                    tempProfile.bmiCategory ?? '',
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPreviewStat(
                    'Protein',
                    '${tempProfile.macroTargets?['protein'] ?? 0}',
                    'g/day',
                    isDark,
                  ),
                ),
                Expanded(
                  child: _buildPreviewStat(
                    'Carbs',
                    '${tempProfile.macroTargets?['carbs'] ?? 0}',
                    'g/day',
                    isDark,
                  ),
                ),
                Expanded(
                  child: _buildPreviewStat(
                    'Fat',
                    '${tempProfile.macroTargets?['fat'] ?? 0}',
                    'g/day',
                    isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calculate_outlined,
            color: isDark ? Colors.white38 : Colors.grey.shade500,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Fill in all fields to see your personalized targets',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStat(
    String label,
    String value,
    String unit,
    bool isDark,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.green.shade300 : Colors.green.shade800,
          ),
        ),
        Text(
          unit.isNotEmpty ? '$label ($unit)' : label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.green.shade400 : Colors.green.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
