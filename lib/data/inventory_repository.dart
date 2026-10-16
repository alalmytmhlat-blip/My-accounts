import '../data/app_database.dart';

class Product {
  const Product({
    required this.id, required this.name, required this.code, required this.category,
    required this.unit, required this.quantity, required this.minimumQuantity,
    required this.purchasePriceMinor, required this.salePriceMinor,
  });
  final int id;
  final String name, code, category, unit;
  final double quantity, minimumQuantity;
  final int purchasePriceMinor, salePriceMinor;
  bool get isOutOfStock => quantity <= 0;
  bool get isLowStock => !isOutOfStock && quantity <= minimumQuantity;

  factory Product.fromMap(Map<String, Object?> row) => Product(
    id: row['id'] as int, name: row['name'] as String,
    code: row['code'] as String? ?? '', category: row['category'] as String? ?? '',
    unit: row['unit'] as String? ?? 'قطعة',
    quantity: (row['quantity'] as num?)?.toDouble() ?? 0,
    minimumQuantity: (row['minimum_quantity'] as num?)?.toDouble() ?? 0,
    purchasePriceMinor: row['purchase_price_minor'] as int? ?? 0,
    salePriceMinor: row['sale_price_minor'] as int? ?? 0,
  );
}

class InventorySummary {
  const InventorySummary({required this.productsCount, required this.lowStockCount,
    required this.outOfStockCount, required this.stockValueMinor});
  final int productsCount, lowStockCount, outOfStockCount, stockValueMinor;
}

class InventoryRepository {
  InventoryRepository(this.database);
  final AppDatabase database;

  Future<List<Product>> getProducts({String query = ''}) async {
    final rows = await database.db.query('products',
      where: "status = 'active' AND (name LIKE ? OR code LIKE ? OR category LIKE ?)",
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name COLLATE NOCASE');
    return rows.map(Product.fromMap).toList();
  }

  Future<InventorySummary> getSummary() async {
    final rows = await database.db.rawQuery('''
      SELECT COUNT(*) products_count,
      SUM(CASE WHEN quantity > 0 AND quantity <= minimum_quantity THEN 1 ELSE 0 END) low_count,
      SUM(CASE WHEN quantity <= 0 THEN 1 ELSE 0 END) out_count,
      COALESCE(SUM(quantity * purchase_price_minor), 0) stock_value
      FROM products WHERE status = 'active'
    ''');
    final row = rows.first;
    return InventorySummary(
      productsCount: (row['products_count'] as int?) ?? 0,
      lowStockCount: (row['low_count'] as int?) ?? 0,
      outOfStockCount: (row['out_count'] as int?) ?? 0,
      stockValueMinor: ((row['stock_value'] as num?) ?? 0).round(),
    );
  }

  Future<int> addProduct({
    required String name, String code = '', String category = '', String unit = 'قطعة',
    required double quantity, required double minimumQuantity,
    required int purchasePriceMinor, required int salePriceMinor,
  }) async {
    final now = DateTime.now().toIso8601String();
    return database.db.transaction((txn) async {
      final id = await txn.insert('products', {
        'name': name.trim(), 'code': code.trim(), 'category': category.trim(),
        'unit': unit.trim().isEmpty ? 'قطعة' : unit.trim(), 'quantity': quantity,
        'minimum_quantity': minimumQuantity, 'purchase_price_minor': purchasePriceMinor,
        'sale_price_minor': salePriceMinor, 'created_at': now, 'updated_at': now,
      });
      if (quantity > 0) {
        await txn.insert('stock_movements', {
          'product_id': id, 'change_quantity': quantity, 'quantity_after': quantity,
          'reason': 'رصيد افتتاحي', 'created_at': now,
        });
      }
      return id;
    });
  }

  Future<void> adjustStock({
    required int productId, required double change, required String reason, String note = '',
  }) async {
    if (change == 0) throw ArgumentError('يجب أن تكون حركة المخزون غير صفرية');
    await database.db.transaction((txn) async {
      final rows = await txn.query('products', columns: ['quantity'],
        where: 'id = ? AND status = ?', whereArgs: [productId, 'active'], limit: 1);
      if (rows.isEmpty) throw StateError('الصنف غير موجود');
      final current = (rows.first['quantity'] as num).toDouble();
      final next = current + change;
      if (next < 0) throw StateError('لا يمكن أن تصبح الكمية سالبة');
      final now = DateTime.now().toIso8601String();
      await txn.update('products', {'quantity': next, 'updated_at': now},
        where: 'id = ?', whereArgs: [productId]);
      await txn.insert('stock_movements', {
        'product_id': productId, 'change_quantity': change, 'quantity_after': next,
        'reason': reason, 'note': note.trim(), 'created_at': now,
      });
    });
  }
}
