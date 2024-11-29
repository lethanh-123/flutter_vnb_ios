import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://banhang.shopvnb.com/app_api_ban_hang";

  static Future<Map<String, dynamic>?> callApi(
      String act, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl?act=$act');
    final headers = {
      'Authorization': 'Bearer 64f18d01cc3fbdb1cb5f8a448b277c9c',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('API Call Error: $e');
      return null;
    }
  }
}
