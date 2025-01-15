import 'package:doctordesktop/Doctor/AssignedLabScreen.dart';
import 'package:doctordesktop/Doctor/DoctorAdmittedPatientScreen.dart';
import 'package:doctordesktop/Doctor/DoctorPatientDetailScreen.dart';
import 'package:doctordesktop/Doctor/PatientDetailScreen.dart';
import 'package:doctordesktop/StateProvider.dart';
import 'package:doctordesktop/authProvider/auth_provider.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

final assignedPatientsProvider =
    StateNotifierProvider<AssignedPatientsNotifier, AsyncValue<List<Patient1>>>(
  (ref) {
    final authRepository = ref.read(authRepositoryProvider);
    final notifier = AssignedPatientsNotifier(authRepository);
    notifier.fetchAssignedPatients();
    return notifier;
  },
);

class AssignedPatientsScreen extends ConsumerStatefulWidget {
  const AssignedPatientsScreen({Key? key}) : super(key: key);

  @override
  _AssignedPatientsScreenState createState() => _AssignedPatientsScreenState();
}

class _AssignedPatientsScreenState
    extends ConsumerState<AssignedPatientsScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Initial manual refresh
    ref.refresh(assignedPatientsProvider.notifier).fetchAssignedPatients();
    // Set up the timer to refresh every 1 minute (60 seconds)
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      ref.refresh(assignedPatientsProvider.notifier).fetchAssignedPatients();
    });
  }

  @override
  void dispose() {
    // Cancel the timer when the screen is disposed to avoid memory leaks
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.black),
                onPressed: () {
                  // Refresh logic for assigned patients
                  ref
                      .refresh(assignedPatientsProvider.notifier)
                      .fetchAssignedPatients();
                },
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(19), // Adjust height of TabBar
            child: Container(
              color: Colors.black, // Background color for TabBar
              child: const TabBar(
                indicatorColor: Colors.cyan, // Tab selection indicator color
                labelColor: Colors.cyan, // Active tab text/icon color
                unselectedLabelColor:
                    Colors.grey, // Inactive tab text/icon color
                tabs: [
                  Tab(
                    icon: Icon(Icons.people),
                    text: 'Assigned Patients',
                  ),
                  Tab(
                    icon: Icon(Icons.people_outline_rounded),
                    text: 'Admitted Patient',
                  ),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            AssignedPatientsView(),
            AdmittedPatientsScreen(),
          ],
        ),
      ),
    );
  }
}

class AssignedPatientsView extends ConsumerWidget {
  const AssignedPatientsView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignedPatients = ref.watch(assignedPatientsProvider);
    final doctor = DoctorRepository();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),

      backgroundColor:
          Color(0xFFeff7f8), // Light background for the entire list
      body: assignedPatients.when(
        data: (patients) => ListView.builder(
          itemCount: patients.length,
          itemBuilder: (context, index) {
            final patient = patients[index];
            final admissionStatus = patient.admissionRecords.isNotEmpty
                ? patient.admissionRecords.first.status
                : 'Pending';

            // Set status color based on the admission status
            Color statusColor =
                admissionStatus == 'admitted' ? Colors.green : Colors.red;

            return Dismissible(
              key: Key(patient.id),
              direction: DismissDirection.startToEnd,
              onDismissed: (direction) async {
                bool? shouldDischarge =
                    await _showDischargeConfirmationDialog(context);

                if (shouldDischarge == true) {
                  await _dischargePatient(patient, ref);
                  ref
                      .read(assignedPatientsProvider.notifier)
                      .removePatient(patient);
                } else {
                  ref
                      .refresh(assignedPatientsProvider.notifier)
                      .fetchAssignedPatients();
                }
              },
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red, Colors.deepOrange],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              child: Card(
                color: Colors.white, // Black background for the card
                elevation: 15.0, // Add shadow for the card
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: const BorderSide(
                    color: Color(0Xffeff7f8), // Cyan border for the card
                    width: 2.0,
                  ),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                      Methods().getGoogleDriveDirectLink(patient.imageUrl),
                    ),
                    radius: 30,

                    // radius: 30,
                    // backgroundColor: Colors.cyan, // Cyan background for avatar
                    // child: Text(
                    //   patient.name[0].toUpperCase(),
                    //   style: const TextStyle(
                    //     fontSize: 24,
                    //     fontWeight: FontWeight.bold,
                    //     color: Colors.black, // Black text inside the avatar
                    //   ),
                    // ),
                  ),
                  title: Text(
                    patient.name,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color:
                          Colors.deepPurpleAccent, // Cyan color for the title
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Age: ${patient.age}, Gender: ${patient.gender}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: Colors.black, // Cyan color for the subtitle
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Status: $admissionStatus',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: statusColor, // Status-specific color
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // First Icon (Assign to Lab)
                      // IconButton(
                      //   icon: const Icon(
                      //     Icons.assignment_late,
                      //     color: Colors.cyan,
                      //     size: 28, // Larger icon size
                      //   ),
                      //   onPressed: () async {
                      //     await _handleAssignLab(context, patient, ref);
                      //   },
                      // ),
                      // Second Icon (Admit Patient)
                      // IconButton(
                      //   icon: const Icon(
                      //     Icons.person_add,
                      //     color: Colors.cyan,
                      //     size: 28, // Larger icon size
                      //   ),
                      //   onPressed: () async {
                      //     await _admitPatient(patient, ref, context);
                      //   },
                      // ),
                      ElevatedButton(
                        onPressed: () async {
                          await _admitPatient(patient, ref, context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.green, // Cyan background color
                          foregroundColor: Colors.white, // White text color
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(8), // Rounded corners
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8), // Padding for better appearance
                        ),
                        child: const Text(
                          "Admit Patient",
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold, // Bold text for emphasis
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          await _handleAssignLab(context, patient, ref);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan, // Cyan background color
                          foregroundColor: Colors.white, // White text color
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(8), // Rounded corners
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8), // Padding for better appearance
                        ),
                        child: const Text(
                          "Assign to Lab",
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold, // Bold text for emphasis
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      // Third Icon (Discharge Patient)
                      ElevatedButton(
                        onPressed: () async {
                          final admissionId = patient.admissionRecords.first.id;

                          // _showConditionDialog(context, admissionId, patient);
                          _showConditionDialog(
                              context, admissionId, patient, ref);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.green, // Cyan background color
                          foregroundColor: Colors.white, // White text color
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(8), // Rounded corners
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8), // Padding for better appearance
                        ),
                        child: const Text(
                          "Discharge  Patient",
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold, // Bold text for emphasis
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PatientDetailScreen4(patient: patient),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Trigger the refresh when the button is pressed
          ref.refresh(assignedPatientsProvider);
        },
        child: const Icon(Icons.refresh),
        backgroundColor: Colors.cyan, // Cyan background for the button
      ),
    );
  }

  Future<void> _showDischargeDialog(
      BuildContext context,
      String admissionId,
      String selectedCondition,
      double amount,
      Patient1 patient,
      WidgetRef ref) async {
    final doctor = DoctorRepository();
    bool? confirmDischarge = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Discharge',
              style: TextStyle(color: Colors.deepPurple)),
          content: const Text(
              'Are you sure you want to discharge this patient?',
              style: TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                _showConditionDialog(context, admissionId, patient, ref);
              },
              child: const Text('Back', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Confirm Discharge',
                  style: TextStyle(color: Colors.deepPurple)),
            ),
          ],
        );
      },
    );

    if (confirmDischarge == true) {
      try {
        final response = await doctor.updateConditionAtDischarge(
          admissionId: admissionId,
          conditionAtDischarge: selectedCondition,
          amountToBePayed: amount,
        );

        await _dischargePatient(patient, ref); // Pass ref here

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Discharge successful: ${response['message']}'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to discharge patient')),
        );
      }
    }
  }

  Future<void> _showConditionDialog(BuildContext context, String admissionId,
      Patient1 patient, WidgetRef ref) async {
    String selectedCondition = 'Discharged'; // Default value for condition
    String additionalInfo = ''; // Default empty text field
    String amountToBePayed = ''; // New field for amount

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Update Condition at Discharge'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedCondition,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCondition = newValue!;
                      });
                    },
                    items: <String>[
                      'Discharged',
                      "Transferred",
                      "A.M.A.",
                      "Absconded",
                      "Expired"
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (text) {
                      additionalInfo = text;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Additional Information',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (text) {
                      amountToBePayed = text;
                    },
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount to be Paid',
                      border: OutlineInputBorder(),
                    ),
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
                    final amount = double.tryParse(amountToBePayed);
                    if (amount == null || amount < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid amount entered')),
                      );
                      return;
                    }
                    Navigator.of(context).pop();
                    await _showDischargeDialog(context, admissionId,
                        selectedCondition, amount, patient, ref); // Pass ref
                  },
                  child: const Text('Next'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class OtherScreenView extends StatelessWidget {
  const OtherScreenView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'This is the other screen',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

Future<bool?> _showDischargeConfirmationDialog(BuildContext context) async {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Confirm Discharge',
            style: TextStyle(color: Colors.deepPurple)),
        content: const Text('Are you sure you want to discharge this patient?',
            style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discharge',
                style: TextStyle(color: Colors.deepPurple)),
          ),
        ],
      );
    },
  );
}

Future<void> _dischargePatient(Patient1 patient, WidgetRef ref) async {
  try {
    final admissionId = patient.admissionRecords.isNotEmpty
        ? patient.admissionRecords.first.id
        : '';
    final authRepository = ref.read(authRepositoryProvider);
    final result = await authRepository.dischargePatient(
      patientId: patient.patientId,
      admissionId: admissionId,
    );
    print("the admission id is ${admissionId}");
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(result['message'] ?? 'Unknown error occurred.'),
    //     backgroundColor:
    //         (result['success'] as bool? ?? false) ? Colors.green : Colors.red,
    //   ),
    // );
    ;

    ref.refresh(assignedPatientsProvider.notifier).fetchAssignedPatients();
  } catch (e) {
    print('Error discharging patient: $e');
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('Error discharging patient: $e'),
    //     backgroundColor: Colors.red,
    //   ),
    // );
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

class SelectAdmissionDialog extends StatelessWidget {
  final List<AdmissionRecord> admissionRecords;

  const SelectAdmissionDialog({
    Key? key,
    required this.admissionRecords,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Admission Record',
          style: TextStyle(color: Colors.deepPurple)),
      content: SingleChildScrollView(
        child: Column(
          children: admissionRecords.map((admission) {
            return ListTile(
              title: Text('Admission Date: ${admission.admissionDate}'),
              subtitle: Text('Reason: ${admission.reasonForAdmission}'),
              onTap: () {
                Navigator.of(context).pop(admission.id);
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}

class AssignLabDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return AlertDialog(
      title: const Text('Assign to Lab',
          style: TextStyle(color: Colors.deepPurple)),
      content: TextField(
        controller: controller,
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
            Navigator.of(context).pop(controller.text);
          },
          child:
              const Text('Assign', style: TextStyle(color: Colors.deepPurple)),
        ),
      ],
    );
  }
}
