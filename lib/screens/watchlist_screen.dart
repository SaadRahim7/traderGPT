import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/watchlist_provider.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import '../api_handler/apis/demoapi.dart';
import '../provider/stock_chart_provider.dart';

class WatchlistScreen extends StatefulWidget {
  @override
  _WatchlistScreenState createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  bool isLoading = true;
  List<Map<String, dynamic>> watchlist = [];

  List<String> _users = [];
  List<String> _options = ["Live", "Paper", "Coinbase"];

  final TextEditingController stockController = TextEditingController();
  String? selectedStock;
  double? selectedPrice;
  int? selectedYear;

  var code = '''
import pandas as pd
import yfinance as yf
import os
import requests

def fetch_data(indicator, interval='annual', datatype='json'):
    api_key = os.getenv('ALPHA_VANTAGE_API_KEY')
    url = f"https://www.alphavantage.co/query?function={indicator}&interval={interval}&apikey={api_key}&datatype={datatype}"
    response = requests.get(url)
    data = response.json()
    if 'data' in data:
        records = data['data']
        df = pd.DataFrame(records)
        df['date'] = pd.to_datetime(df['date'])
        df['value'] = df['value'].astype(float)
        return df.set_index('date')
    else:
        raise ValueError(f"Unexpected data format from Alpha Vantage API for {indicator}")

def get_historical_data(tickers, start_date, end_date):
    data = yf.download(tickers, start=start_date, end=end_date)
    return data['Adj Close']

def calculate_indicators(data):
    indicators = pd.DataFrame(index=data.index)
    for ticker in data.columns:
        indicators[f'{ticker}_SMA50'] = data[ticker].rolling(window=50).mean()
        indicators[f'{ticker}_SMA200'] = data[ticker].rolling(window=200).mean()
        indicators[f'{ticker}_Return'] = data[ticker].pct_change().rolling(window=20).mean()
        indicators[f'{ticker}_Volatility'] = data[ticker].pct_change().rolling(window=20).std()
    return indicators

def generate_signals(data, indicators):
    signals, scores, total_score = {}, {}, 0
    for ticker in data.columns:
        sma_score = 1 if indicators[f'{ticker}_SMA50'].iloc[-1] > indicators[f'{ticker}_SMA200'].iloc[-1] else 0
        return_score = max(indicators[f'{ticker}_Return'].iloc[-1], 0)
        volatility_score = 1 / (indicators[f'{ticker}_Volatility'].iloc[-1] + 1)
        score = sma_score * 0.5 + return_score * 0.3 + volatility_score * 0.2
        scores[ticker] = score
        total_score += score
    for ticker in data.columns:
        signals[ticker] = int(round((scores[ticker] / total_score) * 100)) if total_score != 0 else 0
    remaining_allocation = 100 - sum(signals.values())
    if remaining_allocation != 0:
        sorted_tickers = sorted(signals, key=lambda x: scores[x], reverse=True)
        for i in range(abs(remaining_allocation)):
            signals[sorted_tickers[i % len(sorted_tickers)]] += 1 if remaining_allocation > 0 else -1
    return signals

def trading_strategy(start_date, end_date):
    tickers = ['NVDA', 'AMD', 'INTC']
    data = get_historical_data(tickers, start_date, end_date)
    indicators = calculate_indicators(data)
    signals = generate_signals(data, indicators)
    return signals, data

start_date = "2021-01-01"
end_date = pd.Timestamp.today().strftime('%Y-%m-%d')
signals, data = trading_strategy(start_date, end_date)

# Adjust cryptocurrency signals
signals = {k: v for k, v in signals.items()}

print(signals)
''';

  final List<Map<String, dynamic>> _tableData = [
    {
      "Symbol": "AAPL",
      "Quantity": 50,
      "Side": "Buy",
      "Type": "Market",
      "Status": "Completed",
      "Filled Quantity": 50,
      "Submitted At": "2024-10-01",
      "Filled At": "2024-10-02",
    },
    {
      "Symbol": "GOOGL",
      "Quantity": 20,
      "Side": "Sell",
      "Type": "Limit",
      "Status": "Pending",
      "Filled Quantity": 10,
      "Submitted At": "2024-10-05",
      "Filled At": "-",
    },
  ];

  Future<void> chart() async {
    Size size = MediaQuery.of(context).size;
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(12),
          content: SizedBox(
            width: size.width * 0.8,
            height: size.height * 0.8,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  HighlightView(
                    code,
                    language: 'python',
                    theme: darculaTheme,
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
                  const SizedBox(height: 20),
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      border: TableBorder.all(color: Colors.grey[700]!),
                      columns: [
                        const DataColumn(
                            label:
                                Text('Field')), // Label for the fields column
                        ..._tableData.asMap().entries.map(
                              (entry) => DataColumn(
                                label: Text('Row ${entry.key + 1}'),
                              ),
                            ), // Dynamically creates columns for each row of data
                      ],
                      rows: [
                        _buildVerticalRow(
                            'Symbol', (row) => row['Symbol'].toString()),
                        _buildVerticalRow(
                            'Quantity', (row) => row['Quantity'].toString()),
                        _buildVerticalRow(
                            'Side', (row) => row['Side'].toString()),
                        _buildVerticalRow(
                            'Type', (row) => row['Type'].toString()),
                        _buildVerticalRow(
                            'Status', (row) => row['Status'].toString()),
                        _buildVerticalRow('Filled Quantity',
                            (row) => row['Filled Quantity'].toString()),
                        _buildVerticalRow('Submitted At',
                            (row) => row['Submitted At'].toString()),
                        _buildVerticalRow(
                            'Filled At', (row) => row['Filled At'].toString()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                      onPressed: () {},
                      child: const Text("Invest in this Strategy"))
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildVerticalRow(
      String label, String Function(Map<String, dynamic>) valueGetter) {
    return DataRow(
      cells: [
        DataCell(Text(label)),
        ..._tableData.map(
          (row) => DataCell(Text(valueGetter(row))),
        ),
      ],
    );
  }

  Future<void> _getEmailAndFetchWatchlist() async {
    String? email = await _secureStorage.read(key: 'email');
    await Provider.of<WatchlistProvider>(context, listen: false)
        .fetchWatchlist(email!);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getEmailAndFetchWatchlist();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<WatchlistProvider>(
        builder: (context, watchlistProvider, child) {
          if (watchlistProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (watchlistProvider.watchlist.isEmpty) {
            return const Center(child: Text("No watchlists available"));
          }

          return ListView.builder(
            itemCount: watchlistProvider.watchlist.length,
            itemBuilder: (context, index) {
              final watchlist = watchlistProvider.watchlist[index];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: ListTile(
                  title: Text(watchlist.name),
                  subtitle: Text(watchlist.originalCreator),
                  trailing: SizedBox(
                    width: 100,
                    child: Row(
                      children: [
                        IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () {
                              chart();
                            }),
                        IconButton(
                            icon: const Icon(Icons.delete), onPressed: () {}),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),

      //   body: isLoading
      //       ? const Center(child: CircularProgressIndicator())
      //       : Padding(
      //           padding: const EdgeInsets.all(16),
      //           child: Column(
      //             children: [

      //               isLoading
      //                   ? const Center(
      //                       child: CircularProgressIndicator(),
      //                     )
      //                   : ListView.builder(
      //                       shrinkWrap: true,
      //                       itemCount: watchlist.length,
      //                       itemBuilder: (context, index) {
      //                         final item = watchlist[index];
      //                         return ListTile(
      //                           contentPadding: const EdgeInsets.all(0),
      //                           title: Text(item['name']),
      //                           subtitle: Text('Creator: ${item['creator']}'),
      //                           trailing: SizedBox(
      //                             width: 100,
      //                             child: Row(
      //                               children: [
      //                                 IconButton(
      //                                     icon: const Icon(Icons.visibility),
      //                                     onPressed: () {
      //                                       chart();
      //                                     }),
      //                                 IconButton(
      //                                   icon: const Icon(Icons.delete),
      //                                   onPressed: () =>
      //                                       _removeFromWatchlist(index),
      //                                 ),
      //                               ],
      //                             ),
      //                           ),
      //                         );
      //                       },
      //                     )
      //             ],
      //           ),
      //         ),
    );
  }
}
