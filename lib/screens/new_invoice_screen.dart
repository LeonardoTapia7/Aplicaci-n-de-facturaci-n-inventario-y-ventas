import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/product.dart';
import '../providers/app_state.dart';
import '../widgets/common_widgets.dart';

// ─── Validators ──────────────────────────────────────────────────────────────

String? validateEmail(String email) {
  if (email.isEmpty) return null; // optional field
  final re = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
  if (!re.hasMatch(email)) return 'Ingresa un correo válido (ej: nombre@dominio.com)';
  return null;
}

String? validateCedula(String value) {
  if (value.isEmpty) return null; // optional
  // Ecuador: cédula = 10 digits, RUC = 13 digits
  final digits = RegExp(r'^\d{10}$').hasMatch(value);
  final ruc    = RegExp(r'^\d{13}$').hasMatch(value);
  if (!digits && !ruc) return 'Debe ser cédula (10 dígitos) o RUC (13 dígitos)';
  // Basic Luhn-style check for Ecuador cédula (first 2 digits = province 01-24)
  if (digits) {
    final prov = int.parse(value.substring(0, 2));
    if (prov < 1 || prov > 24) return 'Cédula inválida (provincia incorrecta)';
    // Mod-10 verification
    int total = 0;
    for (int i = 0; i < 9; i++) {
      int d = int.parse(value[i]);
      if (i.isEven) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      total += d;
    }
    final check = (10 - (total % 10)) % 10;
    if (check != int.parse(value[9])) return 'Número de cédula inválido';
  }
  return null;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class NewInvoiceScreen extends StatefulWidget {
  const NewInvoiceScreen({super.key});
  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  final _nameC  = TextEditingController();
  final _idC    = TextEditingController();
  final _emailC = TextEditingController();
  final _notesC = TextEditingController();
  final List<InvoiceItem> _items = [];

  String? _emailError;
  String? _cedulaError;

  double get _subtotal => _items.fold(0.0, (s, i) => s + i.subtotal);
  double get _tax      => _subtotal * 0.12;
  double get _total    => _subtotal + _tax;

  @override
  void dispose() {
    for (final c in [_nameC, _idC, _emailC, _notesC]) c.dispose();
    super.dispose();
  }

  bool _validateClient() {
    final eErr = validateEmail(_emailC.text.trim());
    final cErr = validateCedula(_idC.text.trim());
    setState(() { _emailError = eErr; _cedulaError = cErr; });
    return eErr == null && cErr == null;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Factura')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('Datos del Cliente'),
          const SizedBox(height: 10),

          // Name
          buildField(_nameC, 'Nombre completo del cliente *'),

          // Cédula/RUC with digit-only input
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: _idC,
              decoration: InputDecoration(
                labelText: 'Cédula (10 dígitos) o RUC (13 dígitos)',
                errorText: _cedulaError,
                suffixIcon: _cedulaError == null && _idC.text.isNotEmpty
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(13),
              ],
              onChanged: (_) => setState(() {
                _cedulaError = validateCedula(_idC.text.trim());
              }),
            ),
          ),

          // Email with domain validation
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: _emailC,
              decoration: InputDecoration(
                labelText: 'Correo electrónico (ej: nombre@dominio.com)',
                errorText: _emailError,
                suffixIcon: _emailError == null && _emailC.text.isNotEmpty
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => setState(() {
                _emailError = validateEmail(_emailC.text.trim());
              }),
            ),
          ),

          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const SectionTitle('Productos'),
            ElevatedButton.icon(
              onPressed: s.products.isEmpty
                  ? null
                  : () => _showAddItemDialog(context, s),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar'),
            ),
          ]),
          const SizedBox(height: 8),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Agrega al menos un producto.',
                  style: TextStyle(color: Colors.grey)),
            )
          else
            ..._items.asMap().entries.map((e) => Card(
                  child: ListTile(
                    title: Text(e.value.product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${e.value.quantity} × ${cur.format(e.value.unitPrice)}'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(cur.format(e.value.subtotal),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red, size: 18),
                        onPressed: () =>
                            setState(() => _items.removeAt(e.key)),
                      ),
                    ]),
                  ),
                )),
          const SizedBox(height: 16),
          _TotalsCard(subtotal: _subtotal, tax: _tax, total: _total),
          const SizedBox(height: 10),
          buildField(_notesC, 'Notas u observaciones (opcional)'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(14),
                  textStyle: const TextStyle(fontSize: 16)),
              onPressed: (_items.isEmpty || _nameC.text.isEmpty)
                  ? null
                  : () {
                      if (!_validateClient()) return;
                      _submit(context);
                    },
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text('Emitir Factura'),
            ),
          ),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  void _submit(BuildContext context) {
    final state = context.read<AppState>();
    final inv = Invoice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      number: state.generateInvoiceNumber(),
      date: DateTime.now(),
      clientName: _nameC.text.trim(),
      clientId: _idC.text.trim(),
      clientEmail: _emailC.text.trim(),
      items: List.from(_items),
      notes: _notesC.text.trim(),
    );
    state.addInvoice(inv);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅  Factura ${inv.number} emitida'),
        backgroundColor: Colors.green));
  }

  void _showAddItemDialog(BuildContext ctx, AppState s) {
    Product? sel;
    final qC = TextEditingController(text: '1');
    final pC = TextEditingController();
    String? qError;
    String? pError;

    showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (c, ss) => AlertDialog(
          title: const Text('Agregar Producto'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<Product>(
              decoration: const InputDecoration(labelText: 'Producto *'),
              items: s.products
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text('${p.name}  (Stock: ${p.stock})',
                            overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (p) => ss(() {
                sel = p;
                pC.text = p?.salePrice.toStringAsFixed(2) ?? '';
              }),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: qC,
              decoration: InputDecoration(
                labelText: 'Cantidad *',
                errorText: qError,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) => ss(() {
                final q = int.tryParse(v);
                qError = (q == null || q <= 0)
                    ? 'Debe ser un número mayor a 0'
                    : null;
              }),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: pC,
              decoration: InputDecoration(
                labelText: 'Precio unitario (\$) *',
                errorText: pError,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => ss(() {
                final p = double.tryParse(v);
                pError = (p == null || p <= 0)
                    ? 'El precio debe ser mayor a \$0'
                    : null;
              }),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (sel == null) return;
                final qty   = int.tryParse(qC.text) ?? 0;
                final price = double.tryParse(pC.text) ?? 0;
                // Validate before adding
                ss(() {
                  qError = qty <= 0 ? 'Debe ser mayor a 0' : null;
                  pError = price <= 0 ? 'Debe ser mayor a \$0' : null;
                });
                if (qty <= 0 || price <= 0 || sel == null) return;
                setState(() => _items.add(InvoiceItem(
                      product: sel!,
                      quantity: qty,
                      unitPrice: price,
                    )));
                Navigator.pop(c);
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Totals card ──────────────────────────────────────────────────────────────

class _TotalsCard extends StatelessWidget {
  final double subtotal, tax, total;
  const _TotalsCard(
      {required this.subtotal, required this.tax, required this.total});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kPinkLight,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          _row('Subtotal (sin IVA):', cur.format(subtotal)),
          _row('IVA 12%:', cur.format(tax)),
          const Divider(),
          _row('TOTAL:', cur.format(total), big: true),
        ]),
      ),
    );
  }

  Widget _row(String l, String v, {bool big = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l,
              style: TextStyle(
                  fontWeight: big ? FontWeight.bold : FontWeight.normal,
                  fontSize: big ? 15 : 13)),
          Text(v,
              style: TextStyle(
                  fontWeight: big ? FontWeight.bold : FontWeight.normal,
                  fontSize: big ? 15 : 13,
                  color: big ? kPink : null)),
        ]),
      );
}