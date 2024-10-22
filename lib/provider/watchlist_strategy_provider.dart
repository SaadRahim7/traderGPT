import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/watchlist_strategy_model.dart';
import 'package:flutter_application_1/provider/api_provider.dart';

class WatchlistStrategyProvider with ChangeNotifier {
  WatchlistStrategy? _watchlistStrategy;
  bool _isLoading = false;
  String? _errorMessage;

  WatchlistStrategy? get watchlistStrategy => _watchlistStrategy;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchWatchlist(
      String userid, String creatorid, String strategyid) async {
    _isLoading = true;
    notifyListeners();

    try {
      _watchlistStrategy = await ApiProvider()
          .getWatchliststrategy(userid, creatorid, strategyid);
    } catch (e) {
      print("Failed to load strategies: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
