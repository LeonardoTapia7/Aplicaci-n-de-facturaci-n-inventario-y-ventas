import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/invoice.dart';
import '../providers/app_state.dart';
import '../services/pdf_service.dart';
import '../widgets/common_widgets.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final Invoice invoice;
  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(invoice.number),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Descargar PDF',
            onPressed: () => PdfService.generateInvoicePdf(invoice),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'toggle') {
                s.toggleInvoicePaid(invoice.id);
                Navigator.pop(context);
              }
              if (v == 'del') _confirmDelete(context, s);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'toggle',
                child: Text(invoice.isPaid
                    ? '🔄  Marcar como Pendiente'
                    : '✅  Marcar como Pagado'),
              ),
              const PopupMenuItem(
                  value: 'del',
                  child: Text('🗑️  Eliminar Factura')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(invoice.number,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        StatusBadge(
                            invoice.isPaid
                                ? 'PAGADO'
                                : 'PENDIENTE',
                            invoice.isPaid
                                ? Colors.green
                                : Colors.orange),
                      ]),
                  const SizedBox(height: 6),
                  Text('Fecha: ${dateFmt.format(invoice.date)}',
                      style: const TextStyle(color: Colors.grey)),
                  const Divider(height: 20),
                  const Text('CLIENTE',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: kPink)),
                  const SizedBox(height: 4),
                  Text(invoice.clientName,
                      style: const TextStyle(fontSize: 15)),
                  if (invoice.clientId.isNotEmpty)
                    Text('CI/RUC: ${invoice.clientId}'),
                  if (invoice.clientEmail.isNotEmpty)
                    Text('Email: ${invoice.clientEmail}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const SectionTitle('PRODUCTOS'),
          const SizedBox(height: 6),
          ...invoice.items.map((item) => Card(
                child: ListTile(
                  title: Text(item.product.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${item.quantity} ${item.product.unit}(s) × ${cur.format(item.unitPrice)}'),
                  trailing: Text(cur.format(item.subtotal),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
              )),
          const SizedBox(height: 12),
          // Totals + profit
          Card(
            color: kPinkLight,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                _dRow('Subtotal:', cur.format(invoice.subtotal)),
                _dRow('IVA 12%:', cur.format(invoice.tax)),
                const Divider(),
                _dRow('TOTAL:', cur.format(invoice.total),
                    color: kPink, bold: true),
                const Divider(),
                _dRow('Costo de producción:',
                    cur.format(invoice.cost),
                    color: Colors.orange),
                _dRow('Ganancia neta:',
                    cur.format(invoice.profit),
                    color: Colors.green,
                    bold: true),
              ]),
            ),
          ),
          if (invoice.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Notas:',
                          style:
                              TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(invoice.notes),
                    ]),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(14),
                  textStyle: const TextStyle(fontSize: 16)),
              onPressed: () =>
                  PdfService.generateInvoicePdf(invoice),
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('Imprimir / Descargar PDF'),
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _dRow(String l, String v,
      {Color? color, bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l,
                  style: TextStyle(
                      color: color,
                      fontWeight:
                          bold ? FontWeight.bold : null)),
              Text(v,
                  style: TextStyle(
                      color: color,
                      fontWeight: bold
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: bold ? 15 : 13)),
            ]),
      );

  void _confirmDelete(BuildContext context, AppState s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Factura'),
        content: Text(
            '¿Eliminar ${invoice.number}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              s.deleteInvoice(invoice.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}