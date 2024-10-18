class Positions {
  final String symbol;
  final double avgPrice;
  final double marketValue;
  final double qty;
  final double? totalCost; // Optional, for Coinbase response

  Positions({
    required this.symbol,
    required this.avgPrice,
    required this.marketValue,
    required this.qty,
    this.totalCost, // Optional for non-coinbase data
  });

  // Factory constructor to create an Positions from JSON
  factory Positions.fromJson(Map<String, dynamic> json, String symbol) {
    return Positions(
      symbol: symbol,
      avgPrice: json.containsKey('avg_price')
          ? json['avg_price']?.toDouble() ?? 0.0
          : json['average_price']?.toDouble() ?? 0.0,
      marketValue: json.containsKey('market_value')
          ? json['market_value']?.toDouble() ?? 0.0
          : json['total_cost']?.toDouble() ?? 0.0,
      qty: json['qty']?.toDouble() ?? json['quantity']?.toDouble() ?? 0.0,
      totalCost: json.containsKey('total_cost')
          ? json['total_cost']?.toDouble()
          : null, // Only available in Coinbase response
    );
  }
}

class PositionsResponse {
  final Map<String, Positions> Positionss;

  PositionsResponse({required this.Positionss});

  // Factory constructor to parse the entire response
  factory PositionsResponse.fromJson(Map<String, dynamic> json) {
    final assets = <String, Positions>{};
    json.forEach((symbol, data) {
      assets[symbol] =
          Positions.fromJson(data, symbol); // Passing the symbol as the key
    });
    return PositionsResponse(Positionss: assets);
  }
}
