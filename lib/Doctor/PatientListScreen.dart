import 'dart:async';

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

// Providers
final patientListProvider =
    StateNotifierProvider<PatientListNotifier, AsyncValue<PatientListResponse>>(
        (ref) {
  return PatientListNotifier();
});

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedPatientTypeProvider = StateProvider<String>((ref) => 'all');
final selectedPatientProvider = StateProvider<Patient?>((ref) => null);

class PatientListNotifier
    extends StateNotifier<AsyncValue<PatientListResponse>> {
  PatientListNotifier() : super(const AsyncValue.loading()) {
    fetchPatients();
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMasterDetail = screenWidth > 1200;

    return Scaffold(
      appBar: HospitalTheme.buildAppBar(
        context: context,
        title: 'Patient Management',
        showBackButton: false,
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(patientListProvider.notifier).refreshPatients(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
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
    return Row(
      children: [
        // Master pane
        Expanded(
          flex: 3,
          child: _buildPatientListPane(),
        ),
        Container(
          width: 1,
          color: HospitalTheme.border,
        ),
        // Detail pane
        Expanded(
          flex: 2,
          child: _buildDetailPane(),
        ),
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
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    final selectedType = ref.watch(selectedPatientTypeProvider);
                    return DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Patient Type',
                        prefixIcon: Icon(Icons.filter_list),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('All Patients')),
                        DropdownMenuItem(value: 'ipd', child: Text('IPD Only')),
                        DropdownMenuItem(value: 'opd', child: Text('OPD Only')),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
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

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Expanded(
            child: isDesktop
                ? _buildPatientDataTable(response.patients)
                : _buildPatientCardList(response.patients),
          ),
          if (response.pagination.totalPages > 1)
            _buildPagination(response.pagination),
        ],
      ),
    );
  }

  Widget _buildPatientDataTable(List<Patient> patients) {
    return SingleChildScrollView(
      child: HospitalTheme.buildCard(
        padding: EdgeInsets.zero,
        child: DataTable(
          columnSpacing: 24,
          horizontalMargin: 24,
          showCheckboxColumn: false,
          columns: const [
            DataColumn(label: Text('Patient')),
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Age/Gender')),
            DataColumn(label: Text('Contact')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Visits')),
            DataColumn(label: Text('Actions')),
          ],
          rows: patients.map((patient) => _buildDataRow(patient)).toList(),
        ),
      ),
    );
  }

  DataRow _buildDataRow(Patient patient) {
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
              IconButton(
                onPressed: () => _editPatient(patient),
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Patient',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPatientCardList(List<Patient> patients) {
    return ListView.builder(
      itemCount: patients.length,
      padding: const EdgeInsets.only(bottom: 16),
      itemBuilder: (context, index) {
        final patient = patients[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: HospitalTheme.buildPatientInfoCard(
            name: patient.name,
            patientId: patient.patientId,
            age: patient.age.toString(),
            gender: patient.gender,
            phoneNumber: patient.contact,
            lastVisit: patient.lastDischargeDate != null
                ? '${patient.lastDischargeDate!.day}/${patient.lastDischargeDate!.month}/${patient.lastDischargeDate!.year}'
                : null,
            imageUrl: patient.imageUrl,
            onTap: () => _selectPatient(patient),
            onEditPressed: () => _editPatient(patient),
          ),
        );
      },
    );
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
    return Padding(
      padding: const EdgeInsets.all(16),
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
              ),
              Text(
                  'Page ${pagination.currentPage} of ${pagination.totalPages}'),
              IconButton(
                onPressed: pagination.hasNextPage
                    ? () => _changePage(pagination.currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
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

  void _selectPatient(Patient patient) {
    ref.read(selectedPatientProvider.notifier).state = patient;
  }

  void _viewPatient(Patient patient) {
    _selectPatient(patient);
    // TODO: Navigate to patient details if not in master-detail layout
  }

  void _editPatient(Patient patient) {
    // TODO: Navigate to edit patient screen
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatientHeader(),
            const SizedBox(height: 24),
            _buildBasicInfo(),
            const SizedBox(height: 24),
            _buildMedicalInfo(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHeader() {
    return HospitalTheme.buildCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: HospitalTheme.surfaceLight,
            backgroundImage: patient.imageUrl != null
                ? NetworkImage(patient.imageUrl!)
                : null,
            child: patient.imageUrl == null
                ? Icon(Icons.person, size: 48, color: HospitalTheme.primary)
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
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${patient.patientId}',
                  style: TextStyle(
                    fontSize: 16,
                    color: HospitalTheme.textMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    HospitalTheme.buildStatusBadge(
                      patient.patientType,
                      color: patient.patientType == 'IPD'
                          ? HospitalTheme.medical
                          : HospitalTheme.pharmacy,
                    ),
                    const SizedBox(width: 8),
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
              const SizedBox(width: 16),
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
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: HospitalTheme.textMedium,
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Expanded(
        //   child: ElevatedButton.icon(
        //     onPressed: () {
        //       // TODO: Navigate to edit patient
        //     },
        //     icon: const Icon(Icons.edit),
        //     label: const Text('Edit Patient'),
        //   ),
        // ),
        // const SizedBox(width: 12),
        // Expanded(
        //   child: OutlinedButton.icon(
        //     onPressed: () {
        //       // TODO: Navigate to patient history
        //     },
        //     icon: const Icon(Icons.history),
        //     label: const Text('View History'),
        //   ),
        // ),
      ],
    );
  }
}
