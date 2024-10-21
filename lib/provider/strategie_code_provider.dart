import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/api_provider.dart';

class StrategiesCodeProvider with ChangeNotifier {
  var strategieCode;
  bool isLoading = false;
  String? errorMessage;
  var refector;

  Future<void> fetchStratrgieCode(String username, String strategieid) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      strategieCode =
          await ApiProvider().getstrategiecode(username, strategieid);
    } catch (error) {
      errorMessage = 'Failed to load data: $error';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
