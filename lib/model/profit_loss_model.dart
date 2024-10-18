class ProfitLoss {
  List<ProductWisePl>? productWisePl; // For Coinbase
  ProfitLossByStrategy? profitLossByStrategy; // For Paper/Live
  List<Strategy>? strategies; // For Paper/Live strategies

  double? totalPl;
  double? totalRealizedPl;
  double? totalUnrealizedPl;

  ProfitLoss({
    this.productWisePl,
    this.profitLossByStrategy,
    this.strategies,
    this.totalPl,
    this.totalRealizedPl,
    this.totalUnrealizedPl,
  });

  factory ProfitLoss.fromJson(Map<String, dynamic> json) {
    return ProfitLoss(
      productWisePl: json['product_wise_pl'] != null
          ? List<ProductWisePl>.from(
              json['product_wise_pl'].map((item) => ProductWisePl.fromJson(item)))
          : null,
      profitLossByStrategy: json['profit_loss_by_strategy'] != null
          ? ProfitLossByStrategy.fromJson(json['profit_loss_by_strategy'])
          : null,
      strategies: json['strategies'] != null
          ? List<Strategy>.from(json['strategies'].map((item) => Strategy.fromJson(item)))
          : null,
      totalPl: json['total_pl']?.toDouble(),
      totalRealizedPl: json['total_realized_pl']?.toDouble(),
      totalUnrealizedPl: json['total_unrealized_pl']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_wise_pl': productWisePl?.map((item) => item.toJson()).toList(),
      'profit_loss_by_strategy': profitLossByStrategy?.toJson(),
      'strategies': strategies?.map((item) => item.toJson()).toList(),
      'total_pl': totalPl,
      'total_realized_pl': totalRealizedPl,
      'total_unrealized_pl': totalUnrealizedPl,
    };
  }
}

class ProductWisePl {
  String productId;
  double realizedPl;
  double totalPl;
  double unrealizedPl;

  ProductWisePl({
    required this.productId,
    required this.realizedPl,
    required this.totalPl,
    required this.unrealizedPl,
  });

  factory ProductWisePl.fromJson(Map<String, dynamic> json) {
    return ProductWisePl(
      productId: json['product_id'],
      realizedPl: json['realized_pl'].toDouble(),
      totalPl: json['total_pl'].toDouble(),
      unrealizedPl: json['unrealized_pl'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'realized_pl': realizedPl,
      'total_pl': totalPl,
      'unrealized_pl': unrealizedPl,
    };
  }
}

class ProfitLossByStrategy {
  Map<String, double> profitLossMap;

  ProfitLossByStrategy({
    required this.profitLossMap,
  });

  factory ProfitLossByStrategy.fromJson(Map<String, dynamic> json) {
    return ProfitLossByStrategy(
      profitLossMap: Map<String, double>.from(json),
    );
  }

  Map<String, dynamic> toJson() {
    return profitLossMap;
  }
}

class Strategy {
  String displayName;
  String id;
  String name;

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

  Map<String, dynamic> toJson() {
    return {
      'display_name': displayName,
      'id': id,
      'name': name,
    };
  }
}
