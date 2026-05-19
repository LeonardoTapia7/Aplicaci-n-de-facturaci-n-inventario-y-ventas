class Product {
  String id;
  String name;
  String category;
  double cost;
  double salePrice;
  int stock;
  String unit;

  Product({
    required this.id,
    required this.name,
    this.category = '',
    required this.cost,
    required this.salePrice,
    this.stock = 0,
    this.unit = 'unidad',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'cost': cost,
        'salePrice': salePrice,
        'stock': stock,
        'unit': unit,
      };

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        id: m['id'] as String,
        name: m['name'] as String,
        category: m['category'] as String? ?? '',
        cost: (m['cost'] as num).toDouble(),
        salePrice: (m['salePrice'] as num).toDouble(),
        stock: m['stock'] as int? ?? 0,
        unit: m['unit'] as String? ?? 'unidad',
      );

  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? cost,
    double? salePrice,
    int? stock,
    String? unit,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        cost: cost ?? this.cost,
        salePrice: salePrice ?? this.salePrice,
        stock: stock ?? this.stock,
        unit: unit ?? this.unit,
      );
}