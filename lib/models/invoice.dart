import 'invoice_item.dart';

class Invoice {
  String id;
  String number;
  DateTime date;
  String clientName;
  String clientId;
  String clientEmail;
  List<InvoiceItem> items;
  double taxRate;
  bool isPaid;
  String notes;

  Invoice({
    required this.id,
    required this.number,
    required this.date,
    required this.clientName,
    this.clientId = '',
    this.clientEmail = '',
    required this.items,
    this.taxRate = 0.12,
    this.isPaid = false,
    this.notes = '',
  });

  double get subtotal => items.fold(0.0, (s, i) => s + i.subtotal);
  double get tax => subtotal * taxRate;
  double get total => subtotal + tax;
  double get cost =>
      items.fold(0.0, (s, i) => s + (i.product.cost * i.quantity));
  double get profit => total - cost;

  Map<String, dynamic> toMap() => {
        'id': id,
        'number': number,
        'date': date.toIso8601String(),
        'clientName': clientName,
        'clientId': clientId,
        'clientEmail': clientEmail,
        'taxRate': taxRate,
        'isPaid': isPaid ? 1 : 0,
        'notes': notes,
      };

  factory Invoice.fromMap(
          Map<String, dynamic> m, List<InvoiceItem> items) =>
      Invoice(
        id: m['id'] as String,
        number: m['number'] as String,
        date: DateTime.parse(m['date'] as String),
        clientName: m['clientName'] as String,
        clientId: m['clientId'] as String? ?? '',
        clientEmail: m['clientEmail'] as String? ?? '',
        items: items,
        taxRate: (m['taxRate'] as num?)?.toDouble() ?? 0.12,
        isPaid: (m['isPaid'] as int?) == 1,
        notes: m['notes'] as String? ?? '',
      );
}