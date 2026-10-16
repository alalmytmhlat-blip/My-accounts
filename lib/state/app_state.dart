import 'package:flutter/foundation.dart';
import '../data/inventory_repository.dart';
import '../data/expense_repository.dart';
import '../data/party_repository.dart';
import '../data/account_repository.dart';
import '../data/financial_movement_repository.dart';

class AppState extends ChangeNotifier {
  AppState(this.repository, this.inventoryRepository, this.expenseRepository, this.accountRepository, this.movementRepository);
  final PartyRepository repository;
  final InventoryRepository inventoryRepository;
  final ExpenseRepository expenseRepository;
  final AccountRepository accountRepository;
  final FinancialMovementRepository movementRepository;
  DashboardSummary? summary;
  InventorySummary? inventorySummary;
  AccountSummary? accountSummary;
  FinancialMovementSummary? movementSummary;
  List<FinancialMovement> movements = [];
  List<FinancialAccount> accounts = [];
  List<Party> customers = [];
  List<Party> suppliers = [];
  List<Product> products = [];
  List<Expense> expenses = [];
  bool loading = false;
  String? error;

  Future<void> refresh() async {
    loading = true; error = null; notifyListeners();
    try {
      summary = await repository.getDashboardSummary();
      customers = await repository.getParties(type: 'customer');
      suppliers = await repository.getParties(type: 'supplier');
      products = await inventoryRepository.getProducts();
      inventorySummary = await inventoryRepository.getSummary();
      expenses = await expenseRepository.getExpenses();
      accounts = await accountRepository.getAccounts();
      accountSummary = await accountRepository.getSummary();
      movements = await movementRepository.getMovements();
      movementSummary = await movementRepository.getSummary();
    } catch (_) { error = 'تعذر تحميل البيانات. حاول مرة أخرى.'; }
    finally { loading = false; notifyListeners(); }
  }

  Future<void> addParty({required String name, required String type, String phone = '', String address = ''}) async {
    await repository.addParty(name: name, type: type, phone: phone, address: address); await refresh();
  }
  Future<void> addProduct({required String name, String code = '', String category = '', String unit = 'قطعة', required double quantity, required double minimumQuantity, required int purchasePriceMinor, required int salePriceMinor}) async {
    await inventoryRepository.addProduct(name: name, code: code, category: category, unit: unit, quantity: quantity, minimumQuantity: minimumQuantity, purchasePriceMinor: purchasePriceMinor, salePriceMinor: salePriceMinor); await refresh();
  }
  Future<void> addExpense({required String title, required int amountMinor, required String date, String category = ''}) async {
    await expenseRepository.addExpense(title: title, amountMinor: amountMinor, date: date, category: category); await refresh();
  }
  Future<void> addAccount({required String name, required String type, required int openingBalanceMinor}) async {
    await accountRepository.addAccount(name: name, type: type, openingBalanceMinor: openingBalanceMinor); await refresh();
  }
  Future<void> addMovement({required int accountId, required String type, required int amountMinor, required String description, required String date}) async {
    await movementRepository.addMovement(accountId: accountId, type: type, amountMinor: amountMinor, description: description, date: date); await refresh();
  }
  Future<void> adjustStock({required int productId, required double change, required String reason, String note = ''}) async {
    await inventoryRepository.adjustStock(productId: productId, change: change, reason: reason, note: note); await refresh();
  }
}
