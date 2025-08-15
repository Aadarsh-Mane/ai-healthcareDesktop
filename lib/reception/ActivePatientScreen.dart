// File: lib/screens/reception/active_patient_screen.dart

import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/core/utils/PdfViewerScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ==================== MODELS ====================

class PatientInsuranceInfo {
  final bool hasInsurance;
  final String? eligibilityStatus;
  final bool? isAuthorizedForTreatment;

  const PatientInsuranceInfo({
    required this.hasInsurance,
    this.eligibilityStatus,
    this.isAuthorizedForTreatment,
  });

  factory PatientInsuranceInfo.fromJson(Map<String, dynamic> json) {
    return PatientInsuranceInfo(
      hasInsurance: json['hasInsurance'] ?? false,
      eligibilityStatus: json['eligibilityStatus']?.toString(),
      isAuthorizedForTreatment: json['isAuthorizedForTreatment'],
    );
  }
}

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
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Doctor',
      usertype: json['usertype']?.toString() ?? 'doctor',
    );
  }
}

class CurrentAdmission {
  final String id;
  final int opdNumber;
  final int ipdNumber;
  final DateTime admissionDate;
  final String status;
  final String patientType;
  final Doctor doctor;

  const CurrentAdmission({
    required this.id,
    required this.opdNumber,
    required this.ipdNumber,
    required this.admissionDate,
    required this.status,
    required this.patientType,
    required this.doctor,
  });

  factory CurrentAdmission.fromJson(Map<String, dynamic> json) {
    return CurrentAdmission(
      id: json['_id']?.toString() ?? '',
      opdNumber: json['opdNumber'] ?? 0,
      ipdNumber: json['ipdNumber'] ?? 0,
      admissionDate:
          DateTime.tryParse(json['admissionDate']?.toString() ?? '') ??
              DateTime.now(),
      status: json['status']?.toString() ?? 'unknown',
      patientType: json['patientType']?.toString() ?? 'Internal',
      doctor: Doctor.fromJson(json['doctor'] ?? {}),
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
  final String address;
  final String imageUrl;
  final double pendingAmount;
  final CurrentAdmission? currentAdmission;
  final PatientInsuranceInfo? insuranceInfo;

  const ActivePatient({
    required this.id,
    required this.patientId,
    required this.name,
    required this.age,
    required this.gender,
    required this.contact,
    required this.address,
    required this.imageUrl,
    required this.pendingAmount,
    this.currentAdmission,
    this.insuranceInfo,
  });

  factory ActivePatient.fromJson(Map<String, dynamic> json) {
    return ActivePatient(
      id: json['_id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Patient',
      age: json['age'] ?? 0,
      gender: json['gender']?.toString() ?? 'Unknown',
      contact: json['contact']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      pendingAmount: (json['pendingAmount'] ?? 0).toDouble(),
      currentAdmission: json['currentAdmission'] != null
          ? CurrentAdmission.fromJson(json['currentAdmission'])
          : null,
      insuranceInfo: json['insuranceInfo'] != null
          ? PatientInsuranceInfo.fromJson(json['insuranceInfo'])
          : null,
    );
  }
}

class ActivePatientsSummary {
  final int totalActivePatients;
  final int withInsurance;
  final int withoutInsurance;
  final int ipdPatients;
  final int opdPatients;
  final int emergencyPatients;

  const ActivePatientsSummary({
    required this.totalActivePatients,
    required this.withInsurance,
    required this.withoutInsurance,
    required this.ipdPatients,
    required this.opdPatients,
    required this.emergencyPatients,
  });

  factory ActivePatientsSummary.fromJson(Map<String, dynamic> json) {
    return ActivePatientsSummary(
      totalActivePatients: json['totalActivePatients'] ?? 0,
      withInsurance: json['withInsurance'] ?? 0,
      withoutInsurance: json['withoutInsurance'] ?? 0,
      ipdPatients: json['ipdPatients'] ?? 0,
      opdPatients: json['opdPatients'] ?? 0,
      emergencyPatients: json['emergencyPatients'] ?? 0,
    );
  }
}

class ActivePatientsResponse {
  final bool success;
  final String message;
  final List<ActivePatient> patients;
  final ActivePatientsSummary summary;
  final Map<String, int> pagination;

  const ActivePatientsResponse({
    required this.success,
    required this.message,
    required this.patients,
    required this.summary,
    required this.pagination,
  });

  factory ActivePatientsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return ActivePatientsResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      patients: (data['patients'] as List<dynamic>?)
              ?.map((patient) => ActivePatient.fromJson(patient))
              .toList() ??
          [],
      summary: ActivePatientsSummary.fromJson(data['summary'] ?? {}),
      pagination: Map<String, int>.from(data['pagination'] ?? {}),
    );
  }
}

// ==================== STATE MANAGEMENT ====================

class ActivePatientsState {
  final List<ActivePatient> patients;
  final ActivePatientsSummary? summary;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String? selectedPatientType;
  final bool? hasInsuranceFilter;
  final int currentPage;
  final int totalPages;
  final ActivePatient? selectedPatient;

  const ActivePatientsState({
    this.patients = const [],
    this.summary,
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedPatientType,
    this.hasInsuranceFilter,
    this.currentPage = 1,
    this.totalPages = 1,
    this.selectedPatient,
  });

  ActivePatientsState copyWith({
    List<ActivePatient>? patients,
    ActivePatientsSummary? summary,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? selectedPatientType,
    bool? hasInsuranceFilter,
    int? currentPage,
    int? totalPages,
    ActivePatient? selectedPatient,
  }) {
    return ActivePatientsState(
      patients: patients ?? this.patients,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedPatientType: selectedPatientType ?? this.selectedPatientType,
      hasInsuranceFilter: hasInsuranceFilter ?? this.hasInsuranceFilter,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      selectedPatient: selectedPatient ?? this.selectedPatient,
    );
  }
}

class ActivePatientsNotifier extends StateNotifier<ActivePatientsState> {
  ActivePatientsNotifier() : super(const ActivePatientsState()) {
    loadActivePatients();
  }

  static const String baseUrl =
      '${BASE_URL}/reception/getActivePatientsWithAdmissions';

  Future<void> loadActivePatients({
    int page = 1,
    String? searchTerm,
    String? patientType,
    bool? hasInsurance,
    bool resetFilters = false,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': '10',
      };

      // Only add filters if they are not null and not being reset
      if (!resetFilters) {
        if (searchTerm?.isNotEmpty == true) {
          queryParams['searchTerm'] = searchTerm!;
        }
        if (patientType?.isNotEmpty == true) {
          queryParams['patientType'] = patientType!;
        }
        if (hasInsurance != null) {
          queryParams['hasInsurance'] = hasInsurance.toString();
        }
      }

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

      print('Loading patients with URL: $uri'); // Debug log
      print(
          'Filters - resetFilters: $resetFilters, searchTerm: $searchTerm, patientType: $patientType, hasInsurance: $hasInsurance'); // Debug log

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final activePatientsResponse =
            ActivePatientsResponse.fromJson(jsonData);

        if (activePatientsResponse.success) {
          state = state.copyWith(
            patients: activePatientsResponse.patients,
            summary: activePatientsResponse.summary,
            isLoading: false,
            currentPage: activePatientsResponse.pagination['page'] ?? 1,
            totalPages: activePatientsResponse.pagination['pages'] ?? 1,
            // Clear selected patient if list changes
            selectedPatient: activePatientsResponse.patients.isNotEmpty
                ? activePatientsResponse.patients.first
                : null,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: activePatientsResponse.message.isNotEmpty
                ? activePatientsResponse.message
                : 'Failed to load active patients',
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error:
              'Server error: ${response.statusCode}. Please check your connection.',
        );
      }
    } catch (e) {
      print('Error loading patients: $e'); // Debug log
      state = state.copyWith(
        isLoading: false,
        error:
            'Network error: ${e.toString()}. Please check your internet connection.',
      );
    }
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updatePatientTypeFilter(String? patientType) {
    state = state.copyWith(selectedPatientType: patientType);
    loadActivePatients(
      searchTerm: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      patientType: patientType,
      hasInsurance: state.hasInsuranceFilter,
    );
  }

  void updateInsuranceFilter(bool? hasInsurance) {
    state = state.copyWith(hasInsuranceFilter: hasInsurance);
    loadActivePatients(
      searchTerm: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      patientType: state.selectedPatientType,
      hasInsurance: hasInsurance,
    );
  }

  void searchPatients() {
    loadActivePatients(
      searchTerm: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      patientType: state.selectedPatientType,
      hasInsurance: state.hasInsuranceFilter,
    );
  }

  void clearAllFilters() {
    state = state.copyWith(
      searchQuery: '',
      selectedPatientType: null,
      hasInsuranceFilter: null,
    );
    loadActivePatients(resetFilters: true);
  }

  void clearSearchQuery() {
    state = state.copyWith(searchQuery: '');
  }

  void selectPatient(ActivePatient patient) {
    state = state.copyWith(selectedPatient: patient);
  }

  void goToPage(int page) {
    if (page >= 1 && page <= state.totalPages) {
      loadActivePatients(
        page: page,
        searchTerm: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        patientType: state.selectedPatientType,
        hasInsurance: state.hasInsuranceFilter,
      );
    }
  }

  void refreshData() {
    loadActivePatients(
      page: state.currentPage,
      searchTerm: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      patientType: state.selectedPatientType,
      hasInsurance: state.hasInsuranceFilter,
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ==================== PROVIDERS ====================

final activePatientsProvider =
    StateNotifierProvider<ActivePatientsNotifier, ActivePatientsState>(
  (ref) => ActivePatientsNotifier(),
);

// ==================== SCREEN ====================

class ActivePatientScreen extends ConsumerStatefulWidget {
  const ActivePatientScreen({super.key});

  @override
  ConsumerState<ActivePatientScreen> createState() =>
      _ActivePatientScreenState();
}

class _ActivePatientScreenState extends ConsumerState<ActivePatientScreen> {
  final TextEditingController _searchController = TextEditingController();
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();

    // Listen to search controller changes to update the search query state
    _searchController.addListener(() {
      final notifier = ref.read(activePatientsProvider.notifier);
      if (_searchController.text != notifier.state.searchQuery) {
        notifier.updateSearchQuery(_searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activePatientsProvider);
    final notifier = ref.read(activePatientsProvider.notifier);
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 1200;

    // Sync search controller with state
    if (_searchController.text != state.searchQuery) {
      _searchController.text = state.searchQuery;
    }

    return PdfViewerWidget(
      primaryColor: HospitalTheme.primary,
      appBarTitle: 'Active Patients',
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
            _searchFocusNode.requestFocus();
          },
          const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () {
            _searchFocusNode.requestFocus();
          },
          const SingleActivator(LogicalKeyboardKey.f5): () {
            notifier.refreshData();
          },
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (state.selectedPatient != null && isWideScreen) {
              notifier.selectPatient(state.patients.isNotEmpty
                  ? state.patients.first
                  : state.selectedPatient!);
            }
          },
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: HospitalTheme.background,
            body: isWideScreen
                ? _buildMasterDetailLayout(context, state, notifier)
                : _buildSinglePaneLayout(context, state, notifier),
          ),
        ),
      ),
    );
  }

  Widget _buildMasterDetailLayout(BuildContext context,
      ActivePatientsState state, ActivePatientsNotifier notifier) {
    return Row(
      children: [
        // Master Pane (Patient List)
        SizedBox(
          width: 450,
          child: Column(
            children: [
              _buildHeader(context, state, notifier,
                  isCompact: true, showSummary: false),
              Expanded(
                child: _buildPatientsList(context, state, notifier,
                    isMasterPane: true),
              ),
              if (state.totalPages > 1)
                _buildPagination(context, state, notifier),
            ],
          ),
        ),

        // Divider
        const VerticalDivider(
            width: 1, thickness: 1, color: HospitalTheme.border),

        // Detail Pane
        Expanded(
          child: _buildDetailPane(context, state, notifier),
        ),
      ],
    );
  }

  Widget _buildSinglePaneLayout(BuildContext context, ActivePatientsState state,
      ActivePatientsNotifier notifier) {
    final screenSize = MediaQuery.of(context).size;
    final isCompact = screenSize.width < 900;

    return Column(
      children: [
        _buildHeader(context, state, notifier,
            isCompact: isCompact, showSummary: true),
        Expanded(
          child:
              _buildPatientsList(context, state, notifier, isMasterPane: false),
        ),
        if (state.totalPages > 1) _buildPagination(context, state, notifier),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ActivePatientsState state,
      ActivePatientsNotifier notifier,
      {required bool isCompact, required bool showSummary}) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12.0 : 24.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: HospitalTheme.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Actions Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Patients',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: HospitalTheme.textDark,
                                fontWeight: FontWeight.bold,
                                fontSize: isCompact ? 20 : 24,
                              ),
                    ),
                    if (state.summary != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '${state.summary!.totalActivePatients} patients currently admitted',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: HospitalTheme.textMedium,
                                  ),
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (state.selectedPatientType != null ||
                      state.hasInsuranceFilter != null ||
                      state.searchQuery.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        notifier.clearAllFilters();
                      },
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Clear Filters'),
                      style: TextButton.styleFrom(
                        foregroundColor: HospitalTheme.warning,
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed:
                        state.isLoading ? null : () => notifier.refreshData(),
                    icon: state.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    tooltip: 'Refresh (F5)',
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Summary Cards (only in single pane mode)
          if (showSummary && state.summary != null) ...[
            _buildSummaryCards(context, state, isCompact),
            const SizedBox(height: 16),
          ],

          // Filters
          _buildFilters(context, state, notifier, isCompact),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
      BuildContext context, ActivePatientsState state, bool isCompact) {
    if (state.summary == null) return const SizedBox.shrink();

    final summary = state.summary!;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 600
        ? 2
        : screenWidth < 900
            ? 3
            : 4;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildSummaryCard(
          title: 'Total Active',
          value: summary.totalActivePatients.toString(),
          icon: Icons.people,
          color: HospitalTheme.primary,
        ),
        _buildSummaryCard(
          title: 'IPD Patients',
          value: summary.ipdPatients.toString(),
          icon: Icons.local_hospital,
          color: HospitalTheme.medical,
        ),
        _buildSummaryCard(
          title: 'With Insurance',
          value: summary.withInsurance.toString(),
          icon: Icons.security,
          color: HospitalTheme.success,
        ),
        _buildSummaryCard(
          title: 'Without Insurance',
          value: summary.withoutInsurance.toString(),
          icon: Icons.money_off,
          color: HospitalTheme.warning,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: HospitalTheme.radiusMedium,
        border: Border.all(color: HospitalTheme.border),
        boxShadow: HospitalTheme.shadowSmall,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: HospitalTheme.textMedium,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, ActivePatientsState state,
      ActivePatientsNotifier notifier, bool isCompact) {
    return Column(
      children: [
        // Search Bar
        TextFormField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: 'Search patients... (Ctrl+F)',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      notifier.clearSearchQuery();
                      notifier.searchPatients();
                    },
                    icon: const Icon(Icons.clear),
                  )
                : null,
          ),
          onChanged: (value) {
            // The listener in initState will handle updating the search query
            // notifier.updateSearchQuery(value); // Remove this to avoid duplicate updates
          },
          onFieldSubmitted: (value) {
            notifier.searchPatients();
          },
        ),

        const SizedBox(height: 12),

        // Filter Row
        if (isCompact)
          Column(
            children: [
              _buildPatientTypeFilter(state, notifier),
              const SizedBox(height: 12),
              _buildInsuranceFilter(state, notifier),
            ],
          )
        else
          Row(
            children: [
              Expanded(child: _buildPatientTypeFilter(state, notifier)),
              const SizedBox(width: 12),
              Expanded(child: _buildInsuranceFilter(state, notifier)),
            ],
          ),
      ],
    );
  }

  Widget _buildPatientTypeFilter(
      ActivePatientsState state, ActivePatientsNotifier notifier) {
    return DropdownButtonFormField<String>(
      value: state.selectedPatientType,
      decoration: const InputDecoration(
        labelText: 'Patient Type',
        prefixIcon: Icon(Icons.category),
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('All Types')),
        DropdownMenuItem(value: 'Internal', child: Text('Internal')),
        DropdownMenuItem(value: 'External', child: Text('External')),
        DropdownMenuItem(value: 'Emergency', child: Text('Emergency')),
      ],
      onChanged: (value) => notifier.updatePatientTypeFilter(value),
    );
  }

  Widget _buildInsuranceFilter(
      ActivePatientsState state, ActivePatientsNotifier notifier) {
    return DropdownButtonFormField<bool>(
      value: state.hasInsuranceFilter,
      decoration: const InputDecoration(
        labelText: 'Insurance Status',
        prefixIcon: Icon(Icons.security),
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('All Patients')),
        DropdownMenuItem(value: true, child: Text('With Insurance')),
        DropdownMenuItem(value: false, child: Text('Without Insurance')),
      ],
      onChanged: (value) => notifier.updateInsuranceFilter(value),
    );
  }

  Widget _buildPatientsList(BuildContext context, ActivePatientsState state,
      ActivePatientsNotifier notifier,
      {required bool isMasterPane}) {
    if (state.isLoading && state.patients.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading active patients...'),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: HospitalTheme.error),
              const SizedBox(height: 16),
              const Text(
                'Failed to Load Active Patients',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.error,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => notifier.refreshData(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => notifier.clearError(),
                child: const Text('Clear Error'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.patients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 64, color: HospitalTheme.textLight),
            const SizedBox(height: 16),
            const Text(
              'No Active Patients Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: HospitalTheme.textMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No patients match your current filters.',
              style: TextStyle(
                fontSize: 14,
                color: HospitalTheme.textLight,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                notifier.clearAllFilters();
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(isMasterPane ? 12 : 16),
      itemCount: state.patients.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final patient = state.patients[index];
        return _buildPatientListItem(patient, state, notifier,
            isMasterPane: isMasterPane);
      },
    );
  }

  Widget _buildPatientListItem(ActivePatient patient, ActivePatientsState state,
      ActivePatientsNotifier notifier,
      {required bool isMasterPane}) {
    final isSelected = state.selectedPatient?.id == patient.id;

    return InkWell(
      onTap: () {
        if (isMasterPane) {
          notifier.selectPatient(patient);
        } else {
          _viewPatientDetails(patient);
        }
      },
      borderRadius: HospitalTheme.radiusMedium,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? HospitalTheme.primary.withOpacity(0.1)
              : Colors.white,
          borderRadius: HospitalTheme.radiusMedium,
          border: Border.all(
            color: isSelected ? HospitalTheme.primary : HospitalTheme.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected ? HospitalTheme.shadow : HospitalTheme.shadowSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                CircleAvatar(
                  radius: isMasterPane ? 16 : 20,
                  backgroundColor: HospitalTheme.surfaceLight,
                  backgroundImage: patient.imageUrl.isNotEmpty
                      ? NetworkImage(patient.imageUrl)
                      : null,
                  child: patient.imageUrl.isEmpty
                      ? Icon(Icons.person,
                          color: HospitalTheme.primary,
                          size: isMasterPane ? 16 : 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: TextStyle(
                          fontSize: isMasterPane ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ID: ${patient.patientId}',
                        style: TextStyle(
                          fontSize: isMasterPane ? 11 : 12,
                          color: HospitalTheme.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(patient.currentAdmission?.status ?? 'unknown',
                    isCompact: isMasterPane),
              ],
            ),

            if (!isMasterPane) ...[
              const SizedBox(height: 12),

              // Patient Info Row
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildInfoChip('${patient.age} yrs', Icons.cake),
                  _buildInfoChip(
                    patient.gender,
                    patient.gender.toLowerCase() == 'male'
                        ? Icons.male
                        : Icons.female,
                  ),
                  if (patient.insuranceInfo?.hasInsurance == true)
                    _buildInfoChip('Insured', Icons.security,
                        color: HospitalTheme.success),
                ],
              ),

              if (patient.currentAdmission != null) ...[
                const SizedBox(height: 12),
                _buildAdmissionInfo(patient.currentAdmission!, isCompact: true),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailPane(BuildContext context, ActivePatientsState state,
      ActivePatientsNotifier notifier) {
    if (state.selectedPatient == null) {
      return Container(
        color: HospitalTheme.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_search,
                  size: 80, color: HospitalTheme.textLight),
              const SizedBox(height: 16),
              const Text(
                'Select a Patient',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: HospitalTheme.textMedium,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a patient from the list to view details',
                style: TextStyle(
                  fontSize: 14,
                  color: HospitalTheme.textLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final patient = state.selectedPatient!;

    return Container(
      color: HospitalTheme.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
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
                        radius: 40,
                        backgroundColor: HospitalTheme.surfaceLight,
                        backgroundImage: patient.imageUrl.isNotEmpty
                            ? NetworkImage(patient.imageUrl)
                            : null,
                        child: patient.imageUrl.isEmpty
                            ? const Icon(Icons.person,
                                size: 40, color: HospitalTheme.primary)
                            : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: HospitalTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Patient ID: ${patient.patientId}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: HospitalTheme.textMedium,
                              ),
                            ),
                            if (patient.contact.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Contact: ${patient.contact}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: HospitalTheme.textMedium,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildStatusBadge(
                              patient.currentAdmission?.status ?? 'unknown'),
                          if (patient.pendingAmount > 0) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: HospitalTheme.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '₹${patient.pendingAmount.toStringAsFixed(0)} Due',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: HospitalTheme.warning,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Patient Details Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 3,
                    children: [
                      _buildDetailCard(
                          'Age', '${patient.age} years', Icons.cake),
                      _buildDetailCard(
                        'Gender',
                        patient.gender,
                        patient.gender.toLowerCase() == 'male'
                            ? Icons.male
                            : Icons.female,
                      ),
                      _buildDetailCard(
                        'Insurance',
                        patient.insuranceInfo?.hasInsurance == true
                            ? 'Yes'
                            : 'No',
                        Icons.security,
                        valueColor: patient.insuranceInfo?.hasInsurance == true
                            ? HospitalTheme.success
                            : HospitalTheme.textMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Address Card
            if (patient.address.isNotEmpty) ...[
              HospitalTheme.buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Address',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 18, color: HospitalTheme.textMedium),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            patient.address,
                            style: const TextStyle(
                              fontSize: 16,
                              color: HospitalTheme.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Current Admission Card
            if (patient.currentAdmission != null) ...[
              HospitalTheme.buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Admission Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAdmissionInfo(patient.currentAdmission!,
                        isCompact: false),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Insurance Information Card
            if (patient.insuranceInfo != null) ...[
              HospitalTheme.buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Insurance Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInsuranceInfo(patient.insuranceInfo!),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewPatientDetails(patient),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('View Full Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HospitalTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _generatePatientReport(patient),
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('Generate Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HospitalTheme.info,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildDetailCard(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HospitalTheme.surfaceLight,
        borderRadius: HospitalTheme.radiusSmall,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: HospitalTheme.textMedium),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? HospitalTheme.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: HospitalTheme.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsuranceInfo(PatientInsuranceInfo insurance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              insurance.hasInsurance ? Icons.check_circle : Icons.cancel,
              color: insurance.hasInsurance
                  ? HospitalTheme.success
                  : HospitalTheme.error,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              insurance.hasInsurance
                  ? 'Has Insurance Coverage'
                  : 'No Insurance Coverage',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: insurance.hasInsurance
                    ? HospitalTheme.success
                    : HospitalTheme.error,
              ),
            ),
          ],
        ),
        if (insurance.hasInsurance && insurance.eligibilityStatus != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 18, color: HospitalTheme.textMedium),
              const SizedBox(width: 12),
              Text(
                'Eligibility Status: ${insurance.eligibilityStatus}',
                style: const TextStyle(
                  fontSize: 14,
                  color: HospitalTheme.textMedium,
                ),
              ),
            ],
          ),
        ],
        if (insurance.hasInsurance &&
            insurance.isAuthorizedForTreatment != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                insurance.isAuthorizedForTreatment!
                    ? Icons.verified
                    : Icons.pending,
                size: 18,
                color: insurance.isAuthorizedForTreatment!
                    ? HospitalTheme.success
                    : HospitalTheme.warning,
              ),
              const SizedBox(width: 12),
              Text(
                insurance.isAuthorizedForTreatment!
                    ? 'Authorized for Treatment'
                    : 'Authorization Pending',
                style: TextStyle(
                  fontSize: 14,
                  color: insurance.isAuthorizedForTreatment!
                      ? HospitalTheme.success
                      : HospitalTheme.warning,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(String status, {bool isCompact = false}) {
    Color color;
    String displayStatus;

    switch (status.toLowerCase()) {
      case 'admitted':
        color = HospitalTheme.info;
        displayStatus = 'Admitted';
        break;
      case 'discharged':
        color = HospitalTheme.success;
        displayStatus = 'Discharged';
        break;
      case 'transferred':
        color = HospitalTheme.warning;
        displayStatus = 'Transferred';
        break;
      default:
        color = HospitalTheme.textMedium;
        displayStatus = status.isEmpty ? 'Unknown' : status;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(
          fontSize: isCompact ? 10 : 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, {Color? color}) {
    final chipColor = color ?? HospitalTheme.textMedium;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdmissionInfo(CurrentAdmission admission,
      {required bool isCompact}) {
    final admissionDate = _formatDate(admission.admissionDate);

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_hospital,
                  size: 14, color: HospitalTheme.textMedium),
              const SizedBox(width: 4),
              Text(
                'IPD: ${admission.ipdNumber}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: HospitalTheme.textDark,
                ),
              ),
              const Spacer(),
              Text(
                admissionDate,
                style: const TextStyle(
                  fontSize: 12,
                  color: HospitalTheme.textMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person,
                  size: 14, color: HospitalTheme.textMedium),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Dr. ${admission.doctor.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: HospitalTheme.textMedium,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 3,
      children: [
        _buildDetailCard(
            'IPD Number', admission.ipdNumber.toString(), Icons.local_hospital),
        _buildDetailCard(
            'OPD Number', admission.opdNumber.toString(), Icons.event_note),
        _buildDetailCard('Type', admission.patientType, Icons.category),
        _buildDetailCard('Admission Date', admissionDate, Icons.calendar_today),
        _buildDetailCard(
            'Consulting Doctor', 'Dr. ${admission.doctor.name}', Icons.person),
        _buildDetailCard('Status', admission.status, Icons.info_outline),
      ],
    );
  }

  Widget _buildPagination(BuildContext context, ActivePatientsState state,
      ActivePatientsNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: HospitalTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${state.currentPage} of ${state.totalPages}',
            style: const TextStyle(
              fontSize: 14,
              color: HospitalTheme.textMedium,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: state.currentPage > 1
                    ? () => notifier.goToPage(state.currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous Page',
              ),
              IconButton(
                onPressed: state.currentPage < state.totalPages
                    ? () => notifier.goToPage(state.currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next Page',
              ),
            ],
          ),
        ],
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

  void _viewPatientDetails(ActivePatient patient) {
    // TODO: Navigate to patient details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing details for ${patient.name}'),
        backgroundColor: HospitalTheme.info,
      ),
    );
  }

  void _generatePatientReport(ActivePatient patient) {
    // TODO: Generate and open PDF report using Methods().openPdf()
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating report for ${patient.name}'),
        backgroundColor: HospitalTheme.success,
      ),
    );
  }
}
