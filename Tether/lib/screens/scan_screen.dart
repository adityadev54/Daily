import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/receipt.dart';
import '../services/database_service.dart';
import '../services/ocr_service.dart';
import '../services/notification_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_input.dart';
import 'camera_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _priceController = TextEditingController();

  final DatabaseService _db = DatabaseService();
  final OCRService _ocr = OCRService();
  final NotificationService _notifications = NotificationService();

  File? _imageFile;
  String? _extractedText;
  bool _isProcessing = false;
  bool _isSaving = false;

  // Form state
  DateTime _purchaseDate = DateTime.now();
  ItemCategory _category = ItemCategory.other;
  int _warrantyMonths = 12;
  int _returnDays = 30;
  bool _hasWarranty = true;
  bool _canReturn = true;

  @override
  void initState() {
    super.initState();
    _notifications.initialize();
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _storeNameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );

    if (picked == null) return;

    final imageFile = File(picked.path);
    setState(() {
      _imageFile = imageFile;
      _isProcessing = true;
    });

    try {
      final result = await _ocr.processImage(imageFile);
      setState(() {
        _extractedText = result.fullText;
        _isProcessing = false;
      });

      // Auto-fill form from OCR
      if (result.storeName != null) {
        _storeNameController.text = result.storeName!;
      }
      if (result.price != null) {
        _priceController.text = result.price!;
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('OCR failed: $e')));
      }
    }
  }

  Future<void> _openCamera() async {
    final File? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );

    if (result != null) {
      setState(() {
        _imageFile = result;
        _isProcessing = true;
      });

      try {
        final ocrResult = await _ocr.processImage(result);
        setState(() {
          _extractedText = ocrResult.fullText;
          _isProcessing = false;
        });

        // Auto-fill form from OCR
        if (ocrResult.storeName != null) {
          _storeNameController.text = ocrResult.storeName!;
        }
        if (ocrResult.price != null) {
          _priceController.text = ocrResult.price!;
        }
      } catch (e) {
        setState(() => _isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('OCR failed: $e')));
        }
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final receipt = Receipt(
        itemName: _itemNameController.text.trim(),
        storeName: _storeNameController.text.trim().isEmpty
            ? null
            : _storeNameController.text.trim(),
        purchaseDate: _purchaseDate,
        warrantyExpiry: _hasWarranty
            ? _purchaseDate.add(Duration(days: _warrantyMonths * 30))
            : null,
        returnDeadline: _canReturn
            ? _purchaseDate.add(Duration(days: _returnDays))
            : null,
        price: double.tryParse(_priceController.text),
        imagePath: _imageFile?.path,
        extractedText: _extractedText,
        category: _category,
      );

      await _db.insertReceipt(receipt);

      // Schedule notifications
      if (_hasWarranty && receipt.warrantyExpiry != null) {
        await _notifications.scheduleWarrantyNotification(receipt);
      }
      if (_canReturn && receipt.returnDeadline != null) {
        await _notifications.scheduleReturnNotification(receipt);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.x, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Receipt',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: _imageFile == null ? _buildImagePicker() : _buildForm(),
      ),
    );
  }

  Widget _buildImagePicker() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              LucideIcons.receipt,
              size: 36,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Scan your receipt',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Take a photo or choose from gallery.\nWe\'ll extract the details automatically.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const Spacer(flex: 2),
          _PickerOption(
            icon: LucideIcons.camera,
            label: 'Take Photo',
            onTap: _openCamera,
          ),
          const SizedBox(height: 12),
          _PickerOption(
            icon: LucideIcons.image,
            label: 'Choose from Gallery',
            onTap: () => _pickImage(ImageSource.gallery),
          ),
          const SizedBox(height: 16),
          _SkipButton(
            onTap: () {
              setState(() {
                _imageFile = File(''); // Dummy to skip image
              });
            },
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Processing indicator
            if (_isProcessing)
              TetherCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Reading receipt...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Image preview
            if (_imageFile != null && _imageFile!.path.isNotEmpty) ...[
              if (!_isProcessing) const SizedBox(height: 0),
              if (_isProcessing) const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.file(
                      _imageFile!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _imageFile = null;
                          _extractedText = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            LucideIcons.x,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Item details section
            _SectionHeader(title: 'Item Details'),
            const SizedBox(height: 12),
            TetherTextField(
              controller: _itemNameController,
              label: 'Item Name',
              hint: 'e.g. Sony WH-1000XM5',
              validator: (v) =>
                  v?.isEmpty == true ? 'Please enter item name' : null,
            ),
            const SizedBox(height: 12),
            TetherTextField(
              controller: _storeNameController,
              label: 'Store (optional)',
              hint: 'e.g. Best Buy',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TetherTextField(
                    controller: _priceController,
                    label: 'Price (optional)',
                    hint: '0.00',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateSelector(
                    label: 'Purchase Date',
                    date: _purchaseDate,
                    onTap: _selectDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _CategorySelector(
              value: _category,
              onChanged: (cat) => setState(() {
                _category = cat;
                _warrantyMonths = cat.defaultWarrantyMonths;
                _returnDays = cat.defaultReturnDays;
              }),
            ),

            const SizedBox(height: 32),

            // Warranty section
            _SectionHeader(title: 'Warranty'),
            const SizedBox(height: 12),
            TetherCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ToggleRow(
                    icon: LucideIcons.shield,
                    label: 'Has Warranty',
                    value: _hasWarranty,
                    onChanged: (v) => setState(() => _hasWarranty = v),
                  ),
                  if (_hasWarranty) ...[
                    const SizedBox(height: 16),
                    _DurationSelector(
                      label: 'Duration',
                      value: _warrantyMonths,
                      unit: 'months',
                      options: const [3, 6, 12, 24, 36, 60],
                      onChanged: (v) => setState(() => _warrantyMonths = v),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Return section
            _SectionHeader(title: 'Return Window'),
            const SizedBox(height: 12),
            TetherCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ToggleRow(
                    icon: LucideIcons.rotateCcw,
                    label: 'Can Return',
                    value: _canReturn,
                    onChanged: (v) => setState(() => _canReturn = v),
                  ),
                  if (_canReturn) ...[
                    const SizedBox(height: 16),
                    _DurationSelector(
                      label: 'Return Period',
                      value: _returnDays,
                      unit: 'days',
                      options: const [7, 14, 30, 45, 60, 90],
                      onChanged: (v) => setState(() => _returnDays = v),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Save button
            TetherButton(
              label: 'Save Receipt',
              onPressed: _isSaving ? null : _save,
              isLoading: _isSaving,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// Image picker option
class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: TetherCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

// Skip button
class _SkipButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SkipButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.pencil,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 10),
            Text(
              'Enter manually instead',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Section header
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title.toUpperCase(),
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        fontSize: 13,
      ),
    );
  }
}

// Date selector
class _DateSelector extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateSelector({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 10),
                Text(
                  DateFormat('MMM d, y').format(date),
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Category selector
class _CategorySelector extends StatelessWidget {
  final ItemCategory value;
  final ValueChanged<ItemCategory> onChanged;

  const _CategorySelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: ItemCategory.values.map((cat) {
            final isSelected = cat == value;
            return GestureDetector(
              onTap: () => onChanged(cat),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  cat.displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? theme.scaffoldBackgroundColor
                        : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// Toggle row
class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 22,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: Container(
            width: 48,
            height: 28,
            decoration: BoxDecoration(
              color: value
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: value
                      ? theme.scaffoldBackgroundColor
                      : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Duration selector
class _DurationSelector extends StatelessWidget {
  final String label;
  final int value;
  final String unit;
  final List<int> options;
  final ValueChanged<int> onChanged;

  const _DurationSelector({
    required this.label,
    required this.value,
    required this.unit,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.map((opt) {
              final isSelected = opt == value;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => onChanged(opt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$opt $unit',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? theme.scaffoldBackgroundColor
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
