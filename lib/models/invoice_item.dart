import 'product.dart';

class InvoiceItem {
  int? dbId;
  String? invoiceId;
  Product product;
  int quantity;
  double unitPrice;

  InvoiceItem({
    this.dbId,
    this.invoiceId,
    required this.product,
    required this.quantity,
    required this.unitPrice,
  });

  double get subtotal => quantity * unitPrice;

  Map<String, dynamic> toMap(String invoiceId) => {
        'invoiceId': invoiceId,
        'productId': product.id,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };
}