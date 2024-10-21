import 'package:flutter/foundation.dart';
import '../model/backtest_strategy_chart_model.dart';
import '../model/metric_model.dart';
import 'api_provider.dart';

class BacktestProvider with ChangeNotifier {
  StrategyMetric? _metricData;
  StrategyBacktestChart? _chartData;
  StrategyBacktestChartYahoo? _yahooData;
  bool _isLoading = false;
  String? _errorMessage;

  StrategyMetric? get metricData => _metricData;
  StrategyBacktestChart? get chartData => _chartData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchStrategyMetric(String username, String strategy) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _metricData = await ApiProvider().getStrategyMetrics(username, strategy);
    } catch (e) {
      _errorMessage = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStrategyChart(String username, String strategy) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _chartData =
          await ApiProvider().getStrategyBacktestChart(username, strategy);
    } catch (e) {
      _errorMessage = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStrategyChartYahoo(
      String username, String strategy, List dates) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _yahooData =
          await ApiProvider().getYahooCharts(username, strategy, dates);
    } catch (e) {
      _errorMessage = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
