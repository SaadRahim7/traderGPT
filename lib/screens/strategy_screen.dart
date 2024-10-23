import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/strategy_backtest_model.dart';
import 'package:flutter_application_1/provider/api_provider.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../provider/strategy_backtest_provider.dart';
import '../services/openai_service.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/dark.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widget/flushbar.dart';

class StrategyScreen extends StatefulWidget {
  @override
  _StrategyScreenState createState() => _StrategyScreenState();
}

const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
Conversation? currentConversation;
List<String> strategies = [];

class _StrategyScreenState extends State<StrategyScreen> {
  List<Conversation> conversations = [];

  //Conversation? currentConversation;
  TextEditingController messageController = TextEditingController();
  ScrollController scrollController = ScrollController();
  bool isLoading = false;
  String errorMessage = '';
  bool isAuthenticated = false;

  final TextEditingController stockController = TextEditingController();
  String? selectedStock;
  double? selectedPrice;
  int? selectedYear;
  String? currentConversationId;
  String? selectedMessageId;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
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
              final messagesSnapshot =
                  (data['messages'] as List<dynamic>? ?? []);

              final messages = messagesSnapshot.map((message) {
                // Check if the 'id' field exists
                final messageId =
                    message.containsKey('id') ? message['id'] as String? : null;
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

        print(
            'Selected Message ID: $selectedMessageId'); // Use this ID as needed
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
              child: ListView(
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
                                print(
                                    'currentConversationId $currentConversationId');
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
  // final void Function(String messageId)
  //     showBacktest;

  MessageBubble({
    required this.message,
    // required this.showBacktest
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isLoading = false; // Track the loading state

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: widget.message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!widget.message.isUser) const CircleAvatar(child: Text('AI')),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color:
                    widget.message.isUser ? Colors.blue[800] : Colors.grey[800],
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
                                  backgroundColor: _isLoading
                                      ? Colors.grey
                                      : Colors.green, // Green background
                                ),
                                onPressed: _isLoading
                                    ? null
                                    : () async {
                                        setState(() {
                                          _isLoading = true;
                                        });

                                        if (widget.message.id == null ||
                                            widget.message.id == "") {
                                          FlushBar.flushbarmessagered(
                                              message: "There is no message id",
                                              context: context);
                                        } else {
                                          String? userId = await _secureStorage
                                              .read(key: 'email');

                                          showDialog(
                                            context: context,
                                            builder: (context) =>
                                                StrategyChartDialog(
                                              userid: userId!,
                                              conversationid:
                                                  currentConversation!.id,
                                              messageid: widget.message.id!,
                                            ),
                                          );

                                          if (strategies.length > 0) {
                                            strategies.clear();
                                          }
                                          strategies.add('S&P500');
                                          strategies.add('GPT Strategy');
                                        }

                                        setState(() {
                                          _isLoading = false;
                                        });
                                      },
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ) // Show a loader while loading
                                    : const Text('Backtest'),
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

///////////////////////////////////////////////////////////////////////////////////////
class StrategyChartDialog extends StatefulWidget {
  String userid;
  String conversationid;
  String messageid;
  StrategyChartDialog(
      {super.key,
      required this.userid,
      required this.conversationid,
      required this.messageid});

  @override
  State<StrategyChartDialog> createState() => _StrategyChartDialogState();
}

class _StrategyChartDialogState extends State<StrategyChartDialog> {
  String errorMessage = '';
  bool isPaperAccount = false;
  @override
  void initState() {
    super.initState();

    final provider =
        Provider.of<StrategyBacktestProvider>(context, listen: false);
    provider.fetchInteractiveData(
        widget.userid, widget.conversationid, widget.messageid);
  }

  String _generateRandomState() {
    final rand = Random.secure();
    final values = List<int>.generate(16, (i) => rand.nextInt(256));
    return base64Url.encode(values);
  }

  Future<void> _showDeployModal(String strategyId) async {
    String? userId = await _secureStorage.read(key: 'email');
    Size size = MediaQuery.of(context).size;

    return showDialog(
      context: context,
      builder: (context) {
        // Move these variables outside of StatefulBuilder to persist between state updates
        final _formKey = GlobalKey<FormState>();
        final TextEditingController strategyNameController =
            TextEditingController();
        final TextEditingController fundingAmountController =
            TextEditingController();

        String frequency = 'hourly';
        String? deploymentEnvironment; // Initialize here
        bool shareWithCommunity = true;
        bool selfImprove = true;
        bool isDeploying = false;
        bool _isLoading = false; // Track the loading state

        double buyingPower = 0.0; // Holds the buying power value

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
                      const Text(
                        'Deploy Trading Bot',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

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
                                'paper', // Show Alpaca Paper only if Alpaca Live is not connected
                                'live', // Show Alpaca Live if connected
                                'coinbase', // Show Coinbase
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
                                          await ApiProvider()
                                              .conversationStrategyDeploy(
                                            context: context,
                                            userId: userId!,
                                            selectedEnvironment:
                                                deploymentEnvironment!,
                                            strategyName:
                                                strategyNameController.text,
                                            frequency: frequency,
                                            fundingAmount: fundingAmount,
                                            shareWithCommunity:
                                                shareWithCommunityInt,
                                            selfImprove: selfImproveInt,
                                            strategyId: strategyId,
                                          );

                                          // Close the dialog after a delay
                                          Future.delayed(Duration(seconds: 2),
                                              () {
                                            Navigator.of(context).pop();
                                            Navigator.of(context).pop();
                                          });
                                        } catch (error) {
                                          // Handle the error, e.g., show an error message

                                          FlushBar.flushbarmessagegreen(
                                              message:
                                                  "Failed to deploy bot. Please try again.",
                                              context: context);
                                        } finally {
                                          setStateDialog(() {
                                            isDeploying =
                                                false; // Re-enable button after API call
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
                                ? SizedBox(
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
    final strategyBacktestProvider =
        Provider.of<StrategyBacktestProvider>(context);
    return AlertDialog(
      insetPadding: const EdgeInsets.all(12),
      content: SizedBox(
        width: size.width * 0.8,
        height: size.height * 0.8,
        child: Consumer<StrategyBacktestProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (provider.errorMessage != null) {
              Logger().i(provider.errorMessage);
              return Center(child: Text(provider.errorMessage!));
            } else if (provider.data != null) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    strategyBacktestProvider.data! != null
                        ? LineChartWidget(
                            chartData: strategyBacktestProvider.data!)
                        : const Center(
                            child: Text('No data available'),
                          ),
                    const SizedBox(height: 20),
                    if (provider.data!.metrics != null)
                      _buildMetricsTable(provider.data!.metrics!),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: () {
                          _showDeployModal(
                              strategyBacktestProvider.data!.strategyId!);
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
          columns: const [
            DataColumn(label: Text('Metric')),
            DataColumn(label: Text('GPT Trader Strategy')),
            DataColumn(label: Text('S&P 500')),
          ],
          rows: [
            _createDataRow('Annualized Return', metrics.annualizedReturn),
            _createDataRow('Final Value', metrics.finalValue),
            _createDataRow('Initial Investment', metrics.initialInvestment),
            _createDataRow('Max Drawdown', metrics.maxDrawdown),
            _createDataRow('Sharpe Ratio', metrics.sharpeRatio),
            _createDataRow('Standard Deviation', metrics.standardDeviation),
          ],
        ));
  }
}

class LineChartWidget extends StatefulWidget {
  final StrategyBacktestModel chartData;

  const LineChartWidget({super.key, required this.chartData});

  @override
  _LineChartWidgetState createState() => _LineChartWidgetState();
}

class _LineChartWidgetState extends State<LineChartWidget> {
  TextEditingController _symbolController = TextEditingController();
  String? _inputText = 'other';
  List color = [];

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final backtestProvider = Provider.of<StrategyBacktestProvider>(context);
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
                  Provider.of<StrategyBacktestProvider>(context, listen: false)
                      .fetchStrategyChartYahoo(email!, _symbolController.text,
                          widget.chartData.dates!);
                  // _addStrategy();
                  _symbolController.clear();
                },
                child: const Text('Add Ticker'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        if (backtestProvider.data != null)
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
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: CustomText(
                        color: backtestProvider.allStrategiesColor[index],
                        title: backtestProvider.allStrategies[index],
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
          child: Consumer<StrategyBacktestProvider>(
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

                            if (index < provider.data!.dates!.length) {
                              year = DateFormat('yyyy').format(
                                  DateTime.parse(provider.data!.dates![index]));
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

DataRow _createDataRow(String metricName, MetricsDetail? detail) {
  return DataRow(cells: [
    DataCell(Text(metricName)),
    DataCell(Text(detail?.gptTraderStrategy ?? 'N/A')),
    DataCell(Text(detail?.sp500 ?? 'N/A')),
  ]);
}
