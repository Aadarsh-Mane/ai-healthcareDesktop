import 'dart:convert';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/ToastMessage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:doctordesktop/constants/Url.dart';
import 'package:toastification/toastification.dart';

class AssignScreen extends StatefulWidget {
  final String patientId;
  final String admissionId;

  const AssignScreen({
    Key? key,
    required this.patientId,
    required this.admissionId,
  }) : super(key: key);

  @override
  State<AssignScreen> createState() => _AssignScreenState();
}

class _AssignScreenState extends State<AssignScreen> {
  List<Map<String, dynamic>> _doctors = [];

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
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
            'email': d['email'],
            'speciality': d['speciality'],
            'imageUrl': d['imageUrl'],
          };
        }).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load doctors'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _assignDoctor(String doctorId) async {
    final response = await http.post(
      Uri.parse('${KVM_URL}/reception/assign-Doctor'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'patientId': widget.patientId,
        'doctorId': doctorId,
        'admissionId': widget.admissionId,
        'isReadmission': false,
      }),
    );

    if (response.statusCode == 200) {
      ToastMessage().showToast(context, 'Patient Added Successfully', '',
          ToastificationType.success);
      Navigator.pop(context); // Pop the screen after success
    } else {
      ToastMessage().showToast(
          context, 'Patient Failed to Added', '', ToastificationType.error);
    }
    Navigator.pop(context); // Pop the screen after success
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Assign Doctor')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _doctors.isEmpty
            ? Center(child: CircularProgressIndicator())
            : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 3 / 2,
                ),
                itemCount: _doctors.length,
                itemBuilder: (context, index) {
                  final doctor = _doctors[index];
                  return Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: InkWell(
                      onTap: () => _assignDoctor(doctor['id']),
                      borderRadius: BorderRadius.circular(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: NetworkImage(
                                Methods().getGoogleDriveDirectLink(doctor[
                                        'imageUrl'] ??
                                    "https://i.postimg.cc/nz0YBQcH/Logo-light.png"),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              doctor['name'] ?? 'Unknown',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4),
                            Text(
                              doctor['email'] ?? 'No email provided',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
