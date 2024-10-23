import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/watchlist_strategy_model.dart';
import 'package:flutter_application_1/provider/api_provider.dart';

import '../model/backtest_strategy_chart_model.dart';

class WatchlistStrategyProvider with ChangeNotifier {
  WatchlistStrategy? _watchlistStrategy;
  StrategyBacktestChartYahoo? _yahooData;
  bool _isLoading = false;
  String? _errorMessage;

  WatchlistStrategy? get watchlistStrategy => _watchlistStrategy;
  StrategyBacktestChartYahoo? get yahooData => _yahooData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<List<FlSpot>> _allDatas = [];
  List<List<FlSpot>> get allDatas => _allDatas;

  Future<void> fetchWatchlist(
      String userid, String creatorid, String strategyid) async {
    _isLoading = true;
    notifyListeners();

    List<FlSpot> sp500Data = [];
    List<FlSpot>? strategyData = [];

    _allDatas = [];

    try {
      _watchlistStrategy = await ApiProvider()
          .getWatchliststrategy(userid, creatorid, strategyid);

      // Add SP500 data
      if (_watchlistStrategy!.interactiveData != null) {
        for (int i = 0;
            i < _watchlistStrategy!.interactiveData.sp500Returns.length;
            i++) {
          double? returnValue =
              _watchlistStrategy!.interactiveData.sp500Returns[i];
          if (returnValue != null) {
            sp500Data.add(FlSpot(i.toDouble(), returnValue));
          }
        }

        _allDatas.add(sp500Data);
      }

      // Add strategy returns data
      if (_watchlistStrategy!.interactiveData != null) {
        for (int i = 0;
            i < _watchlistStrategy!.interactiveData.strategyReturns.length;
            i++) {
          double? returnValue =
              _watchlistStrategy!.interactiveData.strategyReturns[i];
          if (returnValue != null) {
            strategyData.add(FlSpot(i.toDouble(), returnValue));
          }
        }

        _allDatas.add(strategyData);
      }
    } catch (e) {
      print("Failed to load strategies: $e");
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
