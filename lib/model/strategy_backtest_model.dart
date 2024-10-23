import 'dart:convert';

// class StrategyBacktestModel {
//   final InteractiveDataJson interactiveDataJson;
//   final String interactiveDataPath;
//   final MetricsJson metricsJson;
//   final String metricsPath;
//   final String plotPath;
//   final String status;
//   final String strategyId;

//   StrategyBacktestModel({
//     required this.interactiveDataJson,
//     required this.interactiveDataPath,
//     required this.metricsJson,
//     required this.metricsPath,
//     required this.plotPath,
//     required this.status,
//     required this.strategyId,
//   });

//   factory StrategyBacktestModel.fromJson(Map<String, dynamic> json) {
//     return StrategyBacktestModel(
//       interactiveDataJson: InteractiveDataJson.fromJson(json['interactive_data']),
//       interactiveDataPath: json['interactive_data_path'],
//       metricsJson: MetricsJson.fromJson(jsonDecode(json['metrics_json'])),
//       metricsPath: json['metrics_path'],
//       plotPath: json['plot_path'],
//       status: json['status'],
//       strategyId: json['strategy_id'],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'interactive_data_json': interactiveDataJson.toJson(),
//       'interactive_data_path': interactiveDataPath,
//       'metrics_json': jsonEncode(metricsJson.toJson()),
//       'metrics_path': metricsPath,
//       'plot_path': plotPath,
//       'status': status,
//       'strategy_id': strategyId,
//     };
//   }
// }

// class InteractiveDataJson {
//   final List<String> dates;
//   final List<double?> sp500Returns;
//   final List<double?> strategyReturns;

//   InteractiveDataJson({
//     required this.dates,
//     required this.sp500Returns,
//     required this.strategyReturns,
//   });

//   factory InteractiveDataJson.fromJson(Map<String, dynamic> json) {
//     return InteractiveDataJson(
//       dates: List<String>.from(json['dates']),
//       sp500Returns: List<double?>.from(json['sp500_returns'].map((item) => item?.toDouble())),
//       strategyReturns: List<double?>.from(json['strategy_returns'].map((item) => item?.toDouble())),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'dates': dates,
//       'sp500_returns': sp500Returns,
//       'strategy_returns': strategyReturns,
//     };
//   }
// }

// class MetricsJson {
//   final List<String> columns;
//   final List<String> index;
//   final List<List<dynamic>> data;

//   MetricsJson({
//     required this.columns,
//     required this.index,
//     required this.data,
//   });

//   factory MetricsJson.fromJson(Map<String, dynamic> json) {
//     return MetricsJson(
//       columns: List<String>.from(json['columns']),
//       index: List<String>.from(json['index']),
//       data: List<List<dynamic>>.from(json['data'].map((row) => List<dynamic>.from(row))),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'columns': columns,
//       'index': index,
//       'data': data,
//     };
//   }
// }




class StrategyBacktestModel {
  final List<String>? dates;
  final List<dynamic?>? sp500Returns;
  final List<dynamic?>? strategyReturns;
  final String? interactiveDataPath;
  final Metrics? metrics;
  final String? metricsJson;
  final String? metricsPath;
  final String? plotPath;
  final String? status;
  final String? strategyId;

  StrategyBacktestModel({
    this.dates,
    this.sp500Returns,
    this.strategyReturns,
    this.interactiveDataPath,
    this.metrics,
    this.metricsJson,
    this.metricsPath,
    this.plotPath,
    this.status,
    this.strategyId,
  });

  factory StrategyBacktestModel.fromJson(Map<String, dynamic> json) {
    return StrategyBacktestModel(
      dates: List<String>.from(json['interactive_data']['dates']),
      sp500Returns: (json['interactive_data']['sp500_returns'] as List)
          .map((e) => e == null ? null : e.toDouble())
          .toList(),
      strategyReturns: (json['interactive_data']['strategy_returns'] as List)
          .map((e) => e == null ? null : e.toDouble())
          .toList(),
      interactiveDataPath: json['interactive_data_path'],
      metrics: Metrics.fromJson(json['metrics']),
      metricsJson: json['metrics_json'],
      metricsPath: json['metrics_path'],
      plotPath: json['plot_path'],
      status: json['status'],
      strategyId: json['strategy_id'],
    );
  }
}

class Metrics {
  final MetricsDetail? annualizedReturn;
  final MetricsDetail? finalValue;
  final MetricsDetail? initialInvestment;
  final MetricsDetail? maxDrawdown;
  final MetricsDetail? sharpeRatio;
  final MetricsDetail? standardDeviation;

  Metrics({
    this.annualizedReturn,
    this.finalValue,
    this.initialInvestment,
    this.maxDrawdown,
    this.sharpeRatio,
    this.standardDeviation,
  });

  factory Metrics.fromJson(Map<String, dynamic> json) {
    return Metrics(
      annualizedReturn: MetricsDetail.fromJson(json['Annualized Return']),
      finalValue: MetricsDetail.fromJson(json['Final Value']),
      initialInvestment: MetricsDetail.fromJson(json['Initial Investment']),
      maxDrawdown: MetricsDetail.fromJson(json['Max Drawdown']),
      sharpeRatio: MetricsDetail.fromJson(json['Sharpe Ratio']),
      standardDeviation: MetricsDetail.fromJson(json['Standard Deviation']),
    );
  }
}

class MetricsDetail {
  final String gptTraderStrategy;
  final String sp500;

  MetricsDetail({
    required this.gptTraderStrategy,
    required this.sp500,
  });

  factory MetricsDetail.fromJson(Map<String, dynamic> json) {
    return MetricsDetail(
      gptTraderStrategy: json['GPT Trader Strategy'].toString(),
      sp500: json['S&P 500'].toString(),
    );
  }
}

