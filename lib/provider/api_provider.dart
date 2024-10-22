import 'dart:convert';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/community_strategie_model.dart';
import 'package:flutter_application_1/model/logs_model.dart';
import 'package:flutter_application_1/model/metric_model.dart';
import 'package:flutter_application_1/model/order_model.dart';
import 'package:flutter_application_1/model/position_model.dart';
import 'package:flutter_application_1/model/profit_loss_model.dart';
import 'package:flutter_application_1/model/strategy_model.dart' as strat;
import 'package:flutter_application_1/model/watchlist_model.dart';
import 'package:http/http.dart';
import 'package:logger/logger.dart';

import '../model/backtest_strategy_chart_model.dart';
import '../model/watchlist_strategy_model.dart';
import '../widget/flushbar.dart';

class ApiProvider with ChangeNotifier {
  var logger = Logger();
  String? strategyId;
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

    Request req =
        Request('DELETE', Uri.parse('https://www.tradergpt.co/api/strategy'))
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

    Request req = Request(
        'DELETE', Uri.parse('https://www.tradergpt.co/api/watchlist/strategy'))
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

    var jsonData = jsonDecode(responseString);

    logger.i(responseString);

    return jsonData;
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

    Request req = Request(
        'POST', Uri.parse('https://www.tradergpt.co/api/watchlist/strategy'))
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

  Future<bool> deployWatchlist({required BuildContext context,required String userId,required String selectedEnvironment,required  String strategyName,required String frequency,required int fundingAmount,required  int shareWithCommunity,required int selfImprove, required String originalCreatorId,required String originalStrategyId}) async {
    var body = jsonEncode({
      "user_id": userId,
      "selected_environment": selectedEnvironment,
      "strategy_name": strategyName,
      "frequency": frequency,
      "funding_amount": fundingAmount,
      "share_with_community": shareWithCommunity,
      "original_creator_id": originalCreatorId,
      "original_strategy_id": originalStrategyId,
    });

    Request req = Request(
        'POST', Uri.parse('https://www.tradergpt.co/api/community/strategy/deploy'))
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
      FlushBar.flushbarmessagered(message: "${jsonData['message']}", context: context);

      return false;
    }
  }

  Future<bool> backTest({
    required BuildContext context,
    required String userId,
    required String conversationId,
    required String messageId,
  }) async {
    var body = jsonEncode({
      "user_id": userId,
      "conversation_id": conversationId,
      "message_id": messageId,
    });

    print('body $body');

    Request req = Request(
      'POST',
      Uri.parse('https://www.tradergpt.co/api/conversation/backtest'),
    )
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
    print('response.statusCode ${response.statusCode}');
    print('jsonData $jsonData');

    // Adjust this condition to check the correct field
    if (response.statusCode == 200 && jsonData['status'] == 'success') {
      // Ensure strategyId variable is defined
       strategyId = jsonData['strategy_id']; // Store the strategy_id
      print('strategyId $strategyId'); // Print it to verify

      if (jsonData.containsKey('message')) {
        logger.i(jsonData['message']);
      } else {
        logger.i("Backtest was successful, but no message was provided.");
      }
      return true;
    } else {
      // Handle error message correctly
      String errorMessage = jsonData['message'] ?? "An unknown error occurred.";
      logger.e("Failed to add back test: $errorMessage");
      FlushBar.flushbarmessagered(message: errorMessage, context: context);
      return false;
    }
  }


  Future<StrategyMetric> getStrategyMetrics(
      String username, String strategy) async {
    var queryParameters = {
      'user_id': username,
      'strategy_id': strategy,
    };

    Request req = Request(
        'GET', Uri.parse('https://www.tradergpt.co/api/strategy/metrics'))
      ..body = json.encode(queryParameters)
      ..headers.addAll({
        "Content-type": "application/json",
      });

    var response = await req.send();

    // Convert the streamed response to string
    var responseString = await response.stream.bytesToString();

    // Parse the JSON response
    final Map<String, dynamic> jsonData = jsonDecode(responseString);

    StrategyMetric data = StrategyMetric.fromJson(jsonData);

    logger.i(jsonData);

    return data;
  }

  Future<StrategyBacktestChart> getStrategyBacktestChart(
      String username, String strategy) async {
    var queryParameters = {
      'user_id': username,
      'strategy_id': strategy,
    };

    Request req = Request(
        'GET', Uri.parse('https://www.tradergpt.co/api/strategy/backtest'))
      ..body = json.encode(queryParameters)
      ..headers.addAll({
        "Content-type": "application/json",
      });

    var response = await req.send();

    // Convert the streamed response to string
    var responseString = await response.stream.bytesToString();

    // Parse the JSON response
    final Map<String, dynamic> jsonData = jsonDecode(responseString);

    // Create a ChartData instance from the parsed JSON
    StrategyBacktestChart data = StrategyBacktestChart.fromJson(jsonData);

    // Log the response for debugging
    logger.i(jsonData);

    return data;
  }

  Future<StrategyBacktestChartYahoo> getYahooCharts(
      String userId, String symbol, List dates) async {
    var queryParameters = {
      'user_id': userId,
      'symbol': symbol,
      'dates': dates,
    };

    Request req =
        Request('GET', Uri.parse('https://www.tradergpt.co/api/ticker/data'))
          ..body = json.encode(queryParameters)
          ..headers.addAll({
            "Content-type": "application/json",
          });

    var response = await req.send();

    // Convert the streamed response to a string
    var responseString = await response.stream.bytesToString();

    // Parse the JSON response
    final Map<String, dynamic> jsonData = jsonDecode(responseString);

    // Create a CumulativeReturnsResponse instance from the parsed JSON
    StrategyBacktestChartYahoo data =
        StrategyBacktestChartYahoo.fromJson(jsonData);

    // Log the response for debugging
    logger.i(jsonData);

    return data;
  }

  Future<List<LogEntry>> getLogs(String username, String strategy) async {
    var queryParameters = {
      'user_id': username,
      'strategy_id': strategy,
    };

    Request req = Request(
        'GET', Uri.parse('https://www.tradergpt.co/api/cloudwatch_logs'))
      ..body = json.encode(queryParameters)
      ..headers.addAll({
        "Content-type": "application/json",
      });

    var response = await req.send();

    // Convert the streamed response to string
    var responseString = await response.stream.bytesToString();

    // Parse the JSON response
    final List<dynamic> jsonData = jsonDecode(responseString);

    // Create a ChartData instance from the parsed JSON
    List<LogEntry> logs =
        jsonData.map<LogEntry>((log) => LogEntry.fromJson(log)).toList();

    // Log the response for debugging
    logger.i(jsonData);

    return logs;
  }

  Future<WatchlistStrategy> getWatchliststrategy(
      String userid, String creatorid, String strategyid) async {
    var queryParameters = {
      'user_id': userid,
      'original_creator_id': creatorid,
      'strategy_id': strategyid
    };

    Request req = Request(
        'GET', Uri.parse('https://www.tradergpt.co/api/watchlist/strategy'))
      ..body = json.encode(queryParameters)
      ..headers.addAll({
        "Content-type": "application/json",
      });

    // Send the request
    var response = await req.send();

    // Convert the streamed response to string
    var responseString = await response.stream.bytesToString();

    // Parse the JSON response
    var jsonData = jsonDecode(responseString);

    // Create an ApiResponse instance from the parsed JSON
    WatchlistStrategy data = WatchlistStrategy.fromJson(jsonData);

    // Log the response for debugging
    print(jsonData);

    return data;
  }

  Future<String> buyingPower(String userId, String selectedEnvironment) async {
    var queryParameters = {
      'user_id': userId,
      'selected_environment': selectedEnvironment,
    };

    Request req =
    Request('GET', Uri.parse('https://www.tradergpt.co/api/buying_power'))
      ..body = json.encode(queryParameters)
      ..headers.addAll({
        "Content-type": "application/json",
      });
    var response = await req.send();

    // Convert the streamed response to string
    var responseString = await response.stream.bytesToString();

    var jsonData = jsonDecode(responseString);

    logger.i(responseString);

    return jsonData;
  }

  Future<bool> conversationStrategyDeploy({required BuildContext context,required String userId,required String selectedEnvironment,required  String strategyName,required String frequency,required int fundingAmount,required  int shareWithCommunity,required int selfImprove, required String originalCreatorId,required String originalStrategyId, required String strategyIds}) async {
    var body = jsonEncode({
      "user_id": userId,
      "selected_environment": selectedEnvironment,
      "strategy_name": strategyName,
      "frequency": frequency,
      "funding_amount": fundingAmount,
      "share_with_community": shareWithCommunity,
      "original_creator_id": originalCreatorId,
      "original_strategy_id": originalStrategyId,
      "strategy_id": strategyIds,
    });

    Request req = Request(
        'POST', Uri.parse('https://www.tradergpt.co/api/conversation/strategy/deploy'))
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
      FlushBar.flushbarmessagered(message: "${jsonData['message']}", context: context);

      return false;
    }
  }

}
