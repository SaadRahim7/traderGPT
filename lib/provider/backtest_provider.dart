import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
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
  StrategyBacktestChartYahoo? get yahooData => _yahooData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<List<FlSpot>> _allDatas = [];
  List<List<FlSpot>> get allDatas => _allDatas;

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

    List<FlSpot> sp500Data = [];
    List<FlSpot>? strategyData = [];

    _allDatas = [];

    try {
      _chartData =
          await ApiProvider().getStrategyBacktestChart(username, strategy);
      Logger().i("chatdata ${_chartData!.toJson()}");

      // Add SP500 data
      if (_chartData != null) {
        for (int i = 0; i < _chartData!.sp500Returns.length; i++) {
          double? returnValue = _chartData!.sp500Returns[i];
          if (returnValue != null) {
            sp500Data.add(FlSpot(i.toDouble(), returnValue));
          }
        }

        _allDatas.add(sp500Data);
      }

      // Add strategy returns data
      if (_chartData != null) {
        for (int i = 0; i < _chartData!.strategyReturns.length; i++) {
          double? returnValue = _chartData!.strategyReturns[i];
          if (returnValue != null) {
            strategyData.add(FlSpot(i.toDouble(), returnValue));
          }
        }

        _allDatas.add(strategyData);
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStrategyChartYahoo(
      String username, String strategy, List<String> dates) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    List<FlSpot> yahooData = [];

    try {
      _yahooData =
          await ApiProvider().getYahooCharts(username, strategy, dates);

      if (_yahooData != null) {
        for (int i = 0; i < _yahooData!.cumulativeReturns.length; i++) {
          double returnValue = _yahooData!.cumulativeReturns[i];
          if (returnValue != null) {
            yahooData.add(FlSpot(i.toDouble(), returnValue));
          }
        }

        _allDatas.add(yahooData);
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<List<FlSpot>> getSeparatedData() {
    List<FlSpot> yahooData = [];

    if (_yahooData != null) {
      for (int i = 0; i < _yahooData!.cumulativeReturns.length; i++) {
        double returnValue = _yahooData!.cumulativeReturns[i];
        if (returnValue != null) {
          yahooData.add(FlSpot(i.toDouble(), returnValue));
        }
      }

      _allDatas.add(yahooData);
    }

    return _allDatas;
    
  }
}
