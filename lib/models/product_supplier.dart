// lib/models/product_supplier.dart

class ProductSupplier {
  final int? id;
  final int productId;
  final String supplierName;
  final double purchasePrice;
  final int quantity;
  final DateTime dateAdded;
  final String? notes;

  ProductSupplier({
    this.id,
    required this.productId,
    required this.supplierName,
    required this.purchasePrice,
    required this.quantity,
    DateTime? dateAdded,
    this.notes,
  }) : dateAdded = dateAdded ?? DateTime.now();

  factory ProductSupplier.fromMap(Map<String, dynamic> map) {
    return ProductSupplier(
      id: map['id'] as int?,
      productId: map['productId'] as int,
      supplierName: map['supplierName'] as String,
      purchasePrice: (map['purchasePrice'] as num).toDouble(),
      quantity: map['quantity'] as int,
      dateAdded: DateTime.parse(map['dateAdded'] as String),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'supplierName': supplierName,
      'purchasePrice': purchasePrice,
      'quantity': quantity,
      'dateAdded': dateAdded.toIso8601String(),
      'notes': notes,
    };
  }

  ProductSupplier copyWith({
    int? id,
    int? productId,
    String? supplierName,
    double? purchasePrice,
    int? quantity,
    DateTime? dateAdded,
    String? notes,
  }) {
    return ProductSupplier(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      supplierName: supplierName ?? this.supplierName,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      quantity: quantity ?? this.quantity,
      dateAdded: dateAdded ?? this.dateAdded,
      notes: notes ?? this.notes,
    );
  }
}
