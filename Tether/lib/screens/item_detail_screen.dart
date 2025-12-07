import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/receipt.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/export_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';

class ItemDetailScreen extends StatefulWidget {
  final Receipt receipt;

  const ItemDetailScreen({super.key, required this.receipt});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notifications = NotificationService();
  final ExportService _export = ExportService();
  late Receipt _receipt;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _receipt = widget.receipt;
  }

  Future<void> _deleteReceipt() async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;

    setState(() => _isDeleting = true);

    try {
      await _db.deleteReceipt(_receipt.id);
      await _notifications.cancelReceiptNotifications(_receipt.id);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      _showError('Failed to delete item');
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return await showDialog<bool>(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: isDark ? Colors.black : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Delete Item?',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This will permanently delete this receipt and all associated data.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TetherButton(
                          label: 'Cancel',
                          isPrimary: false,
                          onPressed: () => Navigator.pop(context, false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TetherButton(
                          label: 'Delete',
                          onPressed: () => Navigator.pop(context, true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openPartsFinder(String platform) async {
    final query = Uri.encodeComponent('${_receipt.itemName} replacement parts');
    String url;

    switch (platform) {
      case 'ebay':
        url = 'https://www.ebay.com/sch/i.html?_nkw=$query';
        break;
      case 'amazon':
        url = 'https://www.amazon.com/s?k=$query';
        break;
      default:
        return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareReceipt() async {
    final content = _export.getShareableContent(_receipt);
    await Share.share(content, subject: 'Receipt: ${_receipt.itemName}');
  }

  Future<void> _exportAsText() async {
    try {
      final file = await _export.exportToText(_receipt);
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Receipt: ${_receipt.itemName}');
    } catch (e) {
      _showError('Failed to export receipt');
    }
  }

  Future<void> _exportAsHtml() async {
    try {
      final file = await _export.exportToHtml(_receipt);
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Receipt: ${_receipt.itemName}');
    } catch (e) {
      _showError('Failed to export receipt');
    }
  }

  void _showExportOptions() {
    ExportService.showExportOptions(
      context,
      _receipt,
      onShare: _shareReceipt,
      onExportText: _exportAsText,
      onExportHtml: _exportAsHtml,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2),
            onPressed: _showExportOptions,
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2),
            onPressed: _isDeleting ? null : _deleteReceipt,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            if (_receipt.imagePath != null) _buildImage(),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and price
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // Status cards
                  _buildStatusCards(),
                  const SizedBox(height: 24),

                  // Details section
                  _buildDetailsSection(),

                  // Part finder (if warranty expired)
                  if (_receipt.warrantyExpired) ...[
                    const SizedBox(height: 24),
                    _buildPartFinder(),
                  ],

                  // Extracted text
                  if (_receipt.extractedText != null &&
                      _receipt.extractedText!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildExtractedText(),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return GestureDetector(
      onTap: () => _showFullScreenImage(),
      child: Container(
        height: 200,
        width: double.infinity,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(_receipt.imagePath!), fit: BoxFit.cover),
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.expand, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'View full',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenImageViewer(imagePath: _receipt.imagePath!),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _receipt.itemName,
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (_receipt.storeName != null) ...[
              Text(
                _receipt.storeName!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.black.withValues(alpha: 0.5),
                ),
              ),
              Text(
                '  •  ',
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.2),
                ),
              ),
            ],
            Text(
              _receipt.category.displayName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        if (_receipt.price != null) ...[
          const SizedBox(height: 12),
          Text(
            '\$${_receipt.price!.toStringAsFixed(2)}',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusCards() {
    return Row(
      children: [
        Expanded(
          child: _StatusCard(
            icon: LucideIcons.calendar,
            label: 'Purchased',
            value: DateFormat('MMM dd, yyyy').format(_receipt.purchaseDate),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatusCard(
            icon: LucideIcons.timer,
            label: 'Warranty',
            value: _receipt.warrantyStatus,
            isUrgent: _receipt.isWarrantyExpiringSoon,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return TetherCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Receipt Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (_receipt.transactionId != null)
            _DetailRow(label: 'Transaction ID', value: _receipt.transactionId!),
          if (_receipt.barcode != null)
            _DetailRow(label: 'Barcode', value: _receipt.barcode!),
          _DetailRow(
            label: 'Purchase Date',
            value: DateFormat('MMMM dd, yyyy').format(_receipt.purchaseDate),
          ),
          if (_receipt.warrantyExpiry != null)
            _DetailRow(
              label: 'Warranty Expires',
              value: DateFormat(
                'MMMM dd, yyyy',
              ).format(_receipt.warrantyExpiry!),
            ),
          if (_receipt.returnDeadline != null && !_receipt.returnWindowClosed)
            _DetailRow(
              label: 'Return By',
              value: DateFormat(
                'MMMM dd, yyyy',
              ).format(_receipt.returnDeadline!),
              showDivider: false,
            ),
          if (_receipt.returnDeadline == null || _receipt.returnWindowClosed)
            _DetailRow(
              label: 'Category',
              value: _receipt.category.displayName,
              showDivider: false,
            ),
        ],
      ),
    );
  }

  Widget _buildPartFinder() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TetherCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
                child: const Icon(LucideIcons.wrench, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Warranty Expired',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Need replacement parts?',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _PartFinderButton(
                  label: 'eBay',
                  onTap: () => _openPartsFinder('ebay'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PartFinderButton(
                  label: 'Amazon',
                  onTap: () => _openPartsFinder('amazon'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedText() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TetherCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.fileText,
                size: 18,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                'Extracted Text (OCR)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _receipt.extractedText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                height: 1.5,
              ),
              maxLines: 10,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isUrgent;

  const _StatusCard({
    required this.icon,
    required this.label,
    required this.value,
    this.isUrgent = false,
  });

  @override
  Widget build(BuildContext context) {
    return TetherCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: isUrgent ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;

  const _DetailRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.5),
            ),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _PartFinderButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _PartFinderButton({required this.label, required this.onTap});

  @override
  State<_PartFinderButton> createState() => _PartFinderButtonState();
}

class _PartFinderButtonState extends State<_PartFinderButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _isPressed
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05))
              : Colors.transparent,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.15),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.externalLink, size: 16),
            const SizedBox(width: 8),
            Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final String imagePath;

  const _FullScreenImageViewer({required this.imagePath});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  final TransformationController _transformController =
      TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Receipt'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.rotateCcw),
            onPressed: () {
              _transformController.value = Matrix4.identity();
            },
            tooltip: 'Reset zoom',
          ),
        ],
      ),
      body: InteractiveViewer(
        transformationController: _transformController,
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.file(File(widget.imagePath), fit: BoxFit.contain),
        ),
      ),
    );
  }
}
