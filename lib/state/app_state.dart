import 'package:flutter/foundation.dart';
import '../data/party_repository.dart';

class AppState extends ChangeNotifier {
  AppState(this.repository);
  final PartyRepository repository;
  DashboardSummary? summary;
  List<Party> customers = [];
  List<Party> suppliers = [];
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
}
