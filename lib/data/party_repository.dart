import 'app_database.dart';

class Party {
  const Party({
    required this.id, required this.name, required this.type,
    required this.phone, required this.address, required this.balanceMinor,
  });
  final int id;
  final String name;
  final String type;
  final String phone;
  final String address;
  final int balanceMinor;

  factory Party.fromMap(Map<String, Object?> map) => Party(
    id: map['id'] as int,
    name: map['name'] as String,
    type: map['type'] as String,
    phone: map['phone'] as String? ?? '',
    address: map['address'] as String? ?? '',
    balanceMinor: map['opening_balance_minor'] as int? ?? 0,
  );
}

class DashboardSummary {
  const DashboardSummary({required this.sales, required this.expenses, required this.receivables, required this.cash});
  final int sales;
  final int expenses;
  final int receivables;
  final int cash;
  int get net => sales - expenses;
}

class PartyRepository {
  PartyRepository(this._database);
  final AppDatabase _database;

  Future<List<Party>> getParties({String type = 'customer', String query = ''}) async {
    final rows = await _database.db.query(
      'parties',
      where: 'type = ? AND status = ? AND name LIKE ?',
      whereArgs: [type, 'active', '%$query%'],
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(Party.fromMap).toList();
  }

  Future<int> addParty({required String name, required String type, String phone = '', String address = ''}) async {
    final now = DateTime.now().toIso8601String();
    return _database.db.insert('parties', {
      'name': name.trim(), 'type': type, 'phone': phone.trim(), 'address': address.trim(),
      'created_at': now, 'updated_at': now,
    });
  }

  Future<DashboardSummary> getDashboardSummary() async {
    final db = _database.db;
    final salesRows = await db.rawQuery("SELECT COALESCE(SUM(total_minor),0) total FROM invoices WHERE type='sale' AND status != 'cancelled'");
    final expenseRows = await db.rawQuery('SELECT COALESCE(SUM(amount_minor),0) total FROM expenses');
    final receivableRows = await db.rawQuery("SELECT COALESCE((SELECT SUM(opening_balance_minor) FROM parties WHERE type='customer' AND status='active'),0) + COALESCE((SELECT SUM(total_minor-paid_minor) FROM invoices WHERE type='sale' AND status!='cancelled'),0) AS total");
    final accountRows = await db.rawQuery("SELECT COALESCE((SELECT SUM(opening_balance_minor) FROM financial_accounts),0) + COALESCE((SELECT SUM(CASE WHEN movement_type='receipt' THEN amount_minor ELSE -amount_minor END) FROM financial_movements),0) AS total");
    int value(List<Map<String, Object?>> rows) => (rows.first['total'] as int?) ?? 0;
    return DashboardSummary(sales: value(salesRows), expenses: value(expenseRows), receivables: value(receivableRows), cash: value(accountRows));
  }
}
