import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/api_provider.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class StockProvider extends ChangeNotifier {
  Map<String, List<dynamic>> allStockData = {};
  Map<String, Color> stockColors = {};
  Map<String, List<dynamic>> allStockTimestamps = {};

  List<double?> strategyReturns = [];
  List<String>? strategyDates = [];
  var logger = Logger();
  final List<Color> _availableColors = [
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.yellow,
    Colors.pink,
    Colors.blue,
  ];

  Random _random = Random();

  // Fetch stock data from Yahoo Finance API
  Future<void> fetchStockData(context, String symbol) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?range=10y&interval=1mo'),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        List<dynamic> prices =
            data['chart']['result'][0]['indicators']['quote'][0]['close'];
        List<dynamic> timestamps = data['chart']['result'][0]['timestamp'];
        List<dynamic> cleanPrices =
            prices.map((e) => e?.toDouble() ?? 0.0).toList();
        List<dynamic> cleanTimestamps =
            timestamps.map((e) => e.toInt()).toList();

        // Only add if data is not already present
        if (!allStockData.containsKey(symbol)) {
          allStockData[symbol] = cleanPrices;
          allStockTimestamps[symbol] = cleanTimestamps;

          // Assign a random color for the new stock
          Color color =
              _availableColors[_random.nextInt(_availableColors.length)];
          stockColors[symbol] = color;

          notifyListeners();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock/Crypto not avaliable')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$e")),
      );
    }
  }

  Future<void> fetchStrategyChartData(String username, String strategy) async {
    try {
      final strategyChart =
          await ApiProvider().getStrategyBacktestChart(username, strategy);

      if (strategyChart != null) {
        strategyReturns = strategyChart.strategyReturns ?? [];
        strategyDates = strategyChart.dates ?? [];

        // Assign a color to the strategy returns line
        if (!stockColors.containsKey('strategy_returns')) {
          Color strategyColor =
              _availableColors[_random.nextInt(_availableColors.length)];
          stockColors['strategy_returns'] = strategyColor;
        }

        notifyListeners();
      }
    } catch (e) {
      logger.e("Failed to fetch strategy data: $e");
    }
  }

  // Remove stock data but keep S&P 500 (^GSPC)
  void removeStock(String symbol) {
    if (symbol != "^GSPC") {
      allStockData.remove(symbol);
      stockColors.remove(symbol);
      notifyListeners();
    }
  }

  // Fetch default S&P 500 (^GSPC) data on startup
  Future<void> fetchInitialStockData() async {
    await fetchStockData(BuildContext, "^GSPC");
  }
}
