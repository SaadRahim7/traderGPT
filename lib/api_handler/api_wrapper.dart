import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/api_handler/network_constant.dart';
import 'package:flutter_application_1/widget/flushbar.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class ApiWrapper {
  var logger = Logger();

  // Generic GET request
  Future get(Uri url) async {
    final connectivityResult = await (Connectivity().checkConnectivity());

    if (connectivityResult != ConnectivityResult.none) {
      try {
        final response = await http.get(
          url,
          
        );

        logger.i('URL $url Response getApi: ${response.body}');
        return _handleResponse(response);
      } catch (e) {
        FlushBar.flushbarmessagered(message: "$e", context: BuildContext);
      }
    } else {
      FlushBar.flushbarmessagered(
          message: "No Internet Connection", context: BuildContext);
    }
  }

  // Generic POST request
  Future<dynamic> post(String endpoint,
      {Map<String, String>? headers, dynamic body}) async {
    String urlString = '${NetworkConstantsUtil.baseUrl}$endpoint';

    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      try {
        final response = await http.post(
          Uri.parse(urlString),
          headers: headers,
          body: json.encode(body),
        );

        logger.i('URL $urlString Response getApi: ${response.body}');
        return _handleResponse(response);
      } catch (e) {
        FlushBar.flushbarmessagered(message: "$e", context: BuildContext);
      }
    } else {
      FlushBar.flushbarmessagered(
          message: "No Internet Connection", context: BuildContext);
    }
  }

  // Generic PUT request
  Future<dynamic> put(String endpoint,
      {Map<String, String>? headers, dynamic body}) async {
    String urlString = '${NetworkConstantsUtil.baseUrl}$endpoint';

    final connectivityResult = await (Connectivity().checkConnectivity());

    if (connectivityResult != ConnectivityResult.none) {
      try {
        final response = await http.put(
          Uri.parse(urlString),
          headers: headers,
          body: json.encode(body),
        );
        logger.i('URL $urlString Response getApi: ${response.body}');
        return _handleResponse(response);
      } catch (e) {
        FlushBar.flushbarmessagered(message: "$e", context: BuildContext);
      }
    } else {
      FlushBar.flushbarmessagered(
          message: "No Internet Connection", context: BuildContext);
    }
  }

  // Generic DELETE request
  Future<dynamic> delete(String endpoint,
      {Map<String, String>? headers}) async {
    String urlString = '${NetworkConstantsUtil.baseUrl}$endpoint';

    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      try {
        final response =
            await http.delete(Uri.parse(urlString), headers: headers);

        logger.i('URL $urlString Response getApi: ${response.body}');
        return _handleResponse(response);
      } catch (e) {
        FlushBar.flushbarmessagered(message: "$e", context: BuildContext);
      }
    } else {
      FlushBar.flushbarmessagered(
          message: "No Internet Connection", context: BuildContext);
    }
  }

  // Handle HTTP response and parse JSON
  dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return json.decode(response.body);
      case 400:
        throw Exception('Bad request: ${response.body}');
      case 401:
      case 403:
        throw Exception('Unauthorized: ${response.body}');
      case 500:
        throw Exception('Server error: ${response.body}');
      default:
        throw Exception('Unexpected error: ${response.statusCode}');
    }
  }
}
