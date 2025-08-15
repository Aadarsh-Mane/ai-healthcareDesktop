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
      patientId: json['patientId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      age: int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      gender: json['gender']?.toString() ?? '',
      contact: json['contact']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString().isEmpty == true
          ? null
          : json['imageUrl']?.toString(),
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
    try {
      return AdmissionInfo(
        opdNumber: int.tryParse(json['opdNumber']?.toString() ?? '0') ?? 0,
        admissionDate:
            DateTime.tryParse(json['admissionDate']?.toString() ?? '') ??
                DateTime.now(),
        dischargeDate: json['dischargeDate'] != null &&
                json['dischargeDate'].toString().isNotEmpty
            ? DateTime.tryParse(json['dischargeDate'].toString())
            : null,
        doctor: json['doctor']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        conditionAtDischarge: json['conditionAtDischarge']?.toString() ?? '',
        lengthOfStay:
            int.tryParse(json['lengthOfStay']?.toString() ?? '0') ?? 0,
        summaryStats: Map<String, int>.from(
          (json['summaryStats'] as Map<String, dynamic>?)?.map(
                (key, value) =>
                    MapEntry(key, int.tryParse(value?.toString() ?? '0') ?? 0),
              ) ??
              {},
        ),
      );
    } catch (e) {
      return AdmissionInfo(
        opdNumber: 0,
        admissionDate: DateTime.now(),
        dischargeDate: null,
        doctor: '',
        status: '',
        conditionAtDischarge: '',
        lengthOfStay: 0,
        summaryStats: {},
      );
    }
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
      reportType: json['reportType']?.toString() ?? '',
      reportName: json['reportName']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? '',
      driveLink: json['driveLink']?.toString() ?? '',
      generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? '') ??
          DateTime.now(),
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
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      patientInfo: PatientInfo.fromJson(
          json['patientInfo'] as Map<String, dynamic>? ?? {}),
      latestAdmission: AdmissionInfo.fromJson(
          json['latestAdmission'] as Map<String, dynamic>? ?? {}),
      totalAdmissions:
          int.tryParse(json['totalAdmissions']?.toString() ?? '0') ?? 0,
      generatedPDFs: (json['generatedPDFs'] as List<dynamic>?)
              ?.map((pdf) => GeneratedPdf.fromJson(pdf as Map<String, dynamic>))
              .toList() ??
          [],
      totalGenerated:
          int.tryParse(json['totalGenerated']?.toString() ?? '0') ?? 0,
      totalRequested:
          int.tryParse(json['totalRequested']?.toString() ?? '0') ?? 0,
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
    ReportType(
      key: 'surgical',
      displayName: 'Surgical Notes Report',
      description: 'Surgical procedures and operative notes',
      icon: Icons.healing,
      color: HospitalTheme.secondary,
    ),
    ReportType(
      key: 'followUp2Hr',
      displayName: '2-Hour Follow-up',
      description: 'Follow-up assessment after 2 hours',
      icon: Icons.access_time,
      color: Color(0xFF8E24AA),
    ),
    ReportType(
      key: 'followUp4Hr',
      displayName: '4-Hour Follow-up',
      description: 'Follow-up assessment after 4 hours',
      icon: Icons.schedule,
      color: Color(0xFFE65100),
    ),
    ReportType(
      key: 'followUpCombined',
      displayName: 'Combined Follow-up',
      description: 'Comprehensive combined follow-up report',
      icon: Icons.timeline,
      color: Color(0xFF6A1B9A),
    ),
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

  void clearResponse() {
    state = state.copyWith(response: null);
  }

  Future<void> generateReports() async {
    if (state.selectedReportTypes.isEmpty ||
        state.currentPatientId?.isEmpty == true) {
      state = state.copyWith(
          error:
              'Please select at least one report type and enter a valid patient ID');
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
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        final medicalResponse = MedicalRecordResponse.fromJson(responseData);

        state = state.copyWith(
          isGenerating: false,
          response: medicalResponse,
          error: medicalResponse.success ? null : medicalResponse.message,
        );
      } else {
        final errorMessage = response.statusCode == 404
            ? 'Patient not found. Please check the Patient ID.'
            : response.statusCode == 500
                ? 'Server error. Please try again later.'
                : 'Failed to generate reports. Please check your connection.';

        state = state.copyWith(
          isGenerating: false,
          error: errorMessage,
        );
      }
    } catch (e) {
      String errorMessage =
          'Network error. Please check your internet connection.';

      if (e.toString().contains('SocketException')) {
        errorMessage =
            'Unable to connect to server. Please check your network.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timed out. Please try again.';
      }

      state = state.copyWith(
        isGenerating: false,
        error: errorMessage,
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
    extends ConsumerState<MedicalRecordSummaryScreen>
    with TickerProviderStateMixin {
  final TextEditingController _patientIdController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _controlScrollController = ScrollController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();

    if (widget.initialPatientId?.isNotEmpty == true) {
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
    _animationController.dispose();
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
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () {
            Navigator.of(context).pop();
          },
          const SingleActivator(LogicalKeyboardKey.keyG, control: true):
              _handleGenerateReports,
          const SingleActivator(LogicalKeyboardKey.keyR, control: true):
              _handleRefresh,
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: const Color(0xFFF0F4F8),
            appBar: _buildAppBar(),
            body: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildBody(isWideScreen),
              ),
            ),
            floatingActionButton: _buildFloatingActionButton(),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
      ),
      title: const Text(
        'Medical Record Summary',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      actions: [
        Tooltip(
          message: 'Refresh (Ctrl+R)',
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              HapticFeedback.lightImpact();
              _handleRefresh();
            },
          ),
        ),
        Tooltip(
          message: 'Help',
          child: IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showHelpDialog();
            },
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildBody(bool isWideScreen) {
    if (isWideScreen) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildControlPanel(),
          ),
          Container(
            width: 1,
            color: HospitalTheme.border,
          ),
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
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientIdSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [HospitalTheme.surfaceLight, HospitalTheme.cardBackground],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: HospitalTheme.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.folder_special_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medical Records',
                      style: TextStyle(
                        fontSize: 26,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Generate comprehensive patient reports',
                      style: TextStyle(
                        fontSize: 14,
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _patientIdController,
            decoration: const InputDecoration(
              labelText: 'Patient ID',
              hintText: 'Enter patient ID (e.g., SID427)',
              prefixIcon: Icon(Icons.person),
              floatingLabelStyle: TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.w600,
              ),
            ),
            cursorColor: Colors.teal,
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
          SizedBox(
            height: 500,
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
              backgroundColor: HospitalTheme.primary,
              foregroundColor: Colors.white,
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
            _buildGeneratedReportsSuccessCard(state.response!),
            const SizedBox(height: 24),
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

  Widget _buildGeneratedReportsSuccessCard(MedicalRecordResponse response) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [HospitalTheme.success, Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: HospitalTheme.success.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reports Generated Successfully!',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${response.generatedPDFs.length} reports generated for ${response.patientInfo.name}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: response.generatedPDFs.isNotEmpty
                      ? () => _downloadAllReports()
                      : null,
                  icon:
                      const Icon(Icons.download, color: HospitalTheme.success),
                  label: const Text(
                    'Open All Reports',
                    style: TextStyle(
                      color: HospitalTheme.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _generateNewReports(),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'Generate New',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfoCard(PatientInfo patient) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HospitalTheme.primary.withOpacity(0.05),
            HospitalTheme.primary.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HospitalTheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      HospitalTheme.primary,
                      HospitalTheme.primary.withOpacity(0.7)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Patient Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
              'Name', patient.name, Icons.person, HospitalTheme.primary),
          _buildDetailRow(
              'Patient ID', patient.patientId, Icons.badge, HospitalTheme.info),
          _buildDetailRow(
              'Age', '${patient.age} years', Icons.cake, HospitalTheme.warning),
          _buildDetailRow(
              'Gender', patient.gender, Icons.wc, HospitalTheme.secondary),
          _buildDetailRow(
              'Contact', patient.contact, Icons.phone, HospitalTheme.medical),
          _buildDetailRow('Address', patient.address, Icons.location_on,
              HospitalTheme.pharmacy),
        ],
      ),
    );
  }

  Widget _buildAdmissionInfoCard(AdmissionInfo admission) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HospitalTheme.info.withOpacity(0.05),
            HospitalTheme.info.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HospitalTheme.info.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      HospitalTheme.info,
                      HospitalTheme.info.withOpacity(0.7)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Latest Admission Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow('OPD Number', admission.opdNumber.toString(),
              Icons.confirmation_number, HospitalTheme.secondary),
          _buildDetailRow('Doctor', 'Dr. ${admission.doctor}', Icons.person_pin,
              HospitalTheme.medical),
          _buildDetailRow(
              'Admission Date',
              _formatDate(admission.admissionDate),
              Icons.date_range,
              HospitalTheme.success),
          if (admission.dischargeDate != null)
            _buildDetailRow(
                'Discharge Date',
                _formatDate(admission.dischargeDate!),
                Icons.event_available,
                HospitalTheme.info),
          _buildDetailRow('Length of Stay', '${admission.lengthOfStay} days',
              Icons.schedule, HospitalTheme.warning),
          _buildDetailRow(
              'Status', admission.status, Icons.info, HospitalTheme.primary),
          _buildDetailRow(
              'Condition at Discharge',
              admission.conditionAtDischarge,
              Icons.health_and_safety,
              HospitalTheme.emergency),
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
                    label: const Text('Open All'),
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
        gradient: LinearGradient(
          colors: [
            reportType.color.withOpacity(0.05),
            reportType.color.withOpacity(0.02),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: reportType.color.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [reportType.color, reportType.color.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(reportType.icon, color: Colors.white, size: 24),
        ),
        title: Text(
          pdf.reportName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: reportType.color,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(reportType.description),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 14, color: reportType.color.withOpacity(0.7)),
                const SizedBox(width: 4),
                Text(
                  'Generated: ${_formatDateTime(pdf.generatedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: reportType.color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'View PDF',
              child: IconButton(
                onPressed: () => _viewPdf(pdf),
                icon: Icon(Icons.visibility, color: reportType.color),
              ),
            ),
            Tooltip(
              message: 'Download PDF',
              child: IconButton(
                onPressed: () => _downloadPdf(pdf),
                icon: Icon(Icons.download, color: reportType.color),
              ),
            ),
            Tooltip(
              message: 'Share PDF',
              child: IconButton(
                onPressed: () => _sharePdf(pdf),
                icon: Icon(Icons.share, color: reportType.color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.05),
            color.withOpacity(0.02),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: HospitalTheme.textMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return HospitalTheme.buildFloatingActionButton(
      icon: Icons.picture_as_pdf,
      onPressed: _handleGenerateReports,
      tooltip: 'Generate Reports (Ctrl+G)',
    );
  }

  // ==================== EVENT HANDLERS ====================

  void _handleGenerateReports() {
    ref.read(medicalRecordProvider.notifier).generateReports();
  }

  void _handleRefresh() {
    ref.read(medicalRecordProvider.notifier).clearError();
    ref.read(medicalRecordProvider.notifier).clearResponse();
    setState(() {
      // Trigger rebuild
    });
  }

  void _generateNewReports() {
    ref.read(medicalRecordProvider.notifier).clearResponse();
    ref.read(medicalRecordProvider.notifier).clearSelection();
  }

  void _viewPdf(GeneratedPdf pdf) async {
    if (pdf.driveLink.isEmpty) {
      _showMessage('PDF link is not available', isError: true);
      return;
    }

    try {
      // Use the PdfViewerProvider to load and show PDF
      await ref.read(pdfViewerProvider.notifier).loadAndShowPdf(
            pdf.driveLink,
            title: pdf.reportName,
          );

      // Check if there was an error loading the PDF
      final pdfState = ref.read(pdfViewerProvider);
      if (pdfState.error != null) {
        _showMessage('Failed to load PDF: ${pdfState.error}', isError: true);
      }
    } catch (e) {
      _showMessage('Unable to open PDF viewer: ${e.toString()}', isError: true);
    }
  }

  void _downloadPdf(GeneratedPdf pdf) {
    if (pdf.driveLink.isEmpty) {
      _showMessage('PDF link is not available', isError: true);
      return;
    }

    try {
      Methods().openPdf(pdf.driveLink);
      _showMessage('Opening ${pdf.reportName}...');
    } catch (e) {
      _showMessage('Failed to open PDF: ${e.toString()}', isError: true);
    }
  }

  void _sharePdf(GeneratedPdf pdf) {
    if (pdf.driveLink.isEmpty) {
      _showMessage('PDF link is not available', isError: true);
      return;
    }

    try {
      Clipboard.setData(ClipboardData(text: pdf.driveLink));
      _showMessage('PDF link copied to clipboard');
    } catch (e) {
      _showMessage('Failed to copy link to clipboard', isError: true);
    }
  }

  void _downloadAllReports() {
    final state = ref.read(medicalRecordProvider);
    if (state.response?.generatedPDFs.isEmpty != false) {
      _showMessage('No reports available to open', isError: true);
      return;
    }

    try {
      int openedCount = 0;
      for (final pdf in state.response!.generatedPDFs) {
        if (pdf.driveLink.isNotEmpty) {
          Methods().openPdf(pdf.driveLink);
          openedCount++;
        }
      }

      if (openedCount > 0) {
        _showMessage('Opening $openedCount report(s)...');
      } else {
        _showMessage('No valid PDF links found', isError: true);
      }
    } catch (e) {
      _showMessage('Failed to open reports: ${e.toString()}', isError: true);
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: HospitalTheme.radiusLarge,
        ),
        title: const Text('Help - Medical Record Summary'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How to Generate Medical Reports:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('1. Enter a valid Patient ID (e.g., SID427)'),
              Text('2. Select one or more report types from the grid'),
              Text('3. Click "Generate Reports" to create PDFs'),
              Text('4. View, download, or share generated reports'),
              SizedBox(height: 16),
              Text('Available Report Types:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Diagnosis: Medical findings and diagnoses'),
              Text('• Symptoms: Patient complaints and symptoms'),
              Text('• Consulting: Doctor consultation notes'),
              Text('• Prescriptions: Prescribed medications'),
              Text('• Vitals: Patient vital signs and measurements'),
              Text('• Surgical: Surgical procedures and notes'),
              Text('• Follow-up: Post-treatment assessments'),
              SizedBox(height: 16),
              Text('Keyboard Shortcuts:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Ctrl+G: Generate Reports'),
              Text('• Ctrl+R: Refresh Screen'),
              Text('• ESC: Close Screen'),
              SizedBox(height: 16),
              Text('Tips:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Use "Select All" to choose all report types'),
              Text('• Generated reports open in the PDF viewer'),
              Text('• Reports are automatically saved to Google Drive'),
            ],
          ),
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

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? HospitalTheme.error : HospitalTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: HospitalTheme.radiusSmall,
        ),
        duration: Duration(seconds: isError ? 4 : 2),
        action: isError
            ? SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () =>
                    ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              )
            : null,
      ),
    );
  }

  // ==================== UTILITY METHODS ====================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
