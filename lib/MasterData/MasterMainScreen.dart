import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/core/utils/PdfViewerScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ==================== MODELS ====================

class SystemStatistics {
  final int activePatients;
  final int dischargedPatients;
  final int totalAdmissions;
  final int totalPatients;

  const SystemStatistics({
    required this.activePatients,
    required this.dischargedPatients,
    required this.totalAdmissions,
    required this.totalPatients,
  });

  factory SystemStatistics.fromJson(Map<String, dynamic> json) {
    final stats = json['statistics'] ?? {};
    return SystemStatistics(
      activePatients: stats['activePatients'] ?? 0,
      dischargedPatients: stats['dischargedPatients'] ?? 0,
      totalAdmissions: stats['totalAdmissions'] ?? 0,
      totalPatients: stats['totalPatients'] ?? 0,
    );
  }
}

class PatientOverview {
  final String id;
  final String patientId;
  final String name;
  final int age;
  final String gender;
  final String contact;
  final String status;
  final bool discharged;
  final int pendingAmount;
  final LatestAdmission? latestAdmission;
  final LatestHistory? latestHistory;

  const PatientOverview({
    required this.id,
    required this.patientId,
    required this.name,
    required this.age,
    required this.gender,
    required this.contact,
    required this.status,
    required this.discharged,
    required this.pendingAmount,
    this.latestAdmission,
    this.latestHistory,
  });

  factory PatientOverview.fromJson(Map<String, dynamic> json) {
    return PatientOverview(
      id: json['_id'] ?? '',
      patientId: json['patientId'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      contact: json['contact'] ?? '',
      status: json['status'] ?? '',
      discharged: json['discharged'] ?? false,
      pendingAmount: json['pendingAmount'] ?? 0,
      latestAdmission: json['latestAdmission'] != null
          ? LatestAdmission.fromJson(json['latestAdmission'])
          : null,
      latestHistory: json['latestHistory'] != null
          ? LatestHistory.fromJson(json['latestHistory'])
          : null,
    );
  }
}

class LatestAdmission {
  final int opdNumber;
  final int? ipdNumber;
  final DateTime admissionDate;
  final String status;
  final Doctor doctor;

  const LatestAdmission({
    required this.opdNumber,
    this.ipdNumber,
    required this.admissionDate,
    required this.status,
    required this.doctor,
  });

  factory LatestAdmission.fromJson(Map<String, dynamic> json) {
    return LatestAdmission(
      opdNumber: json['opdNumber'] ?? 0,
      ipdNumber: json['ipdNumber'],
      admissionDate: DateTime.parse(
          json['admissionDate'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? '',
      doctor: Doctor.fromJson(json['doctor'] ?? {}),
    );
  }
}

class LatestHistory {
  final int opdNumber;
  final int? ipdNumber;
  final DateTime admissionDate;
  final DateTime? dischargeDate;
  final String conditionAtDischarge;
  final Doctor doctor;

  const LatestHistory({
    required this.opdNumber,
    this.ipdNumber,
    required this.admissionDate,
    this.dischargeDate,
    required this.conditionAtDischarge,
    required this.doctor,
  });

  factory LatestHistory.fromJson(Map<String, dynamic> json) {
    return LatestHistory(
      opdNumber: json['opdNumber'] ?? 0,
      ipdNumber: json['ipdNumber'],
      admissionDate: DateTime.parse(
          json['admissionDate'] ?? DateTime.now().toIso8601String()),
      dischargeDate: json['dischargeDate'] != null
          ? DateTime.parse(json['dischargeDate'])
          : null,
      conditionAtDischarge: json['conditionAtDischarge'] ?? '',
      doctor: Doctor.fromJson(json['doctor'] ?? {}),
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
      name: json['name'] ?? '',
      usertype: json['usertype'] ?? '',
    );
  }
}

class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasNext;
  final bool hasPrev;

  const PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 0,
      totalCount: json['totalCount'] ?? 0,
      hasNext: json['hasNext'] ?? false,
      hasPrev: json['hasPrev'] ?? false,
    );
  }
}

// ==================== STATE MANAGEMENT ====================

class MasterDataState {
  final SystemStatistics? statistics;
  final List<PatientOverview> patients;
  final PaginationInfo? pagination;
  final bool isLoadingStats;
  final bool isLoadingPatients;
  final String? error;
  final String searchQuery;
  final String statusFilter;
  final int currentPage;
  final int pageSize;
  final PatientOverview? selectedPatient;

  const MasterDataState({
    this.statistics,
    this.patients = const [],
    this.pagination,
    this.isLoadingStats = false,
    this.isLoadingPatients = false,
    this.error,
    this.searchQuery = '',
    this.statusFilter = 'all',
    this.currentPage = 1,
    this.pageSize = 20,
    this.selectedPatient,
  });

  MasterDataState copyWith({
    SystemStatistics? statistics,
    List<PatientOverview>? patients,
    PaginationInfo? pagination,
    bool? isLoadingStats,
    bool? isLoadingPatients,
    String? error,
    String? searchQuery,
    String? statusFilter,
    int? currentPage,
    int? pageSize,
    PatientOverview? selectedPatient,
  }) {
    return MasterDataState(
      statistics: statistics ?? this.statistics,
      patients: patients ?? this.patients,
      pagination: pagination ?? this.pagination,
      isLoadingStats: isLoadingStats ?? this.isLoadingStats,
      isLoadingPatients: isLoadingPatients ?? this.isLoadingPatients,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      selectedPatient: selectedPatient ?? this.selectedPatient,
    );
  }
}

class MasterDataNotifier extends StateNotifier<MasterDataState> {
  MasterDataNotifier() : super(const MasterDataState()) {
    loadInitialData();
  }

  static const String baseUrl = 'http://localhost:5001/master';

  Future<void> loadInitialData() async {
    await Future.wait([
      loadStatistics(),
      loadPatients(),
    ]);
  }

  Future<void> loadStatistics() async {
    state = state.copyWith(isLoadingStats: true, error: null);

    try {
      // Simulate API call - replace with actual HTTP request
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock data based on provided API response
      const mockStats = SystemStatistics(
        activePatients: 2,
        dischargedPatients: 5,
        totalAdmissions: 7,
        totalPatients: 7,
      );

      state = state.copyWith(
        statistics: mockStats,
        isLoadingStats: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingStats: false,
        error: 'Failed to load statistics: $e',
      );
    }
  }

  Future<void> loadPatients({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(currentPage: 1);
    }

    state = state.copyWith(isLoadingPatients: true, error: null);

    try {
      // Simulate API call - replace with actual HTTP request
      await Future.delayed(const Duration(milliseconds: 800));

      // Mock data based on provided API response
      final mockPatients = [
        PatientOverview(
          id: "6874189225b3bf513fcc835d",
          patientId: "SID445",
          name: "sidharth",
          age: 23,
          gender: "Male",
          contact: "42323",
          status: "Active",
          discharged: false,
          pendingAmount: 0,
          latestAdmission: LatestAdmission(
            opdNumber: 29,
            ipdNumber: 10,
            admissionDate: DateTime.parse("2025-07-13T20:35:30.387Z"),
            status: "admitted",
            doctor: const Doctor(
              id: "6860dc4ed6040c660c0823af",
              name: "testing1",
              usertype: "doctor",
            ),
          ),
        ),
        PatientOverview(
          id: "687413ca25b3bf513fcc82d1",
          patientId: "AAD680",
          name: "aadars",
          age: 22,
          gender: "Male",
          contact: "9167787316",
          status: "Active",
          discharged: false,
          pendingAmount: 0,
          latestAdmission: LatestAdmission(
            opdNumber: 28,
            ipdNumber: 9,
            admissionDate: DateTime.parse("2025-07-13T20:15:06.245Z"),
            status: "admitted",
            doctor: const Doctor(
              id: "6860dc4ed6040c660c0823af",
              name: "testing1",
              usertype: "doctor",
            ),
          ),
        ),
      ];

      const mockPagination = PaginationInfo(
        currentPage: 1,
        totalPages: 1,
        totalCount: 7,
        hasNext: false,
        hasPrev: false,
      );

      // Apply filters
      List<PatientOverview> filteredPatients = mockPatients;

      if (state.statusFilter != 'all') {
        filteredPatients = filteredPatients
            .where((p) =>
                p.status.toLowerCase() == state.statusFilter.toLowerCase())
            .toList();
      }

      if (state.searchQuery.isNotEmpty) {
        final query = state.searchQuery.toLowerCase();
        filteredPatients = filteredPatients
            .where((p) =>
                p.name.toLowerCase().contains(query) ||
                p.patientId.toLowerCase().contains(query) ||
                p.contact.contains(query))
            .toList();
      }

      state = state.copyWith(
        patients: filteredPatients,
        pagination: mockPagination,
        isLoadingPatients: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingPatients: false,
        error: 'Failed to load patients: $e',
      );
    }
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
    loadPatients(refresh: true);
  }

  void updateStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
    loadPatients(refresh: true);
  }

  void selectPatient(PatientOverview? patient) {
    state = state.copyWith(selectedPatient: patient);
  }

  Future<void> refreshData() async {
    await loadInitialData();
  }

  Future<bool> deletePatient(String patientId,
      {bool hardDelete = false}) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Remove from local state
      final updatedPatients =
          state.patients.where((p) => p.patientId != patientId).toList();
      state = state.copyWith(patients: updatedPatients);

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete patient: $e');
      return false;
    }
  }

  Future<bool> readmitPatient(
      String patientId, Map<String, dynamic> admissionData) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Refresh data after successful readmission
      await loadPatients();

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to readmit patient: $e');
      return false;
    }
  }
}

final masterDataProvider =
    StateNotifierProvider<MasterDataNotifier, MasterDataState>((ref) {
  return MasterDataNotifier();
});

// ==================== MAIN SCREEN ====================

class MasterDataOperationsScreen extends ConsumerStatefulWidget {
  const MasterDataOperationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MasterDataOperationsScreen> createState() =>
      _MasterDataOperationsScreenState();
}

class _MasterDataOperationsScreenState
    extends ConsumerState<MasterDataOperationsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final notifier = ref.read(masterDataProvider.notifier);
      notifier.updateSearch(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(masterDataProvider);
    final notifier = ref.read(masterDataProvider.notifier);

    return PdfViewerWidget(
      primaryColor: HospitalTheme.primary,
      child: Scaffold(
        appBar: HospitalTheme.buildAppBar(
          context: context,
          title: 'Master Data Operations',
          showBackButton: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => notifier.refreshData(),
              tooltip: 'Refresh Data',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 1200;

            if (isWideScreen) {
              return _buildWideScreenLayout(state, notifier, constraints);
            } else {
              return _buildNarrowScreenLayout(state, notifier);
            }
          },
        ),
      ),
    );
  }

  Widget _buildWideScreenLayout(MasterDataState state,
      MasterDataNotifier notifier, BoxConstraints constraints) {
    return Row(
      children: [
        // Left Column - Statistics & Controls
        SizedBox(
          width: constraints.maxWidth * 0.25,
          child: _buildLeftColumn(state, notifier),
        ),

        // Divider
        const VerticalDivider(width: 1),

        // Middle Column - Patient List
        SizedBox(
          width: constraints.maxWidth * 0.45,
          child: _buildMiddleColumn(state, notifier),
        ),

        // Divider
        const VerticalDivider(width: 1),

        // Right Column - Patient Details
        Expanded(
          child: _buildRightColumn(state, notifier),
        ),
      ],
    );
  }

  Widget _buildNarrowScreenLayout(
      MasterDataState state, MasterDataNotifier notifier) {
    return Column(
      children: [
        // Statistics Row
        Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          child: _buildStatisticsRow(state),
        ),

        const Divider(height: 1),

        // Search and Filters
        Container(
          padding: const EdgeInsets.all(16),
          child: _buildSearchAndFilters(state, notifier),
        ),

        const Divider(height: 1),

        // Patient List
        Expanded(
          child: _buildPatientList(state, notifier),
        ),
      ],
    );
  }

  Widget _buildLeftColumn(MasterDataState state, MasterDataNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Cards
          _buildStatisticsCards(state),

          const SizedBox(height: 24),

          // Quick Filters
          _buildQuickFilters(state, notifier),

          const SizedBox(height: 24),

          // Quick Actions
          _buildQuickActions(notifier),
        ],
      ),
    );
  }

  Widget _buildMiddleColumn(
      MasterDataState state, MasterDataNotifier notifier) {
    return Column(
      children: [
        // Search and Filters Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HospitalTheme.surfaceLight,
            border: Border(bottom: BorderSide(color: HospitalTheme.border)),
          ),
          child: _buildSearchAndFilters(state, notifier),
        ),

        // Patient List
        Expanded(
          child: _buildPatientList(state, notifier),
        ),
      ],
    );
  }

  Widget _buildRightColumn(MasterDataState state, MasterDataNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: state.selectedPatient != null
          ? _buildPatientDetails(state.selectedPatient!, notifier)
          : _buildEmptyDetails(),
    );
  }

  Widget _buildStatisticsRow(MasterDataState state) {
    if (state.isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.statistics == null) {
      return const Center(child: Text('No statistics available'));
    }

    final stats = state.statistics!;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Active Patients',
            stats.activePatients.toString(),
            Icons.person,
            HospitalTheme.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Discharged',
            stats.dischargedPatients.toString(),
            Icons.check_circle,
            HospitalTheme.info,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Admissions',
            stats.totalAdmissions.toString(),
            Icons.local_hospital,
            HospitalTheme.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Patients',
            stats.totalPatients.toString(),
            Icons.people,
            HospitalTheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCards(MasterDataState state) {
    if (state.isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.statistics == null) {
      return const Center(child: Text('No statistics available'));
    }

    final stats = state.statistics!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HospitalTheme.buildSectionHeader('System Overview'),
        _buildStatCard(
          'Active Patients',
          stats.activePatients.toString(),
          Icons.person,
          HospitalTheme.success,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'Discharged',
          stats.dischargedPatients.toString(),
          Icons.check_circle,
          HospitalTheme.info,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'Total Admissions',
          stats.totalAdmissions.toString(),
          Icons.local_hospital,
          HospitalTheme.warning,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'Total Patients',
          stats.totalPatients.toString(),
          Icons.people,
          HospitalTheme.primary,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return HospitalTheme.buildCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
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

  Widget _buildQuickFilters(
      MasterDataState state, MasterDataNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HospitalTheme.buildSectionHeader('Quick Filters'),
        _buildFilterChip(
          'All Patients',
          state.statusFilter == 'all',
          () => notifier.updateStatusFilter('all'),
        ),
        const SizedBox(height: 8),
        _buildFilterChip(
          'Active',
          state.statusFilter == 'active',
          () => notifier.updateStatusFilter('active'),
        ),
        const SizedBox(height: 8),
        _buildFilterChip(
          'Discharged',
          state.statusFilter == 'discharged',
          () => notifier.updateStatusFilter('discharged'),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? HospitalTheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? HospitalTheme.primary : HospitalTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? HospitalTheme.primary : HospitalTheme.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(MasterDataNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HospitalTheme.buildSectionHeader('Quick Actions'),
        _buildActionButton(
          'Refresh Data',
          Icons.refresh,
          () => notifier.refreshData(),
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          'Export Data',
          Icons.download,
          () => _showExportDialog(),
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          'System Logs',
          Icons.history,
          () => _showSystemLogs(),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: HospitalTheme.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: HospitalTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: HospitalTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: HospitalTheme.textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: HospitalTheme.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(
      MasterDataState state, MasterDataNotifier notifier) {
    return Column(
      children: [
        // Search Field
        TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by name, ID, or contact...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      notifier.updateSearch('');
                    },
                  )
                : null,
          ),
        ),

        const SizedBox(height: 12),

        // Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildStatusChip('All', 'all', state.statusFilter, notifier),
              const SizedBox(width: 8),
              _buildStatusChip(
                  'Active', 'active', state.statusFilter, notifier),
              const SizedBox(width: 8),
              _buildStatusChip(
                  'Discharged', 'discharged', state.statusFilter, notifier),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, String value, String currentFilter,
      MasterDataNotifier notifier) {
    final isSelected = currentFilter == value;

    return GestureDetector(
      onTap: () => notifier.updateStatusFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? HospitalTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? HospitalTheme.primary : HospitalTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : HospitalTheme.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPatientList(MasterDataState state, MasterDataNotifier notifier) {
    if (state.isLoadingPatients) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: HospitalTheme.error),
            const SizedBox(height: 16),
            Text(
              'Error loading patients',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: HospitalTheme.textMedium),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => notifier.refreshData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.patients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 48, color: HospitalTheme.textLight),
            const SizedBox(height: 16),
            Text(
              'No patients found',
              style: TextStyle(
                fontSize: 18,
                color: HospitalTheme.textMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(color: HospitalTheme.textLight),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.patients.length,
      itemBuilder: (context, index) {
        final patient = state.patients[index];
        return _buildPatientCard(patient, notifier);
      },
    );
  }

  Widget _buildPatientCard(
      PatientOverview patient, MasterDataNotifier notifier) {
    final isSelected = notifier.state.selectedPatient?.id == patient.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: HospitalTheme.buildCard(
        child: InkWell(
          onTap: () => notifier.selectPatient(patient),
          borderRadius: HospitalTheme.radiusMedium,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: HospitalTheme.radiusMedium,
              border: isSelected
                  ? Border.all(color: HospitalTheme.primary, width: 2)
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${patient.patientId}',
                              style: TextStyle(
                                fontSize: 12,
                                color: HospitalTheme.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      HospitalTheme.buildStatusBadge(
                        patient.status,
                        color: patient.discharged
                            ? HospitalTheme.info
                            : HospitalTheme.success,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Patient Info
                  Row(
                    children: [
                      _buildInfoItem(
                        'Age',
                        patient.age.toString(),
                        Icons.cake,
                      ),
                      const SizedBox(width: 16),
                      _buildInfoItem(
                        'Gender',
                        patient.gender,
                        patient.gender.toLowerCase() == 'male'
                            ? Icons.male
                            : Icons.female,
                      ),
                      const SizedBox(width: 16),
                      _buildInfoItem(
                        'Contact',
                        patient.contact,
                        Icons.phone,
                      ),
                    ],
                  ),

                  if (patient.latestAdmission != null) ...[
                    const SizedBox(height: 12),
                    _buildAdmissionInfo(patient.latestAdmission!),
                  ],

                  if (patient.latestHistory != null) ...[
                    const SizedBox(height: 12),
                    _buildHistoryInfo(patient.latestHistory!),
                  ],

                  // Pending Amount
                  if (patient.pendingAmount > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: HospitalTheme.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Pending: ₹${patient.pendingAmount}',
                        style: TextStyle(
                          color: HospitalTheme.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  // Action Buttons
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showPatientActions(patient, notifier),
                        icon: const Icon(Icons.more_horiz, size: 16),
                        label: const Text('Actions'),
                        style: TextButton.styleFrom(
                          foregroundColor: HospitalTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: HospitalTheme.textMedium),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: HospitalTheme.textMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdmissionInfo(LatestAdmission admission) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: HospitalTheme.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Admission',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.success,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'OPD: ${admission.opdNumber}${admission.ipdNumber != null ? ' | IPD: ${admission.ipdNumber}' : ''}',
            style: const TextStyle(fontSize: 11),
          ),
          Text(
            'Dr. ${admission.doctor.name}',
            style: const TextStyle(fontSize: 11),
          ),
          Text(
            _formatDate(admission.admissionDate),
            style: TextStyle(
              fontSize: 10,
              color: HospitalTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryInfo(LatestHistory history) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: HospitalTheme.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last Visit',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.info,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'OPD: ${history.opdNumber}${history.ipdNumber != null ? ' | IPD: ${history.ipdNumber}' : ''}',
            style: const TextStyle(fontSize: 11),
          ),
          Text(
            'Dr. ${history.doctor.name}',
            style: const TextStyle(fontSize: 11),
          ),
          Text(
            history.dischargeDate != null
                ? '${_formatDate(history.admissionDate)} - ${_formatDate(history.dischargeDate!)}'
                : _formatDate(history.admissionDate),
            style: TextStyle(
              fontSize: 10,
              color: HospitalTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientDetails(
      PatientOverview patient, MasterDataNotifier notifier) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Patient Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => notifier.selectPatient(null),
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Patient Info Card
          HospitalTheme.buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: HospitalTheme.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 32,
                        color: HospitalTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ID: ${patient.patientId}',
                            style: TextStyle(
                              color: HospitalTheme.textMedium,
                            ),
                          ),
                          const SizedBox(height: 4),
                          HospitalTheme.buildStatusBadge(
                            patient.status,
                            color: patient.discharged
                                ? HospitalTheme.info
                                : HospitalTheme.success,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem('Age', patient.age.toString()),
                    ),
                    Expanded(
                      child: _buildDetailItem('Gender', patient.gender),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDetailItem('Contact', patient.contact),
                if (patient.pendingAmount > 0) ...[
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'Pending Amount',
                    '₹${patient.pendingAmount}',
                    valueColor: HospitalTheme.warning,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Current Admission or Last Visit
          if (patient.latestAdmission != null) ...[
            HospitalTheme.buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Admission',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.success,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailItem('OPD Number',
                      patient.latestAdmission!.opdNumber.toString()),
                  if (patient.latestAdmission!.ipdNumber != null)
                    _buildDetailItem('IPD Number',
                        patient.latestAdmission!.ipdNumber.toString()),
                  _buildDetailItem('Status', patient.latestAdmission!.status),
                  _buildDetailItem(
                      'Doctor', patient.latestAdmission!.doctor.name),
                  _buildDetailItem('Admission Date',
                      _formatDate(patient.latestAdmission!.admissionDate)),
                ],
              ),
            ),
          ] else if (patient.latestHistory != null) ...[
            HospitalTheme.buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last Visit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.info,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailItem('OPD Number',
                      patient.latestHistory!.opdNumber.toString()),
                  if (patient.latestHistory!.ipdNumber != null)
                    _buildDetailItem('IPD Number',
                        patient.latestHistory!.ipdNumber.toString()),
                  _buildDetailItem(
                      'Doctor', patient.latestHistory!.doctor.name),
                  _buildDetailItem('Admission Date',
                      _formatDate(patient.latestHistory!.admissionDate)),
                  if (patient.latestHistory!.dischargeDate != null)
                    _buildDetailItem('Discharge Date',
                        _formatDate(patient.latestHistory!.dischargeDate!)),
                  _buildDetailItem('Condition at Discharge',
                      patient.latestHistory!.conditionAtDischarge),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Action Buttons
          _buildDetailActions(patient, notifier),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: HospitalTheme.textMedium,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? HospitalTheme.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailActions(
      PatientOverview patient, MasterDataNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () => _showUpdatePatientDialog(patient, notifier),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Update Info'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HospitalTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
            if (patient.discharged)
              ElevatedButton.icon(
                onPressed: () => _showReadmissionDialog(patient, notifier),
                icon: const Icon(Icons.add_circle, size: 16),
                label: const Text('Re-admit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HospitalTheme.success,
                  foregroundColor: Colors.white,
                ),
              ),
            ElevatedButton.icon(
              onPressed: () => _viewPatientHistory(patient),
              icon: const Icon(Icons.history, size: 16),
              label: const Text('View History'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HospitalTheme.info,
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _generatePatientReport(patient),
              icon: const Icon(Icons.picture_as_pdf, size: 16),
              label: const Text('Generate Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HospitalTheme.warning,
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showDeleteConfirmation(patient, notifier),
              icon: const Icon(Icons.delete, size: 16),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HospitalTheme.error,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyDetails() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 64,
            color: HospitalTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a patient',
            style: TextStyle(
              fontSize: 18,
              color: HospitalTheme.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a patient from the list to view details',
            style: TextStyle(
              color: HospitalTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Dialog Methods
  void _showPatientActions(
      PatientOverview patient, MasterDataNotifier notifier) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.edit, color: HospitalTheme.primary),
              title: const Text('Update Patient Info'),
              onTap: () {
                Navigator.pop(context);
                _showUpdatePatientDialog(patient, notifier);
              },
            ),
            if (patient.discharged)
              ListTile(
                leading: Icon(Icons.add_circle, color: HospitalTheme.success),
                title: const Text('Re-admit Patient'),
                onTap: () {
                  Navigator.pop(context);
                  _showReadmissionDialog(patient, notifier);
                },
              ),
            ListTile(
              leading: Icon(Icons.history, color: HospitalTheme.info),
              title: const Text('View History'),
              onTap: () {
                Navigator.pop(context);
                _viewPatientHistory(patient);
              },
            ),
            ListTile(
              leading: Icon(Icons.picture_as_pdf, color: HospitalTheme.warning),
              title: const Text('Generate Report'),
              onTap: () {
                Navigator.pop(context);
                _generatePatientReport(patient);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: HospitalTheme.error),
              title: const Text('Delete Patient'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(patient, notifier);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdatePatientDialog(
      PatientOverview patient, MasterDataNotifier notifier) {
    // TODO: Implement update patient dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Update patient feature coming soon'),
        backgroundColor: HospitalTheme.info,
      ),
    );
  }

  void _showReadmissionDialog(
      PatientOverview patient, MasterDataNotifier notifier) {
    // TODO: Implement readmission dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Re-admission feature coming soon'),
        backgroundColor: HospitalTheme.success,
      ),
    );
  }

  void _showDeleteConfirmation(
      PatientOverview patient, MasterDataNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Patient'),
        content: Text(
            'Are you sure you want to delete ${patient.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await notifier.deletePatient(patient.patientId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${patient.name} deleted successfully'),
                    backgroundColor: HospitalTheme.success,
                  ),
                );
              }
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

  void _viewPatientHistory(PatientOverview patient) {
    // TODO: Navigate to patient history screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Patient history feature coming soon'),
        backgroundColor: HospitalTheme.info,
      ),
    );
  }

  void _generatePatientReport(PatientOverview patient) {
    // TODO: Generate and open PDF report
    final pdfNotifier = ref.read(pdfViewerProvider.notifier);
    pdfNotifier.loadAndShowPdf(
      'https://drive.google.com/file/d/1example/view',
      title: '${patient.name} - Medical Report',
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Choose export format:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportData('pdf');
            },
            child: const Text('PDF'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportData('excel');
            },
            child: const Text('Excel'),
          ),
        ],
      ),
    );
  }

  void _exportData(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting data as $format...'),
        backgroundColor: HospitalTheme.info,
      ),
    );
  }

  void _showSystemLogs() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('System logs feature coming soon'),
        backgroundColor: HospitalTheme.info,
      ),
    );
  }
}
