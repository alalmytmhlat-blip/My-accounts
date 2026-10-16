import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});
  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String query = '';
  String money(int minor) => NumberFormat.currency(locale: 'ar', symbol: 'ر.ي', decimalDigits: 2).format(minor / 100);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final expenses = state.expenses.where((e) => e.title.contains(query) || e.category.contains(query)).toList();
    final total = expenses.fold<int>(0, (sum, expense) => sum + expense.amountMinor);
    return Scaffold(
      appBar: AppBar(title: const Text('المصروفات'), actions: [
        IconButton(onPressed: state.refresh, icon: const Icon(Icons.refresh), tooltip: 'تحديث'),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExpense, icon: const Icon(Icons.add), label: const Text('إضافة مصروف')),
      body: RefreshIndicator(onRefresh: state.refresh, child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
          Card(child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.money_off_outlined)),
            title: const Text('إجمالي المصروفات المعروضة'),
            subtitle: Text('${expenses.length} عملية'),
            trailing: Text(money(total), style: const TextStyle(fontWeight: FontWeight.bold)),
          )),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(hintText: 'بحث باسم المصروف أو التصنيف', prefixIcon: Icon(Icons.search)),
            onChanged: (value) => setState(() => query = value.trim())),
          const SizedBox(height: 8),
          if (state.loading && expenses.isEmpty)
            const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator()))
          else if (expenses.isEmpty)
            const Padding(padding: EdgeInsets.all(28), child: Center(child: Text('لا توجد مصروفات مسجلة بعد.')))
          else
            ...expenses.map((expense) => Card(child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
              title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text([expense.category, expense.date].where((v) => v.isNotEmpty).join(' • ')),
              trailing: Text(money(expense.amountMinor), style: const TextStyle(fontWeight: FontWeight.bold)),
            ))),
        ],
      )),
    );
  }

  Future<void> _addExpense() async {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController();
    final category = TextEditingController();
    final amount = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await showDialog<(String, String, int, DateTime)?>(context: context, builder: (dialogContext) =>
        StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة مصروف'),
          content: SizedBox(width: 420, child: Form(key: formKey, child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: title, decoration: const InputDecoration(labelText: 'بيان المصروف *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'البيان مطلوب' : null),
              const SizedBox(height: 10),
              TextFormField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'المبلغ (ر.ي) *'),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  return n == null || n <= 0 ? 'أدخل مبلغًا أكبر من صفر' : null;
                }),
              const SizedBox(height: 10),
              TextFormField(controller: category, decoration: const InputDecoration(labelText: 'التصنيف')),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('تاريخ المصروف'),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                onTap: () async {
                  final picked = await showDatePicker(context: dialogContext, initialDate: selectedDate,
                    firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (picked != null) { setDialogState(() => selectedDate = picked); }
                },
              ),
            ],
          )))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
            FilledButton(onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, (title.text, category.text,
                  (double.parse(amount.text.trim()) * 100).round(), selectedDate));
              }
            }, child: const Text('حفظ المصروف')),
          ],
        )));
      if (!mounted || result == null) { return; }
      await state.addExpense(title: result.$1, category: result.$2, amountMinor: result.$3,
        date: DateFormat('yyyy-MM-dd').format(result.$4));
      if (mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('تم حفظ المصروف وتحديث الملخص')));
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('تعذر حفظ المصروف')));
      }
    } finally {
      title.dispose();
      category.dispose();
      amount.dispose();
    }
  }
}
