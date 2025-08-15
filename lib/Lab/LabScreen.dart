import 'dart:io';
import 'package:doctordesktop/StateProvider.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class LabPatientsScreen extends ConsumerStatefulWidget {
  const LabPatientsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LabPatientsScreen> createState() => _LabPatientsScreenState();
}

class _LabPatientsScreenState extends ConsumerState<LabPatientsScreen> {
  String _searchQuery = '';
  String _dischargeFilter =
      'not_discharged'; // Default: show not discharged patients
  String _sortOption = 'date_desc'; // Default: newest first

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(labReportNotifierProvider.notifier).fetchLabPatients();
    });
  }

  @override
  Widget build(BuildContext context) {
    final labReportsState = ref.watch(labReportNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab Reports'),
        backgroundColor: HospitalTheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      backgroundColor: HospitalTheme.background,
      body: Column(
        children: [
          // Enhanced Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lab Reports Management',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: HospitalTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'View and manage all patient lab reports',
                          style: TextStyle(
                            fontSize: 14,
                            color: HospitalTheme.textMedium,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildSortDropdown(),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => ref
                              .read(labReportNotifierProvider.notifier)
                              .fetchLabPatients(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HospitalTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    // Search Bar
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: TextField(
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Search by patient name or test name...',
                            prefixIcon: Icon(Icons.search,
                                color: HospitalTheme.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: HospitalTheme.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: HospitalTheme.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: HospitalTheme.primary, width: 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Filter Chips
                    _buildFilterChips(),
                  ],
                ),

                const SizedBox(height: 16),

                // Stats Summary
                _buildStatsSummary(labReportsState),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: labReportsState.when(
              data: (labReports) {
                final filteredReports = labReports.where((report) {
                  // Filter out entries where patient name is null, empty, or "Unknown Patient"
                  final patientName = report.patient?.name?.trim();
                  if (patientName == null ||
                      patientName.isEmpty ||
                      patientName.toLowerCase() == 'unknown patient' ||
                      patientName.toLowerCase() == 'unknown') {
                    return false;
                  }

                  // Apply discharge filter
                  if (_dischargeFilter == 'discharged' &&
                      (report.patient?.discharged != true)) {
                    return false;
                  }
                  if (_dischargeFilter == 'not_discharged' &&
                      (report.patient?.discharged == true)) {
                    return false;
                  }

                  // Apply search query
                  if (_searchQuery.isEmpty) return true;
                  final searchLower = _searchQuery.toLowerCase();

                  final nameMatch =
                      patientName.toLowerCase().contains(searchLower);
                  final testNameMatch = report.labTestNameGivenByDoctor
                          ?.toLowerCase()
                          .contains(searchLower) ??
                      false;

                  return nameMatch || testNameMatch;
                }).toList();

                // Apply sorting
                _sortReports(filteredReports);

                if (filteredReports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.science_outlined,
                          size: 80,
                          color: HospitalTheme.textLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No lab reports available for the selected filters'
                              : 'No matching reports found',
                          style: TextStyle(
                            fontSize: 18,
                            color: HospitalTheme.textMedium,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => setState(() {
                            _searchQuery = '';
                            _dischargeFilter = 'all';
                          }),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Clear Filters'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HospitalTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: filteredReports.length,
                    itemBuilder: (context, index) =>
                        _buildLabReportCard(filteredReports[index]),
                  ),
                );
              },
              loading: () => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: HospitalTheme.primary),
                    const SizedBox(height: 16),
                    Text('Loading lab reports...',
                        style: TextStyle(color: HospitalTheme.textMedium)),
                  ],
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 60, color: HospitalTheme.error),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading lab reports',
                      style:
                          TextStyle(fontSize: 18, color: HospitalTheme.error),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: TextStyle(color: HospitalTheme.textMedium),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref
                          .read(labReportNotifierProvider.notifier)
                          .fetchLabPatients(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: HospitalTheme.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: HospitalTheme.primary,
      //   onPressed: () => _exportReportsDialog(),
      //   child: const Icon(Icons.download, color: Colors.white),
      //   tooltip: 'Export Reports',
      // ),
    );
  }

  void _sortReports(List reports) {
    switch (_sortOption) {
      case 'date_desc':
        reports.sort((a, b) {
          // Sort by ID descending if dates are not available
          // Assuming newer IDs are larger
          return (b.id ?? '').compareTo(a.id ?? '');
        });
        break;
      case 'date_asc':
        reports.sort((a, b) {
          return (a.id ?? '').compareTo(b.id ?? '');
        });
        break;
      case 'name_asc':
        reports.sort((a, b) {
          return (a.patient?.name ?? '').compareTo(b.patient?.name ?? '');
        });
        break;
      case 'name_desc':
        reports.sort((a, b) {
          return (b.patient?.name ?? '').compareTo(a.patient?.name ?? '');
        });
        break;
      default:
        break;
    }
  }

  Widget _buildStatsSummary(dynamic labReportsState) {
    // Only build stats when data is loaded
    if (labReportsState is AsyncData) {
      final labReports = labReportsState.value;

      // Filter out unknown patients for stats too
      final validReports = labReports.where((report) {
        final patientName = report.patient?.name?.trim();
        return patientName != null &&
            patientName.isNotEmpty &&
            patientName.toLowerCase() != 'unknown patient' &&
            patientName.toLowerCase() != 'unknown';
      }).toList();

      int totalReports = validReports.length;
      int activePatients =
          validReports.where((r) => r.patient?.discharged != true).length;
      int dischargedPatients =
          validReports.where((r) => r.patient?.discharged == true).length;
      int pendingReports =
          validReports.where((r) => (r.reports?.length ?? 0) == 0).length;

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Patients',
                '$totalReports',
                Icons.people_alt,
                HospitalTheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Active Patients',
                '$activePatients',
                Icons.person,
                HospitalTheme.success,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Discharged',
                '$dischargedPatients',
                Icons.check_circle,
                HospitalTheme.info,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Pending Reports',
                '$pendingReports',
                Icons.hourglass_empty,
                HospitalTheme.warning,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: HospitalTheme.textMedium,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('All Patients'),
          selected: _dischargeFilter == 'all',
          onSelected: (selected) {
            if (selected) {
              setState(() => _dischargeFilter = 'all');
            }
          },
          backgroundColor: HospitalTheme.surfaceLight,
          selectedColor: HospitalTheme.primary.withOpacity(0.2),
          labelStyle: TextStyle(
            color: _dischargeFilter == 'all'
                ? HospitalTheme.primary
                : HospitalTheme.textMedium,
          ),
          avatar: _dischargeFilter == 'all'
              ? Icon(Icons.check_circle, size: 16, color: HospitalTheme.primary)
              : null,
        ),
        ChoiceChip(
          label: const Text('Not Discharged'),
          selected: _dischargeFilter == 'not_discharged',
          onSelected: (selected) {
            if (selected) {
              setState(() => _dischargeFilter = 'not_discharged');
            }
          },
          backgroundColor: HospitalTheme.surfaceLight,
          selectedColor: HospitalTheme.success.withOpacity(0.2),
          labelStyle: TextStyle(
            color: _dischargeFilter == 'not_discharged'
                ? HospitalTheme.success
                : HospitalTheme.textMedium,
          ),
          avatar: _dischargeFilter == 'not_discharged'
              ? Icon(Icons.person, size: 16, color: HospitalTheme.success)
              : null,
        ),
        ChoiceChip(
          label: const Text('Discharged'),
          selected: _dischargeFilter == 'discharged',
          onSelected: (selected) {
            if (selected) {
              setState(() => _dischargeFilter = 'discharged');
            }
          },
          backgroundColor: HospitalTheme.surfaceLight,
          selectedColor: HospitalTheme.info.withOpacity(0.2),
          labelStyle: TextStyle(
            color: _dischargeFilter == 'discharged'
                ? HospitalTheme.info
                : HospitalTheme.textMedium,
          ),
          avatar: _dischargeFilter == 'discharged'
              ? Icon(Icons.check_circle, size: 16, color: HospitalTheme.info)
              : null,
        ),
      ],
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HospitalTheme.border),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortOption,
          onChanged: (value) {
            if (value != null) {
              setState(() => _sortOption = value);
            }
          },
          icon: Icon(Icons.sort, color: HospitalTheme.primary),
          style: TextStyle(color: HospitalTheme.textDark),
          items: [
            DropdownMenuItem(
              value: 'date_desc',
              child: Row(
                children: [
                  Icon(Icons.arrow_downward,
                      size: 16, color: HospitalTheme.textMedium),
                  const SizedBox(width: 8),
                  const Text('Newest First'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'date_asc',
              child: Row(
                children: [
                  Icon(Icons.arrow_upward,
                      size: 16, color: HospitalTheme.textMedium),
                  const SizedBox(width: 8),
                  const Text('Oldest First'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'name_asc',
              child: Row(
                children: [
                  Icon(Icons.sort_by_alpha,
                      size: 16, color: HospitalTheme.textMedium),
                  const SizedBox(width: 8),
                  const Text('Name (A-Z)'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'name_desc',
              child: Row(
                children: [
                  Icon(Icons.sort_by_alpha,
                      size: 16, color: HospitalTheme.textMedium),
                  const SizedBox(width: 8),
                  const Text('Name (Z-A)'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabReportCard(dynamic report) {
    final patient = report.patient;
    final doctor = report.doctor;
    final isDischargedPatient = patient?.discharged == true;
    final hasReports = (report.reports?.length ?? 0) > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDischargedPatient
              ? HospitalTheme.info.withOpacity(0.3)
              : HospitalTheme.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showReportDetails(report),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Patient Status Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDischargedPatient
                            ? HospitalTheme.info.withOpacity(0.1)
                            : HospitalTheme.laboratory.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isDischargedPatient ? Icons.how_to_reg : Icons.biotech,
                        color: isDischargedPatient
                            ? HospitalTheme.info
                            : HospitalTheme.laboratory,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient?.name ?? 'N/A',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: HospitalTheme.textDark,
                            ),
                          ),
                          Text(
                            'ID: ${report.id ?? "N/A"}',
                            style: TextStyle(
                              fontSize: 12,
                              color: HospitalTheme.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isDischargedPatient)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: HospitalTheme.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                size: 14, color: HospitalTheme.info),
                            const SizedBox(width: 4),
                            Text(
                              'Discharged',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: HospitalTheme.info,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const Spacer(),

                // Patient Info
                _buildInfoRow(Icons.person,
                    '${patient?.age ?? "N/A"} yrs, ${patient?.gender ?? "N/A"}'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.phone, patient?.contact ?? "N/A"),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.medical_services,
                    doctor?.doctorName ?? "Unknown Doctor"),

                const Spacer(),

                // Test Info with Visual Indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: hasReports
                        ? HospitalTheme.success.withOpacity(0.1)
                        : HospitalTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasReports
                          ? HospitalTheme.success.withOpacity(0.2)
                          : HospitalTheme.warning.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                          hasReports
                              ? Icons.check_circle
                              : Icons.pending_actions,
                          size: 16,
                          color: hasReports
                              ? HospitalTheme.success
                              : HospitalTheme.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          report.labTestNameGivenByDoctor ??
                              "No test specified",
                          style: TextStyle(
                            fontSize: 12,
                            color: HospitalTheme.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description,
                            size: 16, color: HospitalTheme.textLight),
                        const SizedBox(width: 4),
                        Text(
                          '${report.reports?.length ?? 0} reports',
                          style: TextStyle(
                            fontSize: 12,
                            color: HospitalTheme.textMedium,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.visibility,
                              size: 20, color: HospitalTheme.primary),
                          onPressed: () => _showReportDetails(report),
                          tooltip: 'View Details',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _navigateToAddReport(report),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HospitalTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Add Report',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: HospitalTheme.textMedium),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: HospitalTheme.textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showReportDetails(dynamic report) {
    showDialog(
      context: context,
      builder: (context) => ReportDetailsDialog(
        report: report,
        onRefresh: () =>
            ref.read(labReportNotifierProvider.notifier).fetchLabPatients(),
      ),
    );
  }

  void _navigateToAddReport(dynamic report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddLabReportScreen(
          admissionId: report.admissionId ?? 'N/A',
          patientId: report.patient?.id ?? 'N/A',
          labReportId: report.id ?? 'N/A',
          onReportUploaded: () {
            ref.read(labReportNotifierProvider.notifier).fetchLabPatients();
          },
        ),
      ),
    );
  }

  void _exportReportsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.download, color: HospitalTheme.primary),
            const SizedBox(width: 8),
            const Text('Export Reports'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select the export format:'),
              const SizedBox(height: 16),
              _buildExportOptionTile(
                icon: Icons.description,
                title: 'PDF Report',
                subtitle: 'Comprehensive report with details',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Exporting as PDF...');
                },
              ),
              _buildExportOptionTile(
                icon: Icons.table_chart,
                title: 'Excel Spreadsheet',
                subtitle: 'Tabular data for analysis',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Exporting as Excel...');
                },
              ),
              _buildExportOptionTile(
                icon: Icons.print,
                title: 'Print Reports',
                subtitle: 'Send reports directly to printer',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Preparing to print...');
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HospitalTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: HospitalTheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {},
        ),
      ),
    );
  }
}

class ReportDetailsDialog extends StatelessWidget {
  final dynamic report;
  final VoidCallback onRefresh;

  const ReportDetailsDialog({
    Key? key,
    required this.report,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final patient = report.patient;
    final doctor = report.doctor;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: HospitalTheme.primary,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lab Report Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${report.id ?? "N/A"}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Info Section
                    _buildSection(
                      title: 'Patient Information',
                      icon: Icons.person,
                      children: [
                        _buildDetailRow('Name', patient?.name ?? "N/A"),
                        _buildDetailRow(
                            'Age', '${patient?.age ?? "N/A"} years'),
                        _buildDetailRow('Gender', patient?.gender ?? "N/A"),
                        _buildDetailRow('Contact', patient?.contact ?? "N/A"),
                        _buildDetailRow(
                            'Discharge Status',
                            patient?.discharged == true
                                ? "Discharged"
                                : "Active"),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Doctor Info Section
                    _buildSection(
                      title: 'Doctor Information',
                      icon: Icons.medical_services,
                      children: [
                        _buildDetailRow(
                            'Name', doctor?.doctorName ?? "Unknown"),
                        _buildDetailRow('Email', doctor?.email ?? "N/A"),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Test Info Section
                    _buildSection(
                      title: 'Test Information',
                      icon: Icons.science,
                      children: [
                        _buildDetailRow(
                            'Admission ID', report.admissionId ?? "N/A"),
                        _buildDetailRow('Test Name',
                            report.labTestNameGivenByDoctor ?? "N/A"),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Reports Section
                    _buildSection(
                      title: 'Test Reports',
                      icon: Icons.description,
                      children: [
                        if (report.reports != null &&
                            report.reports!.isNotEmpty)
                          ...report.reports!
                              .map<Widget>((labReport) =>
                                  _buildReportItem(labReport, context))
                              .toList()
                        else
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'No reports uploaded yet',
                                style: TextStyle(
                                  color: HospitalTheme.textMedium,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: HospitalTheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HospitalTheme.surfaceLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: HospitalTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: HospitalTheme.textMedium,
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

  Widget _buildReportItem(dynamic labReport, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HospitalTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labReport.labTestName ?? "Unknown Test",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Type: ${labReport.labType ?? "N/A"}',
                      style: TextStyle(
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.visibility, color: HospitalTheme.primary),
                    onPressed: () => _openReport(labReport.reportUrl),
                    tooltip: 'View Report',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: HospitalTheme.error),
                    onPressed: () => _confirmDelete(context, labReport._id),
                    tooltip: 'Delete Report',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Uploaded: ${_formatDate(labReport.uploadedAt)}',
            style: TextStyle(
              fontSize: 12,
              color: HospitalTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateInput) {
    if (dateInput == null) return 'N/A';

    try {
      DateTime date;

      if (dateInput is String) {
        date = DateTime.parse(dateInput);
      } else if (dateInput is DateTime) {
        date = dateInput;
      } else {
        return 'N/A';
      }

      return DateFormat('MMM dd, yyyy hh:mm a').format(date.toLocal());
    } catch (e) {
      print('Error formatting date: $e');
      return dateInput.toString();
    }
  }

  Future<void> _openReport(String? url) async {
    if (url == null || url.isEmpty) return;

    try {
      Methods().openPdf(url);
    } catch (e) {
      print('Error opening report: $e');
    }
  }

  void _confirmDelete(BuildContext context, String? reportId) {
    if (reportId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text(
            'Are you sure you want to delete this report? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteReport(context, reportId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReport(BuildContext context, String reportId) async {
    try {
      final response = await http.delete(
        Uri.parse(
            '${KVM_URL}/labs/deleteSpecificReport/${report.id}/$reportId'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report deleted successfully')),
        );
        Navigator.pop(context);
        onRefresh();
      } else {
        throw Exception('Failed to delete report');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting report: $e')),
      );
    }
  }
}

class AddLabReportScreen extends StatefulWidget {
  final String admissionId;
  final String patientId;
  final String labReportId;
  final VoidCallback onReportUploaded;

  const AddLabReportScreen({
    Key? key,
    required this.admissionId,
    required this.patientId,
    required this.labReportId,
    required this.onReportUploaded,
  }) : super(key: key);

  @override
  State<AddLabReportScreen> createState() => _AddLabReportScreenState();
}

class _AddLabReportScreenState extends State<AddLabReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _testNameController = TextEditingController();
  final _testTypeController = TextEditingController();
  File? _selectedFile;
  bool _isUploading = false;

  @override
  void dispose() {
    _testNameController.dispose();
    _testTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _uploadReport() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields and select a file')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${KVM_URL}/labs/upload-lab-report'),
      );

      request.fields['admissionId'] = widget.admissionId;
      request.fields['patientId'] = widget.patientId;
      request.fields['labReportId'] = widget.labReportId;
      request.fields['labTestName'] = _testNameController.text;
      request.fields['labType'] = _testTypeController.text;

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        _selectedFile!.path,
      ));

      var response = await request.send();

      if (response.statusCode == 200) {
        widget.onReportUploaded();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lab report uploaded successfully')),
        );
      } else {
        throw Exception('Failed to upload report');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HospitalTheme.background,
      appBar: AppBar(
        title: const Text('Add Lab Report'),
        backgroundColor: HospitalTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          width: 600,
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Upload Lab Report',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _testNameController,
                  decoration: const InputDecoration(
                    labelText: 'Test Name',
                    prefixIcon: Icon(Icons.science),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter test name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _testTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Test Type',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter test type' : null,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: HospitalTheme.border),
                    borderRadius: BorderRadius.circular(8),
                    color: HospitalTheme.surfaceLight.withOpacity(0.3),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.upload_file,
                        size: 48,
                        color: HospitalTheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFile != null
                            ? 'Selected: ${_selectedFile!.path.split('/').last}'
                            : 'No file selected',
                        style: TextStyle(
                          color: _selectedFile != null
                              ? HospitalTheme.textDark
                              : HospitalTheme.textMedium,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Choose PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HospitalTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isUploading ? null : _uploadReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HospitalTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Upload Report',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Additional utility widgets for enhanced UI

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: HospitalTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class ReportStatusBadge extends StatelessWidget {
  final String status;

  const ReportStatusBadge({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'completed':
        bgColor = HospitalTheme.success.withOpacity(0.1);
        textColor = HospitalTheme.success;
        icon = Icons.check_circle;
        break;
      case 'pending':
        bgColor = HospitalTheme.warning.withOpacity(0.1);
        textColor = HospitalTheme.warning;
        icon = Icons.hourglass_empty;
        break;
      case 'in progress':
        bgColor = HospitalTheme.info.withOpacity(0.1);
        textColor = HospitalTheme.info;
        icon = Icons.autorenew;
        break;
      default:
        bgColor = HospitalTheme.textMedium.withOpacity(0.1);
        textColor = HospitalTheme.textMedium;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced filter options for lab reports
class FilterOptions extends StatelessWidget {
  final Function(String) onFilterChanged;
  final String currentFilter;

  const FilterOptions({
    Key? key,
    required this.onFilterChanged,
    required this.currentFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter By',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: currentFilter == 'all',
                onSelected: (_) => onFilterChanged('all'),
                backgroundColor: HospitalTheme.surfaceLight,
                selectedColor: HospitalTheme.primary.withOpacity(0.2),
                checkmarkColor: HospitalTheme.primary,
              ),
              FilterChip(
                label: const Text('With Reports'),
                selected: currentFilter == 'with_reports',
                onSelected: (_) => onFilterChanged('with_reports'),
                backgroundColor: HospitalTheme.surfaceLight,
                selectedColor: HospitalTheme.primary.withOpacity(0.2),
                checkmarkColor: HospitalTheme.primary,
              ),
              FilterChip(
                label: const Text('No Reports'),
                selected: currentFilter == 'no_reports',
                onSelected: (_) => onFilterChanged('no_reports'),
                backgroundColor: HospitalTheme.surfaceLight,
                selectedColor: HospitalTheme.primary.withOpacity(0.2),
                checkmarkColor: HospitalTheme.primary,
              ),
              FilterChip(
                label: const Text('Discharged'),
                selected: currentFilter == 'discharged',
                onSelected: (_) => onFilterChanged('discharged'),
                backgroundColor: HospitalTheme.surfaceLight,
                selectedColor: HospitalTheme.primary.withOpacity(0.2),
                checkmarkColor: HospitalTheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Enhanced sorting options
class SortOptions extends StatelessWidget {
  final Function(String) onSortChanged;
  final String currentSort;

  const SortOptions({
    Key? key,
    required this.onSortChanged,
    required this.currentSort,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSortChanged,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'date_desc',
          child: Row(
            children: [
              Icon(Icons.arrow_downward, size: 18),
              SizedBox(width: 8),
              Text('Newest First'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'date_asc',
          child: Row(
            children: [
              Icon(Icons.arrow_upward, size: 18),
              SizedBox(width: 8),
              Text('Oldest First'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'name_asc',
          child: Row(
            children: [
              Icon(Icons.sort_by_alpha, size: 18),
              SizedBox(width: 8),
              Text('Name (A-Z)'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'name_desc',
          child: Row(
            children: [
              Icon(Icons.sort_by_alpha, size: 18),
              SizedBox(width: 8),
              Text('Name (Z-A)'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: HospitalTheme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.sort, size: 18, color: HospitalTheme.textMedium),
            const SizedBox(width: 8),
            Text(
              'Sort',
              style: TextStyle(color: HospitalTheme.textMedium),
            ),
            Icon(Icons.arrow_drop_down, color: HospitalTheme.textMedium),
          ],
        ),
      ),
    );
  }
}
