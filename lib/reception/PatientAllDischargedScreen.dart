import 'dart:convert';

import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/model/patientDischargeModel.dart';
import 'package:doctordesktop/reception/ExportSummaryScreen.dart';
import 'package:doctordesktop/reception/GenerateBillScreen.dart';
import 'package:doctordesktop/reception/GenerateIpdBillScreen.dart';
import 'package:doctordesktop/reception/GenerateOpdBill.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class DischargedPatientsNotifier
    extends StateNotifier<AsyncValue<List<PatientDischarge>>> {
  DischargedPatientsNotifier() : super(const AsyncValue.loading()) {
    fetchDischargedPatients();
  }

  Future<void> fetchDischargedPatients() async {
    try {
      final response = await http
          .get(Uri.parse('${VERCEL_URL}/reception/getAllDischargedPatient'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final patients =
            data.map((json) => PatientDischarge.fromJson(json)).toList();
        state = AsyncValue.data(patients);
      } else {
        throw Exception('Failed to load discharged patients');
      }
    } catch (e) {
      // state = AsyncValue.error(e);
    }
  }

  // Manual refresh method
  Future<void> manualRefresh() async {
    state = const AsyncValue.loading(); // Set state to loading while fetching
    await fetchDischargedPatients();
  }
}

final dischargedPatientsProvider = StateNotifierProvider<
    DischargedPatientsNotifier, AsyncValue<List<PatientDischarge>>>(
  (ref) => DischargedPatientsNotifier(),
);

class DischargedPatientsScreen1 extends ConsumerStatefulWidget {
  const DischargedPatientsScreen1({Key? key}) : super(key: key);

  @override
  _DischargedPatientsScreen1State createState() =>
      _DischargedPatientsScreen1State();
}

class _DischargedPatientsScreen1State
    extends ConsumerState<DischargedPatientsScreen1> {
  @override
  void initState() {
    super.initState();
    // Initial data fetch or any setup logic
    ref.read(dischargedPatientsProvider.notifier).fetchDischargedPatients();
  }

  @override
  Widget build(BuildContext context) {
    final dischargedPatientsAsync = ref.watch(dischargedPatientsProvider);

    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Scaffold(
        backgroundColor: Color(0xFFeff7f8),
        appBar: AppBar(
          title: const Text('Discharged Patients'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // Trigger the manual refresh
                ref.read(dischargedPatientsProvider.notifier).manualRefresh();
              },
            ),
          ],
        ),
        body: dischargedPatientsAsync.when(
          data: (patients) {
            if (patients.isEmpty) {
              return const Center(
                child: Text('No discharged patients found.'),
              );
            }
            return ListView.builder(
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final patient = patients[index];
                return Card(
                  color: Colors.white,
                  margin:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: Colors.black45,
                  child: InkWell(
                    onTap: () async {
                      final shouldRefresh = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PatientDetailsScreen(patient: patient),
                        ),
                      );
                      if (shouldRefresh == true) {
                        // Fetch the data again after coming back
                        ref
                            .read(dischargedPatientsProvider.notifier)
                            .fetchDischargedPatients();
                      }
                    },
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                      title: Text(
                        'Name ${patient.name}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.deepPurple[700],
                          letterSpacing: 1.2,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gender: ${patient.gender}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Contact: ${patient.contact}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Discharge Date: ${patient.lastRecord.dischargeDate}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.deepPurple[700],
                        size: 24,
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Error: ${error.toString()}'),
          ),
        ),
      ),
    );
  }
}

class PatientDetailsScreen extends StatefulWidget {
  final PatientDischarge patient;

  const PatientDetailsScreen({Key? key, required this.patient})
      : super(key: key);

  @override
  _PatientDetailsScreenState createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final TextEditingController _billingAmountController =
      TextEditingController();
  final TextEditingController _amountPaidController = TextEditingController();
  bool _isDischargedByReception = false;

  @override
  void initState() {
    super.initState();
    _isDischargedByReception = widget.patient.lastRecord.dischargedByReception;
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _toggleDischargeByReception(bool value) async {
    if (value) {
      bool confirm = await _showConfirmationDialog(context);
      if (confirm) {
        setState(() {
          _isDischargedByReception = true;
        });
        // Call the backend to update the discharge status
        await _updateDischargeStatus();
      }
    } else {
      setState(() {
        _isDischargedByReception = false;
      });
    }
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirm Discharge'),
            content: Text('Are you sure you want to discharge this patient?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _updateDischargeStatus() async {
    // Replace with your API call
    final response = await http.put(
      Uri.parse(
          '${VERCEL_URL}/reception/dischargeByReceptionCondition/${widget.patient.patientId}/${widget.patient.lastRecord.admissionId}'),
    );
    print("heeeloooo ${response.body}");
    if (response.statusCode == 200) {
      _showSnackBar(context, "Patient discharged successfully.");
    } else {
      _showSnackBar(context, "Failed to discharge patient.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.patient.lastRecord;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(
                  context, true); // Indicate that data should be refreshed
            },
          )
        ],
        title: Text(widget.patient.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('Patient ID: ${widget.patient.patientId}',
                style: const TextStyle(fontSize: 16)),
            Text('Gender: ${widget.patient.gender}',
                style: const TextStyle(fontSize: 16)),
            Text('Contact: ${widget.patient.contact}',
                style: const TextStyle(fontSize: 16)),
            const Divider(),
            // Expandable Section for Admission Details
            ExpansionTile(
              title: const Text('Admission Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              children: [
                Text('Admission ID: ${record.admissionId}',
                    style: const TextStyle(fontSize: 16)),
                Text('Admission Date: ${record.admissionDate}',
                    style: const TextStyle(fontSize: 16)),
                Text('Discharge Date: ${record.dischargeDate}',
                    style: const TextStyle(fontSize: 16)),
                Text('Reason for Admission: ${record.reasonForAdmission}',
                    style: const TextStyle(fontSize: 16)),
                Text('Condition at Discharge: ${record.conditionAtDischarge}',
                    style: const TextStyle(fontSize: 16)),
                Text('Symptoms: ${record.symptoms}',
                    style: const TextStyle(fontSize: 16)),
                Text('Initial Diagnosis: ${record.initialDiagnosis}',
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
            const Divider(),
            Text('Doctor: ${record.doctor.name}',
                style: const TextStyle(fontSize: 16)),
            Text('Weight: ${record.weight} kg',
                style: const TextStyle(fontSize: 16)),
            Text(
                'Previous Remaining Amount: \$${record.previousRemainingAmount}',
                style: const TextStyle(fontSize: 16)),
            Text('Amount to be Paid: \$${record.amountToBePayed}',
                style: const TextStyle(fontSize: 16)),
            Text(
                'Discharge By Reception: ${_isDischargedByReception ? "Yes" : "No"}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            SwitchListTile(
              title: Text('Discharge by Reception'),
              value: _isDischargedByReception,
              onChanged: _toggleDischargeByReception,
            ),
            const SizedBox(height: 10),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GenerateBillScreen(
                              patientId: widget.patient.patientId),
                        ),
                      );
                    },
                    child: const Text('Generate Bill'),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _showSnackBar(context, "Generating Prescription...");
                    },
                    child: const Text('Generate Prescription'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Additional buttons as per your original layout...
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Expanded(
                //   child: ElevatedButton(
                //     onPressed: () {
                //       // _showSnackBar(context, "Fetching Receipt...");
                //       _fetchDoctorReceipt(
                //           context,
                //           widget.patient.patientId,
                //           _amountPaidController.text,
                //           _billingAmountController.text);
                //     },
                //     child: const Text('Fetch Receipt'),
                //   ),
                // ),
                const SizedBox(width: 20),
                // Expanded(
                //   child: ElevatedButton(
                //     onPressed: () {
                //       // _showSnackBar(context, "Fetching Doctor Sheet...");
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //           builder: (context) => FourButtonScreen(
                //               patientId: widget.patient.patientId,
                //               admissionId: record.admissionId),
                //         ),
                //       );
                //     },
                //     child: const Text('Export Summary'),
                //   ),
                // ),
              ],
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // _showSnackBar(context, "Fetching Receipt...");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GenerateIpdBillScreen(
                                  patientId: widget.patient.patientId,
                                  remainingAmount:
                                      record.previousRemainingAmount.toString(),
                                )),
                      );
                    },
                    child: const Text('Generate IPD Receipt'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // _showSnackBar(context, "Fetching Doctor Sheet...");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GenerateOpdBillScreen(
                                  patientId: widget.patient.patientId,
                                )),
                      );
                    },
                    child: const Text('OPD Bill'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchDoctorAdvice(BuildContext context, patientId) async {
    final url = '${VERCEL_URL}/reception/getDoctorAdvice/${patientId}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fileLink = data['fileLink'];
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

  Future<void> _fetchDoctorReceipt(BuildContext context, patientId,
      String amount, String billingAmount) async {
    final url =
        '${VERCEL_URL}/reception/receipt/${patientId}/${amount}/${billingAmount}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fileLink = data['fileLink'];
        print('fileLink: ' + fileLink);
        if (fileLink != null) {
          Methods().downloadFile(fileLink, 'doctor_receipt.pdf', context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No file link found in the response')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch doctor receipt')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
