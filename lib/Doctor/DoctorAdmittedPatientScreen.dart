import 'package:doctordesktop/Doctor/DoctorPatientDetailScreen.dart';
import 'package:doctordesktop/StateProvider.dart';
import 'package:doctordesktop/authProvider/auth_provider.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final assignedPatientsProvider =
    StateNotifierProvider<AdmittedPatientsNotifier, AsyncValue<List<Patient1>>>(
  (ref) {
    final authRepository = ref.read(authRepositoryProvider);
    final notifier = AdmittedPatientsNotifier(authRepository);
    notifier.fetchAdmittedPatients();
    return notifier;
  },
);
final assignedPatientsProvider1 =
    StateNotifierProvider<AssignedPatientsNotifier, AsyncValue<List<Patient1>>>(
  (ref) {
    final authRepository = ref.read(authRepositoryProvider);
    final notifier = AssignedPatientsNotifier(authRepository);
    notifier.fetchAssignedPatients();
    return notifier;
  },
);

class AdmittedPatientsScreen extends ConsumerStatefulWidget {
  const AdmittedPatientsScreen({Key? key}) : super(key: key);

  @override
  _AssignedPatientsScreenState createState() => _AssignedPatientsScreenState();
}

class _AssignedPatientsScreenState
    extends ConsumerState<AdmittedPatientsScreen> {
  final doctor = DoctorRepository();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.refresh(assignedPatientsProvider.notifier).fetchAdmittedPatients();
  }

  Widget build(BuildContext context) {
    final assignedPatients = ref.watch(assignedPatientsProvider);

    return Scaffold(
      backgroundColor: Color(0xFFeff7f8),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bb1.png'),
            opacity: 0.3,
            fit: BoxFit.cover,
          ),
        ),
        child: assignedPatients.when(
          data: (patients) => ListView.builder(
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index];
              final admissionStatus = patient.admissionRecords.isNotEmpty
                  ? patient.admissionRecords.first.status
                  : 'Pending';

              Color statusColor =
                  admissionStatus == 'admitted' ? Colors.green : Colors.red;

              return Card(
                color: Colors.white,
                elevation: 20.0,
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: const BorderSide(
                    color: Colors.white,
                    width: 2.0,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF005F9E),
                        Color(0xFF00B8D4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.cyan,
                      child: Text(
                        patient.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    title: Text(
                      patient.name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Age: ${patient.age}, Gender: ${patient.gender}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Status: $admissionStatus',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            await _handleAssignLab(context, patient, ref);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.cyan, // Cyan background color
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
                        ElevatedButton(
                          onPressed: () async {
                            final admissionId =
                                patient.admissionRecords.first.id;
                            _showConditionDialog(
                                context, admissionId, patient, ref);

                            // bool? shouldDischarge =
                            //     await _showDischargeConfirmationDialog(context);
                            // if (shouldDischarge == true) {
                            //   await _dischargePatient(patient, ref);
                            //   ref
                            //       .read(assignedPatientsProvider.notifier)
                            //       .removePatient(patient);
                            // }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Discharge"),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.refresh(assignedPatientsProvider);
        },
        child: const Icon(Icons.refresh),
        backgroundColor: Colors.cyan,
      ),
    );
  }

  Future<void> _showConditionDialog(BuildContext context, String admissionId,
      Patient1 patient, WidgetRef ref) async {
    String selectedCondition = 'Discharged';
    String additionalInfo = '';
    String amountToBePayed = '';

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

                  // ... [keep dropdown and other fields unchanged] ...
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
                    String amountText = amountToBePayed.trim();
                    if (amountText.isEmpty) {
                      amountText = '0'; // Set to zero if empty
                    }

                    // First parse as double to handle decimal inputs
                    final doubleAmount = double.tryParse(amountText);
                    if (doubleAmount == null || doubleAmount < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid numeric amount'),
                        ),
                      );
                      return;
                    }

                    // Convert to integer (truncates decimal values)
                    final intAmount = doubleAmount.toInt();

                    Navigator.of(context).pop();
                    await _showDischargeDialog(
                      context,
                      admissionId,
                      selectedCondition,
                      intAmount, // Pass integer value
                      patient,
                      ref,
                    );
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

  Future<void> _showDischargeDialog(BuildContext context, String admissionId,
      String selectedCondition, int amount, Patient1 patient, ref) async {
    bool confirmDischarge = await showDialog<bool>(
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
                  child:
                      const Text('Back', style: TextStyle(color: Colors.grey)),
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
        ) ??
        false; // Default to false if null

    if (confirmDischarge == true) {
      try {
        final response = await doctor.updateConditionAtDischarge(
          admissionId: admissionId,
          conditionAtDischarge: selectedCondition,
          amountToBePayed: amount.toInt(),
        );

        await _dischargePatient(patient, ref);

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );

      ref.refresh(assignedPatientsProvider.notifier).fetchAdmittedPatients();
      ref.refresh(assignedPatientsProvider1.notifier).fetchAssignedPatients();
    } catch (e) {
      ref.refresh(assignedPatientsProvider.notifier).fetchAdmittedPatients();
      // ref.refresh(assignedPatientsProvider.notifier).fe;
      ref.refresh(assignedPatientsProvider1.notifier).fetchAssignedPatients();

      print('Error discharging patient: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Discharged patient: $e'),
          backgroundColor: Colors.green,
        ),
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

      ref.refresh(assignedPatientsProvider.notifier).fetchAdmittedPatients();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign lab: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
