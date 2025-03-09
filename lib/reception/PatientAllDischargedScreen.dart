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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class DischargedPatientsNotifier
    extends StateNotifier<AsyncValue<List<PatientDischarge>>> {
  DischargedPatientsNotifier() : super(const AsyncValue.loading()) {
    fetchDischargedPatients();
  }

  Future<void> fetchDischargedPatients() async {
    print('Fetching discharged patients...');
    try {
      final response = await http
          .get(Uri.parse('${KVM_URL}/reception/getAllDischargedPatient'));
      print(response.body);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final patients =
            data.map((json) => PatientDischarge.fromJson(json)).toList();
        state = AsyncValue.data(patients);
      } else {
        throw Exception('Failed to load discharged patients');
      }
    } catch (e) {
      print('Error fetching discharged patients: $e');

      // state = AsyncValue.error(e);
    }
  }

  // Manual refresh method
  Future<void> manualRefresh() async {
    print('Manual refresh');
    state = const AsyncValue.loading(); // Set state to loading
    await fetchDischargedPatients(); // Fetch new data
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
  @override
  void initState() {
    super.initState();
    ref.refresh(dischargedPatientsProvider.notifier).fetchDischargedPatients();
    // Listen for route changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ModalRoute.of(context)!.addScopedWillPopCallback(() async {
        await ref.refresh(dischargedPatientsProvider.notifier).manualRefresh();
        return true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final dischargedPatientsAsync = ref.watch(dischargedPatientsProvider);
    int total = dischargedPatientsAsync.when(
      data: (data) => data.length,
      loading: () => 0,
      error: (error, stack) => 0,
    );

    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: 50,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF005F9E),
                Color(0xFF00B8D4),
              ], // Purple to Blue gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              'Total Discharged Patients: ${total}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Color(0xFFeff7f8),
      appBar: AppBar(
        title: const Text('Discharged Patients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Trigger the manual refresh
              ref.invalidate(dischargedPatientsProvider);
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF005F9E),
                Color(0xFF00B8D4),
              ], // Purple to Blue gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
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
                color: Colors.blueAccent,
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
                      print("shouldRefresh $shouldRefresh");
                      if (shouldRefresh == null) {
                        ref
                            .read(dischargedPatientsProvider.notifier)
                            .manualRefresh();
                      }
                    },
                    child: ListTile(
                      hoverColor: Colors.blue[100],
                      contentPadding: const EdgeInsets.all(20),
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor:
                            Colors.transparent, // Removes the background color
                        backgroundImage: AssetImage('assets/images/p2.png'),
                        radius: 30,
                      ),
                      title: Text(
                        'Name : ${patient.name}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Color(0xFF2A79B4),
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.male, size: 18, color: Colors.cyan),
                                SizedBox(width: 8),
                                Text(
                                  'Gender: ${patient.gender}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.phone,
                                    size: 18, color: Colors.black54),
                                SizedBox(width: 8),
                                Text(
                                  'Contact: ${patient.contact}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(FontAwesomeIcons.calendarWeek,
                                    size: 20, color: Colors.deepPurple[700]),
                                SizedBox(width: 8),
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Discharged: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            '${patient.lastRecord.dischargeDate.split(' ')[0]} ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                          color: Colors.black,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            ' ${patient.lastRecord.dischargeDate.split(' ')[1]} ${patient.lastRecord.dischargeDate.split(' ')[2]}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    )),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error: ${error.toString()}'),
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
          '${KVM_URL}/reception/dischargeByReceptionCondition/${widget.patient.patientId}/${widget.patient.lastRecord.admissionId}'),
    );
    print("heeeloooo ${response.body}");
    if (response.statusCode == 200) {
      // Update the UI to reflect the discharge status
      _showSnackBar(context, "Patient discharged successfully.");
    } else {
      _showSnackBar(context, "Failed to discharge patient.");
    }
  }

  @override
  final Color _primaryColor = const Color(0xFF2A79B4);
  final Color _accentColor = const Color(0xFF00C2CB);
  final Color _backgroundColor = const Color(0xFFF8F9FA);

  @override
  @override
  Widget build(BuildContext context) {
    final record = widget.patient.lastRecord;
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(context),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPatientHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: Column(
                children: [
                  // Top Row - Patient Info and Admission Details
                  Expanded(
                    flex: 2,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Pane - Patient Information
                        Expanded(
                          flex: 1,
                          child: _buildInfoCard(
                            'Patient Information',
                            Icons.person_outline,
                            [
                              _buildInfoRow(
                                  'Patient ID', widget.patient.patientId),
                              _buildInfoRow('Gender', widget.patient.gender),
                              _buildInfoRow('Contact', widget.patient.contact),
                              // _buildInfoRow(
                              //     'Date of Birth', widget.patient.dob),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Right Pane - Admission Details
                        Expanded(
                          flex: 1,
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.medical_services,
                                          color: _primaryColor),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Admission Details',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: _primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          _buildInfoRow('Admission ID',
                                              record.admissionId),
                                          _buildInfoRow('Admission Date',
                                              record.admissionDate),
                                          _buildInfoRow('Discharge Date',
                                              record.dischargeDate),
                                          _buildInfoRow('Reason',
                                              record.reasonForAdmission),
                                          _buildInfoRow('Condition',
                                              record.conditionAtDischarge),
                                          _buildInfoRow(
                                              'Symptoms', record.symptoms),
                                          _buildInfoRow('Diagnosis',
                                              record.initialDiagnosis),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bottom Row - Medical and Actions
                  Expanded(
                    flex: 3,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Pane - Medical Overview
                        Expanded(
                          flex: 1,
                          child: _buildMedicalInfoCard(record),
                        ),
                        const SizedBox(width: 16),

                        // Right Pane - Discharge and Actions
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              // Discharge Section
                              Expanded(
                                flex: 3,
                                child: _buildDischargeSection(),
                              ),
                              const SizedBox(height: 16),

                              // Action Buttons
                              Expanded(
                                flex: 3,
                                child: _buildActionButtons(record),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: _primaryColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context, true),
      ),
      title: Text(
        widget.patient.name,
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [_primaryColor, _accentColor],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patient.name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Patient ID: ${widget.patient.patientId}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdmissionDetails(record) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      collapsedBackgroundColor: Colors.white,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Row(
        children: [
          Icon(Icons.medical_services, color: _primaryColor),
          const SizedBox(width: 12),
          Text(
            'Admission Details',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
          ),
        ],
      ),
      children: [
        _buildInfoRow('Admission ID', record.admissionId),
        _buildInfoRow('Admission Date', record.admissionDate),
        _buildInfoRow('Discharge Date', record.dischargeDate),
        _buildInfoRow('Reason', record.reasonForAdmission),
        _buildInfoRow('Condition', record.conditionAtDischarge),
        _buildInfoRow('Symptoms', record.symptoms),
        _buildInfoRow('Diagnosis', record.initialDiagnosis),
      ],
    );
  }

  Widget _buildMedicalInfoCard(record) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.monitor_heart, color: _primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Medical Overview',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMedicalStat(
                'Weight', '${record.weight} kg', Icons.line_weight),
            _buildMedicalStat('Previous Balance',
                '\$${record.previousRemainingAmount}', Icons.attach_money),
            _buildMedicalStat(
                'Amount Due', '\$${record.amountToBePayed}', Icons.payment),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalStat(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: _accentColor, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDischargeSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.exit_to_app, color: _primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Discharge Control',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Mark as Discharged',
                style: GoogleFonts.poppins(fontSize: 15),
              ),
              subtitle: Text(
                'Confirm patient discharge status',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              activeColor: _accentColor,
              activeTrackColor: _accentColor.withOpacity(0.2),
              value: _isDischargedByReception,
              onChanged: _toggleDischargeByReception,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(record) {
    return // ... Rest of the code remains the same until the action buttons section

// Updated Action Buttons Section
        Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Generate Bill',
                Icons.receipt_long,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        GenerateBillScreen(patientId: widget.patient.patientId),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                  'Generate OPD Bill',
                  Icons.assignment,
                  () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GenerateOpdBillScreen(
                                  patientId: widget.patient.patientId,
                                )),
                      )),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                  'Generate IPD Receipt',
                  Icons.summarize,
                  () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GenerateIpdBillScreen(
                                  patientId: widget.patient.patientId,
                                  remainingAmount:
                                      record.previousRemainingAmount.toString(),
                                )),
                      )),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                '',
                Icons.history,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        GenerateBillScreen(patientId: widget.patient.patientId),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );

// ... Rest of the code remains the sa
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 20),
      label:
          Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: _primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 3,
        shadowColor: Colors.black12,
      ),
    );
  }
}
