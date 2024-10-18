import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../provider/stock_chart_provider.dart';

class StockChartScreen extends StatefulWidget {
  const StockChartScreen({super.key});

  @override
  _StockChartScreenState createState() => _StockChartScreenState();
}

class _StockChartScreenState extends State<StockChartScreen> {
  final TextEditingController stockController = TextEditingController();
  String? selectedStock;
  double? selectedPrice;
  int? selectedYear;

  @override
  void initState() {
    super.initState();

    Provider.of<StockProvider>(context, listen: false).fetchInitialStockData();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: stockController,
                decoration: InputDecoration(
                  hintText: "Enter stock & crypto",
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ElevatedButton(
                      onPressed: () async {
                        String symbol =
                            stockController.text.trim().toUpperCase();
                        if (symbol.isNotEmpty) {
                          await Provider.of<StockProvider>(context,
                                  listen: false)
                              .fetchStockData(context, symbol);
                          stockController.clear();
                        }
                      },
                      child: const Text('Add Ticker'),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Consumer<StockProvider>(
                builder: (context, stockProvider, child) {
                  if (stockProvider.allStockData.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 20,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                String year = "";
                                for (var symbol
                                    in stockProvider.allStockData.keys) {
                                  List<dynamic>? timestamps =
                                      stockProvider.allStockTimestamps[symbol];
                                  if (timestamps != null &&
                                      value.toInt() < timestamps.length) {
                                    DateTime date =
                                        DateTime.fromMillisecondsSinceEpoch(
                                            timestamps[value.toInt()] * 1000);
                                    year = date.year.toString();
                                  }
                                }
                                return Text(
                                  year,
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData:
                            stockProvider.allStockData.keys.map((symbol) {
                          return LineChartBarData(
                            spots: stockProvider.allStockData[symbol]!
                                .asMap()
                                .entries
                                .map((entry) =>
                                    FlSpot(entry.key.toDouble(), entry.value))
                                .toList(),
                            isCurved: true,
                            color: stockProvider.stockColors[symbol]!,
                            barWidth: 2,
                            belowBarData: BarAreaData(show: false),
                            dotData: const FlDotData(show: false),
                          );
                        }).toList(),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems:
                                (List<LineBarSpot> touchedBarSpots) {
                              return touchedBarSpots.map((lineBarSpot) {
                                String stockName = stockProvider
                                    .allStockData.keys
                                    .elementAt(lineBarSpot.barIndex);
                                double price = lineBarSpot.y;
                                return LineTooltipItem(
                                  '$stockName: ${price.toStringAsFixed(2)}',
                                  const TextStyle(color: Colors.white),
                                );
                              }).toList();
                            },
                          ),
                          touchCallback: (FlTouchEvent event,
                              LineTouchResponse? touchResponse) {
                            if (event is FlTapDownEvent &&
                                touchResponse != null &&
                                touchResponse.lineBarSpots != null) {
                              for (var lineBarSpot
                                  in touchResponse.lineBarSpots!) {
                                double x = lineBarSpot.x;
                                double y = lineBarSpot.y;

                                String stockName = stockProvider
                                    .allStockData.keys
                                    .elementAt(lineBarSpot.barIndex);
                                selectedStock = stockName;
                                selectedPrice = y;
                                int timestampIndex = x.toInt();
                                if (stockProvider
                                        .allStockTimestamps[stockName] !=
                                    null) {
                                  selectedYear =
                                      DateTime.fromMillisecondsSinceEpoch(
                                    stockProvider.allStockTimestamps[
                                            stockName]![timestampIndex] *
                                        1000,
                                  ).year;
                                }
                              }
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Consumer<StockProvider>(
              builder: (context, stockProvider, child) {
                return Wrap(
                  spacing: 10,
                  children: stockProvider.allStockData.keys.map((symbol) {
                    return GestureDetector(
                      onTap: () {
                        stockProvider.removeStock(symbol);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: stockProvider.stockColors[symbol],
                                shape: BoxShape.rectangle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              symbol,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
