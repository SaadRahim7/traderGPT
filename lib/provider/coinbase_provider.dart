// coinbase_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class CoinbaseProvider with ChangeNotifier {
  final String clientId = '08559d20-bbb7-4a28-9bfa-35486655c258';
  final String clientSecret = 'WOlvQA0uI.gYkLfoVca__5tvAQ';
  final String redirectUri = 'https://www.google.com';
  final String scopes = 'wallet:accounts:read';
  String accessToken = '';
  String refreshToken = '';
  String coinbaseStatus = 'Not Connected';
  String coinbaseBalance = '';
  bool isLoading = false;
  late String buildOAuthUrl =
      "https://www.coinbase.com/oauth/authorize?response_type=code&client_id=$clientId&redirect_uri=$redirectUri&scope=$scopes";

  var logger = Logger();
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  CoinbaseProvider() {
    _loadTokensAndStatus();
  }

  // Load access and refresh tokens and connection status on app start
  Future<void> _loadTokensAndStatus() async {
    isLoading = true;
    notifyListeners();

    accessToken = await secureStorage.read(key: 'accessToken') ?? '';
    refreshToken = await secureStorage.read(key: 'refreshToken') ?? '';

    String? coinbaseConnected =
        await secureStorage.read(key: 'coinbaseConnected');
    if (coinbaseConnected == 'true' && accessToken.isNotEmpty) {
      coinbaseStatus = 'Connected';
      await getCoinbaseWalletBalance();
    }

    isLoading = false;
    notifyListeners();
  }

  // Exchange authorization code for access and refresh tokens
  Future<void> fetchAccessToken(String code) async {
    const url = 'https://api.coinbase.com/oauth/token';

    final response = await http.post(
      Uri.parse(url),
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'client_id': clientId,
        'client_secret': clientSecret,
        'redirect_uri': redirectUri,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      accessToken = data['access_token'];
      refreshToken = data['refresh_token'];
      coinbaseStatus = 'Connected';

      // Store the access and refresh tokens securely
      await secureStorage.write(key: 'accessToken', value: accessToken);
      await secureStorage.write(key: 'refreshToken', value: refreshToken);

      // Store connection status
      await secureStorage.write(key: 'coinbaseConnected', value: 'true');
      notifyListeners();
    } else {
      print('Failed to get access token: ${response.body}');
    }
  }

  // Fetch Coinbase wallet balance using access token
  Future<void> getCoinbaseWalletBalance() async {
    logger.i(accessToken);
    if (accessToken.isEmpty) return;

    const url = 'https://api.coinbase.com/v2/accounts';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final accounts = data['data'];
      if (accounts.isNotEmpty) {
        final balance = accounts[0]['balance']['amount'];
        final currency = accounts[0]['balance']['currency'];
        coinbaseBalance = '$balance $currency';
      }
    } else if (response.statusCode == 401) {
      // Access token expired, try to refresh it
      await refreshAccessToken();
    } else {
      print('Failed to get wallet balance: ${response.body}');
    }

    notifyListeners();
  }

  // Future<void> getCoinbaseWalletBalance() async {
  //   if (accessToken.isEmpty) return;

  //   final url = 'https://api.coinbase.com/v2/accounts';

  //   final response = await http.get(
  //     Uri.parse(url),
  //     headers: {
  //       'Authorization': 'Bearer $accessToken',
  //     },
  //   );

  //   if (response.statusCode == 200) {
  //     final data = jsonDecode(response.body);
  //     final accounts = data['data'];

  //     if (accounts.isNotEmpty) {
  //       // Find the USDT account
  //       final usdtAccount = accounts.firstWhere(
  //         (account) => account['currency']['code'] == 'USDT',
  //         orElse: () => null,
  //       );

  //       if (usdtAccount != null) {
  //         final balance = usdtAccount['balance']['amount'];
  //         final currency = usdtAccount['balance']['currency'];
  //         coinbaseBalance = '$balance $currency';
  //       } else {
  //         coinbaseBalance = 'No USDT balance found';
  //       }
  //     }
  //   } else if (response.statusCode == 401) {
  //     // Access token expired, try to refresh it
  //     await refreshAccessToken();
  //   } else {
  //     print('Failed to get wallet balance: ${response.body}');
  //   }

  //   notifyListeners();
  // }

  // Refresh the access token using the refresh token
  Future<void> refreshAccessToken() async {
    if (refreshToken.isEmpty) return;

    const url = 'https://api.coinbase.com/oauth/token';

    final response = await http.post(
      Uri.parse(url),
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': clientId,
        'client_secret': clientSecret,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      accessToken = data['access_token'];
      refreshToken = data['refresh_token'];

      await secureStorage.write(key: 'accessToken', value: accessToken);
      await secureStorage.write(key: 'refreshToken', value: refreshToken);

      await getCoinbaseWalletBalance();
    } else {
      print('Failed to refresh access token: ${response.body}');
    }

    notifyListeners();
  }

  // Function to reset data (if needed, for logout or disconnect)
  Future<void> resetCoinbaseConnection() async {
    await secureStorage.delete(key: 'accessToken');
    await secureStorage.delete(key: 'refreshToken');
    await secureStorage.delete(key: 'coinbaseConnected');
    accessToken = '';
    refreshToken = '';
    coinbaseStatus = 'Not Connected';
    coinbaseBalance = '';
    notifyListeners();
  }
}
