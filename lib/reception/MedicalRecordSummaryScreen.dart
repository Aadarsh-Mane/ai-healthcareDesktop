import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/core/utils/PdfViewerScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ==================== DATA MODELS ====================

class PatientInfo {
  final String patientId;
  final String name;
  final int age;
  final String gender;
  final String contact;
  final String address;
  final String? imageUrl;

  const PatientInfo({
    required this.patientId,
    required this.name,
    required this.age,
    required this.gender,
    required this.contact,
    required this.address,
    this.imageUrl,
  });

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    return PatientInfo(
      patientId: json['patientId'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      contact: json['contact'] ?? '',
      address: json['address'] ?? '',
      imageUrl: json['imageUrl']?.isEmpty == true ? null : json['imageUrl'],
    );
  }
}

class AdmissionInfo {
  final int opdNumber;
  final DateTime admissionDate;
  final DateTime? dischargeDate;
  final String doctor;
  final String status;
  final String conditionAtDischarge;
  final int lengthOfStay;
  final Map<String, int> summaryStats;

  const AdmissionInfo({
    required this.opdNumber,
    required this.admissionDate,
    this.dischargeDate,
    required this.doctor,
    required this.status,
    required this.conditionAtDischarge,
    required this.lengthOfStay,
    required this.summaryStats,
  });

  factory AdmissionInfo.fromJson(Map<String, dynamic> json) {
    return AdmissionInfo(
      opdNumber: json['opdNumber'] ?? 0,
      admissionDate: DateTime.parse(json['admissionDate']),
      dischargeDate: json['dischargeDate'] != null
          ? DateTime.parse(json['dischargeDate'])
          : null,
      doctor: json['doctor'] ?? '',
      status: json['status'] ?? '',
      conditionAtDischarge: json['conditionAtDischarge'] ?? '',
      lengthOfStay: json['lengthOfStay'] ?? 0,
      summaryStats:
          Map<String, int>.from(json['summaryStats']?['summaryStats'] ?? {}),
    );
  }
}

class GeneratedPdf {
  final String reportType;
  final String reportName;
  final String fileName;
  final String driveLink;
  final DateTime generatedAt;

  const GeneratedPdf({
    required this.reportType,
    required this.reportName,
    required this.fileName,
    required this.driveLink,
    required this.generatedAt,
  });

  factory GeneratedPdf.fromJson(Map<String, dynamic> json) {
    return GeneratedPdf(
      reportType: json['reportType'] ?? '',
      reportName: json['reportName'] ?? '',
      fileName: json['fileName'] ?? '',
      driveLink: json['driveLink'] ?? '',
      generatedAt: DateTime.parse(json['generatedAt']),
    );
  }
}

class MedicalRecordResponse {
  final bool success;
  final String message;
  final PatientInfo patientInfo;
  final AdmissionInfo latestAdmission;
  final int totalAdmissions;
  final List<GeneratedPdf> generatedPDFs;
  final int totalGenerated;
  final int totalRequested;

  const MedicalRecordResponse({
    required this.success,
    required this.message,
    required this.patientInfo,
    required this.latestAdmission,
    required this.totalAdmissions,
    required this.generatedPDFs,
    required this.totalGenerated,
    required this.totalRequested,
  });

  factory MedicalRecordResponse.fromJson(Map<String, dynamic> json) {
    return MedicalRecordResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      patientInfo: PatientInfo.fromJson(json['patientInfo'] ?? {}),
      latestAdmission: AdmissionInfo.fromJson(json['latestAdmission'] ?? {}),
      totalAdmissions: json['totalAdmissions'] ?? 0,
      generatedPDFs: (json['generatedPDFs'] as List<dynamic>?)
              ?.map((pdf) => GeneratedPdf.fromJson(pdf))
              .toList() ??
          [],
      totalGenerated: json['totalGenerated'] ?? 0,
      totalRequested: json['totalRequested'] ?? 0,
    );
  }
}

// ==================== REPORT TYPE DEFINITIONS ====================

class ReportType {
  final String key;
  final String displayName;
  final String description;
  final IconData icon;
  final Color color;

  const ReportType({
    required this.key,
    required this.displayName,
    required this.description,
    required this.icon,
    required this.color,
  });

  static const List<ReportType> availableReports = [
    ReportType(
      key: 'diagnosis',
      displayName: 'Diagnosis Report',
      description: 'Patient diagnosis and medical findings',
      icon: Icons.medical_services,
      color: HospitalTheme.medical,
    ),
    ReportType(
      key: 'symptoms',
      displayName: 'Symptoms Report',
      description: 'Patient symptoms and complaints',
      icon: Icons.sick,
      color: HospitalTheme.error,
    ),
    ReportType(
      key: 'consulting',
      displayName: 'Consulting Report',
      description: 'Doctor consultation notes and observations',
      icon: Icons.person_search,
      color: HospitalTheme.info,
    ),
    ReportType(
      key: 'prescriptions',
      displayName: 'Prescriptions Report',
      description: 'Prescribed medications and treatments',
      icon: Icons.medication,
      color: HospitalTheme.pharmacy,
    ),
    ReportType(
      key: 'vitals',
      displayName: 'Vital Signs Report',
      description: 'Patient vital signs and measurements',
      icon: Icons.favorite,
      color: HospitalTheme.emergency,
    ),
    // ReportType(
    //   key: 'lab',
    //   displayName: 'Laboratory Report',
    //   description: 'Lab test results and analysis',
    //   icon: Icons.science,
    //   color: HospitalTheme.laboratory,
    // ),
    // ReportType(
    //   key: 'procedures',
    //   displayName: 'Procedures Report',
    //   description: 'Medical procedures and interventions',
    //   icon: Icons.healing,
    //   color: HospitalTheme.secondary,
    // ),
    // ReportType(
    //   key: 'discharge',
    //   displayName: 'Discharge Summary',
    //   description: 'Complete discharge summary and instructions',
    //   icon: Icons.exit_to_app,
    //   color: HospitalTheme.success,
    // ),
  ];
}

// ==================== STATE MANAGEMENT ====================

class MedicalRecordState {
  final Set<String> selectedReportTypes;
  final bool isGenerating;
  final String? error;
  final MedicalRecordResponse? response;
  final String? currentPatientId;

  const MedicalRecordState({
    this.selectedReportTypes = const {},
    this.isGenerating = false,
    this.error,
    this.response,
    this.currentPatientId,
  });

  MedicalRecordState copyWith({
    Set<String>? selectedReportTypes,
    bool? isGenerating,
    String? error,
    MedicalRecordResponse? response,
    String? currentPatientId,
  }) {
    return MedicalRecordState(
      selectedReportTypes: selectedReportTypes ?? this.selectedReportTypes,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
      response: response ?? this.response,
      currentPatientId: currentPatientId ?? this.currentPatientId,
    );
  }
}

class MedicalRecordNotifier extends StateNotifier<MedicalRecordState> {
  MedicalRecordNotifier() : super(const MedicalRecordState());

  void setPatientId(String patientId) {
    state = state.copyWith(currentPatientId: patientId);
  }

  void toggleReportType(String reportType) {
    final currentSelection = Set<String>.from(state.selectedReportTypes);
    if (currentSelection.contains(reportType)) {
      currentSelection.remove(reportType);
    } else {
      currentSelection.add(reportType);
    }
    state = state.copyWith(selectedReportTypes: currentSelection);
  }

  void selectAllReports() {
    final allReports = ReportType.availableReports.map((r) => r.key).toSet();
    state = state.copyWith(selectedReportTypes: allReports);
  }

  void clearSelection() {
    state = state.copyWith(selectedReportTypes: {});
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> generateReports() async {
    if (state.selectedReportTypes.isEmpty || state.currentPatientId == null) {
      state = state.copyWith(
          error:
              'Please select at least one report type and ensure patient ID is set');
      return;
    }

    try {
      state = state.copyWith(isGenerating: true, error: null);

      final response = await http.post(
        Uri.parse(
            '${KVM_URL}/reception/generatePatientRecordPDFs/${state.currentPatientId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'reportTypes': state.selectedReportTypes.toList(),
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final medicalResponse = MedicalRecordResponse.fromJson(responseData);

        state = state.copyWith(
          isGenerating: false,
          response: medicalResponse,
          error: medicalResponse.success ? null : medicalResponse.message,
        );
      } else {
        state = state.copyWith(
          isGenerating: false,
          error: 'Failed to generate reports. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: 'Error generating reports: ${e.toString()}',
      );
    }
  }
}

final medicalRecordProvider =
    StateNotifierProvider<MedicalRecordNotifier, MedicalRecordState>((ref) {
  return MedicalRecordNotifier();
});

// ==================== MAIN SCREEN ====================

class MedicalRecordSummaryScreen extends ConsumerStatefulWidget {
  final String? initialPatientId;

  const MedicalRecordSummaryScreen({
    super.key,
    this.initialPatientId,
  });

  @override
  ConsumerState<MedicalRecordSummaryScreen> createState() =>
      _MedicalRecordSummaryScreenState();
}

class _MedicalRecordSummaryScreenState
    extends ConsumerState<MedicalRecordSummaryScreen> {
  final TextEditingController _patientIdController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _controlScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.initialPatientId != null) {
      _patientIdController.text = widget.initialPatientId!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(medicalRecordProvider.notifier)
            .setPatientId(widget.initialPatientId!);
      });
    }
  }

  @override
  void dispose() {
    _patientIdController.dispose();
    _scrollController.dispose();
    _controlScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 1200;

    return PdfViewerWidget(
      primaryColor: HospitalTheme.primary,
      appBarTitle: 'Medical Records',
      child: Scaffold(
        appBar: HospitalTheme.buildAppBar(
          context: context,
          title: 'Medical Record Summary',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _handleRefresh,
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _showHelpDialog,
              tooltip: 'Help',
            ),
          ],
        ),
        body: _buildBody(isWideScreen),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildBody(bool isWideScreen) {
    if (isWideScreen) {
      return Row(
        children: [
          // Left Panel - Controls
          Expanded(
            flex: 2,
            child: _buildControlPanel(),
          ),
          // Divider
          Container(
            width: 1,
            color: HospitalTheme.border,
          ),
          // Right Panel - Results
          Expanded(
            flex: 3,
            child: _buildResultsPanel(),
          ),
        ],
      );
    } else {
      return SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildControlPanel(),
            const Divider(height: 32),
            _buildResultsPanel(),
          ],
        ),
      );
    }
  }

  Widget _buildControlPanel() {
    return SingleChildScrollView(
      controller: _controlScrollController,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatientIdSection(),
            const SizedBox(height: 24),
            _buildReportTypeSelection(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 100), // Extra space at bottom for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildPatientIdSection() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('Patient Information'),
          TextFormField(
            controller: _patientIdController,
            decoration: const InputDecoration(
              labelText: 'Patient ID',
              hintText: 'Enter patient ID (e.g., SID427)',
              prefixIcon: Icon(Icons.person),
            ),
            onChanged: (value) {
              ref
                  .read(medicalRecordProvider.notifier)
                  .setPatientId(value.trim());
            },
            onFieldSubmitted: (_) => _handleGenerateReports(),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeSelection() {
    final state = ref.watch(medicalRecordProvider);

    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          HospitalTheme.buildSectionHeader(
            'Report Types',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: () => ref
                      .read(medicalRecordProvider.notifier)
                      .selectAllReports(),
                  icon: const Icon(Icons.select_all, size: 16),
                  label: const Text('Select All'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () =>
                      ref.read(medicalRecordProvider.notifier).clearSelection(),
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Make report types scrollable
          SizedBox(
            height: 400, // Fixed height for the scrollable area
            child: _buildReportTypeGrid(state.selectedReportTypes),
          ),
          const SizedBox(height: 16),
          _buildSelectionSummary(state.selectedReportTypes),
        ],
      ),
    );
  }

  Widget _buildReportTypeGrid(Set<String> selectedReports) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;

        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 3.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: ReportType.availableReports.length,
          itemBuilder: (context, index) {
            final reportType = ReportType.availableReports[index];
            final isSelected = selectedReports.contains(reportType.key);

            return _ReportTypeCard(
              reportType: reportType,
              isSelected: isSelected,
              onTap: () => ref
                  .read(medicalRecordProvider.notifier)
                  .toggleReportType(reportType.key),
            );
          },
        );
      },
    );
  }

  Widget _buildSelectionSummary(Set<String> selectedReports) {
    if (selectedReports.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: HospitalTheme.warning.withOpacity(0.1),
          borderRadius: HospitalTheme.radiusSmall,
          border: Border.all(color: HospitalTheme.warning),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: HospitalTheme.warning, size: 16),
            const SizedBox(width: 8),
            const Expanded(
                child: Text('Please select at least one report type')),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HospitalTheme.success.withOpacity(0.1),
        borderRadius: HospitalTheme.radiusSmall,
        border: Border.all(color: HospitalTheme.success),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline,
              color: HospitalTheme.success, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text('${selectedReports.length} report type(s) selected')),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final state = ref.watch(medicalRecordProvider);
    final canGenerate = state.selectedReportTypes.isNotEmpty &&
        state.currentPatientId?.isNotEmpty == true &&
        !state.isGenerating;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: canGenerate ? _handleGenerateReports : null,
            icon: state.isGenerating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: Text(state.isGenerating
                ? 'Generating Reports...'
                : 'Generate Reports'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 16),
          _buildErrorCard(state.error!),
        ],
      ],
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HospitalTheme.error.withOpacity(0.1),
        borderRadius: HospitalTheme.radiusSmall,
        border: Border.all(color: HospitalTheme.error),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: HospitalTheme.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(error, style: TextStyle(color: HospitalTheme.error))),
          IconButton(
            onPressed: () =>
                ref.read(medicalRecordProvider.notifier).clearError(),
            icon: Icon(Icons.close, color: HospitalTheme.error, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsPanel() {
    final state = ref.watch(medicalRecordProvider);

    if (state.response == null) {
      return _buildEmptyState();
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatientInfoCard(state.response!.patientInfo),
            const SizedBox(height: 24),
            _buildAdmissionInfoCard(state.response!.latestAdmission),
            const SizedBox(height: 24),
            _buildGeneratedReportsSection(state.response!.generatedPDFs),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: HospitalTheme.textLight,
            ),
            SizedBox(height: 24),
            Text(
              'No Reports Generated Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textMedium,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Select report types and generate medical records to view results here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: HospitalTheme.textLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfoCard(PatientInfo patient) {
    return HospitalTheme.buildPatientInfoCard(
      name: patient.name,
      patientId: patient.patientId,
      age: patient.age.toString(),
      gender: patient.gender,
      phoneNumber: patient.contact,
      imageUrl: patient.imageUrl,
    );
  }

  Widget _buildAdmissionInfoCard(AdmissionInfo admission) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('Latest Admission Details'),
          _buildAdmissionDetails(admission),
        ],
      ),
    );
  }

  Widget _buildAdmissionDetails(AdmissionInfo admission) {
    return Column(
      children: [
        _buildDetailRow('OPD Number', admission.opdNumber.toString()),
        _buildDetailRow('Doctor', 'Dr. ${admission.doctor}'),
        _buildDetailRow('Admission Date', _formatDate(admission.admissionDate)),
        if (admission.dischargeDate != null)
          _buildDetailRow(
              'Discharge Date', _formatDate(admission.dischargeDate!)),
        _buildDetailRow('Length of Stay', '${admission.lengthOfStay} days'),
        _buildDetailRow('Status', admission.status),
        _buildDetailRow(
            'Condition at Discharge', admission.conditionAtDischarge),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: HospitalTheme.textMedium)),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedReportsSection(List<GeneratedPdf> reports) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader(
            'Generated Reports (${reports.length})',
            trailing: reports.isNotEmpty
                ? TextButton.icon(
                    onPressed: _downloadAllReports,
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download All'),
                  )
                : null,
          ),
          if (reports.isEmpty)
            _buildNoReportsMessage()
          else
            ...reports.map((pdf) => _buildReportCard(pdf)).toList(),
        ],
      ),
    );
  }

  Widget _buildNoReportsMessage() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.folder_open, size: 48, color: HospitalTheme.textLight),
          SizedBox(height: 12),
          Text(
            'No reports were generated',
            style: TextStyle(color: HospitalTheme.textMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(GeneratedPdf pdf) {
    final reportType = ReportType.availableReports.firstWhere(
      (r) => r.key == pdf.reportType,
      orElse: () => const ReportType(
        key: 'unknown',
        displayName: 'Unknown Report',
        description: 'Unknown report type',
        icon: Icons.description,
        color: HospitalTheme.textMedium,
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: HospitalTheme.border),
        borderRadius: HospitalTheme.radiusSmall,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: reportType.color.withOpacity(0.1),
            borderRadius: HospitalTheme.radiusSmall,
          ),
          child: Icon(reportType.icon, color: reportType.color, size: 24),
        ),
        title: Text(
          pdf.reportName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(reportType.description),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 14, color: HospitalTheme.textLight),
                const SizedBox(width: 4),
                Text(
                  'Generated: ${_formatDateTime(pdf.generatedAt)}',
                  style: const TextStyle(
                      fontSize: 12, color: HospitalTheme.textLight),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _viewPdf(pdf),
              icon: const Icon(Icons.visibility),
              tooltip: 'View PDF',
            ),
            IconButton(
              onPressed: () => _downloadPdf(pdf),
              icon: const Icon(Icons.download),
              tooltip: 'Download PDF',
            ),
            IconButton(
              onPressed: () => _sharePdf(pdf),
              icon: const Icon(Icons.share),
              tooltip: 'Share PDF',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyG, control: true):
            _handleGenerateReports,
        const SingleActivator(LogicalKeyboardKey.keyR, control: true):
            _handleRefresh,
      },
      child: Focus(
        autofocus: true,
        child: HospitalTheme.buildFloatingActionButton(
          icon: Icons.picture_as_pdf,
          onPressed: _handleGenerateReports,
          tooltip: 'Generate Reports (Ctrl+G)',
        ),
      ),
    );
  }

  // ==================== EVENT HANDLERS ====================

  void _handleGenerateReports() {
    ref.read(medicalRecordProvider.notifier).generateReports();
  }

  void _handleRefresh() {
    ref.read(medicalRecordProvider.notifier).clearError();
    setState(() {
      // Trigger rebuild
    });
  }

  void _viewPdf(GeneratedPdf pdf) {
    ref.read(pdfViewerProvider.notifier).loadAndShowPdf(
          pdf.driveLink,
          title: pdf.reportName,
        );
  }

  void _downloadPdf(GeneratedPdf pdf) {
    Methods().openPdf(pdf.driveLink);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${pdf.reportName}...')),
    );
  }

  void _sharePdf(GeneratedPdf pdf) {
    Clipboard.setData(ClipboardData(text: pdf.driveLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF link copied to clipboard')),
    );
  }

  void _downloadAllReports() {
    final state = ref.read(medicalRecordProvider);
    if (state.response?.generatedPDFs.isNotEmpty == true) {
      for (final pdf in state.response!.generatedPDFs) {
        Methods().openPdf(pdf.driveLink);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Opening ${state.response!.generatedPDFs.length} reports...')),
      );
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help - Medical Record Summary'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Enter a valid Patient ID (e.g., SID427)'),
            SizedBox(height: 8),
            Text('2. Select one or more report types'),
            SizedBox(height: 8),
            Text('3. Click "Generate Reports" to create PDFs'),
            SizedBox(height: 8),
            Text('4. View, download, or share generated reports'),
            SizedBox(height: 16),
            Text('Keyboard Shortcuts:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Ctrl+G: Generate Reports'),
            Text('• Ctrl+R: Refresh'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  // ==================== UTILITY METHODS ====================

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// ==================== CUSTOM WIDGETS ====================

class _ReportTypeCard extends StatelessWidget {
  final ReportType reportType;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReportTypeCard({
    required this.reportType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? reportType.color.withOpacity(0.1) : Colors.white,
          borderRadius: HospitalTheme.radiusSmall,
          border: Border.all(
            color: isSelected ? reportType.color : HospitalTheme.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? HospitalTheme.shadowSmall : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: reportType.color.withOpacity(0.2),
                borderRadius: HospitalTheme.radiusSmall,
              ),
              child: Icon(
                reportType.icon,
                color: reportType.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    reportType.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? reportType.color
                          : HospitalTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reportType.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: HospitalTheme.textMedium,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: reportType.color,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
