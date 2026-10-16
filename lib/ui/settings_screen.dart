import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _tax = TextEditingController();
  final _currency = TextEditingController(text: 'ر.ي');
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _name.text = prefs.getString('business_name') ?? '';
    _phone.text = prefs.getString('business_phone') ?? '';
    _address.text = prefs.getString('business_address') ?? '';
    _tax.text = prefs.getString('business_tax_number') ?? '';
    _currency.text = prefs.getString('business_currency') ?? 'ر.ي';
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('business_name', _name.text.trim());
    await prefs.setString('business_phone', _phone.text.trim());
    await prefs.setString('business_address', _address.text.trim());
    await prefs.setString('business_tax_number', _tax.text.trim());
    await prefs.setString('business_currency', _currency.text.trim());
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ إعدادات المنشأة على الجهاز')),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _tax.dispose();
    _currency.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('إعدادات المنشأة')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Icon(Icons.storefront_outlined, size: 54),
                const SizedBox(height: 8),
                const Text('بيانات المنشأة', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'اسم المنشأة', prefixIcon: Icon(Icons.store)), validator: (v) => v == null || v.trim().isEmpty ? 'أدخل اسم المنشأة' : null),
                const SizedBox(height: 12),
                TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone))),
                const SizedBox(height: 12),
                TextFormField(controller: _address, maxLines: 2, decoration: const InputDecoration(labelText: 'العنوان', prefixIcon: Icon(Icons.location_on_outlined))),
                const SizedBox(height: 12),
                TextFormField(controller: _tax, decoration: const InputDecoration(labelText: 'الرقم الضريبي (اختياري)', prefixIcon: Icon(Icons.numbers))),
                const SizedBox(height: 12),
                TextFormField(controller: _currency, decoration: const InputDecoration(labelText: 'رمز العملة الافتراضي', prefixIcon: Icon(Icons.currency_exchange)), validator: (v) => v == null || v.trim().isEmpty ? 'أدخل رمز العملة' : null),
                const SizedBox(height: 24),
                FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ الإعدادات')),
                const SizedBox(height: 12),
                Text('تُحفظ هذه البيانات محليًا على هذا الجهاز، ولا تُرسل إلى خادم.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
  );
}
