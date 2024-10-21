class StrategyMetric {
  List<String> columns;
  List<StrategyData> data;

  StrategyMetric({required this.columns, required this.data});

  factory StrategyMetric.fromJson(Map<String, dynamic> json) {
    return StrategyMetric(
      columns: List<String>.from(json['columns']),
      data: (json['data'] as List).map((item) => StrategyData.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'columns': columns,
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
} 

class StrategyData {
  String strategyName;
  String initialInvestment;
  String finalValue;
  String annualizedReturn;
  String sharpeRatio;
  String standardDeviation;
  String maxDrawdown;

  StrategyData({
    required this.strategyName,
    required this.initialInvestment,
    required this.finalValue,
    required this.annualizedReturn,
    required this.sharpeRatio,
    required this.standardDeviation,
    required this.maxDrawdown,
  });

  factory StrategyData.fromJson(List<dynamic> json) {
    return StrategyData(
      strategyName: json[0],
      initialInvestment: json[1],
      finalValue: json[2],
      annualizedReturn: json[3],
      sharpeRatio: json[4],
      standardDeviation: json[5],
      maxDrawdown: json[6],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'strategyName': strategyName,
      'initialInvestment': initialInvestment,
      'finalValue': finalValue,
      'annualizedReturn': annualizedReturn,
      'sharpeRatio': sharpeRatio,
      'standardDeviation': standardDeviation,
      'maxDrawdown': maxDrawdown,
    };
  }
}
