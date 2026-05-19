import 'package:flutter/material.dart';

import '../widgets/common_widgets.dart';
import 'dashboard_screen.dart';
import 'inventory_screen.dart';
import 'invoices_screen.dart';
import 'reports_screen.dart';
import 'suppliers_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;

  static const _screens = [
    DashboardScreen(),
    InventoryScreen(),
    InvoicesScreen(),
    SuppliersScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_rounded),
              label: 'Inventario'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Facturas'),
          NavigationDestination(
              icon: Icon(Icons.store_rounded),
              label: 'Proveedores'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Reportes'),
        ],
      ),
    );
  }
}