import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
class AccountsScreen extends StatelessWidget {
 const AccountsScreen({super.key});
 @override Widget build(BuildContext context) {
  final s=context.watch<AppState>();
  return Scaffold(appBar: AppBar(title: const Text('الحسابات والصندوق والبنوك')), body: ListView(children: [Text((s.accountSummary?.balanceMinor ?? 0).toString()), ...s.accounts.map((a)=>ListTile(title: Text(a.name), subtitle: Text(a.type), trailing: Text(a.openingBalanceMinor.toString())))]));
 }
}
