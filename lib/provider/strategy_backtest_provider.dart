import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/strategy_backtest_model.dart';
import 'package:flutter_application_1/provider/api_provider.dart';
import 'package:logger/logger.dart';
import '../model/backtest_strategy_chart_model.dart';

class StrategyBacktestProvider with ChangeNotifier {
  StrategyBacktestModel? _data;
  StrategyBacktestChartYahoo? _yahooData;
  bool _isLoading = false;
  String? _errorMessage;

  StrategyBacktestModel? get data => _data;
  StrategyBacktestChartYahoo? get yahooData => _yahooData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<List<FlSpot>> _allDatas = [];
  List<List<FlSpot>> get allDatas => _allDatas;

  Future<void> fetchInteractiveData(
      String userid, String conversitonid, String messageid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    List<FlSpot> sp500Data = [];
    List<FlSpot>? strategyData = [];

    _allDatas = [];

    try {
      _data = await ApiProvider().backTest(
          context: BuildContext,
          userId: userid,
          conversationId: conversitonid,
          messageId: messageid);

      // Add SP500 data
      if (_data != null) {
        for (int i = 0; i < _data!.sp500Returns!.length; i++) {
          double? returnValue = _data!.sp500Returns![i];
          if (returnValue != null) {
            sp500Data.add(FlSpot(i.toDouble(), returnValue));
          }
        }

        _allDatas.add(sp500Data);
      }

      // Add strategy returns data
      if (_data != null) {
        for (int i = 0; i < _data!.strategyReturns!.length; i++) {
          double? returnValue = _data!.strategyReturns![i];
          if (returnValue != null) {
            strategyData.add(FlSpot(i.toDouble(), returnValue));
          }
        }

        _allDatas.add(strategyData);
      }
    } catch (e) {
      _errorMessage = 'Python Code Execution Failed';
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
