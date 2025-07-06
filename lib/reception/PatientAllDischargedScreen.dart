import 'dart:convert';
import 'dart:ffi';

import 'package:doctordesktop/Doctor/PatientHistoryDetailScreen.dart';
import 'package:doctordesktop/core/utils/PdfViewerScreen.dart';
import 'package:doctordesktop/pharmacy/pharmaTheme.dart';
import 'package:doctordesktop/reception/ManualDischargeSummaryScreen.dart';
import 'package:doctordesktop/reception/MedicalRecordSummaryScreen.dart';
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
// Enhanced data model with proper null safety and discharge summary
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
  final DischargeSummary? dischargeSummary;

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
    this.dischargeSummary,
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
      dischargeSummary: json['dischargeSummary'] != null
          ? DischargeSummary.fromJson(json['dischargeSummary'])
          : null,
    );
  }

  // Helper method to determine if this is an IPD admission
  bool get isIpdAdmission => ipdNumber != null && ipdNumber! > 0;

  // Helper method to get admission type
  String get admissionType => isIpdAdmission ? 'IPD' : 'OPD';

  // Helper method to check if discharge summary is available
  bool get hasDischargeSummary =>
      dischargeSummary != null &&
      dischargeSummary!.isGenerated &&
      dischargeSummary!.driveLink.isNotEmpty;
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

class DischargeSummary {
  final bool isGenerated;
  final bool isDoctorGenerated;
  final String fileName;
  final String driveLink;
  final String generatedBy;
  final String generatedAt;
  final String savedAt;
  final String? finalDiagnosis;
  final List<String> complaints;
  final List<String> pastHistory;
  final List<String> examFindings;
  final List<String> radiology;
  final List<String> pathology;
  final Operation? operation;
  final List<String> treatmentGiven;
  final String? conditionOnDischarge;
  final String template;
  final String version;
  final String originalAdmissionId;
  final String? archivedAt;
  final String? archiveReason;
  final String id;

  const DischargeSummary({
    required this.isGenerated,
    required this.isDoctorGenerated,
    required this.fileName,
    required this.driveLink,
    required this.generatedBy,
    required this.generatedAt,
    required this.savedAt,
    this.finalDiagnosis,
    required this.complaints,
    required this.pastHistory,
    required this.examFindings,
    required this.radiology,
    required this.pathology,
    this.operation,
    required this.treatmentGiven,
    this.conditionOnDischarge,
    required this.template,
    required this.version,
    required this.originalAdmissionId,
    this.archivedAt,
    this.archiveReason,
    required this.id,
  });

  factory DischargeSummary.fromJson(Map<String, dynamic> json) {
    return DischargeSummary(
      isGenerated: json['isGenerated'] as bool? ?? false,
      isDoctorGenerated: json['isDoctorGenerated'] as bool? ?? false,
      fileName: json['fileName']?.toString() ?? '',
      driveLink: json['driveLink']?.toString() ?? '',
      generatedBy: json['generatedBy']?.toString() ?? '',
      generatedAt: json['generatedAt']?.toString() ?? '',
      savedAt: json['savedAt']?.toString() ?? '',
      finalDiagnosis: json['finalDiagnosis']?.toString(),
      complaints: (json['complaints'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      pastHistory: (json['pastHistory'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      examFindings: (json['examFindings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      radiology: (json['radiology'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      pathology: (json['pathology'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      operation: json['operation'] != null
          ? Operation.fromJson(json['operation'])
          : null,
      treatmentGiven: (json['treatmentGiven'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      conditionOnDischarge: json['conditionOnDischarge']?.toString(),
      template: json['template']?.toString() ?? 'standard',
      version: json['version']?.toString() ?? '1.0',
      originalAdmissionId: json['originalAdmissionId']?.toString() ?? '',
      archivedAt: json['archivedAt']?.toString(),
      archiveReason: json['archiveReason']?.toString(),
      id: json['_id']?.toString() ?? '',
    );
  }

  // Helper method to format generated date
  String get formattedGeneratedAt {
    try {
      final dateTime = DateTime.parse(generatedAt);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return generatedAt;
    }
  }

  // Helper method to get summary of complaints
  String get complaintsText {
    if (complaints.isEmpty) return 'Not specified';
    return complaints.join(', ');
  }

  // Helper method to get summary of exam findings
  String get examFindingsText {
    if (examFindings.isEmpty) return 'Not specified';
    return examFindings.join(', ');
  }
}

class Operation {
  final List<String> procedure;

  const Operation({
    required this.procedure,
  });

  factory Operation.fromJson(Map<String, dynamic> json) {
    return Operation(
      procedure: (json['Procedure'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  String get procedureText {
    if (procedure.isEmpty) return 'No procedures';
    return procedure.join(', ');
  }
}

// Extension for capitalizing first letter

// Enhanced state notifier with better error handling and empty state distinction
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

      debugPrint(
          'Fetching discharged patients - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = response.body;

        // Handle empty response
        if (responseBody.isEmpty || responseBody.trim() == '[]') {
          debugPrint('Empty response received - no patients found');
          state = const AsyncValue.data([]);
          return;
        }

        try {
          final dynamic decodedData = json.decode(responseBody);

          // Handle different response formats
          List<dynamic> data;
          if (decodedData is List) {
            data = decodedData;
          } else if (decodedData is Map<String, dynamic>) {
            // If response is wrapped in an object, extract the array
            data = decodedData['data'] ?? decodedData['patients'] ?? [];
          } else {
            debugPrint(
                'Unexpected response format: ${decodedData.runtimeType}');
            data = [];
          }

          if (data.isEmpty) {
            debugPrint('No patients found in response');
            state = const AsyncValue.data([]);
            return;
          }

          final patients = data
              .map((json) =>
                  PatientDischarge.fromJson(json as Map<String, dynamic>))
              .toList();

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

          debugPrint('Successfully loaded ${patients.length} patients');
          state = AsyncValue.data(patients);
        } catch (parseError) {
          debugPrint('JSON parsing error: $parseError');
          debugPrint('Response body: $responseBody');
          state = AsyncValue.error(
            'Failed to parse server response. Please try again.',
            StackTrace.current,
          );
        }
      } else if (response.statusCode == 404) {
        // Handle 404 as no patients found rather than error
        debugPrint('API endpoint returned 404 - treating as no patients found');
        state = const AsyncValue.data([]);
      } else {
        throw Exception(
            'Server error ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'}');
      }
    } on http.ClientException catch (e) {
      debugPrint('Network error: $e');
      state = AsyncValue.error(
        'Network connection failed. Please check your internet connection.',
        StackTrace.current,
      );
    } on FormatException catch (e) {
      debugPrint('Data format error: $e');
      state = AsyncValue.error(
        'Received invalid data from server. Please try again.',
        StackTrace.current,
      );
    } catch (e) {
      debugPrint('Unexpected error fetching discharged patients: $e');
      state = AsyncValue.error(
        'An unexpected error occurred. Please try again.',
        StackTrace.current,
      );
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
                      onRefresh: _refreshData,
                    ),
                    _PatientListView(
                      key: const ValueKey('internal'),
                      patientsAsync: filteredPatientsAsync,
                      listKey: 'internal',
                      scrollController: _scrollControllers['internal']!,
                      isWideScreen: isWideScreen,
                      onRefresh: _refreshData,
                    ),
                    _PatientListView(
                      key: const ValueKey('external'),
                      patientsAsync: filteredPatientsAsync,
                      listKey: 'external',
                      scrollController: _scrollControllers['external']!,
                      isWideScreen: isWideScreen,
                      onRefresh: _refreshData,
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

// Patient list view component with enhanced empty state handling
class _PatientListView extends StatelessWidget {
  final AsyncValue<Map<String, List<PatientDischarge>>> patientsAsync;
  final String listKey;
  final ScrollController scrollController;
  final bool isWideScreen;
  final VoidCallback onRefresh;

  const _PatientListView({
    super.key,
    required this.patientsAsync,
    required this.listKey,
    required this.scrollController,
    required this.isWideScreen,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return patientsAsync.when(
      data: (patientsMap) {
        final patients = patientsMap[listKey] ?? [];
        final allPatients = patientsMap['all'] ?? [];

        // Determine if this is a filter result or truly empty
        final hasFiltersApplied = _hasActiveFilters(context);
        final isFilteredEmpty =
            patients.isEmpty && allPatients.isNotEmpty && hasFiltersApplied;
        final isTrulyEmpty = allPatients.isEmpty;

        if (isTrulyEmpty) {
          return _EmptyDataState(onRefresh: onRefresh);
        } else if (isFilteredEmpty) {
          return _NoMatchesState(onClearFilters: () => _clearFilters(context));
        } else if (patients.isEmpty) {
          return _EmptyTabState(tabName: _getTabDisplayName(listKey));
        }

        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: Scrollbar(
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
          ),
        );
      },
      loading: () => const _LoadingState(),
      error: (error, _) => _ErrorState(
        error: error,
        onRetry: onRefresh,
      ),
    );
  }

  bool _hasActiveFilters(BuildContext context) {
    // This would need to be passed down or accessed via provider
    // For now, we'll assume this method exists
    return false; // Simplified - you'd implement actual filter checking
  }

  void _clearFilters(BuildContext context) {
    // This would clear all filters
    // Implementation would depend on your state management
  }

  String _getTabDisplayName(String key) {
    switch (key) {
      case 'internal':
        return 'internal patients';
      case 'external':
        return 'external patients';
      default:
        return 'patients';
    }
  }
}

// Enhanced empty states with better UX
class _EmptyDataState extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyDataState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: HospitalTheme.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 64,
                color: HospitalTheme.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Discharged Patients Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'No patients have been discharged yet.\nPatients will appear here once they are discharged.',
              style: TextStyle(
                fontSize: 16,
                color: HospitalTheme.textMedium,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HospitalTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoMatchesState extends StatelessWidget {
  final VoidCallback onClearFilters;

  const _NoMatchesState({required this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 64,
                color: Colors.orange.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Matches Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'No patients match your current search and filter criteria.\nTry adjusting your filters or search terms.',
              style: TextStyle(
                fontSize: 16,
                color: HospitalTheme.textMedium,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.filter_list_off),
              label: const Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTabState extends StatelessWidget {
  final String tabName;

  const _EmptyTabState({required this.tabName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: HospitalTheme.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline,
                size: 64,
                color: HospitalTheme.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No ${tabName.capitalizeFirst()}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'There are no $tabName in the system at the moment.',
              style: TextStyle(
                fontSize: 16,
                color: HospitalTheme.textMedium,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
          content: const Row(
            children: [
              Icon(Icons.refresh, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Patient data refreshed'),
            ],
          ),
          backgroundColor: HospitalTheme.primary,
          duration: const Duration(seconds: 2),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: HospitalTheme.primary),
          const SizedBox(height: 16),
          Text(
            'Loading patients...',
            style: TextStyle(
              color: HospitalTheme.textMedium,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// Error state component with better messaging
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to Load Patients',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error.toString(),
              style: TextStyle(
                fontSize: 16,
                color: HospitalTheme.textMedium,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HospitalTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
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

class PatientDetailsScreen extends ConsumerStatefulWidget {
  final PatientDischarge patient;

  const PatientDetailsScreen({Key? key, required this.patient})
      : super(key: key);

  @override
  ConsumerState<PatientDetailsScreen> createState() =>
      _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends ConsumerState<PatientDetailsScreen>
    with TickerProviderStateMixin {
  final TextEditingController _billingAmountController =
      TextEditingController();
  final TextEditingController _amountPaidController = TextEditingController();
  bool _isDischargedByReception = false;
  bool _hasChanges = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _isDischargedByReception = widget.patient.lastRecord.dischargedByReception;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _billingAmountController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  void _showSnackBar(BuildContext context, String message,
      {bool isSuccess = false}) {
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
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? HospitalTheme.success : HospitalTheme.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
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
            shape: RoundedRectangleBorder(
              borderRadius: HospitalTheme.radiusLarge,
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HospitalTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: HospitalTheme.warning,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Confirm Discharge',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to discharge this patient? This action will update the patient\'s status.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: HospitalTheme.textMedium,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: HospitalTheme.textMedium,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: HospitalTheme.radiusSmall,
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HospitalTheme.warning,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: HospitalTheme.radiusSmall,
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Confirm',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
        _hasChanges = true;
        _showSnackBar(context, "Patient discharged successfully.",
            isSuccess: true);
      } else {
        setState(() {
          _isDischargedByReception = false;
        });
        _showSnackBar(
            context, "Failed to discharge patient: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _isDischargedByReception = false;
      });
      _showSnackBar(context, "Error: $e");
    }
  }

  Future<void> _generateDischargeSummary() async {
    BuildContext? dialogContext;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) {
          dialogContext = ctx;
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
                  'Generating discharge summary...',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: HospitalTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we prepare your document',
                  style: GoogleFonts.poppins(
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

      final response = await http.get(
        Uri.parse(
            '${KVM_URL}/reception/generateDischargeSummary/${widget.patient.patientId}'),
      );

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

          _hasChanges = true;

          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext successDialogContext) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: HospitalTheme.radiusLarge,
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: HospitalTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: HospitalTheme.success,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Summary Generated',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.textDark,
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
                        color: HospitalTheme.textMedium,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            HospitalTheme.primary.withOpacity(0.1),
                            HospitalTheme.secondary.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: HospitalTheme.radiusMedium,
                        border: Border.all(
                          color: HospitalTheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: HospitalTheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PDF Document',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: HospitalTheme.textMedium,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  fileName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: HospitalTheme.textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Would you like to open the PDF document now?',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(successDialogContext).pop();
                      _showSnackBar(
                          context, 'Discharge summary saved successfully',
                          isSuccess: true);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: HospitalTheme.textMedium,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: HospitalTheme.radiusSmall,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: HospitalTheme.radiusSmall,
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.open_in_new, size: 18),
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

  void _openDischargeSummaryPdf() {
    final dischargeSummary = widget.patient.lastRecord.dischargeSummary;
    if (dischargeSummary != null && dischargeSummary.driveLink.isNotEmpty) {
      final pdfNotifier = ref.read(pdfViewerProvider.notifier);
      pdfNotifier.loadAndShowPdf(
        dischargeSummary.driveLink,
        title: dischargeSummary.fileName.isNotEmpty
            ? dischargeSummary.fileName
            : 'Discharge Summary',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.patient.lastRecord;
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 1200;
    final isMediumScreen = screenSize.width > 800 && screenSize.width <= 1200;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          Navigator.of(context).pop(_hasChanges);
        },
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
          // Future: Add search functionality
        },
      },
      child: Focus(
        autofocus: true,
        child: PdfViewerWidget(
          primaryColor: HospitalTheme.primary,
          appBarTitle: 'Discharge Summary - ${widget.patient.name}',
          child: WillPopScope(
            onWillPop: () async {
              Navigator.of(context).pop(_hasChanges);
              return false;
            },
            child: Scaffold(
              backgroundColor: const Color(0xFFF0F4F8),
              appBar: _buildAppBar(context),
              body: SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Header and Medical Overview Row - Always same width and height
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: _buildPatientHeader(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: _buildMedicalInfoCard(record),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Discharge Summary Section - Always visible at top if available
                        if (record.hasDischargeSummary) ...[
                          _buildDischargeSummaryCard(record.dischargeSummary!),
                          const SizedBox(height: 16),
                        ],

                        if (isWideScreen) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    _buildPatientInfoCard(),
                                    const SizedBox(height: 16),
                                    _buildAdmissionDetailsCard(record),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    _buildDischargeSection(),
                                    const SizedBox(height: 16),
                                    _buildActionButtons(record),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ] else if (isMediumScreen) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildPatientInfoCard(),
                                    const SizedBox(height: 16),
                                    _buildDischargeSection(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildAdmissionDetailsCard(record),
                                    const SizedBox(height: 16),
                                    _buildActionButtons(record),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          _buildPatientInfoCard(),
                          const SizedBox(height: 16),
                          _buildAdmissionDetailsCard(record),
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context, _hasChanges);
        },
      ),
      title: Text(
        widget.patient.name,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      actions: [
        if (widget.patient.lastRecord.hasDischargeSummary)
          Tooltip(
            message: 'View Discharge Summary',
            child: IconButton(
              icon:
                  const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
              onPressed: () {
                HapticFeedback.lightImpact();
                _openDischargeSummaryPdf();
              },
            ),
          ),
        Tooltip(
          message: 'Print Details',
          child: IconButton(
            icon: const Icon(Icons.print_rounded, color: Colors.white),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showSnackBar(context, 'Print functionality coming soon');
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(Icons.person_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildDischargeSummaryCard(DischargeSummary dischargeSummary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16), // Reduced from 20
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HospitalTheme.success.withOpacity(0.03), // More subtle
            HospitalTheme.primary.withOpacity(0.01),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12), // Reduced from 16
        border: Border.all(
            color: HospitalTheme.success.withOpacity(0.2)), // More subtle
        boxShadow: [
          BoxShadow(
            color: HospitalTheme.success.withOpacity(0.05), // Reduced shadow
            blurRadius: 8, // Reduced from 15
            offset: const Offset(0, 2), // Reduced from 5
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8), // Reduced from 12
                decoration: BoxDecoration(
                  color:
                      HospitalTheme.success, // Solid color instead of gradient
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: Colors.white,
                  size: 20, // Reduced from 24
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discharge Summary Available',
                      style: GoogleFonts.poppins(
                        fontSize: 16, // Reduced from 18
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                    Text(
                      'Generated on ${dischargeSummary.formattedGeneratedAt}',
                      style: GoogleFonts.poppins(
                        fontSize: 12, // Reduced from 13
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              // Compact badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4), // Reduced padding
                decoration: BoxDecoration(
                  color: HospitalTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: HospitalTheme.success.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  dischargeSummary.isDoctorGenerated ? 'Doctor' : 'Auto',
                  style: GoogleFonts.poppins(
                    fontSize: 10, // Reduced from 12
                    fontWeight: FontWeight.w600,
                    color: HospitalTheme.success,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12), // Reduced from 20

          // Compact Content
          Container(
            padding: const EdgeInsets.all(12), // Reduced from 16
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8), // Reduced from 12
              border: Border.all(color: HospitalTheme.border.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PDF Info - Single row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6), // Reduced from 8
                      decoration: BoxDecoration(
                        color: HospitalTheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Colors.white,
                        size: 16, // Reduced from 20
                      ),
                    ),
                    const SizedBox(width: 8), // Reduced from 12
                    Expanded(
                      child: Text(
                        dischargeSummary.fileName.isNotEmpty
                            ? dischargeSummary.fileName
                            : 'Discharge Summary',
                        style: GoogleFonts.poppins(
                          fontSize: 13, // Reduced from 14
                          fontWeight: FontWeight.w600,
                          color: HospitalTheme.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Compact medical info - only if available
                if (dischargeSummary.finalDiagnosis?.isNotEmpty == true ||
                    dischargeSummary.complaints.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Show only most important info in compact format
                  if (dischargeSummary.finalDiagnosis?.isNotEmpty == true)
                    _buildCompactInfoRow(
                      'Diagnosis',
                      dischargeSummary.finalDiagnosis!,
                      HospitalTheme.medical,
                    ),

                  if (dischargeSummary.complaints.isNotEmpty)
                    _buildCompactInfoRow(
                      'Complaints',
                      dischargeSummary.complaintsText,
                      HospitalTheme.emergency,
                    ),
                ],

                const SizedBox(height: 8), // Reduced from 16

                // Compact Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openDischargeSummaryPdf,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HospitalTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8), // Reduced padding
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(6), // Reduced radius
                          ),
                          elevation: 1, // Reduced elevation
                        ),
                        icon: const Icon(Icons.visibility_rounded,
                            size: 16), // Reduced size
                        label: Text(
                          'View',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12, // Reduced font size
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8), // Reduced from 12
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Methods().openPdf(dischargeSummary.driveLink);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: HospitalTheme.primary,
                          side: BorderSide(
                              color: HospitalTheme.primary, width: 1),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8), // Reduced padding
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(6), // Reduced radius
                          ),
                        ),
                        icon: const Icon(Icons.print_rounded,
                            size: 16), // Reduced size
                        label: Text(
                          'Open',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12, // Reduced font size
                          ),
                        ),
                      ),
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

// Add this helper method for compact info rows
  Widget _buildCompactInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: HospitalTheme.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryInfoRow(
      String label, String value, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: HospitalTheme.textMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPatientHeader() {
    final isInternalPatient =
        widget.patient.lastRecord.patientType?.toLowerCase() == 'internal';
    final doctorType =
        widget.patient.lastRecord.doctor?.name?.capitalizeFirst() ?? 'Unknown';

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
                  Icons.person_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.patient.name,
                      style: GoogleFonts.poppins(
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.badge_rounded,
                            color: Colors.black,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ID: ${widget.patient.patientId}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: isInternalPatient
                        ? const LinearGradient(
                            colors: [Color(0xFF2196F3), Color(0xFF64B5F6)])
                        : const LinearGradient(
                            colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isInternalPatient ? Colors.blue : Colors.purple)
                            .withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isInternalPatient
                            ? Icons.home_rounded
                            : Icons.person_outline_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isInternalPatient ? 'Internal' : 'External',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Patient',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrange.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.medical_services_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Doctor',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        doctorType,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFAFBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HospitalTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      HospitalTheme.primary,
                      HospitalTheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: HospitalTheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Patient Information',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildColorfulInfoRow('Patient ID', widget.patient.patientId,
              Icons.badge_rounded, const Color(0xFF3F51B5)),
          _buildColorfulInfoRow('Gender', widget.patient.gender,
              Icons.person_rounded, const Color(0xFFE91E63)),
          _buildColorfulInfoRow('Contact', widget.patient.contact,
              Icons.phone_rounded, const Color(0xFF4CAF50)),
          _buildColorfulInfoRow(
            'Patient Type',
            widget.patient.lastRecord.patientType?.capitalizeFirst() ??
                'Unknown',
            Icons.category_rounded,
            const Color(0xFFFF9800),
          ),
          _buildColorfulInfoRow(
            'Doctor Type',
            widget.patient.lastRecord.doctor?.usertype?.capitalizeFirst() ??
                'Unknown',
            Icons.medical_services_rounded,
            const Color(0xFF9C27B0),
          ),
          _buildColorfulInfoRow(
            'Doctor Name',
            widget.patient.lastRecord.doctor?.name ?? 'Unknown',
            Icons.person_pin_rounded,
            const Color(0xFF795548),
          ),
        ],
      ),
    );
  }

  Widget _buildAdmissionDetailsCard(record) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFAFBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HospitalTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [HospitalTheme.medical, HospitalTheme.pharmacy],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: HospitalTheme.medical.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.medical_services_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Admission Details',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildColorfulInfoRow('Admission ID', record.admissionId,
              Icons.confirmation_number_rounded, const Color(0xFF2196F3)),
          _buildColorfulInfoRow('Admission Date', record.admissionDate,
              Icons.calendar_today_rounded, const Color(0xFF4CAF50)),
          _buildColorfulInfoRow('Discharge Date', record.dischargeDate,
              Icons.event_available_rounded, const Color(0xFFFF9800)),
          _buildColorfulInfoRow(
              'Reason',
              record.reasonForAdmission ?? 'Not specified',
              Icons.description_rounded,
              const Color(0xFFE91E63)),
          _buildColorfulInfoRow('Symptoms', record.symptoms ?? 'Not specified',
              Icons.sick_rounded, const Color(0xFFFF5722)),
          _buildColorfulInfoRow(
              'Diagnosis',
              record.initialDiagnosis ?? 'Not specified',
              Icons.sick,
              const Color(0xFF795548)),
          _buildColorfulInfoRow('Condition', record.conditionAtDischarge,
              Icons.health_and_safety_rounded, const Color(0xFF607D8B)),
        ],
      ),
    );
  }

  Widget _buildColorfulInfoRow(
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
              style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(
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

  Widget _buildMedicalInfoCard(record) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFAFBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HospitalTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [HospitalTheme.laboratory, HospitalTheme.emergency],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: HospitalTheme.laboratory.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.monitor_heart_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Medical Overview',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMedicalStat(
                  'Weight',
                  '${record.weight} kg',
                  Icons.line_weight_rounded,
                  HospitalTheme.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMedicalStat(
                  'Previous Balance',
                  '₹${record.previousRemainingAmount}',
                  Icons.account_balance_wallet_rounded,
                  HospitalTheme.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMedicalStat(
            'Amount Due',
            '₹${record.amountToBePayed}',
            Icons.payment_rounded,
            HospitalTheme.error,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalStat(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.08),
            color.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: HospitalTheme.textMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDischargeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFAFBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HospitalTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isDischargedByReception
                        ? [
                            HospitalTheme.success,
                            HospitalTheme.success.withOpacity(0.7)
                          ]
                        : [HospitalTheme.secondary, HospitalTheme.accent],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (_isDischargedByReception
                              ? HospitalTheme.success
                              : HospitalTheme.secondary)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _isDischargedByReception
                      ? Icons.check_circle_rounded
                      : Icons.exit_to_app_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Discharge Control',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isDischargedByReception
                    ? [
                        HospitalTheme.success.withOpacity(0.05),
                        HospitalTheme.success.withOpacity(0.02)
                      ]
                    : [
                        HospitalTheme.surfaceLight.withOpacity(0.5),
                        Colors.white
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDischargedByReception
                    ? HospitalTheme.success.withOpacity(0.2)
                    : HospitalTheme.border,
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Mark as Discharged',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                  subtitle: Text(
                    'Confirm patient discharge status',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: HospitalTheme.textMedium,
                    ),
                  ),
                  activeColor: HospitalTheme.success,
                  activeTrackColor: HospitalTheme.success.withOpacity(0.3),
                  inactiveThumbColor: HospitalTheme.textLight,
                  inactiveTrackColor: HospitalTheme.border,
                  value: _isDischargedByReception,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    _toggleDischargeByReception(value);
                  },
                ),
                if (_isDischargedByReception) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          HospitalTheme.success.withOpacity(0.1),
                          HospitalTheme.success.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: HospitalTheme.success.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: HospitalTheme.success,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Patient has been marked as discharged',
                            style: GoogleFonts.poppins(
                              color: HospitalTheme.success,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
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
      ),
    );
  }

  Widget _buildActionButtons(record) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFAFBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HospitalTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [HospitalTheme.accent, HospitalTheme.primary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: HospitalTheme.accent.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.dashboard_customize_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Quick Actions',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildModernActionButton(
                'Generate Bill',
                Icons.receipt_long_rounded,
                [const Color(0xFF3B82F6), const Color(0xFF1E40AF)],
                () async {
                  HapticFeedback.mediumImpact();
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GenerateIpdBillScreen(
                          patientId: widget.patient.patientId),
                    ),
                  );
                  if (result == true) {
                    setState(() {
                      _hasChanges = true;
                    });
                  }
                },
              ),
              _buildModernActionButton(
                'OPD Bill',
                Icons.assignment_rounded,
                [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                () async {
                  HapticFeedback.mediumImpact();
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OpdBillingScreen(
                        patientId: widget.patient.patientId,
                      ),
                    ),
                  );
                  if (result == true) {
                    setState(() {
                      _hasChanges = true;
                    });
                  }
                },
              ),
              _buildModernActionButton(
                'History',
                Icons.history_rounded,
                [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientHistoryDetailScreen(
                          patientId: widget.patient.patientId),
                    ),
                  );
                },
              ),
              _buildModernActionButton(
                'Medical Summary',
                Icons.medical_information_rounded,
                [const Color(0xFF059669), const Color(0xFF047857)],
                () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MedicalRecordSummaryScreen(
                          initialPatientId: widget.patient.patientId),
                    ),
                  );
                },
              ),
              _buildModernActionButton(
                'Print Summary',
                Icons.print_rounded,
                [const Color(0xFF7C3AED), const Color(0xFF6D28D9)],
                () {
                  HapticFeedback.mediumImpact();
                  _generateDischargeSummary();
                },
              ),
              _buildModernActionButton(
                'Manual Summary',
                Icons.edit_note_rounded,
                [const Color(0xFFDC2626), const Color(0xFFB91C1C)],
                () async {
                  HapticFeedback.mediumImpact();
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManualDischargeSummaryScreen(
                          patientId: widget.patient.patientId),
                    ),
                  );
                  if (result == true) {
                    setState(() {
                      _hasChanges = true;
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionButton(
    String label,
    IconData icon,
    List<Color> gradientColors,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                // Background patterns
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
