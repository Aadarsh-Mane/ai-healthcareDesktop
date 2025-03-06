import 'dart:convert';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/model/getPatientHistory.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DischargedPatientsScreen extends StatefulWidget {
  @override
  _DischargedPatientsScreenState createState() =>
      _DischargedPatientsScreenState();
}

class _DischargedPatientsScreenState extends State<DischargedPatientsScreen> {
  // Variable to hold the data
  DischargedPatientsResponse? dischargedPatientsResponse;
  bool isLoading = true;
  String errorMessage = '';

  // Function to fetch the data from the API
  Future<void> fetchDischargedPatients() async {
    final response =
        await http.get(Uri.parse('${KVM_URL}/doctors/getdischargedPatient'));

    if (response.statusCode == 200) {
      // Parse the response and update the state
      setState(() {
        dischargedPatientsResponse =
            DischargedPatientsResponse.fromJson(jsonDecode(response.body));
        isLoading = false;
      });
    } else {
      // Handle errors
      setState(() {
        errorMessage = 'Failed to load data';
        isLoading = false;
      });
    }
  }

  // Function to download the discharge summary PDF
  Future<void> downloadAndSavePDF(
    String patientId,
    String name,
    String contact,
    String gender,
    String admissionDate,
    String dischargeDate,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${KVM_URL}/generateDischargeSummary'),
        body: {
          'patientId': patientId,
          'name': name,
          'contact': contact,
          'gender': gender,
          'admissionDate': admissionDate,
          'dischargeDate': dischargeDate,
        },
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/discharge_summary_$patientId.pdf');

        // Save the PDF file
        await file.writeAsBytes(bytes);

        print("PDF saved at: ${file.path}");
      } else {
        print('Failed to generate PDF');
      }
    } catch (e) {
      print('Error downloading PDF: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDischargedPatients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Discharged Patients'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : ListView.builder(
                  itemCount:
                      dischargedPatientsResponse?.patientsHistory?.length ?? 0,
                  itemBuilder: (context, index) {
                    final patient =
                        dischargedPatientsResponse?.patientsHistory?[index];

                    return Card(
                      margin: EdgeInsets.all(10),
                      child: ListTile(
                        title: Text('${patient?.name} (${patient?.patientId})'),
                        subtitle: Text(
                            'Discharge Date: ${patient?.dischargeDate?.toLocal().toString()}'),
                        onTap: () {
                          // Call the function to generate and download PDF when a patient is clicked
                          downloadAndSavePDF(
                              patient?.patientId ?? '', // patientId
                              patient?.name ?? '', // name
                              // patient?. ?? '',        // age
                              patient?.contact ?? '', // contact
                              patient?.gender ?? '', // gender
                              // patient?.address ?? '',    // address
                              patient?.admissionDate?.toLocal().toString() ??
                                  '', // admissionDate
                              patient?.dischargeDate?.toLocal().toString() ??
                                  ''); // dischargeDate
                          // patient?.diagnosis ?? '',  // diagnosis);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
