import 'dart:convert';

import 'package:doctordesktop/Doctor/SpeechToTextScreen.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// Enhanced Models
class Medicine1 {
  final String name;
  final String morning;
  final String afternoon;
  final String night;
  final String comment;

  const Medicine1({
    required this.name,
    required this.morning,
    required this.afternoon,
    required this.night,
    required this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'morning': int.tryParse(morning) ?? 0,
      'afternoon': int.tryParse(afternoon) ?? 0,
      'night': int.tryParse(night) ?? 0,
      'comment': comment,
    };
  }
}

class Vitals1 {
  final String temperature;
  final String pulse;
  final String bloodPressure;
  final String bloodSugarLevel;
  final String other;

  const Vitals1({
    required this.temperature,
    required this.pulse,
    required this.bloodPressure,
    required this.bloodSugarLevel,
    required this.other,
  });

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'pulse': pulse,
      'bloodPressure': bloodPressure,
      'bloodSugarLevel': bloodSugarLevel,
      'other': other,
    };
  }
}

// Enhanced models for fetched data
class FetchedVitals {
  final String id;
  final String temperature;
  final String pulse;
  final String bloodPressure;
  final String bloodSugarLevel;
  final String other;
  final DateTime recordedAt;

  const FetchedVitals({
    required this.id,
    required this.temperature,
    required this.pulse,
    required this.bloodPressure,
    required this.bloodSugarLevel,
    required this.other,
    required this.recordedAt,
  });

  factory FetchedVitals.fromJson(Map<String, dynamic> json) {
    return FetchedVitals(
      id: json['_id']?.toString() ?? '',
      temperature: json['temperature']?.toString() ?? '0',
      pulse: json['pulse']?.toString() ?? '0',
      bloodPressure: json['bloodPressure']?.toString() ?? '0',
      bloodSugarLevel: json['bloodSugarLevel']?.toString() ?? '0',
      other: json['other']?.toString() ?? '',
      recordedAt: DateTime.tryParse(json['recordedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class FetchedPrescription {
  final String id;
  final String name;
  final String morning;
  final String afternoon;
  final String night;
  final String comment;
  final DateTime date;

  const FetchedPrescription({
    required this.id,
    required this.name,
    required this.morning,
    required this.afternoon,
    required this.night,
    required this.comment,
    required this.date,
  });

  factory FetchedPrescription.fromJson(Map<String, dynamic> json) {
    final medicine = json['medicine'] ?? {};
    return FetchedPrescription(
      id: json['_id']?.toString() ?? '',
      name: medicine['name']?.toString() ?? '',
      morning: medicine['morning']?.toString() ?? '0',
      afternoon: medicine['afternoon']?.toString() ?? '0',
      night: medicine['night']?.toString() ?? '0',
      comment: medicine['comment']?.toString() ?? '',
      date: DateTime.tryParse(json['createdAt']?.toString() ??
              json['updatedAt']?.toString() ??
              medicine['date']?.toString() ??
              '') ??
          DateTime.now(),
    );
  }
}

// Enhanced State Management
class MedicalRecordsState {
  final bool isLoading;
  final bool isFetching;
  final String? error;
  final List<String> medicineSuggestions;
  final bool isLoadingSuggestions;
  final int selectedTabIndex;

  // Fetched data
  final List<FetchedVitals> fetchedVitals;
  final List<FetchedPrescription> fetchedPrescriptions;
  final List<String> fetchedDiagnosis;
  final List<String> fetchedSymptoms;

  const MedicalRecordsState({
    this.isLoading = false,
    this.isFetching = false,
    this.error,
    this.medicineSuggestions = const [],
    this.isLoadingSuggestions = false,
    this.selectedTabIndex = 0,
    this.fetchedVitals = const [],
    this.fetchedPrescriptions = const [],
    this.fetchedDiagnosis = const [],
    this.fetchedSymptoms = const [],
  });

  MedicalRecordsState copyWith({
    bool? isLoading,
    bool? isFetching,
    String? error,
    List<String>? medicineSuggestions,
    bool? isLoadingSuggestions,
    int? selectedTabIndex,
    List<FetchedVitals>? fetchedVitals,
    List<FetchedPrescription>? fetchedPrescriptions,
    List<String>? fetchedDiagnosis,
    List<String>? fetchedSymptoms,
  }) {
    return MedicalRecordsState(
      isLoading: isLoading ?? this.isLoading,
      isFetching: isFetching ?? this.isFetching,
      error: error,
      medicineSuggestions: medicineSuggestions ?? this.medicineSuggestions,
      isLoadingSuggestions: isLoadingSuggestions ?? this.isLoadingSuggestions,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      fetchedVitals: fetchedVitals ?? this.fetchedVitals,
      fetchedPrescriptions: fetchedPrescriptions ?? this.fetchedPrescriptions,
      fetchedDiagnosis: fetchedDiagnosis ?? this.fetchedDiagnosis,
      fetchedSymptoms: fetchedSymptoms ?? this.fetchedSymptoms,
    );
  }
}

class MedicalRecordsNotifier extends StateNotifier<MedicalRecordsState> {
  final Ref ref;

  MedicalRecordsNotifier(this.ref) : super(const MedicalRecordsState());

  // Basic headers without auth
  Map<String, String> get _headers {
    return {'Content-Type': 'application/json'};
  }

  void setSelectedTab(int index) {
    state = state.copyWith(selectedTabIndex: index);
  }

  // Existing methods for adding data
  Future<void> addVitals(
      String patientId, String admissionId, Vitals1 vitals) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint(
          'Adding vitals for patient: $patientId, admission: $admissionId');

      final response = await http.post(
        Uri.parse('${BASE_URL}/doctors/addVitals'),
        headers: _headers,
        body: jsonEncode({
          'patientId': patientId,
          'admissionId': admissionId,
          'vitals': [vitals.toJson()],
        }),
      );

      debugPrint('Add vitals response: ${response.statusCode}');
      debugPrint('Add vitals body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        state = state.copyWith(isLoading: false);
        // Refresh vitals after adding
        await fetchVitals(patientId, admissionId);
      } else {
        final responseBody =
            response.body.isNotEmpty ? response.body : 'No error message';
        throw Exception(
            'Failed to add vitals: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      debugPrint('Error adding vitals: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> addPrescription(
      String patientId, String admissionId, Medicine1 medicine) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint(
          'Adding prescription for patient: $patientId, admission: $admissionId');
      debugPrint('Medicine data: ${medicine.toJson()}');

      final requestBody = {
        'patientId': patientId,
        'admissionId': admissionId,
        'prescription': {
          'medicine': medicine.toJson(),
        },
      };

      debugPrint('Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('${BASE_URL}/doctors/addPresciption'),
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      debugPrint('Add prescription response status: ${response.statusCode}');
      debugPrint('Add prescription response body: ${response.body}');

      // Check for both 200 and 201 status codes as success
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Try to parse the response to ensure it's valid JSON
        try {
          final responseData =
              json.decode(response.body) as Map<String, dynamic>;
          debugPrint('Parsed response data: $responseData');

          state = state.copyWith(isLoading: false);
          // Refresh prescriptions after adding
          await fetchPrescriptions(patientId, admissionId);
        } catch (parseError) {
          debugPrint('Error parsing response JSON: $parseError');
          // Even if parsing fails, if status is 200/201, consider it success
          state = state.copyWith(isLoading: false);
          await fetchPrescriptions(patientId, admissionId);
        }
      } else {
        // Try to get error message from response body
        String errorMessage =
            'Failed to add prescription: ${response.statusCode}';

        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          errorMessage =
              errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (e) {
          // If response body is not JSON, use status code error
          debugPrint('Error parsing error response: $e');
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Error adding prescription: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> addDiagnosis(
      String patientId, String admissionId, List<String> diagnosis) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint(
          'Adding diagnosis for patient: $patientId, admission: $admissionId');

      final response = await http.post(
        Uri.parse('${BASE_URL}/doctors/addDiagnosis'),
        headers: _headers,
        body: jsonEncode({
          'patientId': patientId,
          'admissionId': admissionId,
          'diagnosis': diagnosis,
        }),
      );

      debugPrint('Add diagnosis response: ${response.statusCode}');
      debugPrint('Add diagnosis body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        state = state.copyWith(isLoading: false);
        // Refresh diagnosis after adding
        await fetchDiagnosis(patientId, admissionId);
      } else {
        final responseBody =
            response.body.isNotEmpty ? response.body : 'No error message';
        throw Exception(
            'Failed to add diagnosis: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      debugPrint('Error adding diagnosis: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> addSymptoms(
      String patientId, String admissionId, List<String> symptoms) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint(
          'Adding symptoms for patient: $patientId, admission: $admissionId');

      final response = await http.post(
        Uri.parse('${BASE_URL}/doctors/addSymptoms'),
        headers: _headers,
        body: jsonEncode({
          'patientId': patientId,
          'admissionId': admissionId,
          'symptoms': symptoms,
        }),
      );

      debugPrint('Add symptoms response: ${response.statusCode}');
      debugPrint('Add symptoms body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        state = state.copyWith(isLoading: false);
        // Refresh symptoms after adding
        await fetchSymptoms(patientId, admissionId);
      } else {
        final responseBody =
            response.body.isNotEmpty ? response.body : 'No error message';
        throw Exception(
            'Failed to add symptoms: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      debugPrint('Error adding symptoms: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteVital(
      String patientId, String admissionId, String vitalId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await http.delete(
        Uri.parse(
            '${BASE_URL}/doctors/deleteVitals/$patientId/$admissionId/$vitalId'),
        headers: _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        state = state.copyWith(isLoading: false);
        // Refresh vitals after deleting
        await fetchVitals(patientId, admissionId);
      } else {
        final errorMessage = response.statusCode == 404
            ? 'Vital record not found'
            : 'Failed to delete vital: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // New methods for fetching data
  Future<void> fetchVitals(String patientId, String admissionId) async {
    state = state.copyWith(isFetching: true, error: null);

    try {
      final response = await http.get(
        Uri.parse('${BASE_URL}/doctors/fetchVitals/$patientId/$admissionId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final vitalsData = data['vitals'] as List<dynamic>? ?? [];

        final fetchedVitals =
            vitalsData.map((vital) => FetchedVitals.fromJson(vital)).toList();

        state = state.copyWith(
          fetchedVitals: fetchedVitals,
          isFetching: false,
        );
      } else {
        state = state.copyWith(
          fetchedVitals: [],
          isFetching: false,
        );
      }
    } catch (e) {
      debugPrint('Error fetching vitals: $e');
      state = state.copyWith(
        fetchedVitals: [],
        isFetching: false,
        error: 'Failed to fetch vitals: $e',
      );
    }
  }

  Future<void> deletePrescription(
      String patientId, String admissionId, String prescriptionId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await http.delete(
        Uri.parse(
            '${BASE_URL}/doctors/deletePrescription/$patientId/$admissionId/$prescriptionId'),
        headers: _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        state = state.copyWith(isLoading: false);
        // Refresh prescriptions after deleting
        await fetchPrescriptions(patientId, admissionId);
      } else {
        final errorMessage = response.statusCode == 404
            ? 'Prescription record not found'
            : 'Failed to delete prescription: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> fetchPrescriptions(String patientId, String admissionId) async {
    state = state.copyWith(isFetching: true, error: null);

    try {
      final response = await http.get(
        Uri.parse(
            '${BASE_URL}/doctors/getPrescription/$patientId/$admissionId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final prescriptionsData = data['prescriptions'] as List<dynamic>? ?? [];

        final fetchedPrescriptions = prescriptionsData
            .map((prescription) => FetchedPrescription.fromJson(prescription))
            .toList();

        state = state.copyWith(
          fetchedPrescriptions: fetchedPrescriptions,
          isFetching: false,
        );
      } else {
        state = state.copyWith(
          fetchedPrescriptions: [],
          isFetching: false,
        );
      }
    } catch (e) {
      debugPrint('Error fetching prescriptions: $e');
      state = state.copyWith(
        fetchedPrescriptions: [],
        isFetching: false,
        error: 'Failed to fetch prescriptions: $e',
      );
    }
  }

  Future<void> fetchDiagnosis(String patientId, String admissionId) async {
    state = state.copyWith(isFetching: true, error: null);

    try {
      final response = await http.get(
        Uri.parse('${BASE_URL}/doctors/fetchDiagnosis/$patientId/$admissionId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final diagnosisData = data['diagnosis'] as List<dynamic>? ?? [];

        final fetchedDiagnosis =
            diagnosisData.map((diagnosis) => diagnosis.toString()).toList();

        state = state.copyWith(
          fetchedDiagnosis: fetchedDiagnosis,
          isFetching: false,
        );
      } else {
        state = state.copyWith(
          fetchedDiagnosis: [],
          isFetching: false,
        );
      }
    } catch (e) {
      debugPrint('Error fetching diagnosis: $e');
      state = state.copyWith(
        fetchedDiagnosis: [],
        isFetching: false,
        error: 'Failed to fetch diagnosis: $e',
      );
    }
  }

  Future<void> fetchSymptoms(String patientId, String admissionId) async {
    state = state.copyWith(isFetching: true, error: null);

    try {
      final response = await http.get(
        Uri.parse('${BASE_URL}/doctors/fetchSymptoms/$patientId/$admissionId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final symptomsData = data['symptoms'] as List<dynamic>? ?? [];

        final fetchedSymptoms =
            symptomsData.map((symptom) => symptom.toString()).toList();

        state = state.copyWith(
          fetchedSymptoms: fetchedSymptoms,
          isFetching: false,
        );
      } else {
        state = state.copyWith(
          fetchedSymptoms: [],
          isFetching: false,
        );
      }
    } catch (e) {
      debugPrint('Error fetching symptoms: $e');
      state = state.copyWith(
        fetchedSymptoms: [],
        isFetching: false,
        error: 'Failed to fetch symptoms: $e',
      );
    }
  }

  // Fetch all data for a patient
  Future<void> fetchAllMedicalRecords(
      String patientId, String admissionId) async {
    await Future.wait([
      fetchVitals(patientId, admissionId),
      fetchPrescriptions(patientId, admissionId),
      fetchDiagnosis(patientId, admissionId),
      fetchSymptoms(patientId, admissionId),
    ]);
  }

  Future<void> fetchMedicineSuggestions(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(
        medicineSuggestions: [],
        isLoadingSuggestions: false,
      );
      return;
    }

    state = state.copyWith(isLoadingSuggestions: true);

    try {
      final response = await http.get(
        Uri.parse('${BASE_URL}/search?q=$query'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final suggestions = List<String>.from(data['suggestions'] ?? []);

        if (suggestions.isEmpty && query.isNotEmpty) {
          suggestions.add(query);
        }

        state = state.copyWith(
          medicineSuggestions: suggestions,
          isLoadingSuggestions: false,
        );
      } else {
        state = state.copyWith(
          medicineSuggestions: query.isNotEmpty ? [query] : [],
          isLoadingSuggestions: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        medicineSuggestions: query.isNotEmpty ? [query] : [],
        isLoadingSuggestions: false,
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final medicalRecordsProvider =
    StateNotifierProvider<MedicalRecordsNotifier, MedicalRecordsState>((ref) {
  return MedicalRecordsNotifier(ref);
});

class MedicalRecordsScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String admissionId;

  const MedicalRecordsScreen({
    super.key,
    required this.patientId,
    required this.admissionId,
  });

  @override
  ConsumerState<MedicalRecordsScreen> createState() =>
      _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends ConsumerState<MedicalRecordsScreen> {
  final List<_TabData> _tabs = [
    _TabData(
      icon: Icons.favorite_border,
      label: 'Vitals',
      color: HospitalTheme.medical,
    ),
    _TabData(
      icon: Icons.medication,
      label: 'Prescription',
      color: HospitalTheme.pharmacy,
    ),
    _TabData(
      icon: Icons.medical_services,
      label: 'Diagnosis',
      color: HospitalTheme.laboratory,
    ),
    _TabData(
      icon: Icons.sick,
      label: 'Symptoms',
      color: HospitalTheme.warning,
    ),
    _TabData(
      icon: Icons.chat,
      label: 'Consulting',
      color: HospitalTheme.info,
    ),
    _TabData(
      icon: Icons.psychology,
      label: 'Voice AI',
      color: HospitalTheme.accent,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Fetch all medical records when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(medicalRecordsProvider.notifier)
          .fetchAllMedicalRecords(widget.patientId, widget.admissionId);
    });
  }

  void _handleKeyboardShortcuts(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrlOrCmd = HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;

      // Tab navigation shortcuts (Ctrl/Cmd + 1-6)
      if (isCtrlOrCmd) {
        if (event.logicalKey == LogicalKeyboardKey.digit1) {
          ref.read(medicalRecordsProvider.notifier).setSelectedTab(0);
        } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
          ref.read(medicalRecordsProvider.notifier).setSelectedTab(1);
        } else if (event.logicalKey == LogicalKeyboardKey.digit3) {
          ref.read(medicalRecordsProvider.notifier).setSelectedTab(2);
        } else if (event.logicalKey == LogicalKeyboardKey.digit4) {
          ref.read(medicalRecordsProvider.notifier).setSelectedTab(3);
        } else if (event.logicalKey == LogicalKeyboardKey.digit5) {
          ref.read(medicalRecordsProvider.notifier).setSelectedTab(4);
        } else if (event.logicalKey == LogicalKeyboardKey.digit6) {
          ref.read(medicalRecordsProvider.notifier).setSelectedTab(5);
        } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
          // Refresh shortcut (Ctrl/Cmd + R)
          _refreshData();
        }
      }

      // Arrow key navigation
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        final currentIndex = ref.read(medicalRecordsProvider).selectedTabIndex;
        if (currentIndex > 0) {
          ref
              .read(medicalRecordsProvider.notifier)
              .setSelectedTab(currentIndex - 1);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        final currentIndex = ref.read(medicalRecordsProvider).selectedTabIndex;
        if (currentIndex < _tabs.length - 1) {
          ref
              .read(medicalRecordsProvider.notifier)
              .setSelectedTab(currentIndex + 1);
        }
      }
    }
  }

  void _refreshData() {
    ref
        .read(medicalRecordsProvider.notifier)
        .fetchAllMedicalRecords(widget.patientId, widget.admissionId);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 1200;
    final isTablet = screenSize.width > 800;
    final sidebarWidth = isDesktop ? 280.0 : (isTablet ? 240.0 : 200.0);

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyboardShortcuts,
      child: Scaffold(
        backgroundColor: HospitalTheme.background,
        floatingActionButton: _buildFloatingActionButton(),
        appBar: _buildAppBar(context),
        body: Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(medicalRecordsProvider);

            if (isDesktop) {
              return _buildDesktopLayout(state, sidebarWidth);
            } else {
              return _buildTabletMobileLayout(state, isTablet);
            }
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return HospitalTheme.buildAppBar(
      context: context,
      title: 'Medical Records Management',
      actions: [
        _RefreshButton(onRefresh: _refreshData),
        const SizedBox(width: 8),
        _QuickActionsButton(
          patientId: widget.patientId,
          admissionId: widget.admissionId,
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(medicalRecordsProvider);
        return FloatingActionButton.extended(
          onPressed: () {
            // Navigate to add new record based on current tab
            // Implementation depends on your specific screens
          },
          backgroundColor: HospitalTheme.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: Text(_getAddButtonLabel(state.selectedTabIndex)),
        );
      },
    );
  }

  String _getAddButtonLabel(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'Add Vitals';
      case 1:
        return 'Add Prescription';
      case 2:
        return 'Add Diagnosis';
      case 3:
        return 'Add Symptoms';
      case 4:
        return 'Start Consulting';
      case 5:
        return 'Voice Recording';
      default:
        return 'Add Record';
    }
  }

  Widget _buildDesktopLayout(MedicalRecordsState state, double sidebarWidth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar Navigation
        Container(
          width: sidebarWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: HospitalTheme.shadowSmall,
            border: Border(
              right: BorderSide(color: HospitalTheme.border, width: 1),
            ),
          ),
          child: _buildSidebar(state),
        ),

        // Main Content Area
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContentHeader(state),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildTabContent(state.selectedTabIndex),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletMobileLayout(MedicalRecordsState state, bool isTablet) {
    return Column(
      children: [
        // Tab Bar
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: HospitalTheme.border, width: 1),
            ),
          ),
          child: _buildHorizontalTabs(state, isTablet),
        ),

        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
            child: _buildTabContent(state.selectedTabIndex),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar(MedicalRecordsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: HospitalTheme.primaryLight.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(color: HospitalTheme.border, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.medical_information,
                      color: HospitalTheme.primary, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Medical Records',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Patient ID: ${widget.patientId}',
                style: const TextStyle(
                  fontSize: 12,
                  color: HospitalTheme.textMedium,
                ),
              ),
            ],
          ),
        ),

        // Navigation Items
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _tabs.length,
            itemBuilder: (context, index) {
              final tab = _tabs[index];
              final isSelected = state.selectedTabIndex == index;

              return _buildSidebarItem(
                tab: tab,
                index: index,
                isSelected: isSelected,
                onTap: () {
                  ref
                      .read(medicalRecordsProvider.notifier)
                      .setSelectedTab(index);
                },
              );
            },
          ),
        ),

        // Footer with keyboard shortcuts
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HospitalTheme.surfaceLight.withOpacity(0.3),
            border: Border(
              top: BorderSide(color: HospitalTheme.border, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Keyboard Shortcuts',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textMedium,
                ),
              ),
              const SizedBox(height: 8),
              _buildShortcutItem('Ctrl/Cmd + 1-6', 'Switch tabs'),
              _buildShortcutItem('Ctrl/Cmd + R', 'Refresh'),
              _buildShortcutItem('← →', 'Navigate tabs'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutItem(String shortcut, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: HospitalTheme.border,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              shortcut,
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: HospitalTheme.textMedium,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 11,
                color: HospitalTheme.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required _TabData tab,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? tab.color.withOpacity(0.1) : Colors.transparent,
        borderRadius: HospitalTheme.radiusSmall,
        border: isSelected ? Border.all(color: tab.color, width: 1) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: HospitalTheme.radiusSmall,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? tab.color : tab.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    tab.icon,
                    size: 20,
                    color: isSelected ? Colors.white : tab.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? tab.color : HospitalTheme.textDark,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tab.color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalTabs(MedicalRecordsState state, bool isTablet) {
    return Container(
      height: isTablet ? 60 : 55,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          final isSelected = state.selectedTabIndex == index;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  ref
                      .read(medicalRecordsProvider.notifier)
                      .setSelectedTab(index);
                },
                borderRadius: HospitalTheme.radiusSmall,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 16 : 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? tab.color.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: HospitalTheme.radiusSmall,
                    border: isSelected
                        ? Border.all(color: tab.color, width: 1)
                        : Border.all(color: HospitalTheme.border, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.icon,
                        size: isTablet ? 20 : 18,
                        color:
                            isSelected ? tab.color : HospitalTheme.textMedium,
                      ),
                      SizedBox(width: isTablet ? 8 : 6),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color:
                              isSelected ? tab.color : HospitalTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentHeader(MedicalRecordsState state) {
    final currentTab = _tabs[state.selectedTabIndex];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: HospitalTheme.radiusMedium,
        boxShadow: HospitalTheme.shadowSmall,
        border: Border.all(color: HospitalTheme.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: currentTab.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              currentTab.icon,
              color: currentTab.color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentTab.label,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getTabDescription(state.selectedTabIndex),
                  style: const TextStyle(
                    fontSize: 14,
                    color: HospitalTheme.textMedium,
                  ),
                ),
              ],
            ),
          ),
          if (state.isFetching)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(HospitalTheme.primary),
              ),
            ),
        ],
      ),
    );
  }

  String _getTabDescription(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'Monitor and record patient vital signs';
      case 1:
        return 'Manage medications and prescriptions';
      case 2:
        return 'Document medical diagnosis and conditions';
      case 3:
        return 'Track patient symptoms and complaints';
      case 4:
        return 'Doctor-patient consultation records';
      case 5:
        return 'AI-powered voice medical transcription';
      default:
        return '';
    }
  }

  Widget _buildTabContent(int selectedIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: HospitalTheme.radiusMedium,
        boxShadow: HospitalTheme.shadowSmall,
        border: Border.all(color: HospitalTheme.border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: HospitalTheme.radiusMedium,
        child: _getTabContent(selectedIndex),
      ),
    );
  }

  Widget _getTabContent(int index) {
    switch (index) {
      case 0:
        return _buildPlaceholderContent('Vitals', Icons.favorite_border);
      case 1:
        return _buildPlaceholderContent('Prescription', Icons.medication);
      case 2:
        return _buildPlaceholderContent('Diagnosis', Icons.medical_services);
      case 3:
        return _buildPlaceholderContent('Symptoms', Icons.sick);
      case 4:
        return _buildPlaceholderContent('Consulting', Icons.chat);
      case 5:
      // return GoogleSpeechToTextMedicalScreen(
      //   patientId: widget.patientId,
      //   admissionId: widget.admissionId,
      // );
      default:
        return const Center(child: Text('Content not available'));
    }
  }

  Widget _buildPlaceholderContent(String title, IconData icon) {
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
            '$title Screen',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This screen will be implemented with specific $title functionality',
            style: const TextStyle(
              fontSize: 14,
              color: HospitalTheme.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Supporting classes and widgets
class _TabData {
  final IconData icon;
  final String label;
  final Color color;

  const _TabData({
    required this.icon,
    required this.label,
    required this.color,
  });
}

class _RefreshButton extends StatelessWidget {
  final VoidCallback onRefresh;

  const _RefreshButton({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.refresh, color: Colors.white),
      onPressed: onRefresh,
      tooltip: 'Refresh data (Ctrl/Cmd + R)',
    );
  }
}

class _QuickActionsButton extends StatelessWidget {
  final String patientId;
  final String admissionId;

  const _QuickActionsButton({
    required this.patientId,
    required this.admissionId,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      tooltip: 'Quick actions',
      onSelected: (value) {
        switch (value) {
          case 'export':
            _exportData();
            break;
          case 'print':
            _printRecords();
            break;
          case 'share':
            _shareRecords();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.file_download, size: 18),
              SizedBox(width: 8),
              Text('Export Records'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'print',
          child: Row(
            children: [
              Icon(Icons.print, size: 18),
              SizedBox(width: 8),
              Text('Print Records'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, size: 18),
              SizedBox(width: 8),
              Text('Share Records'),
            ],
          ),
        ),
      ],
    );
  }

  void _exportData() {
    // Implementation for export functionality
  }

  void _printRecords() {
    // Implementation for print functionality
  }

  void _shareRecords() {
    // Implementation for share functionality
  }
}
