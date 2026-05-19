import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../models/supplier.dart';
import '../models/supplier_product.dart';
import '../providers/app_state.dart';
import '../widgets/common_widgets.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Proveedores')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openSupplierDialog(context, null),
        child: const Icon(Icons.add),
      ),
      body: s.suppliers.isEmpty
          ? const Center(
              child: Text('Sin proveedores. Agrega el primero.',
                  style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding:
                  const EdgeInsets.only(bottom: 80, top: 8),
              itemCount: s.suppliers.length,
              itemBuilder: (ctx, i) =>
                  _SupplierTile(supplier: s.suppliers[i]),
            ),
    );
  }

  static void _openSupplierDialog(BuildContext ctx, Supplier? sup) {
    showDialog(
        context: ctx,
        builder: (_) => _SupplierDialog(supplier: sup));
  }
}

// ─── Supplier tile with expansion ────────────────────────────────────────────

class _SupplierTile extends StatelessWidget {
  final Supplier supplier;
  const _SupplierTile({required this.supplier});

  @override
  Widget build(BuildContext context) {
    final sup = supplier;

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: kPink,
          child: Text(
            sup.name[0].toUpperCase(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(sup.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${sup.contact}${sup.phone.isNotEmpty ? '  |  ${sup.phone}' : ''}'),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') {
              showDialog(
                  context: context,
                  builder: (_) => _SupplierDialog(supplier: sup));
            }
            if (v == 'del') _confirmDelete(context, sup);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('✏️  Editar')),
            PopupMenuItem(
                value: 'del', child: Text('🗑️  Eliminar')),
          ],
        ),
        children: [
          if (sup.email.isNotEmpty ||
              sup.ruc.isNotEmpty ||
              sup.address.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sup.email.isNotEmpty)
                      Text('📧  ${sup.email}'),
                    if (sup.ruc.isNotEmpty)
                      Text('🏢  RUC: ${sup.ruc}'),
                    if (sup.address.isNotEmpty)
                      Text('📍  ${sup.address}'),
                  ]),
            ),
          if (sup.products.isNotEmpty) ...[
            const Divider(indent: 16, endIndent: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Productos y precios:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: kPink)),
            ),
            ...sup.products.map((sp) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24),
                  dense: true,
                  title: Text(sp.productName),
                  subtitle: Text('Unidad: ${sp.unit}'),
                  trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cur.format(sp.purchasePrice),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kPink)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.red),
                          onPressed: () => context
                              .read<AppState>()
                              .removeProductFromSupplier(sup, sp),
                        ),
                      ]),
                )),
          ],
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextButton.icon(
              onPressed: () => showDialog(
                  context: context,
                  builder: (_) =>
                      _SupplierProductDialog(supplier: sup)),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar producto/precio'),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, Supplier sup) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar proveedor'),
        content: Text('¿Eliminar "${sup.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              ctx.read<AppState>().deleteSupplier(sup.id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─── Supplier dialog ─────────────────────────────────────────────────────────

class _SupplierDialog extends StatefulWidget {
  final Supplier? supplier;
  const _SupplierDialog({this.supplier});

  @override
  State<_SupplierDialog> createState() => _SupplierDialogState();
}

class _SupplierDialogState extends State<_SupplierDialog> {
  late final TextEditingController _nameC, _contactC, _phoneC,
      _emailC, _rucC, _addressC;

  @override
  void initState() {
    super.initState();
    final s = widget.supplier;
    _nameC = TextEditingController(text: s?.name);
    _contactC = TextEditingController(text: s?.contact);
    _phoneC = TextEditingController(text: s?.phone);
    _emailC = TextEditingController(text: s?.email);
    _rucC = TextEditingController(text: s?.ruc);
    _addressC = TextEditingController(text: s?.address);
  }

  @override
  void dispose() {
    for (final c in [
      _nameC, _contactC, _phoneC, _emailC, _rucC, _addressC
    ]) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.supplier != null;
    final state = context.read<AppState>();

    return AlertDialog(
      title: Text(isEdit
          ? '✏️  Editar Proveedor'
          : '➕  Nuevo Proveedor'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          buildField(_nameC, 'Empresa o nombre *'),
          buildField(_contactC, 'Persona de contacto'),
          buildField(_phoneC, 'Teléfono'),
          buildField(_emailC, 'Email'),
          buildField(_rucC, 'RUC'),
          buildField(_addressC, 'Dirección'),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            if (_nameC.text.isEmpty) return;
            final ns = Supplier(
              id: widget.supplier?.id ??
                  DateTime.now()
                      .millisecondsSinceEpoch
                      .toString(),
              name: _nameC.text,
              contact: _contactC.text,
              phone: _phoneC.text,
              email: _emailC.text,
              ruc: _rucC.text,
              address: _addressC.text,
              products: widget.supplier?.products ?? [],
            );
            isEdit
                ? state.updateSupplier(ns)
                : state.addSupplier(ns);
            Navigator.pop(context);
          },
          child: Text(isEdit ? 'Guardar' : 'Agregar'),
        ),
      ],
    );
  }
}

// ─── Supplier product dialog ──────────────────────────────────────────────────

class _SupplierProductDialog extends StatefulWidget {
  final Supplier supplier;
  const _SupplierProductDialog({required this.supplier});

  @override
  State<_SupplierProductDialog> createState() =>
      _SupplierProductDialogState();
}

class _SupplierProductDialogState
    extends State<_SupplierProductDialog> {
  final _nameC = TextEditingController();
  final _priceC = TextEditingController();
  final _unitC = TextEditingController(text: 'kg');
  Product? _linked;

  @override
  void dispose() {
    _nameC.dispose();
    _priceC.dispose();
    _unitC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();

    return AlertDialog(
      title: const Text('Agregar Producto del Proveedor'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        if (state.products.isNotEmpty) ...[
          DropdownButtonFormField<Product?>(
            decoration: const InputDecoration(
                labelText: 'Vincular a inventario (opcional)'),
            value: _linked,
            items: [
              const DropdownMenuItem(
                  value: null, child: Text('No vincular')),
              ...state.products.map((p) => DropdownMenuItem(
                  value: p, child: Text(p.name))),
            ],
            onChanged: (p) => setState(() {
              _linked = p;
              if (p != null) {
                _nameC.text = p.name;
                _unitC.text = p.unit;
              }
            }),
          ),
          const SizedBox(height: 8),
        ],
        buildField(_nameC, 'Nombre del producto/insumo *'),
        buildField(_priceC, 'Precio de compra (\$) *', isNum: true),
        buildField(_unitC, 'Unidad (kg, litro, unidad...)'),
      ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            if (_nameC.text.isEmpty || _priceC.text.isEmpty) return;
            final sp = SupplierProduct(
              supplierId: widget.supplier.id,
              productId: _linked?.id ?? '',
              productName: _nameC.text,
              purchasePrice:
                  double.tryParse(_priceC.text) ?? 0,
              unit: _unitC.text.isEmpty ? 'unidad' : _unitC.text,
            );
            context
                .read<AppState>()
                .addProductToSupplier(widget.supplier, sp);
            Navigator.pop(context);
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}