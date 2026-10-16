import 'package:sqflite/sqflite.dart';
import 'app_database.dart';

class FinancialMovement {
  const FinancialMovement({required this.id, required this.accountId, required this.accountName, required this.type, required this.amountMinor, required this.description, required this.date});
  final int id;
  final int accountId;
  final String accountName;
  final String type;
  final int amountMinor;
  final String description;
  final String date;
  factory FinancialMovement.fromMap(Map<String, Object?> row) => FinancialMovement(
    id: row['id'] as int, accountId: row['account_id'] as int, accountName: row['account_name'] as String,
    type: row['movement_type'] as String, amountMinor: row['amount_minor'] as int,
    description: row['description'] as String, date: row['movement_date'] as String,
  );
}

class FinancialMovementSummary {
  const FinancialMovementSummary({required this.receiptsMinor, required this.paymentsMinor});
  final int receiptsMinor;
  final int paymentsMinor;
  int get netMinor => receiptsMinor - paymentsMinor;
}

class FinancialMovementRepository {
  FinancialMovementRepository(this.database);
  final AppDatabase database;

  Future<List<FinancialMovement>> getMovements() async {
    final rows = await database.db.rawQuery('''SELECT m.*, a.name AS account_name FROM financial_movements m
      INNER JOIN financial_accounts a ON a.id = m.account_id ORDER BY m.movement_date DESC, m.id DESC''');
    return rows.map(FinancialMovement.fromMap).toList();
  }

  Future<FinancialMovementSummary> getSummary() async {
    final rows = await database.db.rawQuery('''SELECT
      COALESCE(SUM(CASE WHEN movement_type = 'receipt' THEN amount_minor ELSE 0 END), 0) AS receipts,
      COALESCE(SUM(CASE WHEN movement_type = 'payment' THEN amount_minor ELSE 0 END), 0) AS payments
      FROM financial_movements''');
    return FinancialMovementSummary(receiptsMinor: rows.first['receipts'] as int, paymentsMinor: rows.first['payments'] as int);
  }

  Future<void> addMovement({required int accountId, required String type, required int amountMinor, required String description, required String date}) async {
    if (!const {'receipt', 'payment'}.contains(type)) throw ArgumentError('نوع الحركة غير صالح');
    if (amountMinor <= 0) throw ArgumentError('يجب أن يكون المبلغ أكبر من صفر');
    if (description.trim().isEmpty) throw ArgumentError('البيان مطلوب');
    await database.db.insert('financial_movements', {
      'account_id': accountId, 'movement_type': type, 'amount_minor': amountMinor,
      'description': description.trim(), 'movement_date': date, 'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }
}
