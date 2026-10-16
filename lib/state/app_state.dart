import 'package:flutter/foundation.dart';
import '../data/inventory_repository.dart';
import '../data/party_repository.dart';

class AppState extends ChangeNotifier {
  AppState(this.repository, this.inventoryRepository);
  final PartyRepository repository;
  final InventoryRepository inventoryRepository;
  DashboardSummary? summary;
  InventorySummary? inventorySummary;
  List<Party> customers = [];
  List<Party> suppliers = [];
  List<Product> products = [];
  bool loading = false;
  String? error;

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      summary = await repository.getDashboardSummary();
      customers = await repository.getParties(type: 'customer');
      suppliers = await repository.getParties(type: 'supplier');
      products = await inventoryRepository.getProducts();
      inventorySummary = await inventoryRepository.getSummary();
    } catch (_) {
      error = 'تعذر تحميل البيانات. حاول مرة أخرى.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> addParty({required String name, required String type, String phone = '', String address = ''}) async {
    await repository.addParty(name: name, type: type, phone: phone, address: address);
    await refresh();
  }

  Future<void> addProduct({
    required String name, String code = '', String category = '', String unit = 'قطعة',
    required double quantity, required double minimumQuantity,
    required int purchasePriceMinor, required int salePriceMinor,
  }) async {
    await inventoryRepository.addProduct(name: name, code: code, category: category, unit: unit,
      quantity: quantity, minimumQuantity: minimumQuantity,
      purchasePriceMinor: purchasePriceMinor, salePriceMinor: salePriceMinor);
    await refresh();
  }

  Future<void> adjustStock({required int productId, required double change, required String reason, String note = ''}) async {
    await inventoryRepository.adjustStock(productId: productId, change: change, reason: reason, note: note);
    await refresh();
  }
}
