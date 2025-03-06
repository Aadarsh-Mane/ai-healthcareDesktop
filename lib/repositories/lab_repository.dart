import 'dart:convert';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/model/getNewLabPatientModel.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LabReportRepository {
  Future<LabReportResponse> fetchLabPatients() async {
    final url = Uri.parse("${KVM_URL}/labs/getlabPatients");
    final response = await http.get(url);
    print(response.body);
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      return LabReportResponse.fromJson(jsonResponse);
    } else {
      throw Exception(
          "Failed to fetch lab patients. Status: ${response.statusCode}");
    }
  }
}

final labReportRepositoryProvider = Provider((ref) => LabReportRepository());
