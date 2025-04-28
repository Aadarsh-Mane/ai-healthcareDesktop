import 'dart:convert';
import 'package:doctordesktop/Doctor/Tabs/UploadReportScreen.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/model/getInvestigationModel.dart';

class InvestigationScreen1 extends StatefulWidget {
  const InvestigationScreen1({Key? key}) : super(key: key);

  @override
  _InvestigationScreenState createState() => _InvestigationScreenState();
}

class _InvestigationScreenState extends State<InvestigationScreen1> {
  bool _isLoading = false;
  String _errorMessage = '';
  List<Investigation> _investigations = [];
  Investigation? _selectedInvestigation;
  bool _isPanelOpen = false;

  // For filtering and sorting
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _sortBy = 'Date (Newest)';

  final List<String> _statusOptions = [
    'All',
    'Scheduled',
    'Results Available',
    'Cancelled'
  ];
  final List<String> _sortOptions = [
    'Date (Newest)',
    'Date (Oldest)',
    'Priority'
  ];

  @override
  void initState() {
    super.initState();
    _fetchInvestigations();
  }

  Future<void> _fetchInvestigations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('${KVM_URL}/investigate/getAllInvestigations'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final investigationResponse = InvestigationResponse.fromJson(jsonData);

        setState(() {
          _investigations = investigationResponse.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load investigations: ${response.statusCode}';
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

  void _viewInvestigationDetails(Investigation investigation) {
    setState(() {
      _selectedInvestigation = investigation;
      _isPanelOpen = true;
    });
  }

  void _closePanel() {
    setState(() {
      _isPanelOpen = false;
    });
  }

  void _navigateToUploadReport(String investigationId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UploadReportScreen(investigationId: investigationId),
      ),
    );
  }

  void _openAttachment(String url) {
    Methods().openPdf(url);
  }

  List<Investigation> get _filteredInvestigations {
    return _investigations.where((investigation) {
      // Apply search filter
      final matchesSearch = _searchQuery.isEmpty ||
          investigation.patient.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          investigation.investigationType
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          investigation.reasonForInvestigation
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          investigation.doctorName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      // Apply status filter
      final matchesStatus =
          _statusFilter == 'All' || investigation.status == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList()
      ..sort((a, b) {
        // Apply sorting
        switch (_sortBy) {
          case 'Date (Newest)':
            return b.orderDate.compareTo(a.orderDate);
          case 'Date (Oldest)':
            return a.orderDate.compareTo(b.orderDate);
          case 'Priority':
            final priorityOrder = {
              'Urgent': 0,
              'High': 1,
              'Routine': 2,
              'Low': 3
            };
            return (priorityOrder[a.priority] ?? 4)
                .compareTo(priorityOrder[b.priority] ?? 4);
          default:
            return 0;
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HospitalTheme.buildAppBar(
        title: 'Laboratory Investigations',
        context: context,
        centerTitle: false,
        showBackButton: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchInvestigations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(HospitalTheme.primary),
            ),
            SizedBox(height: 16),
            Text(
              'Loading investigations...',
              style: TextStyle(
                color: HospitalTheme.textMedium,
                fontSize: 16,
              ),
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
            Icon(
              Icons.error_outline,
              color: HospitalTheme.error,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(
                color: HospitalTheme.error,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchInvestigations,
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_investigations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.science_outlined,
              color: HospitalTheme.textLight,
              size: 72,
            ),
            SizedBox(height: 16),
            Text(
              'No investigations found',
              style: TextStyle(
                color: HospitalTheme.textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'There are no investigations to display',
              style: TextStyle(
                color: HospitalTheme.textMedium,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchInvestigations,
              icon: Icon(Icons.refresh),
              label: Text('Refresh'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Row(
        children: [
          // Main content - investigation table
          Expanded(
            flex: _isPanelOpen ? 3 : 5,
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterBar(),
                  SizedBox(height: 16),
                  Expanded(
                    child: _buildInvestigationTable(),
                  ),
                ],
              ),
            ),
          ),

          // Detail panel (conditionally visible)
          if (_isPanelOpen && _selectedInvestigation != null)
            Container(
              width: constraints.maxWidth * 0.4, // Fixed width for detail panel
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(-2, 0),
                  ),
                ],
              ),
              child: _buildDetailPanel(_selectedInvestigation!),
            ),
        ],
      );
    });
  }

  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with responsive layout
          LayoutBuilder(
            builder: (context, constraints) {
              // If we have enough width, show everything in a single row
              if (constraints.maxWidth > 800) {
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Investigations (${_filteredInvestigations.length}/${_investigations.length})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.textDark,
                        ),
                      ),
                    ),
                    // Status legend
                    _buildStatusLegend(),
                  ],
                );
              } else {
                // On smaller screens, stack vertically
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Investigations (${_filteredInvestigations.length}/${_investigations.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                    SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildStatusLegend(),
                    ),
                  ],
                );
              }
            },
          ),
          SizedBox(height: 16),

          // Filter controls with responsive layout
          LayoutBuilder(
            builder: (context, constraints) {
              // For wider screens, show in a single row
              if (constraints.maxWidth > 750) {
                return Row(
                  children: [
                    // Search bar
                    Expanded(
                      flex: 2,
                      child: _buildSearchField(),
                    ),
                    SizedBox(width: 16),

                    // Status filter
                    Expanded(
                      child: _buildStatusDropdown(),
                    ),
                    SizedBox(width: 16),

                    // Sort options
                    Expanded(
                      child: _buildSortDropdown(),
                    ),
                  ],
                );
              } else {
                // For narrower screens, stack the filter controls vertically
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchField(),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildStatusDropdown()),
                        SizedBox(width: 12),
                        Expanded(child: _buildSortDropdown()),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

// Extracted methods to make the main method more readable
  Widget _buildStatusLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLegendItem(
          color: HospitalTheme.success,
          label: 'Results Available',
        ),
        SizedBox(width: 8),
        _buildLegendItem(
          color: HospitalTheme.warning,
          label: 'Scheduled',
        ),
        SizedBox(width: 8),
        _buildLegendItem(
          color: HospitalTheme.error,
          label: 'Cancelled',
        ),
      ],
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search patient, test type, or reason...',
        prefixIcon: Icon(Icons.search, color: HospitalTheme.textMedium),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: HospitalTheme.border),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        isDense: true,
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _statusFilter,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        isDense: true,
      ),
      items: _statusOptions.map((status) {
        return DropdownMenuItem<String>(
          value: status,
          child: Text(status, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _statusFilter = value!;
        });
      },
    );
  }

  Widget _buildSortDropdown() {
    return DropdownButtonFormField<String>(
      value: _sortBy,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Sort By',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        isDense: true,
      ),
      items: _sortOptions.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _sortBy = value!;
        });
      },
    );
  }

  Widget _buildInvestigationTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Scrollbar(
        thumbVisibility: true,
        thickness: 6,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                  HospitalTheme.primaryLight.withOpacity(0.1)),
              dataRowMinHeight: 60,
              dataRowMaxHeight: 60,
              columnSpacing: 16,
              showCheckboxColumn: false,
              columns: [
                DataColumn(
                  label: Text(
                    'Patient',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Type',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Reason',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Priority',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Ordered',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Scheduled',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Actions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: _filteredInvestigations.map((investigation) {
                // Determine status color
                Color statusColor;
                switch (investigation.status) {
                  case 'Results Available':
                    statusColor = HospitalTheme.success;
                    break;
                  case 'Scheduled':
                    statusColor = HospitalTheme.warning;
                    break;
                  case 'Cancelled':
                    statusColor = HospitalTheme.error;
                    break;
                  default:
                    statusColor = HospitalTheme.info;
                }

                // Determine priority color
                Color priorityColor;
                switch (investigation.priority) {
                  case 'Urgent':
                    priorityColor = HospitalTheme.error;
                    break;
                  case 'High':
                    priorityColor = HospitalTheme.warning;
                    break;
                  case 'Routine':
                    priorityColor = HospitalTheme.info;
                    break;
                  default:
                    priorityColor = HospitalTheme.textMedium;
                }

                return DataRow(
                  cells: [
                    DataCell(
                      Container(
                        width: 200, // Fixed width for patient column
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  HospitalTheme.medical.withOpacity(0.1),
                              child: Text(
                                investigation.patient.name.isNotEmpty
                                    ? investigation.patient.name[0]
                                        .toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: HospitalTheme.medical,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    investigation.patient.name,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'ID: ${investigation.patientIdNumber}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: HospitalTheme.textMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        width: 150, // Fixed width
                        child: Row(
                          children: [
                            Icon(
                              _getInvestigationIcon(
                                  investigation.investigationType),
                              color: HospitalTheme.primary,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                investigation.investigationType,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        width: 180, // Fixed width
                        child: Tooltip(
                          message: investigation.reasonForInvestigation,
                          child: Text(
                            investigation.reasonForInvestigation,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          investigation.status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        width: 100, // Fixed width
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          investigation.priority,
                          style: TextStyle(
                            color: priorityColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        width: 100, // Fixed width
                        child: Text(_formatDate(investigation.orderDate)),
                      ),
                    ),
                    DataCell(
                      Container(
                        width: 100, // Fixed width
                        child: Text(_formatDate(investigation.scheduledDate)),
                      ),
                    ),
                    DataCell(
                      Container(
                        width: 150, // Fixed width
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.visibility,
                                  color: HospitalTheme.primary),
                              tooltip: 'View Details',
                              onPressed: () =>
                                  _viewInvestigationDetails(investigation),
                            ),
                            if (investigation.attachments.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.attachment,
                                    color: HospitalTheme.info),
                                tooltip: 'View Attachments',
                                onPressed: () => _openAttachment(
                                    investigation.attachments.first.fileUrl),
                              ),
                            IconButton(
                              icon: Icon(Icons.upload_file,
                                  color: HospitalTheme.success),
                              tooltip: 'Upload Report',
                              onPressed: () =>
                                  _navigateToUploadReport(investigation.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onSelectChanged: (_) =>
                      _viewInvestigationDetails(investigation),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPanel(Investigation investigation) {
    return Column(
      children: [
        // Header with close button
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HospitalTheme.primary,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                _getInvestigationIcon(investigation.investigationType),
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      investigation.investigationType,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Patient: ${investigation.patient.name}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: _closePanel,
                tooltip: 'Close',
              ),
            ],
          ),
        ),

        // Detail content
        Expanded(
          child: Container(
            color: Colors.grey.shade50,
            child: Scrollbar(
              thumbVisibility: true,
              thickness: 6,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status and priority section
                    _buildDetailSection(
                      title: 'Status Information',
                      children: [
                        _buildStatusRow(
                          'Status',
                          investigation.status,
                          _getStatusColor(investigation.status),
                          Icons.info_outline,
                        ),
                        _buildStatusRow(
                          'Priority',
                          investigation.priority,
                          _getPriorityColor(investigation.priority),
                          Icons.priority_high,
                        ),
                        _buildDetailRow(
                          'Ordered Date',
                          _formatDate(investigation.orderDate),
                          Icons.calendar_today,
                        ),
                        _buildDetailRow(
                          'Scheduled Date',
                          _formatDate(investigation.scheduledDate),
                          Icons.event,
                        ),
                        if (investigation.completionDate != null)
                          _buildDetailRow(
                            'Completion Date',
                            _formatDate(investigation.completionDate!),
                            Icons.check_circle,
                          ),
                      ],
                    ),

                    // Investigation details section
                    _buildDetailSection(
                      title: 'Investigation Details',
                      children: [
                        _buildDetailRow(
                          'Reason',
                          investigation.reasonForInvestigation,
                          Icons.medical_information,
                        ),
                        _buildDetailRow(
                          'Ordering Doctor',
                          investigation.doctorName,
                          Icons.person,
                        ),
                        _buildDetailRow(
                          'Parameters',
                          _getParametersText(
                              investigation.investigationDetails),
                          Icons.list_alt,
                        ),
                        if (investigation.clinicalHistory.isNotEmpty)
                          _buildDetailRow(
                            'Clinical History',
                            investigation.clinicalHistory,
                            Icons.history_edu,
                          ),
                        _buildDetailRow(
                          'Admission Record ID',
                          investigation.admissionRecordId,
                          Icons.local_hospital,
                        ),
                      ],
                    ),

                    // Billing information
                    _buildDetailSection(
                      title: 'Billing Information',
                      children: [
                        if (investigation.billing.cost != null)
                          _buildDetailRow(
                            'Cost',
                            '₹${investigation.billing.cost}',
                            Icons.payments,
                          ),
                        _buildDetailRow(
                          'Payment Status',
                          investigation.billing.paymentStatus ??
                              'Not Available',
                          Icons.payment,
                        ),
                        _buildDetailRow(
                          'Insurance Covered',
                          investigation.billing.insuranceCovered == true
                              ? 'Yes'
                              : 'No',
                          Icons.health_and_safety,
                        ),
                      ],
                    ),

                    // Tags section (if available)
                    if (investigation.tags.isNotEmpty)
                      _buildDetailSection(
                        title: 'Tags',
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: investigation.tags.map((tag) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: HospitalTheme.surfaceLight,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: HospitalTheme.border),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: HospitalTheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),

                    // Performed by section (if available)
                    if (investigation.performedBy != null)
                      _buildDetailSection(
                        title: 'Performed By',
                        children: [
                          _buildDetailRow(
                            'Name',
                            investigation.performedBy!.name,
                            Icons.person,
                          ),
                          _buildDetailRow(
                            'Designation',
                            investigation.performedBy!.designation,
                            Icons.work,
                          ),
                          _buildDetailRow(
                            'Facility',
                            investigation.performedBy!.facility,
                            Icons.business,
                          ),
                        ],
                      ),

                    // Attachments section (if available)
                    if (investigation.attachments.isNotEmpty)
                      _buildDetailSection(
                        title: 'Attachments',
                        children: [
                          ...investigation.attachments.map(
                              (attachment) => _buildAttachmentItem(attachment)),
                        ],
                      ),

                    // Notes section (if available)
                    if (investigation.notes.isNotEmpty)
                      _buildDetailSection(
                        title: 'Notes',
                        children: [
                          ...investigation.notes
                              .map((note) => _buildNoteItem(note)),
                        ],
                      ),

                    // Results section (if available)
                    if (investigation.results != null)
                      _buildDetailSection(
                        title: 'Results',
                        children: [
                          _buildResultsContent(investigation.results!),
                        ],
                      ),

                    // Action buttons
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            if (investigation.attachments.isNotEmpty) {
                              _openAttachment(
                                  investigation.attachments.first.fileUrl);
                            }
                          },
                          icon: Icon(Icons.visibility),
                          label: Text('View Report'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _navigateToUploadReport(investigation.id),
                          icon: Icon(Icons.upload_file),
                          label: Text('Upload Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HospitalTheme.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(
      {required String title, required List<Widget> children}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
      String label, String value, Color statusColor, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: statusColor,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: HospitalTheme.textMedium,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: HospitalTheme.primary,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: HospitalTheme.textMedium,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: HospitalTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentItem(Attachment attachment) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HospitalTheme.surfaceLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HospitalTheme.border),
      ),
      child: Row(
        children: [
          _getAttachmentIcon(attachment.fileType),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: HospitalTheme.primary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Uploaded on ${_formatDate(attachment.uploadDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: HospitalTheme.textMedium,
                  ),
                ),
                if (attachment.description.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    attachment.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: HospitalTheme.textMedium,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.visibility, color: HospitalTheme.info),
            onPressed: () => _openAttachment(attachment.fileUrl),
            tooltip: 'View Attachment',
          ),
          IconButton(
            icon: Icon(Icons.download, color: HospitalTheme.primary),
            onPressed: () => _openAttachment(attachment.fileUrl),
            tooltip: 'Download',
          ),
        ],
      ),
    );
  }

  Widget _getAttachmentIcon(String fileType) {
    IconData iconData;
    Color iconColor;

    switch (fileType.toUpperCase()) {
      case 'PDF':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case 'JPEG':
      case 'JPG':
      case 'PNG':
        iconData = Icons.image;
        iconColor = Colors.blue;
        break;
      case 'DOCX':
      case 'DOC':
        iconData = Icons.description;
        iconColor = Colors.blue.shade800;
        break;
      case 'XLSX':
      case 'XLS':
        iconData = Icons.table_chart;
        iconColor = Colors.green;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  Widget _buildNoteItem(Note note) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HospitalTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: HospitalTheme.primary.withOpacity(0.1),
                child: Text(
                  note.addedBy.name.isNotEmpty
                      ? note.addedBy.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: HospitalTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                '${note.addedBy.name} (${note.addedBy.userType})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: HospitalTheme.primary,
                ),
              ),
              Spacer(),
              Text(
                _formatDate(note.dateAdded),
                style: TextStyle(
                  fontSize: 12,
                  color: HospitalTheme.textMedium,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            note.text,
            style: TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsContent(Results results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: results.isAbnormal
                    ? HospitalTheme.warning.withOpacity(0.1)
                    : HospitalTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    results.isAbnormal ? Icons.warning : Icons.check_circle,
                    size: 16,
                    color: results.isAbnormal
                        ? HospitalTheme.warning
                        : HospitalTheme.success,
                  ),
                  SizedBox(width: 4),
                  Text(
                    results.isAbnormal ? 'Abnormal Results' : 'Normal Results',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: results.isAbnormal
                          ? HospitalTheme.warning
                          : HospitalTheme.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Findings
        if (results.findings.isNotEmpty) ...[
          _buildResultSection('Findings', results.findings),
          SizedBox(height: 16),
        ],

        // Impression
        if (results.impression.isNotEmpty) ...[
          _buildResultSection('Impression', results.impression),
          SizedBox(height: 16),
        ],

        // Recommendations
        if (results.recommendations.isNotEmpty) ...[
          _buildResultSection('Recommendations', results.recommendations),
          SizedBox(height: 16),
        ],

        // Numerical Results
        if (results.numericalResults.isNotEmpty) ...[
          Text(
            'Test Results',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.textDark,
            ),
          ),
          SizedBox(height: 8),
          _buildResultsTable(results.numericalResults, results.normalRanges),
        ],
      ],
    );
  }

  Widget _buildResultSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: HospitalTheme.border),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: HospitalTheme.textDark,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsTable(
      Map<String, dynamic> results, Map<String, dynamic> normalRanges) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HospitalTheme.border),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        thickness: 6,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor:
                MaterialStateProperty.all(HospitalTheme.surfaceLight),
            headingTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: HospitalTheme.primary,
            ),
            dataRowHeight: 50,
            columns: [
              DataColumn(
                  label: Container(width: 120, child: Text('Parameter'))),
              DataColumn(label: Container(width: 100, child: Text('Result'))),
              DataColumn(
                  label: Container(width: 120, child: Text('Normal Range'))),
              DataColumn(label: Container(width: 100, child: Text('Status'))),
            ],
            rows: results.entries.map((entry) {
              final parameter = entry.key;
              final value = entry.value;
              final range = normalRanges[parameter] ?? 'N/A';

              bool isAbnormal = false;
              if (value is num && range is String) {
                // Try to parse the range
                final rangeParts = range.split('-');
                if (rangeParts.length == 2) {
                  try {
                    final min = double.parse(
                        rangeParts[0].replaceAll(RegExp(r'[^0-9.]'), ''));
                    final max = double.parse(
                        rangeParts[1].replaceAll(RegExp(r'[^0-9.]'), ''));
                    isAbnormal = value < min || value > max;
                  } catch (e) {
                    // Parsing failed, assume normal
                  }
                }
              }

              return DataRow(
                cells: [
                  DataCell(Text(parameter)),
                  DataCell(
                    Text(
                      value.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isAbnormal
                            ? HospitalTheme.error
                            : HospitalTheme.textDark,
                      ),
                    ),
                  ),
                  DataCell(Text(range.toString())),
                  DataCell(
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAbnormal
                            ? HospitalTheme.error.withOpacity(0.1)
                            : HospitalTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isAbnormal ? 'Abnormal' : 'Normal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isAbnormal
                              ? HospitalTheme.error
                              : HospitalTheme.success,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Results Available':
        return HospitalTheme.success;
      case 'Scheduled':
        return HospitalTheme.warning;
      case 'Cancelled':
        return HospitalTheme.error;
      default:
        return HospitalTheme.info;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return HospitalTheme.error;
      case 'High':
        return HospitalTheme.warning;
      case 'Routine':
        return HospitalTheme.info;
      default:
        return HospitalTheme.textMedium;
    }
  }

  IconData _getInvestigationIcon(String type) {
    switch (type) {
      case 'Blood Test':
        return Icons.opacity;
      case 'X-Ray':
        return Icons.broken_image;
      case 'CT Scan':
        return Icons.scanner;
      case 'MRI':
        return Icons.scanner_outlined;
      case 'Ultrasound':
        return Icons.waves;
      default:
        return Icons.science;
    }
  }

  String _getParametersText(InvestigationDetails details) {
    if (details.parameters != null && details.parameters!.isNotEmpty) {
      return details.parameters!.join(', ');
    } else if (details.bodySite != null && details.bodySite!.isNotEmpty) {
      return details.bodySite!;
    } else {
      return 'N/A';
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}
