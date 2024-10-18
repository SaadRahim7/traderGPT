import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert' show base64Url;

class StrategyScreen extends StatefulWidget {
  @override
  _StrategyScreenState createState() => _StrategyScreenState();
}

class _StrategyScreenState extends State<StrategyScreen> {
  bool isAuthenticated = false;
  String errorMessage = '';
  double alpacaBuyingPower = 0.0;
  final String clientId = 'YOUR_CLIENT_ID';
  final String clientSecret = 'YOUR_CLIENT_SECRET';
  final String redirectUri = 'YOUR_REDIRECT_URI';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String alpacaLiveAccessToken = '';
  String alpacaPaperAccessToken = '';

  String selectedDeploymentEnvironment = 'live';

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _loadAlpacaAccessTokens();
  }

  Future<void> _loadAlpacaAccessTokens() async {
    if (!isAuthenticated) return;

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        setState(() {
          alpacaLiveAccessToken =
              userDoc.data()?['alpacaLiveAccessToken'] ?? '';
          alpacaPaperAccessToken =
              userDoc.data()?['alpacaPaperAccessToken'] ?? '';
        });
        _fetchAlpacaBuyingPower();
      }
    } catch (e) {
      print('Error loading Alpaca access tokens: $e');
      setState(() {
        errorMessage = 'Failed to load Alpaca tokens. Please try again.';
      });
    }
  }

  Future<void> _checkAuthentication() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      isAuthenticated = user != null;
    });
  }

  Future<void> _exchangeCodeForToken(String code, bool isPaper) async {
    final tokenUrl = 'https://api.alpaca.markets/oauth/token';

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
        String accessToken = data['access_token'];

        final user = FirebaseAuth.instance.currentUser!;
        await _firestore.collection('users').doc(user.uid).set({
          if (isPaper) 'alpacaPaperAccessToken': accessToken,
          if (!isPaper) 'alpacaLiveAccessToken': accessToken,
        }, SetOptions(merge: true));

        setState(() {
          if (isPaper) {
            alpacaPaperAccessToken = accessToken;
            selectedDeploymentEnvironment = 'paper';
          } else {
            alpacaLiveAccessToken = accessToken;
            selectedDeploymentEnvironment = 'live';
          }
        });
        _fetchAlpacaBuyingPower();
      } else {
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
    String? accessToken;
    if (selectedDeploymentEnvironment == 'live' &&
        alpacaLiveAccessToken.isNotEmpty) {
      accessToken = alpacaLiveAccessToken;
    } else if (selectedDeploymentEnvironment == 'paper' &&
        alpacaPaperAccessToken.isNotEmpty) {
      accessToken = alpacaPaperAccessToken;
    } else {
      setState(() {
        alpacaBuyingPower = 0.0;
      });
      return;
    }

    final accountUrl = 'https://api.alpaca.markets/v2/account';

    try {
      final response = await http.get(
        Uri.parse(accountUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          alpacaBuyingPower = double.parse(data['buying_power']);
        });
      } else {
        print('Error fetching buying power: ${response.body}');
        setState(() {
          alpacaBuyingPower = 0.0;
        });
      }
    } catch (e) {
      print('Exception during fetching buying power: $e');
      setState(() {
        alpacaBuyingPower = 0.0;
      });
    }
  }

  Future<void> _showDeployModal() async {
    showDialog(
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
            String connectBrokerage = '';
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
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Icon(Icons.close, color: Colors.grey),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Deploy Trading Bot',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(15.0),
                        decoration: BoxDecoration(
                          color: Colors.green[700],
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: Text(
                          (selectedDeploymentEnvironment == 'live' &&
                                      alpacaLiveAccessToken.isNotEmpty) ||
                                  (selectedDeploymentEnvironment == 'paper' &&
                                      alpacaPaperAccessToken.isNotEmpty)
                              ? 'Buying Power: \$${alpacaBuyingPower.toStringAsFixed(2)}'
                              : 'Buying Power: \$0',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: strategyNameController,
                              decoration: InputDecoration(
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
                            SizedBox(height: 15),
                            DropdownButtonFormField<String>(
                              value: frequency,
                              decoration: InputDecoration(
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
                            SizedBox(height: 15),
                            TextFormField(
                              controller: fundingAmountController,
                              decoration: InputDecoration(
                                labelText: 'Funding Amount (\$)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.numberWithOptions(
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
                            SizedBox(height: 15),
                            DropdownButtonFormField<String>(
                              value: selectedDeploymentEnvironment,
                              decoration: InputDecoration(
                                labelText: 'Deployment Environment',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'live',
                                  child: Text('Live'),
                                ),
                                DropdownMenuItem(
                                  value: 'paper',
                                  child: Text('Paper'),
                                ),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  selectedDeploymentEnvironment = val!;
                                  _fetchAlpacaBuyingPower();
                                });
                                setStateDialog(() {});
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a deployment environment';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 15),
                            DropdownButtonFormField<String>(
                              value: connectBrokerage.isEmpty
                                  ? null
                                  : connectBrokerage,
                              decoration: InputDecoration(
                                labelText: 'Connect Brokerage',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'alpacaLive',
                                  child: Text('Alpaca Live Account'),
                                ),
                                DropdownMenuItem(
                                  value: 'alpacaPaper',
                                  child: Text('Alpaca Paper Account'),
                                ),
                                DropdownMenuItem(
                                  value: 'coinbase',
                                  child: Text('Coinbase Account'),
                                ),
                              ],
                              onChanged: (val) {
                                switch (val) {
                                  case 'alpacaLive':
                                    _initiateAlpacaOAuth(false);
                                    break;
                                  case 'alpacaPaper':
                                    _initiateAlpacaOAuth(true);
                                    break;
                                  case 'coinbase':
                                    break;
                                  default:
                                    print('No option selected');
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a brokerage option';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 15),
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
                                Text('Share with Community'),
                              ],
                            ),
                            SizedBox(height: 10),
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
                                Text('Self-Improve'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black,
                            ),
                            child: Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: isDeploying
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      print('Deploying strategy with options:');
                                      print(
                                          'Strategy Name: ${strategyNameController.text}');
                                      print('Frequency: $frequency');
                                      print(
                                          'Funding Amount: ${fundingAmountController.text}');
                                      print(
                                          'Deployment Environment: $selectedDeploymentEnvironment');
                                      print(
                                          'Connect Brokerage: $connectBrokerage');
                                      print(
                                          'Share with Community: $shareWithCommunity');
                                      print('Self-Improve: $selfImprove');

                                      setStateDialog(() {
                                        isDeploying = true;
                                      });

                                      Future.delayed(Duration(seconds: 2), () {
                                        setStateDialog(() {
                                          isDeploying = false;
                                        });
                                        Navigator.of(context).pop();
                                        print('Deployment successful');
                                      });
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Deploy'),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      if (isDeploying)
                        Column(
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

  void _initiateAlpacaOAuth(bool isPaper) async {
    final state = _generateRandomState();
    final authUrl =
        'https://app.alpaca.markets/oauth/authorize?response_type=code&client_id=$clientId&redirect_uri=${Uri.encodeComponent(redirectUri)}&state=$state&scope=account:write%20trading';

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

              Navigator.of(context).pop();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(authUrl));

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text('Connect to Alpaca')),
        body: WebViewWidget(controller: webViewController),
      ),
    ));
  }

  String _generateRandomState() {
    final rand = Random.secure();
    final values = List<int>.generate(16, (i) => rand.nextInt(256));
    return base64Url.encode(values);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Strategy Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Buying Power: \$${alpacaBuyingPower.toStringAsFixed(2)}'),
            ElevatedButton(
              onPressed: _showDeployModal,
              child: Text('Deploy'),
            ),
          ],
        ),
      ),
    );
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
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback showBacktest;

  MessageBubble({required this.message, required this.showBacktest});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) CircleAvatar(child: Text('AI')),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: message.isUser ? Colors.blue[800] : Colors.grey[800],
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
              child: message.isUser
                  ? Text(
                      message.text,
                      style: TextStyle(color: Colors.white),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text.split('```')[0],
                          style: TextStyle(color: Colors.white),
                        ),
                        if (message.text.contains('```'))
                          Container(
                            margin: EdgeInsets.only(top: 8.0),
                            child: HighlightView(
                              message.text.split('```')[1],
                              language: 'python',
                              padding: EdgeInsets.all(8.0),
                              textStyle: TextStyle(
                                  fontSize: 12.0, color: Colors.white),
                            ),
                          ),
                        if (message.text.contains('```'))
                          Column(
                            children: [
                              SizedBox(height: 8.0),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: showBacktest,
                                child: Text('Backtest'),
                              ),
                            ],
                          ),
                      ],
                    ),
            ),
          ),
          if (message.isUser) CircleAvatar(child: Text('You')),
        ],
      ),
    );
  }
}
