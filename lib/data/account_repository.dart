// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:sqflite/sqflite.dart';
import 'app_database.dart';

class FinancialAccount {
  const FinancialAccount({required this.id, required this.name, required this.type, required this.openingBalanceMinor});
  final int id;
  final String name;
  final String type;
  final int openingBalanceMinor;
  factory FinancialAccount.fromMap(Map<String, Object?> map) => FinancialAccount(id: map['id'] as int, name: map['name'] as String, type: map['type'] as String, openingBalanceMinor: map['opening_balance_minor'] as int);
}

class AccountSummary {
  const AccountSummary({required this.count, required this.balanceMinor});
  final int count;
  final int balanceMinor;
}

class AccountRepository {
  AccountRepository(this.database);
  final AppDatabase database;
  Future<List<FinancialAccount>> getAccounts() async {
    final rows = await database.db.query('financial_accounts', orderBy: 'name COLLATE NOCASE');
    return rows.map(FinancialAccount.fromMap).toList();
  }
  Future<AccountSummary> getSummary() async {
    final rows = await database.db.rawQuery('SELECT COUNT(*) AS account_count, COALESCE(SUM(opening_balance_minor), 0) AS total_minor FROM financial_accounts');
    return AccountSummary(count: (rows.first['account_count'] as int?) ?? 0, balanceMinor: (rows.first['total_minor'] as int?) ?? 0);
  }
  Future<void> addAccount({required String name, required String type, required int openingBalanceMinor}) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('اسم الحساب مطلوب');
    if (!const {'cash', 'bank', 'other'}.contains(type)) throw ArgumentError('نوع الحساب غير صالح');
    final now = DateTime.now().toIso8601String();
    await database.db.insert('financial_accounts', {'name': cleanName, 'type': type, 'opening_balance_minor': openingBalanceMinor, 'created_at': now, 'updated_at': now}, conflictAlgorithm: ConflictAlgorithm.abort);
  }
}
