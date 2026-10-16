import 'package:flutter/material.dart';
class SimpleScreen extends StatelessWidget {
  const SimpleScreen({super.key, required this.title, required this.icon, required this.description});
  final String title, description;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
    ]))),
  );
}
