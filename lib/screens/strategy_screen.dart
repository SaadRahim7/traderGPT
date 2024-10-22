import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/api_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../provider/stock_chart_provider.dart';
import '../services/openai_service.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/dark.dart';
import 'package:fl_chart/fl_chart.dart'; // {{ edit_1 }} Imported fl_chart package
import 'package:http/http.dart' as http; // Imported for HTTP requests
import 'dart:convert'; // Imported for JSON decoding
import 'dart:math'; // {{ edit_23 }} Imported math library for rotation
import 'package:flutter/services.dart'; // {{ edit_25 }} Imported for input formatting
import 'package:webview_flutter/webview_flutter.dart'; // {{ edit_new }} Import updated webview_flutter package
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // {{ edit_6 }} Added flutter_secure_storage for secure token storage
import 'dart:io';

import '../widget/flushbar.dart'; // {{ edit_new }} Import dart:io for platform checks

class StrategyScreen extends StatefulWidget {
  @override
  _StrategyScreenState createState() => _StrategyScreenState();
}
Conversation? currentConversation;

class _StrategyScreenState extends State<StrategyScreen> {
  List<Conversation> conversations = [];
  //Conversation? currentConversation;
  TextEditingController messageController = TextEditingController();
  ScrollController scrollController = ScrollController();
  bool isLoading = false;
  String errorMessage = '';
  bool isAuthenticated = false;
  List<String> additionalTickers = [];
  TextEditingController tickerController = TextEditingController();
  String alpacaAccessToken = '';
  double alpacaBuyingPower = 0.0;
  String clientId = '6c237ee966f7c0ace2c5cf65293b4d61';
  String clientSecret = '25e5e97c680d303fcec2fb9cea33a03a713df133';
  String redirectUri = 'http://www.tradergpt.co/oauth/callback';
  bool isPaperAccount = false;

  final TextEditingController stockController = TextEditingController();
  String? selectedStock;
  double? selectedPrice;
  int? selectedYear;
  String? currentConversationId;
  String? selectedMessageId;


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

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    Provider.of<StockProvider>(context, listen: false).fetchInitialStockData();
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    tickerController.dispose();
    super.dispose();
  }

  void _checkAuthentication() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      isAuthenticated = user != null;
    });
    if (isAuthenticated) {
      _fetchConversations();
    }
  }

 /* void _fetchConversations() async {
    if (!isAuthenticated) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final conversationsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('conversations')
          .orderBy('created_at', descending: true)
          .get();

      setState(() {
        conversations = conversationsSnapshot.docs
            .map((doc) {
              final data = doc.data();
              final messages = (data['messages'] as List<dynamic>? ?? [])
                  .map((message) => ChatMessage(
                        text: message['content'] as String? ?? '',
                        isUser: message['role'] == 'user',
                      ))
                  .toList();

              // Skip conversations with no messages
              if (messages.isEmpty) {
                return null;
              }

              String title = data['summary'] as String? ??
                  (messages.isNotEmpty
                      ? messages.first.text
                      : 'New Conversation');

              return Conversation(
                id: doc.id,
                title: title,
                messages: messages,
              );
            })
            .whereType<Conversation>()
            .toList(); // Filter out null values

        if (conversations.isNotEmpty) {
          currentConversation = conversations.first;
        } else {
          currentConversation = null;
        }
      });
    } catch (e) {
      print('Error fetching conversations: $e');
      setState(() {
        errorMessage = 'Failed to load conversations. Please try again later.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }*/


  void _fetchConversations() async {
    if (!isAuthenticated) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final conversationsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('conversations')
          .orderBy('created_at', descending: true)
          .get();

      setState(() {
        conversations = conversationsSnapshot.docs
            .map((doc) {
          final data = doc.data();
          final messagesSnapshot = (data['messages'] as List<dynamic>? ?? []);

          final messages = messagesSnapshot
              .map((message) {
            // Check if the 'id' field exists
            final messageId = message.containsKey('id') ? message['id'] as String? : null;
            final content = message['content'] as String? ?? '';

            if (selectedMessageId == null && messageId != null) {
              selectedMessageId = messageId;
            }

            // Print verification results for each message
            if (messageId != null) {
              print('Message ID found: $messageId, Content: $content');
            } else {
              print('Message has no valid ID: $content');
            }

            return ChatMessage(
              id: messageId ?? '',
              text: content,
              isUser: message['role'] == 'user',
            );
          }).toList();

          // Skip conversations with no messages
          if (messages.isEmpty) {
            return null;
          }

          String title = data['summary'] as String? ??
              (messages.isNotEmpty
                  ? messages.first.text
                  : 'New Conversation');

          return Conversation(
            id: doc.id,
            title: title,
            messages: messages,
          );
        })
            .whereType<Conversation>()
            .toList(); // Filter out null values

        if (conversations.isNotEmpty) {
          currentConversation = conversations.first;
        } else {
          currentConversation = null;
        }

        print('Selected Message ID: $selectedMessageId'); // Use this ID as needed
      });
    } catch (e) {
      print('Error fetching conversations: $e');
      setState(() {
        errorMessage = 'Failed to load conversations. Please try again later.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  void _createNewConversation() async {
    if (!isAuthenticated) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final timestamp = DateTime.now().toIso8601String();

      final newConversationRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('conversations')
          .add({
        'messages': [],
        'created_at': timestamp,
        'summary': 'New Conversation',
      });

      // Don't add the new conversation to the local list yet
      // It will be added when the first message is sent

      setState(() {
        currentConversation = Conversation(
          id: newConversationRef.id,
          title: 'New Conversation',
          messages: [],
        );
      });
    } catch (e) {
      print('Error creating new conversation: $e');
      setState(() {
        errorMessage = 'Failed to create a new conversation. Please try again.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _sendMessage() async {
    if (!isAuthenticated ||
        messageController.text.trim().isEmpty ||
        currentConversation == null) return;

    final userMessage = messageController.text;
    setState(() {
      currentConversation!.messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
      ));
      isLoading = true;
      errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final openAiService = Provider.of<OpenAIService>(context, listen: false);
      final response = await openAiService.generateTradingStrategy(userMessage);

      setState(() {
        currentConversation!.messages.add(ChatMessage(
          text: response,
          isUser: false,
        ));

        // Add the conversation to the list if it's not already there
        if (!conversations.contains(currentConversation)) {
          conversations.insert(0, currentConversation!);
        }
      });

      final conversationRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('conversations')
          .doc(currentConversation!.id);

      final newMessages = [
        {
          'role': 'user',
          'content': userMessage,
        },
        {
          'role': 'assistant',
          'content': response,
        },
      ];

      final newSummary = _generateSummary(response);
      final timestamp = DateTime.now().toIso8601String();

      await conversationRef.set({
        'messages': FieldValue.arrayUnion(newMessages),
        'summary': newSummary,
        'created_at': timestamp,
      }, SetOptions(merge: true));

      setState(() {
        currentConversation!.title = newSummary;
      });

      messageController.clear();
      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
      setState(() {
        errorMessage = 'Failed to send message. Please try again.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _generateSummary(String response) {
    return response.length > 50 ? response.substring(0, 50) + '...' : response;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // {{ edit_33 }} Added method to calculate metrics
  Map<String, Map<String, dynamic>> _calculateMetrics(
      Map<String, List<FlSpot>> dataMap) {
    Map<String, Map<String, dynamic>> metrics = {};

    dataMap.forEach((ticker, spots) {
      if (spots.length >= 2) {
        double initialInvestment = 100000; // Example initial investment
        double finalValue = initialInvestment * (spots.last.y / spots.first.y);
        double annualizedReturn = 12.3; // Placeholder value
        double sharpeRatio = 0.7; // Placeholder value
        double stdDeviation = 20.3; // Placeholder value
        double maxDrawdown = 23.0; // Placeholder value

        metrics[ticker] = {
          'Initial Investment': initialInvestment,
          'Final Value': finalValue,
          'Annualized Return': annualizedReturn,
          'Sharpe Ratio': sharpeRatio,
          'Standard Deviation': stdDeviation,
          'Max Drawdown': maxDrawdown,
        };
      }
    });

    return metrics;
  }

  // {{ edit_34 }} Updated _showBacktestChart method to include metrics table
  Future<void> _showBacktestChart() async {
    // Initialize symbols with default tickers and any additionalTickers
    List<String> symbols = ['^GSPC', 'NVDA', ...additionalTickers];
    Map<String, List<FlSpot>?> dataMap = {};
    List<DateTime> dialogSortedDates = [];

    // Fetch historical data for all symbols
    for (String symbol in symbols) {
      dataMap[symbol] = await _fetchHistoricalData(symbol);
      if (dataMap[symbol] == null) {
        setState(() {
          errorMessage = 'Failed to load data for $symbol.';
        });
        return;
      }
    }

    // {{ edit_33 }} Calculate metrics
    Map<String, Map<String, dynamic>> metrics =
        _calculateMetrics(dataMap.map((key, value) => MapEntry(key, value!)));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // {{ edit_37 }} Define symbols inside the builder to ensure dynamic updates
            List<String> symbols = ['^GSPC', 'NVDA', ...additionalTickers];

            Widget legend = Wrap(
              spacing: 10,
              children: symbols.map((symbol) {
                Color color;
                switch (symbol) {
                  case '^GSPC':
                    color = Colors.blue;
                    break;
                  case 'NVDA':
                    color = Colors.green;
                    break;
                  default:
                    color = Colors
                        .orange; // {{ edit_30 }} Default color for additional tickers
                }
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      symbol,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                );
              }).toList(),
            );

            // {{ edit_35 }} Added metrics table
            Widget metricsTable = DataTable(
              columns: [
                const DataColumn(
                    label:
                        Text('Metric', style: TextStyle(color: Colors.white))),
                const DataColumn(
                    label: Text('Your Strategy',
                        style: TextStyle(color: Colors.white))),
                const DataColumn(
                    label:
                        Text('S&P 500', style: TextStyle(color: Colors.white))),
              ],
              rows: [
                DataRow(cells: [
                  const DataCell(Text('Initial Investment')),
                  DataCell(Text(
                      '\$${metrics['NVDA']?['Initial Investment']?.toStringAsFixed(2) ?? '-'}')),
                  DataCell(Text(
                      '\$${metrics['^GSPC']?['Initial Investment']?.toStringAsFixed(2) ?? '-'}')),
                ]),
                DataRow(cells: [
                  const DataCell(Text('Final Value')),
                  DataCell(Text(
                      '\$${metrics['NVDA']?['Final Value']?.toStringAsFixed(2) ?? '-'}')),
                  DataCell(Text(
                      '\$${metrics['^GSPC']?['Final Value']?.toStringAsFixed(2) ?? '-'}')),
                ]),
                DataRow(cells: [
                  const DataCell(Text('Annualized Return')),
                  DataCell(Text(
                      '${metrics['NVDA']?['Annualized Return']?.toStringAsFixed(2) ?? '-'}%')),
                  DataCell(Text(
                      '${metrics['^GSPC']?['Annualized Return']?.toStringAsFixed(2) ?? '-'}%')),
                ]),
                DataRow(cells: [
                  const DataCell(Text('Sharpe Ratio')),
                  DataCell(Text(
                      '${metrics['NVDA']?['Sharpe Ratio']?.toStringAsFixed(2) ?? '-'}')),
                  DataCell(Text(
                      '${metrics['^GSPC']?['Sharpe Ratio']?.toStringAsFixed(2) ?? '-'}')),
                ]),
                DataRow(cells: [
                  const DataCell(Text('Standard Deviation')),
                  DataCell(Text(
                      '${metrics['NVDA']?['Standard Deviation']?.toStringAsFixed(2) ?? '-'}%')),
                  DataCell(Text(
                      '${metrics['^GSPC']?['Standard Deviation']?.toStringAsFixed(2) ?? '-'}%')),
                ]),
                DataRow(cells: [
                  const DataCell(Text('Max Drawdown')),
                  DataCell(Text(
                      '${metrics['NVDA']?['Max Drawdown']?.toStringAsFixed(2) ?? '-'}%')),
                  DataCell(Text(
                      '${metrics['^GSPC']?['Max Drawdown']?.toStringAsFixed(2) ?? '-'}%')),
                ]),
              ],
            );

            return AlertDialog(
              title: const Text(
                'Backtest Results',
                style: TextStyle(
                    color: Colors
                        .white), // {{ edit_3 }} Set title text color to white
              ),
              backgroundColor: Colors
                  .grey[900], // {{ edit_4 }} Set dialog background to dark
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.maxFinite,
                      height: 300,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval:
                                500, // {{ edit_5 }} Set horizontal interval
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey[
                                    700], // {{ edit_6 }} Darker grid lines for contrast
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 500, // {{ edit_7 }} Adjusted interval
                                reservedSize:
                                    40, // {{ edit_8 }} Increased reserved size for labels
                                getTitlesWidget: (value, meta) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Text(
                                      '\$${value.toInt()}',
                                      style: const TextStyle(
                                        color: Colors
                                            .white, // {{ edit_9 }} Set y-axis labels to white
                                        fontSize:
                                            10, // {{ edit_10 }} Increased font size
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval:
                                    24, // {{ edit_11 }} Reduced interval for every 2 years
                                reservedSize:
                                    50, // {{ edit_12 }} Increased reserved size for bottom labels
                                getTitlesWidget: (value, meta) {
                                  int index = value.toInt();
                                  if (index < 0 ||
                                      index >= dialogSortedDates.length) {
                                    return const SizedBox.shrink();
                                  }
                                  DateTime date = dialogSortedDates[index];
                                  return Transform.rotate(
                                    angle: -pi /
                                        4, // {{ edit_24 }} Rotated label by -45 degrees
                                    child: Text(
                                      '${date.year}',
                                      style: const TextStyle(
                                        color: Colors
                                            .white, // {{ edit_13 }} Set x-axis labels to white
                                        fontSize:
                                            8, // {{ edit_14 }} Decreased font size
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: Colors.grey),
                          ),
                          minY: 0, // {{ edit_15 }} Set minimum Y value
                          maxY: _getMaxY(dataMap.values
                                  .where((data) => data != null)
                                  .expand((e) => e!)
                                  .toList()) +
                              500, // {{ edit_16 }} Dynamically set max Y
                          lineBarsData: dataMap.entries.map((entry) {
                            Color lineColor;
                            switch (entry.key) {
                              case '^GSPC':
                                lineColor = Colors.blue;
                                break;
                              case 'NVDA':
                                lineColor = Colors.green;
                                break;
                              default:
                                lineColor = Colors
                                    .orange; // {{ edit_30 }} Default color for additional tickers
                            }
                            return LineChartBarData(
                              spots: entry.value!,
                              isCurved: true,
                              color: lineColor,
                              barWidth: 2,
                              dotData: const FlDotData(show: false),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(
                        height:
                            8), // {{ edit_31 }} Spacer between chart and legend
                    legend, // {{ edit_31 }} Inserted legend here
                    const SizedBox(
                        height:
                            16), // {{ edit_32 }} Spacer between legend and metrics table
                    metricsTable, // {{ edit_35 }} Inserted metrics table here
                    const SizedBox(
                        height: 16), // Additional spacer before Invest button

                    // {{ edit_36 }} Added Invest button
                    ElevatedButton(
                      onPressed: _showDeployModal,
                      child: const Text('Invest'),
                    ),

                    const SizedBox(
                        height: 16), // Spacer between Invest button and input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: tickerController,
                            decoration: const InputDecoration(
                              hintText:
                                  'Enter additional stock ticker (e.g., AAPL)',
                              border: OutlineInputBorder(),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[A-Z]')),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            String ticker =
                                tickerController.text.trim().toUpperCase();
                            if (ticker.isNotEmpty &&
                                !additionalTickers.contains(ticker)) {
                              // Fetch data for the new ticker
                              List<FlSpot>? newData =
                                  await _fetchHistoricalData(ticker);
                              if (newData != null) {
                                setState(() {
                                  additionalTickers.add(ticker);
                                  dataMap[ticker] = newData;
                                  dialogSortedDates =
                                      dialogSortedDates; // Assuming dates are the same
                                });
                                setStateDialog(() {}); // Refresh the dialog
                              } else {
                                setState(() {
                                  errorMessage =
                                      'Failed to load data for $ticker.';
                                });
                              }
                              tickerController.clear();
                            }
                          },
                          child: const Text('Add Ticker'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text(
                    'Close',
                    style: TextStyle(
                        color: Colors
                            .white), // {{ edit_19 }} Set button text color to white
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // {{ edit_20 }} Added method to calculate maximum Y value
  double _getMaxY(List<FlSpot> data) {
    return data.isNotEmpty
        ? data.map((spot) => spot.y).reduce((a, b) => a > b ? a : b)
        : 0;
  }

  // {{ edit_21 }} Updated _fetchHistoricalData method using Yahoo Finance
  List<DateTime> _sortedDates = []; // {{ edit_22 }} Added sortedDates list

  Future<List<FlSpot>?> _fetchHistoricalData(String symbol) async {
    try {
      // Encode symbol for URL (handle symbols like ^GSPC)
      final encodedSymbol = Uri.encodeComponent(symbol);
      final url =
          'https://query1.finance.yahoo.com/v8/finance/chart/$encodedSymbol?range=10y&interval=1mo';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        print('Failed to fetch data for $symbol');
        return null;
      }

      final data = json.decode(response.body);
      final chart = data['chart'];
      if (chart == null || chart['result'] == null || chart['result'].isEmpty) {
        print('No chart data found for $symbol');
        return null;
      }

      final result = chart['result'][0];
      final timestamps = result['timestamp'] as List<dynamic>;
      final indicators = result['indicators']['adjclose'][0];
      final closePrices = indicators['adjclose'] as List<dynamic>;

      List<FlSpot> spots = [];
      _sortedDates = timestamps
          .map((ts) => DateTime.fromMillisecondsSinceEpoch(ts * 1000))
          .toList();
      for (int i = 0; i < closePrices.length; i++) {
        final price = closePrices[i];
        if (price == null) continue;
        spots.add(FlSpot(i.toDouble(), price));
      }

      return spots;
    } catch (e) {
      print('Error fetching historical data for $symbol: $e');
      return null;
    }
  }

  Future<void> chart(String messageId) async {
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
                        Navigator.of(context).pop();
                        _showDeployModal();
                      },
                      child: const Text("Deploy"))
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Strategy Chat'),
        actions: [
          if (isAuthenticated)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _createNewConversation,
            ),
        ],
      ),
      drawer: isAuthenticated
          ? Drawer(
            /*  child: ListView(
                children: [
                  DrawerHeader(
                    child: const Text('Conversations'),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  ...conversations
                      .map((conv) => ListTile(
                            title: Text(conv.title),
                            onTap: () {
                              setState(() {
                                currentConversation = conv;
                                currentConversationId = currentConversation!.id;
                                print('currentConversationId $currentConversationId');
                              });
                              Navigator.pop(context);
                            },
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteConversation(conv),
                            ),
                          ))
                      .toList(),
                ],
              ),*/
        child: ListView(
          children: [
            DrawerHeader(
              child: const Text('Conversations'),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ), ...conversations
        .map((conv) => ListTile(
      title: Text(conv.title),
              onTap: () {
                setState(() {
                  currentConversation = conv;
                  currentConversationId = currentConversation!.id;

                  // Filter out messages that have no valid id
                  final validMessages = conv.messages.where((message) => message.id!.isNotEmpty).toList();

                  // Check if there are valid messages
                  if (validMessages.isNotEmpty) {
                    for (var message in validMessages) {
                      print('Message ID: ${message.id}'); // Print each valid message ID
                    }
                    selectedMessageId = validMessages.first.id; // Set to the first valid message ID
                  } else {
                    selectedMessageId = null; // No valid message IDs found
                  }

                  print('currentConversationId: $currentConversationId');
                  print('First Selected Message ID: $selectedMessageId'); // Print the first valid message ID
                });

                Navigator.pop(context); // Close drawer or navigate back
              },


              trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _deleteConversation(conv),
      ),
    ))
        .toList(),

    ],
        ),

      )
          : null,
      body: !isAuthenticated
          ? Center(
              child: ElevatedButton(
                child: const Text('Login'),
                onPressed: () {
                  // Implement login logic here
                  // After successful login, call _checkAuthentication()
                },
              ),
            )
          : Column(
              children: [
                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Expanded(
                  child: currentConversation == null
                      ? const Center(child: Text('No conversation selected'))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: currentConversation!.messages.length,
                          itemBuilder: (context, index) {
                            return MessageBubble(
                              message: currentConversation!.messages[index],
                              showBacktest: chart,
                            );
                          },
                        ),
                ),
                if (isLoading) const LinearProgressIndicator(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          decoration: const InputDecoration(
                            hintText: 'Enter your strategy prompt...',
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Add the _deleteConversation method
  void _deleteConversation(Conversation conversation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content:
            const Text('Are you sure you want to delete this conversation?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('conversations')
          .doc(conversation.id)
          .delete();

      setState(() {
        conversations.remove(conversation);
        if (currentConversation == conversation) {
          currentConversation =
              conversations.isNotEmpty ? conversations.first : null;
        }
      });
    } catch (e) {
      print('Error deleting conversation: $e');
      setState(() {
        errorMessage = 'Failed to delete conversation. Please try again.';
      });
    }
  }

  // {{ edit_38 }} Added _showDeployModal function
  Future<void> _showDeployModal() async {
    // {{ edit_move_connectBrokerage_outside }}
    // Initialize connectBrokerage outside the StatefulBuilder to preserve its state
    String connectBrokerage = '';

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final _formKey = GlobalKey<FormState>();
            final TextEditingController strategyNameController =
                TextEditingController();
            final TextEditingController fundingAmountController =
                TextEditingController();

            String frequency = 'Hourly';
            String deploymentEnvironment = 'Live';
            bool shareWithCommunity = true;
            bool selfImprove = true;
            bool isDeploying = false;

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
                      // Close Button
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(Icons.close, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Title
                      const Text(
                        'Deploy Trading Bot',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      // Buying Power
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
                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Strategy Name
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
                            // Frequency
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
                                'Yearly',
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
                            // Funding Amount
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
                                'Live',
                                'Paper',
                                'Alpaca Live', // {{ edit_10a }} Added Alpaca Live option
                                'Alpaca Paper', // {{ edit_10b }} Added Alpaca Paper option
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
                            // Connect Brokerage
                            DropdownButtonFormField<String>(
                              value: connectBrokerage.isEmpty
                                  ? null
                                  : connectBrokerage, // Use the updated connectBrokerage
                              decoration: const InputDecoration(
                                labelText: 'Connect Brokerage',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                'Alpaca Live Account',
                                'Alpaca Paper Account',
                                'Coinbase Account',
                              ]
                                  .map((brokerage) => DropdownMenuItem(
                                        value: brokerage,
                                        child: Text(brokerage),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                setStateDialog(() {
                                  connectBrokerage = val ?? '';
                                });
                                if (val == 'Alpaca Live Account') {
                                  _initiateAlpacaOAuth(
                                      false); // isPaper = false
                                } else if (val == 'Alpaca Paper Account') {
                                  _initiateAlpacaOAuth(true); // isPaper = true
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a brokerage option';
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
                            // Self-Improve
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
                      // Buttons
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
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      // Handle deploy action
                                      print('Deploying strategy with options:');
                                      print(
                                          'Strategy Name: ${strategyNameController.text}');
                                      print('Frequency: $frequency');
                                      print(
                                          'Funding Amount: ${fundingAmountController.text}');
                                      print(
                                          'Deployment Environment: $deploymentEnvironment');
                                      print(
                                          'Connect Brokerage: $connectBrokerage');
                                      print(
                                          'Share with Community: $shareWithCommunity');
                                      print('Self-Improve: $selfImprove');

                                      setStateDialog(() {
                                        isDeploying = true;
                                      });

                                      // Simulate deployment delay
                                      Future.delayed(const Duration(seconds: 2),
                                          () {
                                        setStateDialog(() {
                                          isDeploying = false;
                                        });
                                        Navigator.of(context).pop();
                                        // Optionally show success message
                                        print('Deployment successful');
                                      });
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
                      const SizedBox(height: 20),
                      if (isDeploying)
                        const Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 10),
                            Text(
                              'Deploying your trading bot...',
                              style: TextStyle(color: Colors.black54),
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

  // {{ edit_31 }} Updated _fetchAlpacaBuyingPower to use the correct base URL
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

  // {{ edit_9 }} Added method to generate random state for OAuth security
  String _generateRandomState() {
    final rand = Random.secure();
    final values = List<int>.generate(16, (i) => rand.nextInt(256));
    return base64Url.encode(values);
  }
}

class Conversation {
  final String id;
  List<ChatMessage> messages;
  String title;

  Conversation(
      {required this.id, this.title = 'New Chat', List<ChatMessage>? messages})
      : messages = messages ?? [];
}

class ChatMessage {
  String? id;
  final String text;
  final bool isUser;

  ChatMessage({this.id, required this.text, required this.isUser});
}

class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final void Function(String messageId) showBacktest; // Accept messageId in callback

  MessageBubble({required this.message, required this.showBacktest});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment:
        widget.message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!widget.message.isUser) const CircleAvatar(child: Text('AI')),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: widget.message.isUser ? Colors.blue[800] : Colors.grey[800],
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding:
              const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
              child: widget.message.isUser
                  ? Text(
                widget.message.text,
                style: const TextStyle(color: Colors.white),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.message.text.split('```')[0],
                    style: const TextStyle(color: Colors.white),
                  ),
                  if (widget.message.text.contains('```'))
                    Container(
                      margin: const EdgeInsets.only(top: 8.0),
                      child: HighlightView(
                        widget.message.text.split('```')[1],
                        language: 'python',
                        theme: darkTheme,
                        padding: const EdgeInsets.all(8.0),
                        textStyle: const TextStyle(
                            fontSize: 12.0, color: Colors.white),
                      ),
                    ),
                  if (widget.message.text.contains('```'))
                    Column(
                      children: [
                        const SizedBox(height: 8.0),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            Colors.green, // Green background
                          ),
                          // Send the message ID when the button is pressed
                          onPressed: ()async{
                            if(widget.message.id == null || widget.message.id == ""){
                              FlushBar.flushbarmessagered(message: "There is no message id", context: context);
                            }else{
                              String? userId = await _secureStorage.read(key: 'email');

                              print('message.id! ${widget.message.id!}');
                              print('conversation_id ${currentConversation!.id}');
                              print('userId $userId');
                              ApiProvider().backTest(context: context, userId: userId!, conversationId: currentConversation!.id, messageId: widget.message.id!);
                             // showBacktest(message.id!);
                            }

                          },
                          child: const Text('Backtest'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (widget.message.isUser) const CircleAvatar(child: Text('You')),
        ],
      ),
    );
  }
}
