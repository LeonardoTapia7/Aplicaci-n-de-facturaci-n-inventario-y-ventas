import 'dart:math';
import 'package:flutter/foundation.dart';

import '../database/db_helper.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../models/supplier_product.dart';

class AppState extends ChangeNotifier {
  final _db = DBHelper.instance;

  List<Product> _products = [];
  List<Invoice> _invoices = [];
  List<Supplier> _suppliers = [];
  int _invoiceCounter = 1;
  bool isLoading = true;

  List<Product> get products => _products;
  List<Invoice> get invoices => _invoices;
  List<Supplier> get suppliers => _suppliers;

  // ─── Init: load everything from DB ───────────────
  Future<void> init() async {
    _products = await _db.getProducts();
    final productMap = {for (final p in _products) p.id: p};
    _invoices = await _db.getInvoices(productMap);
    _suppliers = await _db.getSuppliers();
    _computeInvoiceCounter();
    isLoading = false;
    notifyListeners();
  }

  void _computeInvoiceCounter() {
    if (_invoices.isEmpty) { _invoiceCounter = 1; return; }
    final nums = _invoices.map((inv) {
      final raw = inv.number.replaceAll('FAC-', '');
      return int.tryParse(raw) ?? 0;
    });
    _invoiceCounter = nums.reduce(max) + 1;
  }

  // ─── Products ────────────────────────────────────
  Future<void> addProduct(Product p) async {
    await _db.insertProduct(p);
    _products.add(p);
    _products.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> updateProduct(Product p) async {
    await _db.updateProduct(p);
    final i = _products.indexWhere((x) => x.id == p.id);
    if (i >= 0) _products[i] = p;
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    await _db.deleteProduct(id);
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  String generateProductId() {
    if (_products.isEmpty) return 'P001';
    final nums = _products.map((p) {
      final raw = p.id.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(raw) ?? 0;
    });
    final next = nums.reduce(max) + 1;
    return 'P${next.toString().padLeft(3, '0')}';
  }

  // ─── Invoices ────────────────────────────────────
  Future<void> addInvoice(Invoice inv) async {
    await _db.insertInvoice(inv);
    _invoices.insert(0, inv);
    _invoiceCounter++;
    // Discount stock
    for (final item in inv.items) {
      final i = _products.indexWhere((p) => p.id == item.product.id);
      if (i >= 0 && _products[i].stock >= item.quantity) {
        _products[i].stock -= item.quantity;
        await _db.updateProduct(_products[i]);
      }
    }
    notifyListeners();
  }

  String generateInvoiceNumber() =>
      'FAC-${_invoiceCounter.toString().padLeft(4, '0')}';

  Future<void> toggleInvoicePaid(String id) async {
    final i = _invoices.indexWhere((inv) => inv.id == id);
    if (i >= 0) {
      _invoices[i].isPaid = !_invoices[i].isPaid;
      await _db.updateInvoicePaid(id, _invoices[i].isPaid);
    }
    notifyListeners();
  }

  Future<void> deleteInvoice(String id) async {
    await _db.deleteInvoice(id);
    _invoices.removeWhere((inv) => inv.id == id);
    notifyListeners();
  }

  // ─── Suppliers ───────────────────────────────────
  Future<void> addSupplier(Supplier s) async {
    await _db.insertSupplier(s);
    _suppliers.add(s);
    _suppliers.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> updateSupplier(Supplier s) async {
    await _db.updateSupplier(s);
    final i = _suppliers.indexWhere((x) => x.id == s.id);
    if (i >= 0) _suppliers[i] = s;
    notifyListeners();
  }

  Future<void> deleteSupplier(String id) async {
    await _db.deleteSupplier(id);
    _suppliers.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  // Helper: add a product to an existing supplier and persist
  Future<void> addProductToSupplier(Supplier s, SupplierProduct sp) async {
    sp.supplierId == '' ? sp = SupplierProduct(
      supplierId: s.id,
      productId: sp.productId,
      productName: sp.productName,
      purchasePrice: sp.purchasePrice,
      unit: sp.unit,
    ) : sp;
    s.products.add(sp);
    await _db.updateSupplier(s);
    notifyListeners();
  }

  Future<void> removeProductFromSupplier(
      Supplier s, SupplierProduct sp) async {
    s.products.remove(sp);
    await _db.updateSupplier(s);
    notifyListeners();
  }

  // ─── Analytics ───────────────────────────────────
  double get totalRevenue =>
      _invoices.fold(0.0, (s, inv) => s + inv.total);
  double get totalCost =>
      _invoices.fold(0.0, (s, inv) => s + inv.cost);
  double get totalProfit => totalRevenue - totalCost;
  double get profitMargin =>
      totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0;
  int get paidInvoices => _invoices.where((i) => i.isPaid).length;
  int get pendingInvoices => _invoices.where((i) => !i.isPaid).length;
  double get pendingAmount =>
      _invoices.where((i) => !i.isPaid).fold(0.0, (s, inv) => s + inv.total);
}