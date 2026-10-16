import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const _databaseName = 'hisabati.db';
  static const _version = 1;
  Database? _database;

  Future<void> initialize() async {
    final root = await getDatabasesPath();
    _database = await openDatabase(
      p.join(root, _databaseName),
      version: _version,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE parties (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL CHECK(type IN ('customer','supplier')),
            phone TEXT NOT NULL DEFAULT '',
            email TEXT NOT NULL DEFAULT '',
            address TEXT NOT NULL DEFAULT '',
            tax_number TEXT NOT NULL DEFAULT '',
            opening_balance_minor INTEGER NOT NULL DEFAULT 0,
            credit_limit_minor INTEGER NOT NULL DEFAULT 0,
            notes TEXT NOT NULL DEFAULT '',
            status TEXT NOT NULL DEFAULT 'active',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_parties_name ON parties(name)');
        await db.execute('CREATE INDEX idx_parties_type ON parties(type)');
        await db.execute('''
          CREATE TABLE financial_accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            opening_balance_minor INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount_minor INTEGER NOT NULL CHECK(amount_minor >= 0),
            expense_date TEXT NOT NULL,
            category TEXT NOT NULL DEFAULT '',
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE invoices (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            invoice_number TEXT NOT NULL UNIQUE,
            type TEXT NOT NULL CHECK(type IN ('sale','purchase')),
            party_id INTEGER,
            total_minor INTEGER NOT NULL DEFAULT 0,
            paid_minor INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'draft',
            invoice_date TEXT NOT NULL,
            due_date TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY(party_id) REFERENCES parties(id)
          )
        ''');
        final now = DateTime.now().toIso8601String();
        await db.insert('parties', {
          'name': 'شركة الهدى', 'type': 'customer', 'phone': '770000001',
          'address': 'صنعاء', 'opening_balance_minor': 12500000,
          'created_at': now, 'updated_at': now,
        });
        await db.insert('parties', {
          'name': 'مؤسسة الإتقان', 'type': 'supplier', 'phone': '770000002',
          'address': 'الحديدة', 'opening_balance_minor': 0,
          'created_at': now, 'updated_at': now,
        });
        await db.insert('financial_accounts', {
          'name': 'الصندوق', 'type': 'cash', 'opening_balance_minor': 25000000,
          'created_at': now, 'updated_at': now,
        });
        await db.insert('financial_accounts', {
          'name': 'الحساب البنكي', 'type': 'bank', 'opening_balance_minor': 75000000,
          'created_at': now, 'updated_at': now,
        });
        await db.insert('expenses', {
          'title': 'مصروفات نقل', 'amount_minor': 250000,
          'expense_date': now.substring(0, 10), 'category': 'نقل', 'created_at': now,
        });
        await db.insert('invoices', {
          'invoice_number': 'SAL-0001', 'type': 'sale', 'total_minor': 3500000,
          'paid_minor': 2000000, 'status': 'partial', 'invoice_date': now.substring(0, 10),
          'created_at': now,
        });
      },
    );
  }

  Database get db {
    final value = _database;
    if (value == null) throw StateError('قاعدة البيانات لم تتم تهيئتها');
    return value;
  }
}
