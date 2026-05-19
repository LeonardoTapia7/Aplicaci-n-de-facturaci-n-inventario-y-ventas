import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../models/product.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/supplier.dart';
import '../models/supplier_product.dart';

class DBHelper {
  // Singleton
  static final DBHelper instance = DBHelper._init();
  static Database? _db;
  DBHelper._init();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'dulce_camille.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id        TEXT PRIMARY KEY,
        name      TEXT NOT NULL,
        category  TEXT NOT NULL DEFAULT '',
        cost      REAL NOT NULL,
        salePrice REAL NOT NULL,
        stock     INTEGER NOT NULL DEFAULT 0,
        unit      TEXT NOT NULL DEFAULT 'unidad'
      )
    ''');

    await db.execute('''
      CREATE TABLE invoices (
        id          TEXT PRIMARY KEY,
        number      TEXT NOT NULL,
        date        TEXT NOT NULL,
        clientName  TEXT NOT NULL,
        clientId    TEXT NOT NULL DEFAULT '',
        clientEmail TEXT NOT NULL DEFAULT '',
        taxRate     REAL NOT NULL DEFAULT 0.12,
        isPaid      INTEGER NOT NULL DEFAULT 0,
        notes       TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE invoice_items (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceId  TEXT NOT NULL,
        productId  TEXT NOT NULL,
        quantity   INTEGER NOT NULL,
        unitPrice  REAL NOT NULL,
        FOREIGN KEY (invoiceId) REFERENCES invoices(id) ON DELETE CASCADE,
        FOREIGN KEY (productId) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE suppliers (
        id      TEXT PRIMARY KEY,
        name    TEXT NOT NULL,
        contact TEXT NOT NULL DEFAULT '',
        phone   TEXT NOT NULL DEFAULT '',
        email   TEXT NOT NULL DEFAULT '',
        ruc     TEXT NOT NULL DEFAULT '',
        address TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE supplier_products (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        supplierId    TEXT NOT NULL,
        productId     TEXT NOT NULL DEFAULT '',
        productName   TEXT NOT NULL,
        purchasePrice REAL NOT NULL,
        unit          TEXT NOT NULL DEFAULT 'unidad',
        FOREIGN KEY (supplierId) REFERENCES suppliers(id) ON DELETE CASCADE
      )
    ''');
  }

  // ─────────────────────────────────────────────────
  //  PRODUCTS
  // ─────────────────────────────────────────────────

  Future<List<Product>> getProducts() async {
    final db = await database;
    final rows = await db.query('products', orderBy: 'name ASC');
    return rows.map(Product.fromMap).toList();
  }

  Future<void> insertProduct(Product p) async {
    final db = await database;
    await db.insert('products', p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProduct(Product p) async {
    final db = await database;
    await db.update('products', p.toMap(),
        where: 'id = ?', whereArgs: [p.id]);
  }

  Future<void> deleteProduct(String id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────────
  //  INVOICES
  // ─────────────────────────────────────────────────

  Future<List<Invoice>> getInvoices(Map<String, Product> productMap) async {
    final db = await database;
    final invRows = await db.query('invoices', orderBy: 'date DESC');
    final invoices = <Invoice>[];

    for (final row in invRows) {
      final itemRows = await db.query(
        'invoice_items',
        where: 'invoiceId = ?',
        whereArgs: [row['id']],
      );

      final items = itemRows.map((ir) {
        final pid = ir['productId'] as String;
        final product = productMap[pid] ??
            Product(
                id: pid,
                name: '(Eliminado)',
                cost: 0,
                salePrice: 0);
        return InvoiceItem(
          dbId: ir['id'] as int?,
          invoiceId: ir['invoiceId'] as String,
          product: product,
          quantity: ir['quantity'] as int,
          unitPrice: (ir['unitPrice'] as num).toDouble(),
        );
      }).toList();

      invoices.add(Invoice.fromMap(row, items));
    }
    return invoices;
  }

  Future<void> insertInvoice(Invoice inv) async {
    final db = await database;
    await db.insert('invoices', inv.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    for (final item in inv.items) {
      await db.insert('invoice_items', item.toMap(inv.id));
    }
  }

  Future<void> updateInvoicePaid(String id, bool isPaid) async {
    final db = await database;
    await db.update(
      'invoices',
      {'isPaid': isPaid ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteInvoice(String id) async {
    final db = await database;
    // CASCADE handles invoice_items deletion
    await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────────────
  //  SUPPLIERS
  // ─────────────────────────────────────────────────

  Future<List<Supplier>> getSuppliers() async {
    final db = await database;
    final supRows = await db.query('suppliers', orderBy: 'name ASC');
    final suppliers = <Supplier>[];

    for (final row in supRows) {
      final spRows = await db.query(
        'supplier_products',
        where: 'supplierId = ?',
        whereArgs: [row['id']],
      );
      final products = spRows.map(SupplierProduct.fromMap).toList();
      suppliers.add(Supplier.fromMap(row, products));
    }
    return suppliers;
  }

  Future<void> insertSupplier(Supplier s) async {
    final db = await database;
    await db.insert('suppliers', s.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateSupplier(Supplier s) async {
    final db = await database;
    await db.update('suppliers', s.toMap(),
        where: 'id = ?', whereArgs: [s.id]);
    // Sync supplier_products: delete all, re-insert
    await db.delete('supplier_products',
        where: 'supplierId = ?', whereArgs: [s.id]);
    for (final sp in s.products) {
      await db.insert('supplier_products', sp.toMap());
    }
  }

  Future<void> deleteSupplier(String id) async {
    final db = await database;
    // CASCADE handles supplier_products deletion
    await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }
}