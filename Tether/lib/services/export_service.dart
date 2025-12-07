import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/receipt.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  /// Generate a text summary of a receipt
  String generateReceiptSummary(Receipt receipt) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('MMM d, yyyy');

    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('           TETHER RECEIPT EXPORT');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln();
    buffer.writeln('ITEM DETAILS');
    buffer.writeln('───────────────────────────────────────');
    buffer.writeln('Name: ${receipt.itemName}');
    buffer.writeln('Category: ${receipt.category.displayName}');
    buffer.writeln('Store: ${receipt.storeName ?? 'N/A'}');
    if (receipt.price != null) {
      buffer.writeln('Price: \$${receipt.price!.toStringAsFixed(2)}');
    }
    buffer.writeln();
    buffer.writeln('PURCHASE INFORMATION');
    buffer.writeln('───────────────────────────────────────');
    buffer.writeln('Purchase Date: ${dateFormat.format(receipt.purchaseDate)}');

    if (receipt.warrantyExpiry != null) {
      buffer.writeln();
      buffer.writeln('WARRANTY');
      buffer.writeln('───────────────────────────────────────');
      buffer.writeln(
        'Warranty Expires: ${dateFormat.format(receipt.warrantyExpiry!)}',
      );
      buffer.writeln('Days Remaining: ${receipt.daysUntilWarrantyExpiry}');
      buffer.writeln(
        'Status: ${receipt.warrantyExpiry!.isAfter(DateTime.now()) ? 'Active' : 'Expired'}',
      );
    }

    if (receipt.returnDeadline != null) {
      buffer.writeln();
      buffer.writeln('RETURN WINDOW');
      buffer.writeln('───────────────────────────────────────');
      buffer.writeln(
        'Return By: ${dateFormat.format(receipt.returnDeadline!)}',
      );
      buffer.writeln('Days Remaining: ${receipt.daysUntilReturnDeadline}');
      buffer.writeln(
        'Status: ${receipt.returnDeadline!.isAfter(DateTime.now()) ? 'Open' : 'Closed'}',
      );
    }

    if (receipt.extractedText != null && receipt.extractedText!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('EXTRACTED TEXT');
      buffer.writeln('───────────────────────────────────────');
      buffer.writeln(receipt.extractedText);
    }

    buffer.writeln();
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('Exported from Tether');
    buffer.writeln('Export Date: ${dateFormat.format(DateTime.now())}');
    buffer.writeln('═══════════════════════════════════════');

    return buffer.toString();
  }

  /// Generate HTML content for a receipt (for PDF generation)
  String generateReceiptHtml(Receipt receipt) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      padding: 40px;
      max-width: 600px;
      margin: 0 auto;
      color: #1a1a1a;
    }
    .header {
      text-align: center;
      border-bottom: 2px solid #000;
      padding-bottom: 20px;
      margin-bottom: 30px;
    }
    .header h1 {
      font-size: 24px;
      margin: 0;
      letter-spacing: 4px;
    }
    .header p {
      color: #666;
      margin: 8px 0 0 0;
      font-size: 12px;
    }
    .section {
      margin-bottom: 24px;
    }
    .section-title {
      font-size: 11px;
      font-weight: 600;
      color: #666;
      text-transform: uppercase;
      letter-spacing: 1px;
      margin-bottom: 12px;
      border-bottom: 1px solid #eee;
      padding-bottom: 8px;
    }
    .row {
      display: flex;
      justify-content: space-between;
      padding: 8px 0;
    }
    .label {
      color: #666;
      font-size: 14px;
    }
    .value {
      font-weight: 500;
      font-size: 14px;
    }
    .status {
      display: inline-block;
      padding: 4px 12px;
      border-radius: 4px;
      font-size: 12px;
      font-weight: 600;
    }
    .status.active {
      background: #d4edda;
      color: #155724;
    }
    .status.expired {
      background: #f8d7da;
      color: #721c24;
    }
    .notes {
      background: #f8f9fa;
      padding: 16px;
      border-radius: 8px;
      font-size: 14px;
      line-height: 1.5;
    }
    .footer {
      margin-top: 40px;
      text-align: center;
      font-size: 12px;
      color: #999;
      border-top: 1px solid #eee;
      padding-top: 20px;
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>TETHER</h1>
    <p>Receipt & Warranty Record</p>
  </div>
  
  <div class="section">
    <div class="section-title">Item Details</div>
    <div class="row">
      <span class="label">Name</span>
      <span class="value">${_escapeHtml(receipt.itemName)}</span>
    </div>
    <div class="row">
      <span class="label">Category</span>
      <span class="value">${receipt.category.displayName}</span>
    </div>
    <div class="row">
      <span class="label">Store</span>
      <span class="value">${_escapeHtml(receipt.storeName ?? 'N/A')}</span>
    </div>
    ${receipt.price != null ? '''
    <div class="row">
      <span class="label">Price</span>
      <span class="value">\$${receipt.price!.toStringAsFixed(2)}</span>
    </div>
    ''' : ''}
    <div class="row">
      <span class="label">Purchase Date</span>
      <span class="value">${dateFormat.format(receipt.purchaseDate)}</span>
    </div>
  </div>
  
  ${receipt.warrantyExpiry != null ? '''
  <div class="section">
    <div class="section-title">Warranty</div>
    <div class="row">
      <span class="label">Expires</span>
      <span class="value">${dateFormat.format(receipt.warrantyExpiry!)}</span>
    </div>
    <div class="row">
      <span class="label">Status</span>
      <span class="status ${receipt.warrantyExpiry!.isAfter(DateTime.now()) ? 'active' : 'expired'}">
        ${receipt.warrantyExpiry!.isAfter(DateTime.now()) ? 'Active (${receipt.daysUntilWarrantyExpiry} days)' : 'Expired'}
      </span>
    </div>
  </div>
  ''' : ''}
  
  ${receipt.returnDeadline != null ? '''
  <div class="section">
    <div class="section-title">Return Window</div>
    <div class="row">
      <span class="label">Return By</span>
      <span class="value">${dateFormat.format(receipt.returnDeadline!)}</span>
    </div>
    <div class="row">
      <span class="label">Status</span>
      <span class="status ${receipt.returnDeadline!.isAfter(DateTime.now()) ? 'active' : 'expired'}">
        ${receipt.returnDeadline!.isAfter(DateTime.now()) ? 'Open (${receipt.daysUntilReturnDeadline} days)' : 'Closed'}
      </span>
    </div>
  </div>
  ''' : ''}
  
  ${receipt.extractedText != null && receipt.extractedText!.isNotEmpty ? '''
  <div class="section">
    <div class="section-title">Extracted Text</div>
    <div class="notes">${_escapeHtml(receipt.extractedText!)}</div>
  </div>
  ''' : ''}
  
  <div class="footer">
    Exported from Tether • ${dateFormat.format(DateTime.now())}
  </div>
</body>
</html>
''';
  }

  /// Export receipt to a text file
  Future<File> exportToText(Receipt receipt) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'tether_${receipt.itemName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.txt';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(generateReceiptSummary(receipt));
    return file;
  }

  /// Export receipt to an HTML file
  Future<File> exportToHtml(Receipt receipt) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'tether_${receipt.itemName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.html';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(generateReceiptHtml(receipt));
    return file;
  }

  /// Get shareable content for a receipt
  String getShareableContent(Receipt receipt) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final buffer = StringBuffer();

    buffer.writeln('📄 ${receipt.itemName}');
    buffer.writeln('🏪 ${receipt.storeName ?? 'Unknown store'}');
    if (receipt.price != null) {
      buffer.writeln('💰 \$${receipt.price!.toStringAsFixed(2)}');
    }
    buffer.writeln('📅 Purchased: ${dateFormat.format(receipt.purchaseDate)}');

    if (receipt.warrantyExpiry != null) {
      buffer.writeln(
        '🛡️ Warranty: ${dateFormat.format(receipt.warrantyExpiry!)} (${receipt.daysUntilWarrantyExpiry} days)',
      );
    }

    if (receipt.returnDeadline != null) {
      buffer.writeln(
        '↩️ Return by: ${dateFormat.format(receipt.returnDeadline!)} (${receipt.daysUntilReturnDeadline} days)',
      );
    }

    buffer.writeln();
    buffer.writeln('Shared from Tether');

    return buffer.toString();
  }

  /// Show export options bottom sheet
  static Future<void> showExportOptions(
    BuildContext context,
    Receipt receipt, {
    required VoidCallback onShare,
    required VoidCallback onExportText,
    required VoidCallback onExportHtml,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Colors.black : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Export Receipt',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              _ExportOption(
                icon: Icons.share_outlined,
                title: 'Share',
                subtitle: 'Share receipt details',
                onTap: () {
                  Navigator.pop(context);
                  onShare();
                },
              ),
              _ExportOption(
                icon: Icons.description_outlined,
                title: 'Export as Text',
                subtitle: 'Plain text file',
                onTap: () {
                  Navigator.pop(context);
                  onExportText();
                },
              ),
              _ExportOption(
                icon: Icons.code,
                title: 'Export as HTML',
                subtitle: 'Formatted document',
                onTap: () {
                  Navigator.pop(context);
                  onExportHtml();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, size: 24),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      onTap: onTap,
    );
  }
}
