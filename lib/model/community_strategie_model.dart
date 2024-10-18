class CommunityStrategies {
  final int page;
  final int perPage;
  final List<Strategy> strategies;
  final int total;

  CommunityStrategies({
    required this.page,
    required this.perPage,
    required this.strategies,
    required this.total,
  });

  factory CommunityStrategies.fromJson(Map<String, dynamic> json) {
    return CommunityStrategies(
      page: json['page'],
      perPage: json['per_page'],
      strategies: List<Strategy>.from(json['strategies'].map((s) => Strategy.fromJson(s))),
      total: json['total'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'per_page': perPage,
      'strategies': strategies.map((s) => s.toJson()).toList(),
      'total': total,
    };
  }
}

class Strategy {
  final String? annualizedReturn;
  final String displayName;
  final String? sharpeRatio;
  final String source;
  final String strategyId;
  final String? strategyName;
  final String userEmail;

  Strategy({
    this.annualizedReturn,
    required this.displayName,
    this.sharpeRatio,
    required this.source,
    required this.strategyId,
    this.strategyName,
    required this.userEmail,
  });

  factory Strategy.fromJson(Map<String, dynamic> json) {
    return Strategy(
      annualizedReturn: json['annualized_return'],
      displayName: json['display_name'],
      sharpeRatio: json['sharpe_ratio'],
      source: json['source'],
      strategyId: json['strategy_id'],
      strategyName: json['strategy_name'],
      userEmail: json['user_email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'annualized_return': annualizedReturn,
      'display_name': displayName,
      'sharpe_ratio': sharpeRatio,
      'source': source,
      'strategy_id': strategyId,
      'strategy_name': strategyName,
      'user_email': userEmail,
    };
  }
}
