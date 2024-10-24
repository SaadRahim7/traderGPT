import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

class StockProvider extends ChangeNotifier {
  Map<String, List<dynamic>> allStockData = {};
  Map<String, Color> stockColors = {};
  Map<String, List<dynamic>> allStockTimestamps = {};
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
