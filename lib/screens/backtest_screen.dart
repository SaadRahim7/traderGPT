import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../provider/stock_chart_provider.dart';
import '../services/backtest_service.dart';

class BacktestScreen extends StatefulWidget {
  @override
  _BacktestScreenState createState() => _BacktestScreenState();
}

class _BacktestScreenState extends State<BacktestScreen> {
  bool isLoading = true;
  List<FlSpot> strategyData = [];
  List<FlSpot> sp500Data = [];
  Map<String, String> metrics = {};

  final TextEditingController stockController = TextEditingController();
  String? selectedStock;
  double? selectedPrice;
  int? selectedYear;

  void _runBacktest() async {
    final backtestService =
        Provider.of<BacktestService>(context, listen: false);

    // Fetch data
    final data = await backtestService.runBacktest();
    final calculatedMetrics = await backtestService.calculateMetrics();

    setState(() {
      strategyData = data[0]; // FlSpot data for GPT Trader Strategy
      sp500Data = data[1]; // FlSpot data for S&P 500
      metrics = calculatedMetrics;
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _runBacktest();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Padding(
            padding: EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
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
                  const SizedBox(height: 10),

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
                  const SizedBox(height: 10),
                  SizedBox(
                    height: size.height * 0.4,
                    child: Consumer<StockProvider>(
                      builder: (context, stockProvider, child) {
                        if (stockProvider.allStockData.isEmpty) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return LineChart(
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
                                      List<dynamic>? timestamps = stockProvider
                                          .allStockTimestamps[symbol];
                                      if (timestamps != null &&
                                          value.toInt() < timestamps.length) {
                                        DateTime date =
                                            DateTime.fromMillisecondsSinceEpoch(
                                                timestamps[value.toInt()] *
                                                    1000);
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
                                    .map((entry) => FlSpot(
                                        entry.key.toDouble(), entry.value))
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
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Expanded(
                  //   child: LineChart(
                  //     LineChartData(
                  //       titlesData: FlTitlesData(
                  //         leftTitles: AxisTitles(
                  //           sideTitles: SideTitles(showTitles: true),
                  //         ),
                  //         bottomTitles: AxisTitles(
                  //           sideTitles: SideTitles(showTitles: true),
                  //         ),
                  //       ),
                  //       borderData: FlBorderData(show: true),
                  //       gridData: FlGridData(show: true),
                  //       lineBarsData: [
                  //         LineChartBarData(
                  //           spots: strategyData,
                  //           isCurved: true,
                  //           color: Colors.blue, // Use 'color' instead of 'colors'
                  //           belowBarData: BarAreaData(show: false),
                  //           dotData: FlDotData(show: false), // Optional: disable dots
                  //         ),
                  //         LineChartBarData(
                  //           spots: sp500Data,
                  //           isCurved: true,
                  //           color: Colors.red, // Use 'color' instead of 'colors'
                  //           belowBarData: BarAreaData(show: false),
                  //           dotData: FlDotData(show: false), // Optional: disable dots
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  // SizedBox(height: 16),
                  Text('Backtest Metrics',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  _buildMetricsTable(),
                ],
              ),
            ),
          );
  }

  Widget _buildMetricsTable() {
    return DataTable(
      columns: [
        DataColumn(label: Text('Metric')),
        DataColumn(label: Text('Value')),
      ],
      rows: metrics.entries
          .map(
            (entry) => DataRow(
              cells: [
                DataCell(Text(entry.key)),
                DataCell(Text(entry.value)),
              ],
            ),
          )
          .toList(),
    );
  }
}
