import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/watchlist_model.dart';
import 'package:flutter_application_1/provider/api_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

class WatchlistProvider with ChangeNotifier {
  List<Watchlist> watchlist = [];
  bool _isLoading = false;
  String? _error;

  final storage = const FlutterSecureStorage();
  var logger = Logger();

  List<Watchlist> get watchStrategies => watchlist;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchWatchlist(String username) async {
    _isLoading = true;
    notifyListeners();

   try {
      watchlist = await ApiProvider().getWatchlist(username);
    } catch (e) {
      print("Failed to load strategies: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteWatchList(BuildContext context, String strategyId) async {
    _isLoading = true;
    notifyListeners();

    String? userid = await storage.read(key: 'email');

    logger.i("User ID: $userid");

    print("STRATEGY ID: $strategyId");

    try {
      // Call the deleteStrategy method from ApiProvider
      bool success =
      await ApiProvider().deleteWatchList(userid ?? "", strategyId);

      if (success) {
        fetchWatchlist(userid ?? "");
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Strategy removed from watchlist successfully")));
        logger.i("Watch List deleted successfully.");
      } else {
        logger.e("Failed to delete Watch List.");
      }
    } catch (e) {
      logger.e("Error during deletion: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
