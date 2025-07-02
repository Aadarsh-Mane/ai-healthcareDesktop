import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/Url.dart';

class LaboratoryAssignmentsScreen extends StatefulWidget {
  const LaboratoryAssignmentsScreen({Key? key}) : super(key: key);

  @override
  _LaboratoryAssignmentsScreenState createState() =>
      _LaboratoryAssignmentsScreenState();
}

class _LaboratoryAssignmentsScreenState
    extends State<LaboratoryAssignmentsScreen> {
  bool _isLoading = false;
  String _errorMessage = '';
  List<LabAssignment> _labAssignments = [];
  List<LabAssignment> _filteredAssignments = [];
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchLabAssignments();
  }

  Future<void> _fetchLabAssignments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Authentication token not found. Please log in again.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${KVM_URL}/doctors/getDoctorAssignedPatient'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<LabAssignment> assignments = [];
        for (var labReport in data['labReports']) {
          assignments.add(LabAssignment.fromJson(labReport));
        }

        setState(() {
          _labAssignments = assignments;
          _filteredAssignments = assignments;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No lab assignments found or an error occurred.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  void _filterAssignments() {
    if (_searchQuery.isEmpty && _selectedFilter == 'All') {
      setState(() {
        _filteredAssignments = _labAssignments;
      });
      return;
    }

    setState(() {
      _filteredAssignments = _labAssignments.where((assignment) {
        bool matchesSearch = _searchQuery.isEmpty ||
            assignment.patientName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            assignment.testName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());

        bool matchesFilter = _selectedFilter == 'All' ||
            (_selectedFilter == 'With Reports' && assignment.hasReports) ||
            (_selectedFilter == 'Pending Reports' && !assignment.hasReports);

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterSection(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: HospitalTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.science,
              color: HospitalTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Laboratory Assignments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
              Text(
                'View and manage patient laboratory tests',
                style: TextStyle(
                  fontSize: 14,
                  color: HospitalTheme.textMedium,
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildSearchField(),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _fetchLabAssignments,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      width: 280,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HospitalTheme.border),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by patient name or test...',
          prefixIcon: const Icon(Icons.search, color: HospitalTheme.textMedium),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          isDense: true,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _filterAssignments();
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: HospitalTheme.background,
        border: Border(
          bottom: BorderSide(color: HospitalTheme.border),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Filter: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: HospitalTheme.textDark,
            ),
          ),
          const SizedBox(width: 8),
          _buildFilterChip('All'),
          const SizedBox(width: 8),
          _buildFilterChip('With Reports'),
          const SizedBox(width: 8),
          _buildFilterChip('Pending Reports'),
          const Spacer(),
          Text(
            'Total: ${_filteredAssignments.length} assignments',
            style: TextStyle(
              color: HospitalTheme.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterName) {
    final isSelected = _selectedFilter == filterName;

    return FilterChip(
      selected: isSelected,
      label: Text(filterName),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = filterName;
        });
        _filterAssignments();
      },
      selectedColor: HospitalTheme.primary.withOpacity(0.1),
      checkmarkColor: HospitalTheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? HospitalTheme.primary : HospitalTheme.textMedium,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? HospitalTheme.primary : HospitalTheme.border,
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: HospitalTheme.primary),
            const SizedBox(height: 16),
            Text(
              'Loading lab assignments...',
              style: TextStyle(color: HospitalTheme.textMedium),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: HospitalTheme.error, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(color: HospitalTheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchLabAssignments,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HospitalTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredAssignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.science_outlined,
                color: HospitalTheme.textLight, size: 64),
            const SizedBox(height: 16),
            Text(
              'No lab assignments found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'All'
                  ? 'Try adjusting your filters'
                  : 'Assigned labs will appear here',
              style: TextStyle(color: HospitalTheme.textMedium),
            ),
            const SizedBox(height: 24),
            if (_searchQuery.isNotEmpty || _selectedFilter != 'All')
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedFilter = 'All';
                  });
                  _filterAssignments();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HospitalTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: HospitalTheme.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor:
                  MaterialStateProperty.all(HospitalTheme.surfaceLight),
              dataRowMinHeight: 72,
              dataRowMaxHeight: 100,
              columnSpacing: 32,
              dividerThickness: 1,
              showBottomBorder: true,
              columns: [
                DataColumn(
                  label: Text(
                    'Patient Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Lab Test',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Ordered Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Reports',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Actions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                ),
              ],
              rows: _filteredAssignments.map((assignment) {
                return DataRow(
                  cells: [
                    DataCell(
                      _buildPatientCell(assignment),
                    ),
                    DataCell(
                      _buildTestNameCell(assignment),
                    ),
                    DataCell(
                      _buildOrderDateCell(assignment),
                    ),
                    DataCell(
                      _buildStatusCell(assignment),
                    ),
                    DataCell(
                      _buildReportsCell(assignment),
                    ),
                    DataCell(
                      _buildActionsCell(assignment),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCell(LabAssignment assignment) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: HospitalTheme.primary.withOpacity(0.1),
          child: Text(
            assignment.patientName.isNotEmpty
                ? assignment.patientName[0].toUpperCase()
                : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: HospitalTheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              assignment.patientName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ID: ${assignment.patientId}',
              style: TextStyle(
                fontSize: 12,
                color: HospitalTheme.textMedium,
              ),
            ),
            Text(
              '${assignment.patientAge} yrs, ${assignment.patientGender}',
              style: TextStyle(
                fontSize: 12,
                color: HospitalTheme.textMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTestNameCell(LabAssignment assignment) {
    // Extract the test name part (before the date)
    final testNameParts = assignment.testName.split(' - ');
    final testName = testNameParts[0].trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          testName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (testNameParts.length > 1) const SizedBox(height: 4),
        if (testNameParts.length > 1)
          Text(
            'Ref: ${assignment.assignmentId.substring(0, 10)}...',
            style: TextStyle(
              fontSize: 12,
              color: HospitalTheme.textMedium,
            ),
          ),
      ],
    );
  }

  Widget _buildOrderDateCell(LabAssignment assignment) {
    // Extract the date part (after " - ")
    final testNameParts = assignment.testName.split(' - ');
    String dateStr = '';

    if (testNameParts.length > 1) {
      dateStr = testNameParts[1].trim();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          dateStr.isNotEmpty ? dateStr : 'N/A',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: HospitalTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCell(LabAssignment assignment) {
    final hasReports = assignment.hasReports;

    return HospitalTheme.buildStatusBadge(
      hasReports ? 'Completed' : 'Pending',
      color: hasReports ? HospitalTheme.success : HospitalTheme.warning,
    );
  }

  Widget _buildReportsCell(LabAssignment assignment) {
    if (!assignment.hasReports) {
      return Text(
        'No reports yet',
        style: TextStyle(
          color: HospitalTheme.textMedium,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: assignment.reports.map((report) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.description,
                size: 16,
                color: HospitalTheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                report.labTestName,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: HospitalTheme.textDark,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                report.labType.isNotEmpty ? '(${report.labType})' : '',
                style: TextStyle(
                  fontSize: 12,
                  color: HospitalTheme.textMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionsCell(LabAssignment assignment) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (assignment.hasReports)
          for (var report in assignment.reports)
            Tooltip(
              message: 'View Report',
              child: IconButton(
                icon: Icon(
                  Icons.visibility,
                  color: HospitalTheme.primary,
                ),
                onPressed: () {
                  Methods().openPdf(report.reportUrl);
                },
              ),
            ),
        Tooltip(
          message: 'Patient Details',
          child: IconButton(
            icon: Icon(
              Icons.person,
              color: HospitalTheme.medical,
            ),
            onPressed: () {
              // Navigate to patient details screen
            },
          ),
        ),
      ],
    );
  }
}

class LabAssignment {
  final String assignmentId;
  final String admissionId;
  final String patientId;
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String doctorId;
  final String doctorName;
  final String testName;
  final List<LabReport> reports;
  final bool hasReports;

  LabAssignment({
    required this.assignmentId,
    required this.admissionId,
    required this.patientId,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.doctorId,
    required this.doctorName,
    required this.testName,
    required this.reports,
    required this.hasReports,
  });

  factory LabAssignment.fromJson(Map<String, dynamic> json) {
    List<LabReport> reports = [];
    if (json['reports'] != null) {
      reports = List<LabReport>.from(
        json['reports'].map((reportJson) => LabReport.fromJson(reportJson)),
      );
    }

    return LabAssignment(
      assignmentId: json['_id'] ?? '',
      admissionId: json['admissionId'] ?? '',
      patientId: json['patientId']['_id'] ?? '',
      patientName: json['patientId']['name'] ?? '',
      patientAge: json['patientId']['age'] ?? 0,
      patientGender: json['patientId']['gender'] ?? '',
      doctorId: json['doctorId']['_id'] ?? '',
      doctorName: json['doctorId']['doctorName'] ?? '',
      testName: json['labTestNameGivenByDoctor'] ?? '',
      reports: reports,
      hasReports: reports.isNotEmpty,
    );
  }
}

class LabReport {
  final String labTestName;
  final String reportUrl;
  final String labType;
  final String uploadedAt;

  LabReport({
    required this.labTestName,
    required this.reportUrl,
    required this.labType,
    required this.uploadedAt,
  });

  factory LabReport.fromJson(Map<String, dynamic> json) {
    return LabReport(
      labTestName: json['labTestName'] ?? '',
      reportUrl: json['reportUrl'] ?? '',
      labType: json['labType'] ?? '',
      uploadedAt: json['uploadedAt'] ?? '',
    );
  }
}
