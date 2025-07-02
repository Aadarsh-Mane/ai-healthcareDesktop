import 'dart:math';
import 'dart:ui';

import 'package:doctordesktop/Doctor/AddDiagnosisScreen.dart';
import 'package:doctordesktop/Doctor/AddMedicine.dart';
import 'package:doctordesktop/Doctor/AddPrescriptionDialod.dart';
import 'package:doctordesktop/Doctor/AddSymptomsScreen.dart';
import 'package:doctordesktop/Doctor/AdmitNoteDialog.dart';
import 'package:doctordesktop/Doctor/Animate.dart';
import 'package:doctordesktop/Doctor/AssignedPatientScreen.dart';
import 'package:doctordesktop/Doctor/DoctorAdmittedPatientScreen.dart';
import 'package:doctordesktop/Doctor/DoctorConsultantScreen.dart';
import 'package:doctordesktop/Doctor/DoctorMainScreen.dart';
import 'package:doctordesktop/Doctor/DoctorProfile.dart';
import 'package:doctordesktop/Doctor/PatientHistoryDetailScreen.dart';
import 'package:doctordesktop/Doctor/Tabs/AdmissionLabReportScreen.dart';
import 'package:doctordesktop/Doctor/Tabs/CreateInvestigstion.dart';
import 'package:doctordesktop/Doctor/Tabs/DiagnosisScreen.dart';
import 'package:doctordesktop/Doctor/Tabs/GetInvestigation.dart';
import 'package:doctordesktop/Doctor/Tabs/InvestigationScreen.dart';
import 'package:doctordesktop/Doctor/Tabs/PatientCheck.dart';
import 'package:doctordesktop/Doctor/Tabs/PatientInvestigation.dart';
import 'package:doctordesktop/Doctor/Tabs/PatientProfileScreen.dart';
import 'package:doctordesktop/Doctor/Tabs/PrescriptionScreen.dart';
import 'package:doctordesktop/Doctor/Tabs/SymptomsLayout.dart';
import 'package:doctordesktop/Doctor/Tabs/SymtomsScreen.dart';
import 'package:doctordesktop/Doctor/Tabs/TreatMent.dart';
import 'package:doctordesktop/Doctor/Tabs/VitalsScreen.dart';
import 'package:doctordesktop/Doctor/da.dart';
import 'package:doctordesktop/Doctor/doctornote.dart';
import 'package:doctordesktop/Doctor/sub.dart';
import 'package:doctordesktop/StateProvider.dart';
import 'package:doctordesktop/authProvider/auth_provider.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
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
  bool _isNotesExpanded = false;
  bool _showFloatingNotes = false;
  final GlobalKey _notesButtonKey = GlobalKey();
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
    _fetchMedicines();
    // initializeTts();
    // _flutterTts = FlutterTts();

    // Fetch initial prescriptions
    _refreshConsultations();
    _prescriptionsFuture =
        doctor.fetchConsultant(widget.patient.admissionRecords.first.id);
    _tabController = TabController(length: 8, vsync: this);
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

      final admissionId = patient.admissionRecords.first.id;

      // Show our new admission dialog and get the admit note
      final admitNote = await showDialog<String>(
        context: context,
        builder: (context) => AdmitPatientDialog(
          patientName: patient.name,
          onAdmit: (String location) {
            Navigator.of(context).pop(location);
          },
        ),
      );

      // If dialog was dismissed without selecting, return early
      if (admitNote == null) return;

      final authRepository = ref.read(authRepositoryProvider);
      final result = await authRepository.admitPatient1(
        admissionId: admissionId,
        admitNote: admitNote, // Pass the admit note to the repository function
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Unknown error occurred.'),
          backgroundColor:
              (result['success'] as bool? ?? false) ? Colors.green : Colors.red,
        ),
      );

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
                // final String currentDateTime =
                //     DateFormat('yyyy-MM-dd hh:mm:ss a').format(DateTime.now());

                // Append the current date and time to the 'other' field, placing it on a new line
                // final String otherWithDateTime = '${other.text}';
                final vitals = Vitals(
                  temperature: temperature.text,
                  pulse: pulse.text,
                  bloodPressure: bloodPressure.text,
                  bloodSugarLevel: bloodSugarLevel.text,
                  other: other.text,
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
        builder: (context) => EnhancedDoctorConsultingScreen(
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
  //           ),class ViewHomeIntent extends Intent {}
  //         ],
  //       );
  //     },
  //   );
  // }
  bool _isMonitoringSubmenuOpen = false;
  bool _isInvestigationSubmenuOpen = false;

// Add these methods to toggle the submenu visibility
  void _toggleMonitoringSubmenu() {
    setState(() {
      _isMonitoringSubmenuOpen = !_isMonitoringSubmenuOpen;

      // If we're opening the monitoring submenu, close the investigation submenu
      if (_isMonitoringSubmenuOpen) {
        _isInvestigationSubmenuOpen = false;
      }
    });
  }

  void _toggleInvestigationSubmenu() {
    setState(() {
      _isInvestigationSubmenuOpen = !_isInvestigationSubmenuOpen;

      // If we're opening the investigation submenu, close the monitoring submenu
      if (_isInvestigationSubmenuOpen) {
        _isMonitoringSubmenuOpen = false;
      }
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return Shortcuts(
            shortcuts: <LogicalKeySet, Intent>{
              LogicalKeySet(
                      LogicalKeyboardKey.control, LogicalKeyboardKey.keyD):
                  AddDiagnosisIntent(),
              LogicalKeySet(
                      LogicalKeyboardKey.control, LogicalKeyboardKey.keyC):
                  AddDoctorConsultingIntent(),
              LogicalKeySet(
                      LogicalKeyboardKey.control, LogicalKeyboardKey.keyP):
                  AddPrescriptionIntent(),
              LogicalKeySet(
                      LogicalKeyboardKey.control, LogicalKeyboardKey.keyV):
                  AddVitalsIntent(),
              LogicalKeySet(
                      LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
                  AddSymtomsIntent(),
              LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyO):
                  ViewOverviewIntent(),
              LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyM):
                  ViewMonitoringIntent(), // New shortcut for Monitoring section
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
              LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyT):
                  ViewTreatMentIntent(),
              LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyH):
                  ViewHomeIntent(),
              LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyI):
                  ViewInvestigationIntent(), // New shortcut for Investigation section
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                // Original action handlers
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
                // New monitoring intent action
                ViewMonitoringIntent: CallbackAction<ViewMonitoringIntent>(
                  onInvoke: (intent) {
                    // Toggle the monitoring submenu visibility
                    setState(() {
                      // Find the monitoring nav item and toggle its submenu
                      _toggleMonitoringSubmenu();
                    });
                    return null;
                  },
                ),
                // Original tab navigation intents remain the same
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
                ViewTreatMentIntent: CallbackAction<ViewTreatMentIntent>(
                  onInvoke: (intent) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TreatmentDashboard(
                          patientId: widget.patient.patientId,
                          admissionId: widget.patient.admissionRecords.first.id,
                        ),
                      ),
                    );
                    return null;
                  },
                ),
                ViewHomeIntent: CallbackAction<ViewHomeIntent>(
                  onInvoke: (intent) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DoctorHomeScreen(),
                      ),
                    );
                    return null;
                  },
                ),
                // New investigation intent action
                ViewInvestigationIntent:
                    CallbackAction<ViewInvestigationIntent>(
                  onInvoke: (intent) {
                    // Toggle the investigation submenu visibility
                    setState(() {
                      _toggleInvestigationSubmenu();
                    });
                    return null;
                  },
                ),
              },
              child: Focus(
                autofocus: true,
                child: Scaffold(
                  body: Row(
                    children: [
                      // Modern Sidebar

                      Container(
                        width: 300,
                        decoration: BoxDecoration(
                          color: Color(0xFF1E2843), // Deep navy background
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: Offset(3, 0),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            // Enhanced Header with Back Button
                            Stack(
                              children: [
                                // Gradient Background
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 30, horizontal: 20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF2C3E50),
                                        Color(0xFF34495E),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  // Back Button added at the top
                                  child: Column(
                                    children: [
                                      // Back Button Row
                                      Container(
                                        width: double.infinity,
                                        margin: EdgeInsets.only(bottom: 15),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      AssignedPatientsScreen(),
                                                ),
                                              );
                                            },
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 8, horizontal: 12),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.white
                                                        .withOpacity(0.2),
                                                    Colors.white
                                                        .withOpacity(0.1),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.arrow_back_ios_new,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Back to Dashboard',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Original Patient Info Section
                                      Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.3),
                                                width: 3,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 10,
                                                )
                                              ],
                                            ),
                                            child: CircleAvatar(
                                              radius: 40,
                                              backgroundColor:
                                                  Colors.white.withOpacity(0.1),
                                              child: Image.asset(
                                                  'assets/images/icon1.png'),
                                            ),
                                          ),
                                          SizedBox(width: 15),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                widget.patient.name,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              SizedBox(height: 5),
                                              Text(
                                                'Patient ID: ${widget.patient.patientId}',
                                                style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Navigation Items with Improved Design
                            // Navigation Items list in the sidebar's ListView
                            Expanded(
                              child: ListView(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                children: [
                                  // Overview remains as a main item
                                  _buildNavItem(
                                    index: 0,
                                    icon: Icons.dashboard,
                                    label: 'Overview',
                                  ),

                                  // New Monitoring section with subitems
                                  _buildNavItem(
                                    index: 1, // New index for Monitoring
                                    icon: Icons
                                        .monitor_heart_outlined, // Changed icon to represent monitoring
                                    label: 'Monitoring',
                                    hasSubmenu: true,
                                    submenuItems: [
                                      SubmenuItem(
                                        label: 'Vitals',
                                        icon: Icons.favorite,
                                        onTap: () {
                                          setState(() {
                                            _selectedTabIndex = 1;
                                            _tabController.animateTo(1);
                                          });
                                        },
                                      ),
                                      SubmenuItem(
                                        label: 'Symptoms',
                                        icon: Icons.medical_information,
                                        onTap: () {
                                          setState(() {
                                            _selectedTabIndex = 2;
                                            _tabController.animateTo(2);
                                          });
                                        },
                                      ),
                                      SubmenuItem(
                                        label: 'Follow Ups',
                                        icon: Icons.calendar_today,
                                        onTap: () {
                                          setState(() {
                                            _selectedTabIndex = 3;
                                            _tabController.animateTo(3);
                                          });
                                        },
                                      ),
                                      SubmenuItem(
                                        label: 'Prescription',
                                        icon: Icons.medication,
                                        onTap: () {
                                          setState(() {
                                            _selectedTabIndex = 4;
                                            _tabController.animateTo(4);
                                          });
                                        },
                                      ),
                                      SubmenuItem(
                                        label: 'Consultation',
                                        icon: Icons.medical_services,
                                        onTap: () {
                                          setState(() {
                                            _selectedTabIndex = 5;
                                            _tabController.animateTo(5);
                                          });
                                        },
                                      ),
                                      SubmenuItem(
                                        label: 'Diagnosis',
                                        icon: Icons.local_hospital,
                                        onTap: () {
                                          setState(() {
                                            _selectedTabIndex = 6;
                                            _tabController.animateTo(6);
                                          });
                                        },
                                      ),
                                    ],
                                  ),

                                  // Treatment remains as a main item
                                  _buildNavItem(
                                    index: 7,
                                    icon: Icons.healing,
                                    label: 'Treatment',
                                  ),
                                  _buildNavItem(
                                    index: 9,
                                    icon: Icons.biotech,
                                    label: 'Investigation',
                                    hasSubmenu: true,
                                    submenuItems: [
                                      SubmenuItem(
                                        label:
                                            'Investigation Results ${widget.patient.name}',
                                        icon: Icons.science,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PatientInvestigationScreen(
                                                patientId:
                                                    widget.patient.patientId,
                                                admissionId: widget.patient
                                                    .admissionRecords.first.id,
                                              ),
                                              //     DoctorInvestigationScreen(
                                              //   patientId:
                                              //       widget.patient.patientId,
                                              //   admissionId: widget.patient
                                              //       .admissionRecords.first.id,
                                              // ),
                                            ),
                                          );
                                        },
                                      ),
                                      // SubmenuItem(
                                      //   label: 'Investigation lab',
                                      //   icon: Icons.image,
                                      //   onTap: () {
                                      //     Navigator.push(
                                      //       context,
                                      //       MaterialPageRoute(
                                      //         builder: (context) =>
                                      //             InvestigationScreen1(),
                                      //       ),
                                      //     );
                                      //   },
                                      // ),
                                      SubmenuItem(
                                        label:
                                            'Laboratory Results ${widget.patient.name}',
                                        icon: Icons.assignment,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AdmissionLabReportsScreen(
                                                admissionId: widget.patient
                                                    .admissionRecords.first.id,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      SubmenuItem(
                                        label: 'All Investigations',
                                        icon: Icons.dashboard,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  DoctorInvestigationScreen(
                                                patientId:
                                                    widget.patient.patientId,
                                                admissionId: widget.patient
                                                    .admissionRecords.first.id,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  // Home remains as a main item
                                  _buildNavItem(
                                    index: 8,
                                    icon: Icons.home,
                                    label: 'Home',
                                    onCustomTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AssignedPatientsScreen(),
                                        ),
                                      );
                                    },
                                  ),

                                  // Investigation section with subitems remains
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Main Content Area
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Top App Bar with Modern Design
                              Container(
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                      offset: Offset(0, 4),
                                    )
                                  ],
                                  borderRadius: BorderRadius.circular(
                                      12), // Soft rounded corners
                                ),
                                child: Row(
                                  children: [
                                    // Patient Name with Subtle Gradient
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 25),
                                      child: Row(
                                        children: [
                                          // Optional Patient Avatar
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: Color(0xFF1E2843)
                                                .withOpacity(0.1),
                                            child: Text(
                                              widget.patient.name
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                color: Color(0xFF1E2843),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 15),
                                          Text(
                                            '${widget.patient.name} - Patient Details',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1E2843),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Spacer(),

                                    // Advanced Action Buttons with Hover Effects
                                    Row(
                                      children: [
                                        SizedBox(width: 10),

                                        // Settings Button with Tooltip

                                        SizedBox(width: 20),

                                        // User Profile Section
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundImage: NetworkImage(
                                                'https://t4.ftcdn.net/jpg/06/44/40/73/360_F_644407316_3aGuf15OnNGTbCRxRB7rWa7lIkfLqE4L.jpg', // Replace with actual user avatar
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'DocNex', // Current user name
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF1E2843),
                                                  ),
                                                ),
                                                Text(
                                                  'Care', // User role
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(width: 10),
                                            // Dropdown for user actions
                                            PopupMenuButton<String>(
                                              icon: Icon(
                                                Icons.keyboard_arrow_down,
                                                color: Colors.grey.shade700,
                                              ),
                                              itemBuilder:
                                                  (BuildContext context) => [
                                                PopupMenuItem(
                                                  value: 'profile',
                                                  child: Text('Profile'),
                                                ),
                                              ],
                                              onSelected: (String value) {
                                                // Handle user actions
                                                switch (value) {
                                                  case 'profile':
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              DoctorProfileScreen(),
                                                        ));
                                                    // Navigate to profile
                                                    break;
                                                }
                                              },
                                            ),
                                          ],
                                        ),

                                        SizedBox(width: 20),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Main Content (TabBarView)
                              Expanded(
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    // Existing screen implementations remain the same
                                    _buildFourSquareLayout(
                                        context,
                                        ref,
                                        widget.patient.patientId,
                                        widget
                                            .patient.admissionRecords.first.id),
                                    VitalsScreen(
                                        patientId: widget.patient.patientId,
                                        admissionId: widget
                                            .patient.admissionRecords.first.id),
                                    SymptomsScreen(
                                        patientId: widget.patient.patientId,
                                        admissionId: widget
                                            .patient.admissionRecords.first.id),
                                    _buildFollowUpAnd2hrSection(widget
                                        .patient.admissionRecords.first.id),
                                    DoctorPrescriptionsScreen(
                                        patientId: widget.patient.patientId,
                                        admissionId: widget
                                            .patient.admissionRecords.first.id),
                                    _buildDoctorConsultingSection(),
                                    DiagnosisScreen(
                                        patientId: widget.patient.patientId,
                                        admissionId: widget
                                            .patient.admissionRecords.first.id),
                                    TreatmentDashboard(
                                        patientId: widget.patient.patientId,
                                        admissionId: widget
                                            .patient.admissionRecords.first.id)
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  floatingActionButtonLocation: ExpandableFab.location,
                  floatingActionButton: ExpandableFab(
                    distance: 100.0,
                    type: ExpandableFabType.up,
                    children: [
                      // Add Diagnosis - Gradient Red
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE53E3E), Color(0xFFFC8181)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE53E3E).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: FloatingActionButton.extended(
                          label: const Text(
                            'Add Diagnosis',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          icon: const Icon(Icons.medical_information, size: 20),
                          heroTag: 'fab1',
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          onPressed: () {
                            openAddDiagnosisScreen(
                              widget.patient.patientId,
                              widget.patient.admissionRecords.first.id,
                            );
                          },
                        ),
                      ),

                      // Add Doctor Consulting - Gradient Blue
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3182CE), Color(0xFF63B3ED)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3182CE).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: FloatingActionButton.extended(
                          label: const Text(
                            'Add Doctor Consulting',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          icon: const Icon(Icons.supervisor_account, size: 20),
                          heroTag: 'fab2',
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          onPressed: () {
                            _openAddDoctorConsultingScreen(
                              widget.patient.patientId,
                              widget.patient.admissionRecords.first.id,
                            );
                          },
                        ),
                      ),

                      // Add Prescription - Gradient Green
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF38A169), Color(0xFF68D391)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF38A169).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: FloatingActionButton.extended(
                          label: const Text(
                            'Add Prescription',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          icon: const Icon(Icons.medication, size: 20),
                          heroTag: 'fab3',
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          onPressed: () {
                            _openAddPrescriptionScreen(
                              widget.patient.patientId,
                              widget.patient.admissionRecords.first.id,
                            );
                          },
                        ),
                      ),

                      // Add Vitals - Gradient Orange
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFED8936), Color(0xFFFBB040)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFED8936).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: FloatingActionButton.extended(
                          label: const Text(
                            'Add Vitals',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          icon: const Icon(Icons.favorite, size: 20),
                          heroTag: 'fab4',
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          onPressed: () {
                            _openAddVitalsDialog(
                              widget.patient.patientId,
                              widget.patient.admissionRecords.first.id,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ));
      },
    );
  }

// Define a class for submenu items

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    VoidCallback? onCustomTap,
    bool hasSubmenu = false,
    List<SubmenuItem>? submenuItems,
  }) {
    bool isSelected = _selectedTabIndex == index;
    // Use the shared state variables instead of local ones
    bool isSubmenuOpen = false;

    // Determine which submenu state to use based on the index or label
    if (index == 1) {
      // Monitoring section
      isSubmenuOpen = _isMonitoringSubmenuOpen;
    } else if (index == 9) {
      // Investigation section
      isSubmenuOpen = _isInvestigationSubmenuOpen;
    }

    return LayoutBuilder(builder: (context, constraints) {
      // Adjust for different screen widths
      final bool isSmallScreen = constraints.maxWidth < 120;
      final double iconSize = isSmallScreen ? 20 : 24;
      final double fontSize = isSmallScreen ? 12 : 15;
      final double verticalPadding = isSmallScreen ? 6 : 8;
      final double horizontalPadding = isSmallScreen ? 8 : 16;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main Nav Item
          AnimatedContainer(
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInOutQuint,
            margin: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 6 : 10,
                vertical: isSmallScreen ? 4 : 5),
            decoration: BoxDecoration(
              gradient: isSelected || isSubmenuOpen
                  ? LinearGradient(
                      colors: [
                        Colors.white,
                        Colors.white,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected || isSubmenuOpen
                  ? Colors.white.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected || isSubmenuOpen
                    ? Colors.white.withOpacity(0.3)
                    : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: isSelected || isSubmenuOpen
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                // Main Content
                ListTile(
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding, vertical: verticalPadding),

                  // Leading Icon with Animated Container
                  leading: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      color: isSelected || isSubmenuOpen
                          ? Colors.white.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected || isSubmenuOpen
                          ? Colors.white
                          : Colors.white70,
                      size: iconSize,
                    ),
                  ),

                  // Title with responsive sizing
                  title: isSmallScreen
                      ? null
                      : AnimatedDefaultTextStyle(
                          duration: Duration(milliseconds: 300),
                          style: TextStyle(
                            color: isSelected || isSubmenuOpen
                                ? Colors.white
                                : Colors.white70,
                            fontWeight: isSelected || isSubmenuOpen
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: isSelected || isSubmenuOpen
                                ? fontSize + 1
                                : fontSize,
                            letterSpacing:
                                isSelected || isSubmenuOpen ? 0.7 : 0.5,
                          ),
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                  // Trailing icon - chevron for submenu, indicator dot for regular
                  trailing: isSmallScreen
                      ? null
                      : (hasSubmenu
                          ? Icon(
                              isSubmenuOpen
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: isSelected || isSubmenuOpen
                                  ? Colors.white
                                  : Colors.white70,
                              size: 18,
                            )
                          : isSelected
                              ? Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.5),
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                      )
                                    ],
                                  ),
                                )
                              : null),

                  // Tap Action
                  onTap: () {
                    if (hasSubmenu) {
                      if (index == 1) {
                        // Monitoring section
                        _toggleMonitoringSubmenu();
                      } else if (index == 9) {
                        // Investigation section
                        _toggleInvestigationSubmenu();
                      }
                    } else if (onCustomTap != null) {
                      onCustomTap();
                    } else {
                      setState(() {
                        _selectedTabIndex = index;
                        _tabController.animateTo(index);
                      });
                    }
                  },
                ),

                // Footer-like Interaction Layer
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    height: isSelected || isSubmenuOpen ? 5 : 0,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                      ),
                    ),
                  ),
                ),

                // Hover and Interaction Effect
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      splashColor: Colors.white.withOpacity(0.2),
                      highlightColor: Colors.white.withOpacity(0.1),
                      onTap: () {
                        if (hasSubmenu) {
                          if (index == 1) {
                            // Monitoring section
                            _toggleMonitoringSubmenu();
                          } else if (index == 9) {
                            // Investigation section
                            _toggleInvestigationSubmenu();
                          }
                        } else if (onCustomTap != null) {
                          onCustomTap();
                        } else {
                          setState(() {
                            _selectedTabIndex = index;
                            _tabController.animateTo(index);
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Submenu items (conditionally displayed)
          if (hasSubmenu && isSubmenuOpen && submenuItems != null)
            AnimatedContainer(
              duration: Duration(milliseconds: 400),
              curve: Curves.easeOutQuad,
              margin: EdgeInsets.only(left: 20, right: 10),
              child: Column(
                children: submenuItems
                    .map(
                      (item) => Container(
                        margin: EdgeInsets.only(top: 4, bottom: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: Icon(
                            item.icon,
                            color: Colors.white70,
                            size: 18,
                          ),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          onTap: item.onTap,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      );
    });
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
  void _showMedicineSelectionDialog() {
    // Keep a local copy of the selected medicines for the dialog
    String localSelectedMedicines = ''; // Start with empty selection in dialog
    String searchQuery = '';
    List<Medicine> filteredMedicines = List.from(_medicines);
    bool isSearching = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Filter medicines based on search query
          if (searchQuery.isNotEmpty) {
            filteredMedicines = _medicines
                .where((med) =>
                    med.name.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();
            isSearching = true;
          } else {
            filteredMedicines = List.from(_medicines);
            isSearching = false;
          }

          // Get selected medicines count
          final selectedCount = localSelectedMedicines
              .split(', ')
              .where((e) => e.isNotEmpty)
              .length;

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: HospitalTheme.radiusMedium,
            ),
            elevation: 8,
            insetPadding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: HospitalTheme.cardBackground,
                borderRadius: HospitalTheme.radiusMedium,
                boxShadow: HospitalTheme.shadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with gradient background
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          HospitalTheme.primaryDark,
                          HospitalTheme.primary
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.medication,
                            color: HospitalTheme.textOnPrimary, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Medicine Database',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: HospitalTheme.textOnPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close,
                              color: HospitalTheme.textOnPrimary),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search and Add Medicine row
                          Row(
                            children: [
                              // Search field with clear button
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Search Medicines',
                                    hintText: 'Enter medicine name',
                                    prefixIcon: Icon(Icons.search,
                                        color: HospitalTheme.primary),
                                    suffixIcon: searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(Icons.clear,
                                                color: HospitalTheme.primary),
                                            onPressed: () {
                                              setDialogState(() {
                                                searchQuery = '';
                                              });
                                            },
                                          )
                                        : null,
                                    border: OutlineInputBorder(
                                      borderRadius: HospitalTheme.radiusSmall,
                                      borderSide: BorderSide(
                                          color: HospitalTheme.border),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: HospitalTheme.radiusSmall,
                                      borderSide: BorderSide(
                                          color: HospitalTheme.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: HospitalTheme.radiusSmall,
                                      borderSide: BorderSide(
                                          color: HospitalTheme.primary,
                                          width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      searchQuery = value;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 12),
                              // Button to manage medicines
                              ElevatedButton.icon(
                                icon: Icon(Icons.add_box_outlined),
                                label: Text("Add New"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: HospitalTheme.pharmacy,
                                  foregroundColor: HospitalTheme.textOnPrimary,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: HospitalTheme.radiusSmall,
                                  ),
                                ),
                                onPressed: () async {
                                  // Navigate to medicine management screen
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          MedicineManagementScreen(),
                                    ),
                                  );

                                  // Close the current dialog
                                  Navigator.of(context).pop();

                                  // Refresh medicines and reopen the dialog with fresh data
                                  await _fetchMedicines();

                                  // Small delay to ensure data is refreshed
                                  await Future.delayed(
                                      Duration(milliseconds: 300));

                                  // Reopen the dialog with fresh data
                                  _showMedicineSelectionDialog();
                                },
                              ),
                            ],
                          ),

                          // Selection summary with badges and stats
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 16),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  HospitalTheme.surfaceLight.withOpacity(0.7),
                              borderRadius: HospitalTheme.radiusSmall,
                              border: Border.all(color: HospitalTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        HospitalTheme.buildStatusBadge(
                                          '$selectedCount selected',
                                          color: selectedCount > 0
                                              ? HospitalTheme.medical
                                              : HospitalTheme.borderDark,
                                          outline: false,
                                        ),
                                        SizedBox(width: 8),
                                        if (isSearching)
                                          HospitalTheme.buildStatusBadge(
                                            '${filteredMedicines.length} Results',
                                            color: HospitalTheme.info,
                                            outline: true,
                                          ),
                                      ],
                                    ),
                                    if (selectedCount > 0)
                                      TextButton.icon(
                                        icon: Icon(Icons.clear_all,
                                            size: 18,
                                            color: HospitalTheme.warning),
                                        label: Text('Clear All',
                                            style: TextStyle(
                                                color: HospitalTheme.warning)),
                                        onPressed: () {
                                          setDialogState(() {
                                            localSelectedMedicines = '';
                                          });
                                          // No need to update parent state
                                        },
                                      ),
                                  ],
                                ),

                                // Selected medicines display as chips (only inside dialog)
                                if (localSelectedMedicines.isNotEmpty) ...[
                                  Divider(height: 16),
                                  Text(
                                    'Recently Added Medicines:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: HospitalTheme.textMedium,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: localSelectedMedicines
                                        .split(', ')
                                        .where((e) => e.isNotEmpty)
                                        .map((med) => Chip(
                                              label: Text(
                                                med,
                                                style: TextStyle(
                                                  color: HospitalTheme
                                                      .textOnPrimary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              backgroundColor:
                                                  HospitalTheme.medical,
                                              deleteIconColor:
                                                  HospitalTheme.textOnPrimary,
                                              onDeleted: () {
                                                final currentMedicines =
                                                    localSelectedMedicines
                                                        .split(', ')
                                                        .where(
                                                            (e) => e.isNotEmpty)
                                                        .toList();
                                                currentMedicines.remove(med);

                                                setDialogState(() {
                                                  localSelectedMedicines =
                                                      currentMedicines
                                                          .join(', ');
                                                });
                                                // No need to update parent state
                                              },
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Medicines list
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: HospitalTheme.radiusSmall,
                                border: Border.all(color: HospitalTheme.border),
                              ),
                              child: _isLoading
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    HospitalTheme.primary),
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            'Loading medicines...',
                                            style: TextStyle(
                                              color: HospitalTheme.textMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : filteredMedicines.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.medication_outlined,
                                                size: 48,
                                                color: HospitalTheme.textLight,
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                searchQuery.isEmpty
                                                    ? 'No medicines available in database'
                                                    : 'No medicines matching "$searchQuery"',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color:
                                                      HospitalTheme.textMedium,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              if (searchQuery.isNotEmpty) ...[
                                                SizedBox(height: 20),
                                                ElevatedButton.icon(
                                                  icon: Icon(Icons.add),
                                                  label: Text(
                                                      'Add "$searchQuery" to Prescription'),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        HospitalTheme.success,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 20,
                                                            vertical: 12),
                                                  ),
                                                  onPressed: () async {
                                                    // Create a new medicine with default values
                                                    final medicine = Medicine(
                                                      name: searchQuery.trim(),
                                                      morning: "1",
                                                      afternoon: "1",
                                                      night: "1",
                                                      comment: "",
                                                    );

                                                    final doctorPrescription =
                                                        DoctorPrescription(
                                                            medicine: medicine);

                                                    try {
                                                      await doctor
                                                          .addPrescription(
                                                        widget
                                                            .patient.patientId,
                                                        widget
                                                            .patient
                                                            .admissionRecords
                                                            .first
                                                            .id,
                                                        doctorPrescription,
                                                      );

                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              '$searchQuery added to prescription'),
                                                          duration: Duration(
                                                              seconds: 1),
                                                        ),
                                                      );

                                                      _fetchPrescriptions();

                                                      // Update dialog state only
                                                      final currentMedicines =
                                                          localSelectedMedicines
                                                              .split(', ')
                                                              .where((e) =>
                                                                  e.isNotEmpty)
                                                              .toList();

                                                      if (!currentMedicines
                                                          .contains(
                                                              searchQuery)) {
                                                        currentMedicines
                                                            .add(searchQuery);
                                                      }

                                                      setDialogState(() {
                                                        localSelectedMedicines =
                                                            currentMedicines
                                                                .join(', ');
                                                      });
                                                      // No need to update parent state
                                                    } catch (e) {
                                                      print(
                                                          'Error adding prescription: $e');
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                            content: Text(
                                                                'Error: $e')),
                                                      );
                                                    }
                                                  },
                                                ),
                                              ],
                                            ],
                                          ),
                                        )
                                      : ListView.separated(
                                          itemCount: filteredMedicines.length,
                                          separatorBuilder: (context, index) =>
                                              Divider(
                                                  height: 1,
                                                  thickness: 1,
                                                  color: HospitalTheme.border
                                                      .withOpacity(0.5)),
                                          itemBuilder: (context, index) {
                                            final medicine =
                                                filteredMedicines[index];
                                            final isSelected =
                                                localSelectedMedicines
                                                    .split(', ')
                                                    .where((e) => e.isNotEmpty)
                                                    .contains(medicine.name);

                                            return InkWell(
                                              onTap: () async {
                                                final currentMedicines =
                                                    localSelectedMedicines
                                                        .split(', ')
                                                        .where(
                                                            (e) => e.isNotEmpty)
                                                        .toList();

                                                // Toggle selection on tap
                                                if (currentMedicines
                                                    .contains(medicine.name)) {
                                                  currentMedicines
                                                      .remove(medicine.name);

                                                  setDialogState(() {
                                                    localSelectedMedicines =
                                                        currentMedicines
                                                            .join(', ');
                                                  });
                                                } else {
                                                  // Immediately add this medicine to the prescription database
                                                  try {
                                                    // Create prescription using the medicine's own values
                                                    final prescription =
                                                        Medicine(
                                                      name: medicine.name,
                                                      morning: medicine.morning,
                                                      afternoon:
                                                          medicine.afternoon,
                                                      night: medicine.night,
                                                      comment:
                                                          medicine.comment ??
                                                              '',
                                                    );

                                                    final doctorPrescription =
                                                        DoctorPrescription(
                                                            medicine:
                                                                prescription);

                                                    // Add directly to database
                                                    await doctor
                                                        .addPrescription(
                                                      widget.patient.patientId,
                                                      widget
                                                          .patient
                                                          .admissionRecords
                                                          .first
                                                          .id,
                                                      doctorPrescription,
                                                    );

                                                    // Show success message
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            '${medicine.name} added to prescription'),
                                                        duration: Duration(
                                                            seconds: 1),
                                                      ),
                                                    );

                                                    // Update dialog state only
                                                    currentMedicines
                                                        .add(medicine.name);
                                                    setDialogState(() {
                                                      localSelectedMedicines =
                                                          currentMedicines
                                                              .join(', ');
                                                    });

                                                    // Refresh prescriptions list
                                                    _fetchPrescriptions();
                                                  } catch (e) {
                                                    print(
                                                        'Error adding prescription: $e');
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              'Error: $e')),
                                                    );
                                                  }
                                                }
                                              },
                                              child: Container(
                                                color: isSelected
                                                    ? HospitalTheme.surfaceLight
                                                    : Colors.transparent,
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 2.0),
                                                  child: ListTile(
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 8),
                                                    leading: Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: isSelected
                                                            ? HospitalTheme
                                                                .medical
                                                            : HospitalTheme
                                                                .surfaceLight,
                                                      ),
                                                      child: Center(
                                                        child: Icon(
                                                          Icons.medication,
                                                          color: isSelected
                                                              ? HospitalTheme
                                                                  .textOnPrimary
                                                              : HospitalTheme
                                                                  .medical,
                                                          size: 18,
                                                        ),
                                                      ),
                                                    ),
                                                    title: Text(
                                                      medicine.name,
                                                      style: TextStyle(
                                                        fontWeight: isSelected
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                        color: isSelected
                                                            ? HospitalTheme
                                                                .primary
                                                            : HospitalTheme
                                                                .textDark,
                                                      ),
                                                    ),
                                                    subtitle:
                                                        medicine.comment !=
                                                                    null &&
                                                                medicine.comment
                                                                    .isNotEmpty
                                                            ? RichText(
                                                                text: TextSpan(
                                                                  style:
                                                                      TextStyle(
                                                                    color: HospitalTheme
                                                                        .textMedium,
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                                  children: [
                                                                    TextSpan(
                                                                      text:
                                                                          'Dosage: ',
                                                                      style:
                                                                          TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: HospitalTheme
                                                                            .primary
                                                                            .withOpacity(0.7),
                                                                      ),
                                                                    ),
                                                                    TextSpan(
                                                                      text:
                                                                          '${medicine.morning}-${medicine.afternoon}-${medicine.night}',
                                                                    ),
                                                                    TextSpan(
                                                                      text:
                                                                          ' • ',
                                                                    ),
                                                                    TextSpan(
                                                                      text: medicine
                                                                          .comment,
                                                                      style:
                                                                          TextStyle(
                                                                        fontStyle:
                                                                            FontStyle.italic,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              )
                                                            : RichText(
                                                                text: TextSpan(
                                                                  style:
                                                                      TextStyle(
                                                                    color: HospitalTheme
                                                                        .textMedium,
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                                  children: [
                                                                    TextSpan(
                                                                      text:
                                                                          'Dosage: ',
                                                                      style:
                                                                          TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: HospitalTheme
                                                                            .primary
                                                                            .withOpacity(0.7),
                                                                      ),
                                                                    ),
                                                                    TextSpan(
                                                                      text:
                                                                          '${medicine.morning}-${medicine.afternoon}-${medicine.night}',
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                    trailing: Transform.scale(
                                                      scale: 1.1,
                                                      child: Checkbox(
                                                        activeColor:
                                                            HospitalTheme
                                                                .primary,
                                                        checkColor:
                                                            HospitalTheme
                                                                .textOnPrimary,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                        ),
                                                        value: isSelected,
                                                        onChanged: (bool?
                                                            selected) async {
                                                          final currentMedicines =
                                                              localSelectedMedicines
                                                                  .split(', ')
                                                                  .where((e) =>
                                                                      e.isNotEmpty)
                                                                  .toList();

                                                          if (selected ==
                                                                  true &&
                                                              !currentMedicines
                                                                  .contains(
                                                                      medicine
                                                                          .name)) {
                                                            // Immediately add this medicine to the prescription database
                                                            try {
                                                              // Create prescription using the medicine's own values
                                                              final prescription =
                                                                  Medicine(
                                                                name: medicine
                                                                    .name,
                                                                morning: medicine
                                                                    .morning,
                                                                afternoon: medicine
                                                                    .afternoon,
                                                                night: medicine
                                                                    .night,
                                                                comment: medicine
                                                                        .comment ??
                                                                    '',
                                                              );

                                                              final doctorPrescription =
                                                                  DoctorPrescription(
                                                                      medicine:
                                                                          prescription);

                                                              // Add directly to database
                                                              await doctor
                                                                  .addPrescription(
                                                                widget.patient
                                                                    .patientId,
                                                                widget
                                                                    .patient
                                                                    .admissionRecords
                                                                    .first
                                                                    .id,
                                                                doctorPrescription,
                                                              );

                                                              // Show success message
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                      '${medicine.name} added to prescription'),
                                                                  duration:
                                                                      Duration(
                                                                          seconds:
                                                                              1),
                                                                ),
                                                              );

                                                              // Update dialog state only
                                                              currentMedicines
                                                                  .add(medicine
                                                                      .name);
                                                              setDialogState(
                                                                  () {
                                                                localSelectedMedicines =
                                                                    currentMedicines
                                                                        .join(
                                                                            ', ');
                                                              });

                                                              // Refresh prescriptions list
                                                              _fetchPrescriptions();
                                                            } catch (e) {
                                                              print(
                                                                  'Error adding prescription: $e');
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                SnackBar(
                                                                    content: Text(
                                                                        'Error: $e')),
                                                              );
                                                            }
                                                          } else if (selected ==
                                                              false) {
                                                            currentMedicines
                                                                .remove(medicine
                                                                    .name);

                                                            // Update dialog state only
                                                            setDialogState(() {
                                                              localSelectedMedicines =
                                                                  currentMedicines
                                                                      .join(
                                                                          ', ');
                                                            });
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                            ),
                          ),

                          // Action buttons - Done and Cancel
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: Icon(Icons.cancel_outlined),
                                  label: Text('Cancel'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: HospitalTheme.textMedium,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                SizedBox(width: 12),
                                HospitalTheme.buildGradientButton(
                                  label: 'Done',
                                  onPressed: () {
                                    // Just close the dialog - prescriptions are already added
                                    Navigator.of(context).pop();
                                  },
                                  icon: Icons.check,
                                  startColor: HospitalTheme.primary,
                                  endColor: HospitalTheme.accent,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

// Helper method for displaying dosage pills in the selection dialog
  Widget _buildDosagePill(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Color(0xFF1E2843).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label:$value',
        style: TextStyle(
          fontSize: 12,
          color: Color(0xFF1E2843),
        ),
      ),
    );
  }

  Future<void> _addPrescription() async {
    if (selectedMedicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one medicine')),
      );
      return;
    }

    final morningDosage = morningDosageController.text.isEmpty
        ? '0'
        : morningDosageController.text;
    final afternoonDosage = afternoonDosageController.text.isEmpty
        ? '0'
        : afternoonDosageController.text;
    final nightDosage =
        nightDosageController.text.isEmpty ? '0' : nightDosageController.text;
    final comment = commentController.text;

    // Split the medicines into a list
    List<String> medicinesList =
        selectedMedicines.split(', ').where((med) => med.isNotEmpty).toList();

    try {
      // Create a counter for successful additions
      int successCount = 0;

      // Add each medicine individually
      for (String medicineName in medicinesList) {
        final medicine = Medicine(
          name: medicineName.trim(), // Ensure no extra spaces
          morning: morningDosage,
          afternoon: afternoonDosage,
          night: nightDosage,
          comment: comment,
        );

        final doctorPrescription = DoctorPrescription(medicine: medicine);

        await doctor.addPrescription(
          widget.patient.patientId,
          widget.patient.admissionRecords.first.id,
          doctorPrescription,
        );

        successCount++;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('$successCount prescriptions added successfully')),
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

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

// Add this method to fetch medicines from API
  Future<void> _fetchMedicines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication token not found';
          _isLoading = false;
        });
        return;
      }
      final response = await http.get(
        Uri.parse('${KVM_URL}/doctors/getDoctorMedicines'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> medicinesJson = json.decode(response.body);
        setState(() {
          _medicines.clear();
          _medicines.addAll(
            medicinesJson.map((json) => Medicine.fromJson(json)).toList(),
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load medicines: ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  List<Medicine> _medicines = [];
  String? _errorMessage;

// Single column layout for narrower views
  Widget _buildSingleColumnPrescriptionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected Medicines Section
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected Medicines',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E2843),
                ),
              ),
              SizedBox(height: 10),

              // Selected medicines as chips
              selectedMedicines.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No medicines selected yet',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                  : Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: selectedMedicines
                          .split(', ')
                          .where((medicine) => medicine.isNotEmpty)
                          .map((medicine) => Chip(
                                label: Text(
                                  medicine,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: Color(0xFF1E2843),
                                deleteIconColor: Colors.white,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                labelPadding:
                                    EdgeInsets.symmetric(horizontal: 4),
                                padding: EdgeInsets.symmetric(horizontal: 4),
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

              SizedBox(height: 12),

              // Medicine Name search field
              TextField(
                controller: medicineNameController,
                decoration: InputDecoration(
                  labelText: 'Medicine Name',
                  labelStyle: TextStyle(color: Color(0xFF1E2843), fontSize: 12),
                  prefixIcon:
                      Icon(Icons.search, size: 18, color: Color(0xFF1E2843)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Color(0xFF1E2843), width: 1.5),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  isDense: true,
                ),
                onChanged: _fetchMedicineSuggestions,
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
                    });
                  }
                },
              ),

              // Loading indicator & suggestions
              if (isLoadingSuggestions)
                LinearProgressIndicator(
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E2843)),
                ),

              if (medicineSuggestions.isNotEmpty)
                Container(
                  constraints: BoxConstraints(maxHeight: 120),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: medicineSuggestions.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        dense: true,
                        title: Text(
                          medicineSuggestions[index],
                          style: TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          setState(() {
                            List<String> medicines = selectedMedicines
                                .split(', ')
                                .where((e) => e.isNotEmpty)
                                .toList();
                            if (!medicines
                                .contains(medicineSuggestions[index])) {
                              medicines.add(medicineSuggestions[index]);
                              selectedMedicines = medicines.join(', ');
                            }
                            medicineNameController.clear();
                            medicineSuggestions = [];
                          });
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // Dosage Information
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dosage Information',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E2843),
                ),
              ),
              SizedBox(height: 12),

              // Dosage Fields in compact row
              Row(
                children: [
                  Expanded(
                    child: _buildCompactDosageField(
                      controller: morningDosageController,
                      label: "M",
                      tooltip: "Morning",
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactDosageField(
                      controller: afternoonDosageController,
                      label: "A",
                      tooltip: "Afternoon",
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactDosageField(
                      controller: nightDosageController,
                      label: "N",
                      tooltip: "Night",
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Comment field
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  labelText: 'Comment',
                  labelStyle: TextStyle(color: Color(0xFF1E2843), fontSize: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Color(0xFF1E2843), width: 1.5),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  isDense: true,
                ),
                maxLines: 2,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

// Two column layout for wider screens
  Widget _buildTwoColumnPrescriptionContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column - Selected Medicines
        Expanded(
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Medicines',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E2843),
                  ),
                ),
                SizedBox(height: 10),

                // Selected medicines as chips
                selectedMedicines.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'No medicines selected yet',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: selectedMedicines
                            .split(', ')
                            .where((medicine) => medicine.isNotEmpty)
                            .map((medicine) => Chip(
                                  label: Text(
                                    medicine,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: Color(0xFF1E2843),
                                  deleteIconColor: Colors.white,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  labelPadding:
                                      EdgeInsets.symmetric(horizontal: 4),
                                  padding: EdgeInsets.symmetric(horizontal: 4),
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

                SizedBox(height: 12),

                // Medicine Name search field
                TextField(
                  controller: medicineNameController,
                  decoration: InputDecoration(
                    labelText: 'Medicine Name',
                    labelStyle:
                        TextStyle(color: Color(0xFF1E2843), fontSize: 12),
                    prefixIcon:
                        Icon(Icons.search, size: 18, color: Color(0xFF1E2843)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Color(0xFF1E2843), width: 1.5),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    isDense: true,
                  ),
                  onChanged: _fetchMedicineSuggestions,
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
                      });
                    }
                  },
                ),

                // Loading indicator & suggestions
                if (isLoadingSuggestions)
                  LinearProgressIndicator(
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF1E2843)),
                  ),

                if (medicineSuggestions.isNotEmpty)
                  Container(
                    constraints: BoxConstraints(maxHeight: 120),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: medicineSuggestions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          dense: true,
                          title: Text(
                            medicineSuggestions[index],
                            style: TextStyle(fontSize: 12),
                          ),
                          onTap: () {
                            setState(() {
                              List<String> medicines = selectedMedicines
                                  .split(', ')
                                  .where((e) => e.isNotEmpty)
                                  .toList();
                              if (!medicines
                                  .contains(medicineSuggestions[index])) {
                                medicines.add(medicineSuggestions[index]);
                                selectedMedicines = medicines.join(', ');
                              }
                              medicineNameController.clear();
                              medicineSuggestions = [];
                            });
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),

        SizedBox(width: 16),

        // Right column - Dosage Information
        Expanded(
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dosage Information',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E2843),
                  ),
                ),
                SizedBox(height: 12),

                // Dosage Fields
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactDosageField(
                        controller: morningDosageController,
                        label: "M",
                        tooltip: "Morning",
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactDosageField(
                        controller: afternoonDosageController,
                        label: "A",
                        tooltip: "Afternoon",
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactDosageField(
                        controller: nightDosageController,
                        label: "N",
                        tooltip: "Night",
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Comment field
                TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    labelText: 'Comment',
                    labelStyle:
                        TextStyle(color: Color(0xFF1E2843), fontSize: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Color(0xFF1E2843), width: 1.5),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    isDense: true,
                  ),
                  maxLines: 3,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  } // Compact dosage field for smaller UI

  Widget _buildCompactDosageField({
    required TextEditingController controller,
    required String label,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400),
        ),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF1E2843),
              ),
            ),
            SizedBox(height: 4),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 4),
                border: InputBorder.none,
                isDense: true,
                hintText: '0',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Compact dosage pill for prescription list
  Widget _buildCompactDosagePill(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Color(0xFF1E2843).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label:$value',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1E2843),
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
            .get(Uri.parse('${KVM_URL}/doctors/getDiagnosis/$patientId'));
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

        // Create function for adding diagnosis
        void addDiagnosis() async {
          final currentDateTime =
              DateFormat('yyyy-MM-dd hh:mm:ss a').format(DateTime.now());

          // Get manually entered diagnosis
          final manualDiagnosis = symptomsController.text.trim();

          // Check if we have anything to add
          if (selectedDiagnoses.isEmpty && manualDiagnosis.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Please enter a diagnosis or select from suggestions')),
            );
            return;
          }

          // Combine selected and manual diagnoses
          final combinedDiagnoses = [
                ...selectedDiagnoses,
                if (manualDiagnosis.isNotEmpty) manualDiagnosis,
              ].join(', ') +
              ' Date: $currentDateTime';

          // Send to backend
          await addDoctorDiagnosis(admissionId, combinedDiagnoses, patientId);

          // Refresh diagnoses
          fetchDoctorDiagnosis(patientId, admissionId);

          // Clear selections and text field
          ref.read(selectedDiagnosesProvider.notifier).state = [];
          symptomsController.clear();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Diagnosis added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Main content in stack with floating button
        return Stack(
          children: [
            // Scrollable content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title and header section with space for the floating button
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Diagnosis Management',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF005F9E),
                            ),
                          ),
                        ),
                        // Space for the floating button
                        SizedBox(width: 170),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Selected diagnoses chips
                    if (selectedDiagnoses.isNotEmpty) ...[
                      Text(
                        'Selected Diagnoses:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: selectedDiagnoses.map((diagnosis) {
                            return Chip(
                              label: Text(diagnosis),
                              backgroundColor: Color(0xFF005F9E),
                              labelStyle: TextStyle(color: Colors.white),
                              deleteIconColor: Colors.white70,
                              onDeleted: () {
                                ref
                                    .read(selectedDiagnosesProvider.notifier)
                                    .state = List.from(selectedDiagnoses)
                                  ..remove(diagnosis);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],

                    SizedBox(height: 16),

                    // Manual diagnosis input
                    Text(
                      'Enter Manual Diagnosis:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: symptomsController,
                      decoration: InputDecoration(
                        labelText: 'Enter diagnosis manually',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Color(0xFF005F9E), width: 2),
                        ),
                      ),
                      maxLines: 2,
                    ),

                    SizedBox(height: 16),

                    // AI Suggestions button
                    Row(
                      children: [
                        Text(
                          'AI Diagnosis Suggestions:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => fetchDiagnosisSuggestions(ref),
                          icon: Icon(Icons.psychology),
                          label: Text('Load Suggestions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF005F9E),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8),

                    // AI Suggestions loading or content
                    if (isLoading)
                      Center(
                        child: Column(
                          children: [
                            SizedBox(height: 16),
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF005F9E)),
                            ),
                            SizedBox(height: 8),
                            Text('Loading suggestions...'),
                          ],
                        ),
                      )
                    else if (diagnosisSuggestions.isNotEmpty)
                      // Container with fixed height to avoid overflow
                      Container(
                        height: 250, // Fixed height for suggestions list
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.separated(
                          padding: EdgeInsets.all(8),
                          itemCount: diagnosisSuggestions.length,
                          separatorBuilder: (context, index) =>
                              Divider(height: 1),
                          itemBuilder: (context, index) {
                            final diagnosis = diagnosisSuggestions[index];
                            return CheckboxListTile(
                              title: Text(diagnosis),
                              value: selectedDiagnoses.contains(diagnosis),
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: Color(0xFF005F9E),
                              onChanged: (bool? value) {
                                final updatedList =
                                    List.from(selectedDiagnoses);
                                if (value == true) {
                                  updatedList.add(diagnosis);
                                } else {
                                  updatedList.remove(diagnosis);
                                }
                                ref
                                    .read(selectedDiagnosesProvider.notifier)
                                    .state = updatedList.cast<String>();
                              },
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'No suggestions available. Click "Load Suggestions" to get AI-powered diagnosis recommendations.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Floating Action Button in top right corner
            Positioned(
              right: 20,
              top: 10,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF00B8D4).withOpacity(0.4),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: FloatingActionButton.extended(
                  onPressed: addDiagnosis,
                  label: Text('ADD DIAGNOSIS'),
                  icon: Icon(Icons.add_circle_outline),
                  backgroundColor: Color(0xFF00B8D4),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ],
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        itemCount: medicineSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = medicineSuggestions[index];
          return ListTile(
            dense: true,
            title: Text(
              suggestion,
              style: TextStyle(fontSize: 13),
            ),
            leading: Icon(Icons.medication_outlined,
                size: 16, color: Color(0xFF1E2843)),
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
                medicineSuggestions = []; // Clear suggestions after selection
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
                color: Color(0xFF00B8D4),
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
                  onPressed: _addVitals,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00B8D4),
                    foregroundColor: Colors.black,
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Add Vitals',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                ),
                SizedBox(
                  width: 12,
                ),
                ElevatedButton(
                  onPressed: _clearVitalsFields,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 212, 0, 0),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Clear',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
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

// Add this to the imports at the top of the file if not already there

// Modify the _buildFourSquareLayout method to include an interactive notes feature
  Widget _buildFourSquareLayout(BuildContext context, WidgetRef ref,
      String patientId, String admissionId) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine layout based on screen width
        final bool isLargeScreen = constraints.maxWidth > 1400;
        final bool isMediumScreen = constraints.maxWidth >= 768 &&
            constraints.maxWidth <= 1400; // Laptop screens
        final bool isSmallScreen = constraints.maxWidth < 768;

        // Define fixed heights for sections on laptop screens
        // INCREASED HEIGHT for left column sections (was 200)
        final double leftColumnSectionHeight = isMediumScreen
            ? 362
            : double.infinity; // Increased height for left sections
        final double rightColumnHeight = isMediumScreen
            ? 750
            : double.infinity; // Taller height for prescription
        final double diagnosisHeight = isMediumScreen
            ? 350
            : double.infinity; // Height for diagnosis section

        return Stack(
          children: [
            // Main content area
            Container(
              decoration: BoxDecoration(
                color: Color(0xFFF8FBFD), // Light background
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Special laptop layout - Overview, Vitals, Symptoms on left, Prescription on right
                      if (isMediumScreen)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LEFT COLUMN: Overview, Vitals, Symptoms stacked vertically
                            Expanded(
                              flex: 55,
                              child: Column(
                                children: [
                                  // Overview
                                  _buildStyledSectionContainer(
                                    context,
                                    child: _buildOverviewSection1(context, ref),
                                    title: 'Patient Overview',
                                    icon: Icons.person_outline,
                                    maxHeight: leftColumnSectionHeight,
                                  ),
                                  SizedBox(height: 16),

                                  // Vitals
                                  _buildStyledSectionContainer(
                                    context,
                                    child: _buildVitalsLayout(),
                                    title: 'Vitals Monitoring',
                                    icon: Icons.monitor_heart_outlined,
                                    maxHeight: leftColumnSectionHeight,
                                  ),
                                  SizedBox(height: 16),

                                  // Symptoms
                                  _buildStyledSectionContainer(
                                    context,
                                    child: _buildSymptomsLayout(
                                        context, ref, patientId, admissionId),
                                    title: 'Symptoms',
                                    icon: Icons.medical_services_outlined,
                                    maxHeight: leftColumnSectionHeight,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(width: 16),

                            // RIGHT COLUMN: Prescription with increased height
                            Expanded(
                              flex: 55,
                              child: _buildStyledSectionContainer(
                                context,
                                child: _buildPrescriptionLayout(),
                                title: 'Prescription Management',
                                icon: Icons.medication_outlined,
                                maxHeight:
                                    rightColumnHeight, // Taller height for prescription
                              ),
                            ),
                          ],
                        )
                      else if (isLargeScreen)
                        // Original large screen layout with three columns
                        Column(
                          children: [
                            // First row: Overview and Prescription
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Patient Overview
                                Expanded(
                                  flex: 45,
                                  child: _buildStyledSectionContainer(
                                    context,
                                    child: _buildOverviewSection1(context, ref),
                                    title: 'Patient Overview',
                                    icon: Icons.person_outline,
                                  ),
                                ),
                                SizedBox(width: 16),
                                // Prescription
                                Expanded(
                                  flex: 55,
                                  child: _buildStyledSectionContainer(
                                    context,
                                    child: _buildPrescriptionLayout(),
                                    title: 'Prescription Management',
                                    icon: Icons.medication_outlined,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            // Second row: Vitals, Symptoms, Diagnosis
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Vitals
                                Expanded(
                                  child: _buildStyledSectionContainer(
                                    context,
                                    child: _buildVitalsLayout(),
                                    title: 'Vitals Monitoring',
                                    icon: Icons.monitor_heart_outlined,
                                  ),
                                ),
                                SizedBox(width: 16),
                                // Symptoms
                                Expanded(
                                  child: _buildStyledSectionContainer(
                                    context,
                                    child: _buildSymptomsLayout(
                                        context, ref, patientId, admissionId),
                                    title: 'Symptoms',
                                    icon: Icons.medical_services_outlined,
                                  ),
                                ),
                                SizedBox(width: 16),
                                // Diagnosis
                                Expanded(
                                  child: _buildStyledSectionContainer(
                                    context,
                                    child: buildDiagnosisLayout(
                                      admissionId: admissionId,
                                      patientId: patientId,
                                      addDoctorDiagnosis:
                                          doctor.addDoctorDiagnosis,
                                      fetchDoctorDiagnosis:
                                          doctor.fetchDoctorDiagnosis,
                                    ),
                                    title: 'Diagnosis',
                                    icon: Icons.description_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        // Single column layout for small screens
                        Column(
                          children: [
                            _buildStyledSectionContainer(
                              context,
                              child: _buildOverviewSection1(context, ref),
                              title: 'Patient Overview',
                              icon: Icons.person_outline,
                            ),
                            SizedBox(height: 16),
                            _buildStyledSectionContainer(
                              context,
                              child: _buildPrescriptionLayout(),
                              title: 'Prescription Management',
                              icon: Icons.medication_outlined,
                            ),
                            SizedBox(height: 16),
                            _buildStyledSectionContainer(
                              context,
                              child: _buildVitalsLayout(),
                              title: 'Vitals Monitoring',
                              icon: Icons.monitor_heart_outlined,
                            ),
                            SizedBox(height: 16),
                            _buildStyledSectionContainer(
                              context,
                              child: _buildSymptomsLayout(
                                  context, ref, patientId, admissionId),
                              title: 'Symptoms',
                              icon: Icons.medical_services_outlined,
                            ),
                            SizedBox(height: 16),
                            _buildStyledSectionContainer(
                              context,
                              child: buildDiagnosisLayout(
                                admissionId: admissionId,
                                patientId: patientId,
                                addDoctorDiagnosis: doctor.addDoctorDiagnosis,
                                fetchDoctorDiagnosis:
                                    doctor.fetchDoctorDiagnosis,
                              ),
                              title: 'Diagnosis',
                              icon: Icons.description_outlined,
                            ),
                          ],
                        ),

                      // Full width diagnosis section for laptop layout only
                      if (isMediumScreen)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: _buildStyledSectionContainer(
                            context,
                            child: buildDiagnosisLayout(
                              admissionId: admissionId,
                              patientId: patientId,
                              addDoctorDiagnosis: doctor.addDoctorDiagnosis,
                              fetchDoctorDiagnosis: doctor.fetchDoctorDiagnosis,
                            ),
                            title: 'Diagnosis',
                            icon: Icons.description_outlined,
                            maxHeight: diagnosisHeight,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Interactive Doctor Notes Button
            Positioned(
              right: 20,
              top: 20,
              child: Container(
                key: _notesButtonKey,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showFloatingNotes = !_showFloatingNotes;
                    });
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    width: _showFloatingNotes ? 150 : 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E2843), Color(0xFF2C3E50)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_alt_outlined,
                          color: Colors.white,
                        ),
                        if (_showFloatingNotes)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              "Doctor Notes",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Floating Doctor Notes Panel
            AnimatedPositioned(
              duration: Duration(milliseconds: 400),
              curve: Curves.easeOutQuad,
              right: _showFloatingNotes ? 30 : -350,
              top: 80,
              child: AnimatedOpacity(
                duration: Duration(milliseconds: 300),
                opacity: _showFloatingNotes ? 1.0 : 0.0,
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! > 0) {
                      // Swiped right
                      setState(() {
                        _showFloatingNotes = false;
                      });
                    }
                  },
                  child: Container(
                    width: 320,
                    height: MediaQuery.of(context).size.height * 0.7,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Doctor Notes Header
                              Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF1E2843),
                                      Color(0xFF2C3E50),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.note_alt_outlined,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          "Doctor Notes",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.minimize,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isNotesExpanded = false;
                                            });
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            _isNotesExpanded
                                                ? Icons.fullscreen_exit
                                                : Icons.fullscreen,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isNotesExpanded =
                                                  !_isNotesExpanded;
                                            });
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _showFloatingNotes = false;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Doctor Notes Content
                              Expanded(
                                child: _buildDoctorNotes(
                                  context,
                                  patientId,
                                  admissionId,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Expanded Doctor Notes Panel
            if (_isNotesExpanded && _showFloatingNotes)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      height: MediaQuery.of(context).size.height * 0.85,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Expanded Notes Header
                          Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 16, horizontal: 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF1E2843),
                                  Color(0xFF2C3E50),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.note_alt_outlined,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      "Doctor Notes - Full View",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.fullscreen_exit,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isNotesExpanded = false;
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _showFloatingNotes = false;
                                          _isNotesExpanded = false;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Expanded Notes Content
                          Expanded(
                            child: _buildDoctorNotes(
                              context,
                              patientId,
                              admissionId,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Quick Add Note Floating Action Button
            Positioned(
              right: 30,
              bottom: 100,
              child: AnimatedOpacity(
                duration: Duration(milliseconds: 300),
                opacity: _showFloatingNotes ? 1.0 : 0.0,
                child: FloatingActionButton(
                  backgroundColor: Color(0xFF005F9E),
                  child: Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    _showAddNoteDialog(context, patientId, admissionId);
                  },
                  tooltip: 'Quick Add Note',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

// Section container with fixed height and scrolling for content
  Widget _buildStyledSectionContainer(
    BuildContext context, {
    required Widget child,
    required String title,
    required IconData icon,
    double maxHeight = double.infinity,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.blue.shade700, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          ),

          // Thin divider
          const Divider(height: 1, thickness: 0.5),

          // Content with constrained height and scrolling
          Container(
            constraints: BoxConstraints(
              maxHeight: maxHeight != double.infinity
                  ? maxHeight - 50
                  : double.infinity,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }

// Function to build section containers with consistent styling

// Function to build a styled container with consistent look

// Custom layout for larger screens with prescription taking more space
  Widget _buildCustomLayoutGrid(BuildContext context, WidgetRef ref,
      String patientId, String admissionId) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          // First row: Overview and Prescription with Prescription taking more space
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview section - 40% width
              Expanded(
                flex: 4,
                child: _buildStyledSectionContainer(
                  context,
                  child: _buildOverviewSection1(context, ref),
                  title: 'Patient Overview',
                  icon: Icons.person_outline,
                ),
              ),
              SizedBox(width: 16),
              // Prescription section - 60% width (larger as requested)
              Expanded(
                flex: 6,
                child: _buildStyledSectionContainer(
                  context,
                  child: _buildPrescriptionLayout(),
                  title: 'Prescription Management',
                  icon: Icons.medication_outlined,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Second row: Vitals, Symptoms, and Diagnosis in equal columns
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vitals section
              Expanded(
                child: _buildStyledSectionContainer(
                  context,
                  child: _buildVitalsLayout(),
                  title: 'Vitals Monitoring',
                  icon: Icons.monitor_heart_outlined,
                ),
              ),
              SizedBox(width: 16),
              // Symptoms section
              Expanded(
                child: _buildStyledSectionContainer(
                  context,
                  child: Column(
                    children: [
                      SymptomsLayout(
                        patientId: widget.patient.patientId,
                        admissionId: widget.patient.admissionRecords.first.id,
                        addSymptomsByDoctor: doctor.addSymptomsByDoctor,
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                    ],
                  ),
                  title: 'Symptoms',
                  icon: Icons.medical_services_outlined,
                ),
              ),
              SizedBox(width: 16),
              // Diagnosis section
              Expanded(
                child: _buildStyledSectionContainer(
                  context,
                  child: buildDiagnosisLayout(
                    admissionId: admissionId,
                    patientId: patientId,
                    addDoctorDiagnosis: doctor.addDoctorDiagnosis,
                    fetchDoctorDiagnosis: doctor.fetchDoctorDiagnosis,
                  ),
                  title: 'Diagnosis',
                  icon: Icons.description_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionLayout() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Access Medicine Database Banner
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.medication_outlined, color: Colors.black, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Quick Access to Your Medicine Database',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _showMedicineSelectionDialog();
                  },
                  child: Text('Open Database'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00B8D4),
                    foregroundColor: Colors.black,
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Text(
            'Prescription Detail',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2843),
            ),
          ),
          SizedBox(height: 16),

          // Selected Medicines
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Medicines',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E2843),
                  ),
                ),
                SizedBox(height: 10),

                selectedMedicines.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'No medicines selected yet',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: selectedMedicines
                            .split(', ')
                            .where((medicine) => medicine.isNotEmpty)
                            .map((medicine) => Chip(
                                  label: Text(
                                    medicine,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: Color(0xFF1E2843),
                                  deleteIconColor: Colors.white,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  labelPadding:
                                      EdgeInsets.symmetric(horizontal: 4),
                                  padding: EdgeInsets.symmetric(horizontal: 4),
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

                SizedBox(height: 12),

                // Medicine Name search field - simplified
                TextField(
                  controller: medicineNameController,
                  decoration: InputDecoration(
                    labelText: 'Medicine Name',
                    labelStyle:
                        TextStyle(color: Color(0xFF1E2843), fontSize: 12),
                    prefixIcon:
                        Icon(Icons.search, size: 18, color: Color(0xFF1E2843)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Color(0xFF1E2843), width: 1.5),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    isDense: true,
                  ),
                  onChanged: _fetchMedicineSuggestions,
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
                        medicineSuggestions =
                            []; // Clear suggestions after selection
                      });
                    }
                  },
                ),

                // Display loading indicator or suggestions
                if (isLoadingSuggestions)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (medicineSuggestions.isNotEmpty)
                  _buildSuggestionsList(),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Dosage Information
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dosage Information',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E2843),
                  ),
                ),
                SizedBox(height: 12),

                // Dosage Fields in compact row
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactDosageField(
                        controller: morningDosageController,
                        label: "M",
                        tooltip: "Morning",
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactDosageField(
                        controller: afternoonDosageController,
                        label: "A",
                        tooltip: "Afternoon",
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactDosageField(
                        controller: nightDosageController,
                        label: "N",
                        tooltip: "Night",
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Comment field
                TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    labelText: 'Comment',
                    labelStyle:
                        TextStyle(color: Color(0xFF1E2843), fontSize: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Color(0xFF1E2843), width: 1.5),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    isDense: true,
                  ),
                  maxLines: 2,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Add button centered
          Center(
            child: ElevatedButton.icon(
              onPressed: _addPrescription,
              icon: Icon(Icons.add_circle_outline),
              label: Text('Add Prescription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00B8D4),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          SizedBox(height: 16),

          // Current Prescriptions
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Prescriptions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E2843),
                  ),
                ),

                SizedBox(height: 12),

                // Simple ListView for prescriptions to avoid scroll conflicts
                _prescriptions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            children: [
                              Icon(
                                Icons.medication_outlined,
                                size: 32,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'No prescriptions added yet',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: _prescriptions.map((prescription) {
                          return Card(
                            margin: EdgeInsets.only(bottom: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    Color(0xFF1E2843).withOpacity(0.1),
                                child: Icon(
                                  Icons.medication,
                                  size: 16,
                                  color: Color(0xFF1E2843),
                                ),
                              ),
                              title: Text(
                                prescription.medicine.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1E2843),
                                ),
                              ),
                              subtitle: prescription.medicine.comment.isNotEmpty
                                  ? Text(
                                      prescription.medicine.comment,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    )
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildCompactDosagePill(
                                      'M', prescription.medicine.morning),
                                  SizedBox(width: 4),
                                  _buildCompactDosagePill(
                                      'A', prescription.medicine.afternoon),
                                  SizedBox(width: 4),
                                  _buildCompactDosagePill(
                                      'N', prescription.medicine.night),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline,
                                        size: 18, color: Colors.red),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _deletePrescription(
                                        prescription.medicine.id!),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection1(BuildContext context, WidgetRef ref) {
    return Container(
      // Instead of padding directly, we keep width fluid
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Patient Overview Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.person, color: Colors.blue.shade600),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patient.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${widget.patient.patientId} | Age: ${widget.patient.age} | Gender: ${widget.patient.gender}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons with Wrap for better responsiveness
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _buildActionButton(
                icon: Icons.visibility,
                label: 'View Details',
                color: Colors.teal,
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => PatientHistoryDetailScreen(
                      patientId: widget.patient.patientId,
                    ),
                  ));
                },
              ),
              _buildActionButton(
                icon: Icons.medication,
                label: 'Prescription',
                color: Colors.purple,
                isLoading: _isPrescriptionLoading,
                onPressed: () async {
                  await _fetchDoctorAdvice(context, widget.patient.patientId,
                      widget.patient.admissionRecords.first.id);
                },
              ),
              _buildActionButton(
                icon: Icons.local_hospital,
                label: 'Admit',
                color: Colors.red,
                onPressed: () async =>
                    await _admitPatient(widget.patient, ref, context),
              ),
              _buildActionButton(
                icon: Icons.science,
                label: 'Lab Assign',
                color: Colors.orange,
                onPressed: () async =>
                    await _handleAssignLab(context, widget.patient, ref),
              ),
              _buildActionButton(
                  icon: Icons.science,
                  label: 'Investigation',
                  color: Colors.orange,
                  onPressed: () async {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => CreateInvestigationScreen(
                        patientId: widget.patient.patientId,
                        admissionId: widget.patient.admissionRecords.first.id,
                      ),
                    ));
                  }),
            ],
          ),

          const SizedBox(height: 16),

          // Admission Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admission',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.patient.admissionRecords.isNotEmpty)
                  ..._buildAdmissionDetails(
                      widget.patient.admissionRecords.first)
                else
                  Text(
                    'No admission records found',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNotesPanel(BuildContext context, String patientId,
      String admissionId, BoxConstraints constraints) {
    final bool isMediumScreen = constraints.maxWidth > 900;
    final double panelWidth =
        isMediumScreen ? 320 : min(constraints.maxWidth * 0.85, 280);

    return AnimatedPositioned(
      duration: Duration(milliseconds: 400),
      curve: Curves.easeOutQuad,
      right: isMediumScreen ? 30 : 15,
      top: isMediumScreen ? 80 : 60,
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 300),
        opacity: 1.0,
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! > 0) {
              setState(() {
                _showFloatingNotes = false;
              });
            }
          },
          child: Container(
            width: panelWidth,
            height: MediaQuery.of(context).size.height *
                (isMediumScreen ? 0.7 : 0.6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Doctor Notes Header
                      Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF1E2843),
                              Color(0xFF2C3E50),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.note_alt_outlined,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    "Doctor Notes",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _isNotesExpanded
                                        ? Icons.fullscreen_exit
                                        : Icons.fullscreen,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isNotesExpanded = !_isNotesExpanded;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showFloatingNotes = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Doctor Notes Content
                      Expanded(
                        child: _buildDoctorNotes(
                          context,
                          patientId,
                          admissionId,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

// Build expanded notes panel when maximized
  Widget _buildExpandedNotesPanel(BuildContext context, String patientId,
      String admissionId, BoxConstraints constraints) {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            width: min(constraints.maxWidth * 0.85, 1200),
            height: constraints.maxHeight * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                // Expanded Notes Header
                Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF1E2843),
                        Color(0xFF2C3E50),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.note_alt_outlined,
                            color: Colors.white,
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Doctor Notes - Full View",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.fullscreen_exit,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _isNotesExpanded = false;
                              });
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _showFloatingNotes = false;
                                _isNotesExpanded = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Expanded Notes Content
                Expanded(
                  child: _buildDoctorNotes(
                    context,
                    patientId,
                    admissionId,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _getNotesWidth(BoxConstraints constraints) {
    if (constraints.maxWidth > 1400) return 380;
    if (constraints.maxWidth > 900) return 320;
    return 280;
  }

// Helper method to build notes panel with proper styling
  Widget _buildNotesPanel(BuildContext context, String patientId,
      String admissionId, BoxConstraints constraints) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(
                    vertical: constraints.maxWidth > 900 ? 16 : 12,
                    horizontal: constraints.maxWidth > 900 ? 20 : 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E2843), Color(0xFF2C3E50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.note_alt_outlined, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            "Notes",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: constraints.maxWidth > 900 ? 18 : 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.minimize, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isNotesExpanded = false;
                            });
                          },
                          iconSize: constraints.maxWidth > 900 ? 24 : 20,
                          padding: EdgeInsets.all(
                              constraints.maxWidth > 900 ? 8 : 4),
                          constraints: BoxConstraints(),
                        ),
                        IconButton(
                          icon: Icon(
                            _isNotesExpanded
                                ? Icons.fullscreen_exit
                                : Icons.fullscreen,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _isNotesExpanded = !_isNotesExpanded;
                            });
                          },
                          iconSize: constraints.maxWidth > 900 ? 24 : 20,
                          padding: EdgeInsets.all(
                              constraints.maxWidth > 900 ? 8 : 4),
                          constraints: BoxConstraints(),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _showFloatingNotes = false;
                            });
                          },
                          iconSize: constraints.maxWidth > 900 ? 24 : 20,
                          padding: EdgeInsets.all(
                              constraints.maxWidth > 900 ? 8 : 4),
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _buildDoctorNotes(context, patientId, admissionId),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Helper method to build expanded notes panel
  // Widget _buildExpandedNotesPanel(BuildContext context, String patientId,
  //     String admissionId, BoxConstraints constraints) {
  //   double width, height;

  //   // Responsive sizing for different screen sizes
  //   if (constraints.maxWidth > 1400) {
  //     width = MediaQuery.of(context).size.width * 0.85;
  //     height = MediaQuery.of(context).size.height * 0.85;
  //   } else if (constraints.maxWidth > 900) {
  //     width = MediaQuery.of(context).size.width * 0.8;
  //     height = MediaQuery.of(context).size.height * 0.8;
  //   } else {
  //     width = MediaQuery.of(context).size.width * 0.9;
  //     height = MediaQuery.of(context).size.height * 0.75;
  //   }

  //   return Positioned.fill(
  //     child: Container(
  //       color: Colors.black54,
  //       child: Center(
  //         child: Container(
  //           width: width,
  //           height: height,
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.circular(20),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black26,
  //                 blurRadius: 20,
  //                 spreadRadius: 5,
  //               ),
  //             ],
  //           ),
  //           child: Column(
  //             children: [
  //               // Header
  //               Container(
  //                 padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
  //                 decoration: BoxDecoration(
  //                   gradient: LinearGradient(
  //                     colors: [Color(0xFF1E2843), Color(0xFF2C3E50)],
  //                     begin: Alignment.topLeft,
  //                     end: Alignment.bottomRight,
  //                   ),
  //                   borderRadius: BorderRadius.only(
  //                     topLeft: Radius.circular(20),
  //                     topRight: Radius.circular(20),
  //                   ),
  //                 ),
  //                 child: Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     Row(
  //                       children: [
  //                         Icon(Icons.note_alt_outlined, color: Colors.white),
  //                         SizedBox(width: 12),
  //                         Text(
  //                           "Doctor Notes - Full View",
  //                           style: TextStyle(
  //                             color: Colors.white,
  //                             fontWeight: FontWeight.bold,
  //                             fontSize: 18,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                     Row(
  //                       children: [
  //                         IconButton(
  //                           icon: Icon(Icons.fullscreen_exit,
  //                               color: Colors.white),
  //                           onPressed: () {
  //                             setState(() {
  //                               _isNotesExpanded = false;
  //                             });
  //                           },
  //                         ),
  //                         IconButton(
  //                           icon: Icon(Icons.close, color: Colors.white),
  //                           onPressed: () {
  //                             setState(() {
  //                               _showFloatingNotes = false;
  //                               _isNotesExpanded = false;
  //                             });
  //                           },
  //                         ),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //               ),

  //               // Content
  //               Expanded(
  //                 child: _buildDoctorNotes(context, patientId, admissionId),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

// Optional: Update the _buildDoctorNotes method to be better suited for the floating panel
// Complete updated doctor notes methods

// Updated _buildDoctorNotes method
  Widget _buildDoctorNotes(
      BuildContext context, String patientId, String admissionId) {
    return FutureBuilder(
      key: _futureBuilderKey,
      future: _fetchDoctorNotes(patientId, admissionId),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF005F9E)),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading notes...',
                  style: TextStyle(
                    color: Color(0xFF005F9E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _futureBuilderKey = UniqueKey();
                    });
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF005F9E),
                  ),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.note_alt_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 16),
                Text(
                  'No notes available',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Add your first note to keep track of important observations',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () =>
                      _showAddNoteDialog(context, patientId, admissionId),
                  icon: Icon(Icons.add),
                  label: Text('Add Note'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF005F9E),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        // Display notes in a more visually appealing way
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notes count and last updated
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${snapshot.data!.length} Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E2843),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _showAddNoteDialog(context, patientId, admissionId),
                      icon: Icon(Icons.add, size: 18),
                      label: Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),

              // Notes list
              Expanded(
                child: ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final note = snapshot.data![index];
                    return _buildEnhancedNoteItem(
                      date: note['date'],
                      note: note['text'],
                      doctor: note['doctorName'],
                      noteId: note['_id'],
                      onDelete: () => _showDeleteConfirmation(
                          context, patientId, admissionId, note['_id']),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

// Enhanced note item with better visual design
  Widget _buildEnhancedNoteItem({
    required String date,
    required String note,
    required String doctor,
    required String noteId,
    required Function onDelete,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date and doctor name
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_note,
                      size: 16,
                      color: Color(0xFF005F9E),
                    ),
                    SizedBox(width: 8),
                    Text(
                      date,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Color(0xFF005F9E),
                    ),
                    SizedBox(width: 4),
                    Text(
                      doctor,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF005F9E),
                      ),
                    ),
                    SizedBox(width: 8),
                    InkWell(
                      onTap: () => onDelete(),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Note content
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              note,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

// Updated _showAddNoteDialog method
  void _showAddNoteDialog(
      BuildContext context, String patientId, String admissionId) {
    final textController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Use setDialogState for dialog updates
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dialog header
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF005F9E), Color(0xFF00B8D4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.note_add,
                          color: Colors.white,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Add Doctor Note',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dialog content
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Note Content',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1E2843),
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          child: TextField(
                            controller: textController,
                            decoration: InputDecoration(
                              hintText: 'Enter your note here',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                            maxLines: 5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dialog actions
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (textController.text.isNotEmpty) {
                                    setDialogState(() {
                                      // Update dialog state
                                      isSubmitting = true;
                                    });

                                    // Get current date in the required format
                                    final now = DateTime.now();
                                    final formattedDate =
                                        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

                                    try {
                                      // Add the note
                                      await _addDoctorNote(
                                          patientId,
                                          admissionId,
                                          textController.text,
                                          formattedDate);

                                      // Close dialog after successful addition
                                      Navigator.pop(context);

                                      // Refresh the main widget UI
                                      setState(() {
                                        _futureBuilderKey = UniqueKey();
                                      });

                                      // Show success message
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Note added successfully!'),
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    } catch (e) {
                                      // Handle error
                                      setDialogState(() {
                                        isSubmitting = false;
                                      });

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Error adding note: $e'),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF005F9E),
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isSubmitting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text('Save Note'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

// Enhanced delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, String patientId,
      String admissionId, String noteId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog header
              Container(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Delete Note',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

              // Dialog content
              Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Are you sure you want to delete this note? This action cannot be undone.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),

              // Dialog actions
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        // Close the dialog first
                        Navigator.pop(context);
                        // Then delete the note
                        await _deleteNote(patientId, admissionId, noteId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Updated _deleteNote method
  Future<void> _deleteNote(
      String patientId, String admissionId, String noteId) async {
    try {
      await doctor.deleteDoctorNote(
        patientId: patientId,
        admissionId: admissionId,
        noteId: noteId,
      );

      // Refresh the UI by updating state and forcing the FutureBuilder to rebuild
      setState(() {
        _futureBuilderKey = UniqueKey();
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Note deleted successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("Error deleting note: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting note: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

// Updated _addDoctorNote method
  Future<void> _addDoctorNote(
      String patientId, String admissionId, String text, String date) async {
    try {
      await doctor.addDoctorNote(
        patientId: patientId,
        admissionId: admissionId,
        text: text,
        date: date,
      );
      // Note: setState will be called from the calling function
    } catch (e) {
      print("Error adding note: $e");
      // Re-throw the error so it can be handled in the UI
      throw e;
    }
  }

// Function to fetch doctor notes
  Future<List<dynamic>> _fetchDoctorNotes(
      String patientId, String admissionId) async {
    final url =
        Uri.parse('${KVM_URL}/doctors/fetchNotes/$patientId/$admissionId');
    print(url);
    try {
      final response = await http.get(
        url,
      );
      print(response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['doctorNotes'];
      } else {
        final error = jsonDecode(response.body);
        throw Exception("Error: ${error['message']}");
      }
    } catch (e) {
      throw Exception("Failed to fetch doctor notes: $e");
    }
  }

//   Widget _buildFourSquareLayout(BuildContext context, WidgetRef ref,
//       String patientId, String admissionId) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFFF5F7FA), Color(0xFFE6E9F0)],
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//         ),
//       ),
//       child: SingleChildScrollView(
//         physics: const AlwaysScrollableScrollPhysics(),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: ConstrainedBox(
//             constraints: BoxConstraints(
//               minHeight: MediaQuery.of(context).size.height,
//             ),
//             child: Column(
//               children: [
//                 IntrinsicHeight(
//                   // This ensures all children have the same height
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Left Column
//                       Expanded(
//                         child: Column(
//                           children: [
//                             _buildSectionContainer(
//                               context,
//                               _buildOverviewSection1(context, ref),
//                               title: 'Patient Overview',
//                             ),
//                             const SizedBox(height: 16),
//                             _buildSectionContainer(
//                               context,
//                               _buildVitalsLayout(),
//                               title: 'Vitals Monitoring',
//                             ),
//                             SizedBox(
//                               height: 16,
//                             ),
//                             Column(
//                               children: [
//                                 _buildSectionContainer(
//                                   context,
//                                   Column(
//                                     children: [
//                                       _buildSymptomsLayout(
//                                           context, ref, patientId, admissionId),
//                                       const SizedBox(height: 12),
//                                       Divider(),
//                                     ],
//                                   ),
//                                   title: 'Symptoms',
//                                 ),
//                                 _buildSectionContainer(
//                                   context,
//                                   buildDiagnosisLayout(
//                                       admissionId: admissionId,
//                                       patientId: patientId,
//                                       addDoctorDiagnosis:
//                                           doctor.addDoctorDiagnosis,
//                                       fetchDoctorDiagnosis:
//                                           doctor.fetchDoctorDiagnosis),
//                                   title: 'Diagnosis',
//                                 ),
//                                 SizedBox(
//                                   height: 16,
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),

//                       // Middle drawer that pops out horizontally
//                       HorizontalCenterDrawer(
//                           closedWidth: 50,
//                           openWidth: 300,
//                           child:
// // Inside your parent widget
//                               _buildDoctorNotes(
//                                   context, patientId, admissionId)),

//                       // Right Column
//                       Expanded(
//                         child: Column(
//                           children: [
//                             _buildSectionContainer(
//                               context,
//                               _buildPrescriptionLayout(),
//                               title: 'Prescription Management',
//                             ),
//                             const SizedBox(height: 16),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

  // Doctor notes widget
  // Build doctor notes section

// Add this method for delete confirmation
//   void _showDeleteConfirmation(BuildContext context, String patientId,
//       String admissionId, String noteId) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Delete Note'),
//         content: Text('Are you sure you want to delete this note?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//             ),
//             onPressed: () async {
//               // Close the dialog first
//               Navigator.pop(context);
//               // Then delete the note
//               await _deleteNote(patientId, admissionId, noteId);
//             },
//             child: Text('Delete'),
//           ),
//         ],
//       ),
//     );
//   }

// // Function to show add note dialog
//   void _showAddNoteDialog(
//       BuildContext context, String patientId, String admissionId) {
//     final textController = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Add Doctor Note'),
//         content: TextField(
//           controller: textController,
//           decoration: InputDecoration(
//             hintText: 'Enter your note here',
//             border: OutlineInputBorder(),
//           ),
//           maxLines: 5,
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               if (textController.text.isNotEmpty) {
//                 // Get current date in the required format
//                 final now = DateTime.now();
//                 final formattedDate =
//                     "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

//                 // Close dialog first
//                 Navigator.pop(context);

//                 // Add the note
//                 await _addDoctorNote(
//                     patientId, admissionId, textController.text, formattedDate);

//                 // Refresh the UI by updating state and forcing the FutureBuilder to rebuild
//                 setState(() {
//                   _futureBuilderKey = UniqueKey();
//                 });
//               }
//             },
//             child: Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }

// Function to fetch doctor notes
//   Future<List<dynamic>> _fetchDoctorNotes(
//       String patientId, String admissionId) async {
//     final url =
//         Uri.parse('${KVM_URL}/doctors/fetchNotes/$patientId/$admissionId');
//     print(url);
//     try {
//       final response = await http.get(
//         url,
//       );
//       print(response.body);
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         return data['doctorNotes'];
//       } else {
//         final error = jsonDecode(response.body);
//         throw Exception("Error: ${error['message']}");
//       }
//     } catch (e) {
//       throw Exception("Failed to fetch doctor notes: $e");
//     }
//   }

// // Function to add a doctor note
//   Future<void> _addDoctorNote(
//       String patientId, String admissionId, String text, String date) async {
//     try {
//       await doctor.addDoctorNote(
//         patientId: patientId,
//         admissionId: admissionId,
//         text: text,
//         date: date,
//       );

//       // The setState call will happen in the calling function
//     } catch (e) {
//       print("Error adding note: $e");
//     }
//   }

// // Function to delete a doctor note - fixed version
//   Future<void> _deleteNote(
//       String patientId, String admissionId, String noteId) async {
//     try {
//       await doctor.deleteDoctorNote(
//         patientId: patientId,
//         admissionId: admissionId,
//         noteId: noteId,
//       );

//       // Refresh the UI by updating state and forcing the FutureBuilder to rebuild
//       setState(() {
//         _futureBuilderKey = UniqueKey();
//       });
//     } catch (e) {
//       print("Error deleting note: $e");
//     }
//   }

// In your StatefulWidget class declaration, make sure to add:
  Key _futureBuilderKey = UniqueKey();
  // Horizontal drawer that opens from the middle
  Widget _buildHorizontalDrawer(
      BuildContext context, String patientId, String admissionId) {
    return HorizontalCenterDrawer(
      closedWidth: 50,
      openWidth: 300,
      child: _buildDoctorNotes(context, patientId, admissionId),
    );
  }

  // Doctor notes widget

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
          buildCustomActionButton(
            label: 'Add Symptom',
            startColor: Color(0xFF00B8D4),
            endColor: Color(0xFF00B8D4),
            onPressed: _addSymptom,
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

  Widget buildCustomActionButton({
    required String label,
    required Color startColor,
    required Color endColor,
    required VoidCallback onPressed,
    double width = 150,
    double height = 70,
    bool isLoading = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
              10), // Less rounded corners for more rectangular look
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [startColor.withOpacity(0.7), endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: startColor.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) const CircularProgressIndicator(color: Colors.white),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
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

// Action Button Widget
  // Action Button Widget with Gradient and Animation
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed, // Disable tap when loading
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isLoading
                ? SizedBox(
                    height: 36, // Same height as the icon
                    width: 36, // Same width as the icon
                    child: CustomLoadingAnimation(),
                  )
                : Icon(icon, size: 36, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

// Build Admission Details
  List<Widget> _buildAdmissionDetails(AdmissionRecord record) {
    return [
      _buildDetailRow(
        icon: Icons.calendar_today,
        label: 'Date',
        value: record.admissionDate,
      ),
      const SizedBox(height: 8),
      _buildDetailRow(
        icon: Icons.medical_services,
        label: 'Reason',
        value: record.reasonForAdmission ?? 'Not specified',
      ),
      const SizedBox(height: 8),
      _buildDetailRow(
        icon: Icons.healing,
        label: 'Symptoms',
        value: record.symptoms ?? 'No symptoms',
      ),
    ];
  }

// Detail Row Widget
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade600, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey.shade800),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  bool _isPrescriptionLoading = false;

// Then update your _fetchDoctorAdvice method to handle loading states appropriately
  Future<void> _fetchDoctorAdvice(
      BuildContext context, patientId, admissionId) async {
    setState(() => _isPrescriptionLoading = true);

    try {
      final url =
          '${KVM_URL}/reception/getDoctorAdvice/${patientId}/${admissionId}';

      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);
      final fileLink = data['fileLink'];

      if (fileLink != null) {
        Methods().openPdf(fileLink);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No file link found in the response')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      // Always reset the loading state, regardless of success or failure
      setState(() => _isPrescriptionLoading = false);
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
            _buildInfoRow(
                Icons.healing, 'Symptoms', record.symptoms ?? 'No symptoms'),
            _buildInfoRow(Icons.medical_services, 'Reason',
                record.reasonForAdmission ?? 'No reason provided'),
            _buildInfoRow(Icons.medical_services, 'Initial Diagnosis',
                record.initialDiagnosis ?? 'No initial diagnosis'),
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

class ViewTreatMentIntent extends Intent {}

class ViewHomeIntent extends Intent {}

class ViewMonitoringIntent extends Intent {}

class ViewInvestigationIntent extends Intent {}

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
