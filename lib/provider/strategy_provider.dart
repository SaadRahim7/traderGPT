import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/api_provider.dart';
import '../model/strategy_model.dart';

class StrategyProvider extends ChangeNotifier {
  List<Strategy> _strategies = [];
  bool _loading = false;

  List<Strategy> get strategies => _strategies;
  bool get loading => _loading;

  Future<void> fetchStrategies(String username) async {
    _loading = true;
    notifyListeners();

    try {
      _strategies = await ApiProvider().getStrategy(username);
    } catch (e) {
      print("Failed to load strategies: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
