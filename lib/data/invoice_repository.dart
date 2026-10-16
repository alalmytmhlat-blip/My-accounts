import 'app_database.dart';

class InvoiceLineInput {
  const InvoiceLineInput({required this.productId, required this.quantity, required this.unitPriceMinor});
  final int productId;
  final double quantity;
  final int unitPriceMinor;
}

class InvoiceRecord {
  const InvoiceRecord({required this.id, required this.number, required this.type, required this.partyName,
    required this.totalMinor, required this.paidMinor, required this.status, required this.date, required this.dueDate});
  final int id, totalMinor, paidMinor;
  final String number, type, partyName, status, date;
  final String? dueDate;
  int get remainingMinor => totalMinor - paidMinor;
  factory InvoiceRecord.fromMap(Map<String, Object?> row) => InvoiceRecord(
    id: row['id'] as int, number: row['invoice_number'] as String,
    type: row['type'] as String, partyName: row['party_name'] as String? ?? 'بدون جهة',
    totalMinor: row['total_minor'] as int? ?? 0, paidMinor: row['paid_minor'] as int? ?? 0,
    status: row['status'] as String? ?? 'unpaid', date: row['invoice_date'] as String,
    dueDate: row['due_date'] as String?,
  );
}

class InvoiceRepository {
  InvoiceRepository(this.database);
  final AppDatabase database;

  Future<List<InvoiceRecord>> getInvoices({String? type}) async {
    final rows = await database.db.rawQuery('''
      SELECT i.*, COALESCE(p.name, 'بدون جهة') AS party_name
      FROM invoices i LEFT JOIN parties p ON p.id = i.party_id
      ${type == null ? '' : 'WHERE i.type = ?'}
      ORDER BY i.id DESC
    ''', type == null ? null : [type]);
    return rows.map(InvoiceRecord.fromMap).toList();
  }

  Future<int> createInvoice({
    required String type,
    required int partyId,
    required List<InvoiceLineInput> lines,
    required int paidMinor,
    required String invoiceDate,
    String? dueDate,
  }) async {
    if (type != 'sale' && type != 'purchase') throw ArgumentError('نوع الفاتورة غير صالح');
    if (lines.isEmpty) throw ArgumentError('أضف صنفًا واحدًا على الأقل');
    if (paidMinor < 0) throw ArgumentError('المبلغ المدفوع لا يمكن أن يكون سالبًا');
    final now = DateTime.now().toIso8601String();
    return database.db.transaction((txn) async {
      final partyRows = await txn.query('parties', columns: ['id', 'type', 'status'],
        where: 'id = ?', whereArgs: [partyId], limit: 1);
      if (partyRows.isEmpty || partyRows.first['status'] != 'active') {
        throw StateError('العميل أو المورد غير موجود أو غير نشط');
      }
      final expectedPartyType = type == 'sale' ? 'customer' : 'supplier';
      if (partyRows.first['type'] != expectedPartyType) {
        throw StateError(type == 'sale' ? 'فاتورة البيع تتطلب اختيار عميل' : 'فاتورة الشراء تتطلب اختيار مورد');
      }

      var totalMinor = 0;
      final prepared = <({int productId, String name, double quantity, int price, int lineTotal})>[];
      for (final line in lines) {
        if (line.quantity <= 0 || line.unitPriceMinor < 0) {
          throw ArgumentError('تحقق من الكمية والسعر لكل صنف');
        }
        final products = await txn.query('products',
          where: "id = ? AND status = 'active'", whereArgs: [line.productId], limit: 1);
        if (products.isEmpty) throw StateError('أحد الأصناف غير موجود');
        final product = products.first;
        final lineTotal = (line.quantity * line.unitPriceMinor).round();
        totalMinor += lineTotal;
        prepared.add((productId: line.productId, name: product['name'] as String,
          quantity: line.quantity, price: line.unitPriceMinor, lineTotal: lineTotal));
      }
      if (paidMinor > totalMinor) throw ArgumentError('المدفوع لا يمكن أن يتجاوز إجمالي الفاتورة');
      final number = 'INV-${DateTime.now().microsecondsSinceEpoch}';
      final status = paidMinor == 0 ? 'unpaid' : paidMinor == totalMinor ? 'paid' : 'partial';
      final invoiceId = await txn.insert('invoices', {
        'invoice_number': number, 'type': type, 'party_id': partyId,
        'total_minor': totalMinor, 'paid_minor': paidMinor, 'status': status,
        'invoice_date': invoiceDate, 'due_date': dueDate, 'created_at': now,
      });
      for (final line in prepared) {
        final products = await txn.query('products', columns: ['quantity'],
          where: 'id = ?', whereArgs: [line.productId], limit: 1);
        final current = (products.first['quantity'] as num).toDouble();
        final change = type == 'sale' ? -line.quantity : line.quantity;
        final next = current + change;
        if (next < 0) throw StateError('الكمية المتاحة من "${line.name}" غير كافية');
        await txn.insert('invoice_lines', {
          'invoice_id': invoiceId, 'product_id': line.productId, 'product_name': line.name,
          'quantity': line.quantity, 'unit_price_minor': line.price, 'line_total_minor': line.lineTotal,
        });
        await txn.update('products', {'quantity': next, 'updated_at': now},
          where: 'id = ?', whereArgs: [line.productId]);
        await txn.insert('stock_movements', {
          'product_id': line.productId, 'change_quantity': change, 'quantity_after': next,
          'reason': type == 'sale' ? 'صرف من فاتورة بيع $number' : 'إضافة من فاتورة شراء $number',
          'note': 'فاتورة رقم $number', 'created_at': now,
        });
      }
      return invoiceId;
    });
  }
}
