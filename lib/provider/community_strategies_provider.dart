import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/community_strategie_model.dart';
import 'api_provider.dart';

// class CommunityStrategiesProvider with ChangeNotifier {
//   List<Strategy> _strategies = [];
//   bool _isLoading = false;
//   String _errorMessage = '';

//   List<Strategy> get strategies => _strategies;
//   bool get isLoading => _isLoading;
//   String get errorMessage => _errorMessage;

//   Future<void> fetchCommunityStrategies(String username, String page) async {
//     _isLoading = true;
//     _errorMessage = '';
//     notifyListeners();

//     try {
//       CommunityStrategies fetchedOrders =
//           await ApiProvider().getCommunityStrategies(username, page);

//       _strategies = fetchedOrders.strategies;
//     } catch (error) {
//       _errorMessage = error.toString();
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
// }



class CommunityStrategiesProvider with ChangeNotifier {
  List<Strategy> _strategies = [];
  bool _isLoading = false;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasMore = true;  

  List<Strategy> get strategies => _strategies;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  Future<void> fetchCommunityStrategies(String username, {bool isNextPage = false}) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Use current page or increment for next page if requested
      String page = isNextPage ? (_currentPage + 1).toString() : _currentPage.toString();

      CommunityStrategies fetchedOrders =
          await ApiProvider().getCommunityStrategies(username, page);

      if (fetchedOrders.strategies.isEmpty) {
        _hasMore = false; // No more data to load
      } else {
        if (isNextPage) {
          _strategies.addAll(fetchedOrders.strategies);
          _currentPage++;  // Move to the next page
        } else {
          _strategies = fetchedOrders.strategies;
        }
      }
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}


