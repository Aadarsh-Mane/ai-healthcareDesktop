import 'dart:ffi';

import 'package:doctordesktop/Doctor/AddDiagnosisScreen.dart';
import 'package:doctordesktop/Doctor/AddPrescriptionDialod.dart';
import 'package:doctordesktop/Doctor/AddSymptomsScreen.dart';
import 'package:doctordesktop/Doctor/Animate.dart';
import 'package:doctordesktop/Doctor/DoctorAdmittedPatientScreen.dart';
import 'package:doctordesktop/Doctor/DoctorConsultantScreen.dart';
import 'package:doctordesktop/Doctor/PatientHistoryDetailScreen.dart';
import 'package:doctordesktop/StateProvider.dart';
import 'package:doctordesktop/authProvider/auth_provider.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'package:shimmer/shimmer.dart'; // For printing or viewing the PDF

final assignedPatientsProvider =
    StateNotifierProvider<AssignedPatientsNotifier, AsyncValue<List<Patient1>>>(
  (ref) {
    final authRepository = ref.read(authRepositoryProvider);
    final notifier = AssignedPatientsNotifier(authRepository);
    notifier.fetchAssignedPatients();
    return notifier;
  },
);

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
  int _selectedTabIndex =
      0; // Define this variable to track the selected tab index.

  final TextEditingController _prescriptionController = TextEditingController();
  late Future<List<String>> _prescriptionsFuture;
  // late FlutterTts _flutterTts;
  // final FlutterTts flutterTts = FlutterTts();

  // Future<void> initializeTts() async {
  //   try {
  //     await flutterTts.setLanguage("en-US");
  //     await flutterTts.setPitch(1.0);
  //   } catch (e) {
  //     print("Error initializing TTS: $e");
  //   }
  // }

  @override
  void initState() {
    super.initState();
    // initializeTts();
    // _flutterTts = FlutterTts();

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
    // _flutterTts.stop();

    super.dispose();
  }

  Future<void> _addConsultant(
      String patientId, String admissionId, String consultant) async {
    final url = Uri.parse('${VERCEL_URL}/doctors/addConsultant');
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

  Future<void> _handleAssignLab(
      BuildContext context, Patient1 patient, WidgetRef ref) async {
    final authRepository = ref.read(authRepositoryProvider);
    final admissionId = await showDialog<String>(
      context: context,
      builder: (context) => SelectAdmissionDialog(
        admissionRecords: patient.admissionRecords,
      ),
    );

    if (admissionId == null) return;

    final labTestNameGivenByDoctor = await showDialog<String>(
      context: context,
      builder: (context) => AssignLabDialog(),
    );

    if (labTestNameGivenByDoctor == null || labTestNameGivenByDoctor.isEmpty) {
      return;
    }

    try {
      final result = await authRepository.assignPatientToLab(
        patientId: patient.id,
        admissionId: admissionId,
        labTestNameGivenByDoctor: labTestNameGivenByDoctor,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );

      ref.refresh(assignedPatientsProvider.notifier).fetchAssignedPatients();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign lab: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _admitPatient(
      Patient1 patient, WidgetRef ref, BuildContext context) async {
    try {
      // Assuming the first admission record's ID is used as the admissionId
      if (patient.admissionRecords.isEmpty) {
        throw Exception('No admission records found for this patient.');
      }

      final admissionId = patient.admissionRecords.first
          .id; // Adjust logic if not using the first record

      final authRepository = ref.read(authRepositoryProvider);
      final result = await authRepository.admitPatient1(
        admissionId: admissionId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Unknown error occurred.'),
          backgroundColor:
              (result['success'] as bool? ?? false) ? Colors.green : Colors.red,
        ),
      );
      ;

      ref.refresh(assignedPatientsProvider.notifier).fetchAssignedPatients();
    } catch (e) {
      print(e);
      String errorMessage = 'Failed to admit patient';

      // If the error is a Map (e.g., JSON), parse it
      if (e is Map) {
        errorMessage = e['message'] ?? 'Unknown error occurred';
      } else if (e is String) {
        // If it's a string, use it directly
        errorMessage = e;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Patient already admitted '),
          backgroundColor: Colors.red,
        ),
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
                  temperature: double.parse(pulse.text.toString()),
                  pulse: int.parse(pulse.text.toString()),
                  bloodPressure: bloodPressure.text,
                  bloodSugarLevel: int.parse(bloodSugarLevel.text.toString()),
                  other: otherWithDateTime,
                );

                try {
                  // print("vital are ${vitals.}");
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
              child: const Text('Add Vitals'),
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

  // void _openAddDiagnosisaDialog(String patientId, String admissionId) {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: Text('Add Diagnosis'),
  //         content: TextField(
  //           controller: _prescriptionController,
  //           decoration: InputDecoration(
  //             labelText: 'Enter Diagnosis',
  //             border: OutlineInputBorder(),
  //           ),
  //           maxLines: 3,
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(context);
  //             },
  //             child: Text('Cancel'),
  //           ),
  //           ElevatedButton(
  //             onPressed: () async {
  //               final prescription = _prescriptionController.text;
  //               if (prescription.isNotEmpty) {
  //                 // Add current date and time
  //                 final now = DateTime.now();
  //                 final formattedDateTime =
  //                     '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  //                 final consultantWithDateTime =
  //                     '$prescription $formattedDateTime';

  //                 await _addConsultant(
  //                     patientId, admissionId, consultantWithDateTime);

  //                 _prescriptionController.clear();
  //                 Navigator.pop(context);
  //               } else {
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   SnackBar(content: Text('consultant cannot be empty!')),
  //                 );
  //               }
  //             },
  //             child: Text('Submit'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return Shortcuts(
          shortcuts: <LogicalKeySet, Intent>{
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyD):
                AddDiagnosisIntent(),
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC):
                AddDoctorConsultingIntent(),
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyP):
                AddPrescriptionIntent(),
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyV):
                AddVitalsIntent(),
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
                AddSymtomsIntent(),
            LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyO):
                ViewOverviewIntent(),
            LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyV):
                ViewVitalsIntent(),
            LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyS):
                ViewSymptomsIntent(),
            LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyF):
                ViewFollowUpsIntent(),
            LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyP):
                ViewPrescriptionIntent(),
            LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyC):
                ViewConsultationIntent(),
            LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyD):
                ViewDiagnosisIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              AddDiagnosisIntent: CallbackAction<AddDiagnosisIntent>(
                onInvoke: (intent) {
                  _openAddDiagnosisScreen(widget.patient.patientId,
                      widget.patient.admissionRecords.first.id);
                  return null;
                },
              ),
              AddDoctorConsultingIntent:
                  CallbackAction<AddDoctorConsultingIntent>(
                onInvoke: (intent) {
                  _openAddDoctorConsultingScreen(widget.patient.patientId,
                      widget.patient.admissionRecords.first.id);
                  return null;
                },
              ),
              AddPrescriptionIntent: CallbackAction<AddPrescriptionIntent>(
                onInvoke: (intent) {
                  _openAddPrescriptionScreen(widget.patient.patientId,
                      widget.patient.admissionRecords.first.id);
                  return null;
                },
              ),
              AddVitalsIntent: CallbackAction<AddVitalsIntent>(
                onInvoke: (intent) {
                  _openAddVitalsDialog(widget.patient.patientId,
                      widget.patient.admissionRecords.first.id);
                  return null;
                },
              ),
              AddSymtomsIntent: CallbackAction<AddSymtomsIntent>(
                onInvoke: (intent) {
                  _openAddSymptomsScreen(widget.patient.patientId,
                      widget.patient.admissionRecords.first.id);
                  return null;
                },
              ),
              ViewOverviewIntent: CallbackAction<ViewOverviewIntent>(
                onInvoke: (intent) {
                  setState(() {
                    _selectedTabIndex = 0;
                    _tabController.animateTo(0);
                  });
                  return null;
                },
              ),
              ViewVitalsIntent: CallbackAction<ViewVitalsIntent>(
                onInvoke: (intent) {
                  setState(() {
                    _selectedTabIndex = 1;
                    _tabController.animateTo(1);
                  });
                  return null;
                },
              ),
              ViewSymptomsIntent: CallbackAction<ViewSymptomsIntent>(
                onInvoke: (intent) {
                  setState(() {
                    _selectedTabIndex = 2;
                    _tabController.animateTo(2);
                  });
                  return null;
                },
              ),
              ViewFollowUpsIntent: CallbackAction<ViewFollowUpsIntent>(
                onInvoke: (intent) {
                  setState(() {
                    _selectedTabIndex = 3;
                    _tabController.animateTo(3);
                  });
                  return null;
                },
              ),
              ViewPrescriptionIntent: CallbackAction<ViewPrescriptionIntent>(
                onInvoke: (intent) {
                  setState(() {
                    _selectedTabIndex = 4;
                    _tabController.animateTo(4);
                  });
                  return null;
                },
              ),
              ViewConsultationIntent: CallbackAction<ViewConsultationIntent>(
                onInvoke: (intent) {
                  setState(() {
                    _selectedTabIndex = 5;
                    _tabController.animateTo(5);
                  });
                  return null;
                },
              ),
              ViewDiagnosisIntent: CallbackAction<ViewDiagnosisIntent>(
                onInvoke: (intent) {
                  setState(() {
                    _selectedTabIndex = 6;
                    _tabController.animateTo(6);
                  });
                  return null;
                },
              ),
            },
            child: Focus(
              autofocus: true,
              child: Scaffold(
                appBar: AppBar(
                  title: Text('${widget.patient.name} Details'),
                  backgroundColor: Colors.teal,
                  elevation: 5,
                ),
                body: Row(
                  children: [
                    // Sidebar
                    NavigationRail(
                      selectedIndex: _selectedTabIndex,
                      onDestinationSelected: (index) {
                        setState(() {
                          _selectedTabIndex = index;
                          _tabController.animateTo(index);
                        });
                      },
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        NavigationRailDestination(
                          icon: Image.asset(
                            'assets/images/okk.png', // Path to your image asset
                            width: 24, // Adjust size as needed
                            height: 24,
                          ),
                          label: Text('Overview'),
                        ),
                        NavigationRailDestination(
                          icon: Image.asset(
                            'assets/images/vitals.png', // Path to your image asset
                            width: 24, // Adjust size as needed
                            height: 24,
                          ),
                          label: Text('Vitals'),
                        ),
                        NavigationRailDestination(
                          icon: Image.asset(
                            'assets/images/symptoms.png', // Path to your image asset
                            width: 24, // Adjust size as needed
                            height: 24,
                          ),
                          label: Text('Symptoms'),
                        ),
                        NavigationRailDestination(
                          icon: Image.asset(
                            'assets/images/chemotherapy.png', // Path to your image asset
                            width: 24, // Adjust size as needed
                            height: 24,
                          ),
                          label: Text('Follow Ups'),
                        ),
                        NavigationRailDestination(
                          icon: Image.asset(
                            'assets/images/medical-folder.png', // Path to your image asset
                            width: 24, // Adjust size as needed
                            height: 24,
                          ),
                          label: Text('Prescription'),
                        ),
                        NavigationRailDestination(
                          icon: Image.asset(
                            'assets/images/coo.png', // Path to your image asset
                            width: 24, // Adjust size as needed
                            height: 24,
                          ),
                          label: Text('Consultation'),
                        ),
                        NavigationRailDestination(
                          icon: Image.asset(
                            'assets/images/diagnostic.png', // Path to your image asset
                            width: 24, // Adjust size as needed
                            height: 24,
                          ),
                          label: const Text('Diagnosis'),
                        ),
                      ],
                    ),

                    // Main Content (Tabs Section)
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // _buildOverviewSection(context, ref),
                          _buildFourSquareLayout(
                              context,
                              ref,
                              widget.patient.patientId,
                              widget.patient.admissionRecords.first.id),
                          _buildVitalsSection(widget.patient.patientId,
                              widget.patient.admissionRecords.first.id),
                          _buildSymptomsByDoctorSection(
                              widget.patient.patientId,
                              widget.patient.admissionRecords.first.id),
                          _buildFollowUpSection(
                              widget.patient.admissionRecords.first.id),
                          _buildDoctorPrescriptionsSection(),
                          _buildDoctorConsultingSection(),
                          _buildDoctorDiagnosiSection(
                              widget.patient.admissionRecords.first.id,
                              widget.patient.patientId),
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
                      label: const Text('Add Diagnosis'),
                      heroTag: 'fab1',
                      onPressed: () {
                        _openAddDiagnosisScreen(widget.patient.patientId,
                            widget.patient.admissionRecords.first.id);
                      },
                    ),
                    FloatingActionButton.extended(
                      label: const Text('Add Doctor Consulting'),
                      heroTag: 'fab2',
                      onPressed: () {
                        _openAddDoctorConsultingScreen(widget.patient.patientId,
                            widget.patient.admissionRecords.first.id);
                      },
                    ),
                    FloatingActionButton.extended(
                      label: const Text('Add Prescription'),
                      heroTag: 'fab3',
                      onPressed: () {
                        _openAddPrescriptionScreen(widget.patient.patientId,
                            widget.patient.admissionRecords.first.id);
                      },
                    ),
                    FloatingActionButton.extended(
                      label: const Text('Add Vitals'),
                      heroTag: 'fab4',
                      onPressed: () {
                        _openAddVitalsDialog(widget.patient.patientId,
                            widget.patient.admissionRecords.first.id);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  final TextEditingController medicineNameController = TextEditingController();
  final TextEditingController morningDosageController = TextEditingController();
  final TextEditingController afternoonDosageController =
      TextEditingController();
  final TextEditingController nightDosageController = TextEditingController();
  final TextEditingController commentController = TextEditingController();
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.teal),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.teal, width: 2),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _addPrescription() async {
    final morningDosage = morningDosageController.text.isEmpty
        ? '0'
        : morningDosageController.text;
    final afternoonDosage = afternoonDosageController.text.isEmpty
        ? '0'
        : afternoonDosageController.text;
    final nightDosage =
        nightDosageController.text.isEmpty ? '0' : nightDosageController.text;
    final medicine = Medicine(
      name: selectedMedicines,
      morning: morningDosage,
      afternoon: afternoonDosage,
      night: nightDosage,
      comment: commentController.text,
    );

    final doctorPrescription = DoctorPrescription(medicine: medicine);

    try {
      await doctor.addPrescription(
        widget.patient.patientId,
        widget.patient.admissionRecords.first.id,
        doctorPrescription,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription added successfully')),
      );

      setState(() {
        selectedMedicines = '';
        morningDosageController.clear();
        afternoonDosageController.clear();
        nightDosageController.clear();
        commentController.clear();
      });
    } catch (e) {
      print('Error adding prescription: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildPrescriptionLayout() {
    return Card(
      elevation: 19,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prescription Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.teal,
                    ),
              ),
              const SizedBox(height: 20),
              // Display selected medicines as chips
              Wrap(
                spacing: 10.0,
                runSpacing: 10.0,
                children: selectedMedicines
                    .split(', ')
                    .map((medicine) => Chip(
                          label: Text(medicine,
                              style: const TextStyle(color: Colors.white)),
                          backgroundColor: Colors.teal,
                          onDeleted: () {
                            setState(() {
                              selectedMedicines = selectedMedicines
                                  .split(', ')
                                  .where((e) => e != medicine)
                                  .join(', ');
                            });
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              // Medicine Name field with suggestion fetching
              _buildTextField(
                controller: medicineNameController,
                label: 'Medicine Name',
                onChanged: _fetchMedicineSuggestions,
              ),
              if (isLoadingSuggestions) const LinearProgressIndicator(),
              if (medicineSuggestions.isNotEmpty) _buildSuggestionsList(),
              const SizedBox(height: 20),
              // Dosage Fields
              _buildTextField(
                controller: morningDosageController,
                label: 'Morning Dosage',
              ),
              _buildTextField(
                controller: afternoonDosageController,
                label: 'Afternoon Dosage',
              ),
              _buildTextField(
                controller: nightDosageController,
                label: 'Night Dosage',
              ),
              _buildTextField(
                controller: commentController,
                label: 'Comment',
              ),
              const SizedBox(height: 20),
              // Submit Button
              ElevatedButton(
                onPressed: _addPrescription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xffff96a8),
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                  // minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Add Prescription',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addDiagnosis(String diagnosis) async {
    final newSymptom = diagnosis.trim();
    if (newSymptom.isNotEmpty) {
      // Get current date and time
      final String currentDateTime =
          DateFormat('yyyy-MM-dd hh:mm:ss a').format(DateTime.now());

      // Append date and time to the symptom
      final String symptomWithDateTime = '$newSymptom Date: $currentDateTime';

      // Call the API with the appended symptom
      await doctor.addDoctorDiagnosis(
        widget.patient.admissionRecords.first.id,
        symptomWithDateTime,
        widget.patient.patientId,
      );

      // Fetch updated diagnosis
      doctor.fetchDoctorDiagnosis(
          widget.patient.patientId, widget.patient.admissionRecords.first.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diagnosis added successfully!')),
      );

      // Clear the input field
      // _addDiagnosis.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diagnosis cannot be empty!')),
      );
    }
  }

  Widget _buildDiagnosisLayout() {
    final TextEditingController diagnosisController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Diagnosis',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.teal,
                ),
          ),
          const SizedBox(height: 20),
          // TextField for entering diagnosis
          TextField(
            controller: diagnosisController,
            decoration: const InputDecoration(
              labelText: 'Diagnosis',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          // Add Diagnosis button
          ElevatedButton(
            onPressed: () async {
              if (diagnosisController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Diagnosis cannot be empty')),
                );
                return;
              }
              // Add diagnosis to patient's admission record
              await _addDiagnosis(diagnosisController.text);

              // Clear TextField
              diagnosisController.clear();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Diagnosis added successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffff96a8), // Button color
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17), // Rounded corners
              ),
            ),
            child: const Text(
              'Add Diagnosis',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  List<String> medicineSuggestions = [];
  String selectedMedicines = ''; // Store as a single string
  bool isLoadingSuggestions = false;

  Future<void> _fetchMedicineSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        medicineSuggestions = [];
      });
      return;
    }

    setState(() {
      isLoadingSuggestions = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${VERCEL_URL}/search?q=$query'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          medicineSuggestions = List<String>.from(data['suggestions'] ?? []);
        });
      } else {
        throw Exception('Failed to fetch suggestions');
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
      setState(() {
        medicineSuggestions = [];
      });
    } finally {
      setState(() {
        isLoadingSuggestions = false;
      });
    }

    if (medicineSuggestions.isEmpty && query.isNotEmpty) {
      setState(() {
        if (!medicineSuggestions.contains(query)) {
          medicineSuggestions = [query];
        }
      });
    }
  }

  Widget _buildSuggestionsList() {
    return Container(
      padding: const EdgeInsets.only(top: 10),
      height: 200,
      child: ListView.builder(
        itemCount: medicineSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = medicineSuggestions[index];
          return ListTile(
            title: Text(suggestion),
            onTap: () {
              setState(() {
                // Add the selected medicine to the list
                if (selectedMedicines.isEmpty) {
                  selectedMedicines = suggestion;
                } else {
                  selectedMedicines += ', ' + suggestion;
                }
                // medicineNameController.clear(); // Clear the input field
                medicineSuggestions = []; // Clear suggestions list
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildVitalsLayout() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title: Add Vitals
              const Text(
                'Add Vitals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 10),

              // Vitals Form Fields
              _buildTextField(
                controller: temperatureController,
                label: 'Temperature',
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                controller: pulseController,
                label: 'Pulse',
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                controller: bloodPressureController,
                label: 'Blood Pressure',
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                controller: bloodSugarLevelController,
                label: 'Blood Sugar Level',
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                controller: otherController,
                label: 'Others',
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 20),

              // Action Buttons (Clear & Add Vitals)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _clearVitalsFields,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xffff96a8), // Button color
                      padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 30),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(17), // Rounded corners
                      ),
                      // minimumSize: const Size(double.infinity, 50), // Ensures button width
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _addVitals,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xffff96a8), // Button color
                      padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 30),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(17), // Rounded corners
                      ),
                      // minimumSize: const Size(double.infinity, 50), // Ensures button width
                    ),
                    child: const Text(
                      'Add Vitals',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  final temperatureController = TextEditingController();
  final pulseController = TextEditingController();
  final bloodPressureController = TextEditingController();
  final bloodSugarLevelController = TextEditingController();
  final otherController = TextEditingController();

  void _clearVitalsFields() {
    temperatureController.clear();
    pulseController.clear();
    bloodPressureController.clear();
    bloodSugarLevelController.clear();
    otherController.clear();
  }

  Future<void> _addVitals() async {
    final String currentDateTime =
        DateFormat('yyyy-MM-dd hh:mm:ss a').format(DateTime.now());

    final String otherWithDateTime =
        '${otherController.text}\nDate: $currentDateTime';

    final vitals = Vitals(
      temperature: double.parse(temperatureController.text),
      pulse: int.parse(pulseController.text),
      bloodPressure: bloodPressureController.text,
      bloodSugarLevel: int.parse(bloodSugarLevelController.text),
      other: otherWithDateTime,
    );

    try {
      await doctor.addVitals(widget.patient.patientId,
          widget.patient.admissionRecords.first.id, vitals);
      setState(() {
        doctor.fetchVitals(
            widget.patient.patientId, widget.patient.admissionRecords.first.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vitals added successfully!')),
      );

      _clearVitalsFields();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding vitals: $e')),
      );
    }
  }

  Widget _buildFourSquareLayout(BuildContext context, WidgetRef ref,
      String patientId, String admissionId) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // Left Column
          Expanded(
            child: Column(
              children: [
                // Top-Left Square (Overview Section)
                // FFB2C0
                // FF96A8
                Expanded(
                  child: Container(
                    child: _buildOverviewSection(context, ref),
                  ),
                ),
                Divider(),
                SizedBox(height: 26),
                // Bottom-Left Square (Vitals Input)
                Expanded(
                  child: Container(
                    // Background color for this section
                    child: _buildVitalsLayout(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 26),
          // Right Column
          Expanded(
            child: Column(
              children: [
                // Top-Right Square (Prescription Layout)
                Expanded(
                  child: Container(
                    // Background color for this section
                    child: _buildPrescriptionLayout(),
                  ),
                ),
                Divider(),
                // Bottom-Right Square (Diagnosis Layout)
                SingleChildScrollView(
                  child: Expanded(
                    child: Container(
                        // Background color f
                        //or this section

                        child: Column(
                      children: [
                        _buildDiagnosisLayout(),
                        _buildSymptomsLayout(
                            context, ref, patientId, admissionId),
                      ],
                    )),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsLayout(BuildContext context, WidgetRef ref,
      String patientId, String admissionId) {
    final TextEditingController symptomController = TextEditingController();
    final List<String> symptomSuggestions = [];
    bool isLoadingSuggestions = false;
    String selectedSymptoms = '';

    Future<void> _fetchSymptomSuggestions(String query) async {
      if (query.isEmpty) {
        return;
      }

      isLoadingSuggestions = true;

      try {
        final response = await http.get(
          Uri.parse('${VERCEL_URL}/search?q=$query'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          symptomSuggestions.clear();
          symptomSuggestions
              .addAll(List<String>.from(data['suggestions'] ?? []));
        }
      } catch (e) {
        print('Error fetching suggestions: $e');
      } finally {
        isLoadingSuggestions = false;
      }
    }

    Future<void> _addSymptom() async {
      if (symptomController.text.isEmpty) return;

      final newSymptom = symptomSuggestions.contains(symptomController.text)
          ? symptomController.text
          : symptomController.text;

      final String currentDateTime =
          DateFormat('yyyy-MM-dd hh:mm:ss a').format(DateTime.now());
      final String fullSymptom = '$newSymptom - $currentDateTime';

      try {
        await doctor.addSymptomsByDoctor(
          widget.patient.admissionRecords.first.id,
          fullSymptom, // Pass the fullSymptom with the date appended
          widget.patient.patientId,
        );

        selectedSymptoms +=
            selectedSymptoms.isEmpty ? fullSymptom : ', $fullSymptom';
        symptomController.clear();
        symptomSuggestions.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Symptom added successfully')),
        );
      } catch (e) {
        print('Error adding symptom: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Symptoms',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.teal,
                ),
          ),
          const SizedBox(height: 20),

          // Display selected symptoms
          if (selectedSymptoms.isNotEmpty)
            Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: selectedSymptoms
                  .split(', ')
                  .map((symptom) => Chip(
                        label: Text(symptom,
                            style: const TextStyle(color: Colors.white)),
                        backgroundColor: Colors.teal,
                        onDeleted: () {
                          selectedSymptoms = selectedSymptoms
                              .split(', ')
                              .where((e) => e != symptom)
                              .join(', ');
                        },
                      ))
                  .toList(),
            ),

          const SizedBox(height: 20),

          // Symptom text field
          TextField(
            controller: symptomController,
            decoration: InputDecoration(
              labelText: 'Symptom Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.teal, width: 2),
              ),
            ),
            onChanged: _fetchSymptomSuggestions,
          ),
          const SizedBox(height: 10),

          // Loading indicator or suggestions
          if (isLoadingSuggestions) const LinearProgressIndicator(),
          if (symptomSuggestions.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: symptomSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = symptomSuggestions[index];
                  return ListTile(
                    title: Text(suggestion),
                    onTap: () {
                      selectedSymptoms += selectedSymptoms.isEmpty
                          ? suggestion
                          : ', $suggestion';
                      symptomController.clear();
                      symptomSuggestions.clear();
                    },
                  );
                },
              ),
            ),

          const SizedBox(height: 20),

          // Add Symptom button
          ElevatedButton(
            onPressed: _addSymptom,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffff96a8), // Button color
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17), // Rounded corners
              ),
            ),
            child: const Text(
              'Add Symptom',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
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

  void _openAddDiagnosisScreen(String patientId, String admissionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDiagnosisDoctorScreen(
          patientId: patientId,
          admissionId: admissionId,
          addDoctorDiagnosis: doctor.addDoctorDiagnosis,
          fetchDoctorDiagnosis: doctor.fetchDoctorDiagnosis,
        ),
      ),
    ).then((value) {
      if (value != null && value) {
        // Refresh data af ter returning from the screen
        setState(() {
          doctor.fetchDoctorDiagnosis(patientId, admissionId);
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

  Widget _buildOverviewSection(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Info Section
          _buildPatientInfoCard(ref),
          const SizedBox(height: 20),

          // Admission Records Header
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     const Text(
          //       'Admission Records',
          //       style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          //     ),
          //     IconButton(
          //       onPressed: () {
          //         // Add functionality for adding a record
          //       },
          //       icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
          //       tooltip: 'Add New Record',
          //     ),
          //   ],
          // ),
          Wrap(
            runAlignment: WrapAlignment.spaceEvenly,
            spacing: 16.0, // Horizontal spacing between items
            runSpacing: 8.0, // Vertical spacing between rows

            // mainAxisAlignment: MainAxisAlignment.,
            children: [
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.deepOrangeAccent, // Cyan background color
                  foregroundColor: Colors.white, // White text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8), // Padding for better appearance
                ),
                child: _isLoading
                    ? const CustomLoadingAnimation() // Show loading animation
                    : const Text(
                        'Generate Prescription'), // Show button text when not loading
              ),
              ElevatedButton(
                onPressed: () async {
                  await _admitPatient(widget.patient, ref, context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.deepPurpleAccent, // Cyan background color
                  foregroundColor: Colors.white, // White text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9), // Padding for better appearance
                ),
                child: const Text(
                  "Admit Patient",
                  style: TextStyle(
                    fontWeight: FontWeight.bold, // Bold text for emphasis
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _handleAssignLab(context, widget.patient, ref);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan, // Cyan background color
                  foregroundColor: Colors.white, // White text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8), // Padding for better appearance
                ),
                child: const Text(
                  "Assign to Lab",
                  style: TextStyle(
                    fontWeight: FontWeight.bold, // Bold text for emphasis
                  ),
                ),
              ),
            ],
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
        '${VERCEL_URL}/reception/getDoctorAdvice/${patientId}/${admissionId}';
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

  Widget _buildPatientInfoCard(WidgetRef ref) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 18,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Patient Info Title
            Text(
              'Patient Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 10),

            // Use Wrap to handle multiple lines for patient details
            Wrap(
              spacing: 16.0, // Horizontal spacing between items
              runSpacing: 8.0, // Vertical spacing between rows
              children: [
                // Row 1
                _buildPatientDetail('Patient ID', widget.patient.patientId),
                _buildPatientDetail('Name', widget.patient.name),
                _buildPatientDetail('Age', widget.patient.age.toString()),

                // Row 2
                _buildPatientDetail('Contact', widget.patient.contact),
                _buildPatientDetail('Gender', widget.patient.gender),
                _buildPatientDetail(
                    'Previous Amt', widget.patient.pendingAmount.toString()),

                // Row 3
                _buildPatientDetail('Address', widget.patient.address),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     _buildActionButton(
            //         'Generate Prescription', Colors.deepOrangeAccent, () {
            //       // Handle Generate Prescription action
            //       print('Generate Prescription tapped');
            //     }),
            //     _buildActionButton('Admit Patient', Colors.deepPurpleAccent,
            //         () {
            //       // Handle Admit Patient action
            //       print('Admit Patient tapped');
            //     }),
            //     _buildActionButton('Assign to Lab', Colors.cyan, () {
            //       // Handle Assign to Lab action
            //       print('Assign to Lab tapped');
            //     }),
            //   ],
            // ),

            const SizedBox(height: 12),

            // View Patient Details Button
            // ElevatedButton.icon(
            //   onPressed: () {
            //     Navigator.of(context).push(MaterialPageRoute(
            //       builder: (context) => PatientHistoryDetailScreen(
            //         patientId: widget.patient.patientId,
            //       ),
            //     ));
            //   },
            //   icon: const Icon(Icons.details),
            //   label: const Text('View Patient Details'),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.teal,
            //     foregroundColor: Colors.white,
            //     padding:
            //         const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientDetail(String label, String value) {
    return Container(
      constraints: BoxConstraints(maxWidth: 150), // Controls the maximum width
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 13),
            softWrap: true, // Allows text to wrap if it's too long
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  // Widget _buildPatientDetail(String label, String value) {
  //   return Container(
  //     width: 100, // Controls the width of the container
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           '$label:',
  //           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
  //         ),
  //         const SizedBox(height: 4),
  //         Text(
  //           value,
  //           style: TextStyle(fontSize: 12),
  //           overflow: TextOverflow.ellipsis, // Handles text overflow
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildActionButton(String label, Color color) {
  //   return ElevatedButton(
  //     onPressed: () async {
  //       // Handle action
  //     },
  //     style: ElevatedButton.styleFrom(
  //       backgroundColor: color,
  //       foregroundColor: Colors.white,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(8),
  //       ),
  //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //     ),
  //     child: Text(
  //       label,
  //       style: TextStyle(fontWeight: FontWeight.bold),
  //     ),
  //   );
  // }

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
              overflow: TextOverflow.ellipsis, // Handling long text
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FutureBuilder<List<String>>(
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
                  onPressed: () =>
                      _openAddSymptomsScreen(patientId, admissionId),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add Symptom',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
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
      ),
    );
  }

  Widget _buildDoctorDiagnosiSection(String admissionId, String patientId) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FutureBuilder<List<String>>(
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
                          'Diagnosis',
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
                  onPressed: () =>
                      _openAddDiagnosisScreen(patientId, admissionId),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add Diagnosis',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
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
      ),
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
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 16),
          // Elevated Button to generate prescription
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _isLoading = true; // Start loading animation
              });

              // Perform the fetch operation
              await _fetchDoctorAdvice(
                context,
                widget.patient.patientId,
                widget.patient.admissionRecords.first.id,
              );

              setState(() {
                _isLoading = false; // Stop loading animation
              });
            },
            child: _isLoading
                ? const CustomLoadingAnimation() // Show loading animation
                : const Text(
                    'Generate Prescription'), // Show button text when not loading
          ),
          SizedBox(height: 16),

          // FutureBuilder for prescriptions
          FutureBuilder<List<DoctorPrescription>>(
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
                physics:
                    const NeverScrollableScrollPhysics(), // Avoid nested scroll
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
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic),
                              ),
                            ),
                          Text('Date: ${prescription.medicine.date}'),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ID: ${prescription.medicine.id}', // Adjusted to show the prescription ID
                                style: const TextStyle(color: Colors.grey),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  // Confirm deletion
                                  final shouldDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title:
                                            const Text('Delete Prescription'),
                                        content: const Text(
                                            'Are you sure you want to delete this prescription?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (shouldDelete ?? false) {
                                    try {
                                      // Call the backend to delete the prescription
                                      await doctor.deletePrescription(
                                        widget.patient.patientId,
                                        widget
                                            .patient.admissionRecords.first.id,
                                        prescription.medicine.id ?? '',
                                      );

                                      // Fetch prescriptions again to refresh UI
                                      setState(() {
                                        doctor.fetchPrescriptions(
                                          widget.patient.patientId,
                                          widget.patient.admissionRecords.first
                                              .id,
                                        );
                                      });
                                    } catch (error) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Failed to delete prescription: $error'),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // Widget _buildDoctorPrescriptionsSection() {
  //   return FutureBuilder<List<DoctorPrescription>>(
  //     future: doctor.fetchPrescriptions(
  //       widget.patient.patientId,
  //       widget.patient.admissionRecords.first.id,
  //     ),
  //     builder: (context, snapshot) {
  //       if (snapshot.connectionState == ConnectionState.waiting) {
  //         return const Center(child: CircularProgressIndicator());
  //       }

  //       if (snapshot.hasError) {
  //         return Padding(
  //           padding: const EdgeInsets.all(16.0),
  //           child: Text(
  //             'Error: ${snapshot.error}',
  //             style: const TextStyle(color: Colors.red, fontSize: 14),
  //           ),
  //         );
  //       }

  //       if (!snapshot.hasData || snapshot.data!.isEmpty) {
  //         return const Padding(
  //           padding: EdgeInsets.all(16.0),
  //           child: Text(
  //             'No prescriptions found.',
  //             style: TextStyle(color: Colors.grey, fontSize: 14),
  //           ),
  //         );
  //       }

  //       // Prescriptions are available
  //       final prescriptions = snapshot.data!;

  //       return ListView.builder(
  //         shrinkWrap: true, // Ensures it doesn't cause layout issues
  //         physics: const NeverScrollableScrollPhysics(), // Avoid nested scroll
  //         itemCount: prescriptions.length,
  //         itemBuilder: (context, index) {
  //           final prescription = prescriptions[index];
  //           return Card(
  //             margin: const EdgeInsets.symmetric(vertical: 8.0),
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(10.0),
  //             ),
  //             elevation: 3,
  //             child: Padding(
  //               padding: const EdgeInsets.all(16.0),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     'Medicine: ${prescription.medicine.name}',
  //                     style: const TextStyle(
  //                       fontSize: 18,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                   const SizedBox(height: 8),
  //                   Text('Morning: ${prescription.medicine.morning}'),
  //                   Text('Afternoon: ${prescription.medicine.afternoon}'),
  //                   Text('Night: ${prescription.medicine.night}'),
  //                   if (prescription.medicine.comment.isNotEmpty)
  //                     Padding(
  //                       padding: const EdgeInsets.only(top: 8.0),
  //                       child: Text(
  //                         'Comment: ${prescription.medicine.comment}',
  //                         style: const TextStyle(fontStyle: FontStyle.italic),
  //                       ),
  //                     ),
  //                   Text('Date ${prescription.medicine.date}'),
  //                   Text('iD ${prescription.medicine.id}')
  //                 ],
  //               ),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

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

class AddDiagnosisIntent extends Intent {}

class AddDoctorConsultingIntent extends Intent {}

class AddPrescriptionIntent extends Intent {}

class AddVitalsIntent extends Intent {}

class AddSymtomsIntent extends Intent {}

class ViewOverviewIntent extends Intent {}

class ViewVitalsIntent extends Intent {}

class ViewSymptomsIntent extends Intent {}

class ViewFollowUpsIntent extends Intent {}

class ViewPrescriptionIntent extends Intent {}

class ViewConsultationIntent extends Intent {}

class ViewDiagnosisIntent extends Intent {}

class AssignLabDialog extends StatefulWidget {
  @override
  _AssignLabDialogState createState() => _AssignLabDialogState();
}

class _AssignLabDialogState extends State<AssignLabDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Assign to Lab',
        style: TextStyle(color: Colors.deepPurple),
      ),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Lab Test Name',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () {
            // Get the current date and time in IST
            final now = DateTime.now()
                .toUtc()
                .add(const Duration(hours: 5, minutes: 30));
            final formattedDate = DateFormat('yyyy-MM-dd h:mm a').format(now);

            // Append the date and time to the test name
            // final updatedTestName = '${_controller.text.trim()} $formattedDate';
            final updatedTestName =
                '${_controller.text.trim()} - $formattedDate';

            Navigator.of(context).pop(updatedTestName);
          },
          child:
              const Text('Assign', style: TextStyle(color: Colors.deepPurple)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the controller to prevent memory leaks
    super.dispose();
  }
}
