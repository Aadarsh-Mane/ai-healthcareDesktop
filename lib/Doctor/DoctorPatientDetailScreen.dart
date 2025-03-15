import 'dart:ffi';

import 'package:doctordesktop/Doctor/AddDiagnosisScreen.dart';
import 'package:doctordesktop/Doctor/AddPrescriptionDialod.dart';
import 'package:doctordesktop/Doctor/AddSymptomsScreen.dart';
import 'package:doctordesktop/Doctor/Animate.dart';
import 'package:doctordesktop/Doctor/DoctorAdmittedPatientScreen.dart';
import 'package:doctordesktop/Doctor/DoctorConsultantScreen.dart';
import 'package:doctordesktop/Doctor/PatientHistoryDetailScreen.dart';
import 'package:doctordesktop/Doctor/Tabs/DiagnosisScreen.dart';
import 'package:doctordesktop/Doctor/Tabs/PatientCheck.dart';
import 'package:doctordesktop/Doctor/Tabs/PatientProfileScreen.dart';
import 'package:doctordesktop/Doctor/Tabs/PrescriptionScreen.dart';
import 'package:doctordesktop/Doctor/Tabs/SymtomsScreen.dart';
import 'package:doctordesktop/Doctor/Tabs/VitalsScreen.dart';
import 'package:doctordesktop/StateProvider.dart';
import 'package:doctordesktop/authProvider/auth_provider.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/colors.dart';
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
const _sectionGradient = LinearGradient(
  colors: [Color(0xFF005F9E), Color(0xFF00B8D4)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
const _primaryGradient = LinearGradient(
  colors: [Color(0xFF005F9E), Color(0xFF00B8D4)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const _textFieldGradient = LinearGradient(
  colors: [Color(0xFF005F9E), Color(0xFF00B8D4)],
  stops: [0, 0.5],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
BoxDecoration _boxDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 6,
        offset: Offset(2, 2),
      ),
    ],
    border: Border.all(color: Colors.grey.shade100),
  );
}

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
    _fetchPrescriptions();
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

  List<DoctorPrescription> _prescriptions = [];

  Future<void> _fetchPrescriptions() async {
    try {
      final prescriptions = await doctor.fetchPrescriptions(
        widget.patient.patientId,
        widget.patient.admissionRecords.first.id,
      );
      setState(() {
        _prescriptions = prescriptions;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching prescriptions: $e')),
      );
    }
  }

  Future<void> _deletePrescription(String id) async {
    try {
      await doctor.deletePrescription(widget.patient.patientId,
          widget.patient.admissionRecords.first.id, id);
      await _fetchPrescriptions();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting prescription: $e')),
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
                  temperature: temperature.text,
                  pulse: pulse.text,
                  bloodPressure: bloodPressure.text,
                  bloodSugarLevel: bloodSugarLevel.text,
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
                  openAddDiagnosisScreen(widget.patient.patientId,
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
                      backgroundColor: AppColors.bgColor,
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
                          // ModeView(modeName: "Hello",),
                          VitalsScreen(
                              patientId: widget.patient.patientId,
                              admissionId:
                                  widget.patient.admissionRecords.first.id),
                          SymptomsScreen(
                              patientId: widget.patient.patientId,
                              admissionId:
                                  widget.patient.admissionRecords.first.id),

                          _buildFollowUpAnd2hrSection(
                              widget.patient.admissionRecords.first.id),
                          // _buildDoctorPrescriptionsSection(),
                          DoctorPrescriptionsScreen(
                              patientId: widget.patient.patientId,
                              admissionId:
                                  widget.patient.admissionRecords.first.id),
                          _buildDoctorConsultingSection(),
                          DiagnosisScreen(
                              patientId:
                                  widget.patient.patientId, // Add this line
                              admissionId:
                                  widget.patient.admissionRecords.first.id),
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
                        openAddDiagnosisScreen(widget.patient.patientId,
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
  // Widget _buildTextField({
  //   required TextEditingController controller,
  //   required String label,
  //   TextInputType? keyboardType,
  //   Function(String)? onChanged,
  // }) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 16.0),
  //     child: TextField(
  //       controller: controller,
  //       keyboardType: keyboardType,
  //       decoration: InputDecoration(
  //         labelText: label,
  //         border: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(8),
  //           borderSide: const BorderSide(color: Colors.teal),
  //         ),
  //         focusedBorder: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(8),
  //           borderSide: const BorderSide(color: Colors.teal, width: 2),
  //         ),
  //       ),
  //       onChanged: onChanged,
  //     ),
  //   );
  // }

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
      _fetchPrescriptions();
    } catch (e) {
      print('Error adding prescription: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildTextField1({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Color(0xFF005F9E)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFF00B8D4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFF005F9E), width: 2),
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.clear, color: Color(0xFF005F9E)),
                  onPressed: () {
                    controller.clear();
                    _fetchMedicineSuggestions(''); // Add this line
                  },
                ),
        ),
        onChanged: (value) {
          _fetchMedicineSuggestions(value);
          onChanged?.call(value);
        },
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            setState(() {
              List<String> medicines = selectedMedicines
                  .split(', ')
                  .where((e) => e.isNotEmpty)
                  .toList();
              if (!medicines.contains(value.trim())) {
                medicines.add(value.trim());
                selectedMedicines = medicines.join(', ');
              }
              medicineNameController.clear();
              medicineSuggestions = []; // Clear suggestions
            });
          }
          onSubmitted?.call(value);
        },
      ),
    );
  }

  Widget _buildPrescriptionLayout() {
    return SizedBox(
      height: 500,
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
              _buildTextField1(
                controller: medicineNameController,
                label: 'Medicine Name',
                onChanged: _fetchMedicineSuggestions,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    setState(() {
                      // Ensure no duplicates
                      List<String> medicines = selectedMedicines
                          .split(', ')
                          .where((e) => e.isNotEmpty)
                          .toList();
                      if (!medicines.contains(value.trim())) {
                        medicines.add(value.trim());
                        selectedMedicines = medicines.join(', ');
                      }
                      medicineNameController.clear();
                    });
                  }
                },
              ),

              if (isLoadingSuggestions) const LinearProgressIndicator(),
              if (medicineSuggestions.isNotEmpty) _buildSuggestionsList(),
              const SizedBox(height: 19),
              // Dosage Fields
              Row(
                children: [
                  _buildDosageField(
                    controller: morningDosageController,
                    label: 'Morning Dosage',
                  ),
                  const SizedBox(width: 10),
                  _buildDosageField(
                    controller: afternoonDosageController,
                    label: 'Afternoon Dosage',
                  ),
                  const SizedBox(width: 10),
                  _buildDosageField(
                    controller: nightDosageController,
                    label: 'Night Dosage',
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Comment',
                        labelStyle: TextStyle(color: Color(0xFF005F9E)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFF00B8D4)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Color(0xFF005F9E), width: 2),
                        ),
                      ),
                      controller: commentController,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _buildGradientButton(
                icon: Icons.add,
                onPressed: _addPrescription,
                text: 'Add Prescription',
              ),

              Text(
                'Current Prescriptions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[700],
                ),
              ),
              const SizedBox(height: 10),
              _prescriptions.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('No prescriptions added yet'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _prescriptions.length,
                      itemBuilder: (context, index) {
                        final prescription = _prescriptions[index];
                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 20,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      child: Image.asset(
                                        'assets/images/prescrip.png',
                                        width: 40,
                                        height: 40,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        prescription.medicine.name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal,
                                        ),
                                      ),
                                    ),
                                    _buildDosageDisplay(
                                        'M', prescription.medicine.morning),
                                    const SizedBox(width: 10),
                                    _buildDosageDisplay(
                                        'A', prescription.medicine.afternoon),
                                    const SizedBox(width: 10),
                                    _buildDosageDisplay(
                                        'N', prescription.medicine.night),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red),
                                      onPressed: () => _deletePrescription(
                                          prescription.medicine.id!),
                                    ),
                                  ],
                                ),
                                if (prescription.medicine.comment.isNotEmpty)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(top: 8, left: 56),
                                    child: Text(
                                      'Note: ${prescription.medicine.comment}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDosageField({
    required TextEditingController controller,
    required String label,
  }) {
    return Container(
      width: 60, // Compact size for small numbers
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004E92), Color(0xFF00A6FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(-2, -2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Colors.grey.shade500,
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white, // Ensure text contrasts with gradient
        ),
        decoration: InputDecoration(
          hintText: label.substring(0, 1),
          hintStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDosageDisplay(String time, String dosage) {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(-2, -2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Colors.grey.shade500,
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            time,
            style: TextStyle(
              color: Colors.teal.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            dosage,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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

  final diagnosisSuggestionsProvider = StateProvider<List<String>>((ref) => []);
  final selectedDiagnosesProvider = StateProvider<List<String>>((ref) => []);
  final isLoadingProvider = StateProvider<bool>((ref) => false);

  Widget buildDiagnosisLayout({
    required String admissionId,
    required String patientId,
    required Future<void> Function(
            String admissionId, String symptomWithDateTime, String patientId)
        addDoctorDiagnosis,
    required void Function(String patientId, String admissionId)
        fetchDoctorDiagnosis,
  }) {
    final TextEditingController symptomsController = TextEditingController();

    Future<void> fetchDiagnosisSuggestions(WidgetRef ref) async {
      ref.read(isLoadingProvider.notifier).state = true;
      try {
        final response = await http
            .get(Uri.parse('$KVM_URL/doctors/getDiagnosis/$patientId'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          ref.read(diagnosisSuggestionsProvider.notifier).state =
              List<String>.from(data['diagnosis'] ?? []);
        }
      } catch (e) {
        ref.read(diagnosisSuggestionsProvider.notifier).state = [];
      } finally {
        ref.read(isLoadingProvider.notifier).state = false;
      }
    }

    return Consumer(
      builder: (context, ref, _) {
        final diagnosisSuggestions = ref.watch(diagnosisSuggestionsProvider);
        final selectedDiagnoses = ref.watch(selectedDiagnosesProvider);
        final isLoading = ref.watch(isLoadingProvider);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: selectedDiagnoses.map((diagnosis) {
                  return Chip(
                    label: Text(diagnosis),
                    backgroundColor: Colors.teal,
                    onDeleted: () {
                      ref.read(selectedDiagnosesProvider.notifier).state =
                          List.from(selectedDiagnoses)..remove(diagnosis);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () => fetchDiagnosisSuggestions(ref),
                  child: const Text('AI Suggestions'),
                ),
              ),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  children: diagnosisSuggestions.map((diagnosis) {
                    return CheckboxListTile(
                      title: Text(diagnosis),
                      value: selectedDiagnoses.contains(diagnosis),
                      onChanged: (bool? value) {
                        final updatedList = List.from(selectedDiagnoses);
                        if (value == true) {
                          updatedList.add(diagnosis);
                        } else {
                          updatedList.remove(diagnosis);
                        }
                        ref.read(selectedDiagnosesProvider.notifier).state =
                            updatedList.cast<String>();
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
              TextField(
                controller: symptomsController,
                decoration: const InputDecoration(
                  labelText: 'Enter diagnosis manually',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final currentDateTime = DateFormat('yyyy-MM-dd hh:mm:ss a')
                        .format(DateTime.now());

                    // Get manually entered diagnosis
                    final manualDiagnosis = symptomsController.text.trim();

                    // Combine selected and manual diagnoses
                    final combinedDiagnoses = [
                          ...selectedDiagnoses,
                          if (manualDiagnosis.isNotEmpty) manualDiagnosis,
                        ].join(', ') +
                        ' Date: $currentDateTime';

                    // Send to backend
                    await addDoctorDiagnosis(
                        admissionId, combinedDiagnoses, patientId);

                    // Refresh diagnoses
                    fetchDoctorDiagnosis(patientId, admissionId);

                    // Clear selections and text field
                    ref.read(selectedDiagnosesProvider.notifier).state = [];
                    symptomsController.clear();
                  },
                  child: const Text('Add Diagnosis'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<String> medicineSuggestions = [];
  String selectedMedicines = ''; // Store as a single string
  bool isLoadingSuggestions = false;

  Future<void> _fetchMedicineSuggestions(String query) async {
    // Clear immediately when query is empty
    if (query.isEmpty) {
      setState(() {
        medicineSuggestions = [];
        isLoadingSuggestions = false;
      });
      return;
    }

    setState(() {
      isLoadingSuggestions = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${KVM_URL}/search?q=$query'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final suggestions = List<String>.from(data['suggestions'] ?? []);

        setState(() {
          medicineSuggestions = suggestions;
          // Only add the query as suggestion if there are no results
          if (medicineSuggestions.isEmpty && query.isNotEmpty) {
            medicineSuggestions = [query];
          }
        });
      } else {
        setState(() {
          medicineSuggestions = [];
        });
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
                List<String> medicines = selectedMedicines
                    .split(', ')
                    .where((e) => e.isNotEmpty)
                    .toList();

                if (!medicines.contains(suggestion)) {
                  medicines.add(suggestion);
                  selectedMedicines = medicines.join(', ');
                }

                medicineNameController.clear();
                medicineSuggestions = [];
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Vitals',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 10),

            // Vitals Fields in Compact Layout
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _buildCompactTextField(
                    controller: temperatureController, label: 'Temperature'),
                _buildCompactTextField(
                    controller: pulseController, label: 'Pulse'),
                _buildCompactTextField(
                    controller: bloodPressureController,
                    label: 'Blood Pressure'),
                _buildCompactTextField(
                    controller: bloodSugarLevelController,
                    label: 'Blood Sugar Level'),
                _buildCompactTextField(
                    controller: otherController, label: 'Others'),
              ],
            ),
            const SizedBox(height: 12),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _clearVitalsFields,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xffff96a8),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Clear',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addVitals,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xffff96a8),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add Vitals',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return SizedBox(
      width: 120,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
      temperature: temperatureController.text,
      pulse: pulseController.text,
      bloodPressure: bloodPressureController.text,
      bloodSugarLevel: bloodSugarLevelController.text,
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
// Add this at the top of your file

  Widget _buildFourSquareLayout(BuildContext context, WidgetRef ref,
      String patientId, String admissionId) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF5F7FA), Color(0xFFE6E9F0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column
                    Expanded(
                      child: Column(
                        children: [
                          _buildSectionContainer(
                            context,
                            _buildOverviewSection1(context, ref),
                            title: 'Patient Overview',
                          ),
                          const SizedBox(height: 16),
                          _buildSectionContainer(
                            context,
                            _buildVitalsLayout(),
                            title: 'Vitals Monitoring',
                          ),
                          SizedBox(
                            height: 16,
                          ),
                          Column(
                            children: [
                              _buildSectionContainer(
                                context,
                                buildDiagnosisLayout(
                                    admissionId: admissionId,
                                    patientId: patientId,
                                    addDoctorDiagnosis:
                                        doctor.addDoctorDiagnosis,
                                    fetchDoctorDiagnosis:
                                        doctor.fetchDoctorDiagnosis),
                                title: 'Diagnosis',
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Right Column
                    Expanded(
                      child: Column(
                        children: [
                          _buildSectionContainer(
                            context,
                            _buildPrescriptionLayout(),
                            title: 'Prescription Management',
                          ),
                          const SizedBox(height: 16),
                          _buildSectionContainer(
                            context,
                            Column(
                              children: [
                                _buildSymptomsLayout(
                                    context, ref, patientId, admissionId),
                                const SizedBox(height: 12),
                                Divider(),
                                // buildDiagnosisLayout(
                                //     admissionId: admissionId,
                                //     patientId: patientId,
                                //     addDoctorDiagnosis:
                                //         doctor.addDoctorDiagnosis,
                                //     fetchDoctorDiagnosis:
                                //         doctor.fetchDoctorDiagnosis),
                              ],
                            ),
                            title: 'Symptoms',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContainer(BuildContext context, Widget child,
      {required String title}) {
    return Container(
      decoration: _boxDecoration(),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: _sectionGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ],
      ),
    );
  }

// Updated button styling in _buildOverviewSection

  Widget _buildGradientButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: _sectionGradient,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(1, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isLoading) Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isLoading
                      ? const SizedBox(
                          width: 60,
                          height: 20,
                          child: CustomLoadingAnimation(),
                        )
                      : Text(
                          text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// BoxDecoration for better UI consistency

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

  void openAddDiagnosisScreen(String patientId, String admissionId) {
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

  Widget _buildOverviewSection1(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 340,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 2.0),
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Info Section
              _buildPatientInfoCard(ref),
              const SizedBox(height: 20),
              Wrap(
                runAlignment: WrapAlignment.spaceEvenly,
                spacing: 4.0, // Horizontal spacing between items
                runSpacing: 4.0, // Vertical spacing between rows

                // mainAxisAlignment: MainAxisAlignment.,
                children: [
                  _buildGradientButton(
                    icon: Icons.details,
                    text: 'View Details',
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => PatientHistoryDetailScreen(
                          patientId: widget.patient.patientId,
                        ),
                      ));
                    },
                  ),
                  _buildGradientButton(
                    icon: Icons.medication,
                    text: 'Generate Prescription',
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      await _fetchDoctorAdvice(
                          context,
                          widget.patient.patientId,
                          widget.patient.admissionRecords.first.id);
                      setState(() => _isLoading = false);
                    },
                    isLoading: _isLoading,
                  ),
                  _buildGradientButton(
                    icon: Icons.local_hospital,
                    text: 'Admit Patient',
                    onPressed: () async =>
                        await _admitPatient(widget.patient, ref, context),
                  ),
                  _buildGradientButton(
                    icon: Icons.science,
                    text: 'Assign to Lab',
                    onPressed: () async =>
                        await _handleAssignLab(context, widget.patient, ref),
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
        ),
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

  PageRouteBuilder _createFallingPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, -1), // Starts from the top
            end: Offset(0, 0), // Ends at the normal position
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut, // Smooth falling effect
          )),
          child: child,
        );
      },
    );
  }

  Widget _buildPatientInfoCard(WidgetRef ref) {
    return Card(
      margin: EdgeInsets.zero, //
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 18,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color.fromARGB(255, 255, 255, 255)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                _createFallingPageRoute(ModeView()),
              );
            },
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Patient Info Title
                  Text(
                    'Patient Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Use Wrap to handle multiple lines for patient details
                  Wrap(
                    spacing: 16.0, // Horizontal spacing between items
                    runSpacing: 8.0, // Vertical spacing between rows
                    children: [
                      // Row 1
                      _buildPatientDetail(
                          'Patient ID', widget.patient.patientId),
                      _buildPatientDetail('Name', widget.patient.name),
                      _buildPatientDetail('Age', widget.patient.age.toString()),

                      // Row 2
                      _buildPatientDetail('Contact', widget.patient.contact),
                      _buildPatientDetail('Gender', widget.patient.gender),
                      _buildPatientDetail('Previous Amt',
                          widget.patient.pendingAmount.toString()),

                      // Row 3
                      _buildPatientDetail('Address', widget.patient.address),
                    ],
                  ),

                  const SizedBox(height: 16),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color(0xFF2A79B4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black,
            ),
            softWrap: true, // Allows text to wrap if it's too long
          ),
        ],
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

  Widget _buildLatestFollowUpSection(String recordId) {
    return FutureBuilder<List<FollowUp>>(
      future: doctor.fetchFollowUps(recordId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Text(''),
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
          ],
        );
      },
    );
  }

  Widget _buildFollowUpAnd2hrSection(String recordId) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Text(
              '4 hrFollow-Ups',
            ),
          ),
          _buildFollowUpSection(recordId),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '2-Hour Follow-Ups',
            ),
          ), // Space between the two sections
          _build2hrFollowUpSection(recordId),
        ],
      ),
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

  Widget _build2hrFollowUpSection(String recordId) {
    return FutureBuilder<List<FollowUp>>(
      future: doctor.fetch2hrFollowUps(recordId),
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
                          child: _build2hrFollowUpTable(followUp),
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
}

@override
Widget _buildFollowUpTable(FollowUp followUp) {
  ScrollController _scrollController = ScrollController();

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
          SizedBox(
            height: 150, // Set a height to ensure visibility
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true, // Makes scrollbar always visible
              trackVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _scrollController,
                child: DataTable(
                  columnSpacing: 30,
                  dataRowHeight: 60,
                  headingRowHeight: 50,
                  border: TableBorder.all(color: Colors.grey.shade300),
                  headingRowColor: MaterialStateProperty.all(Colors.cyan),
                  columns: const [
                    DataColumn(
                        label: Text('Type',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white))),
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
                      DataCell(Text('4-Hour Follow-Up')),
                      DataCell(Text(followUp.date)),
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
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Widget _build2hrFollowUpTable(FollowUp followUp) {
  ScrollController _scrollController = ScrollController();

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
          SizedBox(
            height: 150, // Ensures visibility and proper scrolling
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              trackVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _scrollController,
                child: DataTable(
                  columnSpacing: 30,
                  dataRowHeight: 60,
                  headingRowHeight: 50,
                  border: TableBorder.all(color: Colors.grey.shade300),
                  headingRowColor: MaterialStateProperty.all(Colors.cyan),
                  columns: const [
                    DataColumn(
                        label: Text('Type',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white))),
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
                      DataCell(Text(followUp.date)),
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
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
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
