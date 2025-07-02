import 'dart:async';

import 'package:doctordesktop/Doctor/PatientHistoryDetailScreen.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Models
class Patient {
  final String id;
  final String patientId;
  final String name;
  final int age;
  final String gender;
  final String contact;
  final String address;
  final String? imageUrl;
  final bool discharged;
  final double pendingAmount;
  final int totalAdmissions;
  final int ipdAdmissions;
  final int totalVisits;
  final int opdOnlyVisits;
  final DateTime? lastDischargeDate;
  final String? lastDischargeCondition;
  final Doctor? lastDischargeDoctor;
  final String patientType;

  const Patient({
    required this.id,
    required this.patientId,
    required this.name,
    required this.age,
    required this.gender,
    required this.contact,
    required this.address,
    this.imageUrl,
    required this.discharged,
    required this.pendingAmount,
    required this.totalAdmissions,
    required this.ipdAdmissions,
    required this.totalVisits,
    required this.opdOnlyVisits,
    this.lastDischargeDate,
    this.lastDischargeCondition,
    this.lastDischargeDoctor,
    required this.patientType,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['_id'] ?? '',
      patientId: json['patientId'] ?? '',
      name: json['name'] ?? 'Unknown',
      age: (json['age'] is int)
          ? json['age']
          : int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      gender: json['gender'] ?? 'Unknown',
      contact: json['contact'] ?? '',
      address: json['address'] ?? '',
      imageUrl: json['imageUrl']?.isNotEmpty == true ? json['imageUrl'] : null,
      discharged: json['discharged'] ?? false,
      pendingAmount: (json['pendingAmount'] is num)
          ? json['pendingAmount'].toDouble()
          : 0.0,
      totalAdmissions: json['totalAdmissions'] ?? 0,
      ipdAdmissions: json['ipdAdmissions'] ?? 0,
      totalVisits: json['totalVisits'] ?? 0,
      opdOnlyVisits: json['opdOnlyVisits'] ?? 0,
      lastDischargeDate: json['lastDischargeDate'] != null
          ? DateTime.tryParse(json['lastDischargeDate'])
          : null,
      lastDischargeCondition: json['lastDischargeCondition'],
      lastDischargeDoctor: json['lastDischargeDoctor'] != null
          ? Doctor.fromJson(json['lastDischargeDoctor'])
          : null,
      patientType: json['patientType'] ?? 'OPD',
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
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      usertype: json['usertype'] ?? 'doctor',
    );
  }
}

class PaginationData {
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasNextPage;
  final bool hasPrevPage;
  final int limit;
  final int skip;

  const PaginationData({
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.hasNextPage,
    required this.hasPrevPage,
    required this.limit,
    required this.skip,
  });

  factory PaginationData.fromJson(Map<String, dynamic> json) {
    return PaginationData(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalCount: json['totalCount'] ?? 0,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPrevPage: json['hasPrevPage'] ?? false,
      limit: json['limit'] ?? 20,
      skip: json['skip'] ?? 0,
    );
  }
}

class Statistics {
  final int totalPatients;
  final int ipdPatients;
  final int opdPatients;
  final int todayAdmissions;

  const Statistics({
    required this.totalPatients,
    required this.ipdPatients,
    required this.opdPatients,
    required this.todayAdmissions,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      totalPatients: json['totalPatients'] ?? 0,
      ipdPatients: json['ipdPatients'] ?? 0,
      opdPatients: json['opdPatients'] ?? 0,
      todayAdmissions: json['todayAdmissions'] ?? 0,
    );
  }
}

class PatientListResponse {
  final List<Patient> patients;
  final PaginationData pagination;
  final Statistics statistics;

  const PatientListResponse({
    required this.patients,
    required this.pagination,
    required this.statistics,
  });

  factory PatientListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return PatientListResponse(
      patients: (data['patients'] as List? ?? [])
          .map((patient) => Patient.fromJson(patient))
          .toList(),
      pagination: PaginationData.fromJson(data['pagination'] ?? {}),
      statistics: Statistics.fromJson(data['statistics'] ?? {}),
    );
  }
}

// Providers - Use autoDispose to ensure fresh data on each screen visit
final patientListProvider = StateNotifierProvider.autoDispose<
    PatientListNotifier, AsyncValue<PatientListResponse>>((ref) {
  return PatientListNotifier();
});

final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final selectedPatientTypeProvider =
    StateProvider.autoDispose<String>((ref) => 'all');
final selectedPatientProvider =
    StateProvider.autoDispose<Patient?>((ref) => null);

class PatientListNotifier
    extends StateNotifier<AsyncValue<PatientListResponse>> {
  PatientListNotifier() : super(const AsyncValue.loading()) {
    // Don't fetch in constructor to avoid conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchPatients();
    });
  }

  Future<void> fetchPatients({
    String search = '',
    String filterType = 'all',
    int page = 1,
  }) async {
    try {
      state = const AsyncValue.loading();

      final uri = Uri.parse('${KVM_URL}/doctors/getPatientsList')
          .replace(queryParameters: {
        if (search.isNotEmpty) 'search': search,
        'filterType': filterType,
        'page': page.toString(),
        'limit': '20',
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final patientResponse = PatientListResponse.fromJson(jsonData);
          state = AsyncValue.data(patientResponse);
        } else {
          state = AsyncValue.error(
            jsonData['message'] ?? 'Failed to fetch patients',
            StackTrace.current,
          );
        }
      } else {
        state = AsyncValue.error(
          'HTTP ${response.statusCode}: Failed to fetch patients',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refreshPatients() async {
    await fetchPatients();
  }

  // Force refresh when needed
  void ensureDataLoaded() {
    if (state.value == null) {
      fetchPatients();
    }
  }
}

// Main Screen
class PatientListScreen1 extends ConsumerStatefulWidget {
  const PatientListScreen1({super.key});

  @override
  ConsumerState<PatientListScreen1> createState() => _PatientListScreen1State();
}

class _PatientListScreen1State extends ConsumerState<PatientListScreen1> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // Ensure data is loaded when screen is first visited
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized) {
        _ensureDataLoaded();
        _hasInitialized = true;
      }
    });
  }

  void _ensureDataLoaded() {
    final currentState = ref.read(patientListProvider);

    // If there's no data or it's in error state, force refresh
    if (currentState.value == null || currentState.hasError) {
      print('Force refreshing patient data on screen visit');
      ref.read(patientListProvider.notifier).fetchPatients();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    ref.read(searchQueryProvider.notifier).state = query;
    _debounceSearch(query);
  }

  Timer? _debounceTimer;
  void _debounceSearch(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final filterType = ref.read(selectedPatientTypeProvider);
      ref.read(patientListProvider.notifier).fetchPatients(
            search: query,
            filterType: filterType,
          );
    });
  }

  void _onPatientTypeChanged(String? value) {
    if (value != null) {
      ref.read(selectedPatientTypeProvider.notifier).state = value;
      final search = ref.read(searchQueryProvider);
      ref.read(patientListProvider.notifier).fetchPatients(
            search: search,
            filterType: value,
          );
    }
  }

  void _closeDetailPanel() {
    ref.read(selectedPatientProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final availableWidth = screenSize.width - 280; // Account for sidebar
    final selectedPatient = ref.watch(selectedPatientProvider);

    // Force master-detail for debugging (remove this line once working)
    final isMasterDetail = true; // Change this back to: availableWidth > 1000

    print(
        'Screen width: ${screenSize.width}, Available width: $availableWidth, Master-detail: $isMasterDetail');

    return Scaffold(
      appBar: HospitalTheme.buildAppBar(
        context: context,
        title: 'Patient Management',
        showBackButton: false,
        actions: [
          // Add refresh button at the top
          Consumer(
            builder: (context, ref, child) {
              final patientData = ref.watch(patientListProvider);
              final isLoading = patientData.isLoading;

              return IconButton(
                onPressed: isLoading
                    ? null
                    : () {
                        ref
                            .read(patientListProvider.notifier)
                            .refreshPatients();
                      },
                icon: isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.7),
                          ),
                        ),
                      )
                    : const Icon(Icons.refresh),
                tooltip: isLoading ? 'Refreshing...' : 'Refresh (Ctrl+R)',
              );
            },
          ),
          // Show close panel button only when a patient is selected and in master-detail layout
          if (isMasterDetail && selectedPatient != null)
            IconButton(
              onPressed: _closeDetailPanel,
              icon: const Icon(Icons.close),
              tooltip: 'Close Detail Panel (Esc)',
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
            _searchFocusNode.requestFocus();
          },
          const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () {
            _searchFocusNode.requestFocus();
          },
          const SingleActivator(LogicalKeyboardKey.keyR, control: true): () {
            ref.read(patientListProvider.notifier).refreshPatients();
          },
          const SingleActivator(LogicalKeyboardKey.keyR, meta: true): () {
            ref.read(patientListProvider.notifier).refreshPatients();
          },
          // Add Escape key to close detail panel
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (selectedPatient != null) {
              _closeDetailPanel();
            }
          },
        },
        child: Focus(
          autofocus: true,
          child: isMasterDetail
              ? _buildMasterDetailLayout()
              : _buildSinglePaneLayout(),
        ),
      ),
      floatingActionButton: HospitalTheme.buildFloatingActionButton(
        icon: Icons.person_add,
        onPressed: () {
          // TODO: Navigate to add patient screen
        },
        tooltip: 'Add New Patient',
      ),
    );
  }

  Widget _buildMasterDetailLayout() {
    final selectedPatient = ref.watch(selectedPatientProvider);

    return Row(
      children: [
        // Master pane
        Expanded(
          flex: selectedPatient != null ? 7 : 1,
          child: _buildPatientListPane(),
        ),
        if (selectedPatient != null) ...[
          Container(
            width: 1,
            color: HospitalTheme.border,
          ),
          // Detail pane
          Expanded(
            flex: 3,
            child: _buildDetailPane(),
          ),
        ],
      ],
    );
  }

  Widget _buildSinglePaneLayout() {
    return _buildPatientListPane();
  }

  Widget _buildPatientListPane() {
    return Column(
      children: [
        _buildHeader(),
        _buildStatistics(),
        const SizedBox(height: 16),
        Expanded(child: _buildPatientList()),
      ],
    );
  }

  Widget _buildHeader() {
    final screenSize = MediaQuery.of(context).size;
    final isCompact = screenSize.width < 900;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCompact) ...[
            // Stacked layout for smaller screens
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search patients... (Ctrl+F)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _searchFocusNode.unfocus();
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Consumer(
              builder: (context, ref, child) {
                final selectedType = ref.watch(selectedPatientTypeProvider);
                return DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Type',
                    prefixIcon: Icon(Icons.filter_list),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Patients')),
                    DropdownMenuItem(value: 'ipd', child: Text('IPD Only')),
                    DropdownMenuItem(value: 'opd', child: Text('OPD Only')),
                    DropdownMenuItem(
                        value: 'discharged', child: Text('Discharged')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                  ],
                  onChanged: _onPatientTypeChanged,
                );
              },
            ),
          ] else ...[
            // Side-by-side layout for larger screens
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText:
                          'Search patients by name, ID, or contact... (Ctrl+F)',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _searchFocusNode.unfocus();
                              },
                              icon: const Icon(Icons.clear),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final selectedType =
                          ref.watch(selectedPatientTypeProvider);
                      return DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Patient Type',
                          prefixIcon: Icon(Icons.filter_list),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'all', child: Text('All Patients')),
                          DropdownMenuItem(
                              value: 'ipd', child: Text('IPD Only')),
                          DropdownMenuItem(
                              value: 'opd', child: Text('OPD Only')),
                          DropdownMenuItem(
                              value: 'discharged', child: Text('Discharged')),
                          DropdownMenuItem(
                              value: 'active', child: Text('Active')),
                        ],
                        onChanged: _onPatientTypeChanged,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Consumer(
      builder: (context, ref, child) {
        final patientData = ref.watch(patientListProvider);

        return patientData.when(
          data: (response) => _buildStatsCards(response.statistics),
          loading: () => _buildLoadingStats(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildStatsCards(Statistics stats) {
    final screenSize = MediaQuery.of(context).size;
    final isCompact = screenSize.width < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: isCompact
          ? Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: HospitalTheme.buildStatCard(
                        title: 'Total',
                        value: stats.totalPatients.toString(),
                        icon: Icons.people,
                        iconColor: HospitalTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HospitalTheme.buildStatCard(
                        title: 'IPD',
                        value: stats.ipdPatients.toString(),
                        icon: Icons.local_hospital,
                        iconColor: HospitalTheme.medical,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: HospitalTheme.buildStatCard(
                        title: 'OPD',
                        value: stats.opdPatients.toString(),
                        icon: Icons.person_outline,
                        iconColor: HospitalTheme.pharmacy,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HospitalTheme.buildStatCard(
                        title: 'Today',
                        value: stats.todayAdmissions.toString(),
                        icon: Icons.login,
                        iconColor: HospitalTheme.emergency,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: HospitalTheme.buildStatCard(
                    title: 'Total Patients',
                    value: stats.totalPatients.toString(),
                    icon: Icons.people,
                    iconColor: HospitalTheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: HospitalTheme.buildStatCard(
                    title: 'IPD Patients',
                    value: stats.ipdPatients.toString(),
                    icon: Icons.local_hospital,
                    iconColor: HospitalTheme.medical,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: HospitalTheme.buildStatCard(
                    title: 'OPD Patients',
                    value: stats.opdPatients.toString(),
                    icon: Icons.person_outline,
                    iconColor: HospitalTheme.pharmacy,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: HospitalTheme.buildStatCard(
                    title: 'Today Admissions',
                    value: stats.todayAdmissions.toString(),
                    icon: Icons.login,
                    iconColor: HospitalTheme.emergency,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingStats() {
    final screenSize = MediaQuery.of(context).size;
    final isCompact = screenSize.width < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: isCompact
          ? Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: HospitalTheme.buildStatCard(
                        title: 'Total',
                        value: '---',
                        icon: Icons.people,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HospitalTheme.buildStatCard(
                        title: 'IPD',
                        value: '---',
                        icon: Icons.local_hospital,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: HospitalTheme.buildStatCard(
                        title: 'OPD',
                        value: '---',
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HospitalTheme.buildStatCard(
                        title: 'Today',
                        value: '---',
                        icon: Icons.login,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: HospitalTheme.buildStatCard(
                    title: 'Total Patients',
                    value: '---',
                    icon: Icons.people,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: HospitalTheme.buildStatCard(
                    title: 'IPD Patients',
                    value: '---',
                    icon: Icons.local_hospital,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: HospitalTheme.buildStatCard(
                    title: 'OPD Patients',
                    value: '---',
                    icon: Icons.person_outline,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: HospitalTheme.buildStatCard(
                    title: 'Today Admissions',
                    value: '---',
                    icon: Icons.login,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPatientList() {
    return Consumer(
      builder: (context, ref, child) {
        final patientData = ref.watch(patientListProvider);

        return patientData.when(
          data: (response) => _buildPatientListView(response),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: HospitalTheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading patients',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: HospitalTheme.textMedium,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(patientListProvider.notifier).refreshPatients(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPatientListView(PatientListResponse response) {
    if (response.patients.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Expanded(
            child: _buildOptimizedPatientTable(response.patients),
          ),
          if (response.pagination.totalPages > 1)
            _buildPagination(response.pagination),
        ],
      ),
    );
  }

  Widget _buildOptimizedPatientTable(List<Patient> patients) {
    return HospitalTheme.buildCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Dynamically adjust table layout based on available width
          final availableWidth =
              constraints.maxWidth - 48; // Account for padding

          return SingleChildScrollView(
            child: Container(
              width: availableWidth,
              child: DataTable(
                columnSpacing: 16,
                horizontalMargin: 24,
                showCheckboxColumn: false,
                headingRowHeight: 56,
                dataRowHeight: 72,
                columns: _buildTableColumns(availableWidth),
                rows: patients
                    .map((patient) =>
                        _buildOptimizedDataRow(patient, availableWidth))
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  List<DataColumn> _buildTableColumns(double availableWidth) {
    // Responsive column layout based on available width
    if (availableWidth < 800) {
      // Compact layout for smaller screens
      return const [
        DataColumn(
          label: Expanded(
            child: Text('Patient Info',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        DataColumn(
          label: Text('Type/Status',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ];
    } else if (availableWidth < 1000) {
      // Medium layout
      return const [
        DataColumn(
          label: Expanded(
            child:
                Text('Patient', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        DataColumn(
          label: Text('Contact', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ];
    } else {
      // Full layout for large screens
      return const [
        DataColumn(
          label: Expanded(
            child: Text('Patient Information',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        DataColumn(
          label:
              Text('Patient ID', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label:
              Text('Age/Gender', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('Contact', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('Visits', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ];
    }
  }

  DataRow _buildOptimizedDataRow(Patient patient, double availableWidth) {
    if (availableWidth < 800) {
      return _buildCompactDataRow(patient);
    } else if (availableWidth < 1000) {
      return _buildMediumDataRow(patient);
    } else {
      return _buildFullDataRow(patient);
    }
  }

  DataRow _buildCompactDataRow(Patient patient) {
    return DataRow(
      onSelectChanged: (_) => _selectPatient(patient),
      cells: [
        DataCell(
          Container(
            width: double.infinity,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: HospitalTheme.surfaceLight,
                  backgroundImage: patient.imageUrl != null
                      ? NetworkImage(patient.imageUrl!)
                      : null,
                  child: patient.imageUrl == null
                      ? Icon(Icons.person,
                          color: HospitalTheme.primary, size: 18)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        patient.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${patient.patientId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: HospitalTheme.textMedium,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${patient.age}/${patient.gender} • ${patient.contact}',
                        style: TextStyle(
                          fontSize: 11,
                          color: HospitalTheme.textMedium,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          onTap: () => _selectPatient(patient),
        ),
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HospitalTheme.buildStatusBadge(
                patient.patientType,
                color: patient.patientType == 'IPD'
                    ? HospitalTheme.medical
                    : HospitalTheme.pharmacy,
              ),
              const SizedBox(height: 4),
              HospitalTheme.buildStatusBadge(
                patient.discharged ? 'Discharged' : 'Active',
                color: patient.discharged
                    ? HospitalTheme.success
                    : HospitalTheme.warning,
              ),
            ],
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _viewPatient(patient),
                icon: const Icon(Icons.visibility, size: 18),
                tooltip: 'View',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  DataRow _buildMediumDataRow(Patient patient) {
    return DataRow(
      onSelectChanged: (_) => _selectPatient(patient),
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: HospitalTheme.surfaceLight,
                backgroundImage: patient.imageUrl != null
                    ? NetworkImage(patient.imageUrl!)
                    : null,
                child: patient.imageUrl == null
                    ? Icon(Icons.person, color: HospitalTheme.primary, size: 18)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${patient.patientId} • ${patient.age}/${patient.gender}',
                      style: TextStyle(
                        fontSize: 12,
                        color: HospitalTheme.textMedium,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          onTap: () => _selectPatient(patient),
        ),
        DataCell(Text(patient.contact)),
        DataCell(
          HospitalTheme.buildStatusBadge(
            patient.patientType,
            color: patient.patientType == 'IPD'
                ? HospitalTheme.medical
                : HospitalTheme.pharmacy,
          ),
        ),
        DataCell(
          HospitalTheme.buildStatusBadge(
            patient.discharged ? 'Discharged' : 'Active',
            color: patient.discharged
                ? HospitalTheme.success
                : HospitalTheme.warning,
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _viewPatient(patient),
                icon: const Icon(Icons.visibility, size: 18),
                tooltip: 'View',
              ),
            ],
          ),
        ),
      ],
    );
  }

  DataRow _buildFullDataRow(Patient patient) {
    return DataRow(
      onSelectChanged: (_) => _selectPatient(patient),
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: HospitalTheme.surfaceLight,
                backgroundImage: patient.imageUrl != null
                    ? NetworkImage(patient.imageUrl!)
                    : null,
                child: patient.imageUrl == null
                    ? Icon(Icons.person, color: HospitalTheme.primary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (patient.lastDischargeDoctor != null)
                      Text(
                        'Dr. ${patient.lastDischargeDoctor!.name}',
                        style: TextStyle(
                          fontSize: 12,
                          color: HospitalTheme.textMedium,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          onTap: () => _selectPatient(patient),
        ),
        DataCell(Text(patient.patientId)),
        DataCell(Text('${patient.age}/${patient.gender}')),
        DataCell(Text(patient.contact)),
        DataCell(
          HospitalTheme.buildStatusBadge(
            patient.patientType,
            color: patient.patientType == 'IPD'
                ? HospitalTheme.medical
                : HospitalTheme.pharmacy,
          ),
        ),
        DataCell(
          HospitalTheme.buildStatusBadge(
            patient.discharged ? 'Discharged' : 'Active',
            color: patient.discharged
                ? HospitalTheme.success
                : HospitalTheme.warning,
          ),
        ),
        DataCell(Text(patient.totalVisits.toString())),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _viewPatient(patient),
                icon: const Icon(Icons.visibility),
                tooltip: 'View Details',
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _selectPatient(Patient patient) {
    print('Selecting patient: ${patient.name}');
    ref.read(selectedPatientProvider.notifier).state = patient;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: HospitalTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No patients found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: HospitalTheme.textMedium,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: HospitalTheme.textLight,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              ref.read(selectedPatientTypeProvider.notifier).state = 'all';
              ref.read(patientListProvider.notifier).refreshPatients();
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(PaginationData pagination) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: HospitalTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${pagination.skip + 1}-${(pagination.skip + pagination.limit).clamp(0, pagination.totalCount)} of ${pagination.totalCount}',
            style: TextStyle(color: HospitalTheme.textMedium),
          ),
          Row(
            children: [
              IconButton(
                onPressed: pagination.hasPrevPage
                    ? () => _changePage(pagination.currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous Page',
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: HospitalTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Page ${pagination.currentPage} of ${pagination.totalPages}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                onPressed: pagination.hasNextPage
                    ? () => _changePage(pagination.currentPage + 1)
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

  Widget _buildDetailPane() {
    return Consumer(
      builder: (context, ref, child) {
        final selectedPatient = ref.watch(selectedPatientProvider);

        if (selectedPatient == null) {
          return const _EmptyDetailPane();
        }

        return _PatientDetailPane(patient: selectedPatient);
      },
    );
  }

  void _viewPatient(Patient patient) {
    _selectPatient(patient);
  }

  void _changePage(int page) {
    final search = ref.read(searchQueryProvider);
    final filterType = ref.read(selectedPatientTypeProvider);
    ref.read(patientListProvider.notifier).fetchPatients(
          search: search,
          filterType: filterType,
          page: page,
        );
  }
}

// Empty Detail Pane Widget
class _EmptyDetailPane extends StatelessWidget {
  const _EmptyDetailPane();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: HospitalTheme.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: HospitalTheme.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a patient',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: HospitalTheme.textMedium,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a patient from the list to view details',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HospitalTheme.textLight,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// Patient Detail Pane Widget
class _PatientDetailPane extends StatelessWidget {
  final Patient patient;

  const _PatientDetailPane({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: HospitalTheme.background,
      child: Column(
        children: [
          // Header with close button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: HospitalTheme.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Patient Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    return IconButton(
                      onPressed: () {
                        ref.read(selectedPatientProvider.notifier).state = null;
                      },
                      icon: const Icon(Icons.close),
                      tooltip: 'Close (Esc)',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    );
                  },
                ),
              ],
            ),
          ),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPatientHeader(),
                  const SizedBox(height: 20),
                  _buildBasicInfo(),
                  const SizedBox(height: 20),
                  _buildMedicalInfo(),
                  const SizedBox(height: 20),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientHeader() {
    return HospitalTheme.buildCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: HospitalTheme.surfaceLight,
            backgroundImage: patient.imageUrl != null
                ? NetworkImage(patient.imageUrl!)
                : null,
            child: patient.imageUrl == null
                ? Icon(Icons.person, size: 42, color: HospitalTheme.primary)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${patient.patientId}',
                  style: TextStyle(
                    fontSize: 14,
                    color: HospitalTheme.textMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    HospitalTheme.buildStatusBadge(
                      patient.patientType,
                      color: patient.patientType == 'IPD'
                          ? HospitalTheme.medical
                          : HospitalTheme.pharmacy,
                    ),
                    HospitalTheme.buildStatusBadge(
                      patient.discharged ? 'Discharged' : 'Active',
                      color: patient.discharged
                          ? HospitalTheme.success
                          : HospitalTheme.warning,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('Basic Information'),
          _buildInfoRow('Age', '${patient.age} years'),
          _buildInfoRow('Gender', patient.gender),
          _buildInfoRow('Contact', patient.contact),
          _buildInfoRow('Address', patient.address),
          if (patient.pendingAmount > 0)
            _buildInfoRow(
              'Pending Amount',
              '₹${patient.pendingAmount.toStringAsFixed(2)}',
              valueColor: HospitalTheme.error,
            ),
        ],
      ),
    );
  }

  Widget _buildMedicalInfo() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('Medical Information'),
          Row(
            children: [
              Expanded(
                child: HospitalTheme.buildStatCard(
                  title: 'Total Visits',
                  value: patient.totalVisits.toString(),
                  icon: Icons.medical_services,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HospitalTheme.buildStatCard(
                  title: 'IPD Admissions',
                  value: patient.ipdAdmissions.toString(),
                  icon: Icons.local_hospital,
                ),
              ),
            ],
          ),
          if (patient.lastDischargeDate != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              'Last Discharge',
              '${patient.lastDischargeDate!.day}/${patient.lastDischargeDate!.month}/${patient.lastDischargeDate!.year}',
            ),
            if (patient.lastDischargeCondition != null)
              _buildInfoRow(
                  'Discharge Condition', patient.lastDischargeCondition!),
            if (patient.lastDischargeDoctor != null)
              _buildInfoRow(
                  'Last Doctor', 'Dr. ${patient.lastDischargeDoctor!.name}'),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: HospitalTheme.textMedium,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? HospitalTheme.textDark,
                fontWeight:
                    valueColor != null ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PatientHistoryDetailScreen(
                    patientId: patient.patientId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.history),
            label: const Text('View History'),
          ),
        ),
      ],
    );
  }
}
