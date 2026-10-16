import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/party_repository.dart';
import '../state/app_state.dart';

class PartiesScreen extends StatefulWidget {
  const PartiesScreen({super.key});
  @override
  State<PartiesScreen> createState() => _PartiesScreenState();
}
class _PartiesScreenState extends State<PartiesScreen> {
  String type = 'customer';
  String query = '';
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final all = type == 'customer' ? state.customers : state.suppliers;
    final visible = all.where((p) => p.name.contains(query) || p.phone.contains(query)).toList();
    return Scaffold(
      appBar: AppBar(title: Text(type == 'customer' ? 'العملاء' : 'الموردون'), actions: [
        IconButton(onPressed: () => _showAddDialog(context), icon: const Icon(Icons.add_circle_outline), tooltip: 'إضافة'),
      ]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: SegmentedButton<String>(
          segments: const [ButtonSegment(value: 'customer', label: Text('العملاء'), icon: Icon(Icons.people_outline)), ButtonSegment(value: 'supplier', label: Text('الموردون'), icon: Icon(Icons.local_shipping_outlined))],
          selected: {type}, onSelectionChanged: (value) => setState(() => type = value.first),
        )),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(
          decoration: const InputDecoration(hintText: 'ابحث بالاسم أو رقم الهاتف', prefixIcon: Icon(Icons.search)),
          onChanged: (value) => setState(() => query = value.trim()),
        )),
        const SizedBox(height: 8),
        Expanded(child: state.loading && all.isEmpty ? const Center(child: CircularProgressIndicator()) : visible.isEmpty
          ? const Center(child: Text('لا توجد سجلات مطابقة. أضف سجلًا جديدًا للبدء.'))
          : ListView.builder(padding: const EdgeInsets.all(12), itemCount: visible.length, itemBuilder: (context, index) {
            final Party party = visible[index];
            return Card(child: ListTile(
              leading: CircleAvatar(child: Icon(type == 'customer' ? Icons.person_outline : Icons.store_outlined)),
              title: Text(party.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text([party.phone, party.address].where((v) => v.isNotEmpty).join(' • ')),
              trailing: const Icon(Icons.chevron_left),
            ));
          })),
      ]),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final phone = TextEditingController();
    final address = TextEditingController();
    final saved = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(type == 'customer' ? 'إضافة عميل' : 'إضافة مورد'),
      content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: name, decoration: const InputDecoration(labelText: 'الاسم *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null),
        const SizedBox(height: 10),
        TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'رقم الهاتف'), keyboardType: TextInputType.phone),
        const SizedBox(height: 10),
        TextFormField(controller: address, decoration: const InputDecoration(labelText: 'العنوان')),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(dialogContext, true); }, child: const Text('حفظ')),
      ],
    ));
    if (saved == true && mounted) {
      try {
        await context.read<AppState>().addParty(name: name.text, type: type, phone: phone.text, address: address.text);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ السجل بنجاح')));
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حفظ السجل')));
      }
    }
    name.dispose(); phone.dispose(); address.dispose();
  }
}
