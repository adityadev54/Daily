import 'package:uuid/uuid.dart';

enum ItemCategory {
  electronics,
  clothing,
  appliances,
  furniture,
  automotive,
  other,
}

extension ItemCategoryExtension on ItemCategory {
  String get displayName {
    switch (this) {
      case ItemCategory.electronics:
        return 'Electronics';
      case ItemCategory.clothing:
        return 'Clothing';
      case ItemCategory.appliances:
        return 'Appliances';
      case ItemCategory.furniture:
        return 'Furniture';
      case ItemCategory.automotive:
        return 'Automotive';
      case ItemCategory.other:
        return 'Other';
    }
  }

  int get defaultWarrantyMonths {
    switch (this) {
      case ItemCategory.electronics:
        return 12;
      case ItemCategory.clothing:
        return 0;
      case ItemCategory.appliances:
        return 24;
      case ItemCategory.furniture:
        return 12;
      case ItemCategory.automotive:
        return 36;
      case ItemCategory.other:
        return 12;
    }
  }

  int get defaultReturnDays {
    switch (this) {
      case ItemCategory.electronics:
        return 30;
      case ItemCategory.clothing:
        return 30;
      case ItemCategory.appliances:
        return 30;
      case ItemCategory.furniture:
        return 14;
      case ItemCategory.automotive:
        return 7;
      case ItemCategory.other:
        return 30;
    }
  }
}

class Receipt {
  final String id;
  final String itemName;
  final String? storeName;
  final String? transactionId;
  final String? barcode;
  final DateTime purchaseDate;
  final DateTime? warrantyExpiry;
  final DateTime? returnDeadline;
  final double? price;
  final String? imagePath;
  final String? extractedText;
  final ItemCategory category;
  final bool isNewPurchase;
  final bool warrantyExpired;
  final bool returnWindowClosed;
  final DateTime createdAt;
  final DateTime updatedAt;

  Receipt({
    String? id,
    required this.itemName,
    this.storeName,
    this.transactionId,
    this.barcode,
    required this.purchaseDate,
    this.warrantyExpiry,
    this.returnDeadline,
    this.price,
    this.imagePath,
    this.extractedText,
    this.category = ItemCategory.other,
    this.isNewPurchase = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       warrantyExpired =
           warrantyExpiry != null && warrantyExpiry.isBefore(DateTime.now()),
       returnWindowClosed =
           returnDeadline != null && returnDeadline.isBefore(DateTime.now()),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  int get daysUntilWarrantyExpiry {
    if (warrantyExpiry == null) return -1;
    return warrantyExpiry!.difference(DateTime.now()).inDays;
  }

  int get daysUntilReturnDeadline {
    if (returnDeadline == null) return -1;
    return returnDeadline!.difference(DateTime.now()).inDays;
  }

  bool get isWarrantyExpiringSoon {
    final days = daysUntilWarrantyExpiry;
    return days >= 0 && days <= 30;
  }

  bool get isReturnDeadlineSoon {
    final days = daysUntilReturnDeadline;
    return days >= 0 && days <= 7;
  }

  String get warrantyStatus {
    if (warrantyExpiry == null) return 'No warranty';
    if (warrantyExpired) return 'Expired';
    final days = daysUntilWarrantyExpiry;
    if (days <= 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';
    if (days <= 7) return 'Expires in $days days';
    if (days <= 30) return 'Expires in $days days';
    if (days <= 365) {
      final months = (days / 30).floor();
      return 'Expires in $months month${months > 1 ? 's' : ''}';
    }
    final years = (days / 365).floor();
    return 'Expires in $years year${years > 1 ? 's' : ''}';
  }

  String get returnStatus {
    if (returnDeadline == null) return 'No return policy';
    if (returnWindowClosed) return 'Return window closed';
    final days = daysUntilReturnDeadline;
    if (days <= 0) return 'Last day to return';
    if (days == 1) return '1 day left to return';
    return '$days days left to return';
  }

  Receipt copyWith({
    String? itemName,
    String? storeName,
    String? transactionId,
    String? barcode,
    DateTime? purchaseDate,
    DateTime? warrantyExpiry,
    DateTime? returnDeadline,
    double? price,
    String? imagePath,
    String? extractedText,
    ItemCategory? category,
    bool? isNewPurchase,
  }) {
    return Receipt(
      id: id,
      itemName: itemName ?? this.itemName,
      storeName: storeName ?? this.storeName,
      transactionId: transactionId ?? this.transactionId,
      barcode: barcode ?? this.barcode,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      warrantyExpiry: warrantyExpiry ?? this.warrantyExpiry,
      returnDeadline: returnDeadline ?? this.returnDeadline,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
      extractedText: extractedText ?? this.extractedText,
      category: category ?? this.category,
      isNewPurchase: isNewPurchase ?? this.isNewPurchase,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemName': itemName,
      'storeName': storeName,
      'transactionId': transactionId,
      'barcode': barcode,
      'purchaseDate': purchaseDate.toIso8601String(),
      'warrantyExpiry': warrantyExpiry?.toIso8601String(),
      'returnDeadline': returnDeadline?.toIso8601String(),
      'price': price,
      'imagePath': imagePath,
      'extractedText': extractedText,
      'category': category.index,
      'isNewPurchase': isNewPurchase ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      id: map['id'] as String,
      itemName: map['itemName'] as String,
      storeName: map['storeName'] as String?,
      transactionId: map['transactionId'] as String?,
      barcode: map['barcode'] as String?,
      purchaseDate: DateTime.parse(map['purchaseDate'] as String),
      warrantyExpiry: map['warrantyExpiry'] != null
          ? DateTime.parse(map['warrantyExpiry'] as String)
          : null,
      returnDeadline: map['returnDeadline'] != null
          ? DateTime.parse(map['returnDeadline'] as String)
          : null,
      price: map['price'] as double?,
      imagePath: map['imagePath'] as String?,
      extractedText: map['extractedText'] as String?,
      category: ItemCategory.values[map['category'] as int],
      isNewPurchase: (map['isNewPurchase'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
