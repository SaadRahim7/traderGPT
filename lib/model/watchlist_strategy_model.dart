import 'dart:convert';

// Main Response Model
class WatchlistStrategy {
  final String code;
  final InteractiveData interactiveData;
  final Metrics metrics;

  WatchlistStrategy({
    required this.code,
    required this.interactiveData,
    required this.metrics,
  });

  factory WatchlistStrategy.fromJson(Map<String, dynamic> json) {
    return WatchlistStrategy(
      code: json['code'],
      interactiveData: InteractiveData.fromJson(json['interactive_data']),
      metrics: Metrics.fromJson(json['metrics']),
    );
  }
}

// Interactive Data Model
class InteractiveData {
  final List<String> dates;
  final List<double?> sp500Returns;
  final List<double?> strategyReturns;

  InteractiveData({
    required this.dates,
    required this.sp500Returns,
    required this.strategyReturns,
  });

  factory InteractiveData.fromJson(Map<String, dynamic> json) {
    return InteractiveData(
      dates: List<String>.from(json['dates']),
      sp500Returns: List<double?>.from(json['sp500_returns'].map((x) => x is double ? x : null)),
      strategyReturns: List<double?>.from(json['strategy_returns'].map((x) => x is double ? x : null)),
    );
  }
}

// Metrics Model
class Metrics {
  final List<String> columns;
  final List<List<String>> data;

  Metrics({
    required this.columns,
    required this.data,
  });

  factory Metrics.fromJson(Map<String, dynamic> json) {
    return Metrics(
      columns: List<String>.from(json['columns']),
      data: List<List<String>>.from(json['data'].map((x) => List<String>.from(x))),
    );
  }
}

// Example of how to parse JSON string into WatchlistStrategy
WatchlistStrategy parseWatchlistStrategy(String jsonString) {
  final Map<String, dynamic> jsonData = json.decode(jsonString);
  return WatchlistStrategy.fromJson(jsonData);
}
