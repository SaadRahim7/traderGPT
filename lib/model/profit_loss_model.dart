class ProfitLoss {
  final List<ProductWisePl> productWisePl;
  final double totalPl;
  final double totalRealizedPl;
  final double totalUnrealizedPl;
  final ProfitLossByStrategy profitLossByStrategy;
  final List<Strategy> strategies;

  ProfitLoss({
    required this.productWisePl,
    required this.totalPl,
    required this.totalRealizedPl,
    required this.totalUnrealizedPl,
    required this.profitLossByStrategy,
    required this.strategies,
  });

  factory ProfitLoss.fromJson(Map<String, dynamic> json) {
    return ProfitLoss(
      productWisePl: (json['product_wise_pl'] as List)
          .map((item) => ProductWisePl.fromJson(item))
          .toList(),
      totalPl: json['total_pl'],
      totalRealizedPl: json['total_realized_pl'],
      totalUnrealizedPl: json['total_unrealized_pl'],
      profitLossByStrategy: ProfitLossByStrategy.fromJson(json['profit_loss_by_strategy']),
      strategies: (json['strategies'] as List)
          .map((item) => Strategy.fromJson(item))
          .toList(),
    );
  }
}

class ProductWisePl {
  final String productId;
  final double realizedPl;
  final double totalPl;
  final double unrealizedPl;

  ProductWisePl({
    required this.productId,
    required this.realizedPl,
    required this.totalPl,
    required this.unrealizedPl,
  });

  factory ProductWisePl.fromJson(Map<String, dynamic> json) {
    return ProductWisePl(
      productId: json['product_id'],
      realizedPl: json['realized_pl'],
      totalPl: json['total_pl'],
      unrealizedPl: json['unrealized_pl'],
    );
  }
}

class ProfitLossByStrategy {
  final Map<String, double> profitLossByStrategy;
  final double all;

  ProfitLossByStrategy({
    required this.profitLossByStrategy,
    required this.all,
  });

  factory ProfitLossByStrategy.fromJson(Map<String, dynamic> json) {
    return ProfitLossByStrategy(
      profitLossByStrategy: (json..remove('all')).map((key, value) => MapEntry(key, value.toDouble())),
      all: json['all'],
    );
  }
}

class Strategy {
  final String displayName;
  final String id;
  final String name;

  Strategy({
    required this.displayName,
    required this.id,
    required this.name,
  });

  factory Strategy.fromJson(Map<String, dynamic> json) {
    return Strategy(
      displayName: json['display_name'],
      id: json['id'],
      name: json['name'],
    );
  }
}
