import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medication_provider.dart';
import '../../data/models/medication.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMedications());
  }

  void _loadMedications() {
    final authProvider = context.read<AuthProvider>();
    final medicationProvider = context.read<MedicationProvider>();
    if (authProvider.user != null) {
      medicationProvider.loadMedications(authProvider.user!.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final medicationProvider = context.watch<MedicationProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.grey[50],
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Medications',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          if (medicationProvider.activeCount > 0)
                            Text(
                              '${medicationProvider.activeCount} active',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (medicationProvider.medicationsWithFood.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.notification,
                              size: 14,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${medicationProvider.medicationsWithFood.length} with meals',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: medicationProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : medicationProvider.medications.isEmpty
                    ? _buildEmptyState(context)
                    : _buildMedicationsList(context, medicationProvider),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showMedicationFormDialog(context, null),
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.health,
                size: 48,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No medications',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your medications and get\nreminders with your meals',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showMedicationFormDialog(context, null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Medication'),
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationsList(
    BuildContext context,
    MedicationProvider provider,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeMeds = provider.activeMedications;
    final inactiveMeds = provider.medications
        .where((m) => !m.isActive)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        // Active medications
        if (activeMeds.isNotEmpty) ...[
          _buildSectionHeader(context, 'Active', activeMeds.length),
          const SizedBox(height: 12),
          ...activeMeds.map(
            (med) => _buildMedicationCard(context, med, provider),
          ),
        ],

        // Inactive medications
        if (inactiveMeds.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Inactive', inactiveMeds.length),
          const SizedBox(height: 12),
          ...inactiveMeds.map(
            (med) => _buildMedicationCard(context, med, provider),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark ? Colors.white60 : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationCard(
    BuildContext context,
    Medication medication,
    MedicationProvider provider,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.read<AuthProvider>();

    return Dismissible(
      key: Key('medication_${medication.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Iconsax.trash, color: Colors.red[400]),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Medication'),
            content: Text(
              'Are you sure you want to delete "${medication.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        if (authProvider.user != null) {
          provider.deleteMedication(medication.id!, authProvider.user!.id!);
        }
      },
      child: GestureDetector(
        onTap: () => _showMedicationFormDialog(context, medication),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: medication.isActive
                      ? (isDark
                            ? Colors.white10
                            : Colors.black.withOpacity(0.05))
                      : (isDark
                            ? Colors.white.withOpacity(0.03)
                            : Colors.black.withOpacity(0.02)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Iconsax.health,
                  color: medication.isActive
                      ? (isDark ? Colors.white70 : Colors.black87)
                      : (isDark ? Colors.white30 : Colors.black26),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            medication.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: medication.isActive
                                  ? (isDark ? Colors.white : Colors.black)
                                  : (isDark ? Colors.white38 : Colors.black38),
                            ),
                          ),
                        ),
                        if (medication.dosage != null &&
                            medication.dosage!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              medication.dosage!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          medication.frequencyDisplay,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                        if (medication.times.isNotEmpty) ...[
                          Text(
                            ' • ',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black26,
                            ),
                          ),
                          Text(
                            medication.timesDisplay,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (medication.withFood) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🍽️', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              'Take with food',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.orange[isDark ? 300 : 700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Toggle
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: medication.isActive,
                  onChanged: (value) {
                    if (authProvider.user != null) {
                      provider.toggleMedicationActive(
                        medication.id!,
                        value,
                        authProvider.user!.id!,
                      );
                    }
                  },
                  activeColor: isDark ? Colors.white : Colors.black,
                  activeTrackColor: isDark ? Colors.white24 : Colors.black26,
                  inactiveThumbColor: isDark ? Colors.white38 : Colors.black26,
                  inactiveTrackColor: isDark
                      ? Colors.white10
                      : Colors.black.withOpacity(0.05),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMedicationFormDialog(BuildContext context, Medication? medication) {
    final authProvider = context.read<AuthProvider>();
    final medicationProvider = context.read<MedicationProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final nameController = TextEditingController(text: medication?.name);
    final dosageController = TextEditingController(text: medication?.dosage);
    final notesController = TextEditingController(text: medication?.notes);

    String selectedFrequency = medication?.frequency ?? 'daily';
    String selectedTimes = medication?.times ?? 'morning';
    bool withFood = medication?.withFood ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            medication == null
                                ? 'New Medication'
                                : 'Edit Medication',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          if (medication != null)
                            GestureDetector(
                              onTap: () async {
                                Navigator.pop(context);
                                if (authProvider.user != null) {
                                  await medicationProvider.deleteMedication(
                                    medication.id!,
                                    authProvider.user!.id!,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Iconsax.trash,
                                  size: 18,
                                  color: Colors.red[400],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Name field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Medication Name',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: nameController,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g., Aspirin, Metformin',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Dosage field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dosage',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: dosageController,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g., 500mg, 1 tablet',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Frequency section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Frequency',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildPillChip(
                                context,
                                'daily',
                                'Daily',
                                selectedFrequency,
                                (v) {
                                  setModalState(() => selectedFrequency = v);
                                },
                              ),
                              _buildPillChip(
                                context,
                                'twice_daily',
                                'Twice daily',
                                selectedFrequency,
                                (v) {
                                  setModalState(() => selectedFrequency = v);
                                },
                              ),
                              _buildPillChip(
                                context,
                                'three_times',
                                '3x daily',
                                selectedFrequency,
                                (v) {
                                  setModalState(() => selectedFrequency = v);
                                },
                              ),
                              _buildPillChip(
                                context,
                                'weekly',
                                'Weekly',
                                selectedFrequency,
                                (v) {
                                  setModalState(() => selectedFrequency = v);
                                },
                              ),
                              _buildPillChip(
                                context,
                                'as_needed',
                                'As needed',
                                selectedFrequency,
                                (v) {
                                  setModalState(() => selectedFrequency = v);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Time of day section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time of Day',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimeCard(
                                  context,
                                  'morning',
                                  '🌅',
                                  'Morning',
                                  selectedTimes,
                                  (v) => setModalState(() => selectedTimes = v),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTimeCard(
                                  context,
                                  'afternoon',
                                  '☀️',
                                  'Afternoon',
                                  selectedTimes,
                                  (v) => setModalState(() => selectedTimes = v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimeCard(
                                  context,
                                  'evening',
                                  '🌆',
                                  'Evening',
                                  selectedTimes,
                                  (v) => setModalState(() => selectedTimes = v),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTimeCard(
                                  context,
                                  'night',
                                  '🌙',
                                  'Night',
                                  selectedTimes,
                                  (v) => setModalState(() => selectedTimes = v),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // With food toggle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GestureDetector(
                        onTap: () => setModalState(() => withFood = !withFood),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: withFood
                                ? Colors.orange.withOpacity(isDark ? 0.15 : 0.1)
                                : (isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey[100]),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: withFood
                                  ? Colors.orange.withOpacity(0.3)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: withFood
                                      ? Colors.orange.withOpacity(0.2)
                                      : (isDark
                                            ? Colors.white10
                                            : Colors.black.withOpacity(0.05)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '🍽️',
                                  style: TextStyle(fontSize: 20),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Take with food',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                    ),
                                    Text(
                                      'Get reminders during meal times',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black54,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 48,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: withFood
                                      ? Colors.orange
                                      : (isDark
                                            ? Colors.white10
                                            : Colors.black.withOpacity(0.05)),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Stack(
                                  children: [
                                    AnimatedPositioned(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      curve: Curves.easeInOut,
                                      left: withFood ? 22 : 2,
                                      top: 2,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Notes field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notes (optional)',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: notesController,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Any additional instructions...',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: FilledButton(
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty ||
                              authProvider.user == null) {
                            return;
                          }

                          final newMedication = Medication(
                            id: medication?.id,
                            userId: authProvider.user!.id!,
                            name: nameController.text.trim(),
                            dosage: dosageController.text.trim().isEmpty
                                ? null
                                : dosageController.text.trim(),
                            frequency: selectedFrequency,
                            times: selectedTimes,
                            withFood: withFood,
                            notes: notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                            isActive: medication?.isActive ?? true,
                          );

                          if (medication == null) {
                            await medicationProvider.addMedication(
                              newMedication,
                            );
                          } else {
                            await medicationProvider.updateMedication(
                              newMedication,
                            );
                          }

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  medication == null
                                      ? 'Medication added'
                                      : 'Medication updated',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : Colors.black,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          medication == null
                              ? 'Add Medication'
                              : 'Save Changes',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    // Bottom safe area
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPillChip(
    BuildContext context,
    String value,
    String label,
    String selectedValue,
    Function(String) onSelect,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = value == selectedValue;

    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : Colors.black)
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.white70 : Colors.black54),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeCard(
    BuildContext context,
    String value,
    String emoji,
    String label,
    String selectedValue,
    Function(String) onSelect,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = value == selectedValue;

    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05))
              : (isDark ? Colors.white.withOpacity(0.03) : Colors.grey[50]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.white30 : Colors.black26)
                : (isDark ? Colors.white10 : Colors.black.withOpacity(0.03)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? Colors.white54 : Colors.black54),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
