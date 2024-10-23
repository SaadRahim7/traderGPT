import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_application_1/provider/backtest_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import '../model/backtest_strategy_chart_model.dart';
import '../provider/strategy_provider.dart';

class BacktestScreen extends StatefulWidget {
  const BacktestScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _BacktestScreenState createState() => _BacktestScreenState();
}

const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
List<String> strategies = [];

class _BacktestScreenState extends State<BacktestScreen> {
  String? selectedStrategy;

  final TextEditingController stockController = TextEditingController();

  Future<void>? _fetchMetricData;
  Future<void>? _fetchChartcData;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final backtestProvider = Provider.of<BacktestProvider>(context);
    return Padding(
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
                      String? email = await _secureStorage.read(key: 'email');

                      setState(() {
                        Provider.of<BacktestProvider>(context, listen: false)
                            .fetchStrategyMetric(email!, selectedStrategy!);

                        Provider.of<BacktestProvider>(context, listen: false)
                            .fetchStrategyChart(email!, selectedStrategy!);
                      });

                      if (strategies.length > 0) {
                        strategies.clear();
                      }

                      strategies.add('S&P500');
                      strategies.add('GPT Strategy');
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 20),

            //Chart
            if (selectedStrategy != null)
              backtestProvider.chartData != null
                  ? LineChartWidget(chartData: backtestProvider.chartData!)
                  : const Center(
                      child: Text('No data available'),
                    ),
            const SizedBox(height: 20),

            //Metric
            if (selectedStrategy != null)
              const Text('Metrics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (selectedStrategy != null) _buildMetricsTable(),
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
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final provider =
              Provider.of<BacktestProvider>(context, listen: false);
          if (provider.metricData == null) {
            return const Center(child: Text('No data available'));
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
  }
}

class LineChartWidget extends StatefulWidget {
  final StrategyBacktestChart chartData;

  const LineChartWidget({super.key, required this.chartData});

  @override
  // ignore: library_private_types_in_public_api
  _LineChartWidgetState createState() => _LineChartWidgetState();
}

class _LineChartWidgetState extends State<LineChartWidget> {
  TextEditingController _symbolController = TextEditingController();
  String? _inputText = 'other';
  List color = [];

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final backtestProvider = Provider.of<BacktestProvider>(context);
    return Column(
      children: [
        TextField(
          controller: _symbolController,
          decoration: InputDecoration(
            hintText: "Enter stock & crypto",
            suffixIcon: Padding(
              padding: const EdgeInsets.all(10),
              child: ElevatedButton(
                onPressed: () async {
                  String? email = await _secureStorage.read(key: 'email');
                  Provider.of<BacktestProvider>(context, listen: false)
                      .fetchStrategyChartYahoo(email!, _symbolController.text,
                          widget.chartData.dates!);
                  //_addStrategy();
                  _symbolController.clear();
                },
                child: const Text('Add Ticker'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        if (backtestProvider.chartData != null)
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: backtestProvider.allStrategies.length,
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: CustomText(
                          color: backtestProvider.allStrategiesColor[index],
                          title: backtestProvider.allStrategies[index],
                        ))
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: 20),

        //chart
        SizedBox(
          height: size.height * 0.4,
          child: Consumer<BacktestProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              List<LineChartBarData> lineBarsData = [];

              for (int i = 0; i < provider.allDatas.length; i++) {
                var element = provider.allDatas[i];
                var elementColor = provider.allStrategiesColor[i];

                lineBarsData.add(LineChartBarData(
                  spots: element,
                  isCurved: true,
                  color: elementColor,
                  barWidth: 2,
                  belowBarData: BarAreaData(show: false),
                  dotData: const FlDotData(show: false),
                ));
              }

              return LineChart(
                LineChartData(
                    gridData: const FlGridData(show: true),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            int index = value.toInt();
                            String year;

                            if (index < provider.chartData!.dates!.length) {
                              year = DateFormat('yyyy').format(DateTime.parse(
                                  provider.chartData!.dates![index]));
                            } else {
                              year = '';
                            }
                            return Text(year,
                                style: const TextStyle(fontSize: 10));
                          },
                          interval: 300,
                        ),
                      ),
                    ),
                    lineBarsData: lineBarsData),
              );
            },
          ),
        ),
      ],
    );
  }
}

class CustomText extends StatelessWidget {
  final Color color;
  final String title;
  const CustomText({super.key, required this.color, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.rectangle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }
}
