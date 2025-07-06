import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/core/utils/PdfViewerScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==================== DATA MODELS ====================

class PatientDetails {
  final String name;
  final String patientId;
  final int age;
  final String gender;

  const PatientDetails({
    required this.name,
    required this.patientId,
    required this.age,
    required this.gender,
  });

  factory PatientDetails.fromJson(Map<String, dynamic> json) {
    return PatientDetails(
      name: json['name'] ?? '',
      patientId: json['patientId'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
    );
  }
}

class CertificateDetails {
  final String diagnosis;
  final String medicalLeaveStartDate;
  final String expectedRestDuration;
  final String expectedReturnDate;
  final String issueDate;
  final String doctorName;
  final String doctorSpeciality;
  final String doctorDepartment;

  const CertificateDetails({
    required this.diagnosis,
    required this.medicalLeaveStartDate,
    required this.expectedRestDuration,
    required this.expectedReturnDate,
    required this.issueDate,
    required this.doctorName,
    required this.doctorSpeciality,
    required this.doctorDepartment,
  });

  factory CertificateDetails.fromJson(Map<String, dynamic> json) {
    return CertificateDetails(
      diagnosis: json['diagnosis'] ?? '',
      medicalLeaveStartDate: json['medicalLeaveStartDate'] ?? '',
      expectedRestDuration: json['expectedRestDuration'] ?? '',
      expectedReturnDate: json['expectedReturnDate'] ?? '',
      issueDate: json['issueDate'] ?? '',
      doctorName: json['doctorName'] ?? '',
      doctorSpeciality: json['doctorSpeciality'] ?? '',
      doctorDepartment: json['doctorDepartment'] ?? '',
    );
  }
}

class AdmissionInfo {
  final int opdNumber;
  final DateTime admissionDate;

  const AdmissionInfo({
    required this.opdNumber,
    required this.admissionDate,
  });

  factory AdmissionInfo.fromJson(Map<String, dynamic> json) {
    return AdmissionInfo(
      opdNumber: json['opdNumber'] ?? 0,
      admissionDate: DateTime.parse(json['admissionDate']),
    );
  }
}

class MedicalCertificateResponse {
  final bool success;
  final String message;
  final String certificateUrl;
  final String filename;
  final PatientDetails patientDetails;
  final CertificateDetails certificateDetails;
  final AdmissionInfo admissionInfo;

  const MedicalCertificateResponse({
    required this.success,
    required this.message,
    required this.certificateUrl,
    required this.filename,
    required this.patientDetails,
    required this.certificateDetails,
    required this.admissionInfo,
  });

  factory MedicalCertificateResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return MedicalCertificateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      certificateUrl: data['certificateUrl'] ?? '',
      filename: data['filename'] ?? '',
      patientDetails: PatientDetails.fromJson(data['patientDetails'] ?? {}),
      certificateDetails:
          CertificateDetails.fromJson(data['certificateDetails'] ?? {}),
      admissionInfo: AdmissionInfo.fromJson(data['admissionInfo'] ?? {}),
    );
  }
}

// ==================== CERTIFICATE TYPE DEFINITIONS ====================

class CertificateType {
  final String key;
  final String displayName;
  // final String description;
  final IconData icon;
  final Color color;
  final bool isCustom;

  const CertificateType({
    required this.key,
    required this.displayName,
    // required this.description,
    required this.icon,
    required this.color,
    this.isCustom = false,
  });

  static const List<CertificateType> availableTypes = [
    CertificateType(
      key: 'illness',
      displayName: 'Illness Certificate',
      // description: 'For medical leave due to illness or injury',
      icon: Icons.sick,
      color: HospitalTheme.error,
    ),
    CertificateType(
      key: 'fitness',
      displayName: 'Fitness Certificate',
      // description: 'Certifying physical fitness for activities',
      icon: Icons.fitness_center,
      color: HospitalTheme.success,
    ),
    CertificateType(
      key: 'disability',
      displayName: 'Disability Certificate',
      // description: 'For temporary or permanent disability',
      icon: Icons.accessible,
      color: HospitalTheme.warning,
    ),
    CertificateType(
      key: 'vaccination',
      displayName: 'Vaccination Certificate',
      // description: 'Proof of vaccination or immunization',
      icon: Icons.vaccines,
      color: HospitalTheme.medical,
    ),
  ];
}

// ==================== STATE MANAGEMENT ====================

class MedicalCertificateState {
  final bool isGenerating;
  final String? error;
  final MedicalCertificateResponse? response;
  final String diagnosis;
  final DateTime? medicalLeaveStartDate;
  final String expectedRestDuration;
  final DateTime? expectedReturnDate;
  final String doctorSignatureUrl;
  final String additionalNotes;
  final String certificateType;
  final List<CertificateType> customTypes;
  final bool isCustomTypeMode;
  final String customTypeName;
  final String customTypeDescription;

  const MedicalCertificateState({
    this.isGenerating = false,
    this.error,
    this.response,
    this.diagnosis = '',
    this.medicalLeaveStartDate,
    this.expectedRestDuration = '',
    this.expectedReturnDate,
    this.doctorSignatureUrl = '',
    this.additionalNotes = '',
    this.certificateType = 'illness',
    this.customTypes = const [],
    this.isCustomTypeMode = false,
    this.customTypeName = '',
    this.customTypeDescription = '',
  });

  MedicalCertificateState copyWith({
    bool? isGenerating,
    String? error,
    MedicalCertificateResponse? response,
    String? diagnosis,
    DateTime? medicalLeaveStartDate,
    String? expectedRestDuration,
    DateTime? expectedReturnDate,
    String? doctorSignatureUrl,
    String? additionalNotes,
    String? certificateType,
    List<CertificateType>? customTypes,
    bool? isCustomTypeMode,
    String? customTypeName,
    String? customTypeDescription,
  }) {
    return MedicalCertificateState(
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
      response: response ?? this.response,
      diagnosis: diagnosis ?? this.diagnosis,
      medicalLeaveStartDate:
          medicalLeaveStartDate ?? this.medicalLeaveStartDate,
      expectedRestDuration: expectedRestDuration ?? this.expectedRestDuration,
      expectedReturnDate: expectedReturnDate ?? this.expectedReturnDate,
      doctorSignatureUrl: doctorSignatureUrl ?? this.doctorSignatureUrl,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      certificateType: certificateType ?? this.certificateType,
      customTypes: customTypes ?? this.customTypes,
      isCustomTypeMode: isCustomTypeMode ?? this.isCustomTypeMode,
      customTypeName: customTypeName ?? this.customTypeName,
      customTypeDescription:
          customTypeDescription ?? this.customTypeDescription,
    );
  }

  List<CertificateType> get allCertificateTypes {
    return [...CertificateType.availableTypes, ...customTypes];
  }
}

class MedicalCertificateNotifier
    extends StateNotifier<MedicalCertificateState> {
  MedicalCertificateNotifier() : super(const MedicalCertificateState());

  void updateDiagnosis(String diagnosis) {
    state = state.copyWith(diagnosis: diagnosis);
  }

  void updateMedicalLeaveStartDate(DateTime? date) {
    state = state.copyWith(medicalLeaveStartDate: date);
  }

  void updateExpectedRestDuration(String duration) {
    state = state.copyWith(expectedRestDuration: duration);
  }

  void updateExpectedReturnDate(DateTime? date) {
    state = state.copyWith(expectedReturnDate: date);
  }

  void updateDoctorSignatureUrl(String url) {
    state = state.copyWith(doctorSignatureUrl: url);
  }

  void updateAdditionalNotes(String notes) {
    state = state.copyWith(additionalNotes: notes);
  }

  void updateCertificateType(String type) {
    state = state.copyWith(certificateType: type);
  }

  void toggleCustomTypeMode(bool isCustom) {
    state = state.copyWith(
      isCustomTypeMode: isCustom,
      customTypeName: '',
      customTypeDescription: '',
    );
  }

  void updateCustomTypeName(String name) {
    state = state.copyWith(customTypeName: name);
  }

  void updateCustomTypeDescription(String description) {
    state = state.copyWith(customTypeDescription: description);
  }

  void addCustomType() {
    if (state.customTypeName.isNotEmpty &&
        state.customTypeDescription.isNotEmpty) {
      final customType = CertificateType(
        key:
            'custom_${state.customTypeName.toLowerCase().replaceAll(' ', '_')}',
        displayName: state.customTypeName,
        // description: state.customTypeDescription,
        icon: Icons.description,
        color: HospitalTheme.pharmacy,
        isCustom: true,
      );

      final updatedCustomTypes = [...state.customTypes, customType];
      state = state.copyWith(
        customTypes: updatedCustomTypes,
        certificateType: customType.key,
        isCustomTypeMode: false,
        customTypeName: '',
        customTypeDescription: '',
      );
    }
  }

  void removeCustomType(String typeKey) {
    final updatedCustomTypes =
        state.customTypes.where((type) => type.key != typeKey).toList();

    String newCertificateType = state.certificateType;
    if (state.certificateType == typeKey) {
      newCertificateType =
          'illness'; // Default to illness if current type is removed
    }

    state = state.copyWith(
      customTypes: updatedCustomTypes,
      certificateType: newCertificateType,
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearResponse() {
    state = state.copyWith(response: null);
  }

  Future<void> generateCertificate(
      String patientId, String admissionId, String token) async {
    if (state.diagnosis.isEmpty ||
        state.medicalLeaveStartDate == null ||
        state.expectedReturnDate == null) {
      state = state.copyWith(error: 'Please fill in all required fields');
      return;
    }

    try {
      state = state.copyWith(isGenerating: true, error: null);

      final requestBody = {
        'patientId': patientId,
        'admissionId': admissionId,
        'diagnosis': state.diagnosis,
        'medicalLeaveStartDate': _formatDate(state.medicalLeaveStartDate!),
        'expectedRestDuration': state.expectedRestDuration,
        'expectedReturnDate': _formatDate(state.expectedReturnDate!),
        'doctorSignatureUrl': state.doctorSignatureUrl,
        'additionalNotes': state.additionalNotes,
        'certificateType': state.certificateType,
      };

      final response = await http.post(
        Uri.parse('${KVM_URL}/doctors/generateMedicalCertificate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final certificateResponse =
            MedicalCertificateResponse.fromJson(responseData);

        state = state.copyWith(
          isGenerating: false,
          response: certificateResponse,
          error:
              certificateResponse.success ? null : certificateResponse.message,
        );
      } else {
        state = state.copyWith(
          isGenerating: false,
          error:
              'Failed to generate certificate. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: 'Error generating certificate: ${e.toString()}',
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

final medicalCertificateProvider =
    StateNotifierProvider<MedicalCertificateNotifier, MedicalCertificateState>(
        (ref) {
  return MedicalCertificateNotifier();
});

// ==================== MAIN SCREEN ====================

class GenerateMedicalCertificateScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String admissionId;

  const GenerateMedicalCertificateScreen({
    super.key,
    required this.patientId,
    required this.admissionId,
  });

  @override
  ConsumerState<GenerateMedicalCertificateScreen> createState() =>
      _GenerateMedicalCertificateScreenState();
}

class _GenerateMedicalCertificateScreenState
    extends ConsumerState<GenerateMedicalCertificateScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _restDurationController = TextEditingController();
  final _notesController = TextEditingController();
  final _customTypeNameController = TextEditingController();
  final _customTypeDescriptionController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  final ScrollController _controlScrollController = ScrollController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  SharedPreferences? _prefs;
  String get _authToken => _prefs?.getString('auth_token') ?? '';

  @override
  void initState() {
    super.initState();
    _initializePrefs();

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

    // Set default values
    _restDurationController.text = '1 week';
  }

  Future<void> _initializePrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _diagnosisController.dispose();
    _restDurationController.dispose();
    _notesController.dispose();
    _customTypeNameController.dispose();
    _customTypeDescriptionController.dispose();
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
      appBarTitle: 'Medical Certificate',
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () {
            Navigator.of(context).pop();
          },
          const SingleActivator(LogicalKeyboardKey.keyG, control: true): () {
            _handleGenerateCertificate();
          },
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
        'Medical Certificate Generator',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      actions: [
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
          // Left Panel - Form
          Expanded(
            flex: 2,
            child: _buildFormPanel(),
          ),
          // Divider
          Container(
            width: 1,
            color: HospitalTheme.border,
          ),
          // Right Panel - Preview/Results
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
            _buildFormPanel(),
            const Divider(height: 32),
            _buildResultsPanel(),
          ],
        ),
      );
    }
  }

  Widget _buildFormPanel() {
    return SingleChildScrollView(
      controller: _controlScrollController,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPatientInfoCard(),
              const SizedBox(height: 24),
              _buildCertificateTypeSelection(),
              const SizedBox(height: 24),
              _buildMedicalDetailsForm(),
              const SizedBox(height: 24),
              _buildAdditionalDetailsForm(),
              const SizedBox(height: 24),
              _buildActionButtons(),
              const SizedBox(height: 100), // Extra space for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            HospitalTheme.surfaceLight,
            HospitalTheme.cardBackground,
          ],
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
                    colors: [Color(0xFFFFE082), Color(0xFFFFB74D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.medical_information_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Medical Certificate',
                      style: TextStyle(
                        fontSize: 26,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Patient ID: ${widget.patientId}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.confirmation_number_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admission ID',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        widget.admissionId,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateTypeSelection() {
    final state = ref.watch(medicalCertificateProvider);

    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: HospitalTheme.buildSectionHeader('Certificate Type'),
              ),
              TextButton.icon(
                onPressed: () {
                  ref
                      .read(medicalCertificateProvider.notifier)
                      .toggleCustomTypeMode(!state.isCustomTypeMode);
                },
                icon: Icon(
                  state.isCustomTypeMode ? Icons.list : Icons.add,
                  size: 16,
                ),
                label: Text(
                  state.isCustomTypeMode ? 'Back to List' : 'Add Custom',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.isCustomTypeMode) ...[
            _buildCustomTypeForm(),
          ] else ...[
            // Scrollable container with constrained height
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 280, // Maximum height before scrolling
                minHeight: 120, // Minimum height to show at least one row
              ),
              child: _buildCertificateTypesGrid(state),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomTypeForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HospitalTheme.pharmacy.withOpacity(0.05),
            HospitalTheme.pharmacy.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: HospitalTheme.radiusSmall,
        border: Border.all(color: HospitalTheme.pharmacy.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: HospitalTheme.pharmacy,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add_circle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Create Custom Certificate Type',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _customTypeNameController,
            decoration: const InputDecoration(
              labelText: 'Certificate Name *',
              hintText: 'e.g., Mental Health Certificate',
              prefixIcon: Icon(Icons.title),
            ),
            onChanged: (value) => ref
                .read(medicalCertificateProvider.notifier)
                .updateCustomTypeName(value),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _customTypeDescriptionController,
            decoration: const InputDecoration(
              labelText: 'Description *',
              hintText: 'Brief description of this certificate type',
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 2,
            onChanged: (value) => ref
                .read(medicalCertificateProvider.notifier)
                .updateCustomTypeDescription(value),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_customTypeNameController.text.isNotEmpty &&
                    _customTypeDescriptionController.text.isNotEmpty) {
                  ref.read(medicalCertificateProvider.notifier).addCustomType();
                  _customTypeNameController.clear();
                  _customTypeDescriptionController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Custom certificate type added successfully!'),
                      backgroundColor: HospitalTheme.success,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Custom Type'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HospitalTheme.pharmacy,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateTypesGrid(MedicalCertificateState state) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Default certificate types
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
              childAspectRatio: 3.0, // Increased for more horizontal space
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: CertificateType.availableTypes.length,
            itemBuilder: (context, index) {
              final certType = CertificateType.availableTypes[index];
              final isSelected = state.certificateType == certType.key;

              return _CertificateTypeCard(
                certificateType: certType,
                isSelected: isSelected,
                onTap: () => ref
                    .read(medicalCertificateProvider.notifier)
                    .updateCertificateType(certType.key),
              );
            },
          ),

          // Custom certificate types
          if (state.customTypes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: HospitalTheme.pharmacy.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    color: HospitalTheme.pharmacy,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Custom Certificate Types',
                    style: TextStyle(
                      color: HospitalTheme.pharmacy,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                childAspectRatio: 4.0, // Same aspect ratio for consistency
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: state.customTypes.length,
              itemBuilder: (context, index) {
                final certType = state.customTypes[index];
                final isSelected = state.certificateType == certType.key;

                return _CertificateTypeCard(
                  certificateType: certType,
                  isSelected: isSelected,
                  onTap: () => ref
                      .read(medicalCertificateProvider.notifier)
                      .updateCertificateType(certType.key),
                  onDelete: certType.isCustom
                      ? () => ref
                          .read(medicalCertificateProvider.notifier)
                          .removeCustomType(certType.key)
                      : null,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicalDetailsForm() {
    final state = ref.watch(medicalCertificateProvider);

    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('Medical Details'),
          const SizedBox(height: 16),

          // Diagnosis
          TextFormField(
            cursorColor: Colors.teal, // 👈 Change this to your desired color

            controller: _diagnosisController,
            decoration: const InputDecoration(
              labelText: 'Diagnosis *',
              hintText: 'Enter patient diagnosis',
              prefixIcon: Icon(Icons.medical_services),
              floatingLabelStyle: TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.w600,
              ),
            ),

            maxLines: 2,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Diagnosis is required' : null,
            onChanged: (value) => ref
                .read(medicalCertificateProvider.notifier)
                .updateDiagnosis(value),
          ),
          const SizedBox(height: 16),

          // Medical Leave Start Date
          _buildDateField(
            label: 'Medical Leave Start Date *',
            hint: 'Select start date',
            icon: Icons.date_range,
            value: state.medicalLeaveStartDate,
            onChanged: (date) => ref
                .read(medicalCertificateProvider.notifier)
                .updateMedicalLeaveStartDate(date),
          ),
          const SizedBox(height: 16),

          // Expected Rest Duration
          TextFormField(
            cursorColor: Colors.teal, // 👈 Change this to your desired color
            controller: _restDurationController,
            decoration: const InputDecoration(
              floatingLabelStyle: TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.w600,
              ),
              labelText: 'Expected Rest Duration *',
              hintText: 'e.g., 1 week, 2 months',
              prefixIcon: Icon(Icons.schedule),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Rest duration is required' : null,
            onChanged: (value) => ref
                .read(medicalCertificateProvider.notifier)
                .updateExpectedRestDuration(value),
          ),
          const SizedBox(height: 16),

          // Expected Return Date
          _buildDateField(
            label: 'Expected Return Date *',
            hint: 'Select return date',
            icon: Icons.event_available,
            value: state.expectedReturnDate,
            onChanged: (date) => ref
                .read(medicalCertificateProvider.notifier)
                .updateExpectedReturnDate(date),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalDetailsForm() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('Additional Details'),
          const SizedBox(height: 16),

          // Additional Notes
          TextFormField(
            cursorColor: Colors.teal, // 👈 Change this to your desired color
            controller: _notesController,
            decoration: const InputDecoration(
              floatingLabelStyle: TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.w600,
              ),
              labelText: 'Additional Notes',
              hintText: 'Any additional medical instructions or notes',
              prefixIcon: Icon(Icons.note_add),
            ),
            maxLines: 3,
            onChanged: (value) => ref
                .read(medicalCertificateProvider.notifier)
                .updateAdditionalNotes(value),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String hint,
    required IconData icon,
    required DateTime? value,
    required Function(DateTime?) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          value != null ? _formatDisplayDate(value) : hint,
          style: TextStyle(
            color: value != null
                ? HospitalTheme.textDark
                : HospitalTheme.textLight,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final state = ref.watch(medicalCertificateProvider);
    final canGenerate = state.diagnosis.isNotEmpty &&
        state.medicalLeaveStartDate != null &&
        state.expectedReturnDate != null &&
        !state.isGenerating;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: canGenerate ? _handleGenerateCertificate : null,
            icon: state.isGenerating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.medical_information),
            label: Text(state.isGenerating
                ? 'Generating Certificate...'
                : 'Generate Medical Certificate'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: HospitalTheme.primary,
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
                ref.read(medicalCertificateProvider.notifier).clearError(),
            icon: Icon(Icons.close, color: HospitalTheme.error, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsPanel() {
    final state = ref.watch(medicalCertificateProvider);

    if (state.response == null) {
      return _buildEmptyState();
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGeneratedCertificateCard(state.response!),
            const SizedBox(height: 24),
            _buildPatientDetailsCard(state.response!.patientDetails),
            const SizedBox(height: 24),
            _buildCertificateDetailsCard(state.response!.certificateDetails),
            const SizedBox(height: 24),
            _buildAdmissionInfoCard(state.response!.admissionInfo),
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
              Icons.medical_information_outlined,
              size: 80,
              color: HospitalTheme.textLight,
            ),
            SizedBox(height: 24),
            Text(
              'No Certificate Generated Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textMedium,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Fill in the medical details and generate a certificate to view results here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: HospitalTheme.textLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratedCertificateCard(MedicalCertificateResponse response) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            HospitalTheme.success,
            Color(0xFF4CAF50),
          ],
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
                      'Certificate Generated Successfully!',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      response.filename,
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
                  onPressed: () => _viewCertificate(response),
                  icon: const Icon(Icons.visibility,
                      color: HospitalTheme.success),
                  label: const Text(
                    'View Certificate',
                    style: TextStyle(
                        color: HospitalTheme.success,
                        fontWeight: FontWeight.bold),
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
                  onPressed: () => _downloadCertificate(response),
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: const Text(
                    'Open',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget _buildPatientDetailsCard(PatientDetails patient) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('Patient Details'),
          _buildDetailRow(
              'Name', patient.name, Icons.person, HospitalTheme.primary),
          _buildDetailRow(
              'Patient ID', patient.patientId, Icons.badge, HospitalTheme.info),
          _buildDetailRow(
              'Age', '${patient.age} years', Icons.cake, HospitalTheme.warning),
          _buildDetailRow(
              'Gender', patient.gender, Icons.wc, HospitalTheme.secondary),
        ],
      ),
    );
  }

  Widget _buildCertificateDetailsCard(CertificateDetails certificate) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('Certificate Details'),
          _buildDetailRow('Diagnosis', certificate.diagnosis,
              Icons.medical_services, HospitalTheme.error),
          _buildDetailRow('Leave Start Date', certificate.medicalLeaveStartDate,
              Icons.date_range, HospitalTheme.success),
          _buildDetailRow('Rest Duration', certificate.expectedRestDuration,
              Icons.schedule, HospitalTheme.warning),
          _buildDetailRow('Expected Return', certificate.expectedReturnDate,
              Icons.event_available, HospitalTheme.info),
          _buildDetailRow('Issue Date', certificate.issueDate,
              Icons.calendar_today, HospitalTheme.primary),
          _buildDetailRow('Doctor', 'Dr. ${certificate.doctorName}',
              Icons.person_pin, HospitalTheme.medical),
          _buildDetailRow('Speciality', certificate.doctorSpeciality,
              Icons.local_hospital, HospitalTheme.pharmacy),
        ],
      ),
    );
  }

  Widget _buildAdmissionInfoCard(AdmissionInfo admission) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('Admission Information'),
          _buildDetailRow('OPD Number', admission.opdNumber.toString(),
              Icons.confirmation_number, HospitalTheme.secondary),
          _buildDetailRow(
              'Admission Date',
              _formatDisplayDate(admission.admissionDate),
              Icons.event,
              HospitalTheme.primary),
        ],
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
      icon: Icons.medical_information,
      onPressed: _handleGenerateCertificate,
      tooltip: 'Generate Certificate (Ctrl+G)',
    );
  }

  // ==================== EVENT HANDLERS ====================

  void _handleGenerateCertificate() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(medicalCertificateProvider.notifier).generateCertificate(
            widget.patientId,
            widget.admissionId,
            _authToken,
          );
    }
  }

  void _viewCertificate(MedicalCertificateResponse response) {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: HospitalTheme.radiusLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HospitalTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(HospitalTheme.primary),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading PDF...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: HospitalTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we prepare your certificate',
                style: TextStyle(
                  fontSize: 13,
                  color: HospitalTheme.textMedium,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );

    // Load and show PDF with automatic dialog dismissal
    ref
        .read(pdfViewerProvider.notifier)
        .loadAndShowPdf(
          response.certificateUrl,
          title: 'Medical Certificate - ${response.patientDetails.name}',
        )
        .then((_) {
      // Dismiss loading dialog when PDF is loaded
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }).catchError((error) {
      // Dismiss loading dialog on error
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load PDF: $error'),
          backgroundColor: HospitalTheme.error,
        ),
      );
    });
  }

  void _downloadCertificate(MedicalCertificateResponse response) {
    Methods().openPdf(response.certificateUrl);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${response.filename}...')),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help - Medical Certificate Generator'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Select or create a certificate type'),
            SizedBox(height: 8),
            Text('2. Enter the patient diagnosis (required)'),
            SizedBox(height: 8),
            Text('3. Set medical leave start and return dates'),
            SizedBox(height: 8),
            Text('4. Specify expected rest duration'),
            SizedBox(height: 8),
            Text('5. Add notes (optional)'),
            SizedBox(height: 8),
            Text('6. Click "Generate Medical Certificate"'),
            SizedBox(height: 16),
            Text('Custom Types:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Click "Add Custom" to create your own certificate type'),
            Text('• Custom types can be deleted by clicking the X icon'),
            SizedBox(height: 16),
            Text('Keyboard Shortcuts:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Ctrl+G: Generate Certificate'),
            Text('• ESC: Close Screen'),
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

  String _formatDisplayDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// ==================== CUSTOM WIDGETS ====================

class _CertificateTypeCard extends StatelessWidget {
  final CertificateType certificateType;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _CertificateTypeCard({
    required this.certificateType,
    required this.isSelected,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? certificateType.color.withOpacity(0.1)
              : Colors.white,
          borderRadius: HospitalTheme.radiusSmall,
          border: Border.all(
            color: isSelected ? certificateType.color : HospitalTheme.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? HospitalTheme.shadowSmall : null,
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: certificateType.color.withOpacity(0.2),
                    borderRadius: HospitalTheme.radiusSmall,
                  ),
                  child: Icon(
                    certificateType.icon,
                    color: certificateType.color,
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
                        certificateType.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isSelected
                              ? certificateType.color
                              : HospitalTheme.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: certificateType.color,
                    size: 20,
                  ),
              ],
            ),
            // Delete button for custom types
            if (onDelete != null)
              Positioned(
                top: -4,
                right: -4,
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Custom Type'),
                        content: Text(
                          'Are you sure you want to delete "${certificateType.displayName}"?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onDelete!();
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: HospitalTheme.error),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: HospitalTheme.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
