import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../data/app_database.dart';
import '../state/app_state.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;
  String? _lastBackup;

  static const _tableOrder = <String>[
    'parties',
    'financial_accounts',
    'expenses',
    'products',
    'invoices',
    'stock_movements',
    'financial_movements',
    'invoice_lines',
    'invoice_payments',
    'journal_entries',
    'journal_lines',
  ];

  Future<void> _exportBackup() async {
    if (_busy) return;
    setState(() => _busy = true);
    AppDatabase? database;
    try {
      database = AppDatabase();
      await database.initialize();
      final tables = <String, List<Map<String, Object?>>>{};
      for (final table in _tableOrder) {
        final exists = await database.db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [table],
        );
        if (exists.isNotEmpty) {
          tables[table] = await database.db.query(table);
        }
      }
      final preferences = await SharedPreferences.getInstance();
      final settings = <String, String>{};
      for (final key in ['business_name', 'business_phone', 'business_address', 'business_tax_number', 'business_currency']) {
        final value = preferences.getString(key);
        if (value != null) settings[key] = value;
      }
      final payload = <String, Object?>{
        'format': 'hisabati-backup',
        'formatVersion': 1,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'settings': settings,
        'tables': tables,
      };
      final directory = await getDatabasesPath();
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File(p.join(directory, 'hisabati-backup-$stamp.json'));
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
      database = null;
      if (!mounted) return;
      setState(() => _lastBackup = file.path);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'نسخة احتياطية من بيانات تطبيق حساباتي',
        ),
      );
    } catch (error) {
      if (mounted) _message('تعذر إنشاء النسخة الاحتياطية: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreBackup() async {
    if (_busy) return;
    final selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (selection == null || selection.files.isEmpty) return;
    final picked = selection.files.single;
    String raw;
    if (picked.bytes != null) {
      raw = utf8.decode(picked.bytes!);
    } else if (picked.path != null) {
      raw = await File(picked.path!).readAsString();
    } else {
      if (mounted) _message('تعذر قراءة الملف المحدد.');
      return;
    }

    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> ||
          decoded['format'] != 'hisabati-backup' ||
          decoded['formatVersion'] != 1 ||
          decoded['tables'] is! Map<String, dynamic>) {
        throw const FormatException('صيغة النسخة غير مدعومة');
      }
      payload = decoded;
    } catch (error) {
      if (mounted) _message('الملف ليس نسخة احتياطية صالحة: $error');
      return;
    }

    if (!mounted) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('استعادة نسخة احتياطية؟'),
        content: const Text(
          'ستُستبدل البيانات الحالية بالبيانات الموجودة في النسخة المختارة. '
          'يُفضّل إنشاء نسخة احتياطية من البيانات الحالية أولًا.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('استعادة البيانات'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;

    setState(() => _busy = true);
    AppDatabase? database;
    try {
      final sourceTables = payload['tables'] as Map<String, dynamic>;
      database = AppDatabase();
      await database.initialize();
      await database.db.execute('PRAGMA foreign_keys = OFF');
      await database.db.transaction((txn) async {
        for (final table in _tableOrder.reversed) {
          await txn.delete(table);
        }
        for (final table in _tableOrder) {
          final rows = sourceTables[table];
          if (rows is! List) continue;
          for (final row in rows) {
            if (row is! Map) {
              throw FormatException('سجل غير صالح داخل جدول $table');
            }
            await txn.insert(
              table,
              Map<String, Object?>.from(row),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });
      await database.db.execute('PRAGMA foreign_keys = ON');
      database = null;
      final preferences = await SharedPreferences.getInstance();
      final settings = payload['settings'];
      if (settings is Map<String, dynamic>) {
        for (final key in ['business_name', 'business_phone', 'business_address', 'business_tax_number', 'business_currency']) {
          final value = settings[key];
          if (value is String) await preferences.setString(key, value);
        }
      }
      if (!mounted) return;
      await context.read<AppState>().refresh();
      _message('تمت استعادة البيانات. راجع الأرصدة والمخزون قبل متابعة العمل.');
    } catch (error) {
      if (database != null) {
        try { await database.db.execute('PRAGMA foreign_keys = ON'); } catch (_) {}
      }
      if (mounted) _message('تعذرت استعادة النسخة: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('النسخ الاحتياطي والاستعادة')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Icon(Icons.shield_outlined, size: 58),
            const SizedBox(height: 12),
            const Text(
              'حافظ على بيانات منشأتك',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'تتضمن النسخة بيانات العملاء والموردين والأصناف والفواتير '
              'والحسابات والحركات المالية والقيود المحاسبية الموجودة في قاعدة البيانات.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: const Text('إنشاء نسخة احتياطية'),
                subtitle: const Text('ملف JSON يمكن حفظه أو إرساله إلى جهاز آخر'),
                trailing: const Icon(Icons.chevron_left),
                onTap: _busy ? null : _exportBackup,
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.restore_outlined),
                title: const Text('استعادة نسخة احتياطية'),
                subtitle: const Text('اختر ملف حساباتي بصيغة JSON'),
                trailing: const Icon(Icons.chevron_left),
                onTap: _busy ? null : _restoreBackup,
              ),
            ),
            if (_busy) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              const Text('جارٍ تنفيذ العملية، يرجى الانتظار', textAlign: TextAlign.center),
            ],
            if (_lastBackup != null) ...[
              const SizedBox(height: 16),
              const Text('آخر نسخة أُنشئت على هذا الجهاز:'),
              SelectableText(_lastBackup!),
            ],
            const SizedBox(height: 20),
            const Text(
              'تنبيه: استعادة النسخة تستبدل بيانات التطبيق الحالية. '
              'لا تحذف التطبيق أو بياناته قبل التأكد من حفظ ملف النسخة خارج الجهاز.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
}
