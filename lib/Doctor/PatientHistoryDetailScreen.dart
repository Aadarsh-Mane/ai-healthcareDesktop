import 'dart:convert';
import 'dart:io';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class PatientHistoryDetailScreen extends StatefulWidget {
  final String patientId;

  const PatientHistoryDetailScreen({
    Key? key,
    required this.patientId,
  }) : super(key: key);

  @override
  _PatientHistoryDetailScreenState createState() =>
      _PatientHistoryDetailScreenState();
}

class _PatientHistoryDetailScreenState extends State<PatientHistoryDetailScreen>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  Map<String, dynamic> patientHistory = {};
  String errorMessage = '';
  late TabController _tabController;
  int _selectedTabIndex = 0;

  // For method calls
  final Methods _methods = Methods();

  // Hospital theme colors
  static const Color primaryDark = Color(0xFF00477A); // Deep blue
  static const Color primary = Color(0xFF005F9E); // Main blue
  static const Color primaryLight = Color(0xFF0288D1); // Light blue
  static const Color accent = Color(0xFF00B8D4); // Accent teal
  static const Color background =
      Color(0xFFF8FBFD); // Very light blue-tinted gray
  static const Color cardBackground = Colors.white;
  static const Color textDark = Color(0xFF2D3748); // Near black
  static const Color textMedium = Color(0xFF5A6B7F); // Medium blue-gray
  static const Color border = Color(0xFFDFEAF4); // Light blue-tinted border
  static const Color success = Color(0xFF43A047); // Success green
  static const Color warning = Color(0xFFFFA000); // Warning amber
  static const Color error = Color(0xFFE53935); // Error red
  static const Color info = Color(0xFF039BE5); // Info light blue
  static const Color medical = Color(0xFF2196F3); // Medical blue
  static const Color pharmacy = Color(0xFF26A69A); // Pharmacy teal
  static const Color laboratory = Color(0xFF7E57C2); // Laboratory purple
  static const Color emergency = Color(0xFFEF5350); // Emergency red

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    fetchPatientHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchPatientHistory() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final url = Uri.parse(
          '${KVM_URL}/doctors/getPatientHistory1/${widget.patientId}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          patientHistory = data['history'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Failed to load patient history. Status: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Patient History Details',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: IconThemeData(color: primary),
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primary),
                  SizedBox(height: 16),
                  Text(
                    'Loading patient history...',
                    style: TextStyle(
                      color: textMedium,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: error,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        errorMessage,
                        style: TextStyle(
                          color: textMedium,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: fetchPatientHistory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                        ),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : patientHistoryLayout(),
    );
  }

  Widget patientHistoryLayout() {
    return Row(
      children: [
        // Left Sidebar with Patient Info
        Container(
          width: 300,
          color: Color(0xFF1E2843), // Dark navy background
          child: Column(
            children: [
              // Patient info header
              Container(
                padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
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
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
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
                        backgroundColor: Colors.white.withOpacity(0.1),
                        child: Text(
                          patientHistory['name']
                                  ?.substring(0, 1)
                                  .toUpperCase() ??
                              'P',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      patientHistory['name'] ?? 'Patient Name',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'ID: ${patientHistory['patientId'] ?? 'Unknown ID'}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Patient details
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSidebarSection(
                        title: 'Demographics',
                        items: [
                          _buildInfoItem(
                              'Age',
                              '${patientHistory['age'] ?? 'N/A'} years',
                              Icons.calendar_today),
                          _buildInfoItem('Gender',
                              patientHistory['gender'] ?? 'N/A', Icons.person),
                          _buildInfoItem('Contact',
                              patientHistory['contact'] ?? 'N/A', Icons.phone),
                          _buildInfoItem('Address',
                              patientHistory['address'] ?? 'N/A', Icons.home),
                        ],
                      ),

                      SizedBox(height: 24),

                      _buildSidebarSection(
                        title: 'Admission Summary',
                        items: [
                          _buildInfoItem(
                            'Total Admissions',
                            '${(patientHistory['history'] as List?)?.length ?? 0}',
                            Icons.local_hospital,
                          ),
                          if ((patientHistory['history'] as List?)
                                  ?.isNotEmpty ??
                              false)
                            _buildInfoItem(
                              'Last Admission',
                              _formatDate(patientHistory['history'][0]
                                  ['admissionDate']),
                              Icons.access_time,
                            ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Navigation Buttons
                      _buildActionButton(
                        icon: Icons.picture_as_pdf,
                        label: 'Export PDF',
                        onTap: () {
                          // PDF export feature would be implemented here
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('PDF export feature coming soon')),
                          );
                        },
                      ),

                      SizedBox(height: 16),

                      _buildActionButton(
                        icon: Icons.print,
                        label: 'Print Record',
                        onTap: () {
                          // Print implementation would go here
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Print feature coming soon')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Main Content Area
        Expanded(
          child: Container(
            color: background,
            child: Column(
              children: [
                // Tab Bar
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabs: [
                      _buildTab(Icons.history, 'Admission History', 0),
                      _buildTab(Icons.medication, 'Prescriptions', 1),
                      _buildTab(Icons.healing, 'Symptoms & Diagnosis', 2),
                      _buildTab(Icons.monitor_heart, 'Vitals', 3),
                      _buildTab(Icons.science, 'Lab Reports', 4),
                      _buildTab(Icons.note_alt, 'Doctor Notes', 5),
                      _buildTab(Icons.follow_the_signs, 'Follow-ups', 6),
                    ],
                    indicatorColor: primary,
                    labelColor: primary,
                    unselectedLabelColor: textMedium,
                  ),
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAdmissionHistoryTab(),
                      _buildPrescriptionsTab(),
                      _buildSymptomsAndDiagnosisTab(),
                      _buildVitalsTab(),
                      _buildLabReportsTab(),
                      _buildDoctorNotesTab(),
                      _buildFollowUpsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(IconData icon, String label, int index) {
    final isSelected = _selectedTabIndex == index;

    return Tab(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isSelected ? 22 : 20),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: isSelected ? 14 : 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSection(
      {required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white70,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Colors.white,
              ),
              SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TAB CONTENT BUILDERS

  Widget _buildAdmissionHistoryTab() {
    final historyList = patientHistory['history'] as List? ?? [];

    if (historyList.isEmpty) {
      return _buildEmptyState('No admission records found', Icons.history);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admission History',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final admission = historyList[index];
              return _buildAdmissionCard(admission, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdmissionCard(Map<String, dynamic> admission, int index) {
    final admissionDate = _formatDate(admission['admissionDate']);
    final dischargeDate = admission['dischargeDate'] != null
        ? _formatDate(admission['dischargeDate'])
        : 'Not discharged';

    final status = admission['status'] ?? 'Unknown';
    Color statusColor;

    switch (status.toLowerCase()) {
      case 'discharged':
        statusColor = success;
        break;
      case 'pending':
        statusColor = warning;
        break;
      case 'critical':
        statusColor = emergency;
        break;
      default:
        statusColor = info;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, primaryLight],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.local_hospital,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  'Admission #${index + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAdmissionInfoRow(
                    'Admission ID', admission['admissionId'] ?? 'N/A'),
                _buildAdmissionInfoRow('Admission Date', admissionDate),
                _buildAdmissionInfoRow('Discharge Date', dischargeDate),
                _buildAdmissionInfoRow('Reason for Admission',
                    admission['reasonForAdmission'] ?? 'N/A'),
                _buildAdmissionInfoRow('Initial Diagnosis',
                    admission['initialDiagnosis'] ?? 'N/A'),
                _buildAdmissionInfoRow(
                    'Symptoms', admission['symptoms'] ?? 'N/A'),
                _buildAdmissionInfoRow(
                    'Weight', '${admission['weight'] ?? 'N/A'} kg'),
                _buildAdmissionInfoRow(
                    'Doctor', admission['doctor']?['name'] ?? 'N/A'),
                _buildAdmissionInfoRow('Amount to be Paid',
                    '₹ ${admission['amountToBePayed'] ?? 0}'),

                // Additional details for discharged patients
                if (admission['dischargeDate'] != null) ...[
                  SizedBox(height: 16),
                  Text(
                    'Discharge Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textDark,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildAdmissionInfoRow('Condition at Discharge',
                      admission['conditionAtDischarge'] ?? 'N/A'),
                  _buildAdmissionInfoRow(
                      'Discharged by Reception',
                      admission['dischargedByReception'] == true
                          ? 'Yes'
                          : 'No'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdmissionInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label + ':',
              style: TextStyle(
                color: textMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: primary,
      ),
    );
  }

  Widget _buildPrescriptionsTab() {
    List<dynamic> allPrescriptions = [];

    // Collect all prescriptions from all admissions
    final historyList = patientHistory['history'] as List? ?? [];
    for (var admission in historyList) {
      final prescriptions = admission['doctorPrescriptions'] as List? ?? [];
      for (var prescription in prescriptions) {
        prescription['admissionId'] = admission['admissionId'];
        prescription['admissionDate'] = admission['admissionDate'];
        allPrescriptions.add(prescription);
      }
    }

    if (allPrescriptions.isEmpty) {
      return _buildEmptyState('No prescriptions found', Icons.medication);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prescriptions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          SizedBox(height: 20),

          // Prescriptions table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Table header
                Container(
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: _buildTableHeader('Medicine')),
                      Expanded(child: _buildTableHeader('Morning')),
                      Expanded(child: _buildTableHeader('Afternoon')),
                      Expanded(child: _buildTableHeader('Night')),
                      Expanded(flex: 2, child: _buildTableHeader('Comments')),
                      Expanded(flex: 2, child: _buildTableHeader('Date')),
                    ],
                  ),
                ),

                // Table content
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: allPrescriptions.length,
                  itemBuilder: (context, index) {
                    final prescription = allPrescriptions[index];
                    final medicine = prescription['medicine'] ?? {};

                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade200,
                          ),
                        ),
                      ),
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              medicine['name'] ?? 'N/A',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              medicine['morning'] ?? '0',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              medicine['afternoon'] ?? '0',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              medicine['night'] ?? '0',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              medicine['comment'] ?? '-',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              _formatDate(medicine['date']),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to extract date from description
  DateTime? _extractDateFromDescription(String description) {
    final regex = RegExp(r'Date: (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})');
    final match = regex.firstMatch(description);

    if (match != null && match.groupCount >= 1) {
      final dateStr = match.group(1);
      try {
        return DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateStr!);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Helper method to format date
  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';

    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else {
        date = DateTime.parse(dateValue.toString());
      }

      return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
    } catch (e) {
      return dateValue.toString();
    }
  }

  Widget _buildSymptomsAndDiagnosisTab() {
    List<Map<String, dynamic>> allEntries = [];

    // Collect all symptoms and diagnoses from all admissions
    final historyList = patientHistory['history'] as List? ?? [];
    for (var admission in historyList) {
      final admissionId = admission['admissionId'];
      final admissionDate = admission['admissionDate'];

      // Add symptoms
      final symptoms = admission['symptomsByDoctor'] as List? ?? [];
      for (var symptom in symptoms) {
        allEntries.add({
          'type': 'Symptom',
          'description': symptom,
          'admissionId': admissionId,
          'admissionDate': admissionDate,
        });
      }

      // Add diagnoses
      final diagnoses = admission['diagnosisByDoctor'] as List? ?? [];
      for (var diagnosis in diagnoses) {
        allEntries.add({
          'type': 'Diagnosis',
          'description': diagnosis,
          'admissionId': admissionId,
          'admissionDate': admissionDate,
        });
      }
    }

    // Sort by most recent first (based on date in the description)
    allEntries.sort((a, b) {
      final dateA = _extractDateFromDescription(a['description']);
      final dateB = _extractDateFromDescription(b['description']);

      if (dateA != null && dateB != null) {
        return dateB.compareTo(dateA);
      }
      return 0;
    });

    if (allEntries.isEmpty) {
      return _buildEmptyState('No symptoms or diagnoses found', Icons.healing);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Symptoms & Diagnosis',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: allEntries.length,
            itemBuilder: (context, index) {
              final entry = allEntries[index];
              return _buildSymptomsOrDiagnosisCard(entry);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsOrDiagnosisCard(Map<String, dynamic> entry) {
    final type = entry['type'];
    final description = entry['description'];

    // Extract date from the description (format: "text Date: yyyy-MM-dd HH:mm:ss")
    final dateStr = _extractDateFromDescription(description);

    // For UI purposes - extract just the main content without the date part
    String mainContent = description;
    if (description.contains('Date:')) {
      mainContent =
          description.substring(0, description.indexOf('Date:')).trim();
    }

    IconData icon;
    Color color;

    if (type == 'Symptom') {
      icon = Icons.sick;
      color = warning;
    } else {
      icon = Icons.medical_information;
      color = medical;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Spacer(),
                      if (dateStr != null)
                        Text(
                          dateStr != null
                              ? DateFormat('MMM dd, yyyy - hh:mm a')
                                  .format(dateStr)
                              : 'N/A',
                          style: TextStyle(
                            color: textMedium,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    mainContent,
                    style: TextStyle(
                      fontSize: 15,
                      color: textDark,
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

  Widget _buildVitalsTab() {
    List<dynamic> allVitals = [];

    // Collect all vitals from all admissions
    final historyList = patientHistory['history'] as List? ?? [];
    for (var admission in historyList) {
      final vitals = admission['vitals'] as List? ?? [];
      for (var vital in vitals) {
        vital['admissionId'] = admission['admissionId'];
        vital['admissionDate'] = admission['admissionDate'];
        allVitals.add(vital);
      }
    }

    // Sort by most recent first
    allVitals.sort((a, b) {
      final dateA = a['recordedAt'] ?? '';
      final dateB = b['recordedAt'] ?? '';
      return dateB.toString().compareTo(dateA.toString());
    });

    if (allVitals.isEmpty) {
      return _buildEmptyState('No vitals records found', Icons.monitor_heart);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vitals Records',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: allVitals.length,
            itemBuilder: (context, index) {
              final vital = allVitals[index];
              return _buildVitalCard(vital, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVitalCard(Map<String, dynamic> vital, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: medical.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.monitor_heart,
                  color: medical,
                ),
                SizedBox(width: 8),
                Text(
                  'Vital Record #${index + 1}',
                  style: TextStyle(
                    color: medical,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Spacer(),
                Text(
                  _formatDate(vital['recordedAt']),
                  style: TextStyle(
                    color: textMedium,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVitalInfoRow(
                    'Temperature', vital['temperature'] ?? 'N/A'),
                _buildVitalInfoRow('Pulse', vital['pulse'] ?? 'N/A'),
                _buildVitalInfoRow(
                    'Blood Pressure', vital['bloodPressure'] ?? 'N/A'),
                _buildVitalInfoRow(
                    'Blood Sugar Level', vital['bloodSugarLevel'] ?? 'N/A'),
                _buildVitalInfoRow('Other', vital['other'] ?? 'N/A'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label + ':',
              style: TextStyle(
                color: textMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabReportsTab() {
    List<Map<String, dynamic>> allLabReports = [];

    // Collect all lab reports from all admissions
    final historyList = patientHistory['history'] as List? ?? [];
    for (var admission in historyList) {
      final labReportGroups = admission['labReports'] as List? ?? [];
      for (var group in labReportGroups) {
        final reports = group['reports'] as List? ?? [];
        final testName = group['labTestNameGivenByDoctor'] ?? 'Unknown Test';

        for (var report in reports) {
          report['admissionId'] = admission['admissionId'];
          report['testName'] = testName;
          allLabReports.add(report);
        }
      }
    }

    if (allLabReports.isEmpty) {
      return _buildEmptyState('No lab reports found', Icons.science);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lab Reports',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: allLabReports.length,
            itemBuilder: (context, index) {
              final report = allLabReports[index];
              return _buildLabReportCard(report);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLabReportCard(Map<String, dynamic> report) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Open the lab report PDF when tapped
          if (report['reportUrl'] != null) {
            _methods.openPdf(report['reportUrl']);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Report URL not available')),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: laboratory.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description,
                  color: laboratory,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report['labTestName'] ?? 'Unknown Lab Test',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textDark,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Test Type: ${report['labType'] ?? 'N/A'}',
                      style: TextStyle(
                        color: textMedium,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Uploaded: ${_formatDate(report['uploadedAt'])}',
                      style: TextStyle(
                        color: textMedium,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new,
                color: primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorNotesTab() {
    List<dynamic> allNotes = [];

    // Collect all doctor notes from all admissions
    final historyList = patientHistory['history'] as List? ?? [];
    for (var admission in historyList) {
      final notes = admission['doctorNotes'] as List? ?? [];
      for (var note in notes) {
        note['admissionId'] = admission['admissionId'];
        allNotes.add(note);
      }
    }

    // Sort by most recent first
    allNotes.sort((a, b) {
      final dateA = a['date'] ?? '';
      final dateB = b['date'] ?? '';
      return dateB.toString().compareTo(dateA.toString());
    });

    if (allNotes.isEmpty) {
      return _buildEmptyState('No doctor notes found', Icons.note_alt);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Doctor Notes',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: allNotes.length,
            itemBuilder: (context, index) {
              final note = allNotes[index];
              return _buildNoteCard(note);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.note_alt,
                    color: primary,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. ${note['doctorName'] ?? 'Unknown'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textDark,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${note['date'] ?? 'Unknown date'} ${note['time'] ?? ''}',
                        style: TextStyle(
                          color: textMedium,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Text(
                note['text'] ?? 'No content',
                style: TextStyle(
                  fontSize: 14,
                  color: textDark,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpsTab() {
    List<dynamic> allFollowUps = [];

    // Collect all follow-ups and 4hr follow-ups from all admissions
    final historyList = patientHistory['history'] as List? ?? [];
    for (var admission in historyList) {
      // Regular follow-ups
      final followUps = admission['followUps'] as List? ?? [];
      for (var followUp in followUps) {
        followUp['admissionId'] = admission['admissionId'];
        followUp['type'] = 'Regular';
        allFollowUps.add(followUp);
      }

      // 4-hour follow-ups
      final fourHrFollowUps = admission['fourHrFollowUpSchema'] as List? ?? [];
      for (var followUp in fourHrFollowUps) {
        followUp['admissionId'] = admission['admissionId'];
        followUp['type'] = '4-Hour';
        allFollowUps.add(followUp);
      }
    }

    // Sort by most recent first
    allFollowUps.sort((a, b) {
      final dateA = a['date'] ?? '';
      final dateB = b['date'] ?? '';
      return dateB.toString().compareTo(dateA.toString());
    });

    if (allFollowUps.isEmpty) {
      return _buildEmptyState(
          'No follow-up records found', Icons.follow_the_signs);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Follow-Up Records',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: allFollowUps.length,
            itemBuilder: (context, index) {
              final followUp = allFollowUps[index];
              return _buildFollowUpCard(followUp, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpCard(Map<String, dynamic> followUp, int index) {
    final isRegular = followUp['type'] == 'Regular';
    final color = isRegular ? primary : accent;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.follow_the_signs,
                  color: color,
                ),
                SizedBox(width: 8),
                Text(
                  '${followUp['type']} Follow-Up #${index + 1}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Spacer(),
                Text(
                  followUp['date'] ?? 'Unknown date',
                  style: TextStyle(
                    color: textMedium,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFollowUpInfoRow('Notes', followUp['notes'] ?? 'N/A'),
                if (followUp['observations'] != null &&
                    followUp['observations'].toString().isNotEmpty)
                  _buildFollowUpInfoRow(
                      'Observations', followUp['observations']),

                SizedBox(height: 16),
                Text(
                  'Vital Signs',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textDark,
                  ),
                ),
                SizedBox(height: 8),

                // If 4-hour follow-up, use the fourhr* fields, otherwise use regular fields
                _buildFollowUpInfoRow(
                    'Temperature',
                    isRegular
                        ? followUp['temperature'] ?? 'N/A'
                        : followUp['fourhrTemperature'] ?? 'N/A'),
                _buildFollowUpInfoRow(
                    'Pulse',
                    isRegular
                        ? followUp['pulse'] ?? 'N/A'
                        : followUp['fourhrpulse'] ?? 'N/A'),
                _buildFollowUpInfoRow(
                    'Respiration Rate', followUp['respirationRate'] ?? 'N/A'),
                _buildFollowUpInfoRow(
                    'Blood Pressure',
                    isRegular
                        ? followUp['bloodPressure'] ?? 'N/A'
                        : followUp['fourhrbloodPressure'] ?? 'N/A'),
                _buildFollowUpInfoRow(
                    'Oxygen Saturation',
                    isRegular
                        ? followUp['oxygenSaturation'] ?? 'N/A'
                        : followUp['fourhroxygenSaturation'] ?? 'N/A'),
                _buildFollowUpInfoRow(
                    'Blood Sugar Level',
                    isRegular
                        ? followUp['bloodSugarLevel'] ?? 'N/A'
                        : followUp['fourhrbloodSugarLevel'] ?? 'N/A'),

                if (followUp['ivFluid'] != null ||
                    followUp['fourhrivFluid'] != null) ...[
                  SizedBox(height: 16),
                  Text(
                    'Fluids & Output',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textDark,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildFollowUpInfoRow(
                      'IV Fluid',
                      isRegular
                          ? followUp['ivFluid'] ?? 'N/A'
                          : followUp['fourhrivFluid'] ?? 'N/A'),
                  if (followUp['nasogastric'] != null)
                    _buildFollowUpInfoRow(
                        'Nasogastric', followUp['nasogastric'] ?? 'N/A'),
                  if (followUp['rtFeedOral'] != null)
                    _buildFollowUpInfoRow(
                        'RT Feed/Oral', followUp['rtFeedOral'] ?? 'N/A'),
                  if (followUp['totalIntake'] != null)
                    _buildFollowUpInfoRow(
                        'Total Intake', followUp['totalIntake'] ?? 'N/A'),
                  if (followUp['cvp'] != null)
                    _buildFollowUpInfoRow('CVP', followUp['cvp'] ?? 'N/A'),
                  _buildFollowUpInfoRow(
                      'Urine',
                      isRegular
                          ? followUp['urine'] ?? 'N/A'
                          : followUp['fourhrurine'] ?? 'N/A'),
                  if (followUp['stool'] != null)
                    _buildFollowUpInfoRow('Stool', followUp['stool'] ?? 'N/A'),
                  if (followUp['rtAspirate'] != null)
                    _buildFollowUpInfoRow(
                        'RT Aspirate', followUp['rtAspirate'] ?? 'N/A'),
                  if (followUp['otherOutput'] != null)
                    _buildFollowUpInfoRow(
                        'Other Output', followUp['otherOutput'] ?? 'N/A'),
                ],

                // Ventilator information if available
                if (followUp['ventyMode'] != null) ...[
                  SizedBox(height: 16),
                  Text(
                    'Ventilator Settings',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textDark,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildFollowUpInfoRow(
                      'Ventilator Mode', followUp['ventyMode'] ?? 'N/A'),
                  _buildFollowUpInfoRow(
                      'Set Rate', followUp['setRate'] ?? 'N/A'),
                  _buildFollowUpInfoRow('FiO2', followUp['fiO2'] ?? 'N/A'),
                  _buildFollowUpInfoRow('PIP', followUp['pip'] ?? 'N/A'),
                  _buildFollowUpInfoRow(
                      'PEEP/CPAP', followUp['peepCpap'] ?? 'N/A'),
                  _buildFollowUpInfoRow(
                      'I:E Ratio', followUp['ieRatio'] ?? 'N/A'),
                  if (followUp['otherVentilator'] != null)
                    _buildFollowUpInfoRow(
                        'Other', followUp['otherVentilator'] ?? 'N/A'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label + ':',
              style: TextStyle(
                color: textMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for empty states
  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: textMedium,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
