import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

// ==================== MODELS ====================

class EmergencyMedication {
  final String id;
  final String patientId;
  final String admissionId;
  final String medicationName;
  final String dosage;
  final String nurseName;
  final String reason;
  final String status;
  final DateTime administeredAt;
  final Patient? patient;
  final Nurse? nurse;
  final DoctorApproval? doctorApproval;

  const EmergencyMedication({
    required this.id,
    required this.patientId,
    required this.admissionId,
    required this.medicationName,
    required this.dosage,
    required this.nurseName,
    required this.reason,
    required this.status,
    required this.administeredAt,
    this.patient,
    this.nurse,
    this.doctorApproval,
  });

  factory EmergencyMedication.fromJson(Map<String, dynamic> json) {
    return EmergencyMedication(
      id: json['_id'] ?? '',
      patientId: json['patientId'] ?? '',
      admissionId: json['admissionId'] ?? '',
      medicationName: json['medicationName'] ?? '',
      dosage: json['dosage'] ?? '',
      nurseName: json['nurseName'] ?? '',
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'Pending',
      administeredAt:
          DateTime.tryParse(json['administeredAt'] ?? '') ?? DateTime.now(),
      patient:
          json['patient'] != null ? Patient.fromJson(json['patient']) : null,
      nurse: json['nurse'] != null ? Nurse.fromJson(json['nurse']) : null,
      doctorApproval: json['doctorApproval'] != null
          ? DoctorApproval.fromJson(json['doctorApproval'])
          : null,
    );
  }

  Color get statusColor {
    // Check if doctor has approved/rejected
    if (doctorApproval != null) {
      if (doctorApproval!.approved == true) {
        return HospitalTheme.success;
      } else if (doctorApproval!.approved == false) {
        return HospitalTheme.error;
      }
    }

    // Fall back to status field
    switch (status.toLowerCase()) {
      case 'approved':
        return HospitalTheme.success;
      case 'rejected':
        return HospitalTheme.error;
      case 'pending':
        return HospitalTheme.warning;
      default:
        return HospitalTheme.info;
    }
  }

  IconData get statusIcon {
    // Check if doctor has approved/rejected
    if (doctorApproval != null) {
      if (doctorApproval!.approved == true) {
        return Icons.check_circle;
      } else if (doctorApproval!.approved == false) {
        return Icons.cancel;
      }
    }

    // Fall back to status field
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.access_time;
      default:
        return Icons.info;
    }
  }

  String get displayStatus {
    // Check if doctor has approved/rejected
    if (doctorApproval != null) {
      if (doctorApproval!.approved == true) {
        return 'Approved';
      } else if (doctorApproval!.approved == false) {
        return 'Rejected';
      }
    }

    // Fall back to status field
    return status;
  }

  bool get isPending {
    return doctorApproval == null || (doctorApproval!.approved == null);
  }
}

class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String contact;
  final String patientId;

  const Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.contact,
    required this.patientId,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      contact: json['contact'] ?? '',
      patientId: json['patientId'] ?? '',
    );
  }
}

class Nurse {
  final String id;

  const Nurse({required this.id});

  factory Nurse.fromJson(Map<String, dynamic> json) {
    return Nurse(id: json['_id'] ?? '');
  }
}

class Doctor {
  final String id;

  const Doctor({required this.id});

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(id: json['_id'] ?? '');
  }
}

class DoctorApproval {
  final bool? approved;
  final String? notes;
  final DateTime? timestamp;
  final Doctor? doctor;

  const DoctorApproval({
    this.approved,
    this.notes,
    this.timestamp,
    this.doctor,
  });

  factory DoctorApproval.fromJson(Map<String, dynamic> json) {
    return DoctorApproval(
      approved: json['approved'],
      notes: json['notes'],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'])
          : null,
      doctor: json['doctor'] != null ? Doctor.fromJson(json['doctor']) : null,
    );
  }
}

class EmergencyMedicationResponse {
  final bool success;
  final String message;
  final List<EmergencyMedication> medications;
  final Pagination pagination;
  final Summary summary;

  const EmergencyMedicationResponse({
    required this.success,
    required this.message,
    required this.medications,
    required this.pagination,
    required this.summary,
  });

  factory EmergencyMedicationResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return EmergencyMedicationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      medications: (data['emergencyMedications'] as List<dynamic>?)
              ?.map((med) => EmergencyMedication.fromJson(med))
              .toList() ??
          [],
      pagination: Pagination.fromJson(data['pagination'] ?? {}),
      summary: Summary.fromJson(data['summary'] ?? {}),
    );
  }
}

class Pagination {
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasNext;
  final bool hasPrev;

  const Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.hasNext,
    required this.hasPrev,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalCount: json['totalCount'] ?? 0,
      hasNext: json['hasNext'] ?? false,
      hasPrev: json['hasPrev'] ?? false,
    );
  }
}

class Summary {
  final int total;
  final int pending;
  final int approved;
  final int rejected;
  final int pendingDoctorApproval;

  const Summary({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.pendingDoctorApproval,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      total: json['total'] ?? 0,
      pending: json['pending'] ?? 0,
      approved: json['approved'] ?? 0,
      rejected: json['rejected'] ?? 0,
      pendingDoctorApproval: json['pendingDoctorApproval'] ?? 0,
    );
  }
}

class MedicationApproval {
  final String medicationId;
  final bool approved;
  final String notes;

  const MedicationApproval({
    required this.medicationId,
    required this.approved,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'medicationId': medicationId,
      'approved': approved,
      'notes': notes,
    };
  }
}

// ==================== PROVIDERS ====================

class EmergencyMedicationService {
  static Future<EmergencyMedicationResponse> getEmergencyMedications(
    String patientId,
    String admissionId,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      final response = await http.get(
        Uri.parse(
            '${BASE_URL}/doctors/getPatientEmergencyMedicationsForDoctor/$patientId/$admissionId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return EmergencyMedicationResponse.fromJson(data);
      } else {
        throw Exception(
            'Failed to load emergency medications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching emergency medications: $e');
    }
  }

  static Future<bool> bulkApproveMedications(
    String patientId,
    String admissionId,
    List<MedicationApproval> medications,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      final response = await http.patch(
        Uri.parse(
            '${BASE_URL}/doctors/doctorBulkApproveEmergencyMedications/$patientId/$admissionId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode(
            {'medications': medications.map((m) => m.toJson()).toList()}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error approving medications: $e');
      throw Exception('Error approving medications: $e');
    }
  }
}

final emergencyMedicationProvider = StateNotifierProvider<
    EmergencyMedicationNotifier, AsyncValue<List<EmergencyMedication>>>((ref) {
  return EmergencyMedicationNotifier();
});

class EmergencyMedicationNotifier
    extends StateNotifier<AsyncValue<List<EmergencyMedication>>> {
  EmergencyMedicationNotifier() : super(const AsyncValue.loading());

  Future<void> fetchMedications(String patientId, String admissionId) async {
    state = const AsyncValue.loading();
    try {
      final response = await EmergencyMedicationService.getEmergencyMedications(
          patientId, admissionId);
      if (response.success) {
        state = AsyncValue.data(response.medications);
      } else {
        state = AsyncValue.error(response.message, StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e.toString(), stackTrace);
    }
  }

  Future<void> refreshMedications(String patientId, String admissionId) async {
    await fetchMedications(patientId, admissionId);
  }
}

final selectedMedicationProvider =
    StateProvider<EmergencyMedication?>((ref) => null);

final medicationSearchProvider =
    StateNotifierProvider<MedicationSearchNotifier, String>((ref) {
  return MedicationSearchNotifier();
});

class MedicationSearchNotifier extends StateNotifier<String> {
  MedicationSearchNotifier() : super('');

  void updateSearchQuery(String query) {
    state = query;
  }

  void clearSearch() {
    state = '';
  }
}

final filteredMedicationsProvider =
    Provider<AsyncValue<List<EmergencyMedication>>>((ref) {
  final medicationsAsync = ref.watch(emergencyMedicationProvider);
  final searchQuery = ref.watch(medicationSearchProvider);

  return medicationsAsync.when(
    data: (medications) {
      if (searchQuery.isEmpty) {
        return AsyncValue.data(medications);
      }

      final filtered = medications.where((medication) {
        final query = searchQuery.toLowerCase();
        return medication.medicationName.toLowerCase().contains(query) ||
            medication.nurseName.toLowerCase().contains(query) ||
            medication.reason.toLowerCase().contains(query) ||
            medication.dosage.toLowerCase().contains(query);
      }).toList();

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// ==================== MAIN SCREEN ====================

class DoctorEmergencyMedicationScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String admissionId;

  const DoctorEmergencyMedicationScreen({
    Key? key,
    required this.patientId,
    required this.admissionId,
  }) : super(key: key);

  @override
  ConsumerState<DoctorEmergencyMedicationScreen> createState() =>
      _DoctorEmergencyMedicationScreenState();
}

class _DoctorEmergencyMedicationScreenState
    extends ConsumerState<DoctorEmergencyMedicationScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _isProcessing = false;
  String? _processingError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(emergencyMedicationProvider.notifier)
          .fetchMedications(widget.patientId, widget.admissionId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyboardShortcuts(KeyEvent event) {
    if (event is KeyDownEvent) {
      if ((HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed) &&
          event.logicalKey == LogicalKeyboardKey.keyF) {
        _searchFocusNode.requestFocus();
      }
      if (event.logicalKey == LogicalKeyboardKey.f5) {
        _handleRefresh();
      }
      if (event.logicalKey == LogicalKeyboardKey.escape &&
          _searchController.text.isNotEmpty) {
        _clearSearch();
      }
    }
  }

  Future<void> _handleRefresh() async {
    await ref
        .read(emergencyMedicationProvider.notifier)
        .refreshMedications(widget.patientId, widget.admissionId);
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(medicationSearchProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 768;
    final isTablet = screenSize.width > 600 && screenSize.width <= 768;

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyboardShortcuts,
      child: Scaffold(
        backgroundColor: HospitalTheme.background,
        appBar: AppBar(
          title: const Text('Emergency Medications'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _handleRefresh,
              tooltip: 'Refresh (F5)',
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: SafeArea(
          child: _buildResponsiveLayout(context, isDesktop, isTablet),
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(
      BuildContext context, bool isDesktop, bool isTablet) {
    if (isDesktop) {
      return _buildDesktopSplitView(context);
    } else if (isTablet) {
      return _buildTabletView(context);
    } else {
      return _buildMobileView(context);
    }
  }

  Widget _buildDesktopSplitView(BuildContext context) {
    return Row(
      children: [
        // Master Panel (Left Side)
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: HospitalTheme.border),
              ),
            ),
            child: _buildMasterPanel(context, true),
          ),
        ),
        // Detail Panel (Right Side)
        Expanded(
          flex: 7,
          child: Container(
            color: HospitalTheme.background,
            child: _buildDetailPanel(context, true),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletView(BuildContext context) {
    final selectedMedication = ref.watch(selectedMedicationProvider);

    if (selectedMedication != null) {
      return _buildDetailPanel(context, false);
    }

    return _buildMasterPanel(context, false);
  }

  Widget _buildMobileView(BuildContext context) {
    final selectedMedication = ref.watch(selectedMedicationProvider);

    if (selectedMedication != null) {
      return _buildDetailPanel(context, false);
    }

    return _buildMasterPanel(context, false);
  }

  Widget _buildMasterPanel(BuildContext context, bool isDesktop) {
    final filteredMedications = ref.watch(filteredMedicationsProvider);

    return Column(
      children: [
        // Header and Search
        Container(
          padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: HospitalTheme.border),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isDesktop) ...[
                _buildHeaderSection(context, isDesktop),
                const SizedBox(height: 16.0),
              ] else ...[
                Text(
                  'Emergency Medications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: HospitalTheme.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8.0),
              ],
              _buildSearchBar(context, isDesktop),
            ],
          ),
        ),
        // Medications List
        Expanded(
          child: _buildMedicationsList(context, filteredMedications, isDesktop),
        ),
        // Keyboard Shortcuts (Desktop only)
        if (isDesktop) _buildKeyboardShortcuts(context),
      ],
    );
  }

  Widget _buildDetailPanel(BuildContext context, bool isDesktop) {
    final selectedMedication = ref.watch(selectedMedicationProvider);

    if (selectedMedication == null) {
      return _buildEmptyDetailPanel(context, isDesktop);
    }

    return Column(
      children: [
        // Detail Header
        Container(
          padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: HospitalTheme.border),
            ),
          ),
          child: Row(
            children: [
              if (!isDesktop)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => ref
                      .read(selectedMedicationProvider.notifier)
                      .state = null,
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medication Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: HospitalTheme.textDark,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      selectedMedication.medicationName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: HospitalTheme.textMedium,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: selectedMedication.statusColor.withOpacity(0.1),
                  borderRadius: HospitalTheme.radiusSmall,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selectedMedication.statusIcon,
                      size: 16.0,
                      color: selectedMedication.statusColor,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      selectedMedication.displayStatus,
                      style: TextStyle(
                        color: selectedMedication.statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Detail Content
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
            child:
                _buildMedicationDetails(context, selectedMedication, isDesktop),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDetailPanel(BuildContext context, bool isDesktop) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120.0,
            height: 120.0,
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medication_outlined,
              size: 60.0,
              color: HospitalTheme.textMedium,
            ),
          ),
          const SizedBox(height: 24.0),
          Text(
            'Select a Medication',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: HospitalTheme.textMedium,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Choose a medication from the list to view details',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: HospitalTheme.textLight,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, bool isDesktop) {
    return Row(
      children: [
        Container(
          width: isDesktop ? 60.0 : 50.0,
          height: isDesktop ? 60.0 : 50.0,
          decoration: BoxDecoration(
            color: HospitalTheme.emergency.withOpacity(0.1),
            borderRadius: HospitalTheme.radiusMedium,
          ),
          child: Icon(
            Icons.medical_services_outlined,
            color: HospitalTheme.emergency,
            size: isDesktop ? 30.0 : 25.0,
          ),
        ),
        SizedBox(width: isDesktop ? 16.0 : 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Emergency Medications',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: HospitalTheme.textDark,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Review and approve emergency medications',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: HospitalTheme.textMedium,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDesktop) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: isDesktop ? double.infinity : double.infinity,
      ),
      child: TextFormField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (value) => ref
            .read(medicationSearchProvider.notifier)
            .updateSearchQuery(value),
        decoration: InputDecoration(
          hintText: 'Search medications...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildMedicationsList(
      BuildContext context,
      AsyncValue<List<EmergencyMedication>> filteredMedications,
      bool isDesktop) {
    return filteredMedications.when(
      data: (medications) {
        if (medications.isEmpty) {
          return _buildEmptyState(context, isDesktop);
        }

        return ListView.builder(
          padding: EdgeInsets.all(isDesktop ? 16.0 : 8.0),
          itemCount: medications.length,
          itemBuilder: (context, index) {
            final medication = medications[index];
            return _buildMedicationListItem(context, medication, isDesktop);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          _buildErrorState(context, error.toString(), isDesktop),
    );
  }

  Widget _buildMedicationListItem(
      BuildContext context, EmergencyMedication medication, bool isDesktop) {
    final selectedMedication = ref.watch(selectedMedicationProvider);
    final isSelected = selectedMedication?.id == medication.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: isSelected ? HospitalTheme.surfaceLight : Colors.white,
        borderRadius: HospitalTheme.radiusMedium,
        border: Border.all(
          color: isSelected ? HospitalTheme.primary : HospitalTheme.border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected ? HospitalTheme.shadow : null,
      ),
      child: InkWell(
        borderRadius: HospitalTheme.radiusMedium,
        onTap: () =>
            ref.read(selectedMedicationProvider.notifier).state = medication,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      color: HospitalTheme.medical.withOpacity(0.1),
                      borderRadius: HospitalTheme.radiusSmall,
                    ),
                    child: Icon(
                      Icons.medication_outlined,
                      color: HospitalTheme.medical,
                      size: 20.0,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.medicationName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: HospitalTheme.textDark,
                            fontSize: 16.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          'Dosage: ${medication.dosage}',
                          style: TextStyle(
                            color: HospitalTheme.textMedium,
                            fontSize: 12.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: medication.statusColor.withOpacity(0.1),
                      borderRadius: HospitalTheme.radiusSmall,
                    ),
                    child: Text(
                      medication.displayStatus,
                      style: TextStyle(
                        color: medication.statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Row(
                children: [
                  Icon(Icons.person,
                      size: 14.0, color: HospitalTheme.textMedium),
                  const SizedBox(width: 4.0),
                  Text(
                    'Nurse: ${medication.nurseName}',
                    style: TextStyle(
                      color: HospitalTheme.textMedium,
                      fontSize: 12.0,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time,
                      size: 14.0, color: HospitalTheme.textMedium),
                  const SizedBox(width: 4.0),
                  Text(
                    _formatDateTime(medication.administeredAt),
                    style: TextStyle(
                      color: HospitalTheme.textMedium,
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
              if (medication.reason.isNotEmpty) ...[
                const SizedBox(height: 8.0),
                Text(
                  'Reason: ${medication.reason}',
                  style: TextStyle(
                    fontSize: 13.0,
                    color: HospitalTheme.textMedium,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicationDetails(
      BuildContext context, EmergencyMedication medication, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Medication Info Card
        HospitalTheme.buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.medication_outlined,
                      size: 20.0, color: HospitalTheme.medical),
                  const SizedBox(width: 8.0),
                  Text(
                    'Medication Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.textDark,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              _buildDetailInfoGrid([
                _DetailInfo('Medication Name', medication.medicationName),
                _DetailInfo('Dosage', medication.dosage),
                _DetailInfo('Reason', medication.reason),
                _DetailInfo('Administered At',
                    _formatDateTime(medication.administeredAt)),
                _DetailInfo('Status', medication.displayStatus),
                _DetailInfo('Nurse', medication.nurseName),
              ], isDesktop),
            ],
          ),
        ),

        const SizedBox(height: 20.0),

        // Doctor Approval Info Card
        if (medication.doctorApproval != null) ...[
          HospitalTheme.buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.approval,
                        size: 20.0, color: HospitalTheme.primary),
                    const SizedBox(width: 8.0),
                    Text(
                      'Doctor Approval',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: HospitalTheme.textDark,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                _buildDetailInfoGrid([
                  _DetailInfo(
                      'Approved',
                      medication.doctorApproval!.approved == true
                          ? 'Yes'
                          : medication.doctorApproval!.approved == false
                              ? 'No'
                              : 'Pending'),
                  _DetailInfo(
                      'Notes', medication.doctorApproval!.notes ?? 'No notes'),
                  _DetailInfo(
                      'Approval Time',
                      medication.doctorApproval!.timestamp != null
                          ? _formatDateTime(
                              medication.doctorApproval!.timestamp!)
                          : 'Not set'),
                  _DetailInfo('Doctor ID',
                      medication.doctorApproval!.doctor?.id ?? 'Not set'),
                ], isDesktop),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
        ],

        // Patient Info Card
        if (medication.patient != null) ...[
          HospitalTheme.buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 20.0, color: HospitalTheme.primary),
                    const SizedBox(width: 8.0),
                    Text(
                      'Patient Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: HospitalTheme.textDark,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                _buildDetailInfoGrid([
                  _DetailInfo('Name', medication.patient!.name),
                  _DetailInfo('Patient ID', medication.patient!.patientId),
                  _DetailInfo('Age', '${medication.patient!.age} years'),
                  _DetailInfo('Gender', medication.patient!.gender),
                  _DetailInfo('Contact', medication.patient!.contact),
                  _DetailInfo('Admission ID', medication.admissionId),
                ], isDesktop),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
        ],

        // Approval Actions Card
        HospitalTheme.buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.approval,
                      size: 20.0, color: HospitalTheme.primary),
                  const SizedBox(width: 8.0),
                  Text(
                    'Approval Actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.textDark,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              if (_processingError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: HospitalTheme.error.withOpacity(0.1),
                    borderRadius: HospitalTheme.radiusSmall,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: HospitalTheme.error),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          _processingError!,
                          style: TextStyle(color: HospitalTheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
              ],
              if (medication.isPending) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () => _handleApproval(medication, true),
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 16.0,
                                height: 16.0,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HospitalTheme.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () => _handleApproval(medication, false),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HospitalTheme.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: medication.statusColor.withOpacity(0.1),
                    borderRadius: HospitalTheme.radiusSmall,
                  ),
                  child: Row(
                    children: [
                      Icon(medication.statusIcon,
                          color: medication.statusColor),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'This medication has been ${medication.displayStatus.toLowerCase()}',
                              style: TextStyle(
                                color: medication.statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (medication.doctorApproval?.notes != null) ...[
                              const SizedBox(height: 4.0),
                              Text(
                                'Notes: ${medication.doctorApproval!.notes}',
                                style: TextStyle(
                                  color: medication.statusColor,
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailInfoGrid(List<_DetailInfo> items, bool isDesktop) {
    return Wrap(
      spacing: 16.0,
      runSpacing: 12.0,
      children:
          items.map((item) => _buildDetailInfoItem(item, isDesktop)).toList(),
    );
  }

  Widget _buildDetailInfoItem(_DetailInfo item, bool isDesktop) {
    return SizedBox(
      width: isDesktop ? 200.0 : double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: TextStyle(
              fontSize: 12.0,
              color: HospitalTheme.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 14.0,
              color: HospitalTheme.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDesktop) {
    final searchQuery = ref.watch(medicationSearchProvider);
    final isSearching = searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isDesktop ? 120.0 : 100.0,
              height: isDesktop ? 120.0 : 100.0,
              decoration: BoxDecoration(
                color: HospitalTheme.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching ? Icons.search_off : Icons.medication_outlined,
                size: isDesktop ? 60.0 : 50.0,
                color: HospitalTheme.textMedium,
              ),
            ),
            SizedBox(height: isDesktop ? 24.0 : 16.0),
            Text(
              isSearching ? 'No medications found' : 'No emergency medications',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: HospitalTheme.textMedium,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8.0),
            Text(
              isSearching
                  ? 'Try adjusting your search criteria'
                  : 'There are currently no emergency medications',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HospitalTheme.textLight,
                  ),
              textAlign: TextAlign.center,
            ),
            if (isSearching) ...[
              const SizedBox(height: 16.0),
              ElevatedButton.icon(
                onPressed: _clearSearch,
                icon: const Icon(Icons.clear),
                label: const Text('Clear Search'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, bool isDesktop) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isDesktop ? 120.0 : 100.0,
              height: isDesktop ? 120.0 : 100.0,
              decoration: BoxDecoration(
                color: HospitalTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: isDesktop ? 60.0 : 50.0,
                color: HospitalTheme.error,
              ),
            ),
            SizedBox(height: isDesktop ? 24.0 : 16.0),
            Text(
              'Error Loading Medications',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: HospitalTheme.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8.0),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HospitalTheme.textMedium,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: _handleRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardShortcuts(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      child: HospitalTheme.buildCard(
        padding: const EdgeInsets.all(12.0),
        backgroundColor: HospitalTheme.surfaceLight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Keyboard Shortcuts',
              style: TextStyle(
                color: HospitalTheme.textDark,
                fontWeight: FontWeight.w600,
                fontSize: 12.0,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              '• Ctrl+F: Focus search • F5: Refresh • Esc: Clear search',
              style: TextStyle(
                color: HospitalTheme.textMedium,
                fontSize: 10.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ACTIONS ====================

  Future<void> _handleApproval(
      EmergencyMedication medication, bool approved) async {
    setState(() {
      _isProcessing = true;
      _processingError = null;
    });

    try {
      final approval = MedicationApproval(
        medicationId: medication.id,
        approved: approved,
        notes: approved
            ? 'Emergency medication approved by doctor'
            : 'Emergency medication rejected by doctor',
      );

      final success = await EmergencyMedicationService.bulkApproveMedications(
        widget.patientId,
        widget.admissionId,
        [approval],
      );

      if (success) {
        // Refresh the data
        await ref
            .read(emergencyMedicationProvider.notifier)
            .refreshMedications(widget.patientId, widget.admissionId);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                approved
                    ? 'Medication approved successfully'
                    : 'Medication rejected successfully',
              ),
              backgroundColor:
                  approved ? HospitalTheme.success : HospitalTheme.error,
            ),
          );
        }
      } else {
        throw Exception('Failed to update medication status');
      }
    } catch (e) {
      setState(() {
        _processingError = e.toString();
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    // Convert to IST (UTC+5:30)
    final istDateTime =
        dateTime.toUtc().add(const Duration(hours: 5, minutes: 30));
    return '${istDateTime.day.toString().padLeft(2, '0')}/${istDateTime.month.toString().padLeft(2, '0')}/${istDateTime.year} ${istDateTime.hour.toString().padLeft(2, '0')}:${istDateTime.minute.toString().padLeft(2, '0')} IST';
  }
}

// ==================== HELPER CLASSES ====================

class _DetailInfo {
  final String label;
  final String value;

  const _DetailInfo(this.label, this.value);
}
