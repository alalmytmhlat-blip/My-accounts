import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('الحسابات والصندوق والبنوك')),
      body: ListView(children: [
        ListTile(title: const Text('إجمالي الأرصدة الافتتاحية'), subtitle: Text((state.accountSummary?.balanceMinor ?? 0).toString())),
        ...state.accounts.map((account) => ListTile(title: Text(account.name), subtitle: Text(account.type), trailing: Text(account.openingBalanceMinor.toString()))),
      ]),
    );
  }
}
