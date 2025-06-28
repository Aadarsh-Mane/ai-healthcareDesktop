import 'dart:convert';

import 'package:doctordesktop/Doctor/PatientHistoryDetailScreen.dart';
import 'package:doctordesktop/reception/ManualDischargeSummaryScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/model/patientDischargeModel.dart';
import 'package:doctordesktop/reception/GenerateBillScreen.dart';
import 'package:doctordesktop/reception/GenerateOpdBill.dart';
import 'package:doctordesktop/reception/ExportSummaryScreen.dart';

// Enhanced filter class with proper state management
class PatientFilters {
  final String searchQuery;
  final String doctorType;
  final String dateRange;
  final String patientType;
  final String admissionType; // New: Filter by IPD/OPD

  const PatientFilters({
    this.searchQuery = '',
    this.doctorType = 'All',
    this.dateRange = 'All Time',
    this.patientType = 'All',
    this.admissionType = 'All', // All, IPD, OPD
  });

  PatientFilters copyWith({
    String? searchQuery,
    String? doctorType,
    String? dateRange,
    String? patientType,
    String? admissionType,
  }) {
    return PatientFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      doctorType: doctorType ?? this.doctorType,
      dateRange: dateRange ?? this.dateRange,
      patientType: patientType ?? this.patientType,
      admissionType: admissionType ?? this.admissionType,
    );
  }

  bool filterPatient(PatientDischarge patient) {
    // Search query filter - check multiple fields including numbers
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      final searchableText = [
        patient.name,
        patient.patientId,
        patient.contact,
        patient.lastRecord.doctor?.name ?? '',
        patient.lastRecord.opdNumber?.toString() ?? '',
        patient.lastRecord.ipdNumber?.toString() ?? '',
      ].join(' ').toLowerCase();

      if (!searchableText.contains(query)) {
        return false;
      }
    }

    // Patient type filter
    if (patientType != 'All') {
      final currentPatientType =
          patient.lastRecord.patientType?.toLowerCase() ?? '';
      if (patientType.toLowerCase() != currentPatientType) {
        return false;
      }
    }

    // Doctor type filter
    if (doctorType != 'All') {
      final patientDoctorType =
          patient.lastRecord.doctor?.usertype?.toLowerCase() ?? '';
      if (doctorType.toLowerCase() != patientDoctorType) {
        return false;
      }
    }

    // Admission type filter (IPD/OPD)
    if (admissionType != 'All') {
      final hasIpdNumber = patient.lastRecord.ipdNumber != null &&
          patient.lastRecord.ipdNumber! > 0;
      final hasOpdNumber = patient.lastRecord.opdNumber != null &&
          patient.lastRecord.opdNumber! > 0;

      if (admissionType == 'IPD' && !hasIpdNumber) {
        return false;
      } else if (admissionType == 'OPD' && (!hasOpdNumber || hasIpdNumber)) {
        // OPD only if has OPD number but no IPD number (not admitted)
        return false;
      }
    }

    // Date range filter
    if (dateRange != 'All Time') {
      final dischargeDate = _parseDateString(patient.lastRecord.dischargeDate);
      if (dischargeDate != null) {
        final now = DateTime.now();

        switch (dateRange) {
          case 'Today':
            if (!_isSameDay(dischargeDate, now)) return false;
            break;
          case 'This Week':
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            if (dischargeDate.isBefore(startOfWeek)) return false;
            break;
          case 'This Month':
            final startOfMonth = DateTime(now.year, now.month, 1);
            if (dischargeDate.isBefore(startOfMonth)) return false;
            break;
          case 'Last 7 Days':
            final sevenDaysAgo = now.subtract(const Duration(days: 7));
            if (dischargeDate.isBefore(sevenDaysAgo)) return false;
            break;
          case 'Last 30 Days':
            final thirtyDaysAgo = now.subtract(const Duration(days: 30));
            if (dischargeDate.isBefore(thirtyDaysAgo)) return false;
            break;
        }
      }
    }

    return true;
  }

  DateTime? _parseDateString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;

    try {
      // Handle format: "2025-06-20 01:46:30 PM"
      final parts = dateStr.split(' ');
      if (parts.length >= 3) {
        final dateParts = parts[0].split('-');
        final timeParts = parts[1].split(':');
        final amPm = parts[2];

        if (dateParts.length == 3 && timeParts.length == 3) {
          var hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final second = int.parse(timeParts[2]);

          // Handle AM/PM
          if (amPm.toUpperCase() == 'PM' && hour < 12) {
            hour += 12;
          } else if (amPm.toUpperCase() == 'AM' && hour == 12) {
            hour = 0;
          }

          return DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
            hour,
            minute,
            second,
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error parsing date: $dateStr - $e');
      return null;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// Enhanced data model with proper null safety
class PatientDischarge {
  final String name;
  final String gender;
  final String contact;
  final String patientId;
  final LastRecord lastRecord;

  const PatientDischarge({
    required this.name,
    required this.gender,
    required this.contact,
    required this.patientId,
    required this.lastRecord,
  });

  factory PatientDischarge.fromJson(Map<String, dynamic> json) {
    return PatientDischarge(
      name: json['name']?.toString() ?? 'Unknown',
      gender: json['gender']?.toString() ?? 'Unknown',
      contact: json['contact']?.toString() ?? 'Unknown',
      patientId: json['patientId']?.toString() ?? 'Unknown',
      lastRecord: LastRecord.fromJson(json['lastRecord'] ?? {}),
    );
  }
}

class LastRecord {
  final String admissionId;
  final int? opdNumber;
  final int? ipdNumber;
  final String admissionDate;
  final String dischargeDate;
  final String status;
  final String? patientType;
  final String? admitNotes;
  final String conditionAtDischarge;
  final double amountToBePayed;
  final double previousRemainingAmount;
  final bool dischargedByReception;
  final double weight;
  final Doctor? doctor;
  final String? reasonForAdmission;
  final String? symptoms;
  final String? initialDiagnosis;
  final String? treatmentGiven;
  final String? followUpAdvice;
  final String? investigations;
  final String? operativeProcedures;

  const LastRecord({
    required this.admissionId,
    this.opdNumber,
    this.ipdNumber,
    required this.admissionDate,
    required this.dischargeDate,
    required this.status,
    this.patientType,
    this.admitNotes,
    required this.conditionAtDischarge,
    required this.amountToBePayed,
    required this.previousRemainingAmount,
    required this.dischargedByReception,
    required this.weight,
    this.doctor,
    this.reasonForAdmission,
    this.symptoms,
    this.initialDiagnosis,
    this.treatmentGiven,
    this.followUpAdvice,
    this.investigations,
    this.operativeProcedures,
  });

  factory LastRecord.fromJson(Map<String, dynamic> json) {
    return LastRecord(
      admissionId: json['admissionId']?.toString() ?? '',
      opdNumber: (json['opdNumber'] as num?)?.toInt(),
      ipdNumber: (json['ipdNumber'] as num?)?.toInt(),
      admissionDate: json['admissionDate']?.toString() ?? '',
      dischargeDate: json['dischargeDate']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Unknown',
      patientType: json['patientType']?.toString(),
      admitNotes: json['admitNotes']?.toString(),
      conditionAtDischarge:
          json['conditionAtDischarge']?.toString() ?? 'Unknown',
      amountToBePayed: (json['amountToBePayed'] as num?)?.toDouble() ?? 0.0,
      previousRemainingAmount:
          (json['previousRemainingAmount'] as num?)?.toDouble() ?? 0.0,
      dischargedByReception: json['dischargedByReception'] as bool? ?? false,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      doctor: json['doctor'] != null ? Doctor.fromJson(json['doctor']) : null,
      reasonForAdmission: json['reasonForAdmission']?.toString(),
      symptoms: json['symptoms']?.toString(),
      initialDiagnosis: json['initialDiagnosis']?.toString(),
      treatmentGiven: json['treatmentGiven']?.toString(),
      followUpAdvice: json['followUpAdvice']?.toString(),
      investigations: json['investigations']?.toString(),
      operativeProcedures: json['operativeProcedures']?.toString(),
    );
  }

  // Helper method to determine if this is an IPD admission
  bool get isIpdAdmission => ipdNumber != null && ipdNumber! > 0;

  // Helper method to get admission type
  String get admissionType => isIpdAdmission ? 'IPD' : 'OPD';
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
      name: json['name']?.toString() ?? 'Unknown',
      usertype: json['usertype']?.toString() ?? 'unknown',
    );
  }
}

// Enhanced state notifier with better error handling
class DischargedPatientsNotifier
    extends StateNotifier<AsyncValue<List<PatientDischarge>>> {
  DischargedPatientsNotifier() : super(const AsyncValue.loading()) {
    fetchDischargedPatients();
  }

  static const String apiUrl = '${KVM_URL}/reception/getAllDischargedPatient';

  Future<void> fetchDischargedPatients() async {
    try {
      state = const AsyncValue.loading();

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));
      print('Fetching discharged patients from ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final patients =
            data.map((json) => PatientDischarge.fromJson(json)).toList();

        // Sort by discharge date (newest first)
        patients.sort((a, b) {
          final dateA =
              DateTime.tryParse(a.lastRecord.dischargeDate.split(' ')[0]) ??
                  DateTime(1970);
          final dateB =
              DateTime.tryParse(b.lastRecord.dischargeDate.split(' ')[0]) ??
                  DateTime(1970);
          return dateB.compareTo(dateA);
        });

        state = AsyncValue.data(patients);
      } else {
        throw Exception(
            'Server returned ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Error fetching discharged patients: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refresh() async {
    await fetchDischargedPatients();
  }
}

// Providers
final dischargedPatientsProvider = StateNotifierProvider<
    DischargedPatientsNotifier, AsyncValue<List<PatientDischarge>>>(
  (ref) => DischargedPatientsNotifier(),
);

final patientFiltersProvider =
    StateProvider<PatientFilters>((ref) => const PatientFilters());

final selectedTabProvider = StateProvider<int>((ref) => 0);

final filteredPatientsProvider =
    Provider<AsyncValue<Map<String, List<PatientDischarge>>>>((ref) {
  final patientsAsync = ref.watch(dischargedPatientsProvider);
  final filters = ref.watch(patientFiltersProvider);

  return patientsAsync.when(
    data: (patients) {
      final filteredPatients =
          patients.where((patient) => filters.filterPatient(patient)).toList();

      final internalPatients = filteredPatients
          .where((p) => p.lastRecord.patientType?.toLowerCase() == 'internal')
          .toList();

      final externalPatients = filteredPatients
          .where((p) => p.lastRecord.patientType?.toLowerCase() == 'external')
          .toList();

      return AsyncValue.data({
        'all': filteredPatients,
        'internal': internalPatients,
        'external': externalPatients,
      });
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Enhanced main screen with performance optimizations
class DischargedPatientsScreen1 extends ConsumerStatefulWidget {
  const DischargedPatientsScreen1({super.key});

  @override
  ConsumerState<DischargedPatientsScreen1> createState() =>
      _DischargedPatientsScreenState();
}

class _DischargedPatientsScreenState
    extends ConsumerState<DischargedPatientsScreen1>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  // Separate scroll controllers for each tab
  final Map<String, ScrollController> _scrollControllers = {
    'all': ScrollController(),
    'internal': ScrollController(),
    'external': ScrollController(),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    _tabController.addListener(_handleTabChange);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dischargedPatientsProvider.notifier).fetchDischargedPatients();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();

    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      ref.read(selectedTabProvider.notifier).state = _tabController.index;
    }
  }

  void _handleSearch(String value) {
    ref.read(patientFiltersProvider.notifier).update(
          (state) => state.copyWith(searchQuery: value),
        );
  }

  void _clearSearch() {
    _searchController.clear();
    _handleSearch('');
    _searchFocusNode.unfocus();
  }

  void _resetFilters() {
    _searchController.clear();
    ref.read(patientFiltersProvider.notifier).state = const PatientFilters();
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPatientsAsync = ref.watch(filteredPatientsProvider);
    final selectedTab = ref.watch(selectedTabProvider);
    final filters = ref.watch(patientFiltersProvider);

    // Responsive calculations
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 1200;
    final isMediumScreen = screenSize.width > 800;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            _focusSearch,
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
            _focusSearch,
        const SingleActivator(LogicalKeyboardKey.escape): _clearSearch,
        const SingleActivator(LogicalKeyboardKey.keyR, control: true):
            _refreshData,
        const SingleActivator(LogicalKeyboardKey.keyR, meta: true):
            _refreshData,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: HospitalTheme.background,
          appBar: _buildAppBar(context),
          body: Column(
            children: [
              _FiltersSection(
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
                filters: filters,
                isWideScreen: isWideScreen,
                onSearch: _handleSearch,
                onClearSearch: _clearSearch,
                onResetFilters: _resetFilters,
                onFilterChange: (newFilters) {
                  ref.read(patientFiltersProvider.notifier).state = newFilters;
                },
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _PatientListView(
                      key: const ValueKey('all'),
                      patientsAsync: filteredPatientsAsync,
                      listKey: 'all',
                      scrollController: _scrollControllers['all']!,
                      isWideScreen: isWideScreen,
                    ),
                    _PatientListView(
                      key: const ValueKey('internal'),
                      patientsAsync: filteredPatientsAsync,
                      listKey: 'internal',
                      scrollController: _scrollControllers['internal']!,
                      isWideScreen: isWideScreen,
                    ),
                    _PatientListView(
                      key: const ValueKey('external'),
                      patientsAsync: filteredPatientsAsync,
                      listKey: 'external',
                      scrollController: _scrollControllers['external']!,
                      isWideScreen: isWideScreen,
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: _BottomStatusBar(
            filteredPatientsAsync: filteredPatientsAsync,
          ),
        ),
      ),
    );
  }

  void _focusSearch() {
    _searchFocusNode.requestFocus();
  }

  void _refreshData() {
    ref.read(dischargedPatientsProvider.notifier).refresh();
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return HospitalTheme.buildAppBar(
      context: context,
      title: 'Discharged Patients',
      actions: [
        Tooltip(
          message: 'Export Data (Ctrl+E)',
          child: IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export feature coming soon')),
              );
            },
          ),
        ),
        Tooltip(
          message: 'Refresh (Ctrl+R)',
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
        ),
        const SizedBox(width: 16),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people),
                SizedBox(width: 8),
                Text('All'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person),
                SizedBox(width: 8),
                Text('Internal'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline),
                SizedBox(width: 8),
                Text('External'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Extracted filters section for better performance
class _FiltersSection extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final PatientFilters filters;
  final bool isWideScreen;
  final Function(String) onSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onResetFilters;
  final Function(PatientFilters) onFilterChange;

  const _FiltersSection({
    required this.searchController,
    required this.searchFocusNode,
    required this.filters,
    required this.isWideScreen,
    required this.onSearch,
    required this.onClearSearch,
    required this.onResetFilters,
    required this.onFilterChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isWideScreen ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildSearchField(),
        ),
        const SizedBox(width: 12),
        Expanded(child: _buildPatientTypeFilter()),
        const SizedBox(width: 12),
        Expanded(child: _buildAdmissionTypeFilter()),
        const SizedBox(width: 12),
        Expanded(child: _buildDoctorTypeFilter()),
        const SizedBox(width: 12),
        Expanded(child: _buildDateRangeFilter()),
        const SizedBox(width: 16),
        _buildResetButton(),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        _buildSearchField(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildPatientTypeFilter()),
            const SizedBox(width: 8),
            Expanded(child: _buildAdmissionTypeFilter()),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildDoctorTypeFilter()),
            const SizedBox(width: 8),
            Expanded(child: _buildDateRangeFilter()),
          ],
        ),
        const SizedBox(height: 12),
        _buildResetButton(),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: searchController,
      focusNode: searchFocusNode,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.search, color: HospitalTheme.primary),
        hintText: 'Search by name, ID, contact, OPD/IPD number... (Ctrl+F)',
        filled: true,
        fillColor: HospitalTheme.background,
        border: HospitalTheme.radiusSmall.let(
          (radius) => OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: HospitalTheme.border),
          ),
        ),
        enabledBorder: HospitalTheme.radiusSmall.let(
          (radius) => OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: HospitalTheme.border),
          ),
        ),
        focusedBorder: HospitalTheme.radiusSmall.let(
          (radius) => OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: HospitalTheme.primary, width: 2),
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixIcon: searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: onClearSearch,
              )
            : null,
      ),
      onChanged: onSearch,
    );
  }

  Widget _buildAdmissionTypeFilter() {
    return _CustomDropdown(
      value: filters.admissionType,
      hint: 'Admission',
      icon: Icons.local_hospital,
      items: const [
        {'value': 'All', 'label': 'All Types'},
        {'value': 'IPD', 'label': 'IPD Only'},
        {'value': 'OPD', 'label': 'OPD Only'},
      ],
      onChanged: (value) {
        if (value != null) {
          onFilterChange(filters.copyWith(admissionType: value));
        }
      },
    );
  }

  Widget _buildPatientTypeFilter() {
    return _CustomDropdown(
      value: filters.patientType,
      hint: 'Patient Type',
      icon: Icons.people,
      items: const [
        {'value': 'All', 'label': 'All Types'},
        {'value': 'Internal', 'label': 'Internal'},
        {'value': 'External', 'label': 'External'},
      ],
      onChanged: (value) {
        if (value != null) {
          onFilterChange(filters.copyWith(patientType: value));
        }
      },
    );
  }

  Widget _buildDoctorTypeFilter() {
    return _CustomDropdown(
      value: filters.doctorType,
      hint: 'Doctor Type',
      icon: Icons.medical_services,
      items: const [
        {'value': 'All', 'label': 'All Doctors'},
        {'value': 'doctor', 'label': 'Internal'},
        {'value': 'external', 'label': 'External'},
      ],
      onChanged: (value) {
        if (value != null) {
          onFilterChange(filters.copyWith(doctorType: value));
        }
      },
    );
  }

  Widget _buildDateRangeFilter() {
    return _CustomDropdown(
      value: filters.dateRange,
      hint: 'Date Range',
      icon: Icons.date_range,
      items: const [
        {'value': 'All Time', 'label': 'All Time'},
        {'value': 'Today', 'label': 'Today'},
        {'value': 'Last 7 Days', 'label': 'Last 7 Days'},
        {'value': 'This Week', 'label': 'This Week'},
        {'value': 'Last 30 Days', 'label': 'Last 30 Days'},
        {'value': 'This Month', 'label': 'This Month'},
      ],
      onChanged: (value) {
        if (value != null) {
          onFilterChange(filters.copyWith(dateRange: value));
        }
      },
    );
  }

  Widget _buildResetButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.filter_list_off),
      label: const Text('Reset'),
      style: ElevatedButton.styleFrom(
        backgroundColor: HospitalTheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: HospitalTheme.radiusSmall),
      ),
      onPressed: onResetFilters,
    );
  }
}

// Custom dropdown component
class _CustomDropdown extends StatelessWidget {
  final String value;
  final String hint;
  final IconData icon;
  final List<Map<String, String>> items;
  final Function(String?) onChanged;

  const _CustomDropdown({
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: HospitalTheme.background,
        borderRadius: HospitalTheme.radiusSmall,
        border: Border.all(color: HospitalTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Row(
            children: [
              Icon(icon, size: 16, color: HospitalTheme.textMedium),
              const SizedBox(width: 8),
              Text(hint),
            ],
          ),
          icon: Icon(Icons.arrow_drop_down, color: HospitalTheme.primary),
          onChanged: onChanged,
          items: items
              .map((item) => DropdownMenuItem<String>(
                    value: item['value'],
                    child: Text(
                      item['label']!,
                      style: TextStyle(
                        color: HospitalTheme.textDark,
                        fontSize: 14,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// Patient list view component
class _PatientListView extends StatelessWidget {
  final AsyncValue<Map<String, List<PatientDischarge>>> patientsAsync;
  final String listKey;
  final ScrollController scrollController;
  final bool isWideScreen;

  const _PatientListView({
    super.key,
    required this.patientsAsync,
    required this.listKey,
    required this.scrollController,
    required this.isWideScreen,
  });

  @override
  Widget build(BuildContext context) {
    return patientsAsync.when(
      data: (patientsMap) {
        final patients = patientsMap[listKey] ?? [];

        if (patients.isEmpty) {
          return _EmptyState(onRefresh: () {
            // Refresh logic would be handled by parent
          });
        }

        return Scrollbar(
          controller: scrollController,
          thumbVisibility: true,
          child: ListView.builder(
            controller: scrollController,
            padding: EdgeInsets.all(isWideScreen ? 24 : 16),
            itemCount: patients.length,
            itemBuilder: (context, index) => _PatientCard(
              patient: patients[index],
              isWideScreen: isWideScreen,
            ),
          ),
        );
      },
      loading: () => const _LoadingState(),
      error: (error, _) => _ErrorState(
        error: error,
        onRetry: () {
          // Retry logic would be handled by parent
        },
      ),
    );
  }
}

// Patient card component with enhanced navigation
class _PatientCard extends ConsumerWidget {
  final PatientDischarge patient;
  final bool isWideScreen;

  const _PatientCard({
    required this.patient,
    required this.isWideScreen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInternal =
        patient.lastRecord.patientType?.toLowerCase() == 'internal';
    final doctorType = patient.lastRecord.doctor?.usertype ?? 'unknown';
    final formattedDate = _formatDate(patient.lastRecord.dischargeDate);
    final admissionType = patient.lastRecord.admissionType;
    final isIpdAdmission = patient.lastRecord.isIpdAdmission;

    return HospitalTheme.buildCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _navigateToDetails(context, ref),
        borderRadius: HospitalTheme.radiusMedium,
        child: Column(
          children: [
            // Header with enhanced information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HospitalTheme.surfaceLight,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  // First row: Patient ID and main tags
                  Row(
                    children: [
                      Icon(Icons.badge, size: 18, color: HospitalTheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'ID: ${patient.patientId}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: HospitalTheme.primary,
                        ),
                      ),
                      const Spacer(),
                      _buildTypeChip(
                        label: isInternal ? 'Internal' : 'External',
                        color: isInternal ? Colors.blue : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      _buildTypeChip(
                        label: doctorType.capitalizeFirst(),
                        color: doctorType == 'doctor'
                            ? Colors.green
                            : Colors.purple,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Second row: Admission numbers and type
                  Row(
                    children: [
                      // Admission type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isIpdAdmission
                              ? Colors.red.withOpacity(0.1)
                              : Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isIpdAdmission ? Colors.red : Colors.teal,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isIpdAdmission ? Icons.hotel : Icons.assignment,
                              size: 16,
                              color: isIpdAdmission ? Colors.red : Colors.teal,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              admissionType,
                              style: TextStyle(
                                color:
                                    isIpdAdmission ? Colors.red : Colors.teal,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Numbers display
                      if (patient.lastRecord.opdNumber != null)
                        _buildNumberChip(
                          label: 'OPD',
                          number: patient.lastRecord.opdNumber!,
                          color: Colors.teal,
                        ),

                      if (patient.lastRecord.ipdNumber != null &&
                          patient.lastRecord.ipdNumber! > 0) ...[
                        if (patient.lastRecord.opdNumber != null)
                          const SizedBox(width: 8),
                        _buildNumberChip(
                          label: 'IPD',
                          number: patient.lastRecord.ipdNumber!,
                          color: Colors.red,
                        ),
                      ],

                      const Spacer(),

                      // Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(patient.lastRecord.status)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color:
                                  _getStatusColor(patient.lastRecord.status)),
                        ),
                        child: Text(
                          patient.lastRecord.status.capitalizeFirst(),
                          style: TextStyle(
                            color: _getStatusColor(patient.lastRecord.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                patient.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green),
                              ),
                              child: const Text(
                                'Discharged',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            _InfoItem(
                              icon: Icons.person,
                              label: 'Gender',
                              value: patient.gender,
                              color: Colors.blue,
                            ),
                            _InfoItem(
                              icon: Icons.phone,
                              label: 'Contact',
                              value: patient.contact,
                              color: Colors.deepPurple,
                            ),
                            _InfoItem(
                              icon: Icons.calendar_today,
                              label: 'Discharged',
                              value: formattedDate,
                              color: Colors.teal,
                            ),
                            if (patient.lastRecord.doctor != null)
                              _InfoItem(
                                icon: Icons.medical_services,
                                label: 'Doctor',
                                value: patient.lastRecord.doctor!.name,
                                color: Colors.orange,
                              ),
                            if (patient.lastRecord.amountToBePayed > 0)
                              _InfoItem(
                                icon: Icons.attach_money,
                                label: 'Amount',
                                value:
                                    '₹${patient.lastRecord.amountToBePayed.toStringAsFixed(0)}',
                                color: Colors.indigo,
                              ),
                            if (patient.lastRecord.admitNotes != null &&
                                patient.lastRecord.admitNotes!.isNotEmpty)
                              _InfoItem(
                                icon: Icons.note,
                                label: 'Notes',
                                value: patient.lastRecord.admitNotes!,
                                color: Colors.brown,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberChip(
      {required String label, required int number, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '#$number',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'admitted':
        return Colors.orange;
      case 'pending':
        return Colors.amber;
      case 'discharged':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTypeChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Unknown';

    try {
      final parts = dateStr.split(' ');
      if (parts.isNotEmpty) {
        final datePart = parts[0];
        final dateComponents = datePart.split('-');
        if (dateComponents.length == 3) {
          final date = DateTime(
            int.parse(dateComponents[0]),
            int.parse(dateComponents[1]),
            int.parse(dateComponents[2]),
          );
          return DateFormat.yMMMd().format(date);
        }
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  // ENHANCED: Navigation method that handles return value and triggers refresh
  Future<void> _navigateToDetails(BuildContext context, WidgetRef ref) async {
    // Navigate to patient details and wait for result
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PatientDetailsScreen(patient: patient),
      ),
    );

    // If result is true (indicating changes were made), refresh the data
    if (result == true && context.mounted) {
      // Access the provider through the ref to trigger refresh
      ref.read(dischargedPatientsProvider.notifier).refresh();

      // Show a brief feedback to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.refresh, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Patient data refreshed'),
            ],
          ),
          backgroundColor: HospitalTheme.primary,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }
}

// Info item component
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: HospitalTheme.textMedium,
                fontSize: 11,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Loading state component
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading patients...'),
        ],
      ),
    );
  }
}

// Error state component
class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          const Text('Failed to load patients'),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// Empty state component
class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('No patients found'),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters or refresh the data',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRefresh,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

// Bottom status bar component
class _BottomStatusBar extends StatelessWidget {
  final AsyncValue<Map<String, List<PatientDischarge>>> filteredPatientsAsync;

  const _BottomStatusBar({
    required this.filteredPatientsAsync,
  });

  @override
  Widget build(BuildContext context) {
    return filteredPatientsAsync.when(
      data: (patientsMap) {
        final totalAll = patientsMap['all']?.length ?? 0;
        final totalInternal = patientsMap['internal']?.length ?? 0;
        final totalExternal = patientsMap['external']?.length ?? 0;

        // Calculate IPD and OPD counts
        final allPatients = patientsMap['all'] ?? [];
        final totalIpd =
            allPatients.where((p) => p.lastRecord.isIpdAdmission).length;
        final totalOpd =
            allPatients.where((p) => !p.lastRecord.isIpdAdmission).length;

        return Container(
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [HospitalTheme.primaryDark, HospitalTheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatusCounter(
                label: 'All',
                count: totalAll,
                icon: Icons.people,
              ),
              Container(height: 40, width: 1, color: Colors.white30),
              _StatusCounter(
                label: 'Internal',
                count: totalInternal,
                icon: Icons.person,
              ),
              Container(height: 40, width: 1, color: Colors.white30),
              _StatusCounter(
                label: 'External',
                count: totalExternal,
                icon: Icons.person_outline,
              ),
              Container(height: 40, width: 1, color: Colors.white30),
              _StatusCounter(
                label: 'IPD',
                count: totalIpd,
                icon: Icons.hotel,
              ),
              Container(height: 40, width: 1, color: Colors.white30),
              _StatusCounter(
                label: 'OPD',
                count: totalOpd,
                icon: Icons.assignment,
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 80),
      error: (_, __) => const SizedBox(height: 80),
    );
  }
}

// Status counter component
class _StatusCounter extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;

  const _StatusCounter({
    required this.label,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Extension for String
extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

// Extension for BorderRadius
extension BorderRadiusExtension on BorderRadius {
  T let<T>(T Function(BorderRadius) transform) {
    return transform(this);
  }
}

// ENHANCED: Patient Details Screen with proper return handling
class PatientDetailsScreen extends StatefulWidget {
  final PatientDischarge patient;

  const PatientDetailsScreen({Key? key, required this.patient})
      : super(key: key);

  @override
  _PatientDetailsScreenState createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final TextEditingController _billingAmountController =
      TextEditingController();
  final TextEditingController _amountPaidController = TextEditingController();
  bool _isDischargedByReception = false;
  bool _hasChanges = false; // Track if any changes were made

  @override
  void initState() {
    super.initState();
    _isDischargedByReception = widget.patient.lastRecord.dischargedByReception;
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _toggleDischargeByReception(bool value) async {
    if (value) {
      bool confirm = await _showConfirmationDialog(context);
      if (confirm) {
        setState(() {
          _isDischargedByReception = true;
        });
        // Call the backend to update the discharge status
        await _updateDischargeStatus();
      }
    } else {
      setState(() {
        _isDischargedByReception = false;
      });
    }
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Confirm Discharge',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: HospitalTheme.primary,
              ),
            ),
            content: Text(
              'Are you sure you want to discharge this patient?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey.shade700),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HospitalTheme.secondary,
                ),
                child: Text(
                  'Confirm',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
        ) ??
        false;
  }

  Future<void> _updateDischargeStatus() async {
    try {
      final response = await http.put(
        Uri.parse(
            '${KVM_URL}/reception/dischargeByReceptionCondition/${widget.patient.patientId}/${widget.patient.lastRecord.admissionId}'),
      );

      if (response.statusCode == 200) {
        // Mark that changes were made
        _hasChanges = true;
        _showSnackBar(context, "Patient discharged successfully.");
      } else {
        setState(() {
          // Reset the switch if the API call fails
          _isDischargedByReception = false;
        });
        _showSnackBar(
            context, "Failed to discharge patient: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        // Reset the switch if there's an exception
        _isDischargedByReception = false;
      });
      _showSnackBar(context, "Error: $e");
    }
  }

  Future<void> _generateDischargeSummary() async {
    BuildContext? dialogContext;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) {
          dialogContext = ctx;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(HospitalTheme.primary),
                  strokeWidth: 3,
                ),
                SizedBox(height: 20),
                Text(
                  'Generating discharge summary...',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please wait while we prepare your document',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      final response = await http.get(
        Uri.parse(
            '${KVM_URL}/reception/generateDischargeSummary/${widget.patient.patientId}'),
      );

      // Close loading dialog
      if (dialogContext != null && Navigator.of(dialogContext!).canPop()) {
        Navigator.of(dialogContext!).pop();
        dialogContext = null;
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final String driveLink = responseData['data']['driveLink'];
          final String fileName =
              responseData['data']['fileName'] ?? 'Discharge Summary';

          // Mark that changes were made (summary generated)
          _hasChanges = true;

          // Show success dialog
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext successDialogContext) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Summary Generated',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discharge summary has been generated successfully!',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: HospitalTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: HospitalTheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            color: HospitalTheme.primary,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              fileName,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: HospitalTheme.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Would you like to open the PDF document now?',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(successDialogContext).pop();
                      _showSnackBar(
                          context, 'Discharge summary saved successfully');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(successDialogContext).pop();
                      Methods().openPdf(driveLink);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HospitalTheme.primary,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    icon: Icon(Icons.open_in_new, size: 18),
                    label: Text(
                      'Open PDF',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        } else {
          _showSnackBar(context,
              'Failed to generate discharge summary: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else {
        _showSnackBar(context,
            'Failed to generate discharge summary. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (dialogContext != null && Navigator.of(dialogContext!).canPop()) {
        Navigator.of(dialogContext!).pop();
      }

      print('Error generating discharge summary: $e');
      _showSnackBar(
          context, 'Error generating discharge summary: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.patient.lastRecord;
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 1200;
    final isMediumScreen = screenSize.width > 800 && screenSize.width <= 1200;

    return WillPopScope(
      // ENHANCED: Handle back button to return changes flag
      onWillPop: () async {
        Navigator.of(context).pop(_hasChanges);
        return false;
      },
      child: Scaffold(
        backgroundColor: HospitalTheme.background,
        appBar: _buildAppBar(context),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildPatientHeader(),
                  const SizedBox(height: 20),
                  // Responsive layout based on screen width
                  if (isWideScreen) ...[
                    // Wide screen layout - two columns side by side
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column - Patient & Admission details
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              _buildInfoCard(
                                'Patient Information',
                                Icons.person_outline,
                                _buildPatientInfoContent(),
                              ),
                              const SizedBox(height: 16),
                              _buildInfoCard(
                                'Admission Details',
                                Icons.medical_services,
                                _buildAdmissionDetailsContent(record),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right column - Medical overview, discharge & actions
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              _buildMedicalInfoCard(record),
                              const SizedBox(height: 16),
                              _buildDischargeSection(),
                              const SizedBox(height: 16),
                              _buildActionButtons(record),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else if (isMediumScreen) ...[
                    // Medium screen layout - staggered columns
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column - Patient info & Medical overview
                        Expanded(
                          child: Column(
                            children: [
                              _buildInfoCard(
                                'Patient Information',
                                Icons.person_outline,
                                _buildPatientInfoContent(),
                              ),
                              const SizedBox(height: 16),
                              _buildMedicalInfoCard(record),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right column - Admission details, discharge & actions
                        Expanded(
                          child: Column(
                            children: [
                              _buildInfoCard(
                                'Admission Details',
                                Icons.medical_services,
                                _buildAdmissionDetailsContent(record),
                              ),
                              const SizedBox(height: 16),
                              _buildDischargeSection(),
                              const SizedBox(height: 16),
                              _buildActionButtons(record),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Mobile/small screen layout - single column
                    _buildInfoCard(
                      'Patient Information',
                      Icons.person_outline,
                      _buildPatientInfoContent(),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      'Admission Details',
                      Icons.medical_services,
                      _buildAdmissionDetailsContent(record),
                    ),
                    const SizedBox(height: 16),
                    _buildMedicalInfoCard(record),
                    const SizedBox(height: 16),
                    _buildDischargeSection(),
                    const SizedBox(height: 16),
                    _buildActionButtons(record),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build the patient info content separately to avoid code duplication
  Widget _buildPatientInfoContent() {
    return Column(
      children: [
        _buildInfoRow('Patient ID', widget.patient.patientId),
        _buildInfoRow('Gender', widget.patient.gender),
        _buildInfoRow('Contact', widget.patient.contact),
        _buildInfoRow(
            'Patient Type',
            widget.patient.lastRecord.patientType?.capitalizeFirst() ??
                'Unknown'),
        _buildInfoRow(
            'Doctor Type',
            widget.patient.lastRecord.doctor?.usertype?.capitalizeFirst() ??
                'Unknown'),
        _buildInfoRow(
            'Doctor Name', widget.patient.lastRecord.doctor?.name ?? 'Unknown'),
      ],
    );
  }

  // Build the admission details content separately
  Widget _buildAdmissionDetailsContent(record) {
    return Column(
      children: [
        _buildInfoRow('Admission ID', record.admissionId),
        _buildInfoRow('Admission Date', record.admissionDate),
        _buildInfoRow('Discharge Date', record.dischargeDate),
        _buildInfoRow('Reason', record.reasonForAdmission ?? 'Not specified'),
        _buildInfoRow('Symptoms', record.symptoms ?? 'Not specified'),
        _buildInfoRow('Diagnosis', record.initialDiagnosis ?? 'Not specified'),
        _buildInfoRow('Condition', record.conditionAtDischarge),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: HospitalTheme.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        // ENHANCED: Return changes flag when back button is pressed
        onPressed: () => Navigator.pop(context, _hasChanges),
      ),
      title: Text(
        widget.patient.name,
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      actions: [
        Tooltip(
          message: 'Print Details',
          child: IconButton(
            icon: Icon(Icons.print, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Print functionality coming soon')),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientHeader() {
    // Determine patient and doctor type for the header display
    final isInternalPatient =
        widget.patient.lastRecord.patientType?.toLowerCase() == 'internal';
    final doctorType =
        widget.patient.lastRecord.doctor?.usertype?.capitalizeFirst() ??
            'Unknown';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [HospitalTheme.primary, HospitalTheme.secondary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patient.name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Patient ID: ${widget.patient.patientId}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // Type badges
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Patient type badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isInternalPatient ? Icons.person : Icons.person_outline,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 5),
                    Text(
                      isInternalPatient
                          ? 'Internal Patient'
                          : 'External Patient',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 6),

              // Doctor type badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      doctorType.toLowerCase() == 'doctor'
                          ? Icons.medical_services
                          : Icons.person_pin,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 5),
                    Text(
                      '$doctorType Doctor',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, Widget content) {
    return Card(
      color: HospitalTheme.background,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: HospitalTheme.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: HospitalTheme.primary,
                  ),
                ),
              ],
            ),
            Divider(color: Colors.grey.shade200, thickness: 1, height: 24),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalInfoCard(record) {
    return Card(
      color: HospitalTheme.background,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_heart, color: HospitalTheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Medical Overview',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: HospitalTheme.primary,
                  ),
                ),
              ],
            ),
            Divider(color: Colors.grey.shade200, thickness: 1, height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildMedicalStat(
                      'Weight', '${record.weight} kg', Icons.line_weight),
                ),
                Expanded(
                  child: _buildMedicalStat('Previous Balance',
                      '${record.previousRemainingAmount}', Icons.attach_money),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildMedicalStat(
                'Amount Due', '${record.amountToBePayed}', Icons.payment),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalStat(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HospitalTheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: HospitalTheme.secondary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: HospitalTheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDischargeSection() {
    return Card(
      color: HospitalTheme.background,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.exit_to_app, color: HospitalTheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Discharge Control',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: HospitalTheme.primary,
                  ),
                ),
              ],
            ),
            Divider(color: Colors.grey.shade200, thickness: 1, height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Mark as Discharged',
                style: GoogleFonts.poppins(fontSize: 15),
              ),
              subtitle: Text(
                'Confirm patient discharge status',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              activeColor: HospitalTheme.secondary,
              activeTrackColor: HospitalTheme.secondary.withOpacity(0.2),
              value: _isDischargedByReception,
              onChanged: _toggleDischargeByReception,
            ),
            if (_isDischargedByReception)
              Container(
                margin: EdgeInsets.only(top: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Patient has been marked as discharged',
                        style: GoogleFonts.poppins(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(record) {
    return Card(
      color: HospitalTheme.background,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard_customize, color: HospitalTheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Actions',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: HospitalTheme.primary,
                  ),
                ),
              ],
            ),
            Divider(color: Colors.grey.shade200, thickness: 1, height: 24),
            Container(
              width: double.infinity,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.start,
                children: [
                  _buildActionButton(
                    'Generate Bill',
                    Icons.receipt_long,
                    Colors.blue,
                    () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GenerateIpdBillScreen(
                              patientId: widget.patient.patientId),
                        ),
                      );
                      // Mark changes if bill was generated
                      if (result == true) {
                        setState(() {
                          _hasChanges = true;
                        });
                      }
                    },
                  ),
                  _buildActionButton(
                    'Generate OPD Bill',
                    Icons.assignment,
                    Colors.orange,
                    () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OpdBillingScreen(
                            patientId: widget.patient.patientId,
                          ),
                        ),
                      );
                      // Mark changes if bill was generated
                      if (result == true) {
                        setState(() {
                          _hasChanges = true;
                        });
                      }
                    },
                  ),
                  _buildActionButton(
                    'View History',
                    Icons.history,
                    Colors.indigo,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientHistoryDetailScreen(
                            patientId: widget.patient.patientId),
                      ),
                    ),
                  ),
                  _buildActionButton(
                    'Print Summary',
                    Icons.print,
                    Colors.blueGrey,
                    () {
                      _generateDischargeSummary();
                    },
                  ),
                  _buildActionButton(
                    'Generate Manual Summary',
                    Icons.print,
                    Colors.blueGrey,
                    () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManualDischargeSummaryScreen(
                              patientId: widget.patient.patientId),
                        ),
                      );
                      // Mark changes if summary was generated
                      if (result == true) {
                        setState(() {
                          _hasChanges = true;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String text, IconData icon, Color color, VoidCallback onTap) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return ElevatedButton.icon(
      icon: Icon(icon, size: isSmallScreen ? 16 : 20),
      label: Text(
        text,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: isSmallScreen ? 12 : 14,
        ),
      ),
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 12 : 16,
            horizontal: isSmallScreen ? 12 : 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 3,
        shadowColor: Colors.black12,
      ),
    );
  }
}
