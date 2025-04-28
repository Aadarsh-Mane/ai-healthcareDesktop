import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/Url.dart';

class AdmissionLabReportsScreen extends StatefulWidget {
  final String admissionId;
  final String patientName;

  const AdmissionLabReportsScreen({
    Key? key,
    required this.admissionId,
    this.patientName = '',
  }) : super(key: key);

  @override
  _AdmissionLabReportsScreenState createState() =>
      _AdmissionLabReportsScreenState();
}

class _AdmissionLabReportsScreenState extends State<AdmissionLabReportsScreen> {
  bool _isLoading = false;
  String _errorMessage = '';
  List<LabReport> _labReports = [];
  List<LabReport> _filteredReports = [];
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _patientId = '';
  String _patientName = '';

  @override
  void initState() {
    super.initState();
    _fetchLabReports();
  }

  Future<void> _fetchLabReports() async {
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
        Uri.parse(
            '${KVM_URL}/doctors/getLabReportsByAdmissionId/${widget.admissionId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          List<LabReport> reports = [];
          for (var labReport in data['data']) {
            reports.add(LabReport.fromJson(labReport));

            // Extract patient info from the first report
            if (reports.length == 1) {
              _patientId = labReport['patientId']['patientId'] ?? '';
              if (widget.patientName.isEmpty) {
                _patientName = labReport['patientId']['name'] ?? '';
              } else {
                _patientName = widget.patientName;
              }
            }
          }

          setState(() {
            _labReports = reports;
            _filteredReports = reports;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Failed to load lab reports: ${data['message'] ?? "Unknown error"}';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load lab reports: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  void _filterReports() {
    if (_searchQuery.isEmpty && _selectedFilter == 'All') {
      setState(() {
        _filteredReports = _labReports;
      });
      return;
    }

    setState(() {
      _filteredReports = _labReports.where((report) {
        bool matchesSearch = _searchQuery.isEmpty ||
            report.testName.toLowerCase().contains(_searchQuery.toLowerCase());

        bool matchesFilter = _selectedFilter == 'All' ||
            (_selectedFilter == 'With Results' && report.hasResults) ||
            (_selectedFilter == 'Pending Results' && !report.hasResults);

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
              color: HospitalTheme.laboratory.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.biotech,
              color: HospitalTheme.laboratory,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Laboratory Reports for $_patientName',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Patient ID: $_patientId | Admission ID: ${widget.admissionId.substring(0, 10)}...',
                  style: TextStyle(
                    fontSize: 14,
                    color: HospitalTheme.textMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 280,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: HospitalTheme.border),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search lab tests...',
                prefixIcon:
                    const Icon(Icons.search, color: HospitalTheme.textMedium),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _filterReports();
              },
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _fetchLabReports,
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
          _buildFilterChip('With Results'),
          const SizedBox(width: 8),
          _buildFilterChip('Pending Results'),
          const Spacer(),
          Text(
            'Total: ${_filteredReports.length} lab tests',
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
        _filterReports();
      },
      selectedColor: HospitalTheme.laboratory.withOpacity(0.1),
      checkmarkColor: HospitalTheme.laboratory,
      labelStyle: TextStyle(
        color: isSelected ? HospitalTheme.laboratory : HospitalTheme.textMedium,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? HospitalTheme.laboratory : HospitalTheme.border,
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
            CircularProgressIndicator(color: HospitalTheme.laboratory),
            const SizedBox(height: 16),
            Text(
              'Loading lab reports...',
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
              onPressed: _fetchLabReports,
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

    if (_filteredReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.science_outlined,
                color: HospitalTheme.textLight, size: 64),
            const SizedBox(height: 16),
            Text(
              'No lab reports found',
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
                  : 'Lab reports will appear here when available',
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
                  _filterReports();
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
      padding: const EdgeInsets.all(24.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.6,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
        ),
        itemCount: _filteredReports.length,
        itemBuilder: (context, index) {
          final report = _filteredReports[index];
          return _buildReportCard(report);
        },
      ),
    );
  }

  Widget _buildReportCard(LabReport report) {
    // Parse test date from string "test-name - date"
    final testNameParts = report.testName.split(' - ');
    final testName = testNameParts[0];
    String orderDate = testNameParts.length > 1 ? testNameParts[1] : '';

    // Format upload date if available
    String uploadDate = '';
    if (report.hasResults && report.results.isNotEmpty) {
      try {
        final parsedDate = DateTime.parse(report.results[0].uploadedAt);
        uploadDate = DateFormat('MMM dd, yyyy hh:mm a').format(parsedDate);
      } catch (e) {
        uploadDate = report.results[0].uploadedAt;
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: report.hasResults
              ? HospitalTheme.success.withOpacity(0.3)
              : HospitalTheme.border,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: report.hasResults && report.results.isNotEmpty
            ? () => Methods().openPdf(report.results[0].reportUrl)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: report.hasResults
                          ? HospitalTheme.success.withOpacity(0.1)
                          : HospitalTheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      report.hasResults
                          ? Icons.assignment_turned_in
                          : Icons.pending_actions,
                      color: report.hasResults
                          ? HospitalTheme.success
                          : HospitalTheme.warning,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          testName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: HospitalTheme.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Ordered: $orderDate',
                          style: TextStyle(
                            fontSize: 12,
                            color: HospitalTheme.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  HospitalTheme.buildStatusBadge(
                    report.hasResults ? 'Completed' : 'Pending',
                    color: report.hasResults
                        ? HospitalTheme.success
                        : HospitalTheme.warning,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Expanded(
                child: report.hasResults && report.results.isNotEmpty
                    ? _buildResultDetails(report.results[0], uploadDate)
                    : _buildPendingDetails(),
              ),
              if (report.hasResults && report.results.isNotEmpty)
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Methods().openPdf(report.results[0].reportUrl),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HospitalTheme.laboratory,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultDetails(ReportResult result, String uploadDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.assessment, size: 16, color: HospitalTheme.laboratory),
            const SizedBox(width: 8),
            Text(
              'Lab Test: ${result.labTestName}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: HospitalTheme.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (result.labType.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.category, size: 16, color: HospitalTheme.medical),
              const SizedBox(width: 8),
              Text(
                'Type: ${result.labType}',
                style: TextStyle(
                  color: HospitalTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: HospitalTheme.info),
            const SizedBox(width: 8),
            Text(
              'Uploaded: $uploadDate',
              style: TextStyle(
                color: HospitalTheme.textMedium,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          'Click to view the full report',
          style: TextStyle(
            color: HospitalTheme.textLight,
            fontStyle: FontStyle.italic,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPendingDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This lab test has been ordered but results have not been uploaded yet.',
          style: TextStyle(
            color: HospitalTheme.textMedium,
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: HospitalTheme.warning),
            const SizedBox(width: 8),
            Text(
              'Results pending from laboratory',
              style: TextStyle(
                color: HospitalTheme.warning,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class LabReport {
  final String id;
  final String admissionId;
  final String testName;
  final List<ReportResult> results;
  final bool hasResults;

  LabReport({
    required this.id,
    required this.admissionId,
    required this.testName,
    required this.results,
    required this.hasResults,
  });

  factory LabReport.fromJson(Map<String, dynamic> json) {
    List<ReportResult> results = [];
    if (json['reports'] != null) {
      results = List<ReportResult>.from(
        json['reports'].map((reportJson) => ReportResult.fromJson(reportJson)),
      );
    }

    return LabReport(
      id: json['_id'] ?? '',
      admissionId: json['admissionId'] ?? '',
      testName: json['labTestNameGivenByDoctor'] ?? '',
      results: results,
      hasResults: results.isNotEmpty,
    );
  }
}

class ReportResult {
  final String labTestName;
  final String reportUrl;
  final String labType;
  final String uploadedAt;

  ReportResult({
    required this.labTestName,
    required this.reportUrl,
    required this.labType,
    required this.uploadedAt,
  });

  factory ReportResult.fromJson(Map<String, dynamic> json) {
    return ReportResult(
      labTestName: json['labTestName'] ?? '',
      reportUrl: json['reportUrl'] ?? '',
      labType: json['labType'] ?? '',
      uploadedAt: json['uploadedAt'] ?? '',
    );
  }
}
