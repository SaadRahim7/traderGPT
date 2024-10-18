import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/api_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../model/strategy_model.dart';

class StrategyProvider extends ChangeNotifier {

  final storage = const FlutterSecureStorage();
  var logger = Logger();

  StrategyProvider(){
    fetchStrategies();
  }
  List<Strategy> _strategies = [];
  bool _loading = false;

  List<Strategy> get strategies => _strategies;
  bool get loading => _loading;

  Future<void> fetchStrategies([String? username]) async {
    _loading = true;
    notifyListeners();

    String? userid = await storage.read(key: 'email');

    print(userid);
    logger.i(userid);

    try {
      _strategies = await ApiProvider().getStrategy(userid ?? "");
      
      print(_strategies);
    } catch (e) {
      print("Failed to load strategies: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
