// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use, prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  Future<void> _addAccount(BuildContext context) async {
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();
    String accountType = 'cash';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة حساب جديد'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'اسم الحساب', hintText: 'مثال: الصندوق الرئيسي'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'أدخل اسم الحساب' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: accountType,
                  decoration: const InputDecoration(labelText: 'نوع الحساب'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('صندوق نقدي')),
                    DropdownMenuItem(value: 'bank', child: Text('حساب بنكي')),
                    DropdownMenuItem(value: 'other', child: Text('حساب آخر')),
                  ],
                  onChanged: (value) { if (value != null) setDialogState(() => accountType = value); },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: balanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: const InputDecoration(labelText: 'الرصيد الافتتاحي', helperText: 'يمكن إدخال رصيد موجب أو سالب'),
                  validator: (value) => double.tryParse((value ?? '').trim()) == null ? 'أدخل مبلغاً صحيحاً' : null,
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () { if (formKey.currentState?.validate() ?? false) Navigator.pop(dialogContext, true); }, child: const Text('حفظ الحساب')),
          ],
        ),
      ),
    );
    if (accepted == true && context.mounted) {
      final amount = double.parse(balanceController.text.trim());
      try {
        await context.read<AppState>().addAccount(name: nameController.text, type: accountType, openingBalanceMinor: (amount * 100).round());
      } catch (_) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حفظ الحساب. تحقق من البيانات وحاول مجدداً.')));
      }
    }
    nameController.dispose();
    balanceController.dispose();
  }

  String _money(int minor) {
    final absolute = minor.abs();
    final prefix = minor < 0 ? '−' : '';
    return '$prefix${absolute ~/ 100}.${(absolute % 100).toString().padLeft(2, '0')}';
  }

  String _typeLabel(String type) => type == 'cash' ? 'صندوق نقدي' : type == 'bank' ? 'حساب بنكي' : 'حساب آخر';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('الحسابات والصندوق والبنوك')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addAccount(context),
        icon: const Icon(Icons.add),
        label: const Text('إضافة حساب'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AppState>().refresh(),
        child: ListView(padding: const EdgeInsets.only(bottom: 96), children: [
          Card(margin: const EdgeInsets.all(12), child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('إجمالي الأرصدة الافتتاحية'),
              const SizedBox(height: 8),
              Text(_money(state.accountSummary?.balanceMinor ?? 0), style: Theme.of(context).textTheme.headlineMedium),
              Text('عدد الحسابات: ${state.accountSummary?.count ?? 0}'),
            ]),
          )),
          if (state.accounts.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('لا توجد حسابات بعد. أضف الصندوق أو الحساب البنكي.'))),
          ...state.accounts.map((account) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: ListTile(
              leading: CircleAvatar(child: Icon(account.type == 'bank' ? Icons.account_balance_outlined : Icons.account_balance_wallet_outlined)),
              title: Text(account.name),
              subtitle: Text(_typeLabel(account.type)),
              trailing: Text(_money(account.openingBalanceMinor), style: Theme.of(context).textTheme.titleMedium),
            ),
          )),
          const Padding(padding: EdgeInsets.all(12), child: Text('الأرصدة المعروضة افتتاحية فقط؛ ستُربط بحركات القبض والصرف والقيود المحاسبية في المرحلة التالية.')),
        ]),
      ),
    );
  }
}
