import 'package:sqflite/sqflite.dart';
import 'app_database.dart';

class Expense {
  const Expense({required this.id, required this.title, required this.amountMinor,
    required this.date, required this.category});
  final int id;
  final String title, date, category;
  final int amountMinor;
  factory Expense.fromMap(Map<String, Object?> row) => Expense(
    id: row['id'] as int,
    title: row['title'] as String,
    amountMinor: row['amount_minor'] as int,
    date: row['expense_date'] as String,
    category: row['category'] as String? ?? '',
  );
}

class ExpenseRepository {
  ExpenseRepository(this.database);
  final AppDatabase database;

  Future<List<Expense>> getExpenses() async {
    final rows = await database.db.query('expenses', orderBy: 'expense_date DESC, id DESC');
    return rows.map(Expense.fromMap).toList();
  }

  Future<void> addExpense({required String title, required int amountMinor,
    required String date, String category = ''}) async {
    if (title.trim().isEmpty) throw ArgumentError('عنوان المصروف مطلوب');
    if (amountMinor <= 0) throw ArgumentError('قيمة المصروف يجب أن تكون أكبر من صفر');
    await database.db.insert('expenses', {
      'title': title.trim(), 'amount_minor': amountMinor, 'expense_date': date,
      'category': category.trim(), 'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }
}
