import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/inventory_repository.dart';
import '../state/app_state.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String query = '';
  String money(int minor) => NumberFormat.currency(locale: 'ar', symbol: 'ر.ي', decimalDigits: 2).format(minor / 100);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final products = state.products.where((p) => p.name.contains(query) || p.code.contains(query) || p.category.contains(query)).toList();
    final summary = state.inventorySummary;
    return Scaffold(
      appBar: AppBar(title: const Text('المنتجات والمخزون'), actions: [
        IconButton(onPressed: state.refresh, icon: const Icon(Icons.refresh), tooltip: 'تحديث'),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProduct, icon: const Icon(Icons.add), label: const Text('إضافة صنف')),
      body: RefreshIndicator(
        onRefresh: state.refresh,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
          if (summary != null) LayoutBuilder(builder: (context, constraints) {
            final width = (constraints.maxWidth - 20) / 3;
            return Wrap(spacing: 10, children: [
              _Metric(width: width, title: 'الأصناف', value: '${summary.productsCount}', color: Theme.of(context).colorScheme.primary),
              _Metric(width: width, title: 'منخفض', value: '${summary.lowStockCount}', color: Colors.orange),
              _Metric(width: width, title: 'نافد', value: '${summary.outOfStockCount}', color: Colors.red),
            ]);
          }),
          const SizedBox(height: 12),
          Card(child: ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('قيمة المخزون بالتكلفة'),
            trailing: Text(money(summary?.stockValueMinor ?? 0), style: const TextStyle(fontWeight: FontWeight.bold)),
          )),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(hintText: 'بحث باسم الصنف أو الرمز أو التصنيف', prefixIcon: Icon(Icons.search)),
            onChanged: (value) => setState(() => query = value.trim())),
          const SizedBox(height: 8),
          if (state.loading && products.isEmpty)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (products.isEmpty)
            const Padding(padding: EdgeInsets.all(28), child: Center(child: Text('لا توجد أصناف. اضغط «إضافة صنف» للبدء.')))
          else
            ...products.map((product) => _productCard(product)),
        ]),
      ),
    );
  }

  Widget _productCard(Product product) {
    final color = product.isOutOfStock ? Colors.red : product.isLowStock ? Colors.orange : Colors.green;
    final status = product.isOutOfStock ? 'نافد' : product.isLowStock ? 'مخزون منخفض' : 'متوفر';
    return Card(child: ListTile(
      leading: CircleAvatar(backgroundColor: color.withValues(alpha: .12), child: Icon(Icons.inventory_2_outlined, color: color)),
      title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text([
        if (product.code.isNotEmpty) 'الرمز: ${product.code}',
        'الكمية: ${_quantity(product.quantity)} ${product.unit}',
        status,
      ].join('\n'), style: TextStyle(color: color)),
      isThreeLine: true,
      trailing: IconButton(tooltip: 'تعديل المخزون', icon: const Icon(Icons.tune), onPressed: () => _showStockDialog(product)),
    ));
  }

  String _quantity(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toString();

  Future<void> _showAddProduct() async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final code = TextEditingController();
    final category = TextEditingController();
    final unit = TextEditingController(text: 'قطعة');
    final quantity = TextEditingController(text: '0');
    final minimum = TextEditingController(text: '0');
    final purchase = TextEditingController(text: '0');
    final sale = TextEditingController(text: '0');
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    double? number(String value) => double.tryParse(value.trim());
    int? minor(String value) {
      final parsed = double.tryParse(value.trim());
      if (parsed == null || parsed < 0) return null;
      return (parsed * 100).round();
    }
    try {
      final saved = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة صنف جديد'),
        content: SizedBox(width: 420, child: Form(key: formKey, child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'اسم الصنف *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'الاسم مطلوب' : null),
            const SizedBox(height: 8),
            TextFormField(controller: code, decoration: const InputDecoration(labelText: 'رمز الصنف')),
            const SizedBox(height: 8),
            TextFormField(controller: category, decoration: const InputDecoration(labelText: 'التصنيف')),
            const SizedBox(height: 8),
            TextFormField(controller: unit, decoration: const InputDecoration(labelText: 'وحدة القياس')),
            const SizedBox(height: 8),
            TextFormField(controller: quantity, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'الكمية الافتتاحية *'),
              validator: (v) => v == null || number(v) == null || number(v)! < 0 ? 'أدخل كمية صحيحة' : null),
            const SizedBox(height: 8),
            TextFormField(controller: minimum, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'حد التنبيه للمخزون المنخفض'),
              validator: (v) => v == null || number(v) == null || number(v)! < 0 ? 'أدخل حدًا صحيحًا' : null),
            const SizedBox(height: 8),
            TextFormField(controller: purchase, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'سعر الشراء (ر.ي)'),
              validator: (v) => v == null || minor(v) == null ? 'أدخل سعرًا صحيحًا' : null),
            const SizedBox(height: 8),
            TextFormField(controller: sale, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'سعر البيع (ر.ي)'),
              validator: (v) => v == null || minor(v) == null ? 'أدخل سعرًا صحيحًا' : null),
          ],
        )))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () { if (formKey.currentState!.validate()) { Navigator.pop(dialogContext, true); } }, child: const Text('حفظ الصنف')),
        ],
      ));
      if (!mounted || saved != true) { return; }
      await state.addProduct(name: name.text, code: code.text, category: category.text, unit: unit.text,
        quantity: number(quantity.text)!, minimumQuantity: number(minimum.text)!,
        purchasePriceMinor: minor(purchase.text)!, salePriceMinor: minor(sale.text)!);
      if (mounted) { messenger.showSnackBar(const SnackBar(content: Text('تم حفظ الصنف والمخزون'))); }
    } catch (_) {
      if (mounted) { messenger.showSnackBar(const SnackBar(content: Text('تعذر حفظ الصنف'))); }
    } finally {
      name.dispose(); code.dispose(); category.dispose(); unit.dispose(); quantity.dispose();
      minimum.dispose(); purchase.dispose(); sale.dispose();
    }
  }

  Future<void> _showStockDialog(Product product) async {
    final amount = TextEditingController();
    final note = TextEditingController();
    String movement = 'add';
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await showDialog<(String, double, String)?>(context: context, builder: (dialogContext) =>
        StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
          title: Text('حركة مخزون: ${product.name}'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('الرصيد الحالي: ${_quantity(product.quantity)} ${product.unit}'),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'add', label: Text('إضافة'), icon: Icon(Icons.add)),
                ButtonSegment(value: 'remove', label: Text('صرف'), icon: Icon(Icons.remove)),
              ],
              selected: {movement}, onSelectionChanged: (v) => setDialogState(() => movement = v.first)),
            const SizedBox(height: 10),
            TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'الكمية')),
            const SizedBox(height: 8),
            TextField(controller: note, decoration: const InputDecoration(labelText: 'ملاحظة اختيارية')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
            FilledButton(onPressed: () {
              final value = double.tryParse(amount.text.trim());
              if (value != null && value > 0) { Navigator.pop(dialogContext, (movement, value, note.text)); }
            }, child: const Text('حفظ الحركة')),
          ],
        )));
      if (!mounted || result == null) { return; }
      await state.adjustStock(productId: product.id, change: result.$1 == 'add' ? result.$2 : -result.$2,
        reason: result.$1 == 'add' ? 'إضافة مخزون' : 'صرف مخزون', note: result.$3);
      if (mounted) { messenger.showSnackBar(const SnackBar(content: Text('تم تحديث كمية المخزون'))); }
    } catch (error) {
      if (mounted) {
        final message = error.toString().contains('سالبة') ? 'الكمية المطلوبة أكبر من الرصيد المتاح' : 'تعذر تحديث المخزون';
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      amount.dispose(); note.dispose();
    }
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.width, required this.title, required this.value, required this.color});
  final double width;
  final String title, value;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(width: width, child: Card(child: Padding(
    padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.circle, color: color, size: 12), const SizedBox(height: 8),
      Text(title, style: const TextStyle(fontSize: 12)), const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
    ]),
  )));
}
