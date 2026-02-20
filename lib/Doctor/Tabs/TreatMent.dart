import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:doctordesktop/constants/Url.dart';

// Enhanced Data Models
class PatientInfo {
  final String patientId;
  final String name;
  final int age;
  final String gender;
  final String contact;
  final String address;
  final String imageUrl;

  PatientInfo({
    required this.patientId,
    required this.name,
    required this.age,
    required this.gender,
    required this.contact,
    required this.address,
    required this.imageUrl,
  });

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    return PatientInfo(
      patientId: json['patientId'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      contact: json['contact'] ?? '',
      address: json['address'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}

class AdmissionInfo {
  final String admissionId;
  final int opdNumber;
  final int ipdNumber;
  final String admissionDate;
  final String status;
  final Doctor doctor;
  final Section section;
  final int bedNumber;
  final String reasonForAdmission;

  AdmissionInfo({
    required this.admissionId,
    required this.opdNumber,
    required this.ipdNumber,
    required this.admissionDate,
    required this.status,
    required this.doctor,
    required this.section,
    required this.bedNumber,
    required this.reasonForAdmission,
  });

  factory AdmissionInfo.fromJson(Map<String, dynamic> json) {
    return AdmissionInfo(
      admissionId: json['admissionId'] ?? '',
      opdNumber: json['opdNumber'] ?? 0,
      ipdNumber: json['ipdNumber'] ?? 0,
      admissionDate: json['admissionDate'] ?? '',
      status: json['status'] ?? '',
      doctor: Doctor.fromJson(json['doctor'] ?? {}),
      section: Section.fromJson(json['section'] ?? {}),
      bedNumber: json['bedNumber'] ?? 0,
      reasonForAdmission: json['reasonForAdmission'] ?? '',
    );
  }

  String get formattedAdmissionDate {
    try {
      final date = DateTime.parse(admissionDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return admissionDate;
    }
  }
}

class Doctor {
  final String id;
  final String name;
  final String usertype;

  Doctor({
    required this.id,
    required this.name,
    required this.usertype,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      usertype: json['usertype'] ?? '',
    );
  }
}

class Section {
  final String id;
  final String name;
  final String type;

  Section({
    required this.id,
    required this.name,
    required this.type,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
    );
  }
}

// Treatment Models
class TreatmentMedication {
  final String id;
  final String name;
  final String dosage;
  final String type;
  final String date;
  final String time;
  final String administrationStatus;
  final String? administeredBy;
  final String? administeredAt;
  final String administrationNotes;
  final String? nurseName;

  TreatmentMedication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.type,
    required this.date,
    required this.time,
    required this.administrationStatus,
    this.administeredBy,
    this.administeredAt,
    this.nurseName,
    required this.administrationNotes,
  });

  factory TreatmentMedication.fromJson(Map<String, dynamic> json) {
    return TreatmentMedication(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      dosage: json['dosage'] ?? '',
      type: json['type'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      administrationStatus: json['administrationStatus'] ?? 'Pending',
      administeredBy: json['administeredBy']?.toString(),
      administeredAt: json['administeredAt'],
      administrationNotes: json['administrationNotes'] ?? '',
      nurseName: json['nurseName']?.toString(),
    );
  }

  String get formattedAdministeredTime {
    if (administeredAt == null) return 'Not administered';
    try {
      final dateTime = DateTime.parse(administeredAt!);
      final istDateTime = dateTime.add(const Duration(hours: 5, minutes: 30));
      return '${istDateTime.day}/${istDateTime.month}/${istDateTime.year} ${istDateTime.hour.toString().padLeft(2, '0')}:${istDateTime.minute.toString().padLeft(2, '0')} IST';
    } catch (e) {
      return administeredAt ?? 'Invalid date';
    }
  }

  Color get statusColor {
    switch (administrationStatus.toLowerCase()) {
      case 'administered':
        return HospitalTheme.success;
      case 'pending':
        return HospitalTheme.warning;
      case 'skipped':
        return HospitalTheme.error;
      default:
        return HospitalTheme.info;
    }
  }

  IconData get statusIcon {
    switch (administrationStatus.toLowerCase()) {
      case 'administered':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.schedule_rounded;
      case 'skipped':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

class IVFluid {
  final String id;
  final String name;
  final String quantity;
  final String duration;
  final String date;
  final String time;
  final String administrationStatus;
  final String? administeredBy;
  final String? administeredAt;

  IVFluid({
    required this.id,
    required this.name,
    required this.quantity,
    required this.duration,
    required this.date,
    required this.time,
    required this.administrationStatus,
    this.administeredBy,
    this.administeredAt,
  });

  factory IVFluid.fromJson(Map<String, dynamic> json) {
    return IVFluid(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? '',
      duration: json['duration'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      administrationStatus: json['administrationStatus'] ?? 'Pending',
      administeredBy: json['administeredBy']?.toString(),
      administeredAt: json['administeredAt'],
    );
  }

  String get formattedAdministeredTime {
    if (administeredAt == null) return 'Not administered';
    try {
      final dateTime = DateTime.parse(administeredAt!);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return administeredAt ?? 'Invalid date';
    }
  }

  Color get statusColor {
    switch (administrationStatus.toLowerCase()) {
      case 'administered':
        return HospitalTheme.success;
      case 'pending':
        return HospitalTheme.warning;
      case 'skipped':
        return HospitalTheme.error;
      default:
        return HospitalTheme.info;
    }
  }
}

class TreatmentProcedure {
  final String id;
  final String name;
  final String frequency;
  final String date;
  final String time;
  final String administrationStatus;
  final String? administeredBy;
  final String? administeredAt;

  TreatmentProcedure({
    required this.id,
    required this.name,
    required this.frequency,
    required this.date,
    required this.time,
    required this.administrationStatus,
    this.administeredBy,
    this.administeredAt,
  });

  factory TreatmentProcedure.fromJson(Map<String, dynamic> json) {
    return TreatmentProcedure(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      frequency: json['frequency'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      administrationStatus: json['administrationStatus'] ?? 'Pending',
      administeredBy: json['administeredBy']?.toString(),
      administeredAt: json['administeredAt'],
    );
  }

  String get formattedAdministeredTime {
    if (administeredAt == null) return 'Not administered';
    try {
      final dateTime = DateTime.parse(administeredAt!);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return administeredAt ?? 'Invalid date';
    }
  }

  Color get statusColor {
    switch (administrationStatus.toLowerCase()) {
      case 'administered':
        return HospitalTheme.success;
      case 'pending':
        return HospitalTheme.warning;
      case 'skipped':
        return HospitalTheme.error;
      default:
        return HospitalTheme.info;
    }
  }
}

class SpecialInstruction {
  final String id;
  final String instruction;
  final String date;
  final String time;
  final String status;

  SpecialInstruction({
    required this.id,
    required this.instruction,
    required this.date,
    required this.time,
    required this.status,
  });

  factory SpecialInstruction.fromJson(Map<String, dynamic> json) {
    return SpecialInstruction(
      id: json['_id'] ?? '',
      instruction: json['instruction'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      status: json['status'] ?? 'Pending',
    );
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'completed':
        return HospitalTheme.success;
      case 'pending':
        return HospitalTheme.warning;
      case 'cancelled':
        return HospitalTheme.error;
      default:
        return HospitalTheme.info;
    }
  }
}

class TreatmentData {
  final List<TreatmentMedication> medications;
  final List<IVFluid> ivFluids;
  final List<TreatmentProcedure> procedures;
  final List<SpecialInstruction> specialInstructions;

  TreatmentData({
    required this.medications,
    required this.ivFluids,
    required this.procedures,
    required this.specialInstructions,
  });

  factory TreatmentData.fromJson(Map<String, dynamic> json) {
    return TreatmentData(
      medications: (json['medications'] as List? ?? [])
          .map((m) => TreatmentMedication.fromJson(m))
          .toList(),
      ivFluids: (json['ivFluids'] as List? ?? [])
          .map((f) => IVFluid.fromJson(f))
          .toList(),
      procedures: (json['procedures'] as List? ?? [])
          .map((p) => TreatmentProcedure.fromJson(p))
          .toList(),
      specialInstructions: (json['specialInstructions'] as List? ?? [])
          .map((s) => SpecialInstruction.fromJson(s))
          .toList(),
    );
  }

  int get totalItems =>
      medications.length +
      ivFluids.length +
      procedures.length +
      specialInstructions.length;
}

// Enhanced Main Screen
class EnhancedTreatmentScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String admissionId;

  const EnhancedTreatmentScreen({
    Key? key,
    required this.patientId,
    required this.admissionId,
  }) : super(key: key);

  @override
  ConsumerState<EnhancedTreatmentScreen> createState() =>
      _EnhancedTreatmentScreenState();
}

class _EnhancedTreatmentScreenState
    extends ConsumerState<EnhancedTreatmentScreen>
    with TickerProviderStateMixin {
  bool isLoading = true;
  TreatmentData? treatmentData;
  PatientInfo? patientInfo;
  AdmissionInfo? admissionInfo;
  String errorMessage = '';
  bool _hasChanges = false;
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

    fetchTreatmentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchTreatmentData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final treatmentResponse = await http.get(
        Uri.parse(
            '${KVM_URL}/doctors/getDoctorTreatment/${widget.patientId}/${widget.admissionId}'),
      );

      final medicationResponse = await http.get(
        Uri.parse(
            '${KVM_URL}/doctors/getMedicationStatus/${widget.patientId}/${widget.admissionId}'),
      );

      if (treatmentResponse.statusCode == 200) {
        final treatmentJson = json.decode(treatmentResponse.body);
        setState(() {
          treatmentData = TreatmentData.fromJson(treatmentJson['data']);
        });
      }

      if (medicationResponse.statusCode == 200) {
        final medicationJson = json.decode(medicationResponse.body);
        if (medicationJson['success'] == true) {
          final data = medicationJson['data'];
          setState(() {
            patientInfo = PatientInfo.fromJson(data['patientInfo']);
            admissionInfo = AdmissionInfo.fromJson(data['admissionInfo']);
          });
        }
      }

      setState(() {
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> deleteTreatmentItem(
      String treatmentType, String treatmentId) async {
    try {
      final response = await http.delete(
        Uri.parse('${KVM_URL}/doctors/deleteDoctorTreatment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'patientId': widget.patientId,
          'admissionId': widget.admissionId,
          'treatmentType': treatmentType,
          'treatmentId': treatmentId,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Treatment item deleted successfully', isSuccess: true);
        setState(() {
          _hasChanges = true;
        });
        await fetchTreatmentData();
      } else {
        _showSnackBar('Failed to delete treatment item');
      }
    } catch (e) {
      _showSnackBar('Error deleting treatment item: $e');
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.info,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? HospitalTheme.success : HospitalTheme.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 1200;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          Navigator.of(context).pop(_hasChanges);
        },
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          _showAddTreatmentDialog();
        },
      },
      child: Focus(
        autofocus: true,
        child: WillPopScope(
          onWillPop: () async {
            Navigator.of(context).pop(_hasChanges);
            return false;
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF0F4F8),
            appBar: _buildAppBar(context),
            body: SafeArea(
              child: isLoading
                  ? _buildLoadingState()
                  : errorMessage.isNotEmpty
                      ? _buildErrorState()
                      : FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              if (patientInfo != null && admissionInfo != null)
                                _buildHeaderSection(),
                              _buildTabBar(),
                              Expanded(
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildMedicationsTab(),
                                    _buildIVFluidsTab(),
                                    _buildProceduresTab(),
                                    _buildSpecialInstructionsTab(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
            floatingActionButton: !isLoading && treatmentData != null
                ? _buildFloatingActionButton()
                : null,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
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
      automaticallyImplyLeading: false,
      title: const Text(
        'Treatment Management',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      actions: [
        Tooltip(
          message: 'Add Treatment (Ctrl+N)',
          child: IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showAddTreatmentDialog();
            },
          ),
        ),
        Tooltip(
          message: 'Refresh Data',
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () {
              HapticFeedback.lightImpact();
              fetchTreatmentData();
            },
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    HospitalTheme.primary.withOpacity(0.1),
                    HospitalTheme.secondary.withOpacity(0.1),
                  ],
                ),
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
              'Loading treatment data...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: HospitalTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: HospitalTheme.shadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HospitalTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: HospitalTheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to Load Data',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              style: TextStyle(
                fontSize: 16,
                color: HospitalTheme.textMedium,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: fetchTreatmentData,
              style: ElevatedButton.styleFrom(
                backgroundColor: HospitalTheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'Try Again',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HospitalTheme.surfaceLight,
            HospitalTheme.cardBackground,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: HospitalTheme.shadow,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [HospitalTheme.primary, HospitalTheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: patientInfo!.imageUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      patientInfo!.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.person_rounded,
                    size: 30,
                    color: Colors.white,
                  ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientInfo!.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${patientInfo!.patientId} • ${admissionInfo!.section.name} • Bed ${admissionInfo!.bedNumber}',
                  style: TextStyle(
                    fontSize: 14,
                    color: HospitalTheme.textMedium,
                  ),
                ),
              ],
            ),
          ),
          if (treatmentData != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: HospitalTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: HospitalTheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.medical_services_rounded,
                      color: HospitalTheme.primary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${treatmentData!.totalItems} Items',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: HospitalTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: HospitalTheme.shadowSmall,
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: HospitalTheme.primary,
        unselectedLabelColor: HospitalTheme.textMedium,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              HospitalTheme.primary.withOpacity(0.1),
              HospitalTheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        tabs: [
          Tab(
            icon: const Icon(Icons.medication_rounded, size: 20),
            text: 'Medications (${treatmentData?.medications.length ?? 0})',
          ),
          Tab(
            icon: const Icon(Icons.water_drop_rounded, size: 20),
            text: 'IV Fluids (${treatmentData?.ivFluids.length ?? 0})',
          ),
          Tab(
            icon: const Icon(Icons.healing_rounded, size: 20),
            text: 'Procedures (${treatmentData?.procedures.length ?? 0})',
          ),
          Tab(
            icon: const Icon(Icons.note_rounded, size: 20),
            text:
                'Instructions (${treatmentData?.specialInstructions.length ?? 0})',
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsTab() {
    if (treatmentData?.medications.isEmpty ?? true) {
      return _buildEmptyState(
          'No medications prescribed', Icons.medication_rounded);
    }

    return RefreshIndicator(
      onRefresh: fetchTreatmentData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: treatmentData!.medications.length,
        itemBuilder: (context, index) {
          final medication = treatmentData!.medications[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMedicationCard(medication),
          );
        },
      ),
    );
  }

  Widget _buildIVFluidsTab() {
    if (treatmentData?.ivFluids.isEmpty ?? true) {
      return _buildEmptyState(
          'No IV fluids prescribed', Icons.water_drop_rounded);
    }

    return RefreshIndicator(
      onRefresh: fetchTreatmentData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: treatmentData!.ivFluids.length,
        itemBuilder: (context, index) {
          final fluid = treatmentData!.ivFluids[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildIVFluidCard(fluid),
          );
        },
      ),
    );
  }

  Widget _buildProceduresTab() {
    if (treatmentData?.procedures.isEmpty ?? true) {
      return _buildEmptyState('No procedures scheduled', Icons.healing_rounded);
    }

    return RefreshIndicator(
      onRefresh: fetchTreatmentData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: treatmentData!.procedures.length,
        itemBuilder: (context, index) {
          final procedure = treatmentData!.procedures[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildProcedureCard(procedure),
          );
        },
      ),
    );
  }

  Widget _buildSpecialInstructionsTab() {
    if (treatmentData?.specialInstructions.isEmpty ?? true) {
      return _buildEmptyState('No special instructions', Icons.note_rounded);
    }

    return RefreshIndicator(
      onRefresh: fetchTreatmentData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: treatmentData!.specialInstructions.length,
        itemBuilder: (context, index) {
          final instruction = treatmentData!.specialInstructions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSpecialInstructionCard(instruction),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: HospitalTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: HospitalTheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add new items',
              style: TextStyle(
                fontSize: 14,
                color: HospitalTheme.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationCard(TreatmentMedication medication) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: medication.statusColor.withOpacity(0.2)),
        boxShadow: HospitalTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: medication.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.medication_liquid_rounded,
                  color: medication.statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                    Text(
                      medication.dosage,
                      style: TextStyle(
                        fontSize: 13,
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: medication.statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(medication.statusIcon, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      medication.administrationStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showDeleteConfirmation(
                  'medications',
                  medication.id,
                  medication.name,
                ),
                icon: Icon(Icons.delete_outline, color: HospitalTheme.error),
                tooltip: 'Delete Medication',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip('Type', medication.type, Icons.category_rounded),
              const SizedBox(width: 8),
              _buildInfoChip(
                  'Date', medication.date, Icons.calendar_today_rounded),
              const SizedBox(width: 8),
              _buildInfoChip(
                  'Time', medication.time, Icons.access_time_rounded),
            ],
          ),
          if (medication.administrationStatus.toLowerCase() ==
              'administered') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HospitalTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: HospitalTheme.success.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: HospitalTheme.success, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Administration Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAdministrationInfo(
                          'Administered By',
                          medication.nurseName ?? 'Unknown',
                          Icons.person_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAdministrationInfo(
                          'Administered At',
                          medication.formattedAdministeredTime,
                          Icons.access_time_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIVFluidCard(IVFluid fluid) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fluid.statusColor.withOpacity(0.2)),
        boxShadow: HospitalTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: fluid.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.water_drop_rounded,
                  color: fluid.statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fluid.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                    Text(
                      '${fluid.quantity} • ${fluid.duration}',
                      style: TextStyle(
                        fontSize: 13,
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: fluid.statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  fluid.administrationStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showDeleteConfirmation(
                  'ivFluids',
                  fluid.id,
                  fluid.name,
                ),
                icon: Icon(Icons.delete_outline, color: HospitalTheme.error),
                tooltip: 'Delete IV Fluid',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip('Quantity', fluid.quantity,
                  Icons.format_list_numbered_rounded),
              const SizedBox(width: 8),
              _buildInfoChip('Duration', fluid.duration, Icons.timer_rounded),
            ],
          ),
          if (fluid.administrationStatus.toLowerCase() == 'administered') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HospitalTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: HospitalTheme.success.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: HospitalTheme.success, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Administration Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAdministrationInfo(
                          'Administered By',
                          fluid.administeredBy ?? 'Unknown',
                          Icons.person_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAdministrationInfo(
                          'Administered At',
                          fluid.formattedAdministeredTime,
                          Icons.access_time_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProcedureCard(TreatmentProcedure procedure) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: procedure.statusColor.withOpacity(0.2)),
        boxShadow: HospitalTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: procedure.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.healing_rounded,
                  color: procedure.statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      procedure.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                    Text(
                      procedure.frequency,
                      style: TextStyle(
                        fontSize: 13,
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: procedure.statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  procedure.administrationStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showDeleteConfirmation(
                  'procedures',
                  procedure.id,
                  procedure.name,
                ),
                icon: Icon(Icons.delete_outline, color: HospitalTheme.error),
                tooltip: 'Delete Procedure',
              ),
            ],
          ),
          if (procedure.administrationStatus.toLowerCase() ==
              'administered') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HospitalTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: HospitalTheme.success.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: HospitalTheme.success, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Administration Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAdministrationInfo(
                          'Administered By',
                          procedure.administeredBy ?? 'Unknown',
                          Icons.person_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAdministrationInfo(
                          'Administered At',
                          procedure.formattedAdministeredTime,
                          Icons.access_time_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdministrationInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 12, color: HospitalTheme.success),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: HospitalTheme.textMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  color: HospitalTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialInstructionCard(SpecialInstruction instruction) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: instruction.statusColor.withOpacity(0.2)),
        boxShadow: HospitalTheme.shadowSmall,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: instruction.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.note_rounded,
              color: instruction.statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction.instruction,
              style: TextStyle(
                fontSize: 14,
                color: HospitalTheme.textDark,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: instruction.statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              instruction.status,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _showDeleteConfirmation(
              'specialInstructions',
              instruction.id,
              instruction.instruction,
            ),
            icon: Icon(Icons.delete_outline, color: HospitalTheme.error),
            tooltip: 'Delete Instruction',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: HospitalTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HospitalTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: HospitalTheme.textMedium),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 10,
              color: HospitalTheme.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
      String treatmentType, String treatmentId, String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: HospitalTheme.error),
            const SizedBox(width: 12),
            const Text(
              'Delete Treatment',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$itemName"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteTreatmentItem(treatmentType, treatmentId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddTreatmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTreatmentDialog(
        patientId: widget.patientId,
        admissionId: widget.admissionId,
        onTreatmentAdded: () {
          setState(() {
            _hasChanges = true;
          });
          fetchTreatmentData();
        },
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showAddTreatmentDialog,
      backgroundColor: HospitalTheme.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'Add Treatment',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

// Add Treatment Dialog
class AddTreatmentDialog extends StatefulWidget {
  final String patientId;
  final String admissionId;
  final VoidCallback onTreatmentAdded;

  const AddTreatmentDialog({
    Key? key,
    required this.patientId,
    required this.admissionId,
    required this.onTreatmentAdded,
  }) : super(key: key);

  @override
  State<AddTreatmentDialog> createState() => _AddTreatmentDialogState();
}

class _AddTreatmentDialogState extends State<AddTreatmentDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = false;

  // Medication fields
  final medicationNameController = TextEditingController();
  final medicationDosageController = TextEditingController();
  String selectedMedicationType = 'Oral';

  // IV Fluid fields
  final ivFluidNameController = TextEditingController();
  final ivFluidQuantityController = TextEditingController();
  final ivFluidDurationController = TextEditingController();

  // Procedure fields
  final procedureNameController = TextEditingController();
  final procedureFrequencyController = TextEditingController();

  // Special Instruction fields
  final specialInstructionController = TextEditingController();

  final List<String> medicationTypes = [
    'Oral',
    'Injectable',
    'Topical',
    'Inhalation'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    medicationNameController.dispose();
    medicationDosageController.dispose();
    ivFluidNameController.dispose();
    ivFluidQuantityController.dispose();
    ivFluidDurationController.dispose();
    procedureNameController.dispose();
    procedureFrequencyController.dispose();
    specialInstructionController.dispose();
    super.dispose();
  }

  Future<void> addTreatment() async {
    setState(() {
      isLoading = true;
    });

    try {
      final Map<String, dynamic> requestBody = {
        'patientId': widget.patientId,
        'admissionId': widget.admissionId,
        'medications': <Map<String, dynamic>>[],
        'ivFluids': <Map<String, dynamic>>[],
        'procedures': <Map<String, dynamic>>[],
        'specialInstructions': <Map<String, dynamic>>[],
      };

      switch (_tabController.index) {
        case 0:
          if (medicationNameController.text.isNotEmpty &&
              medicationDosageController.text.isNotEmpty) {
            requestBody['medications'].add({
              'name': medicationNameController.text,
              'dosage': medicationDosageController.text,
              'type': selectedMedicationType,
            });
          }
          break;
        case 1:
          if (ivFluidNameController.text.isNotEmpty &&
              ivFluidQuantityController.text.isNotEmpty &&
              ivFluidDurationController.text.isNotEmpty) {
            requestBody['ivFluids'].add({
              'name': ivFluidNameController.text,
              'quantity': ivFluidQuantityController.text,
              'duration': ivFluidDurationController.text,
            });
          }
          break;
        case 2:
          if (procedureNameController.text.isNotEmpty &&
              procedureFrequencyController.text.isNotEmpty) {
            requestBody['procedures'].add({
              'name': procedureNameController.text,
              'frequency': procedureFrequencyController.text,
            });
          }
          break;
        case 3:
          if (specialInstructionController.text.isNotEmpty) {
            requestBody['specialInstructions'].add({
              'instruction': specialInstructionController.text,
            });
          }
          break;
      }

      final response = await http.post(
        Uri.parse('${KVM_URL}/doctors/addDoctorTreatment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        widget.onTreatmentAdded();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text(
                  'Treatment added successfully',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: HospitalTheme.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        throw Exception('Failed to add treatment');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to add treatment: $e',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: HospitalTheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.add_circle_rounded,
                    color: HospitalTheme.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Add New Treatment',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded,
                      color: HospitalTheme.textMedium),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: HospitalTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: HospitalTheme.primary,
                unselectedLabelColor: HospitalTheme.textMedium,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  boxShadow: HospitalTheme.shadowSmall,
                ),
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                tabs: const [
                  Tab(icon: Icon(Icons.medication_rounded), text: 'Medication'),
                  Tab(icon: Icon(Icons.water_drop_rounded), text: 'IV Fluid'),
                  Tab(icon: Icon(Icons.healing_rounded), text: 'Procedure'),
                  Tab(icon: Icon(Icons.note_rounded), text: 'Instruction'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMedicationForm(),
                  _buildIVFluidForm(),
                  _buildProcedureForm(),
                  _buildSpecialInstructionForm(),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : addTreatment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HospitalTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Add Treatment',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTextField(
            controller: medicationNameController,
            label: 'Medication Name',
            hint: 'Enter medication name',
            icon: Icons.medication_rounded,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: medicationDosageController,
            label: 'Dosage',
            hint: 'Enter dosage instructions',
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            label: 'Type',
            value: selectedMedicationType,
            items: medicationTypes,
            onChanged: (value) =>
                setState(() => selectedMedicationType = value!),
            icon: Icons.category_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildIVFluidForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTextField(
            controller: ivFluidNameController,
            label: 'IV Fluid Name',
            hint: 'Enter IV fluid name',
            icon: Icons.water_drop_rounded,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: ivFluidQuantityController,
            label: 'Quantity',
            hint: 'Enter quantity (e.g., 500ml)',
            icon: Icons.format_list_numbered_rounded,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: ivFluidDurationController,
            label: 'Duration',
            hint: 'Enter duration (e.g., Over 4 hours)',
            icon: Icons.timer_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildProcedureForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTextField(
            controller: procedureNameController,
            label: 'Procedure Name',
            hint: 'Enter procedure name',
            icon: Icons.healing_rounded,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: procedureFrequencyController,
            label: 'Frequency',
            hint: 'Enter frequency (e.g., Every 24 hours)',
            icon: Icons.repeat_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialInstructionForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTextField(
            controller: specialInstructionController,
            label: 'Special Instruction',
            hint: 'Enter special instruction',
            icon: Icons.note_rounded,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HospitalTheme.border),
        boxShadow: HospitalTheme.shadowSmall,
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: HospitalTheme.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          labelStyle: TextStyle(color: HospitalTheme.textMedium),
          hintStyle: TextStyle(color: HospitalTheme.textLight),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HospitalTheme.border),
        boxShadow: HospitalTheme.shadowSmall,
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        style: TextStyle(color: HospitalTheme.textDark),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: HospitalTheme.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          labelStyle: TextStyle(color: HospitalTheme.textMedium),
        ),
      ),
    );
  }
}
