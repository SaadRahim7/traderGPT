import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/community_strategies_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

class CommunityScreen extends StatefulWidget {
  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
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
      final provider =
          Provider.of<CommunityStrategiesProvider>(context, listen: false);
      if (!provider.isLoading && provider.hasMore) {
        _loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<CommunityStrategiesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.strategies.isEmpty) {
            return Center(child: CircularProgressIndicator());
          } else if (provider.errorMessage.isNotEmpty) {
            return Center(child: Text('Error: ${provider.errorMessage}'));
          } else if (provider.strategies.isEmpty) {
            return Center(child: Text('No strategies available'));
          } else {
            return ListView.builder(
              controller: _scrollController,
              itemCount:
                  provider.strategies.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.strategies.length) {
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
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Annual Return ${strategy.annualizedReturn}"),
                            Text("Sharpe Ratio ${strategy.sharpeRatio}"),
                          ],
                        ),
                        SizedBox(height: 10),
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: ElevatedButton(
                            onPressed: () async {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Add to Watchlist'),
                          ),
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
