import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> dispose() async {
    await _textRecognizer.close();
  }

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (image == null) return null;
    return File(image.path);
  }

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (image == null) return null;
    return File(image.path);
  }

  // Process image and extract text
  Future<OCRResult> processImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await _textRecognizer.processImage(
      inputImage,
    );

    String fullText = recognizedText.text;
    List<String> lines = [];

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        lines.add(line.text);
      }
    }

    // Extract key information
    final extractedData = _extractReceiptData(fullText, lines);

    return OCRResult(
      fullText: fullText,
      lines: lines,
      extractedData: extractedData,
    );
  }

  // Extract structured data from receipt text
  Map<String, String?> _extractReceiptData(
    String fullText,
    List<String> lines,
  ) {
    final data = <String, String?>{};

    // Extract store name (usually first non-empty line)
    for (final line in lines) {
      if (line.trim().isNotEmpty && line.length > 2) {
        data['storeName'] = line.trim();
        break;
      }
    }

    // Extract transaction ID patterns
    final transactionPatterns = [
      RegExp(
        r'(?:trans|transaction|txn|order|invoice|receipt)[\s#:]*([A-Z0-9-]+)',
        caseSensitive: false,
      ),
      RegExp(r'#\s*([A-Z0-9-]{6,})'),
      RegExp(r'(?:ref|reference)[\s#:]*([A-Z0-9-]+)', caseSensitive: false),
    ];

    for (final pattern in transactionPatterns) {
      final match = pattern.firstMatch(fullText);
      if (match != null) {
        data['transactionId'] = match.group(1);
        break;
      }
    }

    // Extract barcode/UPC patterns
    final barcodePattern = RegExp(r'\b(\d{8,14})\b');
    final barcodeMatch = barcodePattern.firstMatch(fullText);
    if (barcodeMatch != null) {
      data['barcode'] = barcodeMatch.group(1);
    }

    // Extract date patterns
    final datePatterns = [
      RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})'),
      RegExp(r'(\d{4}[/-]\d{1,2}[/-]\d{1,2})'),
      RegExp(r'(\w{3,9}\s+\d{1,2},?\s+\d{4})', caseSensitive: false),
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(fullText);
      if (match != null) {
        data['date'] = match.group(1);
        break;
      }
    }

    // Extract time patterns
    final timePattern = RegExp(
      r'(\d{1,2}:\d{2}(?::\d{2})?\s*(?:AM|PM)?)',
      caseSensitive: false,
    );
    final timeMatch = timePattern.firstMatch(fullText);
    if (timeMatch != null) {
      data['time'] = timeMatch.group(1);
    }

    // Extract total/price patterns
    final pricePatterns = [
      RegExp(
        r'(?:total|amount|grand total|subtotal)[\s:]*\$?([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(r'\$\s*([\d,]+\.\d{2})'),
    ];

    for (final pattern in pricePatterns) {
      final matches = pattern.allMatches(fullText);
      if (matches.isNotEmpty) {
        // Get the last match (usually the total)
        final lastMatch = matches.last;
        data['price'] = lastMatch.group(1)?.replaceAll(',', '');
        break;
      }
    }

    // Try to identify product names
    final productIndicators = ['item', 'product', 'description', 'qty'];
    for (int i = 0; i < lines.length; i++) {
      final lineLower = lines[i].toLowerCase();
      if (productIndicators.any((indicator) => lineLower.contains(indicator))) {
        // The next line might contain product info
        if (i + 1 < lines.length) {
          data['itemHint'] = lines[i + 1];
        }
        break;
      }
    }

    return data;
  }

  // Save image to app directory
  Future<String> saveImage(File imageFile, String receiptId) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${directory.path}/receipt_images');

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final extension = path.extension(imageFile.path);
    final savedPath = '${imagesDir.path}/$receiptId$extension';
    await imageFile.copy(savedPath);

    return savedPath;
  }

  // Delete saved image
  Future<void> deleteImage(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

class OCRResult {
  final String fullText;
  final List<String> lines;
  final Map<String, String?> extractedData;

  OCRResult({
    required this.fullText,
    required this.lines,
    required this.extractedData,
  });

  String? get storeName => extractedData['storeName'];
  String? get transactionId => extractedData['transactionId'];
  String? get barcode => extractedData['barcode'];
  String? get date => extractedData['date'];
  String? get time => extractedData['time'];
  String? get price => extractedData['price'];
  String? get itemHint => extractedData['itemHint'];

  bool get hasTransactionId =>
      transactionId != null && transactionId!.isNotEmpty;
  bool get hasBarcode => barcode != null && barcode!.isNotEmpty;
}
