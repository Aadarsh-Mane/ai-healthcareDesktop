import 'dart:convert';

import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/model/getNewPatientHistoryModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class HistoryRepository {
  Future<PatientHistory> fetchPatientHistory(String patientId) async {
    final url = Uri.parse('${KVM_URL}/doctors/getPatientHistory1/$patientId');

    final response = await http.get(
      url,
    );
    print("hello ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (responseData.containsKey('history')) {
        final historyData = responseData['history'];

        // Check if history is a List or Map
        if (historyData is Map<String, dynamic>) {
          return PatientHistory.fromJson(responseData);
        } else {
          throw Exception(
              'Unexpected data type for history: ${historyData.runtimeType}');
        }
      } else {
        throw Exception('No patient history data found');
      }
    } else {
      throw Exception(
          'Failed to fetch patient history: ${response.statusCode}');
    }
  }
}
