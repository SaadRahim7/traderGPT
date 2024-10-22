class StrategyBacktestChart {
  List<String>? dates;
  List<double?> sp500Returns;
  List<double?> strategyReturns;

  StrategyBacktestChart({
    required this.dates,
    required this.sp500Returns,
    required this.strategyReturns,
  });

  // Factory constructor for creating a new StrategyBacktestChart instance from a map
  factory StrategyBacktestChart.fromJson(Map<String, dynamic> json) {
    return StrategyBacktestChart(
      dates: List<String>.from(json['dates']),
      sp500Returns: (json['sp500_returns'] as List<dynamic>)
          .map((item) => item != null ? item as double : null)
          .toList(),
      strategyReturns: (json['strategy_returns'] as List<dynamic>)
          .map((item) => item != null ? item as double : null)
          .toList(),
    );
  }

  // Method to convert the StrategyBacktestChart instance back to JSON
  Map<String, dynamic> toJson() {
    return {
      'dates': dates,
      'sp500_returns': sp500Returns,
      'strategy_returns': strategyReturns,
    };
  }
}

class StrategyBacktestChartYahoo {
  final List<double> cumulativeReturns;
  final List<String> dates;

  StrategyBacktestChartYahoo({
    required this.cumulativeReturns,
    required this.dates,
  });

  factory StrategyBacktestChartYahoo.fromJson(Map<String, dynamic> json) {
    return StrategyBacktestChartYahoo(
      cumulativeReturns: List<double>.from(json['cumulative_returns']),
      dates: List<String>.from(json['dates']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cumulative_returns': cumulativeReturns,
      'dates': dates,
    };
  }
}



