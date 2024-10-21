import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_application_1/provider/backtest_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../model/backtest_strategy_chart_model.dart';
import '../provider/stock_chart_provider.dart';
import '../provider/strategy_provider.dart';
import '../services/backtest_service.dart';
import 'package:http/http.dart' as http;

class BacktestScreen extends StatefulWidget {
  @override
  _BacktestScreenState createState() => _BacktestScreenState();
}

class _BacktestScreenState extends State<BacktestScreen> {
  bool isLoading = true;
  List<FlSpot> strategyData = [];
  List<FlSpot> sp500Data = [];
  Map<String, String> metrics = {};
  String? selectedStrategy;

  final TextEditingController stockController = TextEditingController();
  String? selectedStock;
  double? selectedPrice;
  int? selectedYear;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  Future<void>? _fetchMetricData;
  Future<void>? _fetchChartcData;

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
    final backtestProvider = Provider.of<BacktestProvider>(context);
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  //Strategy Dropdown
                  Consumer<StrategyProvider>(
                    builder: (context, strategyProvider, child) {
                      if (strategyProvider.loading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (strategyProvider.strategies.isEmpty) {
                        return const Text("No strategies available");
                      }

                      return DropdownButtonFormField<String>(
                        isExpanded: true,
                        hint: const Text('Select a strategy'),
                        value: selectedStrategy,
                        items: strategyProvider.strategies.map((strategy) {
                          return DropdownMenuItem<String>(
                            value: strategy.id,
                            child: Text(
                              strategy.displayName.toString(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) async {
                          setState(() {
                            selectedStrategy = newValue;
                          });
                          if (newValue != null) {
                            String? email =
                                await _secureStorage.read(key: 'email');

                            setState(() {
                              _fetchMetricData = Provider.of<BacktestProvider>(
                                      context,
                                      listen: false)
                                  .fetchStrategyMetric(
                                      email!, selectedStrategy!);

                              _fetchChartcData = Provider.of<BacktestProvider>(
                                      context,
                                      listen: false)
                                  .fetchStrategyChart(
                                      email!, selectedStrategy!);
                            });
                          }
                        },
                      );
                    },
                  ),
                  SizedBox(height: 20),

                  //Add ticker Field
                  if (selectedStrategy != null)
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

                  //Crypto & Title Name
                  if (selectedStrategy != null)
                    Consumer<StockProvider>(
                      builder: (context, stockProvider, child) {
                        return Wrap(
                          spacing: 10,
                          children:
                              stockProvider.allStockData.keys.map((symbol) {
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
                                        color:
                                            stockProvider.stockColors[symbol],
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

                  //Chart
                  if (selectedStrategy != null)
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
                                        List<dynamic>? timestamps =
                                            stockProvider
                                                .allStockTimestamps[symbol];
                                        if (timestamps != null &&
                                            value.toInt() < timestamps.length) {
                                          DateTime date = DateTime
                                              .fromMillisecondsSinceEpoch(
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

                  //Chart1
                  if (selectedStrategy != null)
                    backtestProvider.chartData != null
                        ? SizedBox(
                            height: size.height * 0.4,
                            child: LineChartWidget(
                                chartData: backtestProvider.chartData!),
                          )
                        : Center(child: Text('No data available')),

                  //Metric
                  if (selectedStrategy != null)
                    const Text('Metrics',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildMetricsTable(),
                ],
              ),
            ),
          );
  }

  Widget _buildMetricsTable() {
    return FutureBuilder<void>(
      future: _fetchMetricData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final provider =
              Provider.of<BacktestProvider>(context, listen: false);
          if (provider.metricData == null) {
            return Center(child: Text('No data available'));
          }

          final data = provider.metricData!;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: data.columns
                  .map((column) => DataColumn(label: Text(column)))
                  .toList(),
              rows: data.data.map((strategy) {
                return DataRow(cells: [
                  DataCell(Text(strategy.strategyName)),
                  DataCell(Text(strategy.initialInvestment)),
                  DataCell(Text(strategy.finalValue)),
                  DataCell(Text(strategy.annualizedReturn)),
                  DataCell(Text(strategy.sharpeRatio)),
                  DataCell(Text(strategy.standardDeviation)),
                  DataCell(Text(strategy.maxDrawdown)),
                ]);
              }).toList(),
            ),
          );
        }
      },
    );

    // Consumer<BacktestProvider>(
    //   builder: (context, backtestProvider, child) {
    //     if (backtestProvider.isLoading) {
    //       return const Center(child: CircularProgressIndicator());
    //     }

    //     if (backtestProvider.errorMessage != null) {
    //       return Center(child: Text(backtestProvider.errorMessage!));
    //     }

    //     final data = backtestProvider.metricData!;

    //     return SingleChildScrollView(
    //       scrollDirection: Axis.horizontal,
    //       child: DataTable(
    //         columns: data.columns
    //             .map((column) => DataColumn(label: Text(column)))
    //             .toList(),
    //         rows: data.data.map((strategy) {
    //           return DataRow(cells: [
    //             DataCell(Text(strategy.strategyName)),
    //             DataCell(Text(strategy.initialInvestment)),
    //             DataCell(Text(strategy.finalValue)),
    //             DataCell(Text(strategy.annualizedReturn)),
    //             DataCell(Text(strategy.sharpeRatio)),
    //             DataCell(Text(strategy.standardDeviation)),
    //             DataCell(Text(strategy.maxDrawdown)),
    //           ]);
    //         }).toList(),
    //       ),
    //     );
    //   },
    // );
  }
}

// class LineChartWidget extends StatelessWidget {
//   final StrategyBacktestChart chartData;

//   LineChartWidget({required this.chartData});

//   @override
//   Widget build(BuildContext context) {
//     return LineChart(
//       LineChartData(
//         gridData: FlGridData(show: true),
//         titlesData: FlTitlesData(
//           topTitles:
//               const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           rightTitles:
//               const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           leftTitles:
//               const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           bottomTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               getTitlesWidget: (value, meta) {
//                 int index = value.toInt();

//                 if (index % 12 == 0 &&
//                     index >= 0 &&
//                     index < chartData.dates!.length) {
//                   return Text(
//                     _formatToYear(chartData.dates![index]),
//                     style: TextStyle(fontSize: 10),
//                   );
//                 }

//                 return const SizedBox.shrink();
//               },
//               interval: 50,
//             ),
//           ),
//         ),
//         lineBarsData: [
//           // S&P 500 returns line
//           LineChartBarData(
//             spots: _getMonthlySpots(
//               chartData.sp500Returns!,
//             ),
//             isCurved: true,
//             color: Colors.blue,
//             barWidth: 2,
//             belowBarData: BarAreaData(show: false),
//             dotData: const FlDotData(show: false),
//           ),
//           // Strategy returns line
//           LineChartBarData(
//             spots: _getMonthlySpots(
//               chartData.strategyReturns!,
//             ),
//             isCurved: true,
//             color: Colors.yellow,
//             barWidth: 2,
//             belowBarData: BarAreaData(show: false),
//             dotData: const FlDotData(show: false),
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatToYear(String date) {
//     return date.substring(0, 4); // Extract only the year (YYYY)
//   }

//   // Helper function to filter only the last 10 years (120 months)
//   List<String> _getLastTenYearsDates(List<String> dates) {
//     int startIndex = dates.length > 120 ? dates.length - 120 : 0;
//     return dates.sublist(startIndex);
//   }

//   // Helper function to filter data for the last 10 years (120 months)
//   List<double?> _getLastTenYearsData(List<double?> data) {
//     int startIndex = data.length > 120 ? data.length - 120 : 0;
//     return data.sublist(startIndex);
//   }

//   // Helper function to get all monthly data points (filtered for 10 years)
//   List<FlSpot> _getMonthlySpots(List<double?> data) {
//     List<FlSpot> spots = [];

//     for (int i = 0; i < data.length; i++) {
//       if (data[i] != null) {
//         spots.add(FlSpot(i.toDouble(), data[i]!));
//       }
//     }

//     return spots;
//   }
// }

class LineChartWidget extends StatefulWidget {
  final StrategyBacktestChart chartData;

  LineChartWidget({required this.chartData});

  @override
  _LineChartWidgetState createState() => _LineChartWidgetState();
}

class _LineChartWidgetState extends State<LineChartWidget> {
  TextEditingController _symbolController = TextEditingController();
  List<FlSpot> _newSpots = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _symbolController,

            decoration: InputDecoration(
              labelText: 'Enter Stock Symbol',
              border: OutlineInputBorder(),
            ),
            
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Provider.of<BacktestProvider>(context, listen: false)
                .fetchStrategyChartYahoo('trump2020@gmail.com', _symbolController.text, [
              "2014-06-20",
              "2014-06-23",
              "2014-06-24",
              "2014-06-25",
            ]);
          },
          child: Text('Search'),
        ),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();

                      if (index % 12 == 0 &&
                          index >= 0 &&
                          index < widget.chartData.dates!.length) {
                        return Text(
                          _formatToYear(widget.chartData.dates![index]),
                          style: TextStyle(fontSize: 10),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                    interval: 50,
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: _newSpots.isNotEmpty
                      ? _newSpots
                      : _getMonthlySpots(widget.chartData.sp500Returns!),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 2,
                  belowBarData: BarAreaData(show: false),
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: _getMonthlySpots(widget.chartData.strategyReturns!),
                  isCurved: true,
                  color: Colors.yellow,
                  barWidth: 2,
                  belowBarData: BarAreaData(show: false),
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _fetchStockData() async {
    String symbol = _symbolController.text.trim();
    if (symbol.isEmpty) return;

    String apiUrl =
        'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?interval=1mo&range=10y'; // Example Yahoo Finance API URL

    try {
      var response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        List<FlSpot> stockSpots = _parseYahooData(data);
        setState(() {
          _newSpots = stockSpots;
        });
      } else {
        // Handle error (e.g., symbol not found)
        print('Error fetching stock data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  List<FlSpot> _parseYahooData(dynamic data) {
    // Extract historical prices and timestamps from Yahoo data
    List<dynamic> timestamps = data['chart']['result'][0]['timestamp'];
    List<dynamic> prices =
        data['chart']['result'][0]['indicators']['quote'][0]['close'];

    List<FlSpot> spots = [];
    for (int i = 0; i < prices.length; i++) {
      if (prices[i] != null) {
        spots.add(FlSpot(i.toDouble(), prices[i]));
      }
    }
    return spots;
  }

  String _formatToYear(String date) {
    return date.substring(0, 4); // Extract only the year (YYYY)
  }

  List<FlSpot> _getMonthlySpots(List<double?> data) {
    List<FlSpot> spots = [];

    for (int i = 0; i < data.length; i++) {
      if (data[i] != null) {
        spots.add(FlSpot(i.toDouble(), data[i]!));
      }
    }

    return spots;
  }
}
