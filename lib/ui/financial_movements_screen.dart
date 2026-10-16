// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class FinancialMovementsScreen extends StatelessWidget {
  const FinancialMovementsScreen({super.key});

  String _money(int minor) {
    final value = minor.abs();
    return '${minor < 0 ? '−' : ''}${value ~/ 100}.${(value % 100).toString().padLeft(2, '0')}';
  }

  Future<void> _add(BuildContext context, String type) async {
    final state = context.read<AppState>();
    if (state.accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف حساباً أو صندوقاً أولاً.')));
      return;
    }
    final description = TextEditingController();
    final amount = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var accountId = state.accounts.first.id;
    var date = DateTime.now();
    final saved = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: Text(type == 'receipt' ? 'تسجيل سند قبض' : 'تسجيل سند صرف'),
      content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<int>(value: accountId, decoration: const InputDecoration(labelText: 'الحساب'), items: state.accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(), onChanged: (v) { if (v != null) setDialogState(() => accountId = v); }),
        const SizedBox(height: 10),
        TextFormField(controller: description, decoration: const InputDecoration(labelText: 'البيان'), validator: (v) => v == null || v.trim().isEmpty ? 'أدخل البيان' : null),
        const SizedBox(height: 10),
        TextFormField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'المبلغ'), validator: (v) { final n = double.tryParse((v ?? '').trim()); return n == null || n <= 0 ? 'أدخل مبلغاً أكبر من صفر' : null; }),
        const SizedBox(height: 10),
        ListTile(contentPadding: EdgeInsets.zero, title: const Text('التاريخ'), subtitle: Text('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'), trailing: const Icon(Icons.calendar_month), onTap: () async { final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2000), lastDate: DateTime(2100)); if (picked != null) setDialogState(() => date = picked); }),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')), FilledButton(onPressed: () { if (formKey.currentState?.validate() ?? false) Navigator.pop(dialogContext, true); }, child: const Text('حفظ'))],
    )));
    if (saved == true && context.mounted) {
      final minor = (double.parse(amount.text.trim()) * 100).round();
      try {
        await context.read<AppState>().addMovement(accountId: accountId, type: type, amountMinor: minor, description: description.text, date: date.toIso8601String().substring(0, 10));
      } catch (_) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حفظ السند. حاول مرة أخرى.')));
      }
    }
    description.dispose(); amount.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final summary = state.movementSummary;
    return Scaffold(
      appBar: AppBar(title: const Text('سندات القبض والصرف')),
      floatingActionButton: PopupMenuButton<String>(tooltip: 'إضافة سند', icon: const Icon(Icons.add_circle, size: 56), onSelected: (v) => _add(context, v), itemBuilder: (_) => const [PopupMenuItem(value: 'receipt', child: Text('سند قبض')), PopupMenuItem(value: 'payment', child: Text('سند صرف'))]),
      body: RefreshIndicator(onRefresh: () => context.read<AppState>().refresh(), child: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
        Card(margin: const EdgeInsets.all(12), child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
          Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('إجمالي القبض'), Text(_money(summary?.receiptsMinor ?? 0), style: Theme.of(context).textTheme.titleLarge)])), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('إجمالي الصرف'), Text(_money(summary?.paymentsMinor ?? 0), style: Theme.of(context).textTheme.titleLarge)]))]),
          const Divider(), Row(children: [const Expanded(child: Text('صافي الحركات')), Text(_money(summary?.netMinor ?? 0), style: Theme.of(context).textTheme.titleMedium)]),
        ]))),
        if (state.movements.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('لا توجد سندات مسجلة بعد.'))),
        ...state.movements.map((m) => Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: ListTile(
          leading: CircleAvatar(child: Icon(m.type == 'receipt' ? Icons.south_west : Icons.north_east)),
          title: Text(m.description), subtitle: Text('${m.accountName} • ${m.date} • ${m.type == 'receipt' ? 'قبض' : 'صرف'}'),
          trailing: Text('${m.type == 'receipt' ? '+' : '−'}${_money(m.amountMinor)}', style: TextStyle(color: m.type == 'receipt' ? Colors.green : Theme.of(context).colorScheme.error, fontWeight: FontWeight.w600)),
        ))),
      ])),
    );
  }
}
