import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';

class PatientAssignmentScreen extends StatefulWidget {
  @override
  _PatientAssignmentScreenState createState() =>
      _PatientAssignmentScreenState();
}

class _PatientAssignmentScreenState extends State<PatientAssignmentScreen> {
  List<Map<String, dynamic>> doctors = [];
  String? selectedDoctorId;
  String? selectedDoctorName;
  List<Map<String, dynamic>> patients = [];
  Map<String, dynamic>? selectedPatient;
  bool isLoading = false;
  bool isAssigning = false;
  String error = '';
  String successMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final response =
          await http.get(Uri.parse('${KVM_URL}/reception/listDoctors'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Store full doctor objects with IDs
        if (data['doctors'] != null && data['doctors'].isNotEmpty) {
          setState(() {
            doctors = List<Map<String, dynamic>>.from(data['doctors']);
          });
        } else {
          setState(() {
            doctors = [];
            error = ''; // Clear any existing error
          });
        }
      } else {
        setState(() {
          error = 'Failed to load doctors: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        error = 'Network error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchPatients() async {
    if (selectedDoctorName == null) return;

    setState(() {
      isLoading = true;
      error = '';
      patients = [];
      selectedPatient = null; // Reset selected patient when changing doctors
    });

    try {
      final response = await http.get(
        Uri.parse(
            '${KVM_URL}/reception/getPatientAssignedToDoctor/$selectedDoctorName'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // Handle empty patients array properly
          patients = List<Map<String, dynamic>>.from(data['patients'] ?? []);
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        // Handle "no patients found" as an empty list, not an error
        setState(() {
          patients = [];
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load patients: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _assignDoctor(String newDoctorId) async {
    if (selectedPatient == null) {
      _showErrorDialog('No patient selected');
      return;
    }

    // Check if patient has admission records
    if (selectedPatient!['admissionRecords'] == null ||
        (selectedPatient!['admissionRecords'] as List).isEmpty) {
      _showErrorDialog('Patient has no admission records');
      return;
    }

    // Get the latest admission record ID
    final admissionId = selectedPatient!['admissionRecords'][0]['_id'];
    final patientId = selectedPatient!['patientId'];
    final admissionRecord = selectedPatient!['admissionRecords'][0];

    // Debug what fields are available in the admission record
    print("Admission record fields: ${admissionRecord.keys.toList()}");
    setState(() {
      isAssigning = true;
      error = '';
      successMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('${KVM_URL}/reception/assign-Doctor'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patientId': patientId,
          'doctorId': newDoctorId,
          'admissionId': admissionId,
        }),
      );
      print(response.body);
      print(admissionId);
      print(patientId);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          successMessage = data['message'] ?? 'Doctor assigned successfully';

          // Refresh the patient list to reflect changes
          _fetchPatients();
        });

        // Show success dialog
        _showSuccessDialog(successMessage);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to assign doctor');
      }
    } catch (e) {
      setState(() {
        error = 'Error assigning doctor: $e';
      });
      _showErrorDialog(error);
    } finally {
      setState(() {
        isAssigning = false;
      });
    }
  }

  void _showAssignDoctorDialog() {
    if (selectedPatient == null) {
      _showErrorDialog('Please select a patient first');
      return;
    }

    String? newDoctorId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Doctor'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Container(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assign a new doctor to ${selectedPatient!['name']}',
                    style: TextStyle(color: HospitalTheme.textMedium),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Current Doctor: $selectedDoctorName',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.primary,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: HospitalTheme.radiusSmall,
                      border: Border.all(color: HospitalTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: Text('Select New Doctor'),
                        value: newDoctorId,
                        items: doctors
                            .where((doc) => doc['_id'] != selectedDoctorId)
                            .map((doctor) {
                          return DropdownMenuItem<String>(
                            value: doctor['_id'],
                            child: Text(
                              doctor['doctorName'] ?? 'Unknown',
                              style: TextStyle(color: HospitalTheme.textDark),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            newDoctorId = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (newDoctorId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please select a doctor')),
                );
                return;
              }
              Navigator.pop(context);
              _assignDoctor(newDoctorId!);
            },
            child: Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient Assignment',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'View and manage patient assignments to doctors',
              style: TextStyle(
                fontSize: 14,
                color: HospitalTheme.textMedium,
              ),
            ),
          ],
        ),
        _buildDoctorSelector(),
      ],
    );
  }

  Widget _buildDoctorSelector() {
    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: HospitalTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedDoctorId,
          hint: Text(
            doctors.isEmpty ? 'No doctors available' : 'Select Doctor',
            style: TextStyle(color: HospitalTheme.textMedium),
          ),
          icon: Icon(Icons.arrow_drop_down, color: HospitalTheme.primary),
          isExpanded: true,
          disabledHint: doctors.isEmpty
              ? Text(
                  'No doctors available',
                  style: TextStyle(color: HospitalTheme.textMedium),
                )
              : null,
          onChanged: doctors.isEmpty
              ? null // Disable dropdown if no doctors
              : (String? doctorId) {
                  final selectedDoctor = doctors.firstWhere(
                    (doc) => doc['_id'] == doctorId,
                    orElse: () => {"doctorName": "Unknown"},
                  );

                  setState(() {
                    selectedDoctorId = doctorId;
                    selectedDoctorName = selectedDoctor['doctorName'];
                  });

                  _fetchPatients();
                },
          items: doctors.map<DropdownMenuItem<String>>((doctor) {
            return DropdownMenuItem<String>(
              value: doctor['_id'],
              child: Text(
                doctor['doctorName'] ?? 'Unknown',
                style: TextStyle(color: HospitalTheme.textDark),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading && patients.isEmpty && doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: HospitalTheme.primary),
            const SizedBox(height: 16),
            Text(
              'Loading data...',
              style: TextStyle(color: HospitalTheme.textMedium),
            ),
          ],
        ),
      );
    }

    if (error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              error,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchDoctors,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: HospitalTheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 64,
              color: HospitalTheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No doctors available in the system',
              style: TextStyle(
                fontSize: 18,
                color: HospitalTheme.textMedium,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchDoctors,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: HospitalTheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (selectedDoctorName == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: HospitalTheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Please select a doctor to view assigned patients',
              style: TextStyle(
                fontSize: 18,
                color: HospitalTheme.textMedium,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Now show the UI for when doctor is selected, even if no patients
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Patient List Panel
        Expanded(
          flex: 2,
          child: _buildPatientListPanel(),
        ),
        const SizedBox(width: 24),
        // Patient Details Panel - only show when a patient is selected
        Expanded(
          flex: 3,
          child: selectedPatient != null
              ? _buildPatientDetailsPanel()
              : Container(
                  decoration: BoxDecoration(
                    color: HospitalTheme.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: HospitalTheme.border),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 64,
                          color: HospitalTheme.textMedium.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          patients.isEmpty
                              ? 'No patients assigned to this doctor'
                              : 'Select a patient to view details',
                          style: TextStyle(
                            fontSize: 16,
                            color: HospitalTheme.textMedium,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPatientListPanel() {
    return Container(
      decoration: BoxDecoration(
        color: HospitalTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: HospitalTheme.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Assigned Patients',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: HospitalTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${patients.length} Patients',
                    style: TextStyle(
                      color: HospitalTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: HospitalTheme.border),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LinearProgressIndicator(
                backgroundColor: HospitalTheme.primary.withOpacity(0.1),
                color: HospitalTheme.primary,
              ),
            ),
          Expanded(
            child: patients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 48,
                          color: HospitalTheme.textMedium.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No patients assigned to this doctor',
                          style: TextStyle(
                            color: HospitalTheme.textMedium,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: patients.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: HospitalTheme.border),
                    itemBuilder: (context, index) {
                      final patient = patients[index];
                      final isSelected = selectedPatient == patient;

                      return Material(
                        color: isSelected
                            ? HospitalTheme.primary.withOpacity(0.1)
                            : HospitalTheme.cardBackground,
                        child: InkWell(
                          onTap: () =>
                              setState(() => selectedPatient = patient),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: isSelected
                                    ? HospitalTheme.primary
                                    : HospitalTheme.accent.withOpacity(0.2),
                                child: Text(
                                  patient['name'] != null &&
                                          patient['name'].toString().isNotEmpty
                                      ? patient['name'][0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : HospitalTheme.primary,
                                  ),
                                ),
                              ),
                              title: Text(
                                patient['name'] ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: HospitalTheme.textDark,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: ${patient['patientId'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: HospitalTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${patient['age'] ?? 'N/A'} yrs | ${patient['gender'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: HospitalTheme.textMedium,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: isSelected
                                    ? HospitalTheme.primary
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientDetailsPanel() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey<String>(
            selectedPatient?['patientId']?.toString() ?? 'no-patient'),
        decoration: BoxDecoration(
          color: HospitalTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: HospitalTheme.border),
        ),
        child: selectedPatient == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 64,
                      color: HospitalTheme.textMedium.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select a patient to view details',
                      style: TextStyle(
                        fontSize: 16,
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // Action buttons for patient
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: HospitalTheme.surfaceLight,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Patient Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: HospitalTheme.primary,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed:
                              isAssigning ? null : _showAssignDoctorDialog,
                          icon: isAssigning
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(Icons.swap_horiz),
                          label: Text('Reassign Doctor'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HospitalTheme.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Patient details content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPatientHeader(),
                          const SizedBox(height: 32),
                          _buildPatientInformation(),
                          const SizedBox(height: 32),
                          _buildAdmissionRecords(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPatientHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: HospitalTheme.primary.withOpacity(0.2),
          child: Text(
            selectedPatient != null &&
                    selectedPatient!['name'] != null &&
                    selectedPatient!['name'].toString().isNotEmpty
                ? selectedPatient!['name'][0].toUpperCase()
                : '?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedPatient?['name'] ?? 'Unknown',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Patient ID: ${selectedPatient?['patientId'] ?? 'N/A'}',
                style: TextStyle(
                  fontSize: 14,
                  color: HospitalTheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPatientInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Patient Information'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HospitalTheme.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.person,
                      label: 'Age',
                      value: '${selectedPatient?['age'] ?? 'N/A'} years',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      icon: selectedPatient?['gender']
                                  ?.toString()
                                  .toLowerCase() ==
                              'male'
                          ? Icons.male
                          : selectedPatient?['gender']
                                      ?.toString()
                                      .toLowerCase() ==
                                  'female'
                              ? Icons.female
                              : Icons.people,
                      label: 'Gender',
                      value: selectedPatient?['gender'] ?? 'N/A',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.phone,
                      label: 'Contact',
                      value: selectedPatient?['contact'] ?? 'N/A',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.location_on,
                      label: 'Address',
                      value: selectedPatient?['address'] ?? 'N/A',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: HospitalTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: HospitalTheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: HospitalTheme.textMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: HospitalTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdmissionRecords() {
    final admissionRecords =
        selectedPatient?['admissionRecords'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Admission Records'),
        const SizedBox(height: 16),
        if (admissionRecords.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: HospitalTheme.border),
            ),
            child: Center(
              child: Text(
                'No admission records available',
                style: TextStyle(
                  color: HospitalTheme.textMedium,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: admissionRecords.length,
            itemBuilder: (context, index) {
              final admission =
                  admissionRecords[index] as Map<String, dynamic>? ?? {};
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: HospitalTheme.border),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    colorScheme: ColorScheme.light(
                      primary: HospitalTheme.primary,
                    ),
                  ),
                  child: ExpansionTile(
                    title: Text(
                      'Admission on ${admission['admissionDate'] ?? 'Unknown Date'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                    subtitle: Text(
                      'Reason: ${admission['reasonForAdmission'] ?? 'N/A'}',
                      style: TextStyle(
                        color: HospitalTheme.textMedium,
                        fontSize: 12,
                      ),
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: HospitalTheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.medical_services_outlined,
                        color: HospitalTheme.primary,
                      ),
                    ),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    childrenPadding: const EdgeInsets.all(16),
                    children: [
                      _buildAdmissionDetails(admission),
                      const SizedBox(height: 16),
                      _buildFollowUps(admission),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildAdmissionDetails(Map<String, dynamic> admission) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admission Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: HospitalTheme.border),
          ),
          child: Column(
            children: [
              _buildDetailRow('Admission Date',
                  admission['admissionDate']?.toString() ?? 'N/A'),
              const Divider(height: 24),
              _buildDetailRow('Reason',
                  admission['reasonForAdmission']?.toString() ?? 'N/A'),
              const Divider(height: 24),
              _buildDetailRow(
                  'Symptoms', admission['symptoms']?.toString() ?? 'N/A'),
              const Divider(height: 24),
              _buildDetailRow('Initial Diagnosis',
                  admission['initialDiagnosis']?.toString() ?? 'N/A'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFollowUps(Map<String, dynamic> admission) {
    final followUps = admission['followUps'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Follow-ups',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        if (followUps.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: HospitalTheme.border),
            ),
            child: Center(
              child: Text(
                'No follow-ups recorded',
                style: TextStyle(
                  color: HospitalTheme.textMedium,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: followUps.length,
            itemBuilder: (context, index) {
              final followUp = followUps[index] as Map<String, dynamic>? ?? {};
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: HospitalTheme.border),
                ),
                child: ExpansionTile(
                  title: Text(
                    'Date: ${followUp['date'] ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: HospitalTheme.accent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.event_note,
                      color: HospitalTheme.accent,
                      size: 16,
                    ),
                  ),
                  childrenPadding: const EdgeInsets.all(16),
                  children: [
                    _buildDetailRow(
                        'Notes', followUp['notes']?.toString() ?? 'N/A'),
                    const Divider(height: 24),
                    _buildDetailRow(
                        'Temperature',
                        followUp['temperature'] != null
                            ? '${followUp['temperature']}°C'
                            : 'N/A'),
                    const Divider(height: 24),
                    _buildDetailRow('Observations',
                        followUp['observations']?.toString() ?? 'N/A'),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: HospitalTheme.primary, width: 4),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: HospitalTheme.primary,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: HospitalTheme.textDark,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              color: HospitalTheme.textMedium,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
