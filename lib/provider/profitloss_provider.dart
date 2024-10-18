import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/profit_loss_model.dart';

import 'api_provider.dart';

class ProfitlossProvider extends ChangeNotifier {
  List<ProfitLoss> _profitloss = [];
  bool _loading = false;

  List<ProfitLoss> get profitloss => _profitloss;
  bool get loading => _loading;

  Future<void> fetchStrategies(String username, String mode) async {
    _loading = true;
    notifyListeners();

    try {
      _profitloss = await ApiProvider().profitloss(username, mode);
    } catch (e) {
      print("Failed to load strategies: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
