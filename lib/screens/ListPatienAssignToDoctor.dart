import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:doctordesktop/constants/Url.dart';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PatientAssignmentScreen extends StatefulWidget {
  @override
  _PatientAssignmentScreenState createState() =>
      _PatientAssignmentScreenState();
}

class _PatientAssignmentScreenState extends State<PatientAssignmentScreen> {
  List<String> doctorNames = [];
  String? selectedDoctor;
  List<Map<String, dynamic>> patients = [];
  Map<String, dynamic>? selectedPatient;

  Future<void> _fetchDoctors() async {
    final response =
        await http.get(Uri.parse('${KVM_URL}/reception/listDoctors'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        doctorNames = List<String>.from(
            data['doctors'].map((doctor) => doctor['doctorName']));
      });
    }
  }

  Future<void> _fetchPatients() async {
    if (selectedDoctor != null) {
      final response = await http.get(
        Uri.parse(
            '${KVM_URL}/reception/getPatientAssignedToDoctor/$selectedDoctor'),
      );

      if (response.statusCode == 200) {
        setState(() {
          patients = List<Map<String, dynamic>>.from(
              jsonDecode(response.body)['patients']);
          selectedPatient = null;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doctor-Patient Assignment'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: 300,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedDoctor,
                  hint: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Select Doctor',
                        style: TextStyle(color: Colors.white70)),
                  ),
                  dropdownColor: Theme.of(context).primaryColor,
                  style: TextStyle(color: Colors.white),
                  icon: Icon(Icons.arrow_drop_down, color: Colors.white70),
                  onChanged: (String? newDoctor) {
                    setState(() => selectedDoctor = newDoctor);
                    _fetchPatients();
                  },
                  items: doctorNames
                      .map<DropdownMenuItem<String>>((String doctorName) {
                    return DropdownMenuItem<String>(
                      value: doctorName,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(doctorName),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient List Panel
            Expanded(
              flex: 2,
              child: Card(
                color: Colors.white,
                elevation: 4,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Assigned Patients',
                          style: Theme.of(context).textTheme.bodyLarge),
                    ),
                    Expanded(
                      child: patients.isEmpty
                          ? Center(child: Text('No patients assigned'))
                          : ListView.separated(
                              itemCount: patients.length,
                              separatorBuilder: (_, __) => Divider(height: 1),
                              itemBuilder: (context, index) {
                                final patient = patients[index];
                                return ListTile(
                                  title: Text(patient['name'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                      )),
                                  subtitle: Text(
                                    'ID: ${patient['patientId']}',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'Poppins',
                                        color: Color(0xFF2A79B4)),
                                  ),
                                  leading: CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.white,
                                      child: Text(
                                        patient['name'][0].toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 24,
                                          color: Color(0xFF2A79B4),
                                          fontFamily: 'Poppins',
                                        ),
                                      )),
                                  selected: selectedPatient == patient,
                                  onTap: () =>
                                      setState(() => selectedPatient = patient),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 16),
            // Patient Details Panel
            Expanded(
              flex: 3,
              child: Card(
                  elevation: 4,
                  child: selectedPatient == null
                      ? Center(child: Text('Select a patient to view details'))
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader('Patient Information'),
                              _buildInfoRow(
                                  'Patient ID',
                                  selectedPatient?['patientId']?.toString() ??
                                      'N/A'),
                              _buildInfoRow('Age',
                                  selectedPatient?['age']?.toString() ?? 'N/A'),
                              _buildInfoRow('Gender',
                                  selectedPatient?['gender'] ?? 'N/A'),
                              _buildInfoRow('Contact',
                                  selectedPatient?['contact'] ?? 'N/A'),
                              _buildInfoRow('Address',
                                  selectedPatient?['address'] ?? 'N/A'),
                              // _buildInfoRow(
                              //     'Address', selectedPatient?['address']),
                              SizedBox(height: 24),
                              _buildSectionHeader('Admission Records'),
                              ...(selectedPatient?['admissionRecords'] as List?)
                                      ?.map<Widget>((admission) {
                                    final admissionMap =
                                        admission as Map<String, dynamic>? ??
                                            {};
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildSubSectionHeader(
                                              'Admission Details'),
                                          _buildInfoRow(
                                              'Admission Date',
                                              admissionMap['admissionDate']
                                                      ?.toString() ??
                                                  'N/A'),
                                          _buildInfoRow(
                                              'Reason',
                                              admissionMap['reasonForAdmission']
                                                      ?.toString() ??
                                                  'N/A'),
                                          _buildInfoRow(
                                              'Symptoms',
                                              admissionMap['symptoms']
                                                      ?.toString() ??
                                                  'N/A'),
                                          _buildInfoRow(
                                              'Initial Diagnosis',
                                              admissionMap['initialDiagnosis']
                                                      ?.toString() ??
                                                  'N/A'),
                                          SizedBox(height: 12),
                                          _buildSubSectionHeader('Follow-ups'),
                                          ...(admissionMap['followUps']
                                                      as List?)
                                                  ?.map<Widget>((followUp) {
                                                final followUpMap = followUp
                                                        as Map<String,
                                                            dynamic>? ??
                                                    {};
                                                return Container(
                                                  margin: EdgeInsets.only(
                                                      bottom: 8),
                                                  padding: EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      _buildInfoRow(
                                                          'Date',
                                                          followUpMap['date']
                                                                  ?.toString() ??
                                                              'N/A'),
                                                      _buildInfoRow(
                                                          'Notes',
                                                          followUpMap['notes']
                                                                  ?.toString() ??
                                                              'N/A'),
                                                      _buildInfoRow(
                                                          'Observations',
                                                          followUpMap['observations']
                                                                  ?.toString() ??
                                                              'N/A'),
                                                    ],
                                                  ),
                                                );
                                              }).toList() ??
                                              [],
                                        ],
                                      ),
                                    );
                                  }).toList() ??
                                  [],
                            ],
                          ),
                        )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(title,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor)),
    );
  }

  Widget _buildSubSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700)),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                fontSize: 16,
                height: 1.3,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
