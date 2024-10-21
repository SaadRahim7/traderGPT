import 'dart:math';

import 'package:flutter/material.dart';

import '../model/logs_model.dart';
import 'api_provider.dart';

class LogProvider with ChangeNotifier {
  List<LogEntry> _logs = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<LogEntry> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchLogs(String username, String strategieid) async {
    _isLoading = true;
    notifyListeners();

    try {
      _logs = await ApiProvider().getLogs(username, strategieid);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
