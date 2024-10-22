import 'dart:convert';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/api_provider.dart';
import 'package:flutter_application_1/provider/watchlist_provider.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http; // Imported for HTTP requests

import '../api_handler/apis/demoapi.dart';
import '../provider/coinbase_provider.dart';
import '../provider/stock_chart_provider.dart';

class WatchlistScreen extends StatefulWidget {
  @override
  _WatchlistScreenState createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  bool isLoading = true;
  List<Map<String, dynamic>> watchlist = [];
  late CoinbaseProvider coinbaseProvider;
  late WatchlistProvider watchlistProvider;
  String originalStrategyId = '';
  String originalCreatorId = '';
  String errorMessage = '';
  String alpacaAccessToken = '';
  double alpacaBuyingPower = 0.0;
  String clientId = '6c237ee966f7c0ace2c5cf65293b4d61';
  String clientSecret = '25e5e97c680d303fcec2fb9cea33a03a713df133';
  bool isPaperAccount = false;

  String redirectUri = 'http://www.tradergpt.co/oauth/callback';

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
                      onPressed: () {
                        _showDeployModal();
                      },
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      coinbaseProvider = Provider.of<CoinbaseProvider>(context, listen: false);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      watchlistProvider = Provider.of<WatchlistProvider>(context, listen: false);
    });
  }

  // {{ edit_6 }} Added method to initiate Alpaca OAuth
  void _initiateAlpacaOAuth(bool isPaper) async {
    final state = _generateRandomState();
    final authUrl =
        'https://app.alpaca.markets/oauth/authorize?response_type=code&client_id=$clientId&redirect_uri=${Uri.encodeComponent(redirectUri)}&state=$state&scope=account:write%20trading';

    // Initialize WebViewController
    final WebViewController webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith(redirectUri)) {
              final uri = Uri.parse(request.url);
              final code = uri.queryParameters['code'];
              final returnedState = uri.queryParameters['state'];

              if (returnedState == state && code != null) {
                _exchangeCodeForToken(code, isPaper);
              }

              Navigator.of(context).pop(); // Close WebView
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(authUrl));

    // Open WebView for OAuth
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Connect to Alpaca')),
        body: WebViewWidget(
            controller:
                webViewController), // {{ edit_new }} Use WebViewWidget with the initialized controller
      ),
    ));
  }

// {{ edit_7 }} Added method to exchange authorization code for access token
  Future<void> _exchangeCodeForToken(String code, bool isPaper) async {
    final tokenUrl =
        'https://api.alpaca.markets/oauth/token'; // {{ edit_new }} Ensure this points to your backend's token exchange endpoint

    try {
      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'client_id': clientId,
          'client_secret': clientSecret,
          'client_secret': clientSecret,
          'redirect_uri': redirectUri,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          alpacaAccessToken = data['access_token'];
          isPaperAccount = isPaper; // {{ edit_30 }} Set the account type
        });
        _fetchAlpacaBuyingPower();
      } else {
        // Handle error response
        print('Error exchanging code: ${response.body}');
        setState(() {
          errorMessage = 'Failed to connect to Alpaca. Please try again.';
        });
      }
    } catch (e) {
      print('Exception during token exchange: $e');
      setState(() {
        errorMessage = 'An error occurred while connecting to Alpaca.';
      });
    }
  }

  Future<void> _fetchAlpacaBuyingPower() async {
    final accountUrl = isPaperAccount
        ? 'https://paper-api.alpaca.markets/v2/account'
        : 'https://api.alpaca.markets/v2/account';

    try {
      final response = await http.get(
        Uri.parse(accountUrl),
        headers: {
          'Authorization': 'Bearer $alpacaAccessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          alpacaBuyingPower = double.parse(data['buying_power']);
        });
      } else {
        // Handle error response
        print('Error fetching buying power: ${response.body}');
        setState(() {
          errorMessage =
              'Failed to load buying power. Please check your account status.';
        });
      }
    } catch (e) {
      print('Exception during fetching buying power: $e');
      setState(() {
        errorMessage = 'An error occurred while fetching buying power.';
      });
    }
  }

  String _generateRandomState() {
    final rand = Random.secure();
    final values = List<int>.generate(16, (i) => rand.nextInt(256));
    return base64Url.encode(values);
  }

  Future<void> _showDeployModal() async {
    // {{ edit_move_connectBrokerage_outside }}
    // Initialize connectBrokerage outside the StatefulBuilder to preserve its state
    String connectBrokerage = '';

    return showDialog(
      context: context,
      builder: (context) {
        // Move these variables outside of StatefulBuilder to persist between state updates
        final _formKey = GlobalKey<FormState>();
        final TextEditingController strategyNameController =
            TextEditingController();
        final TextEditingController fundingAmountController =
            TextEditingController();

        String frequency = 'Hourly';
        String deploymentEnvironment = 'Alpaca Paper'; // Initialize here
        bool shareWithCommunity = true;
        bool selfImprove = true;
        bool isDeploying = false;


        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              backgroundColor: Colors.grey[800],
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(Icons.close, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Deploy Trading Bot',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      // Buying Power Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15.0),
                        decoration: BoxDecoration(
                          color: Colors.green[700],
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: Text(
                          alpacaAccessToken.isNotEmpty
                              ? 'Buying Power: \$${alpacaBuyingPower.toStringAsFixed(2)}'
                              : coinbaseProvider.accessToken.isNotEmpty
                                  ? 'Buying Power: \$${coinbaseProvider.coinbaseBalance}'
                                  : 'Buying Power: \$0',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Form Section
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: strategyNameController,
                              decoration: const InputDecoration(
                                labelText: 'Strategy Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a strategy name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            // Frequency Dropdown
                            DropdownButtonFormField<String>(
                              value: frequency,
                              decoration: const InputDecoration(
                                labelText: 'Frequency',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                'Hourly',
                                'Daily',
                                'Weekly',
                                'Monthly',
                                'Quarterly',
                                'yearly'
                              ]
                                  .map((freq) => DropdownMenuItem(
                                        value: freq,
                                        child: Text(freq),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                setStateDialog(() {
                                  frequency = val!;
                                });
                              },
                            ),
                            const SizedBox(height: 15),
                            // Funding Amount Field
                            TextFormField(
                              controller: fundingAmountController,
                              decoration: const InputDecoration(
                                labelText: 'Funding Amount (\$)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a funding amount';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            // Deployment Environment Dropdown
                            DropdownButtonFormField<String>(
                              value: deploymentEnvironment,
                              decoration: const InputDecoration(
                                labelText: 'Deployment Environment',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                'Alpaca Paper', // Show Alpaca Paper only if Alpaca Live is not connected
                                'Alpaca Live', // Show Alpaca Live if connected
                                'Coinbase', // Show Coinbase
                              ]
                                  .map((env) => DropdownMenuItem(
                                        value: env,
                                        child: Text(env),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                setStateDialog(() {
                                  deploymentEnvironment = val!;

                                  if (deploymentEnvironment == 'Alpaca Live') {
                                    _initiateAlpacaOAuth(false);
                                  } else if (deploymentEnvironment ==
                                      'Alpaca Paper') {
                                    _initiateAlpacaOAuth(true);
                                  } else if (deploymentEnvironment ==
                                      'Coinbase') {
                                    if (coinbaseProvider.coinbaseStatus ==
                                        'Connected') {
                                      () async {
                                        await coinbaseProvider
                                            .getCoinbaseWalletBalance();
                                        setStateDialog(() {});
                                      }();
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Scaffold(
                                            appBar: AppBar(
                                                title: const Text("Coinbase")),
                                            body: WebViewWidget(
                                              controller: WebViewController()
                                                ..setJavaScriptMode(
                                                    JavaScriptMode.unrestricted)
                                                ..setNavigationDelegate(
                                                  NavigationDelegate(
                                                    onNavigationRequest:
                                                        (request) async {
                                                      if (request.url.contains(
                                                          coinbaseProvider
                                                              .redirectUri)) {
                                                        final Uri uri =
                                                            Uri.parse(
                                                                request.url);
                                                        final String? code =
                                                            uri.queryParameters[
                                                                'code'];
                                                        if (code != null) {
                                                          await coinbaseProvider
                                                              .fetchAccessToken(
                                                                  code);
                                                          await coinbaseProvider
                                                              .getCoinbaseWalletBalance();
                                                          setStateDialog(() {});
                                                          Navigator.pop(
                                                              context);
                                                        }
                                                        return NavigationDecision
                                                            .prevent;
                                                      }
                                                      return NavigationDecision
                                                          .navigate;
                                                    },
                                                  ),
                                                )
                                                ..loadRequest(Uri.parse(
                                                    coinbaseProvider
                                                        .buildOAuthUrl)),
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a deployment option';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            // Share with Community
                            Row(
                              children: [
                                Checkbox(
                                  value: shareWithCommunity,
                                  onChanged: (val) {
                                    setStateDialog(() {
                                      shareWithCommunity = val!;
                                    });
                                  },
                                ),
                                const Text('Share with Community'),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Self-Improve Checkbox
                            Row(
                              children: [
                                Checkbox(
                                  value: selfImprove,
                                  onChanged: (val) {
                                    setStateDialog(() {
                                      selfImprove = val!;
                                    });
                                  },
                                ),
                                const Text('Self-Improve'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Deploy Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: isDeploying
                                ? null
                                : ()async{
                                    if (_formKey.currentState!.validate()) {
                                     /* setStateDialog(() {
                                        isDeploying = true;
                                      });*/
                                      String? userId = await _secureStorage.read(key: 'email');

                                      print('userId $userId');
                                      print('originalCreatorId $originalCreatorId');
                                      print('originalStrategyId $originalStrategyId');
                                      int selfImproveInt = selfImprove ? 1 : 0;
                                      int shareWithCommunityInt = shareWithCommunity ? 1 : 0;

                                      print('selfImprove as int: $selfImproveInt');
                                      print('shareWithCommunity as int: $shareWithCommunityInt');
                                      print('deploymentEnvironment: $deploymentEnvironment');
                                      print('frequency: $frequency');
                                      print('strategyNameController: ${strategyNameController.text}');
                                      print('fundingAmountController: ${fundingAmountController.text}');
                                      String fundingAmountText = fundingAmountController.text;

                                      int? fundingAmount = int.tryParse(fundingAmountText);
                                      if (fundingAmount != null) {
                                        print('Funding Amount as int: $fundingAmount');
                                      } else {
                                        print('Error: Invalid number format');
                                      }

                                      ApiProvider().deployWatchlist(context: context, userId: userId!, selectedEnvironment: deploymentEnvironment, strategyName: strategyNameController.text, frequency: frequency, fundingAmount: fundingAmount!, shareWithCommunity: shareWithCommunityInt, selfImprove: selfImproveInt, originalCreatorId: originalCreatorId, originalStrategyId: originalStrategyId);
                                      /*Future.delayed(const Duration(seconds: 2),
                                          () {
                                        setStateDialog(() {
                                          //isDeploying = false;
                                        });
                                        Navigator.of(context).pop();
                                      });*/
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Deploy'),
                          ),
                        ],
                      ),
                      if (isDeploying)
                        const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
                              originalStrategyId = watchlist.id;
                              originalCreatorId = watchlist.originalCreator;
                              print('originalStrategyId abc $originalStrategyId');
                              print('originalCreatorId abc $originalCreatorId');
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
    );
  }
}
