import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  String money(int minor) => NumberFormat.currency(locale: 'ar', symbol: 'ر.ي', decimalDigits: 2).format(minor / 100);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final invoices = state.invoices;
    final sales = invoices.where((e) => e.type == 'sale').fold<int>(0, (sum, e) => sum + e.totalMinor);
    final purchases = invoices.where((e) => e.type == 'purchase').fold<int>(0, (sum, e) => sum + e.totalMinor);
    final customerDue = invoices.where((e) => e.type == 'sale').fold<int>(0, (sum, e) => sum + e.remainingMinor);
    final supplierDue = invoices.where((e) => e.type == 'purchase').fold<int>(0, (sum, e) => sum + e.remainingMinor);
    final expenseTotal = state.expenses.fold<int>(0, (sum, e) => sum + e.amountMinor);
    final stockValue = state.inventorySummary?.stockValueMinor ?? 0;
    final movement = state.movementSummary;
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: RefreshIndicator(
        onRefresh: state.refresh,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('ملخص مالي من البيانات المسجلة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final width = (constraints.maxWidth - 12) / 2;
            return Wrap(spacing: 12, runSpacing: 12, children: [
              _ReportMetric(width: width, title: 'إجمالي المبيعات', value: money(sales), icon: Icons.trending_up),
              _ReportMetric(width: width, title: 'إجمالي المشتريات', value: money(purchases), icon: Icons.shopping_cart_outlined),
              _ReportMetric(width: width, title: 'المتبقي على العملاء', value: money(customerDue), icon: Icons.people_outline),
              _ReportMetric(width: width, title: 'المتبقي للموردين', value: money(supplierDue), icon: Icons.local_shipping_outlined),
              _ReportMetric(width: width, title: 'المصروفات', value: money(expenseTotal), icon: Icons.money_off_outlined),
              _ReportMetric(width: width, title: 'قيمة المخزون بالتكلفة', value: money(stockValue), icon: Icons.inventory_2_outlined),
            ]);
          }),
          const SizedBox(height: 18),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('حركة الصندوق والبنوك', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _ReportLine(label: 'إجمالي القبض', value: money(movement?.receiptsMinor ?? 0)),
            _ReportLine(label: 'إجمالي الصرف', value: money(movement?.paymentsMinor ?? 0)),
            const Divider(),
            _ReportLine(label: 'صافي حركة السندات', value: money(movement?.netMinor ?? 0), bold: true),
          ]))),
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(
            'الأرقام محسوبة من الفواتير والسندات والمصروفات والأصناف المحفوظة على هذا الجهاز. هذه تقارير تشغيلية أولية؛ لا تشمل بعد الضرائب أو المرتجعات أو إقفال الفترات.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ))),
        ]),
      ),
    );
  }
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({required this.width, required this.title, required this.value, required this.icon});
  final double width;
  final String title, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(width: width, child: Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, color: Theme.of(context).colorScheme.primary),
    const SizedBox(height: 10),
    Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    const SizedBox(height: 6),
    FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
  ]))));
}

class _ReportLine extends StatelessWidget {
  const _ReportLine({required this.label, required this.value, this.bold = false});
  final String label, value;
  final bool bold;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
    Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal))),
    Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
  ]));
}
