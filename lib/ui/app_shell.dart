import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'dashboard_screen.dart';
import 'parties_screen.dart';
import 'more_screen.dart';
import 'invoices_screen.dart';
import 'simple_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selected = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppState>().refresh());
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardScreen(),
      const InvoicesScreen(),
      const PartiesScreen(),
      const SimpleScreen(title: 'التقارير', icon: Icons.bar_chart_rounded, description: 'التقارير المحاسبية قيد الإنشاء.'),
      const MoreScreen(),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: selected, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (value) => setState(() => selected = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'الفواتير'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'العملاء'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), label: 'التقارير'),
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'المزيد'),
        ],
      ),
    );
  }
}
