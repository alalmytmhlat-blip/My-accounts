import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';
import 'invoices_screen.dart';
import 'financial_movements_screen.dart';
import 'expenses_screen.dart';
import 'parties_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  String money(int minor) => NumberFormat.currency(locale: 'ar', symbol: 'ر.ي', decimalDigits: 2).format(minor / 100);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final summary = state.summary;
    return RefreshIndicator(
      onRefresh: state.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white)),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('حساباتي', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              Text('إدارة أعمالك المالية بسهولة', style: TextStyle(color: Colors.grey)),
            ])),
            IconButton(onPressed: state.refresh, icon: const Icon(Icons.refresh_rounded), tooltip: 'تحديث'),
          ]),
          const SizedBox(height: 22),
          if (state.error != null) Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(state.error!))),
          if (state.loading && summary == null) const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
          if (summary != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withValues(alpha: .78)]), borderRadius: BorderRadius.circular(22)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('ملخص النشاط', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(money(summary.net), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const Text('صافي المبيعات مطروحًا منها المصروفات المسجلة', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (context, constraints) {
              final width = (constraints.maxWidth - 12) / 2;
              return Wrap(spacing: 12, runSpacing: 12, children: [
                _Metric(width: width, title: 'المبيعات', value: money(summary.sales), icon: Icons.trending_up, color: Colors.green),
                _Metric(width: width, title: 'المصروفات', value: money(summary.expenses), icon: Icons.trending_down, color: Colors.orange),
                _Metric(width: width, title: 'مستحقات العملاء', value: money(summary.receivables), icon: Icons.people_alt_outlined, color: Colors.blue),
                _Metric(width: width, title: 'الصندوق والبنوك', value: money(summary.cash), icon: Icons.account_balance_outlined, color: Colors.purple),
              ]);
            }),
          ],
          const SizedBox(height: 22),
          const Text('إجراءات سريعة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 10, children: [
            _QuickAction(icon: Icons.add_shopping_cart, label: 'فاتورة مبيعات',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InvoicesScreen()))),
            _QuickAction(icon: Icons.add_card, label: 'سند قبض',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FinancialMovementsScreen()))),
            _QuickAction(icon: Icons.money_off_csred_outlined, label: 'إضافة مصروف',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExpensesScreen()))),
            _QuickAction(icon: Icons.person_add_alt_1, label: 'إضافة عميل',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PartiesScreen()))),
          ]),
          const SizedBox(height: 22),
          const Text('نظرة عامة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            const Icon(Icons.storage_outlined, size: 30),
            const SizedBox(width: 12),
            Expanded(child: Text('بياناتك محفوظة محليًا على الجهاز. اسحب للأسفل لتحديث ملخص قاعدة البيانات.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
          ]))),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.width, required this.title, required this.value, required this.icon, required this.color});
  final double width;
  final String title, value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(width: width, child: Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, color: color),
    const SizedBox(height: 12),
    Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    const SizedBox(height: 5),
    FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
  ]))));
}
class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => ActionChip(avatar: Icon(icon, size: 18), label: Text(label), onPressed: onPressed);
}
