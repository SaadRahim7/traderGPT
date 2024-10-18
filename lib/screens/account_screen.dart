import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../provider/coinbase_provider.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final coinbaseProvider = Provider.of<CoinbaseProvider>(context);

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
                                  appBar: AppBar(
                                      title: const Text("Coinbase")),
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
