import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/app_state.dart';
import '../widgets/common_widgets.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes y Análisis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── General KPIs ──────────────────────────────────────────────
          const SectionTitle('📊  Análisis General'),
          const SizedBox(height: 10),
          Card(
            color: kPinkLight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _kpiRow('Total Ingresos (con IVA)',
                    cur.format(s.totalRevenue),
                    Colors.blue.shade700),
                _kpiRow('Total Costos (producción)',
                    cur.format(s.totalCost),
                    Colors.orange.shade700),
                const Divider(height: 20),
                _kpiRow('Ganancia Bruta',
                    cur.format(s.totalProfit),
                    Colors.green.shade700,
                    big: true),
                _kpiRow('Margen de ganancia',
                    '${s.profitMargin.toStringAsFixed(2)}%',
                    kPink,
                    big: true),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value:
                      (s.profitMargin / 100).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: Colors.white,
                  color: s.profitMargin >= 30
                      ? Colors.green
                      : Colors.orange,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 4),
                Text(
                  s.profitMargin >= 50
                      ? '✅ Excelente rentabilidad'
                      : s.profitMargin >= 30
                          ? '⚠️ Margen aceptable'
                          : s.totalRevenue == 0
                              ? 'Sin ventas registradas'
                              : '🔴 Margen bajo — revisa costos',
                  style: TextStyle(
                    fontSize: 12,
                    color: s.profitMargin >= 50
                        ? Colors.green
                        : s.profitMargin >= 30
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // ── Per-product ───────────────────────────────────────────────
          const SectionTitle('🧁  Rentabilidad por Producto'),
          const SizedBox(height: 8),
          if (s.products.isEmpty)
            const Text('Sin productos en inventario.',
                style: TextStyle(color: Colors.grey))
          else
            ...s.products.map((p) => _ProductProfitCard(product: p)),
          const SizedBox(height: 20),

          // ── Supplier comparison ───────────────────────────────────────
          const SectionTitle('🏪  Comparativa Proveedor vs Venta'),
          const SizedBox(height: 8),
          if (s.suppliers.isEmpty ||
              s.suppliers.every((sup) => sup.products.isEmpty))
            const Text(
                'Agrega productos a tus proveedores para ver la comparativa.',
                style: TextStyle(color: Colors.grey))
          else
            ...s.suppliers.expand((sup) => sup.products.map((sp) {
                  final linked = s.products
                      .cast<Product?>()
                      .firstWhere(
                        (p) =>
                            p?.id == sp.productId ||
                            (p?.name.toLowerCase().contains(
                                    sp.productName.toLowerCase()) ??
                                false),
                        orElse: () => null,
                      );
                  final diff = linked != null
                      ? linked.salePrice - sp.purchasePrice
                      : null;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(sp.productName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            Text('Proveedor: ${sup.name}',
                                style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12)),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                              children: [
                                _priceBox(
                                    'Precio proveedor',
                                    sp.purchasePrice,
                                    Colors.red.shade400,
                                    sp.unit),
                                const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.grey),
                                if (linked != null) ...[
                                  _priceBox(
                                      'Precio venta',
                                      linked.salePrice,
                                      Colors.blue.shade600,
                                      linked.unit),
                                  const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.grey),
                                  _priceBox(
                                      'Diferencia',
                                      diff!,
                                      diff >= 0
                                          ? Colors.green.shade600
                                          : Colors.red,
                                      sp.unit),
                                ] else
                                  const Text(
                                      'Sin vínculo en inventario',
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12)),
                              ],
                            ),
                          ]),
                    ),
                  );
                })),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _kpiRow(String l, String v, Color c,
      {bool big = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l, style: TextStyle(fontSize: big ? 14 : 13)),
              Text(v,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: big ? 16 : 13,
                      color: c)),
            ]),
      );

  Widget _priceBox(String l, double v, Color c, String unit) =>
      Column(children: [
        Text(cur.format(v),
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: c)),
        Text(l,
            style: const TextStyle(
                fontSize: 10, color: Colors.grey)),
        Text('por $unit',
            style: const TextStyle(
                fontSize: 9, color: Colors.grey)),
      ]);
}

// ─── Per-product card ─────────────────────────────────────────────────────────

class _ProductProfitCard extends StatelessWidget {
  final Product product;
  const _ProductProfitCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final margin = p.salePrice > 0
        ? ((p.salePrice - p.cost) / p.salePrice * 100)
        : 0.0;
    final gain = p.salePrice - p.cost;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(p.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14))),
                    Text('ID: ${p.id}',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _mini('Costo', cur.format(p.cost),
                            Colors.orange),
                        _mini('Precio venta',
                            cur.format(p.salePrice), Colors.blue),
                        _mini('Ganancia/unidad',
                            cur.format(gain), Colors.green),
                        _mini(
                            'Stock',
                            '${p.stock} ${p.unit}(s)',
                            p.stock <= 5
                                ? Colors.red
                                : Colors.grey),
                      ]),
                ),
                Column(children: [
                  Text('${margin.toStringAsFixed(1)}%',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: margin >= 30
                              ? Colors.green
                              : Colors.orange)),
                  const Text('Margen',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey)),
                ]),
              ]),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (margin / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: margin >= 50
                    ? Colors.green
                    : margin >= 30
                        ? Colors.orange
                        : Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Text(
                margin >= 50
                    ? '✅ Excelente margen'
                    : margin >= 30
                        ? '⚠️ Margen aceptable'
                        : '🔴 Margen bajo — revisar precio',
                style: TextStyle(
                    fontSize: 11,
                    color: margin >= 50
                        ? Colors.green
                        : margin >= 30
                            ? Colors.orange
                            : Colors.red),
              ),
            ]),
      ),
    );
  }

  Widget _mini(String l, String v, Color c) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(children: [
          Text('$l: ',
              style: const TextStyle(
                  fontSize: 12, color: Colors.black54)),
          Text(v,
              style: TextStyle(
                  fontSize: 12,
                  color: c,
                  fontWeight: FontWeight.bold)),
        ]),
      );
}