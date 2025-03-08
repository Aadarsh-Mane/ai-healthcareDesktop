import 'dart:convert';

import 'package:doctordesktop/model/patientDischargeModel.dart';
import 'package:doctordesktop/repositories/auth_repository.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final auth = AuthRepository();

class DoctorRepository {
  Future<void> addPrescription(String patientId, String admissionId,
      DoctorPrescription doctorPrescription) async {
    final url = Uri.parse('${KVM_URL}/doctors/addPresciption');
    final token = await auth.getToken(); // Fetch your token for authentication

    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'patientId': patientId,
        'admissionId': admissionId,
        'prescription': {
          // Updated to include the `prescription` key

          'medicine': {
            'name': doctorPrescription.medicine.name,
            'morning': doctorPrescription.medicine.morning,
            'afternoon': doctorPrescription.medicine.afternoon,
            'night': doctorPrescription.medicine.night,
            'comment': doctorPrescription.medicine.comment,
          },
        }
      }),
    );
    print('Medicine Name: ${doctorPrescription.medicine.name}');
    print('Morning Dosage: ${doctorPrescription.medicine.morning}');
    print('Afternoon Dosage: ${doctorPrescription.medicine.afternoon}');
    print('Night Dosage: ${doctorPrescription.medicine.night}');
    print('Comment: ${doctorPrescription.medicine.comment}');

    print('Payload: ${response.body}');

    print(response.body);

    if (response.statusCode != 201) {
      throw Exception('Failed to add prescription: ${response.statusCode}');
    }
  }

  Future<List<String>> fetchConsultant(String admissionId) async {
    final url = Uri.parse('${KVM_URL}/doctors/getConsultant/$admissionId');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    print("the admiison is ${admissionId}");
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      print(response.body);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<String>.from(data.map((item) => item.toString()));
      } else {
        throw Exception('Failed to fetch prescriptions');
      }
    } catch (e) {
      throw Exception('Error fetching prescriptions: $e');
    }
  }

  Future<List<FollowUp>> fetchFollowUps(String admissionId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    final url = Uri.parse(
        '${KVM_URL}/nurse/followups/$admissionId'); // API endpoint for fetching follow-ups
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => FollowUp.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load follow-ups');
      }
    } catch (e) {
      throw Exception('Error fetching follow-ups: $e');
    }
  }

  Future<List<FollowUp>> fetch2hrFollowUps(String admissionId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    final url = Uri.parse(
        '${KVM_URL}/nurse/2hrfollowups/$admissionId'); // API endpoint for fetching follow-ups
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => FollowUp.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load follow-ups');
      }
    } catch (e) {
      throw Exception('Error fetching follow-ups: $e');
    }
  }

  Future<List<DoctorPrescription>> fetchPrescriptions(
      String patientId, String admissionId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    final url =
        Uri.parse('${KVM_URL}/doctors/getPrescription/$patientId/$admissionId');

    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.get(
      url,
    );
    print(
        "checkigng ${response.body}"); // Print the response body to inspect it

    if (response.statusCode == 200) {
      // Assuming the response body contains a "prescriptions" array
      final Map<String, dynamic> responseData = json.decode(response.body);

      // Extract the "prescriptions" array
      final prescriptionsList = responseData['prescriptions'];

      if (prescriptionsList != null && prescriptionsList is List) {
        // Convert each item in the list to a DoctorPrescription object
        return prescriptionsList
            .map((data) => DoctorPrescription.fromJson(data))
            .toList();
      } else {
        throw Exception('No prescriptions data found');
      }
    } else {
      throw Exception('Failed to fetch prescriptions: ${response.statusCode}');
    }
  }

  Future<List<String>> fetchSymptomsByDoctor(
      String patientId, String admissionId) async {
    print("hello from patient " + patientId);
    final url = '${KVM_URL}/doctors/fetchSymptoms/$patientId/$admissionId';
    try {
      final response = await http.get(Uri.parse(url));
      // print("Fetching ${patientId}");
      if (response.statusCode == 200) {
        return List<String>.from(json.decode(response.body)['symptoms'] ?? []);
      } else {
        throw Exception('Failed to fetch symptoms: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching symptoms: $e');
    }
  }

  Future<void> deletePrescription(
      String patientId, String admissionId, String prescriptionId) async {
    final url = Uri.parse(
        '${KVM_URL}/doctors/deletePrescription/$patientId/$admissionId/$prescriptionId');
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete prescription');
    }
  }

  Future<void> deleteSymptoms(
      String patientId, String admissionId, String symptom) async {
    final url = Uri.parse(
        '${KVM_URL}/doctors/deleteSymptom/$patientId/$admissionId/$symptom');
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete prescription');
    }
  }

  Future<void> deleteDiagnosis(
      String patientId, String admissionId, String diagnosis) async {
    final url = Uri.parse(
        '${KVM_URL}/doctors/deleteDiagnosis/$patientId/$admissionId/$diagnosis');
    final response = await http.delete(url);
    print(response.body);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete diagnosis');
    }
  }

  Future<void> deleteVitals(
      String patientId, String admissionId, String vitalsId) async {
    final url = Uri.parse(
        '${KVM_URL}/doctors/deleteVitals/$patientId/$admissionId/$vitalsId');
    final response = await http.delete(url);
    print(response.body);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete prescription');
    }
  }

  Future<void> addSymptomsByDoctor(
      String admissionId, String newSymptom, String patientId) async {
    try {
      final response = await http.post(
        Uri.parse('${KVM_URL}/doctors/addSymptoms'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "patientId": patientId,
          "admissionId": admissionId,
          "symptoms": [newSymptom],
        }),
      );
      print("the response is ${response.body}");
      if (response.statusCode == 200) {
        await fetchSymptomsByDoctor(
            patientId, admissionId); // Refresh symptoms after adding
      } else {
        throw Exception('Failed to add symptom');
      }
    } catch (e) {
      print('Error adding symptom: $e');
    }
  }

  Future<void> addVitals(
      String patientId, String admissionId, Vitals vitals) async {
    final url = Uri.parse('${KVM_URL}/doctors/addVitals');
    final token = await auth.getToken(); // Fetch your token for authentication

    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'patientId': patientId,
        'admissionId': admissionId,
        'vitals': {
          'temperature': vitals.temperature,
          'pulse': vitals.pulse,
          'bloodPressure': vitals.bloodPressure,
          'bloodSugarLevel': vitals.bloodSugarLevel,
          'other': vitals.other,
        },
      }),
    );
    print("vitas response ${response.body}");
    if (response.statusCode != 200) {
      throw Exception('Failed to add prescription: ${response.statusCode}');
    }
  }

  Future<List<Vitals>> fetchVitals(String patientId, String admissionId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    final url =
        Uri.parse('${KVM_URL}/doctors/fetchVitals/$patientId/$admissionId');

    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.get(
      url,
    );
    print("vitas fetch ${response.body}");

    if (response.statusCode == 200) {
      // Assuming the response body contains a "prescriptions" array
      final Map<String, dynamic> responseData = json.decode(response.body);

      // Extract the "prescriptions" array
      final prescriptionsList = responseData['vitals'];

      if (prescriptionsList != null && prescriptionsList is List) {
        // Convert each item in the list to a DoctorPrescription object
        return prescriptionsList.map((data) => Vitals.fromJson(data)).toList();
      } else {
        throw Exception('No prescriptions data found');
      }
    } else {
      throw Exception('Failed to fetch prescriptions: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> updateConditionAtDischarge(
      {required String admissionId,
      required String conditionAtDischarge,
      required int amountToBePayed}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    final response = await http.post(
      Uri.parse('${KVM_URL}/doctors/updateCondition'),
      headers: {
        'Authorization': 'Bearer ${token}', // Add authentication token
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'admissionId': admissionId,
        'conditionAtDischarge': conditionAtDischarge,
        'amountToBePayed': amountToBePayed
      }),
    );
    print("checking ${response.body}");
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update condition at discharge');
    }
  }

  Future<List<DoctorConsulting>> fetchDoctorConsultant(
      String patientId, String admissionId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    final url = Uri.parse(
        '${KVM_URL}/doctors/doctorConsulting/$patientId/$admissionId');

    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.get(
      url,
    );
    print(
        "checkigng ${response.body}"); // Print the response body to inspect it

    if (response.statusCode == 200) {
      // Assuming the response body contains a "prescriptions" array
      final Map<String, dynamic> responseData = json.decode(response.body);

      // Extract the "prescriptions" array
      final consultingList = responseData['doctorConsulting'];

      if (consultingList != null && consultingList is List) {
        // Convert each item in the list to a DoctorPrescription object
        return consultingList
            .map((data) => DoctorConsulting.fromJson(data))
            .toList();
      } else {
        throw Exception('No prescriptions data found');
      }
    } else {
      throw Exception('Failed to fetch prescriptions: ${response.statusCode}');
    }
  }

  Future<void> addDoctorConsultant(String patientId, String admissionId,
      DoctorConsulting doctorPrescription) async {
    final url = Uri.parse('${KVM_URL}/doctors/addDoctorConsultant');
    final token = await auth.getToken(); // Fetch your token for authentication

    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'patientId': patientId,
        'admissionId': admissionId,
        'consulting': {
          'allergies': doctorPrescription.allergies,
          'cheifComplaint': doctorPrescription.cheifComplaint,
          'describeAllergies': doctorPrescription.describeAllergies,
          'historyOfPresentIllness': doctorPrescription.historyOfPresentIllness,
          'personalHabits': doctorPrescription.personalHabits,
          'familyHistory': doctorPrescription.familyHistory,
          'menstrualHistory': doctorPrescription.menstrualHistory,
          'wongBaker': doctorPrescription.wongBaker,
          'visualAnalogue': doctorPrescription.visualAnalogue,
          'relevantPreviousInvestigations':
              doctorPrescription.relevantPreviousInvestigations,
          'immunizationHistory': doctorPrescription.immunizationHistory,
          'pastMedicalHistory': doctorPrescription.pastMedicalHistory,
          'date': doctorPrescription.date,
        }
      }),
    );
    ;

    print('Payload: ${response.body}');

    print(response.body);

    if (response.statusCode != 201) {
      throw Exception('Failed to add prescription: ${response.statusCode}');
    }
  }

  Future<List<String>> fetchDoctorDiagnosis(
      String admissionId, String patientId) async {
    final url = '${KVM_URL}/doctors/fetchDiagnosis/$patientId/$admissionId';
    print("patient id is ${patientId} and admission id is ${admissionId}");
    try {
      final response = await http.get(Uri.parse(url));
      print("this is for diagnosi ${response.body}");
      if (response.statusCode == 200) {
        return List<String>.from(json.decode(response.body)['diagnosis'] ?? []);
      } else {
        throw Exception('Failed to fetch daignosis: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching diagnosis: $e');
    }
  }

  Future<void> addDoctorDiagnosis(
      String admissionId, String newDiagnosis, String patientId) async {
    try {
      final response = await http.post(
        Uri.parse('${KVM_URL}/doctors/addDiagnosis'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "patientId": patientId,
          "admissionId": admissionId,
          "diagnosis": [newDiagnosis],
        }),
      );
      print("the response is ${response.body}");
      if (response.statusCode == 200) {
        await fetchDoctorDiagnosis(
            admissionId, patientId); // Refresh symptoms after adding
      } else {
        throw Exception('Failed to add daignosis');
      }
    } catch (e) {
      print('Error adding diagnosis: $e');
    }
  }

  final dischargedPatientsProvider =
      FutureProvider<List<PatientDischarge>>((ref) async {
    final response = await http
        .get(Uri.parse('${KVM_URL}/reception/getAllDischargedPatient'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => PatientDischarge.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load discharged patients');
    }
  });
}
