import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/account_provider.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../provider/coinbase_provider.dart';
import '../provider/strategy_provider.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final coinbaseProvider = Provider.of<CoinbaseProvider>(context);
    final strategyProvider = Provider.of<StrategyProvider>(context);
    final accountProvider = Provider.of<AccountProvider>(context);

    return coinbaseProvider.isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                ListTile(
                  title: const Text('Coinbase Account'),
                  subtitle: Text(coinbaseProvider.coinbaseStatus),
                  trailing: ElevatedButton(
                    onPressed: coinbaseProvider.coinbaseStatus == 'Connected'
                        ? () async {
                            await coinbaseProvider.resetCoinbaseConnection();
                          }
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Scaffold(
                                  appBar: AppBar(title: const Text("Coinbase")),
                                  body: WebViewWidget(
                                    controller: WebViewController()
                                      ..setJavaScriptMode(
                                          JavaScriptMode.unrestricted)
                                      ..setNavigationDelegate(
                                        NavigationDelegate(
                                          onNavigationRequest: (request) async {
                                            if (request.url.contains(
                                                coinbaseProvider.redirectUri)) {
                                              final Uri uri =
                                                  Uri.parse(request.url);
                                              final String? code =
                                                  uri.queryParameters['code'];
                                              if (code != null) {
                                                await coinbaseProvider
                                                    .fetchAccessToken(code);
                                                await coinbaseProvider
                                                    .getCoinbaseWalletBalance();
                                                Navigator.pop(context);
                                              }
                                              return NavigationDecision.prevent;
                                            }
                                            return NavigationDecision.navigate;
                                          },
                                        ),
                                      )
                                      ..loadRequest(
                                        Uri.parse(
                                          coinbaseProvider.buildOAuthUrl,
                                        ),
                                      ),
                                  ),
                                ),
                              ),
                            );
                          },
                    child: Text(coinbaseProvider.coinbaseStatus == 'Connected'
                        ? 'Connected'
                        : 'Connect'),
                  ),
                ),
                if (coinbaseProvider.coinbaseBalance.isNotEmpty)
                  ListTile(
                    title: const Text('Coinbase Balance'),
                    subtitle: Text(coinbaseProvider.coinbaseBalance),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    _deleteAccount(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Delete Account'),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.center,
                  child: Text("STRATEGY"),
                ),
                const SizedBox(height: 20),
                ListView.separated(
                  shrinkWrap: true,
                  itemCount: strategyProvider.strategies.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 8);
                  },
                  itemBuilder: (context, index) {
                    final currentStrategy = strategyProvider.strategies[index];
                    return Row(
                      children: [
                        Flexible(
                          child: Text(
                            "${currentStrategy.name} (${currentStrategy.id})",
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: (){
                            var isSuccess = accountProvider.deleteStrategy(context, currentStrategy.id);
                            if(isSuccess == true){

                              strategyProvider.fetchStrategies();
                            }
                          },
                          child: Text("Delete"),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
  }

  void _deleteAccount(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account deletion not implemented')),
    );
  }
}
