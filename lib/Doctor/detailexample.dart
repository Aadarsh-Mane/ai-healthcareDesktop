import 'dart:ffi';

import 'package:doctordesktop/Doctor/AddPrescriptionDialod.dart';
import 'package:doctordesktop/Doctor/AddSymptomsScreen.dart';
import 'package:doctordesktop/Doctor/Animate.dart';
import 'package:doctordesktop/Doctor/DoctorConsultantScreen.dart';
import 'package:doctordesktop/Doctor/PatientHistoryDetailScreen.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'package:shimmer/shimmer.dart'; // For printing or viewing the PDF

class PatientDetailScreen4 extends StatefulWidget {
  final Patient1 patient;

  const PatientDetailScreen4({Key? key, required this.patient})
      : super(key: key);

  @override
  _PatientDetailScreen2State createState() => _PatientDetailScreen2State();
}

class _PatientDetailScreen2State extends State<PatientDetailScreen4>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false; // Track loading state

  late TabController _tabController;
  int _currentTabIndex = 0; // Track the current tab index
  final doctor = DoctorRepository();
  final TextEditingController _prescriptionController = TextEditingController();
  late Future<List<String>> _prescriptionsFuture;
  @override
  void initState() {
    super.initState();
    // Fetch initial prescriptions
    _refreshConsultations();
    _prescriptionsFuture =
        doctor.fetchConsultant(widget.patient.admissionRecords.first.id);
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || !_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  void _refreshConsultations() {
    setState(() {
      doctor.fetchDoctorConsultant(
          widget.patient.patientId, widget.patient.admissionRecords.first.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addConsultant(
      String patientId, String admissionId, String consultant) async {
    final url = Uri.parse('${KVM_URL}/doctors/addConsultant');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    final body = {
      "patientId": patientId,
      "admissionId": admissionId,
      "prescription": consultant,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );
      print(response.body);
      if (response.statusCode == 200) {
        // Prescription added successfully
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Prescription added successfully!')),
        );

        // Refresh the prescriptions
        setState(() {
          _prescriptionsFuture = doctor.fetchConsultant(admissionId);
        });
      } else {
        throw Exception('Failed to add prescription: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _openAddSymptomsByDoctorDialog(String admissionId) {
    final TextEditingController _symptomsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Symptoms by Doctor'),
          content: TextField(
            controller: _symptomsController,
            decoration: const InputDecoration(
              labelText: 'Enter symptom',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newSymptom = _symptomsController.text.trim();
                if (newSymptom.isNotEmpty) {
                  // Get current date
                  final String currentDateTime =
                      DateFormat('yyyy-MM-dd hh:mm:ss a')
                          .format(DateTime.now());

                  // Append date and time to the symptom
                  final String symptomWithDateTime =
                      '$newSymptom Date: $currentDateTime';

                  // Call the API with the appended symptom
                  await doctor.addSymptomsByDoctor(
                    admissionId,
                    symptomWithDateTime,
                    widget.patient.patientId,
                  );

                  setState(() {
                    doctor.fetchSymptomsByDoctor(
                      widget.patient.patientId,
                      admissionId,
                    );
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _openAddDiagnosisDialog(String admissionId) {
    final TextEditingController _symptomsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Diagnosis by Doctor'),
          content: TextField(
            controller: _symptomsController,
            decoration: const InputDecoration(
              labelText: 'Enter diagnosis',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newSymptom = _symptomsController.text.trim();
                if (newSymptom.isNotEmpty) {
                  // Get current date
                  final String currentDateTime =
                      DateFormat('yyyy-MM-dd hh:mm:ss a')
                          .format(DateTime.now());

                  // Append date and time to the symptom
                  final String symptomWithDateTime =
                      '$newSymptom Date: $currentDateTime';

                  // Call the API with the appended symptom
                  await doctor.addDoctorDiagnosis(
                    admissionId,
                    symptomWithDateTime,
                    widget.patient.patientId,
                  );

                  setState(() {
                    doctor.fetchDoctorDiagnosis(
                      widget.patient.patientId,
                      admissionId,
                    );
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _openAddPrescriptionDialog(String patientId, String admissionId) {
    final medicineNameController = TextEditingController();
    final morningController = TextEditingController();
    final afternoonController = TextEditingController();
    final nightController = TextEditingController();
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Prescription'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: medicineNameController,
                decoration: const InputDecoration(labelText: 'Medicine Name'),
              ),
              TextField(
                controller: morningController,
                decoration: const InputDecoration(labelText: 'Morning Dosage'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: afternoonController,
                decoration:
                    const InputDecoration(labelText: 'Afternoon Dosage'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: nightController,
                decoration: const InputDecoration(labelText: 'Night Dosage'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(labelText: 'Comment'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final medicine = Medicine(
                  name: medicineNameController.text,
                  morning: morningController.text,
                  afternoon: afternoonController.text,
                  night: nightController.text,
                  comment: commentController.text,
                );

                final doctorPrescription =
                    DoctorPrescription(medicine: medicine);

                try {
                  await doctor.addPrescription(
                      patientId, admissionId, doctorPrescription);

                  // Refresh the data after adding the prescription
                  setState(() {
                    doctor.fetchPrescriptions(patientId, admissionId);
                  });

                  Navigator.of(context).pop(); // Close the dialog
                } catch (e) {
                  print('Error adding prescription: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Add Prescription'),
            ),
          ],
        );
      },
    );
  }

  void _openAddVitalsDialog(String patientId, String admissionId) {
    final temperature = TextEditingController();
    final pulse = TextEditingController();
    final bloodPressure = TextEditingController();
    final bloodSugarLevel = TextEditingController();
    final other = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Vitals'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: temperature,
                decoration: const InputDecoration(labelText: 'Temperature '),
              ),
              TextField(
                controller: pulse,
                decoration: const InputDecoration(labelText: 'Pulse'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: bloodPressure,
                decoration: const InputDecoration(labelText: 'Blood Pressure'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: bloodSugarLevel,
                decoration: const InputDecoration(labelText: 'Sugar Level'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: other,
                decoration: const InputDecoration(labelText: 'Others'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final String currentDateTime =
                    DateFormat('yyyy-MM-dd hh:mm:ss a').format(DateTime.now());

                // Append the current date and time to the 'other' field, placing it on a new line
                final String otherWithDateTime =
                    '${other.text}\nDate: $currentDateTime';
                final vitals = Vitals(
                  temperature: temperature.text,
                  pulse: pulse.text,
                  bloodPressure: bloodPressure.text,
                  bloodSugarLevel: bloodSugarLevel.text,
                  other: otherWithDateTime,
                );

                try {
                  await doctor.addVitals(patientId, admissionId, vitals);

                  // Refresh the data after adding the prescription
                  setState(() {
                    doctor.fetchVitals(patientId, admissionId);
                  });

                  Navigator.of(context).pop(); // Close the dialog
                } catch (e) {
                  print('Error adding prescription: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Add Prescription'),
            ),
          ],
        );
      },
    );
  }

  void _openAddDoctorConsultingScreen(String patientId, String admissionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDoctorConsultingScreen(
          patientId: patientId,
          admissionId: admissionId,
        ),
      ),
    ).then((value) {
      if (value != null && value) {
        // Refresh data here
        _refreshConsultations(); // Call the function to refresh consultations

        doctor.fetchDoctorConsultant(patientId, admissionId);
      }
    });
  }

  // void _openAddDoctorConsultingDialog(String patientId, String admissionId) {
  //   final allergiesController = TextEditingController();
  //   final cheifComplaintController = TextEditingController(); // Fixed spelling
  //   final describeAllergiesController = TextEditingController();
  //   final historyOfPresentIllnessController = TextEditingController();
  //   final personalHabitsController = TextEditingController();
  //   final familyHistoryController = TextEditingController();
  //   final menstrualHistoryController = TextEditingController();
  //   final wongBakerController = TextEditingController();
  //   final visualAnalogueController = TextEditingController();
  //   final relevantPreviousInvestigationsController = TextEditingController();
  //   final immunizationHistoryController = TextEditingController();
  //   final pastMedicalHistoryController = TextEditingController();
  //   ;

  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Add Doctor Consulting'),
  //         content: SizedBox(
  //           width: MediaQuery.of(context).size.width * 0.8, // Wider dialog
  //           child: SingleChildScrollView(
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 TextField(
  //                   controller: allergiesController,
  //                   decoration:
  //                       const InputDecoration(labelText: 'Known Allergies'),
  //                 ),
  //                 TextField(
  //                   controller: cheifComplaintController,
  //                   decoration:
  //                       const InputDecoration(labelText: 'Chief Complaint'),
  //                 ),
  //                 TextField(
  //                   controller: describeAllergiesController,
  //                   decoration:
  //                       const InputDecoration(labelText: 'Describe Allergies'),
  //                 ),
  //                 TextField(
  //                   controller: historyOfPresentIllnessController,
  //                   decoration: const InputDecoration(
  //                       labelText: 'History of Present Illness'),
  //                 ),
  //                 TextField(
  //                   controller: personalHabitsController,
  //                   decoration:
  //                       const InputDecoration(labelText: 'Personal Habits'),
  //                 ),
  //                 TextField(
  //                   controller: familyHistoryController,
  //                   decoration:
  //                       const InputDecoration(labelText: 'Family History'),
  //                 ),
  //                 TextField(
  //                   controller: menstrualHistoryController,
  //                   decoration:
  //                       const InputDecoration(labelText: 'Menstrual History'),
  //                 ),
  //                 TextField(
  //                   controller: wongBakerController,
  //                   decoration: const InputDecoration(labelText: 'Wong Baker'),
  //                 ),
  //                 TextField(
  //                   controller: visualAnalogueController,
  //                   decoration:
  //                       const InputDecoration(labelText: 'Visual Analogue'),
  //                 ),
  //                 TextField(
  //                   controller: relevantPreviousInvestigationsController,
  //                   decoration: const InputDecoration(
  //                       labelText: 'Relevant Previous Investigations'),
  //                 ),
  //                 TextField(
  //                   controller: immunizationHistoryController,
  //                   decoration: const InputDecoration(
  //                       labelText: 'Immunization History'),
  //                 ),
  //                 TextField(
  //                   controller: pastMedicalHistoryController,
  //                   decoration: const InputDecoration(
  //                       labelText: 'Past Medical History'),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text('Cancel'),
  //           ),
  //           TextButton(
  //             onPressed: () async {
  //               final consulting = DoctorConsulting(
  //                   allergies: allergiesController.text,
  //                   cheifComplaint: cheifComplaintController.text,
  //                   describeAllergies: describeAllergiesController.text,
  //                   historyOfPresentIllness:
  //                       historyOfPresentIllnessController.text,
  //                   personalHabits: personalHabitsController.text,
  //                   familyHistory: familyHistoryController.text,
  //                   menstrualHistory: menstrualHistoryController.text,
  //                   wongBaker: wongBakerController.text,
  //                   visualAnalogue: visualAnalogueController.text,
  //                   relevantPreviousInvestigations:
  //                       relevantPreviousInvestigationsController.text,
  //                   immunizationHistory: immunizationHistoryController.text,
  //                   pastMedicalHistory: pastMedicalHistoryController.text);

  //               try {
  //                 await doctor.addDoctorConsultant(
  //                     patientId, admissionId, consulting);
  //                 setState(() {
  //                   doctor.fetchDoctorConsultant(patientId, admissionId);
  //                 });
  //                 Navigator.of(context).pop();
  //               } catch (e) {
  //                 print('Error adding consulting: $e');
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   SnackBar(content: Text('Error: $e')),
  //                 );
  //               }
  //             },
  //             child: const Text('Add Doctor Consultant'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  void _openAddConsultantDialog(String patientId, String admissionId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Diagnosis'),
          content: TextField(
            controller: _prescriptionController,
            decoration: InputDecoration(
              labelText: 'Enter Diagnosis',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final prescription = _prescriptionController.text;
                if (prescription.isNotEmpty) {
                  // Add current date and time
                  final now = DateTime.now();
                  final formattedDateTime =
                      '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                  final consultantWithDateTime =
                      '$prescription $formattedDateTime';

                  await _addConsultant(
                      patientId, admissionId, consultantWithDateTime);

                  _prescriptionController.clear();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('consultant cannot be empty!')),
                  );
                }
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  // Future<void> generatePdf(
  //     List<FollowUp> followUps, BuildContext context) async {
  //   final pdf = pw.Document();

  //   pdf.addPage(
  //     pw.MultiPage(
  //       pageFormat: PdfPageFormat.a4,
  //       margin: pw.EdgeInsets.all(32),
  //       build: (pw.Context context) {
  //         return [
  //           // Header Section
  //           pw.Column(
  //             crossAxisAlignment: pw.CrossAxisAlignment.start,
  //             children: [
  //               pw.Text(
  //                 'Tambe Hospital',
  //                 style: pw.TextStyle(
  //                   fontSize: 28,
  //                   fontWeight: pw.FontWeight.bold,
  //                   color: PdfColors.teal,
  //                 ),
  //               ),
  //               pw.SizedBox(height: 10),
  //               pw.Text(
  //                 'Patient Follow-Up Report',
  //                 style: pw.TextStyle(
  //                   fontSize: 24,
  //                   fontWeight: pw.FontWeight.bold,
  //                 ),
  //               ),
  //               pw.Divider(thickness: 1.5, color: PdfColors.teal),
  //               pw.SizedBox(height: 10),
  //               pw.Text(
  //                 'Patient Name: ${widget.patient.name}',
  //                 style: pw.TextStyle(
  //                   fontSize: 16,
  //                   fontWeight: pw.FontWeight.bold,
  //                 ),
  //               ),
  //               pw.Text(
  //                 'Report Generated: ${DateFormat('dd/MM/yyyy, HH:mm').format(DateTime.now())}',
  //                 style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
  //               ),
  //               pw.SizedBox(height: 20),
  //             ],
  //           ),

  //           // Follow-Ups Section (2-hour fields)
  //           if (followUps.isNotEmpty)
  //             pw.Column(
  //               children: followUps.map((followUp) {
  //                 return pw.Container(
  //                   margin: pw.EdgeInsets.only(bottom: 15),
  //                   padding: pw.EdgeInsets.all(8),
  //                   decoration: pw.BoxDecoration(
  //                     border: pw.Border.all(color: PdfColors.grey400),
  //                     borderRadius: pw.BorderRadius.circular(4),
  //                   ),
  //                   child: pw.Column(
  //                     crossAxisAlignment: pw.CrossAxisAlignment.start,
  //                     children: [
  //                       pw.Text(
  //                         '2hr Fields - Date: ${followUp.date}',
  //                         style: pw.TextStyle(
  //                           fontWeight: pw.FontWeight.bold,
  //                           fontSize: 14,
  //                           color: PdfColors.teal,
  //                         ),
  //                       ),
  //                       pw.Divider(),

  //                       // Table for 2-hour Fields
  //                       pw.Table(
  //                         columnWidths: {
  //                           0: pw.FlexColumnWidth(1),
  //                           1: pw.FlexColumnWidth(2),
  //                         },
  //                         border: pw.TableBorder(
  //                           horizontalInside: pw.BorderSide(
  //                             color: PdfColors.grey300,
  //                             width: 0.5,
  //                           ),
  //                         ),
  //                         children: [
  //                           pw.TableRow(children: [
  //                             pw.Text('Notes:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text(followUp.notes),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('Temperature:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.temperature}°C'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('Oxygen Saturation:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.oxygenSaturation}%'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('Peep/Cap:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.peepCpap}'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('Ie Ratio:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.fiO2}'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('Blood Pressure:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.bloodPressure}'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('Oxygen Saturation:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.oxygenSaturation} %'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('Blood Sugar Level:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.bloodSugarLevel} mg/dL'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('Other Vitals:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.otherVitals}'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('IV Fluid:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.ivFluid} ml'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('Nasogastric:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.nasogastric}'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('RT Feed/Oral:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.rtFeedOral}'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('Total Intake:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.totalIntake} ml'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('CVP:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.cvp} mmHg'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('Urine:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.urine} ml'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('Stool:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.stool}'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('RT Aspirate:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.rtAspirate}'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('Other Output:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.otherOutput}'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('Ventilator Mode:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.ventyMode}'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('Set Rate:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.setRate} bpm'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('FiO2:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.fiO2} %'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('PIP:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.pip} cmH2O'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('PEEP/CPAP:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.peepCpap} cmH2O'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('IE Ratio:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.ieRatio}'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('Other Ventilator Info:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.otherVentilator}'),
  //                           ]),
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                 );
  //               }).toList(),
  //             ),

  //           // Start new page for 4-hour Fields
  //           pw.NewPage(),

  //           // 4-hour Fields Section
  //           if (followUps.isNotEmpty)
  //             pw.Column(
  //               children: followUps.map((followUp) {
  //                 return pw.Container(
  //                   margin: pw.EdgeInsets.only(bottom: 15),
  //                   padding: pw.EdgeInsets.all(8),
  //                   decoration: pw.BoxDecoration(
  //                     border: pw.Border.all(color: PdfColors.grey400),
  //                     borderRadius: pw.BorderRadius.circular(4),
  //                   ),
  //                   child: pw.Column(
  //                     crossAxisAlignment: pw.CrossAxisAlignment.start,
  //                     children: [
  //                       // Date for 4-hour fields
  //                       pw.Text(
  //                         '4hr Fields - Date: ${followUp.date}',
  //                         style: pw.TextStyle(
  //                           fontWeight: pw.FontWeight.bold,
  //                           fontSize: 14,
  //                           color: PdfColors.teal,
  //                         ),
  //                       ),
  //                       pw.Divider(),

  //                       // Table for 4-hour Fields
  //                       pw.Table(
  //                         columnWidths: {
  //                           0: pw.FlexColumnWidth(1),
  //                           1: pw.FlexColumnWidth(2),
  //                         },
  //                         border: pw.TableBorder(
  //                           horizontalInside: pw.BorderSide(
  //                             color: PdfColors.grey300,
  //                             width: 0.5,
  //                           ),
  //                         ),
  //                         children: [
  //                           pw.TableRow(children: [
  //                             pw.Text('4hr Temperature:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.fourhrTemperature}°C'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('4hr Blood Pressure:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.fourhrbloodPressure}'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('4hr IV Fluid:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.fourhrivFluid} ml'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('4hr Pulse:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.fourhrpulse} bpm'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('4hr Oxygen Saturation:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.fourhroxygenSaturation} %'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('4hr Blood Sugar Level:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text(
  //                                 '${followUp.fourhrbloodSugarLevel} mg/dL'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('4hr Other Vitals:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.fourhrotherVitals}'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('4hr Urine:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.fourhrurine} ml'),
  //                           ]),
  //                           pw.TableRow(children: [
  //                             pw.Text('4hr IV Fluid:',
  //                                 style: pw.TextStyle(
  //                                     fontWeight: pw.FontWeight.bold)),
  //                             pw.Text('${followUp.fourhrivFluid} ml'),
  //                           ]),
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                 );
  //               }).toList(),
  //             )
  //           else
  //             pw.Text(
  //               'No follow-up records available.',
  //               style: pw.TextStyle(fontSize: 14, color: PdfColors.red),
  //             ),

  //           // Footer Section
  //           pw.SizedBox(height: 40),
  //           pw.Divider(thickness: 1),
  //           pw.Align(
  //             alignment: pw.Alignment.centerRight,
  //             child: pw.Text(
  //               'Generated on ${DateFormat('dd/MM/yyyy, HH:mm').format(DateTime.now())}',
  //               style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
  //             ),
  //           ),
  //         ];
  //       },
  //     ),
  //   );

  //   // Display the generated PDF
  //   await Printing.layoutPdf(onLayout: (PdfPageFormat format) async {
  //     return pdf.save();
  //   });
  // }

// Reusable section title builder
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }

// Reusable text field builder function
  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.blueGrey[50], // Soft background color
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

// Reusable number input field builder
  Widget _buildNumberInputField(
      TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.blueGrey[50], // Soft background color
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patient.name} Details'),
        backgroundColor: Colors.teal,
        elevation: 5,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Vitals'),
            Tab(text: 'Symptoms'),
            Tab(text: 'Follow Ups'),
            Tab(text: 'Prescription'),
            Tab(text: 'Consultation'),
            Tab(text: 'Diagnosis'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              setState(() {
                doctor.fetchFollowUps(widget.patient.admissionRecords.first.id);
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () async {
              final followUps = await doctor.fetchFollowUps(
                widget.patient.admissionRecords.first.id,
              );
              // generatePdf(followUps, context);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content (TabBarView)
          TabBarView(
            controller: _tabController,
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: _buildOverviewSection(),
              ),
              SingleChildScrollView(
                child: _buildVitalsSection(
                  widget.patient.patientId,
                  widget.patient.admissionRecords.first.id,
                ),
              ),
              SingleChildScrollView(
                child: _buildSymptomsByDoctorSection(
                  widget.patient.patientId,
                  widget.patient.admissionRecords.first.id,
                ),
              ),
              SingleChildScrollView(
                child: _buildFollowUpSection(
                  widget.patient.admissionRecords.first.id,
                ),
              ),
              SingleChildScrollView(
                child: _buildDoctorPrescriptionsSection(),
              ),
              SingleChildScrollView(
                child: _buildDoctorConsultingSection(),
              ),
              SingleChildScrollView(
                child: _buildDoctorDiagnosiSection(
                  widget.patient.admissionRecords.first.id,
                  widget.patient.patientId,
                ),
              ),
            ],
          ),
          // Floating Sidebar
          // Floating Sidebar Widget
          Positioned(
            top: 100, // Adjust based on desired vertical placement
            left: 10, // Slight padding from the screen edge
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSidebarTab(Icons.calendar_today, 'Overview', 0),
                SizedBox(height: 16),
                _buildSidebarTab(Icons.monitor_heart, 'Vitals', 1),
                SizedBox(height: 16),
                _buildSidebarTab(Icons.warning, 'Symptoms', 2),
                SizedBox(height: 16),
                _buildSidebarTab(Icons.follow_the_signs, 'Follow Ups', 3),
                SizedBox(height: 16),
                _buildSidebarTab(Icons.description, 'Prescription', 4),
                SizedBox(height: 16),
                _buildSidebarTab(Icons.chat, 'Consultation', 5),
                SizedBox(height: 16),
                _buildSidebarTab(Icons.local_hospital, 'Diagnosis', 6),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        distance: 100.0,
        type: ExpandableFabType.up,
        children: [
          FloatingActionButton.extended(
            label: Text('Add Diagnosis'),
            heroTag: 'fab1',
            onPressed: () {
              _openAddConsultantDialog(
                widget.patient.patientId,
                widget.patient.admissionRecords.first.id,
              );
            },
          ),
          FloatingActionButton.extended(
            label: Text('Add DoctorConsulting'),
            heroTag: 'fab2',
            onPressed: () {
              _openAddDoctorConsultingScreen(
                widget.patient.patientId,
                widget.patient.admissionRecords.first.id,
              );
            },
          ),
          FloatingActionButton.extended(
            label: Text('Add Prescription'),
            heroTag: 'fab3',
            onPressed: () {
              _openAddPrescriptionScreen(
                widget.patient.patientId,
                widget.patient.admissionRecords.first.id,
              );
            },
          ),
          FloatingActionButton.extended(
            label: Text('Add Vitals'),
            heroTag: 'fab4',
            onPressed: () {
              _openAddVitalsDialog(
                widget.patient.patientId,
                widget.patient.admissionRecords.first.id,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarTab(IconData icon, String label, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _tabController.index = index;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color:
              _tabController.index == index ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            if (_tabController.index == index)
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
          ],
        ),
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: _tabController.index == index
                  ? Colors.transparent
                  : Colors.transparent,
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: _tabController.index == index
                    ? Colors.transparent
                    : Colors.teal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

// Helper function to build floating tabs
  Widget _buildFloatingTab(String title, int index) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: _tabController.index == index ? Colors.teal : Colors.black54,
          fontWeight: _tabController.index == index
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      onTap: () {
        setState(() {
          _tabController.index = index;
        });
      },
    );
  }

  void _openAddPrescriptionScreen(String patientId, String admissionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPrescriptionScreen(
          patientId: patientId,
          admissionId: admissionId,
        ),
      ),
    ).then((value) {
      if (value != null && value) {
        // Refresh data af ter returning from the screen
        setState(() {
          doctor.fetchPrescriptions(patientId, admissionId);
        });
      }
    });
  }

  void _openAddSymptomsScreen(String patientId, String admissionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSymptomScreen(
          patientId: patientId,
          admissionId: admissionId,
        ),
      ),
    ).then((value) {
      if (value != null && value) {
        // Refresh data after returning from the screen
        setState(() {
          doctor.fetchSymptomsByDoctor(patientId, admissionId);
        });
      }
    });
  }

  Widget _buildOverviewSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Info Section
          _buildPatientInfoCard(),
          const SizedBox(height: 20),

          // Admission Records Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Admission Records',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () {
                  // Add functionality for adding a record
                },
                icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
                tooltip: 'Add New Record',
              ),
            ],
          ),
          const Divider(thickness: 1, color: Colors.grey),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _isLoading = true; // Start loading animation
              });

              // Perform the fetch operation
              await _fetchDoctorAdvice(context, widget.patient.patientId,
                  widget.patient.admissionRecords.first.id);

              setState(() {
                _isLoading = false; // Stop loading animation
              });
            },
            child: _isLoading
                ? const CustomLoadingAnimation() // Show loading animation
                : const Text(
                    'Generate Prescription'), // Show button text when not loading
          ),
          // Admission Records List
          if (widget.patient.admissionRecords.isNotEmpty)
            ...widget.patient.admissionRecords.map((record) {
              return _buildAdmissionRecordCard(record);
            }).toList()
          else
            const Center(
              child: Text(
                'No admission records found.',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _fetchDoctorAdvice(
      BuildContext context, patientId, admissionId) async {
    final url =
        '${KVM_URL}/reception/getDoctorAdvice/${patientId}/${admissionId}';
    try {
      final response = await http.get(Uri.parse(url));
      print("body res ${response.body}");
      final data = jsonDecode(response.body);
      final fileLink = data['fileLink'];
      print("working ${fileLink}");
      if (fileLink != null) {
        Methods().openPdf(fileLink);
        // Methods().downloadFile(fileLink, 'doctor_advice.pdf', context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No file link found in the response')),
        );
      }
    } catch (e) {
      print("fuck $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildPatientInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(
                Methods().getGoogleDriveDirectLink(widget.patient.imageUrl),
              ),
              radius: 30,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      widget.patient.name,
                      key: ValueKey(widget.patient.name),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.perm_identity, 'Patient ID',
                      widget.patient.patientId),
                  _buildInfoRow(Icons.cake, 'Age', '${widget.patient.age}'),
                  _buildInfoRow(Icons.male, 'Gender', widget.patient.gender),
                  _buildInfoRow(Icons.phone, 'Contact', widget.patient.contact),
                  _buildInfoRow(Icons.home, 'Address', widget.patient.address),
                  _buildInfoRow(Icons.account_balance_wallet,
                      'Previous Remaining', '${widget.patient.pendingAmount}'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => PatientHistoryDetailScreen(
                          patientId: widget.patient.patientId,
                        ),
                      ));
                    },
                    icon: const Icon(Icons.details),
                    label: const Text('View Patient Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.teal),
          const SizedBox(width: 8),
          Text('$label: ',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdmissionRecordCard(AdmissionRecord record) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_hospital, color: Colors.teal, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Reason: ${record.reasonForAdmission}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_today, 'Date', record.admissionDate),
            _buildInfoRow(Icons.healing, 'Symptoms', record.symptoms),
            _buildInfoRow(Icons.medical_services, 'Initial Diagnosis',
                record.initialDiagnosis),
            const SizedBox(height: 12),
            _buildLatestFollowUpSection(record.id),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: 3, // Show 3 shimmer items for loading
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16.0,
                    width: 150.0,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 16.0,
                    width: 100.0,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 16.0,
                    width: 200.0,
                    color: Colors.grey[300],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSymptomsByDoctorSection(String patientId, String admissionId) {
    return FutureBuilder<List<String>>(
      future: doctor.fetchSymptomsByDoctor(patientId, admissionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text(
            'Error: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          );
        } else if (snapshot.hasData) {
          final symptoms = snapshot.data!;
          print("got the symbol: $admissionId");
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Symptoms by Doctor:',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal),
              ),
              const SizedBox(height: 12),
              if (symptoms.isEmpty)
                const Text(
                  'No symptoms added by the doctor.',
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey),
                )
              else
                // Enhanced DataTable with improved styling
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade400,
                        blurRadius: 10,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: DataTable(
                    columnSpacing: 24,
                    horizontalMargin: 16,
                    columns: const [
                      DataColumn(
                          label: Text(
                        'No.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                          fontSize: 16,
                        ),
                      )),
                      DataColumn(
                          label: Text(
                        'Symptom',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                          fontSize: 16,
                        ),
                      )),
                    ],
                    rows: symptoms
                        .asMap()
                        .map((index, symptom) {
                          return MapEntry(
                            index,
                            DataRow(cells: [
                              DataCell(
                                Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  symptom,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ]),
                          );
                        })
                        .values
                        .toList(),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _openAddSymptomsScreen(patientId, admissionId),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Add Symptom',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 5,
                ),
              ),
            ],
          );
        } else {
          return const Text('No data available');
        }
      },
    );
  }

  Widget _buildDoctorDiagnosiSection(String admissionId, String patientId) {
    return FutureBuilder<List<String>>(
      future: doctor.fetchDoctorDiagnosis(admissionId, patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text(
            'Error: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          );
        } else if (snapshot.hasData) {
          final symptoms = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Diagnosis by Doctor:',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal),
              ),
              const SizedBox(height: 12),
              if (symptoms.isEmpty)
                const Text(
                  'No diagnosis added by the doctor.',
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey),
                )
              else
                // Enhanced DataTable with improved styling
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade400,
                        blurRadius: 10,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: DataTable(
                    columnSpacing: 24,
                    horizontalMargin: 16,
                    columns: const [
                      DataColumn(
                          label: Text(
                        'No.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                          fontSize: 16,
                        ),
                      )),
                      DataColumn(
                          label: Text(
                        'Symptom',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                          fontSize: 16,
                        ),
                      )),
                    ],
                    rows: symptoms
                        .asMap()
                        .map((index, symptom) {
                          return MapEntry(
                            index,
                            DataRow(cells: [
                              DataCell(
                                Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  symptom,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ]),
                          );
                        })
                        .values
                        .toList(),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _openAddDiagnosisDialog(admissionId),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Add Symptom',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 5,
                ),
              ),
            ],
          );
        } else {
          return const Text('No data available');
        }
      },
    );
  }

// Widget _buildVitalsSection(String patientId, String admissionId) {
//   return FutureBuilder<Vitals>(
//     future: fetchVitals(patientId, admissionId),
//     builder: (context, snapshot) {
//       if (snapshot.connectionState == ConnectionState.waiting) {
//         // Show loading indicator while fetching data
//         return CircularProgressIndicator();
//       } else if (snapshot.hasError) {
//         // Show error message if something went wrong
//         return Text('Error: ${snapshot.error}');
//       } else if (!snapshot.hasData) {
//         // Show a message if no data is available
//         return Text('No vitals data available');
//       } else {
//         // Successfully fetched data, display it
//         Vitals vitals = snapshot.data!;
//         return Card(
//           margin: const EdgeInsets.symmetric(vertical: 8.0),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15.0),
//           ),
//           elevation: 6,
//           child: Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Temperature: ${vitals.temperature}°C',
//                     style: const TextStyle(fontSize: 16)),
//                 Text('Pulse: ${vitals.pulse} bpm',
//                     style: const TextStyle(fontSize: 16)),
//                 Text('Other: ${vitals.other}',
//                     style: const TextStyle(fontSize: 16)),
//               ],
//             ),
//           ),
//         );
//       }
//     },
//   );
// }

  Widget _buildLatestFollowUpSection(String recordId) {
    return FutureBuilder<List<FollowUp>>(
      future: doctor.fetchFollowUps(recordId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        var followUps = snapshot.data ?? [];
        if (followUps.isEmpty) {
          return const Text(
            'No follow-ups available.',
            style: TextStyle(fontSize: 14),
          );
        }

        final dateFormat = DateFormat('d/M/yyyy, HH:mm:ss');

        // Sort follow-ups by date (newest first)
        followUps.sort((a, b) {
          final dateA = dateFormat.parse(a.date);
          final dateB = dateFormat.parse(b.date);
          return dateB.compareTo(dateA);
        });
        final latestFollowUp = followUps.first;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Latest Follow-Up:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: 1.0,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date: ${latestFollowUp.date}',
                        style: const TextStyle(fontSize: 14)),
                    Text('Notes: ${latestFollowUp.notes}',
                        style: const TextStyle(fontSize: 14)),
                    Text('Temperature: ${latestFollowUp.temperature}',
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
            // const Text(
            //   'Follow-Ups:',
            //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            // ),
            // const SizedBox(height: 8),
            // ...followUps.map((followUp) {
            //   return Padding(
            //     padding: const EdgeInsets.symmetric(vertical: 4.0),
            //     child: Align(
            //       alignment: Alignment.center, // Center the dropdown
            //       child: Container(
            //         width: 400, // Adjust width for desktop
            //         decoration: BoxDecoration(
            //           borderRadius: BorderRadius.circular(8),
            //           border: Border.all(color: Colors.grey.shade400),
            //           color: Colors.white,
            //         ),
            //         child: ExpansionTile(
            //           title: Text('Date: ${followUp.date}',
            //               style: const TextStyle(fontSize: 14)),
            //           subtitle: Text(
            //               'Time: ${followUp.date.split(',').last.trim()}',
            //               style: const TextStyle(
            //                   fontSize: 12, color: Colors.grey)),
            //           children: [
            //             Padding(
            //               padding: const EdgeInsets.symmetric(horizontal: 16.0),
            //               child: _buildFollowUpTable(followUp),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ),
            //   );
            // }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildFollowUpSection(String recordId) {
    return FutureBuilder<List<FollowUp>>(
      future: doctor.fetchFollowUps(recordId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerEffect();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        var followUps = snapshot.data ?? [];
        if (followUps.isEmpty) {
          return const Text(
            'No follow-ups available.',
            style: TextStyle(fontSize: 14),
          );
        }

        final dateFormat = DateFormat('d/M/yyyy, HH:mm:ss');

        // Sort follow-ups by date (newest first)
        followUps.sort((a, b) {
          final dateA = dateFormat.parse(a.date);
          final dateB = dateFormat.parse(b.date);
          return dateB.compareTo(dateA);
        });
        final latestFollowUp = followUps.first;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Text(
            //   'Latest Follow-Up:',
            //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            // ),
            // AnimatedOpacity(
            //   duration: const Duration(milliseconds: 500),
            //   opacity: 1.0,
            //   child: Padding(
            //     padding:
            //         const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Text('Date: ${latestFollowUp.date}',
            //             style: const TextStyle(fontSize: 14)),
            //         Text('Notes: ${latestFollowUp.notes}',
            //             style: const TextStyle(fontSize: 14)),
            //         Text('Temperature: ${latestFollowUp.temperature}',
            //             style: const TextStyle(fontSize: 14)),
            //       ],
            //     ),
            //   ),
            // ),
            // const Text(
            //   'Follow-Ups:',
            //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            // ),
            const SizedBox(height: 8),
            ...followUps.map((followUp) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Align(
                  alignment: Alignment.center, // Center the dropdown
                  child: Container(
                    width: 900, // Adjust width for desktop
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                      color: Colors.white,
                    ),
                    child: ExpansionTile(
                      title: Text('Date: ${followUp.date}',
                          style: const TextStyle(fontSize: 14)),
                      subtitle: Text(
                          'Time: ${followUp.date.split(',').last.trim()}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _buildFollowUpTable(followUp),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildConsultantSection() {
    return FutureBuilder<List<String>>(
      future: _prescriptionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Error loading prescriptions: ${snapshot.error}',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        final prescriptions = snapshot.data ?? [];
        if (prescriptions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No prescriptions available.',
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: prescriptions.map((prescription) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 2,
              child: ListTile(
                leading: Icon(
                  Icons.medical_services_outlined,
                  color: Colors.teal[600],
                  size: 28,
                ),
                title: Text(
                  'Consultant: $prescription',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDoctorPrescriptionsSection() {
    return FutureBuilder<List<DoctorPrescription>>(
      future: doctor.fetchPrescriptions(
        widget.patient.patientId,
        widget.patient.admissionRecords.first.id,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No prescriptions found.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          );
        }

        // Prescriptions are available
        final prescriptions = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true, // Ensures it doesn't cause layout issues
          physics: const NeverScrollableScrollPhysics(), // Avoid nested scroll
          itemCount: prescriptions.length,
          itemBuilder: (context, index) {
            final prescription = prescriptions[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medicine: ${prescription.medicine.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Morning: ${prescription.medicine.morning}'),
                    Text('Afternoon: ${prescription.medicine.afternoon}'),
                    Text('Night: ${prescription.medicine.night}'),
                    if (prescription.medicine.comment.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Comment: ${prescription.medicine.comment}',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    Text('Date ${prescription.medicine.date}')
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDoctorConsultingSection() {
    return FutureBuilder<List<DoctorConsulting>>(
      future: doctor.fetchDoctorConsultant(
        widget.patient.patientId,
        widget.patient.admissionRecords.first.id,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No consulting data found.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          );
        }

        final doctorConsulting = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var doctorConsult in doctorConsulting)
              _buildExpandableSection(doctorConsult),
          ],
        );
      },
    );
  }

  Widget _buildExpandableSection(DoctorConsulting doctorConsult) {
    bool _isExpanded = false; // Local state for each section.

    return StatefulBuilder(
      builder: (context, setState) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Date: ${doctorConsult.date}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isExpanded)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildTable(doctorConsult),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTable(DoctorConsulting doctorConsult) {
    return Table(
      border: TableBorder.all(
        color: Colors.teal.withOpacity(0.3),
        width: 1,
      ),
      columnWidths: {
        0: FixedColumnWidth(200),
        1: FlexColumnWidth(),
      },
      children: [
        _buildTableRow('Date Added', doctorConsult.date),
        _buildTableRow('Allergies', doctorConsult.allergies),
        _buildTableRow('Known Allergies', doctorConsult.allergies),
        _buildTableRow('Chief Complaint', doctorConsult.cheifComplaint),
        _buildTableRow('Describe Allergies', doctorConsult.describeAllergies),
        _buildTableRow('History of Present Illness',
            doctorConsult.historyOfPresentIllness),
        _buildTableRow('Personal Habits', doctorConsult.personalHabits),
        _buildTableRow('Family History', doctorConsult.familyHistory),
        _buildTableRow('Menstrual History', doctorConsult.menstrualHistory),
        _buildTableRow('Wong Baker', doctorConsult.wongBaker),
        _buildTableRow('Visual Analogue', doctorConsult.visualAnalogue),
        _buildTableRow('Previous Investigations',
            doctorConsult.relevantPreviousInvestigations),
        _buildTableRow(
            'Immunization History', doctorConsult.immunizationHistory),
        _buildTableRow(
            'Past Medical History', doctorConsult.pastMedicalHistory),
      ],
    );
  }

  TableRow _buildTableRow(String title, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.teal,
              fontSize: 16,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value.isNotEmpty ? value : 'N/A',
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailText(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.teal,
            size: 20.0,
          ),
          SizedBox(width: 8.0),
          Text(
            '$title: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.teal,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: TextStyle(fontSize: 16, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsSection(String patientId, String admissionId) {
    return FutureBuilder<List<Vitals>>(
      future: doctor.fetchVitals(patientId, admissionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerEffect(); // Use shimmer effect during loading

          // return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No vitals data available'));
        } else {
          List<Vitals> vitalsList = snapshot.data!;
          return ListView.builder(
            shrinkWrap: true,
            itemCount: vitalsList.length,
            itemBuilder: (context, index) {
              Vitals vitals = vitalsList[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Temperature: ${vitals.temperature}°C',
                          style: TextStyle(fontSize: 16)),
                      Text('Pulse: ${vitals.pulse} bpm',
                          style: TextStyle(fontSize: 16)),
                      Text('BP: ${vitals.bloodPressure} ',
                          style: TextStyle(fontSize: 16)),
                      Text('BSL: ${vitals.bloodSugarLevel} ',
                          style: TextStyle(fontSize: 16)),
                      Text('Other: ${vitals.other}',
                          style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
}

@override
Widget _buildFollowUpTable(FollowUp followUp) {
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15.0),
    ),
    elevation: 4,
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Follow-Up Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 30, // Increased spacing for desktop readability
              dataRowHeight: 60,
              headingRowHeight: 50,
              border: TableBorder.all(color: Colors.grey.shade300),
              headingRowColor: MaterialStateProperty.all(Colors.cyan),
              columns: const [
                DataColumn(
                  label: Text(
                    'Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Temperature')),
                DataColumn(label: Text('Pulse')),
                DataColumn(label: Text('Respiration Rate')),
                DataColumn(label: Text('Blood Pressure')),
                DataColumn(label: Text('Oxygen Saturation')),
                DataColumn(label: Text('Blood Sugar Level')),
                DataColumn(label: Text('Other Vitals')),
                DataColumn(label: Text('IV Fluid')),
                DataColumn(label: Text('Nasogastric')),
                DataColumn(label: Text('RT Feed Oral')),
                DataColumn(label: Text('Total Intake')),
                DataColumn(label: Text('CVP')),
                DataColumn(label: Text('Urine Output')),
                DataColumn(label: Text('Stool')),
                DataColumn(label: Text('RT Aspirate')),
                DataColumn(label: Text('Other Output')),
                DataColumn(label: Text('Ventilator Mode')),
                DataColumn(label: Text('Set Rate')),
                DataColumn(label: Text('FiO2')),
                DataColumn(label: Text('PIP')),
                DataColumn(label: Text('PEEP/CPAP')),
                DataColumn(label: Text('IE Ratio')),
                DataColumn(label: Text('Other Ventilator')),
              ],
              rows: [
                DataRow(cells: [
                  DataCell(Text('2-Hour Follow-Up')),
                  DataCell(Text(
                      followUp.date)), // Adding the Date for 2-hour follow-up

                  DataCell(Text(followUp.temperature.toString())),
                  DataCell(Text(followUp.pulse.toString())),
                  DataCell(Text(followUp.respirationRate.toString())),
                  DataCell(Text(followUp.bloodPressure)),
                  DataCell(Text(followUp.oxygenSaturation.toString())),
                  DataCell(Text(followUp.bloodSugarLevel.toString())),
                  DataCell(Text(followUp.otherVitals)),
                  DataCell(Text(followUp.ivFluid)),
                  DataCell(Text(followUp.nasogastric)),
                  DataCell(Text(followUp.rtFeedOral)),
                  DataCell(Text(followUp.totalIntake)),
                  DataCell(Text(followUp.cvp)),
                  DataCell(Text(followUp.urine)),
                  DataCell(Text(followUp.stool)),
                  DataCell(Text(followUp.rtAspirate)),
                  DataCell(Text(followUp.otherOutput)),
                  DataCell(Text(followUp.ventyMode)),
                  DataCell(Text(followUp.setRate.toString())),
                  DataCell(Text(followUp.fiO2.toString())),
                  DataCell(Text(followUp.pip.toString())),
                  DataCell(Text(followUp.peepCpap)),
                  DataCell(Text(followUp.ieRatio)),
                  DataCell(Text(followUp.otherVentilator)),
                ]),
                DataRow(cells: [
                  DataCell(Text('4-Hour Follow-Up')),
                  DataCell(Text(
                      followUp.date)), // Adding the Date for 2-hour follow-up

                  DataCell(Text(followUp.fourhrTemperature)),
                  DataCell(Text(followUp.fourhrpulse)),
                  DataCell(Text(followUp.respirationRate.toString())),
                  DataCell(Text(followUp.fourhrbloodPressure)),
                  DataCell(Text(followUp.fourhroxygenSaturation)),
                  DataCell(Text(followUp.fourhrbloodSugarLevel)),
                  DataCell(Text(followUp.fourhrotherVitals)),
                  DataCell(Text(followUp.fourhrivFluid)),
                  DataCell(Text(followUp.nasogastric)),
                  DataCell(Text(followUp.rtFeedOral)),
                  DataCell(Text(followUp.totalIntake)),
                  DataCell(Text(followUp.cvp)),
                  DataCell(Text(followUp.fourhrurine)),
                  DataCell(Text(followUp.stool)),
                  DataCell(Text(followUp.rtAspirate)),
                  DataCell(Text(followUp.otherOutput)),
                  DataCell(Text(followUp.ventyMode)),
                  DataCell(Text(followUp.setRate.toString())),
                  DataCell(Text(followUp.fiO2.toString())),
                  DataCell(Text(followUp.pip.toString())),
                  DataCell(Text(followUp.peepCpap)),
                  DataCell(Text(followUp.ieRatio)),
                  DataCell(Text(followUp.otherVentilator)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

DataRow _buildTableRow(String label, String value) {
  return DataRow(
    cells: [
      DataCell(
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
      DataCell(
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            value,
            key: ValueKey(value),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ),
    ],
  );
}
