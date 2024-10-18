import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/watchlist_model.dart';
import 'package:flutter_application_1/provider/api_provider.dart';

class WatchlistProvider with ChangeNotifier {
  List<Watchlist> watchlist = [];
  bool _isLoading = false;
  String? _error;

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
}
