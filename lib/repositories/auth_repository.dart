// lib/repositories/auth_repository.dart
import 'dart:convert';

import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/model/getDoctorProfile.dart';
import 'package:doctordesktop/model/getLabPatient.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${KVM_URL}/users/signin'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      print(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final token = responseBody['token'];
        final usertype = responseBody['user']['usertype'];

        await storeToken(token);
        await storeUsertype(usertype);

        return token;
      } else if (response.statusCode == 401) {
        print("Invalid credentials provided");
        return null;
      } else {
        throw Exception('Failed to login. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Login error: $e");
      rethrow;
    }
  }

  Future<String?> loginNurse(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${KVM_URL}/nurse/signin'), // Different URL for nurse
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final token = responseBody['token'];
        final usertype = responseBody['user']['usertype'];

        await storeToken(token);
        await storeUsertype(usertype);
        return token;
      } else if (response.statusCode == 401) {
        print("Invalid credentials provided");
        return null;
      } else {
        throw Exception('Failed to login. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Login error: $e");
      rethrow;
    }
  }

  Future<void> storeUsertype(String usertype) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usertype', usertype);
  }

  Future<String?> getUsertype() async {
    final prefs = await SharedPreferences.getInstance();
    final usertype = prefs.getString('usertype');
    print("Retrieved usertype from SharedPreferences: $usertype");
    return usertype;
  }

  Future<void> storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    print(
        "Token stored: $token"); // Add this line to verify the token is stored
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    // print("Retrieved token from SharedPreferences: $token");
    return token;
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<void> clearUsertype() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs
        .remove('usertype'); // Remove the usertype from SharedPreferences
    print("Usertype cleared");
  }

  Future<List<Patient1>> fetchAssignedPatients() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Token not found in SharedPreferences');
    }

    try {
      final response = await http.get(
        Uri.parse('${KVM_URL}/doctors/getAssignedPatients'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print("Fetch patients response status code: ${response.statusCode}");
      print("Fetch patients response body: ${response.body}");

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['patients'];
        return data.map((json) => Patient1.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to fetch patients. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching assigned patients: $e");
      rethrow;
    }
  }

  Future<DoctorProfile> fetchDoctorProfile() async {
    print("heelo");
    final token = await getToken();
    if (token == null) {
      throw Exception('Token not found in SharedPreferences');
    }
    try {
      final response = await http.get(
        Uri.parse('${KVM_URL}/doctors/getDoctorProfile'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      print(
          "Fetch doctor profile response status code: ${response.statusCode}");
      print("Fetch doctor profile response body: ${response.body}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return DoctorProfile.fromJson(
            data['doctorProfile']); // Parse single object
      } else {
        throw Exception(
            'Failed to fetch doctorProfile. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching doctorProfile: $e");
      rethrow;
    }
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("All SharedPreferences data cleared");
  }

  Future<List<Patient1>> fetchPatients() async {
    try {
      final response =
          await http.get(Uri.parse('${KVM_URL}/reception/listPatients'));
      print(response.body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final patients = (data['patients'] as List)
            .map((patientJson) => Patient1.fromJson(patientJson))
            .toList();
        return patients;
      } else {
        throw Exception('Failed to load patients');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Patient1>> getAssignedPatients() async {
    try {
      // Retrieve the stored token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      print(token);
      if (token == null) {
        throw Exception('No authentication token found.');
      }

      final response = await http.get(
        Uri.parse('${KVM_URL}/doctors/getAssignedPatients'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('Patient JSON: $json');

      // print(response.body); // Inspect the API response
      print('Full response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['patients'] as List<dynamic>;
        return data.map((json) => Patient1.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to fetch assigned patients. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching assigned patients: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> assignPatientToLab({
    required String patientId,
    required String admissionId,
    required String labTestNameGivenByDoctor,
  }) async {
    final token = await getToken(); // Retrieve the token from storage
    final url = Uri.parse('${KVM_URL}/doctors/assignPatient');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'patientId': patientId,
          'admissionId': admissionId,
          'labTestNameGivenByDoctor': labTestNameGivenByDoctor,
        }),
      );
      print("this is from  ${response.body}");

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Patient assigned to lab successfully',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to assign patient to lab',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  Future<List<Patient1>> getAdmittedPatients() async {
    try {
      // Retrieve the stored token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      print(token);
      if (token == null) {
        throw Exception('No authentication token found.');
      }

      final response = await http.get(
        Uri.parse('${KVM_URL}/doctors/getAdmittedPatient'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      // print(response.body); // Inspect the API response
      // print('Full response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['patients'] as List<dynamic>;
        return data.map((json) => Patient1.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to fetch assigned patients. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching assigned patients: $e');
      rethrow;
    }
  }

  Future<List<AssignedLab>> getAssignedLabs() async {
    final token = await getToken(); // Retrieve the token from storage
    if (token == null) {
      throw Exception('Token not found in SharedPreferences');
    }
    final response = await http.get(
      Uri.parse('${KVM_URL}/doctors/getDoctorAssignedPatient'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    // print(response.body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['labReports']
          as List; // Extract the "labReports" key
      return data.map((json) => AssignedLab.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load assigned labs');
    }
  }

  Future<Map<String, dynamic>> dischargePatient({
    required String patientId,
    required String admissionId,
  }) async {
    final token = await getToken(); // Retrieve the token from storage

    final response = await http.post(
      Uri.parse('${KVM_URL}/doctors/dischargePatient'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'patientId': patientId,
        'admissionId': admissionId,
      }),
    );
    return json.decode(response.body);
  }

  Future<void> storeTokenToBackend(String fcmToken) async {
    final token = await getToken(); // Retrieve the token from storage

    final response = await http.post(
      Uri.parse('${KVM_URL}/storeFcmToken'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'fcmToken': fcmToken,
      }),
    );
    print(response.body);
    if (response.statusCode == 200) {
      print('Token stored successfully');
    } else {
      print('Failed to store token: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> admitPatient1(
      {required String admissionId}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('No authentication token found.');
    }
    final response = await http.post(
      Uri.parse('${KVM_URL}/doctors/admitPatient'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode({'admissionId': admissionId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to admit patient: ${response.body}');
    }
  }

  Future<List<Patient1>> fetchAdmittedPatients() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final response = await http.get(
      Uri.parse('${KVM_URL}/doctors/getadmittedPatient'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    print(token);
    print("this${response.body}"); // Check the response here

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final patients = (jsonData['admittedPatients'] as List)
          .map((patient) => Patient1.fromJson(patient))
          .toList();
      return patients;
    } else {
      throw Exception(
          'Failed to load admitted patients: ${response.reasonPhrase}');
    }
  }
}
