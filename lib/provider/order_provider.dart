import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/order_model.dart';
import 'package:flutter_application_1/provider/api_provider.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String? _selectedType;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String? get selectedType => _selectedType;

  // Function to fetch orders based on type (live, paper, coinbase)
  Future<void> fetchOrders(String username, String mode) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Call the API function to fetch the orders
      List<Order> fetchedOrders =
          await ApiProvider().getOrders(username, mode);

      _orders = fetchedOrders;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners(); // Notifies UI to re-render when data changes
    }
  }

  // Function to update the selected option from the dropdown
  void setSelectedType(String type) {
    _selectedType = type;
    notifyListeners();
  }
}
