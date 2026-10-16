import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const _databaseName = 'hisabati.db';
  static const _version = 3;
  Database? _database;

  Future<void> initialize() async {
    final root = await getDatabasesPath();
    _database = await openDatabase(
      p.join(root, _databaseName),
      version: _version,
      onCreate: (db, version) async {
        await _createCoreTables(db);
        await _createInventoryTables(db);
        await _createFinancialMovementTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createInventoryTables(db);
        if (oldVersion < 3) await _createFinancialMovementTable(db);
      },
    );
  }

  Future<void> _createCoreTables(DatabaseExecutor db) async {
    await db.execute('''CREATE TABLE parties (
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
      type TEXT NOT NULL CHECK(type IN ('customer','supplier')),
      phone TEXT NOT NULL DEFAULT '', email TEXT NOT NULL DEFAULT '', address TEXT NOT NULL DEFAULT '',
      tax_number TEXT NOT NULL DEFAULT '', opening_balance_minor INTEGER NOT NULL DEFAULT 0,
      credit_limit_minor INTEGER NOT NULL DEFAULT 0, notes TEXT NOT NULL DEFAULT '',
      status TEXT NOT NULL DEFAULT 'active', created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''');
    await db.execute('CREATE INDEX idx_parties_name ON parties(name)');
    await db.execute('CREATE INDEX idx_parties_type ON parties(type)');
    await db.execute('''CREATE TABLE financial_accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, type TEXT NOT NULL,
      opening_balance_minor INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL,
      amount_minor INTEGER NOT NULL CHECK(amount_minor >= 0), expense_date TEXT NOT NULL,
      category TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE invoices (
      id INTEGER PRIMARY KEY AUTOINCREMENT, invoice_number TEXT NOT NULL UNIQUE,
      type TEXT NOT NULL CHECK(type IN ('sale','purchase')), party_id INTEGER,
      total_minor INTEGER NOT NULL DEFAULT 0, paid_minor INTEGER NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'draft', invoice_date TEXT NOT NULL, due_date TEXT,
      created_at TEXT NOT NULL, FOREIGN KEY(party_id) REFERENCES parties(id))''');
  }

  Future<void> _createInventoryTables(DatabaseExecutor db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS products (
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, code TEXT NOT NULL DEFAULT '',
      category TEXT NOT NULL DEFAULT '', unit TEXT NOT NULL DEFAULT 'قطعة',
      quantity REAL NOT NULL DEFAULT 0 CHECK(quantity >= 0), minimum_quantity REAL NOT NULL DEFAULT 0 CHECK(minimum_quantity >= 0),
      purchase_price_minor INTEGER NOT NULL DEFAULT 0 CHECK(purchase_price_minor >= 0),
      sale_price_minor INTEGER NOT NULL DEFAULT 0 CHECK(sale_price_minor >= 0),
      status TEXT NOT NULL DEFAULT 'active', created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_name ON products(name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_code ON products(code)');
    await db.execute('''CREATE TABLE IF NOT EXISTS stock_movements (
      id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER NOT NULL, change_quantity REAL NOT NULL,
      quantity_after REAL NOT NULL, reason TEXT NOT NULL, note TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL,
      FOREIGN KEY(product_id) REFERENCES products(id))''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_stock_movements_product ON stock_movements(product_id)');
  }

  Future<void> _createFinancialMovementTable(DatabaseExecutor db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS financial_movements (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      account_id INTEGER NOT NULL,
      movement_type TEXT NOT NULL CHECK(movement_type IN ('receipt','payment')),
      amount_minor INTEGER NOT NULL CHECK(amount_minor > 0),
      description TEXT NOT NULL,
      movement_date TEXT NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY(account_id) REFERENCES financial_accounts(id) ON DELETE RESTRICT)''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_financial_movements_account_date ON financial_movements(account_id, movement_date)');
  }

  Database get db {
    final value = _database;
    if (value == null) throw StateError('قاعدة البيانات لم تتم تهيئتها');
    return value;
  }
}
