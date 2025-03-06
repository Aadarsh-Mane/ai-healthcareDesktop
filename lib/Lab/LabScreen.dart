import 'dart:io';

import 'package:doctordesktop/StateProvider.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// For picking PDFs or images
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // For picking files (PDF)
import 'dart:io'; // For handling the file
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';

class LabPatientsScreen extends ConsumerStatefulWidget {
  const LabPatientsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LabPatientsScreen> createState() => _LabPatientsScreenState();
}

class _LabPatientsScreenState extends ConsumerState<LabPatientsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch the lab patients when the screen is initialized
    ref.read(labReportNotifierProvider.notifier).fetchLabPatients();

    Future.microtask(() {
      ref.read(labReportNotifierProvider.notifier).fetchLabPatients();
    });
  }

  @override
  Widget build(BuildContext context) {
    final labReportsState = ref.watch(labReportNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab Patients',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
      ),
      body: labReportsState.when(
        data: (labReports) {
          if (labReports.isEmpty) {
            return const Center(
                child: Text('No patients assigned to the lab.'));
          }
          return ListView.builder(
            itemCount: labReports.length,
            itemBuilder: (context, index) {
              final report = labReports[index];
              final patient = report.patient;
              final doctor = report.doctor;

              return GestureDetector(
                onTap: () {
                  // Navigate to the Add Lab Report screen, passing necessary data
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddLabReportScreen(
                        admissionId: report.admissionId ?? 'N/A',
                        patientId: report.patient?.id ?? 'N/A',
                        labReportId: report.id ?? 'N/A',
                        onReportUploaded: () {
                          // Refresh the lab reports when returning from AddLabReportScreen
                          ref
                              .read(labReportNotifierProvider.notifier)
                              .fetchLabPatients();
                        },
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lab Report ID: ${report.id ?? "N/A"}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.teal),
                        ),
                        Text('Admission ID: ${report.admissionId ?? "N/A"}'),
                        const SizedBox(height: 8),
                        Text(
                          'Patient Details:',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal),
                        ),
                        _buildDetailRow('Name', patient?.name ?? "Unknown"),
                        _buildDetailRow(
                            'Age', patient?.age.toString() ?? "N/A"),
                        _buildDetailRow('Gender', patient?.gender ?? "N/A"),
                        _buildDetailRow('Contact', patient?.contact ?? "N/A"),
                        _buildDetailRow('Discharged',
                            patient?.discharged == true ? "Yes" : "No"),
                        const SizedBox(height: 8),
                        Text(
                          'Doctor Details:',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal),
                        ),
                        _buildDetailRow(
                            'Name', doctor?.doctorName ?? "Unknown"),
                        _buildDetailRow('Email', doctor?.email ?? "N/A"),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          'Lab Test Name Given by Doctor',
                          report.labTestNameGivenByDoctor ?? "N/A",
                        ),
                        const SizedBox(height: 8),
                        ExpansionTile(
                          title: Text(
                            'Reports',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.teal),
                          ),
                          children: report.reports != null &&
                                  report.reports!.isNotEmpty
                              ? report.reports!.map((labReport) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildDetailRow('Test Name',
                                            labReport.labTestName ?? "N/A"),
                                        _buildDetailRow(
                                            'Type', labReport.labType ?? "N/A"),
                                        _buildDetailRow(
                                            'Uploaded At',
                                            labReport.uploadedAt
                                                    ?.toLocal()
                                                    .toString() ??
                                                "N/A"),
                                        // GestureDetector(
                                        //   onTap: () async {
                                        //     final url =
                                        //         labReport.reportUrl ?? "";
                                        //     if (await canLaunchUrl(
                                        //         Uri.parse(url))) {
                                        //       await launchUrl(Uri.parse(url),
                                        //           mode: LaunchMode
                                        //               .externalApplication);
                                        //     } else {
                                        //       // You can handle the error or show a message
                                        //       showDialog(
                                        //         context: context,
                                        //         builder: (ctx) => AlertDialog(
                                        //           title: Text('Error'),
                                        //           content: Text(
                                        //               'Could not launch URL: $url'),
                                        //           actions: [
                                        //             TextButton(
                                        //               onPressed: () {
                                        //                 Navigator.of(ctx).pop();
                                        //               },
                                        //               child: Text('OK'),
                                        //             ),
                                        //           ],
                                        //         ),
                                        //       );
                                        //     }
                                        //   },
                                        //   child: Text(
                                        //     labReport.reportUrl ?? "N/A",
                                        //     style: TextStyle(
                                        //       color: Colors.blue,
                                        //       decoration:
                                        //           TextDecoration.underline,
                                        //     ),
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                  );
                                }).toList()
                              : [
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('No reports available'),
                                  ),
                                ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            ref.read(labReportNotifierProvider.notifier).fetchLabPatients(),
        child: const Icon(Icons.refresh),
        backgroundColor: Colors.teal,
      ),
    );
  }

  // Helper function to display details in a consistent way
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style:
                TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

// For HTTP requests

class AddLabReportScreen extends StatefulWidget {
  final String admissionId;
  final String patientId;
  final String labReportId;
  final VoidCallback
      onReportUploaded; // Callback to notify when report is uploaded

  AddLabReportScreen({
    required this.admissionId,
    required this.patientId,
    required this.labReportId,
    required this.onReportUploaded, // Initialize the callback
  });

  @override
  _AddLabReportScreenState createState() => _AddLabReportScreenState();
}

class _AddLabReportScreenState extends State<AddLabReportScreen> {
  final _testNameController = TextEditingController();
  final _testTypeController = TextEditingController();
  File? _selectedFile;

  String? labTestName;
  String? labType;

  // Function to pick PDF file
  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], // Only allow PDF files
    );
    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  // Function to upload the lab report
  Future<void> uploadReport() async {
    if (_selectedFile == null || labTestName == null || labType == null) {
      // Show error if any field is missing
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill in all fields and select a file'),
      ));
      return;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${KVM_URL}/labs/upload-lab-report'), // Your backend URL
    );

    // Add fields
    request.fields['admissionId'] = widget.admissionId;
    request.fields['patientId'] = widget.patientId;
    request.fields['labReportId'] = widget.labReportId;
    request.fields['labTestName'] = labTestName!;
    request.fields['labType'] = labType!;

    // Attach the selected file
    request.files.add(await http.MultipartFile.fromPath(
      'image', // Field name in your backend
      _selectedFile!.path,
    ));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        widget.onReportUploaded(); // Notify the parent screen to refresh

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lab report uploaded successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload report')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Lab Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _testNameController,
              decoration: InputDecoration(labelText: 'Test Name'),
              onChanged: (value) {
                setState(() {
                  labTestName = value;
                });
              },
            ),
            TextField(
              controller: _testTypeController,
              decoration: InputDecoration(labelText: 'Test Type'),
              onChanged: (value) {
                setState(() {
                  labType = value;
                });
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: pickFile,
              child: Text('Pick PDF'),
            ),
            if (_selectedFile != null)
              Text('Selected file: ${_selectedFile!.path.split('/').last}'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: uploadReport,
              child: Text('Submit Lab Report'),
            ),
          ],
        ),
      ),
    );
  }
}
