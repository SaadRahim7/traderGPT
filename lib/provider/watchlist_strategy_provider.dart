import 'dart:math';

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

  List<String> _allStrategies = [];
  List<String> get allStrategies => _allStrategies;
  List<Color> _allStrategiesColor = [];
  List<Color> get allStrategiesColor => _allStrategiesColor;

  Set<Color> usedColors = {};

  Color getRandomUniqueColor() {
    Random random = Random();
    Color newColor;

    do {
      // Generate brighter colors by using higher ranges for RGB values
      newColor = Color.fromARGB(
          255,
          (random.nextInt(3) * 85) + 85, // Min value of 85 for red
          (random.nextInt(3) * 85) + 85, // Min value of 85 for green
          (random.nextInt(3) * 85) + 85 // Min value of 85 for blue
          );
    } while (usedColors.contains(newColor));

    usedColors.add(newColor);
    return newColor;
  }

  Future<void> fetchWatchlist(
      String userid, String creatorid, String strategyid) async {
    _isLoading = true;
    notifyListeners();

    List<FlSpot> sp500Data = [];
    List<FlSpot>? strategyData = [];

    _allDatas = [];
    _allStrategies = [];
    _allStrategiesColor = [];

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
        _allStrategies.add('S&P500');
        _allStrategiesColor.add(getRandomUniqueColor());
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
        _allStrategies.add('GPT Strategy');
        _allStrategiesColor.add(getRandomUniqueColor());
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
        _allStrategies.add(strategy);
        _allStrategiesColor.add(getRandomUniqueColor());
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
