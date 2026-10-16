import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/inventory_repository.dart';
import '../data/invoice_repository.dart';
import '../data/party_repository.dart';
import '../state/app_state.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});
  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  String type = 'sale';
  String query = '';
  String money(int minor) => NumberFormat.currency(locale: 'ar', symbol: 'ر.ي', decimalDigits: 2).format(minor / 100);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final invoices = state.invoices.where((invoice) =>
      invoice.type == type && (invoice.number.contains(query) || invoice.partyName.contains(query))).toList();
    final total = invoices.fold<int>(0, (sum, invoice) => sum + invoice.totalMinor);
    return Scaffold(
      appBar: AppBar(title: const Text('الفواتير'), actions: [
        IconButton(onPressed: state.refresh, icon: const Icon(Icons.refresh), tooltip: 'تحديث'),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createInvoice, icon: const Icon(Icons.add), label: Text(type == 'sale' ? 'فاتورة بيع' : 'فاتورة شراء')),
      body: RefreshIndicator(onRefresh: state.refresh, child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'sale', label: Text('المبيعات'), icon: Icon(Icons.point_of_sale_outlined)),
              ButtonSegment(value: 'purchase', label: Text('المشتريات'), icon: Icon(Icons.shopping_cart_outlined)),
            ],
            selected: {type},
            onSelectionChanged: (value) => setState(() => type = value.first),
          ),
          const SizedBox(height: 12),
          Card(child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
            title: const Text('إجمالي الفواتير المعروضة'),
            subtitle: Text('${invoices.length} فاتورة'),
            trailing: Text(money(total), style: const TextStyle(fontWeight: FontWeight.bold)),
          )),
          const SizedBox(height: 8),
          TextField(decoration: const InputDecoration(hintText: 'بحث برقم الفاتورة أو اسم العميل/المورد', prefixIcon: Icon(Icons.search)),
            onChanged: (value) => setState(() => query = value.trim())),
          const SizedBox(height: 8),
          if (invoices.isEmpty)
            const Padding(padding: EdgeInsets.all(28), child: Center(child: Text('لا توجد فواتير في هذا القسم بعد.')))
          else
            ...invoices.map((invoice) => Card(child: ListTile(
              leading: CircleAvatar(child: Icon(invoice.type == 'sale' ? Icons.north_east : Icons.south_west)),
              title: Text(invoice.number, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${invoice.partyName} • ${invoice.date}\n${_status(invoice.status)} • المتبقي: ${money(invoice.remainingMinor)}'),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                tooltip: 'إجراءات الفاتورة',
                onSelected: (action) { if (action == 'payment') {
                    _recordPayment(invoice);
                  } },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'total', enabled: false, child: Text('الإجمالي: ${money(invoice.totalMinor)}')),
                  if (invoice.remainingMinor > 0) const PopupMenuItem(value: 'payment', child: Text('تسجيل دفعة')),
                ],
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(money(invoice.totalMinor), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Icon(Icons.more_vert, size: 18),
                ]),
              ),
            ))),
        ],
      )),
    );
  }

  Future<void> _recordPayment(InvoiceRecord invoice) async {
    final state = context.read<AppState>();
    if (state.accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف حسابًا ماليًا أولًا لتسجيل الدفعة.')));
      return;
    }
    final amount = TextEditingController();
    final note = TextEditingController();
    var accountId = state.accounts.first.id;
    final result = await showDialog<(int, int, String)?>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: Text('تسجيل دفعة • ${invoice.number}'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('المبلغ المتبقي: ${money(invoice.remainingMinor)}'),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(initialValue: accountId, decoration: const InputDecoration(labelText: 'حساب القبض/الصرف'),
          items: state.accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (value) { if (value != null) {
              setDialogState(() => accountId = value);
            } }),
        const SizedBox(height: 10),
        TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'مبلغ الدفعة')),
        const SizedBox(height: 10),
        TextField(controller: note, decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
        FilledButton(onPressed: () {
          final parsed = double.tryParse(amount.text.trim());
          if (parsed == null || parsed <= 0 || (parsed * 100).round() > invoice.remainingMinor) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تحقق من مبلغ الدفعة وألا يتجاوز المتبقي.')));
            return;
          }
          Navigator.pop(dialogContext, (accountId, (parsed * 100).round(), note.text.trim()));
        }, child: const Text('حفظ الدفعة')),
      ],
    )));
    if (!mounted || result == null) { amount.dispose(); note.dispose(); return; }
    try {
      await context.read<AppState>().addInvoicePayment(invoiceId: invoice.id, accountId: result.$1, amountMinor: result.$2,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()), note: result.$3);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الدفعة وتحديث الفاتورة والحسابات')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تسجيل الدفعة: $error')));
      }
    } finally { amount.dispose(); note.dispose(); }
  }

  String _status(String status) => switch (status) {
    'paid' => 'مدفوعة بالكامل', 'partial' => 'مدفوعة جزئيًا', _ => 'غير مدفوعة',
  };

  Future<void> _createInvoice() async {
    final state = context.read<AppState>();
    final parties = type == 'sale' ? state.customers : state.suppliers;
    final products = state.products;
    if (parties.isEmpty || products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        parties.isEmpty ? (type == 'sale' ? 'أضف عميلًا أولًا' : 'أضف موردًا أولًا') : 'أضف صنفًا إلى المخزون أولًا')));
      return;
    }
    final result = await showDialog<_InvoiceDraft>(context: context, builder: (context) =>
      _InvoiceDialog(type: type, parties: parties, products: products));
    if (!mounted || result == null) {
      return;
    }
    try {
      await state.createInvoice(type: type, partyId: result.partyId, lines: result.lines,
        paidMinor: result.paidMinor, date: DateFormat('yyyy-MM-dd').format(result.date),
        dueDate: result.dueDate == null ? null : DateFormat('yyyy-MM-dd').format(result.dueDate!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الفاتورة وتحديث المخزون')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر حفظ الفاتورة: $error')));
      }
    }
  }
}

class _InvoiceDraft {
  const _InvoiceDraft({required this.partyId, required this.lines, required this.paidMinor, required this.date, this.dueDate});
  final int partyId, paidMinor;
  final List<InvoiceLineInput> lines;
  final DateTime date;
  final DateTime? dueDate;
}

class _CartLine {
  const _CartLine({required this.product, required this.quantity, required this.priceMinor});
  final Product product;
  final double quantity;
  final int priceMinor;
  int get totalMinor => (quantity * priceMinor).round();
}

class _InvoiceDialog extends StatefulWidget {
  const _InvoiceDialog({required this.type, required this.parties, required this.products});
  final String type;
  final List<Party> parties;
  final List<Product> products;
  @override
  State<_InvoiceDialog> createState() => _InvoiceDialogState();
}

class _InvoiceDialogState extends State<_InvoiceDialog> {
  int? partyId;
  int? productId;
  final quantity = TextEditingController(text: '1');
  final price = TextEditingController();
  final paid = TextEditingController(text: '0');
  final cart = <_CartLine>[];
  DateTime invoiceDate = DateTime.now();
  DateTime? dueDate;
  int get totalMinor => cart.fold<int>(0, (sum, line) => sum + line.totalMinor);
  String money(int minor) => NumberFormat.currency(locale: 'ar', symbol: 'ر.ي', decimalDigits: 2).format(minor / 100);

  @override
  void initState() {
    super.initState();
    partyId = widget.parties.first.id;
    productId = widget.products.first.id;
    _setDefaultPrice();
  }

  void _setDefaultPrice() {
    final matches = widget.products.where((product) => product.id == productId);
    if (matches.isNotEmpty) {
      final product = matches.first;
      price.text = ((widget.type == 'sale' ? product.salePriceMinor : product.purchasePriceMinor) / 100).toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    quantity.dispose();
    price.dispose();
    paid.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.type == 'sale' ? 'إنشاء فاتورة بيع' : 'إنشاء فاتورة شراء'),
    content: SizedBox(width: 480, child: SingleChildScrollView(child: Column(
      mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        DropdownButtonFormField<int>(initialValue: partyId, decoration: InputDecoration(labelText: widget.type == 'sale' ? 'العميل' : 'المورد'),
          items: widget.parties.map((party) => DropdownMenuItem(value: party.id, child: Text(party.name, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (value) => setState(() => partyId = value)),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(initialValue: productId, decoration: const InputDecoration(labelText: 'الصنف'),
          items: widget.products.map((product) => DropdownMenuItem(value: product.id, child: Text('${product.name} (متاح: ${product.quantity} ${product.unit})', overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (value) => setState(() { productId = value; _setDefaultPrice(); })),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: quantity, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'الكمية'))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'سعر الوحدة'))),
          IconButton(onPressed: _addLine, icon: const Icon(Icons.add_circle), tooltip: 'إضافة الصنف'),
        ]),
        const SizedBox(height: 8),
        if (cart.isNotEmpty) ...cart.asMap().entries.map((entry) => ListTile(
          dense: true, contentPadding: EdgeInsets.zero,
          title: Text(entry.value.product.name),
          subtitle: Text('${entry.value.quantity} × ${money(entry.value.priceMinor)}'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(money(entry.value.totalMinor)),
            IconButton(onPressed: () => setState(() => cart.removeAt(entry.key)), icon: const Icon(Icons.close, size: 18)),
          ]),
        )),
        const Divider(),
        Align(alignment: Alignment.centerRight, child: Text('الإجمالي: ${money(totalMinor)}', style: const TextStyle(fontWeight: FontWeight.bold))),
        const SizedBox(height: 8),
        TextField(controller: paid, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'المدفوع الآن (ر.ي)')),
        const SizedBox(height: 8),
        ListTile(contentPadding: EdgeInsets.zero, title: const Text('تاريخ الفاتورة'), subtitle: Text(DateFormat('yyyy-MM-dd').format(invoiceDate)),
          trailing: const Icon(Icons.calendar_month), onTap: () async {
            final picked = await showDatePicker(context: context, initialDate: invoiceDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
            if (picked != null) {
              setState(() => invoiceDate = picked);
            }
          }),
        ListTile(contentPadding: EdgeInsets.zero, title: const Text('تاريخ الاستحقاق (اختياري)'),
          subtitle: Text(dueDate == null ? 'غير محدد' : DateFormat('yyyy-MM-dd').format(dueDate!)),
          trailing: const Icon(Icons.event_available), onTap: () async {
            final picked = await showDatePicker(context: context, initialDate: dueDate ?? invoiceDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
            if (picked != null) {
              setState(() => dueDate = picked);
            }
          }),
      ],
    ))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
      FilledButton(onPressed: _save, child: const Text('حفظ الفاتورة')),
    ],
  );

  void _addLine() {
    final id = productId;
    final qty = double.tryParse(quantity.text.trim());
    final unitPrice = double.tryParse(price.text.trim());
    if (id == null || qty == null || qty <= 0 || unitPrice == null || unitPrice < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل كمية وسعرًا صحيحين')));
      return;
    }
    final product = widget.products.firstWhere((item) => item.id == id);
    if (widget.type == 'sale' && cart.where((line) => line.product.id == id).fold<double>(0, (sum, line) => sum + line.quantity) + qty > product.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الكمية المطلوبة تتجاوز المخزون المتاح')));
      return;
    }
    setState(() {
      cart.add(_CartLine(product: product, quantity: qty, priceMinor: (unitPrice * 100).round()));
      quantity.text = '1';
    });
  }

  void _save() {
    if (partyId == null || cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر الجهة وأضف صنفًا واحدًا على الأقل')),
      );
      return;
    }
    Navigator.pop(
      context,
      _InvoiceDraft(
        partyId: partyId!,
        lines: cart
            .map((line) => InvoiceLineInput(
                  productId: line.product.id,
                  quantity: line.quantity,
                  unitPriceMinor: line.priceMinor,
                ))
            .toList(),
        paidMinor: 0,
        date: invoiceDate,
        dueDate: dueDate,
      ),
    );
  }
}
