import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class BacktestService with ChangeNotifier {
  Future<List<List<FlSpot>>> runBacktest() async {
    // Simulate backtest data similar to your Python script
    await Future.delayed(Duration(seconds: 1)); // Simulate network delay

    // Generate dummy data
    final startDate = DateTime.now().subtract(Duration(days: 365 * 10));
    final dates = List<DateTime>.generate(365 * 10, (i) => startDate.add(Duration(days: i)));

    final random = Random();

    // Generate cumulative returns for GPT Trader Strategy
    List<TimeSeriesReturns> strategyReturns = [];
    double cumulativeReturnStrategy = 100000.0; // Initial capital
    for (var date in dates) {
      double dailyReturn = (random.nextDouble() - 0.5) * 0.02; // Simulate daily return between -1% and +1%
      cumulativeReturnStrategy *= (1 + dailyReturn);
      strategyReturns.add(TimeSeriesReturns(date, cumulativeReturnStrategy));
    }

    // Generate cumulative returns for S&P 500
    List<TimeSeriesReturns> sp500Returns = [];
    double cumulativeReturnSP500 = 100000.0; // Initial capital
    for (var date in dates) {
      double dailyReturn = (random.nextDouble() - 0.5) * 0.015; // Simulate daily return between -0.75% and +0.75%
      cumulativeReturnSP500 *= (1 + dailyReturn);
      sp500Returns.add(TimeSeriesReturns(date, cumulativeReturnSP500));
    }

    // Convert data to FlSpot format for fl_chart
    List<FlSpot> strategyFlSpots = strategyReturns.map((returns) {
      return FlSpot(
        returns.time.millisecondsSinceEpoch.toDouble(),
        returns.value,
      );
    }).toList();

    List<FlSpot> sp500FlSpots = sp500Returns.map((returns) {
      return FlSpot(
        returns.time.millisecondsSinceEpoch.toDouble(),
        returns.value,
      );
    }).toList();

    // Return both datasets as a list of lists
    return [strategyFlSpots, sp500FlSpots];
  }

  Future<Map<String, String>> calculateMetrics() async {
    // Simulate metrics calculation
    await Future.delayed(Duration(seconds: 1)); // Simulate network delay

    // Placeholder metrics
    return {
      'Final Value': '\$150,000',
      'Annualized Return': '5.5%',
      'Sharpe Ratio': '1.2',
      'Standard Deviation': '15%',
      'Max Drawdown': '20%',
    };
  }
}

class TimeSeriesReturns {
  final DateTime time;
  final double value;

  TimeSeriesReturns(this.time, this.value);
}