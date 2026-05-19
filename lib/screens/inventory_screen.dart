import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/app_state.dart';
import '../widgets/common_widgets.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final q = _query.toLowerCase();
    final list = s.products
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.id.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Inventario')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openDialog(context, null),
        child: const Icon(Icons.add),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar por nombre, ID o categoría...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(
                  child: Text('Sin productos.',
                      style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) => _ProductTile(
                    product: list[i],
                    onEdit: () => _openDialog(ctx, list[i]),
                    onDelete: () => _confirmDelete(ctx, list[i]),
                  ),
                ),
        ),
      ]),
    );
  }

  void _confirmDelete(BuildContext ctx, Product p) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${p.name}" del inventario?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              ctx.read<AppState>().deleteProduct(p.id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openDialog(BuildContext ctx, Product? p) {
    showDialog(
      context: ctx,
      builder: (_) => _ProductDialog(product: p),
    );
  }
}

// ─── Product tile ─────────────────────────────────────────────────────────────

class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit, onDelete;
  const _ProductTile(
      {required this.product,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final margin = p.salePrice > 0
        ? ((p.salePrice - p.cost) / p.salePrice * 100)
        : 0.0;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: p.stock <= 5 ? Colors.red : kPink,
          child: Text(
            p.id.length >= 4 ? p.id.substring(1) : p.id,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(p.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${p.id}  |  ${p.category}'),
            Text(
                'Costo: ${cur.format(p.cost)}  →  Venta: ${cur.format(p.salePrice)}  (${margin.toStringAsFixed(0)}% margen)'),
            Row(children: [
              Icon(
                p.stock <= 5
                    ? Icons.warning_rounded
                    : Icons.check_circle_rounded,
                size: 13,
                color: p.stock <= 5 ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 4),
              Text('Stock: ${p.stock} ${p.unit}(s)',
                  style: TextStyle(
                      color: p.stock <= 5 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold)),
            ]),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'del') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('✏️  Editar')),
            PopupMenuItem(value: 'del', child: Text('🗑️  Eliminar')),
          ],
        ),
      ),
    );
  }
}

// ─── Add/Edit product dialog ──────────────────────────────────────────────────

class _ProductDialog extends StatefulWidget {
  final Product? product;
  const _ProductDialog({this.product});

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  late final TextEditingController _nameC, _catC, _costC, _priceC, _stockC, _unitC;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameC = TextEditingController(text: p?.name);
    _catC = TextEditingController(text: p?.category);
    _costC = TextEditingController(text: p?.cost.toStringAsFixed(2));
    _priceC = TextEditingController(text: p?.salePrice.toStringAsFixed(2));
    _stockC = TextEditingController(text: p?.stock.toString() ?? '0');
    _unitC = TextEditingController(text: p?.unit ?? 'unidad');
  }

  @override
  void dispose() {
    for (final c in [_nameC, _catC, _costC, _priceC, _stockC, _unitC]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validate() {
    if (_nameC.text.trim().isEmpty) return 'El nombre es obligatorio.';
    final cost = double.tryParse(_costC.text);
    if (cost == null || cost < 0) return 'El costo no puede ser negativo.';
    final price = double.tryParse(_priceC.text);
    if (price == null || price <= 0) return 'El precio de venta debe ser mayor a \$0.';
    if (cost > price) return 'El costo no puede ser mayor que el precio de venta.';
    final stock = int.tryParse(_stockC.text);
    if (stock == null || stock < 0) return 'El stock no puede ser negativo.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    final state = context.read<AppState>();

    return AlertDialog(
      title: Text(isEdit ? '✏️  Editar Producto' : '➕  Nuevo Producto'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          buildField(_nameC, 'Nombre *'),
          buildField(_catC, 'Categoría'),
          buildField(_costC, 'Costo de compra (\$) *', isNum: true),
          buildField(_priceC, 'Precio de venta (\$) *', isNum: true),
          buildField(_stockC, 'Stock inicial', isNum: true),
          buildField(_unitC, 'Unidad (unidad, kg, litro, docena...)'),
          if (_errorMsg != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(_errorMsg!,
                    style: const TextStyle(color: Colors.red, fontSize: 12))),
              ]),
            ),
          ],
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            final err = _validate();
            if (err != null) {
              setState(() => _errorMsg = err);
              return;
            }
            final np = Product(
              id: widget.product?.id ?? state.generateProductId(),
              name: _nameC.text.trim(),
              category: _catC.text.trim(),
              cost: double.parse(_costC.text),
              salePrice: double.parse(_priceC.text),
              stock: int.parse(_stockC.text),
              unit: _unitC.text.trim().isEmpty ? 'unidad' : _unitC.text.trim(),
            );
            isEdit ? state.updateProduct(np) : state.addProduct(np);
            Navigator.pop(context);
          },
          child: Text(isEdit ? 'Guardar' : 'Agregar'),
        ),
      ],
    );
  }
}