import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/community_strategies_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

class CommunityScreen extends StatefulWidget {
  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> strategies = [];

  void _fetchCommunityStrategies() async {
    // TODO: Fetch strategies from your backend
    // For now, we'll use placeholder data
    await Future.delayed(Duration(seconds: 1)); // Simulate network delay

    setState(() {
      strategies = [
        {
          'name': 'Momentum Strategy',
          'creator': 'User123',
          'returns': '15%',
          'sharpe_ratio': '0.7'
        },
        {
          'name': 'Mean Reversion',
          'creator': 'TraderJoe',
          'returns': '8%',
          'sharpe_ratio': '0.4'
        },
        {
          'name': 'AI-Powered',
          'creator': 'DataGuru',
          'returns': '20%',
          'sharpe_ratio': '1.7'
        },
      ];
      isLoading = false;
    });
  }

  void _investInStrategy(Map<String, dynamic> strategy) {
    // TODO: Implement investment logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invested in ${strategy['name']}')),
    );
  }

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _getCommunityStrategies(); // Load the first page
    _scrollController.addListener(_scrollListener); // Listen for scroll events
  }

  Future<void> _getCommunityStrategies() async {
    String? email = await _secureStorage.read(key: 'email');
    await Provider.of<CommunityStrategiesProvider>(context, listen: false)
        .fetchCommunityStrategies(email!,
            isNextPage: false); // Load the first page
  }

  Future<void> _loadMore() async {
    String? email = await _secureStorage.read(key: 'email');
    await Provider.of<CommunityStrategiesProvider>(context, listen: false)
        .fetchCommunityStrategies(email!,
            isNextPage: true); // Load the next page
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // If scrolled to the bottom, load the next page
      final provider =
          Provider.of<CommunityStrategiesProvider>(context, listen: false);
      if (!provider.isLoading && provider.hasMore) {
        _loadMore();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Future<void> _getCommunityStrategies() async {
  //   String? email = await _secureStorage.read(key: 'email');
  //   await Provider.of<CommunityStrategiesProvider>(context, listen: false)
  //       .fetchCommunityStrategies(email!, '1');
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body: Consumer<CommunityStrategiesProvider>(
      //   builder: (context, provider, child) {
      //     if (provider.isLoading) {
      //       // Show loading spinner while data is loading
      //       return Center(child: CircularProgressIndicator());
      //     } else if (provider.errorMessage.isNotEmpty) {
      //       // Show error message if something went wrong
      //       return Center(child: Text('Error: ${provider.errorMessage}'));
      //     } else if (provider.strategies.isEmpty) {
      //       // Show message if no strategies are found
      //       return Center(child: Text('No strategies available'));
      //     } else {
      //       // Show the list of strategies
      //       return ListView.builder(
      //         itemCount: provider.strategies.length,
      //         itemBuilder: (context, index) {
      //           final strategy = provider.strategies[index];
      //           return Card(
      //             margin:
      //                 const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      //             child: ListTile(
      //               title: Text(strategy.userEmail),
      //               subtitle: Column(
      //                 crossAxisAlignment: CrossAxisAlignment.start,
      //                 children: [
      //                   Text(strategy.strategyId),
      //                   Row(
      //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //                     children: [
      //                       Text(
      //                         "Annual Return ${strategy.annualizedReturn}",
      //                       ),
      //                       Text(
      //                         "Sharpe Ration ${strategy.sharpeRatio}",
      //                       ),
      //                     ],
      //                   )
      //                 ],
      //               ),
      //             ),
      //           );
      //         },
      //       );
      //     }
      //   },
      // ),

      body: Consumer<CommunityStrategiesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.strategies.isEmpty) {
            // Show loading spinner for the first load
            return Center(child: CircularProgressIndicator());
          } else if (provider.errorMessage.isNotEmpty) {
            // Show error message if something went wrong
            return Center(child: Text('Error: ${provider.errorMessage}'));
          } else if (provider.strategies.isEmpty) {
            // Show message if no strategies are found
            return Center(child: Text('No strategies available'));
          } else {
            // Show the list of strategies
            return ListView.builder(
              controller: _scrollController, // Attach the scroll controller
              itemCount: provider.strategies.length +
                  (provider.hasMore
                      ? 1
                      : 0), // Add extra item for loading indicator
              itemBuilder: (context, index) {
                if (index == provider.strategies.length) {
                  // Show loading indicator at the bottom when fetching more data
                  return Center(child: CircularProgressIndicator());
                }

                final strategy = provider.strategies[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: ListTile(
                    title: Text(strategy.userEmail),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(strategy.strategyId),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Annual Return ${strategy.annualizedReturn}"),
                            Text("Sharpe Ratio ${strategy.sharpeRatio}"),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
