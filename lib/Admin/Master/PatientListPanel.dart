// File: lib/screens/patient_management_screen.dart

import 'package:doctordesktop/Admin/Master/apis.dart';
import 'package:doctordesktop/Admin/Master/constants.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/core/utils/PdfViewerScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:async';

// ==================== MODELS ====================

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
  final List<AdmissionRecord> admissionRecords;
  final String? city;
  final String? country;
  final String? dob;
  final String? state;

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
    required this.admissionRecords,
    this.city,
    this.country,
    this.dob,
    this.state,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['_id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      age: _safeParseInt(json['age'], 0),
      gender: json['gender']?.toString() ?? '',
      contact: json['contact']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString().isEmpty == true
          ? null
          : json['imageUrl']?.toString(),
      discharged: json['discharged'] ?? false,
      pendingAmount: _safeParseDouble(json['pendingAmount'], 0.0),
      admissionRecords: (json['admissionRecords'] as List<dynamic>?)
              ?.map((record) =>
                  AdmissionRecord.fromJson(record as Map<String, dynamic>))
              .where((record) => record != null)
              .cast<AdmissionRecord>()
              .toList() ??
          [],
      city: json['city']?.toString(),
      country: json['country']?.toString(),
      dob: json['dob']?.toString(),
      state: json['state']?.toString(),
    );
  }

  static int _safeParseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  static double _safeParseDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  Patient copyWith({
    String? id,
    String? patientId,
    String? name,
    int? age,
    String? gender,
    String? contact,
    String? address,
    String? imageUrl,
    bool? discharged,
    double? pendingAmount,
    List<AdmissionRecord>? admissionRecords,
    String? city,
    String? country,
    String? dob,
    String? state,
  }) {
    return Patient(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      contact: contact ?? this.contact,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      discharged: discharged ?? this.discharged,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      admissionRecords: admissionRecords ?? this.admissionRecords,
      city: city ?? this.city,
      country: country ?? this.country,
      dob: dob ?? this.dob,
      state: state ?? this.state,
    );
  }
}

class AdmissionRecord {
  final String id;
  final Doctor? doctor;
  final int? opdNumber;
  final int? ipdNumber;
  final DateTime? admissionDate;
  final DateTime? dischargeDate;
  final String status;
  final String patientType;
  final String conditionAtDischarge;
  final double? weight;
  final String? admitNotes;
  final String? reasonForAdmission;
  final double? amountToBePayed;
  final String? symptoms;
  final String? initialDiagnosis;
  final int? bedNumber;

  const AdmissionRecord({
    required this.id,
    this.doctor,
    this.opdNumber,
    this.ipdNumber,
    this.admissionDate,
    this.dischargeDate,
    required this.status,
    required this.patientType,
    required this.conditionAtDischarge,
    this.weight,
    this.admitNotes,
    this.reasonForAdmission,
    this.amountToBePayed,
    this.symptoms,
    this.initialDiagnosis,
    this.bedNumber,
  });

  factory AdmissionRecord.fromJson(Map<String, dynamic> json) {
    try {
      return AdmissionRecord(
        id: json['_id']?.toString() ?? '',
        doctor: json['doctor'] != null
            ? Doctor.fromJson(json['doctor'] as Map<String, dynamic>)
            : null,
        opdNumber: _safeParseInt(json['opdNumber'], null),
        ipdNumber: _safeParseInt(json['ipdNumber'], null),
        admissionDate: _safeParseDateTime(json['admissionDate']),
        dischargeDate: _safeParseDateTime(json['dischargeDate']),
        status: json['status']?.toString() ?? 'Unknown',
        patientType: json['patientType']?.toString() ?? '',
        conditionAtDischarge: json['conditionAtDischarge']?.toString() ?? '',
        weight: _safeParseDouble(json['weight'], null),
        admitNotes: json['admitNotes']?.toString(),
        reasonForAdmission: json['reasonForAdmission']?.toString(),
        amountToBePayed: _safeParseDouble(json['amountToBePayed'], null),
        symptoms: json['symptoms']?.toString(),
        initialDiagnosis: json['initialDiagnosis']?.toString(),
        bedNumber: _safeParseInt(json['bedNumber'], null),
      );
    } catch (e) {
      print('Error parsing AdmissionRecord: $e');
      print('JSON data: $json');

      return AdmissionRecord(
        id: json['_id']?.toString() ?? '',
        doctor: null,
        opdNumber: null,
        ipdNumber: null,
        admissionDate: null,
        dischargeDate: null,
        status: json['status']?.toString() ?? 'Unknown',
        patientType: json['patientType']?.toString() ?? 'Unknown',
        conditionAtDischarge:
            json['conditionAtDischarge']?.toString() ?? 'Unknown',
        weight: null,
        admitNotes: json['admitNotes']?.toString(),
        reasonForAdmission: json['reasonForAdmission']?.toString(),
        amountToBePayed: null,
        symptoms: json['symptoms']?.toString(),
        initialDiagnosis: json['initialDiagnosis']?.toString(),
        bedNumber: null,
      );
    }
  }

  static int? _safeParseInt(dynamic value, int? defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) {
      if (value.trim().isEmpty) return defaultValue;
      return int.tryParse(value.trim()) ?? defaultValue;
    }
    if (value is double) return value.toInt();
    return defaultValue;
  }

  static double? _safeParseDouble(dynamic value, double? defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      if (value.trim().isEmpty) return defaultValue;
      return double.tryParse(value.trim()) ?? defaultValue;
    }
    return defaultValue;
  }

  static DateTime? _safeParseDateTime(dynamic value) {
    if (value == null) return null;

    try {
      String dateString = value.toString().trim();
      if (dateString.isEmpty) return null;

      List<String> formats = [
        "yyyy-MM-ddTHH:mm:ss.SSSZ",
        "yyyy-MM-ddTHH:mm:ssZ",
        "yyyy-MM-ddTHH:mm:ss.SSS",
        "yyyy-MM-ddTHH:mm:ss",
        "yyyy-MM-dd HH:mm:ss",
        "yyyy-MM-dd",
        "dd/MM/yyyy HH:mm:ss",
        "dd/MM/yyyy",
        "MM/dd/yyyy HH:mm:ss",
        "MM/dd/yyyy",
        "dd-MM-yyyy HH:mm:ss",
        "dd-MM-yyyy",
      ];

      DateTime? parsedDate = DateTime.tryParse(dateString);
      if (parsedDate != null) return parsedDate;

      for (String format in formats) {
        try {
          DateFormat formatter = DateFormat(format);
          return formatter.parse(dateString);
        } catch (e) {
          continue;
        }
      }

      print('Failed to parse date: $dateString');
      return null;
    } catch (e) {
      print('Error parsing date $value: $e');
      return null;
    }
  }

  AdmissionRecord copyWith({
    String? id,
    Doctor? doctor,
    int? opdNumber,
    int? ipdNumber,
    DateTime? admissionDate,
    DateTime? dischargeDate,
    String? status,
    String? patientType,
    String? conditionAtDischarge,
    double? weight,
    String? admitNotes,
    String? reasonForAdmission,
    double? amountToBePayed,
    String? symptoms,
    String? initialDiagnosis,
    int? bedNumber,
  }) {
    return AdmissionRecord(
      id: id ?? this.id,
      doctor: doctor ?? this.doctor,
      opdNumber: opdNumber ?? this.opdNumber,
      ipdNumber: ipdNumber ?? this.ipdNumber,
      admissionDate: admissionDate ?? this.admissionDate,
      dischargeDate: dischargeDate ?? this.dischargeDate,
      status: status ?? this.status,
      patientType: patientType ?? this.patientType,
      conditionAtDischarge: conditionAtDischarge ?? this.conditionAtDischarge,
      weight: weight ?? this.weight,
      admitNotes: admitNotes ?? this.admitNotes,
      reasonForAdmission: reasonForAdmission ?? this.reasonForAdmission,
      amountToBePayed: amountToBePayed ?? this.amountToBePayed,
      symptoms: symptoms ?? this.symptoms,
      initialDiagnosis: initialDiagnosis ?? this.initialDiagnosis,
      bedNumber: bedNumber ?? this.bedNumber,
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
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      usertype: json['usertype']?.toString() ?? 'doctor',
    );
  }
}

class PaginationInfo {
  final int current;
  final int total;
  final int count;
  final int totalRecords;

  const PaginationInfo({
    required this.current,
    required this.total,
    required this.count,
    required this.totalRecords,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      current: _safeParseInt(json['current'], 1),
      total: _safeParseInt(json['total'], 1),
      count: _safeParseInt(json['count'], 0),
      totalRecords: _safeParseInt(json['totalRecords'], 0),
    );
  }

  static int _safeParseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    if (value is double) return value.toInt();
    return defaultValue;
  }

  // Add helper properties for pagination UI
  bool get hasNextPage => current < total;
  bool get hasPreviousPage => current > 1;
  int get startRecord => ((current - 1) * count) + 1;
  int get endRecord =>
      current * count > totalRecords ? totalRecords : current * count;
}

class NextAvailableNumbers {
  final int nextOPDNumber;
  final int nextIPDNumber;

  const NextAvailableNumbers({
    required this.nextOPDNumber,
    required this.nextIPDNumber,
  });

  factory NextAvailableNumbers.fromJson(Map<String, dynamic> json) {
    return NextAvailableNumbers(
      nextOPDNumber: json['nextOPDNumber']?.toInt() ?? 1,
      nextIPDNumber: json['nextIPDNumber']?.toInt() ?? 1,
    );
  }
}

// ==================== STATE MANAGEMENT ====================

class PatientListState {
  final List<Patient> patients;
  final bool isLoading;
  final String? error;
  final PaginationInfo? pagination;
  final String searchQuery;
  final String sortOrder;

  const PatientListState({
    this.patients = const [],
    this.isLoading = false,
    this.error,
    this.pagination,
    this.searchQuery = '',
    this.sortOrder = 'asc',
  });

  PatientListState copyWith({
    List<Patient>? patients,
    bool? isLoading,
    String? error,
    PaginationInfo? pagination,
    String? searchQuery,
    String? sortOrder,
  }) {
    return PatientListState(
      patients: patients ?? this.patients,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pagination: pagination ?? this.pagination,
      searchQuery: searchQuery ?? this.searchQuery,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class PatientListNotifier extends StateNotifier<PatientListState> {
  PatientListNotifier() : super(const PatientListState()) {
    loadPatients();
  }

  Future<void> loadPatients({int page = 1, int limit = 10}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await PatientApiService.getPatients(
        page: page,
        limit: limit,
        search: state.searchQuery,
        sortOrder: state.sortOrder,
      );

      final patients = (response['data'] as List<dynamic>)
          .map((json) {
            try {
              return Patient.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              print('Error parsing patient: $e');
              print('Patient data: $json');
              return null;
            }
          })
          .where((patient) => patient != null)
          .cast<Patient>()
          .toList();

      final pagination = PaginationInfo.fromJson(
          response['pagination'] as Map<String, dynamic>);

      state = state.copyWith(
        patients: patients,
        isLoading: false,
        pagination: pagination,
      );
    } catch (e) {
      String errorMessage;
      if (e is ApiException) {
        if (e.isNetworkError) {
          errorMessage = ApiConstants.networkErrorMessage;
        } else if (e.isServerError) {
          errorMessage = ApiConstants.serverErrorMessage;
        } else {
          errorMessage = e.message;
        }
      } else {
        errorMessage = ApiConstants.unknownErrorMessage;
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    }
  }

  // ADD: Pagination navigation methods
  Future<void> goToPage(int page) async {
    if (state.pagination != null &&
        page >= 1 &&
        page <= state.pagination!.total &&
        page != state.pagination!.current) {
      await loadPatients(page: page);
    }
  }

  Future<void> goToNextPage() async {
    if (state.pagination?.hasNextPage == true) {
      await loadPatients(page: state.pagination!.current + 1);
    }
  }

  Future<void> goToPreviousPage() async {
    if (state.pagination?.hasPreviousPage == true) {
      await loadPatients(page: state.pagination!.current - 1);
    }
  }

  Future<void> goToFirstPage() async {
    if (state.pagination != null && state.pagination!.current != 1) {
      await loadPatients(page: 1);
    }
  }

  Future<void> goToLastPage() async {
    if (state.pagination != null &&
        state.pagination!.current != state.pagination!.total) {
      await loadPatients(page: state.pagination!.total);
    }
  }

  // FIX: Enhanced updatePatientBasicInfo method with proper state management
  Future<Patient> updatePatientBasicInfo(
      String patientId, Map<String, dynamic> updates) async {
    try {
      final response =
          await PatientApiService.updatePatientBasicInfo(patientId, updates);

      final updatedPatientData = response['data'] as Map<String, dynamic>;
      final updatedPatient = Patient.fromJson(updatedPatientData);

      final updatedPatients = state.patients.map((patient) {
        if (patient.patientId == patientId) {
          return updatedPatient;
        }
        return patient;
      }).toList();

      state = state.copyWith(patients: updatedPatients);

      return updatedPatient;
    } catch (e) {
      String errorMessage;
      if (e is ApiException) {
        errorMessage = e.message;
      } else {
        errorMessage = 'Failed to update patient: $e';
      }
      state = state.copyWith(error: errorMessage);
      rethrow;
    }
  }

  Future<AdmissionRecord> updateAdmissionRecord(String patientId,
      String admissionId, Map<String, dynamic> updates) async {
    try {
      if (updates.containsKey('opdNumber') ||
          updates.containsKey('ipdNumber')) {
        final numberUpdates = <String, dynamic>{};
        if (updates.containsKey('opdNumber')) {
          numberUpdates['opdNumber'] = updates['opdNumber'];
        }
        if (updates.containsKey('ipdNumber')) {
          numberUpdates['ipdNumber'] = updates['ipdNumber'];
        }

        try {
          await PatientApiService.updateAdmissionNumbers(
              patientId, admissionId, numberUpdates);
        } catch (e) {
          rethrow;
        }
      }

      final response = await PatientApiService.updateAdmissionRecord(
          patientId, admissionId, updates);

      final updatedAdmissionData = response['data'] as Map<String, dynamic>;
      final updatedAdmission = AdmissionRecord.fromJson(updatedAdmissionData);

      final updatedPatients = state.patients.map((patient) {
        if (patient.patientId == patientId) {
          final updatedRecords = patient.admissionRecords.map((record) {
            if (record.id == admissionId) {
              return updatedAdmission;
            }
            return record;
          }).toList();

          return patient.copyWith(admissionRecords: updatedRecords);
        }
        return patient;
      }).toList();

      state = state.copyWith(patients: updatedPatients);

      return updatedAdmission;
    } catch (e) {
      String errorMessage;
      if (e is ApiException) {
        errorMessage = e.message;
      } else {
        errorMessage = 'Failed to update admission: $e';
      }
      state = state.copyWith(error: errorMessage);
      rethrow;
    }
  }

  Future<void> searchPatients(String query) async {
    state = state.copyWith(searchQuery: query);
    await loadPatients(page: 1); // Reset to first page when searching
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> refreshPatients() async {
    await loadPatients(page: state.pagination?.current ?? 1);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> loadMorePatients() async {
    if (state.isLoading || state.pagination == null) return;

    final currentPage = state.pagination!.current;
    final totalPages = state.pagination!.total;

    if (currentPage < totalPages) {
      final nextPage = currentPage + 1;

      try {
        final response = await PatientApiService.getPatients(
          page: nextPage,
          limit: ApiConstants.defaultPageSize,
          search: state.searchQuery,
          sortOrder: state.sortOrder,
        );

        final newPatients = (response['data'] as List<dynamic>)
            .map((json) {
              try {
                return Patient.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                print('Error parsing patient: $e');
                return null;
              }
            })
            .where((patient) => patient != null)
            .cast<Patient>()
            .toList();

        final pagination = PaginationInfo.fromJson(
            response['pagination'] as Map<String, dynamic>);

        final allPatients = [...state.patients, ...newPatients];

        state = state.copyWith(
          patients: allPatients,
          pagination: pagination,
        );
      } catch (e) {
        state = state.copyWith(error: 'Failed to load more patients: $e');
      }
    }
  }
}

// Providers
final patientListProvider =
    StateNotifierProvider<PatientListNotifier, PatientListState>((ref) {
  return PatientListNotifier();
});

final selectedPatientProvider = StateProvider<Patient?>((ref) => null);
final selectedAdmissionProvider =
    StateProvider<AdmissionRecord?>((ref) => null);

final nextAvailableNumbersProvider =
    FutureProvider<NextAvailableNumbers>((ref) async {
  try {
    final response = await PatientApiService.getNextAvailableNumbers();
    return NextAvailableNumbers.fromJson(
        response['data'] as Map<String, dynamic>);
  } catch (e) {
    throw Exception('Failed to get next available numbers: $e');
  }
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final debouncedSearchProvider = Provider<String>((ref) {
  final query = ref.watch(searchQueryProvider);
  Timer? debounceTimer;
  debounceTimer?.cancel();
  return query;
});

// ==================== MAIN SCREEN ====================

class PatientManagementScreen extends ConsumerStatefulWidget {
  const PatientManagementScreen({super.key});

  @override
  ConsumerState<PatientManagementScreen> createState() =>
      _PatientManagementScreenState();
}

class _PatientManagementScreenState
    extends ConsumerState<PatientManagementScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ServicesBinding.instance.keyboard.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    _searchController.dispose();
    ServicesBinding.instance.keyboard.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if ((HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed) &&
          event.logicalKey == LogicalKeyboardKey.keyF) {
        _searchController.clear();
        _searchController.text = '';
        return true;
      }

      if ((HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed) &&
          event.logicalKey == LogicalKeyboardKey.keyR) {
        ref.read(patientListProvider.notifier).refreshPatients();
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width > 1200;
    final isMediumScreen = screenSize.width > 800;

    return PdfViewerWidget(
      primaryColor: HospitalTheme.primary,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: HospitalTheme.buildAppBar(
          context: context,
          title: 'Patient Managemen',
          showBackButton: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () =>
                  ref.read(patientListProvider.notifier).refreshPatients(),
              tooltip: 'Refresh (Ctrl+R)',
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Row(
          children: [
            Expanded(
              flex: isLargeScreen
                  ? 3
                  : isMediumScreen
                      ? 4
                      : 5,
              child: const _PatientListColumn(),
            ),
            Expanded(
              flex: isLargeScreen
                  ? 4
                  : isMediumScreen
                      ? 5
                      : 6,
              child: const _PatientDetailsColumn(),
            ),
            Expanded(
              flex: isLargeScreen
                  ? 3
                  : isMediumScreen
                      ? 4
                      : 5,
              child: const _AdmissionDetailsColumn(),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== ADD: PAGINATION WIDGETS ====================

class _PaginationWidget extends ConsumerWidget {
  const _PaginationWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientListState = ref.watch(patientListProvider);
    final pagination = patientListState.pagination;
    final notifier = ref.read(patientListProvider.notifier);

    if (pagination == null || pagination.total <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: HospitalTheme.border)),
      ),
      child: Column(
        children: [
          // Page info
          Text(
            'Page ${pagination.current} of ${pagination.total} • Showing ${pagination.startRecord}-${pagination.endRecord} of ${pagination.totalRecords}',
            style: const TextStyle(
              fontSize: 12,
              color: HospitalTheme.textMedium,
            ),
          ),
          const SizedBox(height: 12),
          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PaginationButton(
                icon: Icons.first_page,
                onPressed: pagination.hasPreviousPage
                    ? () => notifier.goToFirstPage()
                    : null,
                tooltip: 'First Page',
              ),
              const SizedBox(width: 4),
              _PaginationButton(
                icon: Icons.chevron_left,
                onPressed: pagination.hasPreviousPage
                    ? () => notifier.goToPreviousPage()
                    : null,
                tooltip: 'Previous Page',
              ),
              const SizedBox(width: 8),

              // Page numbers
              ..._buildPageNumbers(pagination, notifier),

              const SizedBox(width: 8),
              _PaginationButton(
                icon: Icons.chevron_right,
                onPressed: pagination.hasNextPage
                    ? () => notifier.goToNextPage()
                    : null,
                tooltip: 'Next Page',
              ),
              const SizedBox(width: 4),
              _PaginationButton(
                icon: Icons.last_page,
                onPressed: pagination.hasNextPage
                    ? () => notifier.goToLastPage()
                    : null,
                tooltip: 'Last Page',
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers(
      PaginationInfo pagination, PatientListNotifier notifier) {
    const maxVisiblePages = 5;
    final totalPages = pagination.total;
    final currentPage = pagination.current;

    if (totalPages <= maxVisiblePages) {
      // Show all pages if total is small
      return List.generate(totalPages, (index) {
        final pageNumber = index + 1;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: _PageNumberButton(
            pageNumber: pageNumber,
            isSelected: pageNumber == currentPage,
            onPressed: () => notifier.goToPage(pageNumber),
          ),
        );
      });
    }

    // Calculate which pages to show
    final List<Widget> pageButtons = [];

    int startPage = (currentPage - (maxVisiblePages ~/ 2)).clamp(1, totalPages);
    int endPage = (startPage + maxVisiblePages - 1).clamp(1, totalPages);

    // Adjust startPage if we're near the end
    if (endPage == totalPages) {
      startPage = (totalPages - maxVisiblePages + 1).clamp(1, totalPages);
    }

    // Add first page and ellipsis if needed
    if (startPage > 1) {
      pageButtons.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: _PageNumberButton(
          pageNumber: 1,
          isSelected: false,
          onPressed: () => notifier.goToPage(1),
        ),
      ));
      if (startPage > 2) {
        pageButtons.add(const _EllipsisWidget());
      }
    }

    // Add visible page range
    for (int i = startPage; i <= endPage; i++) {
      pageButtons.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: _PageNumberButton(
          pageNumber: i,
          isSelected: i == currentPage,
          onPressed: () => notifier.goToPage(i),
        ),
      ));
    }

    // Add last page and ellipsis if needed
    if (endPage < totalPages) {
      if (endPage < totalPages - 1) {
        pageButtons.add(const _EllipsisWidget());
      }
      pageButtons.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: _PageNumberButton(
          pageNumber: totalPages,
          isSelected: false,
          onPressed: () => notifier.goToPage(totalPages),
        ),
      ));
    }

    return pageButtons;
  }
}

class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  const _PaginationButton({
    required this.icon,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 12,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: 10,
        color:
            onPressed != null ? HospitalTheme.primary : HospitalTheme.textLight,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _PageNumberButton extends StatelessWidget {
  final int pageNumber;
  final bool isSelected;
  final VoidCallback onPressed;

  const _PageNumberButton({
    required this.pageNumber,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isSelected ? null : onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 18,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? HospitalTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isSelected ? null : Border.all(color: HospitalTheme.border),
        ),
        child: Center(
          child: Text(
            pageNumber.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : HospitalTheme.textDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _EllipsisWidget extends StatelessWidget {
  const _EllipsisWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      child: const Text(
        '...',
        style: TextStyle(
          fontSize: 12,
          color: HospitalTheme.textMedium,
        ),
      ),
    );
  }
}

// ==================== COLUMN 1: PATIENT LIST ====================

class _PatientListColumn extends ConsumerStatefulWidget {
  const _PatientListColumn();

  @override
  ConsumerState<_PatientListColumn> createState() => _PatientListColumnState();
}

class _PatientListColumnState extends ConsumerState<_PatientListColumn> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientListState = ref.watch(patientListProvider);
    final selectedPatient = ref.watch(selectedPatientProvider);

    return Container(
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: HospitalTheme.border)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: HospitalTheme.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patients',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: HospitalTheme.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search patients...',
                    prefixIcon:
                        Icon(Icons.search, color: HospitalTheme.primary),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).state = value;
                    Timer(const Duration(milliseconds: 500), () {
                      if (ref.read(searchQueryProvider) == value) {
                        ref
                            .read(patientListProvider.notifier)
                            .searchPatients(value);
                      }
                    });
                  },
                ),
                if (patientListState.pagination != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${patientListState.pagination!.totalRecords} patients found',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: HospitalTheme.textMedium,
                        ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _buildPatientList(patientListState, selectedPatient),
          ),
          // ADD: Pagination widget at the bottom
          const _PaginationWidget(),
        ],
      ),
    );
  }

  Widget _buildPatientList(PatientListState state, Patient? selectedPatient) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: HospitalTheme.primary),
            SizedBox(height: 16),
            Text('Loading patients...'),
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
                  size: 48, color: HospitalTheme.error),
              const SizedBox(height: 16),
              Text(
                'Error Loading Patients',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: HospitalTheme.error,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
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
    }

    if (state.patients.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 48, color: HospitalTheme.textLight),
            SizedBox(height: 16),
            Text('No patients found'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.patients.length,
      itemBuilder: (context, index) {
        final patient = state.patients[index];
        final isSelected = selectedPatient?.id == patient.id;

        return _PatientListTile(
          patient: patient,
          isSelected: isSelected,
          onTap: () {
            ref.read(selectedPatientProvider.notifier).state = patient;
            if (patient.admissionRecords.isNotEmpty) {
              ref.read(selectedAdmissionProvider.notifier).state =
                  patient.admissionRecords.first;
            } else {
              ref.read(selectedAdmissionProvider.notifier).state = null;
            }
          },
        );
      },
    );
  }
}

// FIX: Changed from StatelessWidget to ConsumerWidget
class _PatientListTile extends ConsumerWidget {
  final Patient patient;
  final bool isSelected;
  final VoidCallback onTap;

  const _PatientListTile({
    required this.patient,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // FIX: Get the latest patient data from the patient list state
    final patientList = ref.watch(patientListProvider);
    final currentPatient =
        patientList.patients.where((p) => p.id == patient.id).firstOrNull ??
            patient;

    final latestAdmission = currentPatient.admissionRecords.isNotEmpty
        ? currentPatient.admissionRecords.first
        : null;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? HospitalTheme.surfaceLight : null,
        border: const Border(
            bottom: BorderSide(color: HospitalTheme.border, width: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: HospitalTheme.primary.withOpacity(0.1),
          backgroundImage: currentPatient.imageUrl != null &&
                  currentPatient.imageUrl!.isNotEmpty
              ? NetworkImage(currentPatient.imageUrl!)
              : null,
          child: currentPatient.imageUrl == null ||
                  currentPatient.imageUrl!.isEmpty
              ? Text(
                  currentPatient.name.isNotEmpty
                      ? currentPatient.name[0].toUpperCase()
                      : 'P',
                  style: const TextStyle(
                    color: HospitalTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          currentPatient
              .name, // FIX: Now uses currentPatient which updates automatically
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: HospitalTheme.textDark,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID: ${currentPatient.patientId}',
              style: const TextStyle(
                fontSize: 12,
                color: HospitalTheme.textMedium,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  '${currentPatient.age}Y, ${currentPatient.gender}', // FIX: Updates automatically
                  style: const TextStyle(
                    fontSize: 12,
                    color: HospitalTheme.textMedium,
                  ),
                ),
                const SizedBox(width: 8),
                if (latestAdmission != null)
                  HospitalTheme.buildStatusBadge(
                    latestAdmission.status.toLowerCase() == 'discharged'
                        ? 'Discharged'
                        : 'Active',
                    color: latestAdmission.status.toLowerCase() == 'discharged'
                        ? HospitalTheme.success
                        : HospitalTheme.info,
                  ),
              ],
            ),
          ],
        ),
        trailing: currentPatient.pendingAmount > 0 // FIX: Updates automatically
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: HospitalTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '₹${currentPatient.pendingAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.warning,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'admitted':
        return HospitalTheme.info;
      case 'discharged':
        return HospitalTheme.success;
      case 'pending':
        return HospitalTheme.warning;
      default:
        return HospitalTheme.textMedium;
    }
  }
}

// ==================== COLUMN 2: PATIENT DETAILS ====================
// (Keep all the rest of your existing code exactly the same)

class _PatientDetailsColumn extends ConsumerWidget {
  const _PatientDetailsColumn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPatient = ref.watch(selectedPatientProvider);

    return Container(
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: HospitalTheme.border)),
      ),
      child: selectedPatient == null
          ? const _EmptyStateWidget(
              icon: Icons.person_outline,
              title: 'No Patient Selected',
              subtitle: 'Select a patient from the list to view details',
            )
          : _PatientDetailsView(patient: selectedPatient),
    );
  }
}

class _PatientDetailsView extends ConsumerStatefulWidget {
  final Patient patient;

  const _PatientDetailsView({required this.patient});

  @override
  ConsumerState<_PatientDetailsView> createState() =>
      _PatientDetailsViewState();
}

class _PatientDetailsViewState extends ConsumerState<_PatientDetailsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _contactController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _imageUrlController;
  String _selectedGender = 'Male';
  DateTime? _selectedDob;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeControllers();
  }

  @override
  void didUpdateWidget(_PatientDetailsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patient.id != widget.patient.id) {
      _initializeControllers();
      _isEditing = false;
    }
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.patient.name);
    _ageController = TextEditingController(text: widget.patient.age.toString());
    _contactController = TextEditingController(text: widget.patient.contact);
    _addressController = TextEditingController(text: widget.patient.address);
    _cityController = TextEditingController(text: widget.patient.city ?? '');
    _stateController = TextEditingController(text: widget.patient.state ?? '');
    _countryController =
        TextEditingController(text: widget.patient.country ?? '');
    _imageUrlController =
        TextEditingController(text: widget.patient.imageUrl ?? '');
    _selectedGender = widget.patient.gender;
    _selectedDob = widget.patient.dob != null
        ? DateTime.tryParse(widget.patient.dob!)
        : null;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Watch for changes in the selected patient to rebuild when updated
    final currentSelectedPatient = ref.watch(selectedPatientProvider);

    // FIX: If the current patient has been updated, use the latest data
    final displayPatient = currentSelectedPatient?.id == widget.patient.id
        ? currentSelectedPatient!
        : widget.patient;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: HospitalTheme.border)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: HospitalTheme.primary.withOpacity(0.1),
                backgroundImage: displayPatient.imageUrl != null &&
                        displayPatient.imageUrl!.isNotEmpty
                    ? NetworkImage(displayPatient.imageUrl!)
                    : null,
                child: displayPatient.imageUrl == null ||
                        displayPatient.imageUrl!.isEmpty
                    ? Text(
                        displayPatient.name.isNotEmpty
                            ? displayPatient.name[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          color: HospitalTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayPatient.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: HospitalTheme.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'ID: ${displayPatient.patientId}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: HospitalTheme.textMedium,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        HospitalTheme.buildStatusBadge(
                          displayPatient.discharged ? 'Discharged' : 'Active',
                          color: displayPatient.discharged
                              ? HospitalTheme.success
                              : HospitalTheme.info,
                        ),
                        if (displayPatient.pendingAmount > 0) ...[
                          const SizedBox(width: 8),
                          HospitalTheme.buildStatusBadge(
                            '₹${displayPatient.pendingAmount.toStringAsFixed(0)} Pending',
                            color: HospitalTheme.warning,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isEditing = !_isEditing;
                    if (_isEditing) {
                      _initializeControllersWithPatient(displayPatient);
                    }
                  });
                },
                icon: Icon(
                  _isEditing ? Icons.close : Icons.edit,
                  color: HospitalTheme.primary,
                ),
                tooltip: _isEditing ? 'Cancel Edit' : 'Edit Patient',
              ),
            ],
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: HospitalTheme.border)),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: HospitalTheme.primary,
            unselectedLabelColor: HospitalTheme.textMedium,
            indicatorColor: HospitalTheme.primary,
            tabs: const [
              Tab(text: 'Basic Info'),
              Tab(text: 'Admissions'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBasicInfoTab(displayPatient),
              _buildAdmissionsTab(displayPatient),
            ],
          ),
        ),
      ],
    );
  }

  void _initializeControllersWithPatient(Patient patient) {
    _nameController.text = patient.name;
    _ageController.text = patient.age.toString();
    _contactController.text = patient.contact;
    _addressController.text = patient.address;
    _cityController.text = patient.city ?? '';
    _stateController.text = patient.state ?? '';
    _countryController.text = patient.country ?? '';
    _imageUrlController.text = patient.imageUrl ?? '';
    _selectedGender = patient.gender;
    _selectedDob = patient.dob != null ? DateTime.tryParse(patient.dob!) : null;
  }

  Widget _buildBasicInfoTab(Patient patient) {
    if (_isEditing) {
      return _buildEditForm();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection('Personal Information', [
            _buildInfoRow('Name', patient.name),
            _buildInfoRow('Age', '${patient.age} years'),
            _buildInfoRow('Gender', patient.gender),
            _buildInfoRow(
                'Date of Birth',
                patient.dob != null
                    ? _safeFormatDate(patient.dob!)
                    : 'Not provided'),
          ]),
          const SizedBox(height: 24),
          _buildInfoSection('Contact Information', [
            _buildInfoRow('Phone', patient.contact),
            _buildInfoRow('Address', patient.address),
            _buildInfoRow('City', patient.city ?? 'Not provided'),
            _buildInfoRow('State', patient.state ?? 'Not provided'),
            _buildInfoRow('Country', patient.country ?? 'Not provided'),
          ]),
          const SizedBox(height: 24),
          _buildInfoSection('Medical Overview', [
            _buildInfoRow(
                'Total Admissions', patient.admissionRecords.length.toString()),
            _buildInfoRow(
                'Current Status', patient.discharged ? 'Discharged' : 'Active'),
            _buildInfoRow('Pending Amount',
                '₹${patient.pendingAmount.toStringAsFixed(2)}'),
          ]),
        ],
      ),
    );
  }

  Widget _buildAdmissionsTab(Patient patient) {
    if (patient.admissionRecords.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_hospital_outlined,
                size: 48, color: HospitalTheme.textLight),
            SizedBox(height: 16),
            Text('No admission records found'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: patient.admissionRecords.length,
      itemBuilder: (context, index) {
        final admission = patient.admissionRecords[index];
        final isSelected =
            ref.watch(selectedAdmissionProvider)?.id == admission.id;

        return _AdmissionRecordCard(
          admission: admission,
          isSelected: isSelected,
          onTap: () {
            ref.read(selectedAdmissionProvider.notifier).state = admission;
          },
        );
      },
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HospitalTheme.primaryDark,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        HospitalTheme.buildCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: HospitalTheme.textMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: HospitalTheme.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _safeFormatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Patient Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: HospitalTheme.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              cursorColor: Colors.black,
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (value) =>
                  value?.isEmpty == true ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(labelText: 'Age'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Age is required';
                      if (int.tryParse(value!) == null) return 'Invalid age';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: ['Male', 'Female', 'Other'].map((gender) {
                      return DropdownMenuItem(
                          value: gender, child: Text(gender));
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedGender = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDob ??
                      DateTime.now().subtract(const Duration(days: 365 * 30)),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedDob = date);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date of Birth'),
                child: Text(
                  _selectedDob != null
                      ? DateFormat('dd MMM yyyy').format(_selectedDob!)
                      : 'Select date of birth',
                  style: TextStyle(
                    color: _selectedDob != null
                        ? HospitalTheme.textDark
                        : HospitalTheme.textLight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  value?.isEmpty == true ? 'Contact is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              maxLines: 2,
              validator: (value) =>
                  value?.isEmpty == true ? 'Address is required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(labelText: 'State'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _countryController,
              decoration: const InputDecoration(labelText: 'Country'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              decoration:
                  const InputDecoration(labelText: 'Image URL (Optional)'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _savePatientInfo,
                    child: const Text('Save Changes'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _initializeControllers();
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // FIX: Updated save method with proper state synchronization
  Future<void> _savePatientInfo() async {
    if (!_formKey.currentState!.validate()) return;

    final updates = {
      'name': _nameController.text.trim(),
      'age': int.parse(_ageController.text.trim()),
      'gender': _selectedGender,
      'contact': _contactController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'country': _countryController.text.trim(),
      'dob': _selectedDob?.toIso8601String(),
      'imageUrl': _imageUrlController.text.trim(),
    };

    try {
      // FIX: Call the API and get updated patient
      final updatedPatient = await ref
          .read(patientListProvider.notifier)
          .updatePatientBasicInfo(widget.patient.patientId, updates);

      // FIX: Update the selectedPatientProvider immediately with fresh data
      ref.read(selectedPatientProvider.notifier).state = updatedPatient;

      // FIX: Update any admission records to maintain consistency
      if (widget.patient.admissionRecords.isNotEmpty) {
        final currentSelectedAdmission = ref.read(selectedAdmissionProvider);
        if (currentSelectedAdmission != null) {
          final updatedAdmission = updatedPatient.admissionRecords
              .where((admission) => admission.id == currentSelectedAdmission.id)
              .firstOrNull;

          if (updatedAdmission != null) {
            ref.read(selectedAdmissionProvider.notifier).state =
                updatedAdmission;
          }
        }
      }

      setState(() => _isEditing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient information updated successfully'),
            backgroundColor: HospitalTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to update patient information';
        if (e is ApiException) {
          errorMessage = e.message;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: HospitalTheme.error,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _savePatientInfo(),
            ),
          ),
        );
      }
    }
  }
}

class _AdmissionRecordCard extends StatelessWidget {
  final AdmissionRecord admission;
  final bool isSelected;
  final VoidCallback onTap;

  const _AdmissionRecordCard({
    required this.admission,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: HospitalTheme.buildCard(
        padding: const EdgeInsets.all(0),
        backgroundColor: isSelected ? HospitalTheme.surfaceLight : null,
        child: InkWell(
          onTap: onTap,
          borderRadius: HospitalTheme.radiusMedium,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    HospitalTheme.buildStatusBadge(
                      admission.status,
                      color: _getStatusColor(admission.status),
                    ),
                    Text(
                      admission.admissionDate != null
                          ? _safeFormatDateTime(admission.admissionDate!)
                          : 'Date not available',
                      style: const TextStyle(
                        color: HospitalTheme.textMedium,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (admission.opdNumber != null || admission.ipdNumber != null)
                  Row(
                    children: [
                      if (admission.opdNumber != null) ...[
                        const Icon(Icons.medical_services_outlined,
                            size: 16, color: HospitalTheme.textMedium),
                        const SizedBox(width: 4),
                        Text(
                          'OPD: ${admission.opdNumber}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                      if (admission.opdNumber != null &&
                          admission.ipdNumber != null)
                        const SizedBox(width: 16),
                      if (admission.ipdNumber != null) ...[
                        const Icon(Icons.hotel_outlined,
                            size: 16, color: HospitalTheme.textMedium),
                        const SizedBox(width: 4),
                        Text(
                          'IPD: ${admission.ipdNumber}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                if (admission.doctor != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 16, color: HospitalTheme.textMedium),
                      const SizedBox(width: 4),
                      Text(
                        admission.doctor!.name,
                        style: const TextStyle(color: HospitalTheme.textMedium),
                      ),
                    ],
                  ),
                ],
                if (admission.bedNumber != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.bed_outlined,
                          size: 16, color: HospitalTheme.textMedium),
                      const SizedBox(width: 4),
                      Text(
                        'Bed: ${admission.bedNumber}',
                        style: const TextStyle(color: HospitalTheme.textMedium),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _safeFormatDateTime(DateTime dateTime) {
    try {
      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'admitted':
        return HospitalTheme.info;
      case 'discharged':
        return HospitalTheme.success;
      case 'pending':
        return HospitalTheme.warning;
      default:
        return HospitalTheme.textMedium;
    }
  }
}

// ==================== COLUMN 3: ADMISSION DETAILS ====================

class _AdmissionDetailsColumn extends ConsumerWidget {
  const _AdmissionDetailsColumn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPatient = ref.watch(selectedPatientProvider);
    final selectedAdmission = ref.watch(selectedAdmissionProvider);

    if (selectedPatient == null) {
      return const _EmptyStateWidget(
        icon: Icons.assignment_outlined,
        title: 'No Patient Selected',
        subtitle: 'Select a patient to view admission details',
      );
    }

    if (selectedAdmission == null) {
      return const _EmptyStateWidget(
        icon: Icons.local_hospital_outlined,
        title: 'No Admission Selected',
        subtitle: 'Select an admission record to view details',
      );
    }

    return _AdmissionDetailsView(
      patient: selectedPatient,
      admission: selectedAdmission,
    );
  }
}

class _AdmissionDetailsView extends ConsumerStatefulWidget {
  final Patient patient;
  final AdmissionRecord admission;

  const _AdmissionDetailsView({
    required this.patient,
    required this.admission,
  });

  @override
  ConsumerState<_AdmissionDetailsView> createState() =>
      _AdmissionDetailsViewState();
}

class _AdmissionDetailsViewState extends ConsumerState<_AdmissionDetailsView> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _opdNumberController;
  late TextEditingController _ipdNumberController;
  late TextEditingController _admitNotesController;
  late TextEditingController _reasonController;
  late TextEditingController _symptomsController;
  late TextEditingController _diagnosisController;
  late TextEditingController _weightController;
  late TextEditingController _amountController;
  late TextEditingController _bedNumberController;
  late TextEditingController _conditionController;

  DateTime? _selectedAdmissionDate;
  DateTime? _selectedDischargeDate;
  String _selectedStatus = 'Pending';
  String _selectedPatientType = 'Internal';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(_AdmissionDetailsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.admission.id != widget.admission.id) {
      _initializeControllers();
      _isEditing = false;
    }
  }

  void _initializeControllers() {
    _opdNumberController = TextEditingController(
        text: widget.admission.opdNumber?.toString() ?? '');
    _ipdNumberController = TextEditingController(
        text: widget.admission.ipdNumber?.toString() ?? '');
    _admitNotesController =
        TextEditingController(text: widget.admission.admitNotes ?? '');
    _reasonController =
        TextEditingController(text: widget.admission.reasonForAdmission ?? '');
    _symptomsController =
        TextEditingController(text: widget.admission.symptoms ?? '');
    _diagnosisController =
        TextEditingController(text: widget.admission.initialDiagnosis ?? '');
    _weightController =
        TextEditingController(text: widget.admission.weight?.toString() ?? '');
    _amountController = TextEditingController(
        text: widget.admission.amountToBePayed?.toString() ?? '');
    _bedNumberController = TextEditingController(
        text: widget.admission.bedNumber?.toString() ?? '');
    _conditionController =
        TextEditingController(text: widget.admission.conditionAtDischarge);

    _selectedAdmissionDate = widget.admission.admissionDate;
    _selectedDischargeDate = widget.admission.dischargeDate;
    _selectedStatus = widget.admission.status;
    _selectedPatientType = widget.admission.patientType;
  }

  @override
  void dispose() {
    _opdNumberController.dispose();
    _ipdNumberController.dispose();
    _admitNotesController.dispose();
    _reasonController.dispose();
    _symptomsController.dispose();
    _diagnosisController.dispose();
    _weightController.dispose();
    _amountController.dispose();
    _bedNumberController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: HospitalTheme.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admission Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: HospitalTheme.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (widget.admission.opdNumber != null) ...[
                          Text(
                            'OPD: ${widget.admission.opdNumber}',
                            style: const TextStyle(
                                color: HospitalTheme.textMedium),
                          ),
                          if (widget.admission.ipdNumber != null)
                            const Text(' • ',
                                style:
                                    TextStyle(color: HospitalTheme.textMedium)),
                        ],
                        if (widget.admission.ipdNumber != null)
                          Text(
                            'IPD: ${widget.admission.ipdNumber}',
                            style: const TextStyle(
                                color: HospitalTheme.textMedium),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isEditing = !_isEditing;
                  });
                },
                icon: Icon(
                  _isEditing ? Icons.close : Icons.edit,
                  color: HospitalTheme.primary,
                ),
                tooltip: _isEditing ? 'Cancel Edit' : 'Edit Admission',
              ),
            ],
          ),
        ),
        Expanded(
          child: _isEditing ? _buildEditForm() : _buildDetailsView(),
        ),
      ],
    );
  }

  Widget _buildDetailsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection('Basic Information', [
            _buildInfoRow('Status', widget.admission.status),
            _buildInfoRow('Patient Type', widget.admission.patientType),
            _buildInfoRow(
                'Admission Date',
                widget.admission.admissionDate != null
                    ? _safeFormatDateTime(widget.admission.admissionDate!)
                    : 'Not provided'),
            if (widget.admission.dischargeDate != null)
              _buildInfoRow('Discharge Date',
                  _safeFormatDateTime(widget.admission.dischargeDate!)),
            if (widget.admission.doctor != null)
              _buildInfoRow('Doctor', widget.admission.doctor!.name),
          ]),
          const SizedBox(height: 24),
          _buildInfoSection('Numbers & Location', [
            if (widget.admission.opdNumber != null)
              _buildInfoRow(
                  'OPD Number', widget.admission.opdNumber.toString()),
            if (widget.admission.ipdNumber != null)
              _buildInfoRow(
                  'IPD Number', widget.admission.ipdNumber.toString()),
            if (widget.admission.bedNumber != null)
              _buildInfoRow(
                  'Bed Number', widget.admission.bedNumber.toString()),
            if (widget.admission.weight != null)
              _buildInfoRow('Weight', '${widget.admission.weight} kg'),
          ]),
          const SizedBox(height: 24),
          _buildInfoSection('Medical Information', [
            _buildInfoRow('Reason for Admission',
                widget.admission.reasonForAdmission ?? 'Not provided'),
            _buildInfoRow(
                'Symptoms', widget.admission.symptoms ?? 'Not provided'),
            _buildInfoRow('Initial Diagnosis',
                widget.admission.initialDiagnosis ?? 'Not provided'),
            _buildInfoRow(
                'Admit Notes', widget.admission.admitNotes ?? 'Not provided'),
            _buildInfoRow('Condition at Discharge',
                widget.admission.conditionAtDischarge),
          ]),
          const SizedBox(height: 24),
          _buildInfoSection('Financial Information', [
            _buildInfoRow(
                'Amount to be Paid',
                widget.admission.amountToBePayed != null
                    ? '₹${widget.admission.amountToBePayed!.toStringAsFixed(2)}'
                    : 'Not specified'),
          ]),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    final nextNumbers = ref.watch(nextAvailableNumbersProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Admission Record',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: HospitalTheme.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPatientType,
                    decoration:
                        const InputDecoration(labelText: 'Patient Type'),
                    items: ['Internal', 'External', 'Emergency'].map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedPatientType = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    cursorColor: Colors.black,
                    controller: _opdNumberController,
                    decoration: InputDecoration(
                      labelStyle: const TextStyle(color: Colors.black),
                      labelText: 'OPD Number',
                      suffixText: nextNumbers.when(
                        data: (data) => 'Next: ${data.nextOPDNumber}',
                        loading: () => 'Loading...',
                        error: (_, __) => '',
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    cursorColor: Colors.black,
                    controller: _ipdNumberController,
                    decoration: InputDecoration(
                      labelText: 'IPD Number',
                      labelStyle: const TextStyle(color: Colors.black),
                      suffixText: nextNumbers.when(
                        data: (data) => 'Next: ${data.nextIPDNumber}',
                        loading: () => 'Loading...',
                        error: (_, __) => '',
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedAdmissionDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                              _selectedAdmissionDate ?? DateTime.now()),
                        );
                        if (time != null) {
                          setState(() {
                            _selectedAdmissionDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                          labelStyle: TextStyle(color: Colors.black),
                          labelText: 'Admission Date'),
                      child: Text(
                        _selectedAdmissionDate != null
                            ? _safeFormatDateTime(_selectedAdmissionDate!)
                            : 'Select admission date',
                        style: TextStyle(
                          color: _selectedAdmissionDate != null
                              ? HospitalTheme.textDark
                              : HospitalTheme.textLight,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    cursorColor: Colors.black,
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelStyle: TextStyle(color: Colors.black),
                      labelText: 'Weight (kg)',
                      suffixText: 'kg',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    cursorColor: Colors.black,
                    controller: _bedNumberController,
                    decoration: const InputDecoration(
                        labelStyle: TextStyle(color: Colors.black),
                        labelText: 'Bed Number'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              cursorColor: Colors.black,
              controller: _reasonController,
              decoration: const InputDecoration(
                  labelStyle: TextStyle(color: Colors.black),
                  labelText: 'Reason for Admission'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              cursorColor: Colors.black,
              controller: _symptomsController,
              decoration: const InputDecoration(
                  labelStyle: TextStyle(color: Colors.black),
                  labelText: 'Symptoms'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              cursorColor: Colors.black,
              controller: _diagnosisController,
              decoration: const InputDecoration(
                  labelStyle: TextStyle(color: Colors.black),
                  labelText: 'Initial Diagnosis'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              cursorColor: Colors.black,
              controller: _admitNotesController,
              decoration: const InputDecoration(
                  labelStyle: TextStyle(color: Colors.black),
                  labelText: 'Admit Notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveAdmissionRecord,
                    child: const Text('Save Changes'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _initializeControllers();
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HospitalTheme.primaryDark,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        HospitalTheme.buildCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: HospitalTheme.textMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: HospitalTheme.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _safeFormatDateTime(DateTime dateTime) {
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime.toLocal());
    } catch (e) {
      return 'Invalid date';
    }
  }

  Future<void> _saveAdmissionRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final updates = <String, dynamic>{
      'opdNumber': int.tryParse(_opdNumberController.text.trim()),
      'ipdNumber': int.tryParse(_ipdNumberController.text.trim()),
      'admissionDate': _selectedAdmissionDate?.toIso8601String(),
      'dischargeDate': _selectedDischargeDate?.toIso8601String(),
      'status': _selectedStatus,
      'patientType': _selectedPatientType,
      'admitNotes': _admitNotesController.text.trim(),
      'reasonForAdmission': _reasonController.text.trim(),
      'conditionAtDischarge': _conditionController.text.trim(),
      'amountToBePayed': double.tryParse(_amountController.text.trim()),
      'weight': double.tryParse(_weightController.text.trim()),
      'symptoms': _symptomsController.text.trim(),
      'initialDiagnosis': _diagnosisController.text.trim(),
      'bedNumber': int.tryParse(_bedNumberController.text.trim()),
    };

    updates.removeWhere(
        (key, value) => value == null || (value is String && value.isEmpty));

    try {
      final updatedAdmission = await ref
          .read(patientListProvider.notifier)
          .updateAdmissionRecord(
              widget.patient.patientId, widget.admission.id, updates);

      ref.read(selectedAdmissionProvider.notifier).state = updatedAdmission;

      final currentPatient = ref.read(selectedPatientProvider);
      if (currentPatient != null) {
        final updatedPatient = currentPatient.copyWith(
          admissionRecords: currentPatient.admissionRecords.map((record) {
            if (record.id == updatedAdmission.id) {
              return updatedAdmission;
            }
            return record;
          }).toList(),
        );
        ref.read(selectedPatientProvider.notifier).state = updatedPatient;
      }

      setState(() => _isEditing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admission record updated successfully'),
            backgroundColor: HospitalTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to update admission record';
        if (e is ApiException) {
          errorMessage = e.message;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: HospitalTheme.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _saveAdmissionRecord(),
            ),
          ),
        );
      }
    }
  }
}

// ==================== HELPER WIDGETS ====================

class _EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyStateWidget({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: HospitalTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: HospitalTheme.textMedium,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: HospitalTheme.textLight,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ==================== METHODS CLASS ====================

class Methods {
  static void openPdf(String url) {
    print('Opening PDF: $url');
  }
}
