import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../widgets/common_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    if (s.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.cake_rounded, color: Colors.white),
          SizedBox(width: 8),
          Text('Dulce Camille',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('Resumen General'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              StatCard('Ingresos Totales', cur.format(s.totalRevenue),
                  Icons.trending_up_rounded, Colors.blue.shade700),
              StatCard('Costos Totales', cur.format(s.totalCost),
                  Icons.shopping_bag_rounded, Colors.orange.shade700),
              StatCard('Ganancia Neta', cur.format(s.totalProfit),
                  Icons.attach_money_rounded, Colors.green.shade700),
              StatCard('Margen',
                  '${s.profitMargin.toStringAsFixed(1)}%',
                  Icons.percent_rounded, kPink),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: StatCard('Pagadas', '${s.paidInvoices}',
                Icons.check_circle_rounded, Colors.green)),
            const SizedBox(width: 10),
            Expanded(child: StatCard('Pendientes', '${s.pendingInvoices}',
                Icons.pending_rounded, Colors.orange)),
            const SizedBox(width: 10),
            Expanded(child: StatCard('Por Cobrar',
                cur.format(s.pendingAmount),
                Icons.payments_rounded, Colors.red.shade600)),
          ]),
          const SizedBox(height: 20),
          const SectionTitle('Últimas Facturas'),
          const SizedBox(height: 6),
          if (s.invoices.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Sin facturas aún.',
                  style: TextStyle(color: Colors.grey)),
            )
          else
            ...s.invoices.take(3).map((inv) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          inv.isPaid ? Colors.green : Colors.orange,
                      child: Icon(
                          inv.isPaid
                              ? Icons.check
                              : Icons.pending,
                          color: Colors.white,
                          size: 18),
                    ),
                    title: Text(inv.number,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${inv.clientName} · ${dateFmt.format(inv.date)}'),
                    trailing: Text(cur.format(inv.total),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                  ),
                )),
          const SizedBox(height: 20),
          const SectionTitle('⚠️  Stock Bajo (≤ 5 unidades)'),
          const SizedBox(height: 6),
          if (s.products.where((p) => p.stock <= 5).isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('✅  Todo el stock está en buen nivel.',
                  style: TextStyle(color: Colors.green)),
            )
          else
            ...s.products.where((p) => p.stock <= 5).map((p) => Card(
                  color: Colors.red.shade50,
                  child: ListTile(
                    leading: const CircleAvatar(
                        backgroundColor: Colors.red,
                        child: Icon(Icons.warning_rounded,
                            color: Colors.white, size: 18)),
                    title: Text(p.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                    subtitle: Text('ID: ${p.id}  |  ${p.category}'),
                    trailing: Text('${p.stock} ${p.unit}(s)',
                        style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold)),
                  ),
                )),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}