import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/invoice.dart';
import '../providers/app_state.dart';
import '../widgets/common_widgets.dart';
import 'invoice_detail_screen.dart';
import 'new_invoice_screen.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Facturas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NewInvoiceScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Factura'),
      ),
      body: s.invoices.isEmpty
          ? const Center(
              child: Text('Sin facturas. Crea la primera.',
                  style: TextStyle(color: Colors.grey)))
          : Column(children: [
              // Hint bar
              Container(
                color: Colors.grey.shade100,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _hintChip(Icons.swipe_right_rounded, Colors.green,
                        'Desliza → para pagar'),
                    _hintChip(Icons.swipe_left_rounded, Colors.orange,
                        'Desliza ← para desmarcar'),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80, top: 4),
                  itemCount: s.invoices.length,
                  itemBuilder: (ctx, i) =>
                      _SwipeableInvoiceTile(invoice: s.invoices[i]),
                ),
              ),
            ]),
    );
  }

  Widget _hintChip(IconData icon, Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      );
}

// ─── Swipeable tile ───────────────────────────────────────────────────────────

class _SwipeableInvoiceTile extends StatelessWidget {
  final Invoice invoice;
  const _SwipeableInvoiceTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final inv = invoice;

    return Dismissible(
      key: ValueKey('${inv.id}_${inv.isPaid}'),
      // ── Swipe RIGHT → mark as paid (only when pending) ──────────────
      direction: inv.isPaid
          ? DismissDirection.startToEnd // will only allow left (handled below)
          : DismissDirection.horizontal,

      confirmDismiss: (dir) async {
        final state = context.read<AppState>();

        // Right swipe → mark as paid
        if (dir == DismissDirection.startToEnd) {
          if (!inv.isPaid) {
            state.toggleInvoicePaid(inv.id);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('✅  ${inv.number} marcada como pagada'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ));
          }
          return false; // don't remove the tile, just update
        }

        // Left swipe → ask confirmation to unmark (only if paid)
        if (dir == DismissDirection.endToStart) {
          if (!inv.isPaid) return false; // ignore left swipe on pending
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('¿Desmarcar como pagada?'),
              content: Text(
                  'La factura ${inv.number} volverá al estado Pendiente. ¿Estás seguro?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Sí, desmarcar'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            state.toggleInvoicePaid(inv.id);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('🔄  ${inv.number} marcada como pendiente'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ));
          }
          return false;
        }
        return false;
      },

      // Right background (→ paid)
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.green.shade500,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
          SizedBox(width: 8),
          Text('Marcar pagada',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ]),
      ),

      // Left background (← unmark)
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.orange.shade500,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text('Desmarcar',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          SizedBox(width: 8),
          Icon(Icons.undo_rounded, color: Colors.white, size: 28),
        ]),
      ),

      child: Card(
        child: ListTile(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => InvoiceDetailScreen(invoice: inv))),
          leading: CircleAvatar(
            backgroundColor: inv.isPaid ? Colors.green : Colors.orange,
            child: Icon(
                inv.isPaid ? Icons.check_rounded : Icons.pending_rounded,
                color: Colors.white,
                size: 18),
          ),
          title: Row(children: [
            Text(inv.number,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            StatusBadge(
                inv.isPaid ? 'PAGADO' : 'PENDIENTE',
                inv.isPaid ? Colors.green : Colors.orange),
          ]),
          subtitle:
              Text('${inv.clientName} · ${dateFmt.format(inv.date)}'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(cur.format(inv.total),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              Text('${inv.items.length} ítem(s)',
                  style: const TextStyle(
                      fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}