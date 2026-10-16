import 'package:flutter/material.dart';
import 'inventory_screen.dart';
import 'expenses_screen.dart';
import 'accounts_screen.dart';
import 'financial_movements_screen.dart';
import 'invoices_screen.dart';
import 'simple_screen.dart';
import 'settings_screen.dart';
import 'backup_screen.dart';
import 'parties_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});
  static const entries = <(String, IconData)>[
    ('الفواتير', Icons.receipt_long_outlined),
    ('الموردون', Icons.local_shipping_outlined),
    ('المنتجات والمخزون', Icons.inventory_2_outlined),
    ('سندات القبض والصرف', Icons.receipt_outlined),
    ('المصروفات', Icons.money_off_outlined),
    ('الحسابات والصندوق والبنوك', Icons.account_balance_outlined),
    ('الضرائب والعملات', Icons.currency_exchange_outlined),
    ('النسخ الاحتياطي والاستعادة', Icons.backup_outlined),
    ('الإعدادات', Icons.settings_outlined),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('المزيد')),
    body: ListView(padding: const EdgeInsets.all(12), children: entries.map((entry) => Card(child: ListTile(
      leading: Icon(entry.$2, color: Theme.of(context).colorScheme.primary), title: Text(entry.$1), trailing: const Icon(Icons.chevron_left),
      onTap: () {
        final page = entry.$1 == 'الفواتير' ? const InvoicesScreen()
          : entry.$1 == 'المنتجات والمخزون' ? const InventoryScreen()
          : entry.$1 == 'المصروفات' ? const ExpensesScreen()
          : entry.$1 == 'الحسابات والصندوق والبنوك' ? const AccountsScreen()
          : entry.$1 == 'سندات القبض والصرف' ? const FinancialMovementsScreen()
          : entry.$1 == 'الإعدادات' ? const SettingsScreen()
          : entry.$1 == 'النسخ الاحتياطي والاستعادة' ? const BackupScreen()
          : entry.$1 == 'الموردون' ? const PartiesScreen(initialType: 'supplier')
          : SimpleScreen(title: entry.$1, icon: entry.$2, description: 'سيتم تنفيذ هذه الوحدة وربطها بقاعدة البيانات في المرحلة المخصصة لها.');
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
      },
    ))).toList()),
  );
}
