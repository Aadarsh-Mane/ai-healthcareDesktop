import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:doctordesktop/constants/Url.dart';

Future<void> sendData(
    String email, String password, String usertype, String doctorName) async {
  final url = '${KVM_URL}/reception/addDoctor'; // Replace with your backend URL

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'usertype': usertype,
        'doctorName': doctorName,
      }),
    );

    if (response.statusCode == 201) {
      // Handle successful response
      print('Data sent successfully: ${response.body}');
    } else {
      // Handle error response
      print('Failed to send data: ${response.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
