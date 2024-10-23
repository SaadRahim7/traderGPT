// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/watchlist_strategy_model.dart';
import 'package:flutter_application_1/provider/api_provider.dart';
import 'package:flutter_application_1/provider/watchlist_provider.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import '../provider/coinbase_provider.dart';
import '../provider/watchlist_strategy_provider.dart';
import '../widget/flushbar.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  _WatchlistScreenState createState() => _WatchlistScreenState();
}

const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

List<String> strategies = [];
Set<Color> usedColors = {};
String originalStrategyId = '';
String originalCreatorId = '';

Color getRandomUniqueColor() {
  Random random = Random();
  Color newColor;

  do {
    newColor = Color.fromARGB(255, (random.nextInt(5) * 51),
        (random.nextInt(5) * 51), (random.nextInt(5) * 51));
  } while (usedColors.contains(newColor));

  usedColors.add(newColor);
  return newColor;
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> watchlist = [];

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
                            onPressed: () async {
                              String? email =
                                  await _secureStorage.read(key: 'email');
                              originalStrategyId = watchlist.id;
                              originalCreatorId = watchlist.originalCreator;

                              showDialog(
                                context: context,
                                builder: (context) => StrategyChartDialog(
                                    email: email!,
                                    creatorid: originalCreatorId,
                                    strategyid: originalStrategyId),
                              );

                              if (strategies.length > 0) {
                                strategies.clear();
                              }
                              strategies.add('S&P500');
                              strategies.add('GPT Strategy');
                            }),
                        IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              watchlistProvider.deleteWatchList(
                                  context, watchlist.id);
                            }),
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

class StrategyChartDialog extends StatefulWidget {
  String email;
  String creatorid;
  String strategyid;
  StrategyChartDialog(
      {super.key,
      required this.email,
      required this.creatorid,
      required this.strategyid});

  @override
  State<StrategyChartDialog> createState() => _StrategyChartDialogState();
}

class _StrategyChartDialogState extends State<StrategyChartDialog> {
  late CoinbaseProvider coinbaseProvider;
  late WatchlistProvider watchlistProvider;
  String errorMessage = '';
  String alpacaAccessToken = '';
  double alpacaBuyingPower = 0.0;
  String clientId = '6c237ee966f7c0ace2c5cf65293b4d61';
  String clientSecret = '25e5e97c680d303fcec2fb9cea33a03a713df133';
  bool isPaperAccount = false;
  String redirectUri = 'http://www.tradergpt.co/oauth/callback';
  @override
  void initState() {
    super.initState();

    final provider =
        Provider.of<WatchlistStrategyProvider>(context, listen: false);
    provider.fetchWatchlist(widget.email, widget.creatorid, widget.strategyid);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      coinbaseProvider = Provider.of<CoinbaseProvider>(context, listen: false);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      watchlistProvider =
          Provider.of<WatchlistProvider>(context, listen: false);
    });
  }

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
    String connectBrokerage = '';
    String? userId = await _secureStorage.read(key: 'email');
    Size size = MediaQuery.of(context).size;

    return showDialog(
      context: context,
      builder: (context) {
        final _formKey = GlobalKey<FormState>();
        final TextEditingController strategyNameController =
            TextEditingController();
        final TextEditingController fundingAmountController =
            TextEditingController();

        String frequency = 'hourly';
        String deploymentEnvironment = 'paper';
        bool shareWithCommunity = true;
        bool selfImprove = true;
        bool isDeploying = false;
        bool _isLoading = false;

        double buyingPower = 0.0;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              insetPadding: const EdgeInsets.all(12),
              content: SizedBox(
                width: size.width * 0.8,
                height: size.height * 0.8,
                child: SingleChildScrollView(
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
                          'Buying Power: \$${buyingPower.toStringAsFixed(2)}',
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
                                'hourly',
                                'daily',
                                'weekly',
                                'monthly',
                                'quarterly',
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
                                if (value == null ||
                                    value.isEmpty ||
                                    value == 0) {
                                  return 'Please enter a funding amount';
                                }
                                if (double.tryParse(value) == null ||
                                    double.tryParse(value) == 0) {
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
                                'paper',
                                'live',
                                'coinbase',
                              ]
                                  .map((env) => DropdownMenuItem(
                                        value: env,
                                        child: Text(env),
                                      ))
                                  .toList(),
                              onChanged: (val) async {
                                setStateDialog(() {
                                  deploymentEnvironment = val!;
                                });

                                // Fetch buying power when dropdown value is selected
                                if (deploymentEnvironment != null) {
                                  double result = await ApiProvider()
                                      .buyingPower(
                                          userId!, deploymentEnvironment!);
                                  setStateDialog(() {
                                    buyingPower = result;
                                    print('buyingPower $buyingPower');
                                  });
                                }
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
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      setStateDialog(() {
                                        isDeploying =
                                            true; // Disable the button and show loader
                                      });

                                      int selfImproveInt = selfImprove ? 1 : 0;
                                      int shareWithCommunityInt =
                                          shareWithCommunity ? 1 : 0;

                                      String fundingAmountText =
                                          fundingAmountController.text;
                                      int? fundingAmount =
                                          int.tryParse(fundingAmountText);
                                      if (fundingAmount != null) {
                                        print(
                                            'Funding Amount as int: $fundingAmount');
                                      } else {
                                        print('Error: Invalid number format');
                                        setStateDialog(() {
                                          isDeploying =
                                              false; // Re-enable button in case of error
                                        });
                                        return; // Exit if invalid number
                                      }

                                      if (fundingAmount > buyingPower) {
                                        FlushBar.flushbarmessagegreen(
                                            message:
                                                "Your Buying Power is less then your funding Amount",
                                            context: context);
                                        setStateDialog(() {
                                          isDeploying =
                                              false; // Re-enable button after API call
                                        });
                                      } else {
                                        try {
                                          await ApiProvider().deployWatchlist(
                                            context: context,
                                            userId: userId!,
                                            selectedEnvironment:
                                                deploymentEnvironment,
                                            strategyName:
                                                strategyNameController.text,
                                            frequency: frequency,
                                            fundingAmount: fundingAmount,
                                            shareWithCommunity:
                                                shareWithCommunityInt,
                                            selfImprove: selfImproveInt,
                                            originalCreatorId:
                                                originalCreatorId,
                                            originalStrategyId:
                                                originalStrategyId,
                                          );

                                          Future.delayed(
                                              const Duration(seconds: 2), () {
                                            Navigator.of(context).pop();
                                            Navigator.of(context).pop();
                                          });
                                        } catch (error) {
                                          FlushBar.flushbarmessagegreen(
                                              message:
                                                  "Failed to deploy bot. Please try again.",
                                              context: context);
                                        } finally {
                                          setStateDialog(() {
                                            isDeploying = false;
                                          });
                                        }
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                            ),
                            child: isDeploying
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text('Deploy'),
                          ),
                        ],
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
    Size size = MediaQuery.of(context).size;
    final watchliststrategrProvider =
        Provider.of<WatchlistStrategyProvider>(context);
    return AlertDialog(
      insetPadding: const EdgeInsets.all(12),
      content: SizedBox(
        width: size.width * 0.8,
        height: size.height * 0.8,
        child: Consumer<WatchlistStrategyProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (provider.errorMessage != null) {
              return Text(provider.errorMessage!);
            } else if (provider.watchlistStrategy != null) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HighlightView(
                      provider.watchlistStrategy!.code,
                      language: 'python',
                      theme: darculaTheme,
                    ),
                    const SizedBox(height: 20),
                    watchliststrategrProvider
                                .watchlistStrategy!.interactiveData !=
                            null
                        ? LineChartWidget(
                            chartData: watchliststrategrProvider
                                .watchlistStrategy!.interactiveData)
                        : const Center(
                            child: Text('No data available'),
                          ),
                    const SizedBox(height: 20),
                    if (provider.watchlistStrategy!.metrics != null)
                      _buildMetricsTable(provider.watchlistStrategy!.metrics!),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: () {
                          _showDeployModal();
                        },
                        child: const Text("Invest in this Strategy"))
                  ],
                ),
              );
            } else {
              return const Center(child: Text('No data available'));
            }
          },
        ),
      ),
    );
  }

  Widget _buildMetricsTable(Metrics metrics) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: metrics.columns!
            .map((column) => DataColumn(label: Text(column)))
            .toList(),
        rows: metrics.data!
            .map((row) => DataRow(
                cells: row.map((cell) => DataCell(Text(cell))).toList()))
            .toList(),
      ),
    );
  }
}

class LineChartWidget extends StatefulWidget {
  final InteractiveData chartData;

  const LineChartWidget({super.key, required this.chartData});

  @override
  _LineChartWidgetState createState() => _LineChartWidgetState();
}

class _LineChartWidgetState extends State<LineChartWidget> {
  TextEditingController _symbolController = TextEditingController();
  String? _inputText = 'other';
  List color = [];

  void _updateText() {
    setState(() {
      _inputText = _symbolController.text;
    });
  }

  void _addStrategy() {
    if (_symbolController.text.isNotEmpty) {
      setState(() {
        strategies.add(_symbolController.text);
        _symbolController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final backtestProvider = Provider.of<WatchlistStrategyProvider>(context);
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
                  Provider.of<WatchlistStrategyProvider>(context, listen: false)
                      .fetchStrategyChartYahoo(email!, _symbolController.text,
                          widget.chartData.dates!);
                  _addStrategy();
                },
                child: const Text('Add Ticker'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        if (backtestProvider.watchlistStrategy != null)
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: strategies.length,
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: CustomText(
                        color: Colors.red,
                        title: strategies[index],
                      ),
                    )
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: 20),

        //chart
        SizedBox(
          height: size.height * 0.4,
          child: Consumer<WatchlistStrategyProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              List<LineChartBarData> lineBarsData = [];
              // provider.allDatas.forEach((element) {
              //   color.add(getRandomUniqueColor());
              //   Logger().i("color ${color}");
              //   lineBarsData.add(LineChartBarData(
              //     spots: element,
              //     isCurved: true,
              //     color: color[element.],
              //     barWidth: 2,
              //     belowBarData: BarAreaData(show: false),
              //     dotData: const FlDotData(show: false),
              //   ));
              // });

              for (int i = 0; i < provider.allDatas.length; i++) {
                var element = provider.allDatas[i];
                color.add(getRandomUniqueColor());

                lineBarsData.add(LineChartBarData(
                  spots: element,
                  isCurved: true,
                  color: color[i],
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

                            if (index <
                                provider.watchlistStrategy!.interactiveData
                                    .dates!.length) {
                              year = DateFormat('yyyy').format(DateTime.parse(
                                  provider.watchlistStrategy!.interactiveData
                                      .dates![index]));
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
