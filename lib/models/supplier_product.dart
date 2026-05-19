class SupplierProduct {
  int? dbId;
  String supplierId;
  String productId;
  String productName;
  double purchasePrice;
  String unit;

  SupplierProduct({
    this.dbId,
    required this.supplierId,
    required this.productId,
    required this.productName,
    required this.purchasePrice,
    this.unit = 'unidad',
  });

  Map<String, dynamic> toMap() => {
        'supplierId': supplierId,
        'productId': productId,
        'productName': productName,
        'purchasePrice': purchasePrice,
        'unit': unit,
      };

  factory SupplierProduct.fromMap(Map<String, dynamic> m) => SupplierProduct(
        dbId: m['id'] as int?,
        supplierId: m['supplierId'] as String,
        productId: m['productId'] as String? ?? '',
        productName: m['productName'] as String,
        purchasePrice: (m['purchasePrice'] as num).toDouble(),
        unit: m['unit'] as String? ?? 'unidad',
      );
}