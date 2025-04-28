// lib/repositories/investigation_repository.dart

import 'dart:convert';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/model/getInvestigationModel.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class InvestigationRepository {
  // Get token from shared preferences
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Get all investigations for the doctor
  Future<InvestigationResponse> getDoctorInvestigations(
      {int page = 1, int limit = 10}) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final url = Uri.parse(
        '${KVM_URL}/doctors/getDoctorInvestigations?page=$page&limit=$limit');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return InvestigationResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load investigations: ${response.body}');
    }
  }

  // Create a new investigation
  Future<Map<String, dynamic>> createInvestigation(
      CreateInvestigationRequest request) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final url = Uri.parse('${KVM_URL}/doctors/createInvestigation');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create investigation: ${response.body}');
    }
  }

  // Get investigation details by ID
  Future<Investigation> getInvestigationById(String id) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final url = Uri.parse('${KVM_URL}/doctors/getInvestigation/$id');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return Investigation.fromJson(responseData['data']);
    } else {
      throw Exception('Failed to load investigation details: ${response.body}');
    }
  }

  // Get investigations by patient ID
  Future<InvestigationResponse> getPatientInvestigations(String patientId,
      {int page = 1, int limit = 10}) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final url = Uri.parse(
        '${KVM_URL}/doctors/getPatientInvestigations/$patientId?page=$page&limit=$limit');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return InvestigationResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception(
          'Failed to load patient investigations: ${response.body}');
    }
  }

  // Update investigation status
  Future<Map<String, dynamic>> updateInvestigationStatus(
      String id, String status) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final url = Uri.parse('${KVM_URL}/doctors/updateInvestigationStatus/$id');

    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'status': status}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Failed to update investigation status: ${response.body}');
    }
  }
}
