import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:doctordesktop/constants/Url.dart';

class PatientAssignmentScreen extends StatefulWidget {
  @override
  _PatientAssignmentScreenState createState() =>
      _PatientAssignmentScreenState();
}

class _PatientAssignmentScreenState extends State<PatientAssignmentScreen> {
  List<String> doctorNames = [];
  String? selectedDoctor;
  List<Map<String, dynamic>> patients = [];

  // Fetch the list of available doctors
  Future<void> _fetchDoctors() async {
    final response =
        await http.get(Uri.parse('${VERCEL_URL}/reception/listDoctors'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        doctorNames = List<String>.from(
            data['doctors'].map((doctor) => doctor['doctorName']));
      });
    } else {
      // Handle the error gracefully
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error fetching doctors")));
    }
  }

  // Fetch patients based on the selected doctor
  Future<void> _fetchPatients() async {
    if (selectedDoctor != null) {
      final response = await http.get(
        Uri.parse(
            '${VERCEL_URL}/reception/getPatientAssignedToDoctor/$selectedDoctor'),
      );

      if (response.statusCode == 200) {
        print(response.body);
        final data = jsonDecode(response.body);
        setState(() {
          patients = List<Map<String, dynamic>>.from(data['patients']);
        });
      } else {
        setState(() {
          patients = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("No patients found for this doctor")));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDoctors(); // Fetch the doctors when the screen is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Doctor-Patient Assignment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown to select a doctor
            DropdownButton<String>(
              value: selectedDoctor,
              hint: Text("Select Doctor"),
              onChanged: (String? newDoctor) {
                setState(() {
                  selectedDoctor = newDoctor;
                });
                _fetchPatients(); // Fetch patients based on selected doctor
              },
              items: doctorNames
                  .map<DropdownMenuItem<String>>((String doctorName) {
                return DropdownMenuItem<String>(
                  value: doctorName,
                  child: Text(doctorName),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            // List of patients assigned to the selected doctor
            if (patients.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.symmetric(vertical: 5),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Patient Info
                            Text("Patient ID: ${patient['patientId']}",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("Name: ${patient['name']}"),
                            Text("Age: ${patient['age']}"),
                            Text("Gender: ${patient['gender']}"),
                            Text("Contact: ${patient['contact']}"),
                            Text("Address: ${patient['address']}"),
                            SizedBox(height: 10),
                            // Admission Records
                            Text("Admission Records:",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            ...patient['admissionRecords']
                                .map<Widget>((admission) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "Doctor: ${admission['doctor']['name']}"),
                                  Text(
                                      "Admission Date: ${admission['admissionDate']}"),
                                  Text(
                                      "Reason for Admission: ${admission['reasonForAdmission']}"),
                                  Text("Symptoms: ${admission['symptoms']}"),
                                  Text(
                                      "Initial Diagnosis: ${admission['initialDiagnosis']}"),
                                  SizedBox(height: 5),
                                  // Follow-ups
                                  Text("Follow-ups:",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  ...admission['followUps']
                                      .map<Widget>((followUp) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("Date: ${followUp['date']}"),
                                        Text("Notes: ${followUp['notes']}"),
                                        Text(
                                            "Observations: ${followUp['observations']}"),
                                        SizedBox(height: 5),
                                      ],
                                    );
                                  }).toList(),
                                  SizedBox(height: 10),
                                ],
                              );
                            }).toList(),
                            SizedBox(height: 10),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Center(child: Text("No patients assigned to this doctor")),
          ],
        ),
      ),
    );
  }
}
