import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/position_model.dart';
import 'api_provider.dart';

class PositionProvider with ChangeNotifier {
  PositionsResponse? _positionResponse;
  bool _isLoading = false;
  String _error = "";

  PositionsResponse? get positionResponse => _positionResponse;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchPositions(String username, String mode) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _positionResponse = await ApiProvider().getPositions(username, mode);
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
