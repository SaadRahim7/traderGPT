import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/profit_loss_model.dart';
import 'api_provider.dart';

class ProfitlossProvider with ChangeNotifier {
  ProfitLoss? _profitloss;
  bool _isLoading = false;
  String _errorMessage = '';

  ProfitLoss? get profitloss => _profitloss;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProfitLoss(String username, String mode) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _profitloss = await ApiProvider().getProfitLoss(username, mode);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
