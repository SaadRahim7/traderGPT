import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/community_strategie_model.dart';
import 'package:flutter_application_1/model/order_model.dart';
import 'package:flutter_application_1/model/position_model.dart';
import 'package:flutter_application_1/model/profit_loss_model.dart';
import 'package:flutter_application_1/model/strategy_model.dart' as strat;
import 'package:flutter_application_1/model/watchlist_model.dart';
import 'package:http/http.dart';
import 'package:logger/logger.dart';

class ApiProvider with ChangeNotifier {
  var logger = Logger();

  Future<List<strat.Strategy>> getStrategy(String username) async {
    var queryParameters = {
      'user_id': username,
    };

    Request req =
        Request('GET', Uri.parse('https://www.tradergpt.co/api/strategies'))
          ..body = json.encode(queryParameters)
          ..headers.addAll({
            "Content-type": "application/json",
          });
    var response = await req.send();

    // Convert the streamed response to string
    var responseString = await response.stream.bytesToString();

    // Parse the string as JSON (if the response is in JSON format)
    var jsonData = jsonDecode(responseString);

    List<strat.Strategy> strategies = (jsonData['strategies'] as List)
        .map((strategy) => strat.Strategy.fromJson(strategy))
        .toList();

    // Do something with the jsonData
    logger.i(jsonData);

    return strategies;
  }

  Future<List<Watchlist>> getWatchlist(String username) async {
    var queryParameters = {
      'user_id': username,
    };

    Request req =
        Request('GET', Uri.parse('https://www.tradergpt.co/api/watchlist'))
          ..body = json.encode(queryParameters)
          ..headers.addAll({
            "Content-type": "application/json",
          });
    var response = await req.send();

    // Convert the streamed response to string
    var responseString = await response.stream.bytesToString();

    // Parse the string as JSON (if the response is in JSON format)
    final List<dynamic> jsonData = jsonDecode(responseString);
    List<Watchlist> watchlist =
        jsonData.map<Watchlist>((json) => Watchlist.fromJson(json)).toList();

    // Do something with the jsonData
    logger.i(jsonData);

    return watchlist;
  }

  // Future<List<ProfitLoss>> profitloss(String username, String mode) async {
  //   var queryParameters = {
  //     'user_id': username,
  //     'selected_environment': mode,
  //   };

  //   Request req = Request(
  //       'GET', Uri.parse('https://www.tradergpt.co/api/profit_and_loss'))
  //     ..body = json.encode(queryParameters)
  //     ..headers.addAll({
  //       "Content-type": "application/json",
  //     });
  //   var response = await req.send();

  //   // Convert the streamed response to string
  //   var responseString = await response.stream.bytesToString();

  //   // Parse the string as JSON (if the response is in JSON format)
  //   final List<dynamic> jsonData = jsonDecode(responseString);
  //   List<ProfitLoss> profitloss =
  //       jsonData.map<ProfitLoss>((json) => ProfitLoss.fromJson(json)).toList();

  //   // Do something with the jsonData
  //   logger.i(jsonData);

  //   return profitloss;
  // }

  Future<List<Order>> getOrders(String username, String mode) async {
    var queryParameters = {
      'user_id': username,
      'selected_environment': mode,
    };

    Request req =
        Request('GET', Uri.parse('https://www.tradergpt.co/api/orders'))
          ..body = json.encode(queryParameters)
          ..headers.addAll({
            "Content-type": "application/json",
          });
    var response = await req.send();

    // Convert the streamed response to string
    var responseString = await response.stream.bytesToString();

    final List<dynamic> jsonData = jsonDecode(responseString);
    List<Order> order =
        jsonData.map<Order>((json) => Order.fromJson(json)).toList();

    // Do something with the jsonData
    logger.i(jsonData);

    return order;
  }

  Future<PositionsResponse> getPositions(String username, String mode) async {
    var queryParameters = {
      'user_id': username,
      'selected_environment': mode,
    };

    Request req =
        Request('GET', Uri.parse('https://www.tradergpt.co/api/positions'))
          ..body = json.encode(queryParameters)
          ..headers.addAll({
            "Content-type": "application/json",
          });
    var response = await req.send();

    // Convert the streamed response to string
    var responseString = await response.stream.bytesToString();

    final Map<String, dynamic> jsonData = jsonDecode(responseString);

    PositionsResponse positionResponse = PositionsResponse.fromJson(jsonData);

    logger.i(jsonData);

    return positionResponse;
  }

  Future<Map<String, dynamic>> getStrategyMetrics(String userId, String strategyId) async {
    var body = jsonEncode({
      "user_id": userId,
      "strategy_id": strategyId,
    });

    Request req = Request('GET', Uri.parse('https://www.tradergpt.co/api/strategy/metrics'))
      ..body = body
      ..headers.addAll({
        "Content-type": "application/json",
      });

    var response = await req.send();

    // Convert the streamed response to string
    var responseString = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(responseString);
      logger.i(jsonData); // Log the successful response
      return jsonData; // Return the parsed JSON data
    } else {
      logger.e("Failed to fetch strategy metrics: ${response.statusCode}");
      return {}; // Return an empty map or handle errors as needed
    }
  }

  Future<CommunityStrategies> getCommunityStrategies(
      String username, String page) async {
    var queryParameters = {
      'user_id': username,
      'page': page,
    };

    Request req = Request(
        'GET', Uri.parse('https://www.tradergpt.co/api/community/strategies'))
      ..body = json.encode(queryParameters)
      ..headers.addAll({
        "Content-type": "application/json",
      });
    var response = await req.send();

    // Convert the streamed response to string
    var responseString = await response.stream.bytesToString();

    final Map<String, dynamic> jsonData = jsonDecode(responseString);

    CommunityStrategies communitystrategiesResponse =
        CommunityStrategies.fromJson(jsonData);

    logger.i(jsonData);

    return communitystrategiesResponse;
  }

  Future<bool> deleteStrategy(String userId, String strategyId) async {
    var body = jsonEncode({
      "user_id": userId,
      "strategy_id": strategyId,
    });

    Request req = Request('DELETE', Uri.parse('https://www.tradergpt.co/api/strategy'))
      ..body = body
      ..headers.addAll({
        "Content-type": "application/json",
      });

    var response = await req.send();

    // Convert the streamed response to string
    var responseString = await response.stream.bytesToString();

    // Parse the response
    var jsonData = jsonDecode(responseString);

    // Check if the deletion was successful
    if (response.statusCode == 200 && jsonData['success'] == true) {
      logger.i(jsonData['message']);
      return true;
    } else {
      logger.e("Failed to delete strategy: ${jsonData['message']}");
      return false;
    }
  }


  Future<bool> deleteWatchList(String userId, String strategyId) async {
    var body = jsonEncode({
      "user_id": userId,
      "strategy_id": strategyId,
    });

    Request req = Request('DELETE', Uri.parse('https://www.tradergpt.co/api/watchlist/strategy'))
      ..body = body
      ..headers.addAll({
        "Content-type": "application/json",
      });

    var response = await req.send();

    // Convert the streamed response to string
    var responseString = await response.stream.bytesToString();

    // Parse the response
    var jsonData = jsonDecode(responseString);

    // Check if the deletion was successful
    if (response.statusCode == 200 && jsonData['success'] == true) {
      logger.i(jsonData['message']);
      return true;
    } else {
      logger.e("Failed to delete strategy: ${jsonData['message']}");
      return false;
    }
  }

  Future<String> getstrategiecode(String username, String strategy) async {
    var queryParameters = {
      'user_id': username,
      'strategy_id': strategy,
    };

    Request req =
        Request('GET', Uri.parse('https://www.tradergpt.co/api/strategy/code'))
          ..body = json.encode(queryParameters)
          ..headers.addAll({
            "Content-type": "application/json",
          });
    var response = await req.send();

    // Convert the streamed response to string
    var responseString = await response.stream.bytesToString();

    logger.i(responseString);

    return responseString;
  }

  Future<ProfitLoss> getProfitLoss(String username, String mode) async {
    var queryParameters = {
      'user_id': username,
      'selected_environment': mode,
    };

    Request req = Request(
        'GET', Uri.parse('https://www.tradergpt.co/api/profit_and_loss'))
      ..body = json.encode(queryParameters)
      ..headers.addAll({
        "Content-type": "application/json",
      });
    var response = await req.send();

    // Convert the streamed response to string
    var responseString = await response.stream.bytesToString();

    final Map<String, dynamic> jsonData = jsonDecode(responseString);

    ProfitLoss data = ProfitLoss.fromJson(jsonData);

    logger.i(jsonData);

    return data;
  }

  Future<bool> addStrategyToWatchlist(String userId, String strategyId) async {
    var body = jsonEncode({
      "user_id": userId,
      "strategy_id": strategyId,
    });

    Request req = Request('POST', Uri.parse('https://www.tradergpt.co/api/watchlist/strategy'))
      ..body = body
      ..headers.addAll({
        "Content-type": "application/json",
      });

    var response = await req.send();

    // Convert the streamed response to string
    var responseString = await response.stream.bytesToString();

    // Parse the response
    var jsonData = jsonDecode(responseString);

    // Check if the addition was successful
    if (response.statusCode == 200 && jsonData['success'] == true) {
      logger.i(jsonData['message']);
      return true;
    } else {
      logger.e("Failed to add strategy to watchlist: ${jsonData['message']}");
      return false;
    }
  }
}
