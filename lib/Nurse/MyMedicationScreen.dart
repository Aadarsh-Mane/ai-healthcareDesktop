// my_emergency_medications_screen.dart
import 'package:doctordesktop/Nurse/NurseLoginScreen.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Models [Keep all existing models unchanged]
class DoctorApproval {
  final bool approved;
  final String doctorId;
  final String notes;
  final DateTime timestamp;

  const DoctorApproval({
    required this.approved,
    required this.doctorId,
    required this.notes,
    required this.timestamp,
  });

  factory DoctorApproval.fromJson(Map<String, dynamic> json) {
    return DoctorApproval(
      approved: json['approved'] ?? false,
      doctorId: json['doctorId']?['_id'] ?? '',
      notes: json['notes'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

class ApprovalDetails {
  final String status;
  final String doctorName;
  final DateTime approvedAt;
  final String notes;
  final String priority;
  final int daysSinceApproval;

  const ApprovalDetails({
    required this.status,
    required this.doctorName,
    required this.approvedAt,
    required this.notes,
    required this.priority,
    required this.daysSinceApproval,
  });

  factory ApprovalDetails.fromJson(Map<String, dynamic> json) {
    return ApprovalDetails(
      status: json['status'] ?? '',
      doctorName: json['doctorName'] ?? '',
      approvedAt: DateTime.tryParse(json['approvedAt'] ?? '') ?? DateTime.now(),
      notes: json['notes'] ?? '',
      priority: json['priority'] ?? '',
      daysSinceApproval: json['daysSinceApproval'] ?? 0,
    );
  }
}

class NurseInfo {
  final String name;
  final String employeeId;
  final DateTime administeredAt;

  const NurseInfo({
    required this.name,
    required this.employeeId,
    required this.administeredAt,
  });

  factory NurseInfo.fromJson(Map<String, dynamic> json) {
    return NurseInfo(
      name: json['name'] ?? '',
      employeeId: json['employeeId'] ?? '',
      administeredAt:
          DateTime.tryParse(json['administeredAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class PatientDetails {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String contact;

  const PatientDetails({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.contact,
  });

  factory PatientDetails.fromJson(Map<String, dynamic> json) {
    return PatientDetails(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      contact: json['contact'] ?? '',
    );
  }
}

class TimeInfo {
  final DateTime administeredAt;
  final int daysSinceAdministration;
  final int hoursSinceAdministration;
  final bool isRecent;

  const TimeInfo({
    required this.administeredAt,
    required this.daysSinceAdministration,
    required this.hoursSinceAdministration,
    required this.isRecent,
  });

  factory TimeInfo.fromJson(Map<String, dynamic> json) {
    return TimeInfo(
      administeredAt:
          DateTime.tryParse(json['administeredAt'] ?? '') ?? DateTime.now(),
      daysSinceAdministration: json['daysSinceAdministration'] ?? 0,
      hoursSinceAdministration: json['hoursSinceAdministration'] ?? 0,
      isRecent: json['isRecent'] ?? false,
    );
  }
}

class EmergencyMedication {
  final String id;
  final String patientId;
  final String admissionId;
  final String medicationName;
  final String dosage;
  final String administeredBy;
  final String nurseName;
  final String reason;
  final String status;
  final DateTime administeredAt;
  final String doctorApprovalStatus;
  final ApprovalDetails? approvalDetails;
  final DoctorApproval? doctorApproval;
  final NurseInfo nurseInfo;
  final PatientDetails patientDetails;
  final TimeInfo timeInfo;
  final String? justification;
  final DateTime? reviewedAt;

  const EmergencyMedication({
    required this.id,
    required this.patientId,
    required this.admissionId,
    required this.medicationName,
    required this.dosage,
    required this.administeredBy,
    required this.nurseName,
    required this.reason,
    required this.status,
    required this.administeredAt,
    required this.doctorApprovalStatus,
    this.approvalDetails,
    this.doctorApproval,
    required this.nurseInfo,
    required this.patientDetails,
    required this.timeInfo,
    this.justification,
    this.reviewedAt,
  });

  factory EmergencyMedication.fromJson(Map<String, dynamic> json) {
    return EmergencyMedication(
      id: json['_id'] ?? '',
      patientId: json['patientId'] ?? '',
      admissionId: json['admissionId'] ?? '',
      medicationName: json['medicationName'] ?? '',
      dosage: json['dosage'] ?? '',
      administeredBy: json['administeredBy'] ?? '',
      nurseName: json['nurseName'] ?? '',
      reason: json['reason'] ?? '',
      status: json['status'] ?? '',
      administeredAt:
          DateTime.tryParse(json['administeredAt'] ?? '') ?? DateTime.now(),
      doctorApprovalStatus: json['doctorApprovalStatus'] ?? '',
      approvalDetails: json['approvalDetails'] != null
          ? ApprovalDetails.fromJson(json['approvalDetails'])
          : null,
      doctorApproval: json['doctorApproval'] != null
          ? DoctorApproval.fromJson(json['doctorApproval'])
          : null,
      nurseInfo: NurseInfo.fromJson(json['nurseInfo'] ?? {}),
      patientDetails: PatientDetails.fromJson(json['patientDetails'] ?? {}),
      timeInfo: TimeInfo.fromJson(json['timeInfo'] ?? {}),
      justification: json['justification'],
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'])
          : null,
    );
  }
}

class Pagination {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final bool hasNextPage;
  final bool hasPrevPage;

  const Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalItems: json['totalItems'] ?? 0,
      itemsPerPage: json['itemsPerPage'] ?? 10,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPrevPage: json['hasPrevPage'] ?? false,
    );
  }
}

class EmergencyMedicationsResponse {
  final bool success;
  final String message;
  final List<EmergencyMedication> medications;
  final Pagination pagination;
  final DateTime timestamp;

  const EmergencyMedicationsResponse({
    required this.success,
    required this.message,
    required this.medications,
    required this.pagination,
    required this.timestamp,
  });

  factory EmergencyMedicationsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final medicationsList = data['medications'] as List<dynamic>? ?? [];

    return EmergencyMedicationsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      medications:
          medicationsList.map((m) => EmergencyMedication.fromJson(m)).toList(),
      pagination: Pagination.fromJson(data['pagination'] ?? {}),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

// Providers [Keep all existing providers unchanged]
final emergencyMedicationsProvider = StateNotifierProvider<
    EmergencyMedicationsNotifier, AsyncValue<List<EmergencyMedication>>>((ref) {
  return EmergencyMedicationsNotifier(ref.read(httpClientProvider));
});

class EmergencyMedicationsNotifier
    extends StateNotifier<AsyncValue<List<EmergencyMedication>>> {
  final http.Client _httpClient;

  EmergencyMedicationsNotifier(this._httpClient)
      : super(const AsyncValue.loading()) {
    fetchEmergencyMedications();
  }

  Future<void> fetchEmergencyMedications() async {
    state = const AsyncValue.loading();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('nurse_token') ?? '';

      if (token.isEmpty) {
        state = AsyncValue.error(
            'Authentication token not found', StackTrace.current);
        return;
      }

      final url = Uri.parse('$KVM_URL/nurse/getMyEmergencyMedications');
      final response = await _httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final medicationsResponse =
            EmergencyMedicationsResponse.fromJson(responseData);

        if (medicationsResponse.success) {
          state = AsyncValue.data(medicationsResponse.medications);
        } else {
          state =
              AsyncValue.error(medicationsResponse.message, StackTrace.current);
        }
      } else if (response.statusCode == 401) {
        state = AsyncValue.error(
            'Authentication failed. Please login again.', StackTrace.current);
      } else {
        String errorMessage = 'Failed to fetch emergency medications';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // Use default error message
        }
        state = AsyncValue.error(errorMessage, StackTrace.current);
      }
    } catch (e, stackTrace) {
      String errorMessage = 'An unexpected error occurred';

      if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Connection timeout. Please check your network';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Network error. Please check your connection';
      }

      state = AsyncValue.error(errorMessage, stackTrace);
    }
  }

  Future<void> refreshMedications() async {
    await fetchEmergencyMedications();
  }
}

final medicationsSearchProvider =
    StateNotifierProvider<MedicationsSearchNotifier, String>((ref) {
  return MedicationsSearchNotifier();
});

class MedicationsSearchNotifier extends StateNotifier<String> {
  MedicationsSearchNotifier() : super('');

  void updateSearchQuery(String query) {
    state = query;
  }

  void clearSearch() {
    state = '';
  }
}

final selectedMedicationProvider =
    StateNotifierProvider<SelectedMedicationNotifier, EmergencyMedication?>(
        (ref) {
  return SelectedMedicationNotifier();
});

class SelectedMedicationNotifier extends StateNotifier<EmergencyMedication?> {
  SelectedMedicationNotifier() : super(null);

  void selectMedication(EmergencyMedication medication) {
    state = medication;
  }

  void clearSelection() {
    state = null;
  }
}

final filteredMedicationsProvider =
    Provider<AsyncValue<List<EmergencyMedication>>>((ref) {
  final medicationsAsync = ref.watch(emergencyMedicationsProvider);
  final searchQuery = ref.watch(medicationsSearchProvider);

  return medicationsAsync.when(
    data: (medications) {
      if (searchQuery.isEmpty) {
        return AsyncValue.data(medications);
      }

      final filtered = medications.where((medication) {
        final query = searchQuery.toLowerCase();
        return medication.medicationName.toLowerCase().contains(query) ||
            medication.patientDetails.name.toLowerCase().contains(query) ||
            medication.patientId.toLowerCase().contains(query) ||
            medication.status.toLowerCase().contains(query) ||
            medication.doctorApprovalStatus.toLowerCase().contains(query);
      }).toList();

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// HTTP Client Provider
final httpClientProvider = Provider<http.Client>((ref) => http.Client());

// Updated Screen with Master-Detail Split View
class MyEmergencyMedicationsScreen extends ConsumerStatefulWidget {
  const MyEmergencyMedicationsScreen({super.key});

  @override
  ConsumerState<MyEmergencyMedicationsScreen> createState() =>
      _MyEmergencyMedicationsScreenState();
}

class _MyEmergencyMedicationsScreenState
    extends ConsumerState<MyEmergencyMedicationsScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyboardShortcuts(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Ctrl/Cmd + F to focus search
      if ((HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed) &&
          event.logicalKey == LogicalKeyboardKey.keyF) {
        _searchFocusNode.requestFocus();
      }
      // F5 to refresh
      if (event.logicalKey == LogicalKeyboardKey.f5) {
        _handleRefresh();
      }
      // Escape to clear search
      if (event.logicalKey == LogicalKeyboardKey.escape &&
          _searchController.text.isNotEmpty) {
        _clearSearch();
      }
    }
  }

  Future<void> _handleRefresh() async {
    await ref.read(emergencyMedicationsProvider.notifier).refreshMedications();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(medicationsSearchProvider.notifier).clearSearch();
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
        appBar: HospitalTheme.buildAppBar(
          context: context,
          title: 'My Emergency Medications',
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
          child: _buildMedicationsList(
              context, filteredMedications, isDesktop, true),
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
                      .clearSelection(),
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
            ],
          ),
        ),
        // Detail Content
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
            child: _buildMedicationCard(
                context, selectedMedication, isDesktop, false),
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
              Icons.emergency_outlined,
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
            'Choose a medication from the list to view its details',
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
            Icons.emergency,
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
                'My Emergency Medications',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: HospitalTheme.textDark,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Track emergency medications you have administered',
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
            .read(medicationsSearchProvider.notifier)
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
      bool isDesktop,
      bool isMasterView) {
    return filteredMedications.when(
      data: (medications) {
        if (medications.isEmpty) {
          return _buildEmptyState(context, isDesktop);
        }

        if (isMasterView) {
          return _buildMedicationsListView(context, medications, isDesktop);
        } else {
          return _buildMedicationsGrid(context, medications, isDesktop);
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          _buildErrorState(context, error.toString(), isDesktop),
    );
  }

  Widget _buildMedicationsListView(BuildContext context,
      List<EmergencyMedication> medications, bool isDesktop) {
    return ListView.builder(
      padding: EdgeInsets.all(isDesktop ? 16.0 : 8.0),
      itemCount: medications.length,
      itemBuilder: (context, index) {
        final medication = medications[index];
        return _buildMedicationListItem(context, medication, isDesktop);
      },
    );
  }

  Widget _buildMedicationListItem(
      BuildContext context, EmergencyMedication medication, bool isDesktop) {
    final selectedMedication = ref.watch(selectedMedicationProvider);
    final isSelected = selectedMedication?.id == medication.id;

    Color statusColor;
    IconData statusIcon;

    switch (medication.status.toLowerCase()) {
      case 'approved':
        statusColor = HospitalTheme.success;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = HospitalTheme.error;
        statusIcon = Icons.cancel;
        break;
      case 'pending':
      default:
        statusColor = HospitalTheme.warning;
        statusIcon = Icons.pending;
        break;
    }

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
        onTap: () => ref
            .read(selectedMedicationProvider.notifier)
            .selectMedication(medication),
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
                      color: HospitalTheme.emergency.withOpacity(0.1),
                      borderRadius: HospitalTheme.radiusSmall,
                    ),
                    child: Icon(
                      Icons.emergency,
                      color: HospitalTheme.emergency,
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
                            fontSize: 14.0,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          medication.patientDetails.name,
                          style: TextStyle(
                            color: HospitalTheme.textMedium,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: HospitalTheme.radiusSmall,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12.0, color: statusColor),
                        const SizedBox(width: 4.0),
                        Text(
                          medication.status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Row(
                children: [
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
                  const Spacer(),
                  Text(
                    medication.dosage,
                    style: TextStyle(
                      color: HospitalTheme.textMedium,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicationsGrid(BuildContext context,
      List<EmergencyMedication> medications, bool isDesktop) {
    return ListView.separated(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      itemCount: medications.length,
      separatorBuilder: (context, index) =>
          SizedBox(height: isDesktop ? 16.0 : 12.0),
      itemBuilder: (context, index) {
        final medication = medications[index];
        return _buildMedicationCard(context, medication, isDesktop, true);
      },
    );
  }

  Widget _buildMedicationCard(BuildContext context,
      EmergencyMedication medication, bool isDesktop, bool isGridView) {
    Color statusColor;
    IconData statusIcon;

    switch (medication.status.toLowerCase()) {
      case 'approved':
        statusColor = HospitalTheme.success;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = HospitalTheme.error;
        statusIcon = Icons.cancel;
        break;
      case 'pending':
      default:
        statusColor = HospitalTheme.warning;
        statusIcon = Icons.pending;
        break;
    }

    Color approvalColor;
    IconData approvalIcon;

    switch (medication.doctorApprovalStatus.toLowerCase()) {
      case 'approved by doctor':
        approvalColor = HospitalTheme.success;
        approvalIcon = Icons.verified;
        break;
      case 'rejected by doctor':
        approvalColor = HospitalTheme.error;
        approvalIcon = Icons.gpp_bad;
        break;
      case 'pending review':
      default:
        approvalColor = HospitalTheme.info;
        approvalIcon = Icons.hourglass_empty;
        break;
    }

    Widget cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Status
        Row(
          children: [
            Container(
              width: isDesktop ? 50.0 : 45.0,
              height: isDesktop ? 50.0 : 45.0,
              decoration: BoxDecoration(
                color: HospitalTheme.emergency.withOpacity(0.1),
                borderRadius: HospitalTheme.radiusMedium,
              ),
              child: Icon(
                Icons.emergency,
                color: HospitalTheme.emergency,
                size: isDesktop ? 25.0 : 22.0,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medication.medicationName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.textDark,
                        ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    medication.dosage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: HospitalTheme.textMedium,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: HospitalTheme.radiusSmall,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14.0, color: statusColor),
                      const SizedBox(width: 4.0),
                      Text(
                        medication.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4.0),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: approvalColor.withOpacity(0.1),
                    borderRadius: HospitalTheme.radiusSmall,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(approvalIcon, size: 12.0, color: approvalColor),
                      const SizedBox(width: 4.0),
                      Text(
                        medication.doctorApprovalStatus
                            .replaceAll('by Doctor', ''),
                        style: TextStyle(
                          color: approvalColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // Patient Information
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: HospitalTheme.surfaceLight,
            borderRadius: HospitalTheme.radiusSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person,
                      size: 16.0, color: HospitalTheme.textMedium),
                  const SizedBox(width: 8.0),
                  Text(
                    'Patient Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      'Name',
                      medication.patientDetails.name,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoRow(
                      'Patient ID',
                      medication.patientId,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4.0),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      'Age',
                      '${medication.patientDetails.age} years',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoRow(
                      'Gender',
                      medication.patientDetails.gender,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16.0),

        // Reason
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description,
                    size: 16.0, color: HospitalTheme.textMedium),
                const SizedBox(width: 8.0),
                Text(
                  'Emergency Reason',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                border: Border.all(color: HospitalTheme.border),
                borderRadius: HospitalTheme.radiusSmall,
              ),
              child: Text(
                medication.reason,
                style: TextStyle(
                  color: HospitalTheme.textMedium,
                  fontSize: 13.0,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // Administration Details
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: HospitalTheme.info.withOpacity(0.05),
            borderRadius: HospitalTheme.radiusSmall,
            border: Border.all(color: HospitalTheme.info.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, size: 16.0, color: HospitalTheme.info),
                  const SizedBox(width: 8.0),
                  Text(
                    'Administration Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      'Administered At',
                      _formatDateTime(medication.administeredAt),
                    ),
                  ),
                  Expanded(
                    child: _buildInfoRow(
                      'Time Ago',
                      medication.timeInfo.isRecent
                          ? '${medication.timeInfo.hoursSinceAdministration}h ago'
                          : '${medication.timeInfo.daysSinceAdministration}d ago',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4.0),
              _buildInfoRow(
                'Nurse',
                medication.nurseName,
              ),
            ],
          ),
        ),

        // Approval Details (if available)
        if (medication.approvalDetails != null) ...[
          const SizedBox(height: 16.0),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: HospitalTheme.success.withOpacity(0.05),
              borderRadius: HospitalTheme.radiusSmall,
              border: Border.all(color: HospitalTheme.success.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_user,
                        size: 16.0, color: HospitalTheme.success),
                    const SizedBox(width: 8.0),
                    Text(
                      'Doctor Approval',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        'Doctor',
                        medication.approvalDetails!.doctorName,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoRow(
                        'Priority',
                        medication.approvalDetails!.priority,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                _buildInfoRow(
                  'Approved At',
                  _formatDateTime(medication.approvalDetails!.approvedAt),
                ),
                if (medication.approvalDetails!.notes.isNotEmpty) ...[
                  const SizedBox(height: 8.0),
                  Text(
                    'Notes:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: HospitalTheme.textDark,
                      fontSize: 12.0,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    medication.approvalDetails!.notes,
                    style: TextStyle(
                      color: HospitalTheme.textMedium,
                      fontSize: 12.0,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        // Justification (if available)
        if (medication.justification != null &&
            medication.justification!.isNotEmpty) ...[
          const SizedBox(height: 16.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.gavel,
                      size: 16.0, color: HospitalTheme.textMedium),
                  const SizedBox(width: 8.0),
                  Text(
                    'Justification',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: HospitalTheme.border),
                  borderRadius: HospitalTheme.radiusSmall,
                  color: HospitalTheme.surfaceLight,
                ),
                child: Text(
                  medication.justification!,
                  style: TextStyle(
                    color: HospitalTheme.textMedium,
                    fontSize: 13.0,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );

    if (isGridView) {
      return HospitalTheme.buildCard(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 20.0 : 16.0),
          child: cardContent,
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(0),
        child: cardContent,
      );
    }
  }

  Widget _buildEmptyState(BuildContext context, bool isDesktop) {
    final searchQuery = ref.watch(medicationsSearchProvider);
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
                isSearching ? Icons.search_off : Icons.emergency_outlined,
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
                  : 'You haven\'t administered any emergency medications yet',
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.0,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12.0,
                color: HospitalTheme.textMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.0,
                color: HospitalTheme.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Same day - show time
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
