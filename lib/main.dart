import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'data/app_database.dart';
import 'data/party_repository.dart';
import 'data/inventory_repository.dart';
import 'data/expense_repository.dart';
import 'data/account_repository.dart';
import 'data/financial_movement_repository.dart';
import 'data/invoice_repository.dart';
import 'state/app_state.dart';
import 'ui/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();
  await database.initialize();
  runApp(ChangeNotifierProvider(
    create: (_) => AppState(PartyRepository(database), InventoryRepository(database), ExpenseRepository(database), AccountRepository(database), FinancialMovementRepository(database), InvoiceRepository(database)),
    child: const HisabatiApp(),
  ));
}

class HisabatiApp extends StatelessWidget {
  const HisabatiApp({super.key});
  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF176B45);
    return MaterialApp(
      title: 'حساباتي', debugShowCheckedModeBanner: false, locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')], localizationsDelegates: GlobalMaterialLocalizations.delegates,
      themeMode: ThemeMode.system,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: green, brightness: Brightness.light), scaffoldBackgroundColor: const Color(0xFFF5F7F6), appBarTheme: const AppBarTheme(centerTitle: false, backgroundColor: Color(0xFFF5F7F6)), cardTheme: CardThemeData(elevation: 1, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18)))), inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide.none))),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: green, brightness: Brightness.dark), cardTheme: CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))))),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child ?? const SizedBox.shrink()),
      home: const AppShell(),
    );
  }
}
