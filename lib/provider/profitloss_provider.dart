import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/profit_loss_model.dart';
import 'api_provider.dart';

class ProfitlossProvider with ChangeNotifier {
  ProfitLoss? _profitloss;
  bool _isLoading = false;
  String? _errorMessage;

  ProfitLoss? get strategies => _profitloss;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProfitLoss(String username, String mode) async {
    _isLoading = true;
    notifyListeners();

    try {
      _profitloss = await ApiProvider().getProfitLoss(username, mode);
    } catch (e) {
      _errorMessage = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
