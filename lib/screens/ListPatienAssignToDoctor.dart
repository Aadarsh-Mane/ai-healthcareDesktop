import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:doctordesktop/constants/Url.dart';

class PatientAssignmentScreen extends StatefulWidget {
  @override
  _PatientAssignmentScreenState createState() =>
      _PatientAssignmentScreenState();
}

class _PatientAssignmentScreenState extends State<PatientAssignmentScreen> {
  List<String> doctorNames = [];
  String? selectedDoctor;
  List<Map<String, dynamic>> patients = [];
  Map<String, dynamic>? selectedPatient;
  bool isLoading = false;
  String error = '';

  // Enhanced colors and styles for consistent appearance
  final Color primaryColor = const Color(0xFF005F9E);
  final Color accentColor = const Color(0xFF00B8D4);
  final Color cardBackgroundColor = Colors.white;
  final Color textPrimaryColor = const Color(0xFF2D3748);
  final Color textSecondaryColor = const Color(0xFF5A6B7F);
  final Color borderColor = const Color(0xFFDFEAF4);

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
        setState(() {
          doctorNames = List<String>.from(
              data['doctors'].map((doctor) => doctor['doctorName']));
        });
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
    if (selectedDoctor == null) return;

    setState(() {
      isLoading = true;
      error = '';
      patients = [];
    });

    try {
      final response = await http.get(
        Uri.parse(
            '${KVM_URL}/reception/getPatientAssignedToDoctor/$selectedDoctor'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          patients = List<Map<String, dynamic>>.from(data['patients']);
          selectedPatient = null;
        });
      } else {
        setState(() {
          error = 'Failed to load patients: ${response.statusCode}';
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
                color: textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'View and manage patient assignments to doctors',
              style: TextStyle(
                fontSize: 14,
                color: textSecondaryColor,
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
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedDoctor,
          hint: Text(
            'Select Doctor',
            style: TextStyle(color: textSecondaryColor),
          ),
          icon: Icon(Icons.arrow_drop_down, color: primaryColor),
          isExpanded: true,
          onChanged: (String? newDoctor) {
            setState(() => selectedDoctor = newDoctor);
            _fetchPatients();
          },
          items: doctorNames.map<DropdownMenuItem<String>>((String doctorName) {
            return DropdownMenuItem<String>(
              value: doctorName,
              child: Text(
                doctorName,
                style: TextStyle(color: textPrimaryColor),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading && patients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 16),
            Text(
              'Loading data...',
              style: TextStyle(color: textSecondaryColor),
            ),
          ],
        ),
      );
    }

    if (error.isNotEmpty && patients.isEmpty) {
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
                backgroundColor: primaryColor,
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

    if (selectedDoctor == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Please select a doctor to view assigned patients',
              style: TextStyle(
                fontSize: 18,
                color: textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Patient List Panel
        Expanded(
          flex: 2,
          child: _buildPatientListPanel(),
        ),
        const SizedBox(width: 24),
        // Patient Details Panel
        Expanded(
          flex: 3,
          child: _buildPatientDetailsPanel(),
        ),
      ],
    );
  }

  Widget _buildPatientListPanel() {
    return Container(
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: borderColor),
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
                    color: textPrimaryColor,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${patients.length} Patients',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: borderColor),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LinearProgressIndicator(
                backgroundColor: primaryColor.withOpacity(0.1),
                color: primaryColor,
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
                          color: textSecondaryColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No patients assigned to this doctor',
                          style: TextStyle(
                            color: textSecondaryColor,
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
                        Divider(height: 1, color: borderColor),
                    itemBuilder: (context, index) {
                      final patient = patients[index];
                      final isSelected = selectedPatient == patient;

                      return Material(
                        color: isSelected
                            ? primaryColor.withOpacity(0.1)
                            : cardBackgroundColor,
                        child: InkWell(
                          onTap: () =>
                              setState(() => selectedPatient = patient),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: isSelected
                                    ? primaryColor
                                    : accentColor.withOpacity(0.2),
                                child: Text(
                                  patient['name'][0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : primaryColor,
                                  ),
                                ),
                              ),
                              title: Text(
                                patient['name'] ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimaryColor,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: ${patient['patientId']}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${patient['age']} yrs | ${patient['gender']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: isSelected
                                    ? primaryColor
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
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: borderColor),
        ),
        child: selectedPatient == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 64,
                      color: textSecondaryColor.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select a patient to view details',
                      style: TextStyle(
                        fontSize: 16,
                        color: textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
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
    );
  }

  Widget _buildPatientHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: primaryColor.withOpacity(0.2),
          child: Text(
            selectedPatient?['name'][0].toUpperCase() ?? '?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryColor,
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
                  color: textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Patient ID: ${selectedPatient?['patientId']}',
                style: TextStyle(
                  fontSize: 14,
                  color: primaryColor,
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
            border: Border.all(color: borderColor),
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
                      icon: selectedPatient?['gender']?.toLowerCase() == 'male'
                          ? Icons.male
                          : selectedPatient?['gender']?.toLowerCase() ==
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
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
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
                  color: textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: textPrimaryColor,
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
              border: Border.all(color: borderColor),
            ),
            child: Center(
              child: Text(
                'No admission records available',
                style: TextStyle(
                  color: textSecondaryColor,
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
                  border: Border.all(color: borderColor),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    colorScheme: ColorScheme.light(
                      primary: primaryColor,
                    ),
                  ),
                  child: ExpansionTile(
                    title: Text(
                      'Admission on ${admission['admissionDate'] ?? 'Unknown Date'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textPrimaryColor,
                      ),
                    ),
                    subtitle: Text(
                      'Reason: ${admission['reasonForAdmission'] ?? 'N/A'}',
                      style: TextStyle(
                        color: textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.medical_services_outlined,
                        color: primaryColor,
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
            color: textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
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
            color: textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        if (followUps.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Center(
              child: Text(
                'No follow-ups recorded',
                style: TextStyle(
                  color: textSecondaryColor,
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
                  border: Border.all(color: borderColor),
                ),
                child: ExpansionTile(
                  title: Text(
                    'Date: ${followUp['date'] ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimaryColor,
                    ),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.event_note,
                      color: accentColor,
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
          left: BorderSide(color: primaryColor, width: 4),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primaryColor,
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
              color: textPrimaryColor,
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
              color: textSecondaryColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
