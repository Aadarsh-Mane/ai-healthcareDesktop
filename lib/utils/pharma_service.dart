import 'package:doctordesktop/constants/Url.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // Generic GET method
  static Future<Map<String, dynamic>> get(String endpoint,
      {Map<String, String>? queryParams}) async {
    try {
      final uri = Uri.parse('$KVM_URL/$endpoint').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Generic POST method
  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$KVM_URL/$endpoint');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Generic PUT method
  static Future<Map<String, dynamic>> put(
      String endpoint, String id, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$KVM_URL/$endpoint/$id');

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Generic DELETE method
  static Future<Map<String, dynamic>> delete(String endpoint, String id) async {
    try {
      final uri = Uri.parse('$KVM_URL/$endpoint/$id');

      final response = await http.delete(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to delete data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
