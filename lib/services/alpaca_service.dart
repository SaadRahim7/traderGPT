import 'package:http/http.dart' as http;
import 'dart:convert';

class AlpacaService {
  final String clientId;
  final String clientSecret;
  final String redirectUri;

  AlpacaService({
    required this.clientId,
    required this.clientSecret,
    required this.redirectUri,
  });

  Future<String?> exchangeCodeForToken(String code) async {
    final tokenUrl = 'https://api.alpaca.markets/oauth/token';

    try {
      final response = await http.post(
        Uri.parse(tokenUrl),
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
        return data['access_token'];
      } else {
        print('Error exchanging code: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception during token exchange: $e');
      return null;
    }
  }

  Future<double?> fetchBuyingPower(String accessToken) async {
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
        return double.parse(data['buying_power']);
      } else {
        print('Error fetching buying power: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception during fetching buying power: $e');
      return null;
    }
  }
}