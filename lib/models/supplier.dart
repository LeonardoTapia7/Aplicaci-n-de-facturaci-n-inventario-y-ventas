import 'supplier_product.dart';

class Supplier {
  String id;
  String name;
  String contact;
  String phone;
  String email;
  String ruc;
  String address;
  List<SupplierProduct> products;

  Supplier({
    required this.id,
    required this.name,
    this.contact = '',
    this.phone = '',
    this.email = '',
    this.ruc = '',
    this.address = '',
    List<SupplierProduct>? products,
  }) : products = products ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'contact': contact,
        'phone': phone,
        'email': email,
        'ruc': ruc,
        'address': address,
      };

  factory Supplier.fromMap(
          Map<String, dynamic> m, List<SupplierProduct> products) =>
      Supplier(
        id: m['id'] as String,
        name: m['name'] as String,
        contact: m['contact'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        email: m['email'] as String? ?? '',
        ruc: m['ruc'] as String? ?? '',
        address: m['address'] as String? ?? '',
        products: products,
      );
}