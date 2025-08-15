// active_patients_screen.dart
import 'package:doctordesktop/Nurse/EmergencyMedicationScreen.dart';
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
class Doctor {
  final String id;
  final String name;
  final String usertype;

  const Doctor({
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

  const Section({
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

class CurrentAdmission {
  final String id;
  final DateTime admissionDate;
  final Doctor doctor;
  final Section section;
  final int bedNumber;
  final String status;
  final int pendingMedications;
  final int pendingIVFluids;
  final int pendingProcedures;

  const CurrentAdmission({
    required this.id,
    required this.admissionDate,
    required this.doctor,
    required this.section,
    required this.bedNumber,
    required this.status,
    required this.pendingMedications,
    required this.pendingIVFluids,
    required this.pendingProcedures,
  });

  factory CurrentAdmission.fromJson(Map<String, dynamic> json) {
    return CurrentAdmission(
      id: json['_id'] ?? '',
      admissionDate:
          DateTime.tryParse(json['admissionDate'] ?? '') ?? DateTime.now(),
      doctor: Doctor.fromJson(json['doctor'] ?? {}),
      section: Section.fromJson(json['section'] ?? {}),
      bedNumber: json['bedNumber'] ?? 0,
      status: json['status'] ?? '',
      pendingMedications: json['pendingMedications'] ?? 0,
      pendingIVFluids: json['pendingIVFluids'] ?? 0,
      pendingProcedures: json['pendingProcedures'] ?? 0,
    );
  }
}

class ActivePatient {
  final String id;
  final String patientId;
  final String name;
  final int age;
  final String gender;
  final String contact;
  final String imageUrl;
  final double pendingAmount;
  final CurrentAdmission currentAdmission;
  final int totalAdmissions;

  const ActivePatient({
    required this.id,
    required this.patientId,
    required this.name,
    required this.age,
    required this.gender,
    required this.contact,
    required this.imageUrl,
    required this.pendingAmount,
    required this.currentAdmission,
    required this.totalAdmissions,
  });

  factory ActivePatient.fromJson(Map<String, dynamic> json) {
    return ActivePatient(
      id: json['_id'] ?? '',
      patientId: json['patientId'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      contact: json['contact'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      pendingAmount: (json['pendingAmount'] ?? 0).toDouble(),
      currentAdmission:
          CurrentAdmission.fromJson(json['currentAdmission'] ?? {}),
      totalAdmissions: json['totalAdmissions'] ?? 0,
    );
  }
}

class ActivePatientsResponse {
  final bool success;
  final String message;
  final List<ActivePatient> patients;
  final int totalCount;
  final DateTime timestamp;

  const ActivePatientsResponse({
    required this.success,
    required this.message,
    required this.patients,
    required this.totalCount,
    required this.timestamp,
  });

  factory ActivePatientsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final patientsList = data['patients'] as List<dynamic>? ?? [];

    return ActivePatientsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      patients: patientsList.map((p) => ActivePatient.fromJson(p)).toList(),
      totalCount: data['totalCount'] ?? 0,
      timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

// Providers [Keep existing providers and add new ones]
final activePatientsProvider = StateNotifierProvider<ActivePatientsNotifier,
    AsyncValue<List<ActivePatient>>>((ref) {
  return ActivePatientsNotifier(ref.read(httpClientProvider));
});

class ActivePatientsNotifier
    extends StateNotifier<AsyncValue<List<ActivePatient>>> {
  final http.Client _httpClient;

  ActivePatientsNotifier(this._httpClient) : super(const AsyncValue.loading()) {
    fetchActivePatients();
  }

  Future<void> fetchActivePatients() async {
    state = const AsyncValue.loading();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('nurse_token') ?? '';

      if (token.isEmpty) {
        state = AsyncValue.error(
            'Authentication token not found', StackTrace.current);
        return;
      }

      final url = Uri.parse('$KVM_URL/nurse/getAllActivePatients');
      final response = await _httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final patientsResponse = ActivePatientsResponse.fromJson(responseData);

        if (patientsResponse.success) {
          state = AsyncValue.data(patientsResponse.patients);
        } else {
          state =
              AsyncValue.error(patientsResponse.message, StackTrace.current);
        }
      } else if (response.statusCode == 401) {
        state = AsyncValue.error(
            'Authentication failed. Please login again.', StackTrace.current);
      } else {
        String errorMessage = 'Failed to fetch patients';
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

  Future<void> refreshPatients() async {
    await fetchActivePatients();
  }
}

final patientsSearchProvider =
    StateNotifierProvider<PatientsSearchNotifier, String>((ref) {
  return PatientsSearchNotifier();
});

class PatientsSearchNotifier extends StateNotifier<String> {
  PatientsSearchNotifier() : super('');

  void updateSearchQuery(String query) {
    state = query;
  }

  void clearSearch() {
    state = '';
  }
}

final selectedPatientProvider =
    StateNotifierProvider<SelectedPatientNotifier, ActivePatient?>((ref) {
  return SelectedPatientNotifier();
});

class SelectedPatientNotifier extends StateNotifier<ActivePatient?> {
  SelectedPatientNotifier() : super(null);

  void selectPatient(ActivePatient patient) {
    state = patient;
  }

  void clearSelection() {
    state = null;
  }
}

final filteredPatientsProvider =
    Provider<AsyncValue<List<ActivePatient>>>((ref) {
  final patientsAsync = ref.watch(activePatientsProvider);
  final searchQuery = ref.watch(patientsSearchProvider);

  return patientsAsync.when(
    data: (patients) {
      if (searchQuery.isEmpty) {
        return AsyncValue.data(patients);
      }

      final filtered = patients.where((patient) {
        final query = searchQuery.toLowerCase();
        return patient.name.toLowerCase().contains(query) ||
            patient.patientId.toLowerCase().contains(query) ||
            patient.contact.contains(query) ||
            patient.currentAdmission.doctor.name
                .toLowerCase()
                .contains(query) ||
            patient.currentAdmission.section.name.toLowerCase().contains(query);
      }).toList();

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// HTTP Client Provider
final httpClientProvider = Provider<http.Client>((ref) => http.Client());

// Main Screen with Master-Detail Split View
class ActivePatientsScreen extends ConsumerStatefulWidget {
  const ActivePatientsScreen({super.key});

  @override
  ConsumerState<ActivePatientsScreen> createState() =>
      _ActivePatientsScreenState();
}

class _ActivePatientsScreenState extends ConsumerState<ActivePatientsScreen> {
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
    await ref.read(activePatientsProvider.notifier).refreshPatients();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(patientsSearchProvider.notifier).clearSearch();
  }

  void _navigateToEmergencyMedication(ActivePatient patient) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmergencyMedicationScreen(
          patientId: patient.patientId,
          admissionId: patient.currentAdmission.id,
          patientName: patient.name,
        ),
      ),
    );
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
          title: const Text('Active Patients'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
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
    final selectedPatient = ref.watch(selectedPatientProvider);

    if (selectedPatient != null) {
      return _buildDetailPanel(context, false);
    }

    return _buildMasterPanel(context, false);
  }

  Widget _buildMobileView(BuildContext context) {
    final selectedPatient = ref.watch(selectedPatientProvider);

    if (selectedPatient != null) {
      return _buildDetailPanel(context, false);
    }

    return _buildMasterPanel(context, false);
  }

  Widget _buildMasterPanel(BuildContext context, bool isDesktop) {
    final filteredPatients = ref.watch(filteredPatientsProvider);

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
                  'Active Patients',
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
        // Patients List
        Expanded(
          child: _buildPatientsList(context, filteredPatients, isDesktop, true),
        ),
        // Keyboard Shortcuts (Desktop only)
        if (isDesktop) _buildKeyboardShortcuts(context),
      ],
    );
  }

  Widget _buildDetailPanel(BuildContext context, bool isDesktop) {
    final selectedPatient = ref.watch(selectedPatientProvider);

    if (selectedPatient == null) {
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
                      .read(selectedPatientProvider.notifier)
                      .clearSelection(),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: HospitalTheme.textDark,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      selectedPatient.name,
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
            child: _buildPatientDetails(context, selectedPatient, isDesktop),
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
              Icons.people_outline,
              size: 60.0,
              color: HospitalTheme.textMedium,
            ),
          ),
          const SizedBox(height: 24.0),
          Text(
            'Select a Patient',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: HospitalTheme.textMedium,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Choose a patient from the list to view their details',
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
            color: HospitalTheme.primary.withOpacity(0.1),
            borderRadius: HospitalTheme.radiusMedium,
          ),
          child: Icon(
            Icons.people_outline,
            color: HospitalTheme.primary,
            size: isDesktop ? 30.0 : 25.0,
          ),
        ),
        SizedBox(width: isDesktop ? 16.0 : 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active Patients',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: HospitalTheme.textDark,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Monitor and manage currently admitted patients',
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
        onChanged: (value) =>
            ref.read(patientsSearchProvider.notifier).updateSearchQuery(value),
        decoration: InputDecoration(
          hintText: 'Search patients...',
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

  Widget _buildPatientsList(
      BuildContext context,
      AsyncValue<List<ActivePatient>> filteredPatients,
      bool isDesktop,
      bool isMasterView) {
    return filteredPatients.when(
      data: (patients) {
        if (patients.isEmpty) {
          return _buildEmptyState(context, isDesktop);
        }

        if (isMasterView) {
          return _buildPatientsListView(context, patients, isDesktop);
        } else {
          return _buildPatientsGrid(context, patients, isDesktop);
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          _buildErrorState(context, error.toString(), isDesktop),
    );
  }

  Widget _buildPatientsListView(
      BuildContext context, List<ActivePatient> patients, bool isDesktop) {
    return ListView.builder(
      padding: EdgeInsets.all(isDesktop ? 16.0 : 8.0),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final patient = patients[index];
        return _buildPatientListItem(context, patient, isDesktop);
      },
    );
  }

  Widget _buildPatientListItem(
      BuildContext context, ActivePatient patient, bool isDesktop) {
    final selectedPatient = ref.watch(selectedPatientProvider);
    final isSelected = selectedPatient?.id == patient.id;
    final admission = patient.currentAdmission;
    final hasPendingTasks = admission.pendingMedications > 0 ||
        admission.pendingIVFluids > 0 ||
        admission.pendingProcedures > 0;

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
            ref.read(selectedPatientProvider.notifier).selectPatient(patient),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25.0,
                    backgroundColor: HospitalTheme.primary.withOpacity(0.1),
                    backgroundImage: patient.imageUrl.trim().isNotEmpty &&
                            patient.imageUrl != ' '
                        ? NetworkImage(patient.imageUrl)
                        : null,
                    child: patient.imageUrl.trim().isEmpty ||
                            patient.imageUrl == ' '
                        ? Icon(
                            Icons.person,
                            size: 25.0,
                            color: HospitalTheme.primary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: HospitalTheme.textDark,
                            fontSize: 16.0,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          'ID: ${patient.patientId}',
                          style: TextStyle(
                            color: HospitalTheme.textMedium,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Bed ${admission.bedNumber}',
                        style: TextStyle(
                          color: HospitalTheme.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.0,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        admission.section.name,
                        style: TextStyle(
                          color: HospitalTheme.textMedium,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
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
                    '${patient.age}y, ${patient.gender}',
                    style: TextStyle(
                      color: HospitalTheme.textMedium,
                      fontSize: 12.0,
                    ),
                  ),
                  const Spacer(),
                  if (hasPendingTasks)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: HospitalTheme.warning.withOpacity(0.1),
                        borderRadius: HospitalTheme.radiusSmall,
                      ),
                      child: Text(
                        'Has Pending Tasks',
                        style: TextStyle(
                          color: HospitalTheme.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 10.0,
                        ),
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

  Widget _buildPatientsGrid(
      BuildContext context, List<ActivePatient> patients, bool isDesktop) {
    final crossAxisCount =
        isDesktop ? (MediaQuery.of(context).size.width > 1200 ? 2 : 1) : 1;

    return GridView.builder(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: isDesktop ? 1.2 : 1.0,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final patient = patients[index];
        return _buildPatientCard(context, patient, isDesktop);
      },
    );
  }

  Widget _buildPatientDetails(
      BuildContext context, ActivePatient patient, bool isDesktop) {
    final admission = patient.currentAdmission;
    final hasPendingTasks = admission.pendingMedications > 0 ||
        admission.pendingIVFluids > 0 ||
        admission.pendingProcedures > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Patient Header Card
        HospitalTheme.buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: isDesktop ? 40.0 : 35.0,
                    backgroundColor: HospitalTheme.primary.withOpacity(0.1),
                    backgroundImage: patient.imageUrl.trim().isNotEmpty &&
                            patient.imageUrl != ' '
                        ? NetworkImage(patient.imageUrl)
                        : null,
                    child: patient.imageUrl.trim().isEmpty ||
                            patient.imageUrl == ' '
                        ? Icon(
                            Icons.person,
                            size: isDesktop ? 40.0 : 35.0,
                            color: HospitalTheme.primary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: HospitalTheme.textDark,
                                  ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'Patient ID: ${patient.patientId}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: HospitalTheme.textMedium,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (hasPendingTasks)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: HospitalTheme.warning.withOpacity(0.1),
                        borderRadius: HospitalTheme.radiusSmall,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pending_actions,
                              size: 16.0, color: HospitalTheme.warning),
                          const SizedBox(width: 8.0),
                          Text(
                            'Pending Tasks',
                            style: TextStyle(
                              color: HospitalTheme.warning,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16.0),
              _buildDetailInfoGrid([
                _DetailInfo('Age', '${patient.age} years'),
                _DetailInfo('Gender', patient.gender),
                _DetailInfo('Contact', patient.contact),
                _DetailInfo(
                    'Total Admissions', patient.totalAdmissions.toString()),
                _DetailInfo('Pending Amount',
                    '₹${patient.pendingAmount.toStringAsFixed(2)}'),
                _DetailInfo('Current Status', admission.status),
              ], isDesktop),
            ],
          ),
        ),

        const SizedBox(height: 20.0),

        // Current Admission Card
        HospitalTheme.buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_hospital,
                      size: 20.0, color: HospitalTheme.primary),
                  const SizedBox(width: 8.0),
                  Text(
                    'Current Admission',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.textDark,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              _buildDetailInfoGrid([
                _DetailInfo('Admission ID', admission.id),
                _DetailInfo(
                    'Admission Date', _formatDate(admission.admissionDate)),
                _DetailInfo('Doctor', 'Dr. ${admission.doctor.name}'),
                _DetailInfo('Ward/Section', admission.section.name),
                _DetailInfo('Bed Number', 'Bed ${admission.bedNumber}'),
                _DetailInfo('Section Type', admission.section.type),
              ], isDesktop),
            ],
          ),
        ),

        const SizedBox(height: 20.0),

        // Pending Tasks Card
        if (hasPendingTasks) ...[
          HospitalTheme.buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.pending_actions,
                        size: 20.0, color: HospitalTheme.warning),
                    const SizedBox(width: 8.0),
                    Text(
                      'Pending Tasks',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: HospitalTheme.textDark,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    if (admission.pendingMedications > 0) ...[
                      Expanded(
                        child: _buildTaskCard(
                          'Medications',
                          admission.pendingMedications,
                          Icons.medication_outlined,
                          HospitalTheme.medical,
                        ),
                      ),
                    ],
                    if (admission.pendingMedications > 0 &&
                        (admission.pendingIVFluids > 0 ||
                            admission.pendingProcedures > 0))
                      const SizedBox(width: 12.0),
                    if (admission.pendingIVFluids > 0) ...[
                      Expanded(
                        child: _buildTaskCard(
                          'IV Fluids',
                          admission.pendingIVFluids,
                          Icons.water_drop_outlined,
                          HospitalTheme.info,
                        ),
                      ),
                    ],
                    if (admission.pendingIVFluids > 0 &&
                        admission.pendingProcedures > 0)
                      const SizedBox(width: 12.0),
                    if (admission.pendingProcedures > 0) ...[
                      Expanded(
                        child: _buildTaskCard(
                          'Procedures',
                          admission.pendingProcedures,
                          Icons.healing_outlined,
                          HospitalTheme.laboratory,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
        ],

        // Action Buttons Card
        HospitalTheme.buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.touch_app,
                      size: 20.0, color: HospitalTheme.primary),
                  const SizedBox(width: 8.0),
                  Text(
                    'Actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.textDark,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToEmergencyMedication(patient),
                      icon: const Icon(Icons.emergency),
                      label: const Text('Emergency Medication'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HospitalTheme.emergency,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to patient profile
                      },
                      icon: const Icon(Icons.person_outline),
                      label: const Text('View Profile'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to treatment tasks
                  },
                  icon: const Icon(Icons.assignment_outlined),
                  label: const Text('View Treatment Tasks'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: HospitalTheme.radiusSmall,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.0),
          const SizedBox(height: 8.0),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.0,
              color: HospitalTheme.textMedium,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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

  Widget _buildPatientCard(
      BuildContext context, ActivePatient patient, bool isDesktop) {
    final admission = patient.currentAdmission;
    final hasPendingTasks = admission.pendingMedications > 0 ||
        admission.pendingIVFluids > 0 ||
        admission.pendingProcedures > 0;

    return HospitalTheme.buildCard(
      child: InkWell(
        onTap: () => _navigateToEmergencyMedication(patient),
        borderRadius: HospitalTheme.radiusMedium,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Patient Header
              Row(
                children: [
                  CircleAvatar(
                    radius: isDesktop ? 25.0 : 22.0,
                    backgroundColor: HospitalTheme.primary.withOpacity(0.1),
                    backgroundImage: patient.imageUrl.trim().isNotEmpty &&
                            patient.imageUrl != ' '
                        ? NetworkImage(patient.imageUrl)
                        : null,
                    child: patient.imageUrl.trim().isEmpty ||
                            patient.imageUrl == ' '
                        ? Icon(
                            Icons.person,
                            size: isDesktop ? 25.0 : 22.0,
                            color: HospitalTheme.primary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          patient.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: HospitalTheme.textDark,
                            fontSize: isDesktop ? 18.0 : 14.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          'ID: ${patient.patientId}',
                          style: TextStyle(
                            color: HospitalTheme.textMedium,
                            fontWeight: FontWeight.w500,
                            fontSize: isDesktop ? 16.0 : 11.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (hasPendingTasks)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: HospitalTheme.warning.withOpacity(0.1),
                        borderRadius: HospitalTheme.radiusSmall,
                      ),
                      child: Text(
                        'Pending',
                        style: TextStyle(
                          color: HospitalTheme.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.0,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12.0),

              // Patient Details
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.cake_outlined,
                      label: 'Age',
                      value: '${patient.age}y',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      icon: patient.gender.toLowerCase() == 'male'
                          ? Icons.male
                          : patient.gender.toLowerCase() == 'female'
                              ? Icons.female
                              : Icons.people,
                      label: 'Gender',
                      value: patient.gender.substring(0, 1),
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: patient.contact.length > 8
                          ? '${patient.contact.substring(0, 8)}...'
                          : patient.contact,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12.0),

              // Admission Details
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: HospitalTheme.surfaceLight,
                  borderRadius: HospitalTheme.radiusSmall,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildAdmissionInfo(
                            icon: Icons.medical_services_outlined,
                            label: 'Doctor',
                            value: 'Dr. ${admission.doctor.name}',
                          ),
                        ),
                        Expanded(
                          child: _buildAdmissionInfo(
                            icon: Icons.domain_outlined,
                            label: 'Ward',
                            value: admission.section.name,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAdmissionInfo(
                            icon: Icons.bed_outlined,
                            label: 'Bed',
                            value: 'Bed ${admission.bedNumber}',
                          ),
                        ),
                        Expanded(
                          child: _buildAdmissionInfo(
                            icon: Icons.access_time,
                            label: 'Admitted',
                            value: _formatDate(admission.admissionDate),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Pending Tasks
              if (hasPendingTasks) ...[
                const SizedBox(height: 10.0),
                Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  alignment: WrapAlignment.center,
                  children: [
                    if (admission.pendingMedications > 0)
                      _buildPendingBadge(
                        icon: Icons.medication_outlined,
                        count: admission.pendingMedications,
                        label: 'Meds',
                        color: HospitalTheme.medical,
                      ),
                    if (admission.pendingIVFluids > 0)
                      _buildPendingBadge(
                        icon: Icons.water_drop_outlined,
                        count: admission.pendingIVFluids,
                        label: 'IV',
                        color: HospitalTheme.info,
                      ),
                    if (admission.pendingProcedures > 0)
                      _buildPendingBadge(
                        icon: Icons.healing_outlined,
                        count: admission.pendingProcedures,
                        label: 'Proc',
                        color: HospitalTheme.laboratory,
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 16.0),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 40.0,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToEmergencyMedication(patient),
                  icon: const Icon(Icons.emergency, size: 18.0),
                  label: Text(
                    'Emergency Medication',
                    style: TextStyle(fontSize: isDesktop ? 16.0 : 12.0),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HospitalTheme.emergency,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDesktop) {
    final searchQuery = ref.watch(patientsSearchProvider);
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
                isSearching ? Icons.search_off : Icons.people_outline,
                size: isDesktop ? 60.0 : 50.0,
                color: HospitalTheme.textMedium,
              ),
            ),
            SizedBox(height: isDesktop ? 24.0 : 16.0),
            Text(
              isSearching ? 'No patients found' : 'No active patients',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: HospitalTheme.textMedium,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8.0),
            Text(
              isSearching
                  ? 'Try adjusting your search criteria'
                  : 'There are currently no admitted patients',
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
              'Error Loading Patients',
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

  // Keep existing helper methods
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14.0,
          color: HospitalTheme.textMedium,
        ),
        const SizedBox(height: 3.0),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1.0),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.0,
            color: HospitalTheme.textMedium,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildAdmissionInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12.0,
          color: HospitalTheme.textMedium,
        ),
        const SizedBox(width: 4.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                  color: HospitalTheme.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 8.0,
                  color: HospitalTheme.textMedium,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingBadge({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: HospitalTheme.radiusSmall,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11.0,
            color: color,
          ),
          const SizedBox(width: 3.0),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10.0,
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Helper class for detail information
class _DetailInfo {
  final String label;
  final String value;

  const _DetailInfo(this.label, this.value);
}
