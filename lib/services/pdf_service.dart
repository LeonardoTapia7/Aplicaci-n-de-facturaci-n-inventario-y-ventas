import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/invoice.dart';

class PdfService {
  static final _dateFmt = DateFormat('dd/MM/yyyy');
  static final _cur =
      NumberFormat.currency(locale: 'es_EC', symbol: '\$', decimalDigits: 2);
  static const _pink = PdfColor.fromInt(0xFFE91E8C);

  static Future<void> generateInvoicePdf(Invoice invoice) async {
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildHeader(invoice),
          pw.SizedBox(height: 20),
          pw.Divider(color: _pink, thickness: 1.5),
          pw.SizedBox(height: 12),
          _buildClient(invoice),
          pw.SizedBox(height: 16),
          _buildItemsTable(invoice),
          pw.SizedBox(height: 16),
          _buildTotals(invoice),
          if (invoice.notes.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text('Notas:',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.Text(invoice.notes,
                style: const pw.TextStyle(fontSize: 10)),
          ],
          pw.Spacer(),
          pw.Divider(color: _pink),
          pw.Center(
            child: pw.Text(
              '¡Gracias por su preferencia! — Dulce Camille',
              style: pw.TextStyle(
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                  color: _pink),
            ),
          ),
        ],
      ),
    ));

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  static pw.Widget _buildHeader(Invoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('DULCE CAMILLE',
              style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                  color: _pink)),
          pw.Text('',
              style: const pw.TextStyle(
                  fontSize: 11, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text('Quito, Ecuador',
              style: const pw.TextStyle(fontSize: 10)),
          pw.Text('RUC: 1700000000001',
              style: const pw.TextStyle(fontSize: 10)),
        ]),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _pink, width: 1.5),
            borderRadius:
                const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('FACTURA',
                  style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: _pink)),
              pw.SizedBox(height: 4),
              pw.Text('N° ${invoice.number}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(
                  'Fecha: ${_dateFmt.format(invoice.date)}',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: invoice.isPaid
                      ? PdfColors.green100
                      : PdfColors.orange100,
                  borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(12)),
                ),
                child: pw.Text(
                  invoice.isPaid ? 'PAGADO' : 'PENDIENTE',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                    color: invoice.isPaid
                        ? PdfColors.green800
                        : PdfColors.orange800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildClient(Invoice invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('DATOS DEL CLIENTE',
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _pink)),
        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius:
                pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Row(children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Nombre: ${invoice.clientName}',
                      style: const pw.TextStyle(fontSize: 11)),
                  if (invoice.clientId.isNotEmpty)
                    pw.Text('Cédula/RUC: ${invoice.clientId}',
                        style: const pw.TextStyle(fontSize: 11)),
                ],
              ),
            ),
            if (invoice.clientEmail.isNotEmpty)
              pw.Expanded(
                child: pw.Text('Email: ${invoice.clientEmail}',
                    style: const pw.TextStyle(fontSize: 11)),
              ),
          ]),
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(Invoice invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('DETALLE DE PRODUCTOS',
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _pink)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3.5),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFE91E8C)),
              children: ['Producto', 'Cant.', 'P. Unitario', 'Subtotal']
                  .map((h) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: pw.Text(h,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                fontSize: 10)),
                      ))
                  .toList(),
            ),
            ...invoice.items.asMap().entries.map((e) => pw.TableRow(
                  decoration: pw.BoxDecoration(
                      color: e.key.isEven
                          ? PdfColors.white
                          : PdfColors.grey50),
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(7),
                        child: pw.Text(e.value.product.name,
                            style:
                                const pw.TextStyle(fontSize: 10))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(7),
                        child: pw.Text('${e.value.quantity}',
                            style:
                                const pw.TextStyle(fontSize: 10))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(7),
                        child: pw.Text(
                            _cur.format(e.value.unitPrice),
                            style:
                                const pw.TextStyle(fontSize: 10))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(7),
                        child: pw.Text(
                            _cur.format(e.value.subtotal),
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10))),
                  ],
                )),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTotals(Invoice invoice) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 210,
        child: pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius:
                pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(children: [
            _pdfRow('Subtotal sin IVA:', _cur.format(invoice.subtotal)),
            pw.SizedBox(height: 4),
            _pdfRow('IVA 12%:', _cur.format(invoice.tax)),
            pw.Divider(color: PdfColors.grey400),
            _pdfRow('TOTAL:', _cur.format(invoice.total),
                bold: true, color: _pink),
          ]),
        ),
      ),
    );
  }

  static pw.Widget _pdfRow(String label, String value,
      {bool bold = false, PdfColor? color}) {
    final style = pw.TextStyle(
      fontWeight:
          bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontSize: bold ? 11 : 10,
      color: color,
    );
    return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ]);
  }
}