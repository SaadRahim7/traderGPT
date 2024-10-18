import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String url = 'https://jsonplaceholder.typicode.com/users';

  Future<List<String>> fetchUserNames() async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      List<String> userNames = data.map((item) => item['name'].toString()).toList();
      return userNames;
    } else {
      throw Exception('Failed to load users');
    }
  }
}
