import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AssignDoctorScreen extends StatefulWidget {
  @override
  _AssignDoctorScreenState createState() => _AssignDoctorScreenState();
}

class _AssignDoctorScreenState extends State<AssignDoctorScreen> {
  String? _selectedPatientId;
  String? _selectedAdmissionId;
  String? _selectedDoctorId;
  bool _isReadmission = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _doctors = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await Future.wait([_fetchPatients(), _fetchDoctors()]);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchPatients() async {
    final response =
        await http.get(Uri.parse('${KVM_URL}/reception/listPatients'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _patients = (data['patients'] as List).map((p) {
          return {
            'id': p['patientId'],
            'name': p['name'],
            'admissionRecords': p['admissionRecords'],
          };
        }).toList();
      });
    } else {
      throw Exception('Failed to load patients');
    }
  }

  Future<void> _fetchDoctors() async {
    final response =
        await http.get(Uri.parse('${KVM_URL}/reception/listDoctors'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _doctors = (data['doctors'] as List).map((d) {
          return {
            'id': d['_id'],
            'name': d['doctorName'],
          };
        }).toList();
      });
    } else {
      throw Exception('Failed to load doctors');
    }
  }

  Future<void> _assignDoctor() async {
    if (_selectedPatientId != null &&
        _selectedDoctorId != null &&
        _selectedAdmissionId != null) {
      final response = await http.post(
        Uri.parse('${KVM_URL}/reception/assign-Doctor'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patientId': _selectedPatientId,
          'doctorId': _selectedDoctorId,
          'admissionId': _selectedAdmissionId,
          'isReadmission': _isReadmission,
        }),
      );
      print('Selected Patient: $_selectedPatientId');
      print('Selected Doctor: $_selectedDoctorId');
      print('Selected Admission: $_selectedAdmissionId');
      print('Is Readmission: $_isReadmission');

      // print(_selectedDoctorId);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Doctor assigned successfully!'),
              backgroundColor: Colors.green),
        );
      } else {
        print(response.body);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to assign doctor'),
              backgroundColor: Colors.red),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please select patient, admission, and doctor'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assign Doctor'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedPatientId,
                    decoration: InputDecoration(labelText: 'Select Patient'),
                    items: _patients.map((patient) {
                      return DropdownMenuItem<String>(
                        value: patient['id'],
                        child: Text(patient['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPatientId = value;
                        _selectedAdmissionId =
                            null; // Reset admission on patient change
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a patient' : null,
                  ),
                  if (_selectedPatientId != null)
                    DropdownButtonFormField<String>(
                      value: _selectedAdmissionId,
                      decoration:
                          InputDecoration(labelText: 'Select Admission'),
                      items: _patients
                          .firstWhere((p) => p['id'] == _selectedPatientId)[
                              'admissionRecords']
                          .map<DropdownMenuItem<String>>((admission) {
                        return DropdownMenuItem<String>(
                          value: admission['_id'],
                          child: Text('Admission ID: ${admission['_id']}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedAdmissionId = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select an admission' : null,
                    ),
                  DropdownButtonFormField<String>(
                    value: _selectedDoctorId,
                    decoration: InputDecoration(labelText: 'Select Doctor'),
                    items: _doctors.map((doctor) {
                      return DropdownMenuItem<String>(
                        value: doctor['id'],
                        child: Text(doctor['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDoctorId = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a doctor' : null,
                  ),
                  SwitchListTile(
                    title: Text('Is Readmission'),
                    value: _isReadmission,
                    onChanged: (bool value) {
                      setState(() {
                        _isReadmission = value;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _assignDoctor,
                    child: Text('Assign Doctor'),
                  ),
                ],
              ),
            ),
    );
  }
}
