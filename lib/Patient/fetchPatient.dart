import 'package:doctordesktop/model/PatientModel.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:doctordesktop/constants/Url.dart';

class PatientListScreen extends StatefulWidget {
  @override
  _PatientListScreenState createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  List<Patient> _patients = [];
  List<Patient> _filteredPatients = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    try {
      final response =
          await http.get(Uri.parse('${KVM_URL}/reception/listPatients'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _patients = (data['patients'] as List)
              .map((patientJson) => Patient.fromJson(patientJson))
              .toList();
          _filteredPatients = _patients;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load patients');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterPatients(String query) {
    setState(() {
      _searchQuery = query;
      _filteredPatients = _patients.where((patient) {
        final nameMatch =
            patient.name.toLowerCase().contains(query.toLowerCase());
        final idMatch = patient.patientId.toString().contains(query);
        return nameMatch || idMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Patient List',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlue.shade200, Colors.blueAccent.shade700],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: _filterPatients,
                decoration: InputDecoration(
                  labelText: 'Search by Patient ID or Name',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _filteredPatients.isEmpty
                      ? Center(
                          child: Text(
                            'No patients found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.redAccent,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredPatients.length,
                          padding: const EdgeInsets.all(16.0),
                          itemBuilder: (context, index) {
                            final patient = _filteredPatients[index];
                            return _buildPatientCard(patient);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(Patient patient) {
    return Card(
      elevation: 8,
      shadowColor: Colors.blueAccent.shade200,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.blueAccent.shade200, width: 2),
      ),
      margin: EdgeInsets.symmetric(vertical: 12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blueAccent.shade700,
                  radius: 28,
                  child: Icon(Icons.person, color: Colors.white, size: 28),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient Discharged:  ${patient.discharged ? 'Yes' : 'No'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.blueGrey.shade900,
                        ),
                      ),
                      Text(
                        'Name: ${patient.name}  Pending  amount: ${patient.pendingAmount}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.blueGrey.shade900,
                        ),
                      ),
                      Text(
                        'Patient ID: ${patient.patientId}',
                        style: TextStyle(
                          color: Colors.blueGrey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildDetailRow(Icons.cake, 'Age: ${patient.age}', Colors.purple),
            _buildDetailRow(
                Icons.person_outline, 'Gender: ${patient.gender}', Colors.pink),
            _buildDetailRow(
                Icons.phone, 'Contact: ${patient.contact}', Colors.green),
            _buildDetailRow(Icons.location_on, 'Address: ${patient.address}',
                Colors.orange),
            SizedBox(height: 12),
            Divider(thickness: 1.5, color: Colors.black.withOpacity(0.3)),

            // Admission Records with Follow-ups in nested ExpansionTiles
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blueAccent.shade200, width: 2),
              ),
              child: ExpansionTile(
                title: Text(
                  'Admission Records',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent.shade700,
                    fontSize: 18,
                  ),
                ),
                children: patient.admissionRecords.map((record) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(Icons.local_hospital,
                            'Doctor: ${record.doctor.name}', Colors.red),
                        _buildDetailRow(
                            Icons.calendar_today,
                            'Admission Date: ${record.admissionDate}',
                            Colors.blue),
                        _buildDetailRow(
                            Icons.sick,
                            'Reason: ${record.reasonForAdmission}',
                            Colors.purple),
                        _buildDetailRow(Icons.notes,
                            'Symptoms: ${record.symptoms}', Colors.teal),
                        SizedBox(height: 8),

                        // Follow-ups with nested ExpansionTile
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.blueAccent.shade200, width: 2),
                          ),
                          child: ExpansionTile(
                            title: Text(
                              'Follow-ups',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent.shade400,
                              ),
                            ),
                            children: record.followUps.map((followUp) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailRow(
                                        Icons.date_range,
                                        'Date: ${followUp.date}',
                                        Colors.indigo),
                                    _buildDetailRow(
                                        Icons.notes,
                                        'Notes: ${followUp.notes}',
                                        Colors.deepOrange),
                                    _buildDetailRow(
                                        Icons.visibility,
                                        'Observations: ${followUp.observations}',
                                        Colors.brown),
                                    Divider(
                                        thickness: 1,
                                        color: Colors.black.withOpacity(0.3)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String detail, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              detail,
              style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade800),
            ),
          ),
        ],
      ),
    );
  }
}
