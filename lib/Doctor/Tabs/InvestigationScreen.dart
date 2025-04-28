import 'dart:convert';
import 'package:doctordesktop/Doctor/Tabs/CreateInvestigstion.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DoctorInvestigationScreen extends StatefulWidget {
  final String patientId;
  final String admissionId;

  const DoctorInvestigationScreen(
      {Key? key, required this.patientId, required this.admissionId})
      : super(key: key);

  @override
  _DoctorInvestigationScreenState createState() =>
      _DoctorInvestigationScreenState();
}

class _DoctorInvestigationScreenState extends State<DoctorInvestigationScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Investigation1> _investigations = [];
  Investigation1? _selectedInvestigation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchInvestigations();
  }

  Future<void> _fetchInvestigations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${KVM_URL}/doctors/getDoctorInvestigations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> investigationsJson = data['data'];
          setState(() {
            _investigations = investigationsJson
                .map((json) => Investigation1.fromJson(json))
                .toList();

            if (_investigations.isNotEmpty && _selectedInvestigation == null) {
              _selectedInvestigation = _investigations.first;
            }

            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage =
                'Failed to load investigations: ${data['message'] ?? 'Unknown error'}';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Failed to load investigations: ${response.reasonPhrase}';
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

  List<Investigation1> get _filteredInvestigations {
    return _investigations.where((investigation) {
      // Apply search query filter
      final matchesSearch = investigation.patientName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          investigation.investigationType
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          investigation.status
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (investigation.tags?.any((tag) =>
                  tag.toLowerCase().contains(_searchQuery.toLowerCase())) ??
              false);

      // Apply status filter
      final matchesStatus = _selectedStatusFilter == 'All' ||
          investigation.status == _selectedStatusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _selectInvestigation(Investigation1 investigation) {
    setState(() {
      _selectedInvestigation = investigation;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HospitalTheme.buildAppBar(
        context: context,
        title: 'Investigation Management',
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: BoxDecoration(
        color: HospitalTheme.background,
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator()
                : _errorMessage != null
                    ? _buildErrorMessage()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.science_outlined,
            color: HospitalTheme.primary,
            size: 28,
          ),
          SizedBox(width: 16),
          Text(
            'Investigation Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.textDark,
            ),
          ),
          Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateInvestigationScreen(
                    patientId: widget.patientId,
                    admissionId: widget.admissionId,
                  ),
                ),
              ).then((_) {
                // Refresh data when returning from create screen
                _fetchInvestigations();
              });
            },
            icon: Icon(Icons.add),
            label: Text('New Investigation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          SizedBox(width: 16),
          _buildRefreshButton(),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return ElevatedButton.icon(
      icon: Icon(Icons.refresh),
      label: Text('Refresh Data'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: HospitalTheme.primary,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: _fetchInvestigations,
    );
  }

  Widget _buildLoadingIndicator() {
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

  Widget _buildErrorMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: HospitalTheme.error,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            _errorMessage ?? 'An unknown error occurred',
            style: TextStyle(
              color: HospitalTheme.error,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            label: Text('Try Again'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: HospitalTheme.primary,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _fetchInvestigations,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left sidebar with list of investigations
        Container(
          width: 340,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildFiltersSection(),
              Expanded(
                child: _filteredInvestigations.isEmpty
                    ? _buildNoInvestigationsMessage()
                    : _buildInvestigationsList(),
              ),
            ],
          ),
        ),

        // Right side with investigation details
        Expanded(
          child: _selectedInvestigation == null
              ? _buildNoSelectionMessage()
              : _buildInvestigationDetails(),
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    final statusOptions = [
      'All',
      'Results Available',
      'Scheduled',
      'Pending',
      'Completed',
      'Cancelled'
    ];

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: HospitalTheme.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: HospitalTheme.textDark,
            ),
          ),
          SizedBox(height: 16),

          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search investigations...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: HospitalTheme.border),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          SizedBox(height: 16),

          // Status filter
          Text(
            'Status:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: HospitalTheme.textDark,
            ),
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: HospitalTheme.border),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStatusFilter,
                isExpanded: true,
                items: statusOptions.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatusFilter = value;
                    });
                  }
                },
              ),
            ),
          ),

          SizedBox(height: 16),

          // Investigations count
          Text(
            '${_filteredInvestigations.length} investigations found',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: HospitalTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoInvestigationsMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: HospitalTheme.textLight,
          ),
          SizedBox(height: 16),
          Text(
            'No investigations found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: HospitalTheme.textMedium,
            ),
          ),
          if (_searchQuery.isNotEmpty || _selectedStatusFilter != 'All')
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Try adjusting your filters',
                style: TextStyle(
                  color: HospitalTheme.textMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInvestigationsList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredInvestigations.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: HospitalTheme.border),
      itemBuilder: (context, index) {
        final investigation = _filteredInvestigations[index];
        final isSelected = _selectedInvestigation?.id == investigation.id;

        return _buildInvestigationListItem(investigation, isSelected);
      },
    );
  }

  Widget _buildInvestigationListItem(
      Investigation1 investigation, bool isSelected) {
    // Determine status color
    Color statusColor;
    switch (investigation.status) {
      case 'Results Available':
        statusColor = HospitalTheme.success;
        break;
      case 'Scheduled':
        statusColor = HospitalTheme.info;
        break;
      case 'Pending':
        statusColor = HospitalTheme.warning;
        break;
      case 'Cancelled':
        statusColor = HospitalTheme.error;
        break;
      default:
        statusColor = HospitalTheme.textMedium;
    }

    return InkWell(
      onTap: () => _selectInvestigation(investigation),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? HospitalTheme.surfaceLight : Colors.white,
          border: Border(
            left: BorderSide(
              color: isSelected ? HospitalTheme.primary : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    investigation.investigationType,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: HospitalTheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    investigation.status,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: 16, color: HospitalTheme.textMedium),
                SizedBox(width: 4),
                Text(
                  investigation.patientName,
                  style: TextStyle(color: HospitalTheme.textMedium),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 16, color: HospitalTheme.textMedium),
                SizedBox(width: 4),
                Text(
                  _formatDate(investigation.orderDate),
                  style: TextStyle(color: HospitalTheme.textMedium),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (investigation.tags != null && investigation.tags!.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: investigation.tags!.map((tag) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: HospitalTheme.borderDark.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 11,
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                  );
                }).toList(),
              ),
            SizedBox(height: 4),
            Row(
              children: [
                _buildFeatureIndicator(investigation.hasAttachments,
                    Icons.attach_file, 'Has Attachments'),
                SizedBox(width: 8),
                _buildFeatureIndicator(
                    investigation.hasResults, Icons.assessment, 'Has Results'),
                if (investigation.isOverdue) ...[
                  SizedBox(width: 8),
                  _buildFeatureIndicator(true, Icons.warning, 'Overdue',
                      color: HospitalTheme.error),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureIndicator(bool isAvailable, IconData icon, String tooltip,
      {Color? color}) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isAvailable
              ? (color ?? HospitalTheme.info).withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isAvailable ? (color ?? HospitalTheme.info) : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildNoSelectionMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science_outlined,
            size: 80,
            color: HospitalTheme.textLight,
          ),
          SizedBox(height: 16),
          Text(
            'Select an investigation to view details',
            style: TextStyle(
              fontSize: 18,
              color: HospitalTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestigationDetails() {
    if (_selectedInvestigation == null) return Container();

    final investigation = _selectedInvestigation!;

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with investigation type and status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      investigation.investigationType,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                    SizedBox(height: 4),
                    _buildStatusWithPriorityIndicator(investigation),
                  ],
                ),
              ),
              // Quick actions
              Row(
                children: [
                  _buildActionButton(
                    label: 'Print Details',
                    icon: Icons.print,
                    onPressed: () {
                      // Implement print functionality
                    },
                  ),
                  SizedBox(width: 12),
                  if (investigation.hasAttachments)
                    _buildActionButton(
                      label: 'View Attachment',
                      icon: Icons.visibility,
                      onPressed: () {
                        if (investigation.attachments != null &&
                            investigation.attachments!.isNotEmpty &&
                            investigation.attachments!.first.fileUrl != null) {
                          Methods().openPdf(
                              investigation.attachments!.first.fileUrl!);
                        } else {
                          // Show error or message that file is not available
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('No viewable attachment available')),
                          );
                        }
                      },
                    ),
                ],
              ),
            ],
          ),

          SizedBox(height: 32),

          // Investigation details in cards
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailCard(
                      title: 'Basic Information',
                      icon: Icons.info_outline,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailItem(
                              'Patient', investigation.patientName),
                          _buildDetailItem(
                              'Patient ID', investigation.patientIdNumber),
                          _buildDetailItem('Doctor', investigation.doctorName),
                          _buildDetailItem('Order Date',
                              _formatDate(investigation.orderDate)),
                          if (investigation.scheduledDate != null)
                            _buildDetailItem('Scheduled Date',
                                _formatDate(investigation.scheduledDate!)),
                          if (investigation.completionDate != null)
                            _buildDetailItem('Completion Date',
                                _formatDate(investigation.completionDate!)),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildDetailCard(
                      title: 'Investigation Details',
                      icon: Icons.science_outlined,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailItem(
                              'Type', investigation.investigationType),
                          _buildDetailItem(
                              'Reason', investigation.reasonForInvestigation),
                          _buildDetailItem('Priority', investigation.priority),
                          if (investigation.investigationDetails != null) ...[
                            SizedBox(height: 12),
                            Text(
                              'Parameters:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: HospitalTheme.textDark,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _formatInvestigationDetails(
                                  investigation.investigationDetails!),
                              style: TextStyle(color: HospitalTheme.textDark),
                            ),
                          ],
                          SizedBox(height: 12),
                          Text(
                            'Clinical History:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: HospitalTheme.textDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            investigation.clinicalHistory ??
                                'No clinical history provided',
                            style: TextStyle(color: HospitalTheme.textDark),
                          ),
                        ],
                      ),
                    ),
                    if (investigation.billing != null) ...[
                      SizedBox(height: 20),
                      _buildDetailCard(
                        title: 'Billing Information',
                        icon: Icons.payments_outlined,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailItem(
                                'Payment Status',
                                investigation.billing!.paymentStatus ??
                                    'Unknown'),
                            _buildDetailItem(
                                'Insurance Covered',
                                investigation.billing!.insuranceCovered == true
                                    ? 'Yes'
                                    : 'No'),
                            if (investigation.billing!.cost != null)
                              _buildDetailItem(
                                  'Cost', '₹${investigation.billing!.cost}'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(width: 20),

              // Right column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (investigation.hasResults) ...[
                      _buildResultsCard(investigation),
                      SizedBox(height: 20),
                    ],
                    if (investigation.hasAttachments) ...[
                      _buildAttachmentsCard(investigation),
                      SizedBox(height: 20),
                    ],
                    if (investigation.notes != null &&
                        investigation.notes!.isNotEmpty) ...[
                      _buildNotesCard(investigation),
                      SizedBox(height: 20),
                    ],
                    if (investigation.tags != null &&
                        investigation.tags!.isNotEmpty) ...[
                      _buildTagsCard(investigation),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusWithPriorityIndicator(Investigation1 investigation) {
    // Determine status color
    Color statusColor;
    switch (investigation.status) {
      case 'Results Available':
        statusColor = HospitalTheme.success;
        break;
      case 'Scheduled':
        statusColor = HospitalTheme.info;
        break;
      case 'Pending':
        statusColor = HospitalTheme.warning;
        break;
      case 'Cancelled':
        statusColor = HospitalTheme.error;
        break;
      default:
        statusColor = HospitalTheme.textMedium;
    }

    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor),
          ),
          child: Text(
            investigation.status,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),

        SizedBox(width: 12),

        // Priority indicator
        Row(
          children: [
            Icon(
              Icons.flag,
              size: 16,
              color: investigation.priority == 'Urgent'
                  ? HospitalTheme.error
                  : HospitalTheme.info,
            ),
            SizedBox(width: 4),
            Text(
              investigation.priority,
              style: TextStyle(
                color: investigation.priority == 'Urgent'
                    ? HospitalTheme.error
                    : HospitalTheme.info,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: HospitalTheme.textOnPrimary,
        backgroundColor: HospitalTheme.primary,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: HospitalTheme.primary),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: HospitalTheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: HospitalTheme.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard(Investigation1 investigation) {
    if (investigation.results == null) return Container();

    final results = investigation.results!;

    return _buildDetailCard(
      title: 'Results',
      icon: Icons.assessment,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (results.findings != null) ...[
            Text(
              'Findings:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            SizedBox(height: 4),
            Text(
              results.findings!,
              style: TextStyle(color: HospitalTheme.textDark),
            ),
            SizedBox(height: 12),
          ],
          if (results.impression != null) ...[
            Text(
              'Impression:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            SizedBox(height: 4),
            Text(
              results.impression!,
              style: TextStyle(color: HospitalTheme.textDark),
            ),
            SizedBox(height: 12),
          ],
          if (results.isAbnormal != null) ...[
            _buildDetailItem(
                'Abnormal Result', results.isAbnormal! ? 'Yes' : 'No'),
            SizedBox(height: 8),
          ],
          if (results.numericalResults != null &&
              results.numericalResults!.isNotEmpty) ...[
            Text(
              'Numerical Results:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            SizedBox(height: 8),
            _buildNumericalResultsTable(results),
            SizedBox(height: 12),
          ],
          if (results.recommendations != null) ...[
            Text(
              'Recommendations:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            SizedBox(height: 4),
            Text(
              results.recommendations!,
              style: TextStyle(color: HospitalTheme.textDark),
            ),
          ],
          if (investigation.performedBy != null) ...[
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            Text(
              'Performed By:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${investigation.performedBy!.name} (${investigation.performedBy!.designation}), ${investigation.performedBy!.facility}',
              style: TextStyle(
                color: HospitalTheme.textDark,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNumericalResultsTable(InvestigationResults results) {
    // Extract normal ranges and numerical results
    final numericalResults = results.numericalResults!;
    final normalRanges = results.normalRanges ?? {};

    // Create a list of all keys from both maps
    final allKeys = <String>{};
    allKeys.addAll(numericalResults.keys);
    allKeys.addAll(normalRanges.keys);

    return Table(
      border: TableBorder.all(
        color: HospitalTheme.border,
        width: 1,
      ),
      columnWidths: {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(2),
      },
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(
            color: HospitalTheme.surfaceLight,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Parameter',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Value',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Normal Range',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
            ),
          ],
        ),
        // Data rows
        ...allKeys.map((key) {
          final value = numericalResults[key]?.toString() ?? '-';
          final range = normalRanges[key] ?? '-';

          bool isAbnormal = false;
          if (normalRanges.containsKey(key) &&
              numericalResults.containsKey(key)) {
            // Simple range check for numerical values
            if (range.contains('-')) {
              try {
                final rangeParts = range.split('-');
                if (rangeParts.length == 2) {
                  final minValue = double.tryParse(
                      rangeParts[0].replaceAll(RegExp(r'[^\d.]'), ''));
                  final maxValue = double.tryParse(
                      rangeParts[1].replaceAll(RegExp(r'[^\d.]'), ''));
                  final actualValue = numericalResults[key] is num
                      ? (numericalResults[key] as num).toDouble()
                      : double.tryParse(value);

                  if (minValue != null &&
                      maxValue != null &&
                      actualValue != null) {
                    isAbnormal =
                        actualValue < minValue || actualValue > maxValue;
                  }
                }
              } catch (e) {
                // Ignore parsing errors
              }
            }
          }

          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(key),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  value,
                  style: TextStyle(
                    color: isAbnormal
                        ? HospitalTheme.error
                        : HospitalTheme.textDark,
                    fontWeight:
                        isAbnormal ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(range),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAttachmentsCard(Investigation1 investigation) {
    if (investigation.attachments == null ||
        investigation.attachments!.isEmpty) {
      return Container();
    }

    return _buildDetailCard(
      title: 'Attachments',
      icon: Icons.attach_file,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: investigation.attachments!.map((attachment) {
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: HospitalTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getFileIcon(attachment.fileType ?? ''),
                      color: HospitalTheme.primary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        attachment.fileName ?? 'Unnamed File',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                if (attachment.description != null) ...[
                  SizedBox(height: 8),
                  Text(
                    attachment.description!,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: HospitalTheme.textMedium,
                      fontSize: 13,
                    ),
                  ),
                ],
                SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Uploaded: ${_formatDate(attachment.uploadDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                    Spacer(),
                    ElevatedButton.icon(
                      icon: Icon(Icons.visibility, size: 16),
                      label: Text('View'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: HospitalTheme.textOnPrimary,
                        backgroundColor: HospitalTheme.primary,
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: TextStyle(fontSize: 12),
                        minimumSize: Size(100, 36),
                      ),
                      onPressed: () {
                        if (attachment.fileUrl != null) {
                          Methods().openPdf(attachment.fileUrl!);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('No viewable file available')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toUpperCase()) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'JPEG':
      case 'JPG':
      case 'PNG':
      case 'GIF':
        return Icons.image;
      case 'DOC':
      case 'DOCX':
        return Icons.description;
      case 'XLS':
      case 'XLSX':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildNotesCard(Investigation1 investigation) {
    if (investigation.notes == null || investigation.notes!.isEmpty) {
      return Container();
    }

    return _buildDetailCard(
      title: 'Notes',
      icon: Icons.note,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: investigation.notes!.map((note) {
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: HospitalTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.text ?? '',
                  style: TextStyle(color: HospitalTheme.textDark),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Added by: ${note.addedBy?.name ?? 'Unknown'} (${note.addedBy?.userType ?? 'Staff'})',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                    Spacer(),
                    Text(
                      _formatDate(note.dateAdded!),
                      style: TextStyle(
                        fontSize: 12,
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTagsCard(Investigation1 investigation) {
    return _buildDetailCard(
      title: 'Tags',
      icon: Icons.local_offer_outlined,
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: investigation.tags!.map((tag) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HospitalTheme.primary.withOpacity(0.3)),
            ),
            child: Text(
              tag,
              style: TextStyle(
                color: HospitalTheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatInvestigationDetails(Map<String, dynamic> details) {
    if (details.isEmpty) return 'No details available';

    String result = '';

    if (details.containsKey('parameters') && details['parameters'] is List) {
      List<dynamic> parameters = details['parameters'];
      result += 'Parameters: ${parameters.join(', ')}';
    }

    if (details.containsKey('bodySite')) {
      if (result.isNotEmpty) result += '\n';
      result += 'Body Site: ${details['bodySite']}';
    }

    // If there are other fields in the details that are not handled, add them
    details.forEach((key, value) {
      if (key != 'parameters' && key != 'bodySite') {
        if (result.isNotEmpty) result += '\n';
        if (value is List) {
          result += '$key: ${value.join(', ')}';
        } else {
          result += '$key: $value';
        }
      }
    });

    return result;
  }
}

// Data models for investigation

class Investigation1 {
  final String id;
  final String patientIdNumber;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String investigationType;
  final String status;
  final String orderDate;
  final String reasonForInvestigation;
  final String priority;
  final Map<String, dynamic>? investigationDetails;
  final String admissionRecordId;
  final Billing? billing;
  final List<String>? tags;
  final List<Attachment>? attachments;
  final List<Note>? notes;
  final String? scheduledDate;
  final String? clinicalHistory;
  final String? completionDate;
  final PerformedBy? performedBy;
  final InvestigationResults? results;
  final int daysSinceOrdered;
  final bool isOverdue;
  final bool hasAttachments;
  final bool hasResults;

  Investigation1({
    required this.id,
    required this.patientIdNumber,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.investigationType,
    required this.status,
    required this.orderDate,
    required this.reasonForInvestigation,
    required this.priority,
    this.investigationDetails,
    required this.admissionRecordId,
    this.billing,
    this.tags,
    this.attachments,
    this.notes,
    this.scheduledDate,
    this.clinicalHistory,
    this.completionDate,
    this.performedBy,
    this.results,
    required this.daysSinceOrdered,
    required this.isOverdue,
    required this.hasAttachments,
    required this.hasResults,
  });

  factory Investigation1.fromJson(Map<String, dynamic> json) {
    return Investigation1(
      id: json['_id'] ?? '',
      patientIdNumber: json['patientIdNumber'] ?? '',
      patientName: json['patientId']?['name'] ?? 'Unknown Patient',
      doctorId: json['doctorId'] ?? '',
      doctorName: json['doctorName'] ?? 'Unknown Doctor',
      investigationType: json['investigationType'] ?? 'Unknown Test',
      status: json['status'] ?? 'Pending',
      orderDate: json['orderDate'] ?? '',
      reasonForInvestigation: json['reasonForInvestigation'] ?? 'Not specified',
      priority: json['priority'] ?? 'Routine',
      investigationDetails: json['investigationDetails'],
      admissionRecordId: json['admissionRecordId'] ?? '',
      billing:
          json['billing'] != null ? Billing.fromJson(json['billing']) : null,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((attachment) => Attachment.fromJson(attachment))
              .toList()
          : null,
      notes: json['notes'] != null
          ? (json['notes'] as List).map((note) => Note.fromJson(note)).toList()
          : null,
      scheduledDate: json['scheduledDate'],
      clinicalHistory: json['clinicalHistory'],
      completionDate: json['completionDate'],
      performedBy: json['performedBy'] != null
          ? PerformedBy.fromJson(json['performedBy'])
          : null,
      results: json['results'] != null
          ? InvestigationResults.fromJson(json['results'])
          : null,
      daysSinceOrdered: json['daysSinceOrdered'] ?? 0,
      isOverdue: json['isOverdue'] ?? false,
      hasAttachments: json['hasAttachments'] ?? false,
      hasResults: json['hasResults'] ?? false,
    );
  }
}

class Billing {
  final bool? insuranceCovered;
  final String? paymentStatus;
  final double? cost;

  Billing({
    this.insuranceCovered,
    this.paymentStatus,
    this.cost,
  });

  factory Billing.fromJson(Map<String, dynamic> json) {
    return Billing(
      insuranceCovered: json['insuranceCovered'],
      paymentStatus: json['paymentStatus'],
      cost: json['cost'] != null ? json['cost'].toDouble() : null,
    );
  }
}

class Attachment {
  final String? fileName;
  final String? fileType;
  final String? fileUrl;
  final String? uploadDate;
  final String? description;

  Attachment({
    this.fileName,
    this.fileType,
    this.fileUrl,
    this.uploadDate,
    this.description,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      fileName: json['fileName'],
      fileType: json['fileType'],
      fileUrl: json['fileUrl'],
      uploadDate: json['uploadDate'],
      description: json['description'],
    );
  }
}

class AddedBy {
  final String? userId;
  final String? userType;
  final String? name;

  AddedBy({
    this.userId,
    this.userType,
    this.name,
  });

  factory AddedBy.fromJson(Map<String, dynamic> json) {
    return AddedBy(
      userId: json['userId'],
      userType: json['userType'],
      name: json['name'],
    );
  }
}

class Note {
  final String? text;
  final AddedBy? addedBy;
  final String? dateAdded;

  Note({
    this.text,
    this.addedBy,
    this.dateAdded,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      text: json['text'],
      addedBy:
          json['addedBy'] != null ? AddedBy.fromJson(json['addedBy']) : null,
      dateAdded: json['dateAdded'],
    );
  }
}

class PerformedBy {
  final String designation;
  final String facility;
  final String name;

  PerformedBy({
    required this.designation,
    required this.facility,
    required this.name,
  });

  factory PerformedBy.fromJson(Map<String, dynamic> json) {
    return PerformedBy(
      designation: json['designation'] ?? 'Staff',
      facility: json['facility'] ?? 'Unknown Facility',
      name: json['name'] ?? 'Unknown',
    );
  }
}

class InvestigationResults {
  final String? findings;
  final String? impression;
  final bool? isAbnormal;
  final Map<String, String>? normalRanges;
  final Map<String, dynamic>? numericalResults;
  final String? recommendations;

  InvestigationResults({
    this.findings,
    this.impression,
    this.isAbnormal,
    this.normalRanges,
    this.numericalResults,
    this.recommendations,
  });

  factory InvestigationResults.fromJson(Map<String, dynamic> json) {
    Map<String, String>? normalRanges;
    if (json['normalRanges'] != null) {
      normalRanges = Map<String, String>.from(json['normalRanges']);
    }

    Map<String, dynamic>? numericalResults;
    if (json['numericalResults'] != null) {
      numericalResults = Map<String, dynamic>.from(json['numericalResults']);
    }

    return InvestigationResults(
      findings: json['findings'],
      impression: json['impression'],
      isAbnormal: json['isAbnormal'],
      normalRanges: normalRanges,
      numericalResults: numericalResults,
      recommendations: json['recommendations'],
    );
  }
}
