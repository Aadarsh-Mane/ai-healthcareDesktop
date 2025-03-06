import 'dart:convert';

import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FourButtonScreen extends StatelessWidget {
  final String patientId;
  final String admissionId;

  const FourButtonScreen({
    Key? key,
    required this.patientId,
    required this.admissionId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Four Button Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Handle button 1 press
                _fetchDoctorAdvice(context, patientId);
              },
              child: const Text(' Doctor Advice'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _declarationForm(context);
              },
              child: const Text('Declaration Form'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle button 3 press
                print(
                    'Button 3 pressed with patientId: $patientId and admissionId: $admissionId');
              },
              child: const Text('Button 3'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle button 4 press
                print(
                    'Button 4 pressed with patientId: $patientId and admissionId: $admissionId');
              },
              child: const Text('Button 4'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchDoctorAdvice(BuildContext context, patientId) async {
    final url = '${KVM_URL}/reception/doctorSheet/${patientId}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fileLink = data['fileLink'];
        print(fileLink);
        if (fileLink != null) {
          Methods().downloadFile(fileLink, 'doctor_advice.pdf', context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No file link found in the response')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch doctor advice')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _declarationForm(BuildContext context) async {
    final url = 'https://ai-healthcare-as85.onrender.com/reception/declaration';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fileLink = data['fileLink'];
        print("ok $fileLink");
        if (fileLink != null) {
          Methods().downloadFile(fileLink, 'doctor_advice.pdf', context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No file link found in the response')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch doctor advice')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
