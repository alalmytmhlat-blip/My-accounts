import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  Future<void> _addAccount(BuildContext context) async {
    final name = TextEditingController();
    final balance = TextEditingController(text: '0.00');
    String type = 'cash';
    final form = GlobalKey<FormState>();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: const Text('إضافة حساب'),
        content: Form(key: form, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: name, decoration: const InputDecoration(labelText: 'اسم الحساب'), validator: (v) => v == null || v.trim().isEmpty ? 'اسم الحساب مطلوب' : null),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'نوع الحساب'), items: const [
            DropdownMenuItem(value: 'cash', child: Text('صندوق نقدي')),
            DropdownMenuItem(value: 'bank', child: Text('حساب بنكي')),
            DropdownMenuItem(value: 'other', child: Text('حساب آخر')),
          ], onChanged: (v) { if (v != null) setDialogState(() => type = v); }),
          const SizedBox(height: 12),
          TextFormField(controller: balance, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'الرصيد الافتتاحي'), validator: (v) => double.tryParse((v ?? '').trim()) == null ? 'أدخل مبلغاً صحيحاً' : null),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () { if (form.currentState?.validate() ?? false) Navigator.pop(dialogContext, true); }, child: const Text('حفظ')),
        ],
      )),
    );
    if (accepted == true && context.mounted) {
      final amount = double.parse(balance.text.trim());
      await context.read<AppState>().addAccount(name: name.text, type: type, openingBalanceMinor: (amount * 100).round());
    }
    name.dispose();
    balance.dispose();
  }

  String _format(int minor) {
    final absolute = minor.abs();
    return (minor < 0 ? '−' : '') + (absolute ~/ 100).toString() + '.' + (absolute % 100).toString().padLeft(2, '0');
  }

  String _label(String type) => type == 'cash' ? 'صندوق نقدي' : type == 'bank' ? 'حساب بنكي' : 'حساب آخر';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('الحسابات والصندوق والبنوك')),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _addAccount(context), icon: const Icon(Icons.add), label: const Text('إضافة حساب')),
      body: RefreshIndicator(onRefresh: () => context.read<AppState>().refresh(), child: ListView(padding: const EdgeInsets.only(bottom: 88), children: [
        Card(margin: const EdgeInsets.all(12), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('إجمالي الأرصدة الافتتاحية'),
          const SizedBox(height: 8),
          Text(_format(state.accountSummary?.balanceMinor ?? 0), style: Theme.of(context).textTheme.headlineMedium),
          Text('عدد الحسابات: ' + (state.accountSummary?.count ?? 0).toString()),
        ]))),
        if (state.accounts.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('لا توجد حسابات بعد. أضف الصندوق أو الحساب البنكي.'))),
        ...state.accounts.map((account) => Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), child: ListTile(
          leading: CircleAvatar(child: Icon(account.type == 'bank' ? Icons.account_balance_outlined : Icons.account_balance_wallet_outlined)),
          title: Text(account.name), subtitle: Text(_label(account.type)), trailing: Text(_format(account.openingBalanceMinor)),
        ))),
        const Padding(padding: EdgeInsets.all(12), child: Text('الأرصدة المعروضة افتتاحية فقط؛ لم تُربط بعد بحركات القبض والصرف أو القيود المحاسبية.')),
      ])),
    );
  }
}
