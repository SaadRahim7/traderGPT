import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/api_provider.dart';
import 'package:flutter_application_1/provider/strategy_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../model/strategy_model.dart';

class AccountProvider extends ChangeNotifier {
  final storage = const FlutterSecureStorage();
  var logger = Logger();

  StrategyProvider strategyProvider = StrategyProvider();

  bool _loading = false;



  bool get loading => _loading;

  Future<void> deleteStrategy(BuildContext context, String strategyId) async {
    _loading = true;
    notifyListeners();

    String? userid = await storage.read(key: 'email');

    logger.i("User ID: $userid");

    try {
      // Call the deleteStrategy method from ApiProvider
      bool success =
          await ApiProvider().deleteStrategy(userid ?? "", strategyId);

      if (success) {
        // If deletion is successful, fetch updated strategies
        // _strategies = await ApiProvider().getStrategy(userid ?? "");
        strategyProvider.fetchStrategies(userid ?? "");
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Strategy deleted successfully.")));
        logger.i("Strategy deleted successfully.");
      } else {
        logger.e("Failed to delete strategy.");
      }
    } catch (e) {
      logger.e("Error during deletion: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
