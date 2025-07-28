// File: lib/screens/patient_counter_screen.dart

import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// ==================== MODELS ====================

class PatientCounter {
  final String id;
  final String name;
  final int currentValue;
  final DateTime lastReset;
  final String resetPeriod;
  final int nextValue;
  final DateTime? changedAt;
  final int? previousValue;

  const PatientCounter({
    required this.id,
    required this.name,
    required this.currentValue,
    required this.lastReset,
    required this.resetPeriod,
    required this.nextValue,
    this.changedAt,
    this.previousValue,
  });

  factory PatientCounter.fromJson(Map<String, dynamic> json) {
    return PatientCounter(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      currentValue: (json['currentValue'] as num?)?.toInt() ?? 0,
      lastReset: DateTime.tryParse(json['lastReset'] as String? ?? '') ??
          DateTime.now(),
      resetPeriod: json['resetPeriod'] as String? ?? 'yearly',
      nextValue: (json['nextValue'] as num?)?.toInt() ?? 0,
      changedAt: json['changedAt'] != null
          ? DateTime.tryParse(json['changedAt'] as String)
          : null,
      previousValue: (json['previousValue'] as num?)?.toInt(),
    );
  }

  PatientCounter copyWith({
    String? id,
    String? name,
    int? currentValue,
    DateTime? lastReset,
    String? resetPeriod,
    int? nextValue,
    DateTime? changedAt,
    int? previousValue,
  }) {
    return PatientCounter(
      id: id ?? this.id,
      name: name ?? this.name,
      currentValue: currentValue ?? this.currentValue,
      lastReset: lastReset ?? this.lastReset,
      resetPeriod: resetPeriod ?? this.resetPeriod,
      nextValue: nextValue ?? this.nextValue,
      changedAt: changedAt ?? this.changedAt,
      previousValue: previousValue ?? this.previousValue,
    );
  }
}

class CounterSummary {
  final int opdCurrentValue;
  final int ipdCurrentValue;
  final int opdNextValue;
  final int ipdNextValue;
  final int totalCounters;

  const CounterSummary({
    required this.opdCurrentValue,
    required this.ipdCurrentValue,
    required this.opdNextValue,
    required this.ipdNextValue,
    required this.totalCounters,
  });

  factory CounterSummary.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    return CounterSummary(
      opdCurrentValue: (summary['opdCurrentValue'] as num?)?.toInt() ?? 0,
      ipdCurrentValue: (summary['ipdCurrentValue'] as num?)?.toInt() ?? 0,
      opdNextValue: (summary['opdNextValue'] as num?)?.toInt() ?? 0,
      ipdNextValue: (summary['ipdNextValue'] as num?)?.toInt() ?? 0,
      totalCounters: (json['totalCounters'] as num?)?.toInt() ?? 0,
    );
  }
}

class PatientRecord {
  final String patientId;
  final int? opdNumber;
  final int? ipdNumber;
  final String name;
  final int age;
  final String gender;
  final String contact;
  final DateTime admissionDate;
  final DateTime? dischargeDate;
  final String? stayDuration;
  final String conditionAtDischarge;
  final double amountToBePayed;

  const PatientRecord({
    required this.patientId,
    this.opdNumber,
    this.ipdNumber,
    required this.name,
    required this.age,
    required this.gender,
    required this.contact,
    required this.admissionDate,
    this.dischargeDate,
    this.stayDuration,
    required this.conditionAtDischarge,
    required this.amountToBePayed,
  });

  factory PatientRecord.fromJson(Map<String, dynamic> json) {
    return PatientRecord(
      patientId: json['patientId'] as String? ?? '',
      opdNumber: (json['opdNumber'] as num?)?.toInt(),
      ipdNumber: (json['ipdNumber'] as num?)?.toInt(),
      name: json['name'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      gender: json['gender'] as String? ?? '',
      contact: json['contact'] as String? ?? '',
      admissionDate:
          DateTime.tryParse(json['admissionDate'] as String? ?? '') ??
              DateTime.now(),
      dischargeDate: json['dischargeDate'] != null
          ? DateTime.tryParse(json['dischargeDate'] as String)
          : null,
      stayDuration: json['stayDuration'] as String?,
      conditionAtDischarge: json['conditionAtDischarge'] as String? ?? '',
      amountToBePayed: (json['amountToBePayed'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CounterState {
  final List<PatientCounter> counters;
  final CounterSummary? summary;
  final bool isLoading;
  final String? error;
  final PatientCounter? selectedCounter;
  final bool isUpdating;
  final bool isAddingPatient;
  final PatientRecord? recentlyAddedPatient;
  final String? successMessage;

  const CounterState({
    this.counters = const [],
    this.summary,
    this.isLoading = false,
    this.error,
    this.selectedCounter,
    this.isUpdating = false,
    this.isAddingPatient = false,
    this.recentlyAddedPatient,
    this.successMessage,
  });

  CounterState copyWith({
    List<PatientCounter>? counters,
    CounterSummary? summary,
    bool? isLoading,
    String? error,
    PatientCounter? selectedCounter,
    bool? isUpdating,
    bool? isAddingPatient,
    PatientRecord? recentlyAddedPatient,
    String? successMessage,
  }) {
    return CounterState(
      counters: counters ?? this.counters,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCounter: selectedCounter ?? this.selectedCounter,
      isUpdating: isUpdating ?? this.isUpdating,
      isAddingPatient: isAddingPatient ?? this.isAddingPatient,
      recentlyAddedPatient: recentlyAddedPatient ?? this.recentlyAddedPatient,
      successMessage: successMessage,
    );
  }
}

// ==================== API SERVICE ====================

class CounterApiService {
  static const String baseUrl = BASE_URL;

  static Future<Map<String, dynamic>> _makeRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      late http.Response response;

      switch (method.toLowerCase()) {
        case 'get':
          response = await http.get(
            uri,
            headers: {'Content-Type': 'application/json'},
          ).timeout(const Duration(seconds: 30));
          break;
        case 'put':
          response = await http
              .put(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: body != null ? json.encode(body) : null,
              )
              .timeout(const Duration(seconds: 30));
          break;
        case 'post':
          response = await http
              .post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: body != null ? json.encode(body) : null,
              )
              .timeout(const Duration(seconds: 30));
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Request timeout. Please check your connection.');
    } on FormatException {
      throw Exception('Invalid response format from server.');
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> getAllCounters() async {
    return await _makeRequest('/api/patient-counters');
  }

  static Future<Map<String, dynamic>> updateCounter(
    String counterId,
    int newValue,
    String resetPeriod,
  ) async {
    return await _makeRequest(
      '/api/patient-counters/$counterId',
      method: 'PUT',
      body: {
        'newValue': newValue,
        'resetPeriod': resetPeriod,
      },
    );
  }

  static Future<Map<String, dynamic>> addPatientRecord({
    required String name,
    required int age,
    required String gender,
    required String contact,
    required String admissionDate,
    String? dischargeDate,
    int? opdNumber,
    int? ipdNumber,
    bool autoGenerate = false,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'age': age,
      'gender': gender,
      'contact': contact,
      'admissionDate': admissionDate,
      'autoGenerate': autoGenerate,
    };

    if (dischargeDate != null) body['dischargeDate'] = dischargeDate;
    if (opdNumber != null) body['opdNumber'] = opdNumber;
    if (ipdNumber != null) body['ipdNumber'] = ipdNumber;

    return await _makeRequest('/addPatientRecord', method: 'POST', body: body);
  }
}

// ==================== RIVERPOD PROVIDERS ====================

class CounterNotifier extends StateNotifier<CounterState> {
  CounterNotifier() : super(const CounterState());

  Future<void> loadCounters() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await CounterApiService.getAllCounters();

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        final countersJson = data['counters'] as List<dynamic>? ?? [];

        final counters = countersJson
            .map(
                (json) => PatientCounter.fromJson(json as Map<String, dynamic>))
            .toList();

        final summary = CounterSummary.fromJson(data);

        state = state.copyWith(
          counters: counters,
          summary: summary,
          isLoading: false,
          selectedCounter: counters.isNotEmpty ? counters.first : null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] as String? ?? 'Failed to load counters',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateCounter(
      String counterId, int newValue, String resetPeriod) async {
    if (state.isUpdating) return;

    state = state.copyWith(isUpdating: true, error: null);

    try {
      final response = await CounterApiService.updateCounter(
          counterId, newValue, resetPeriod);

      if (response['success'] == true) {
        final updatedCounterData =
            response['data']['counter'] as Map<String, dynamic>;
        final updatedCounter = PatientCounter.fromJson(updatedCounterData);

        final updatedCounters = state.counters.map((counter) {
          return counter.id == counterId ? updatedCounter : counter;
        }).toList();

        state = state.copyWith(
          counters: updatedCounters,
          selectedCounter: state.selectedCounter?.id == counterId
              ? updatedCounter
              : state.selectedCounter,
          isUpdating: false,
          successMessage: 'Counter updated successfully',
        );

        // Refresh the full data to get updated summary
        await loadCounters();
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: response['message'] as String? ?? 'Failed to update counter',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addPatientRecord({
    required String name,
    required int age,
    required String gender,
    required String contact,
    required String admissionDate,
    String? dischargeDate,
    int? opdNumber,
    int? ipdNumber,
    bool autoGenerate = false,
  }) async {
    if (state.isAddingPatient) return;

    state = state.copyWith(isAddingPatient: true, error: null);

    try {
      final response = await CounterApiService.addPatientRecord(
        name: name,
        age: age,
        gender: gender,
        contact: contact,
        admissionDate: admissionDate,
        dischargeDate: dischargeDate,
        opdNumber: opdNumber,
        ipdNumber: ipdNumber,
        autoGenerate: autoGenerate,
      );

      if (response['success'] == true) {
        final patientData = response['data'] as Map<String, dynamic>;
        final patientRecord = PatientRecord.fromJson(patientData);

        state = state.copyWith(
          isAddingPatient: false,
          recentlyAddedPatient: patientRecord,
          successMessage: response['message'] as String? ??
              'Patient record added successfully',
        );

        // Refresh counters to get updated values
        await loadCounters();
      } else {
        state = state.copyWith(
          isAddingPatient: false,
          error:
              response['message'] as String? ?? 'Failed to add patient record',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isAddingPatient: false,
        error: e.toString(),
      );
    }
  }

  void selectCounter(PatientCounter counter) {
    state = state.copyWith(selectedCounter: counter);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }

  void clearRecentPatient() {
    state = state.copyWith(recentlyAddedPatient: null);
  }
}

final counterProvider =
    StateNotifierProvider<CounterNotifier, CounterState>((ref) {
  return CounterNotifier();
});

// ==================== MAIN SCREEN ====================

class PatientCounterScreen extends ConsumerStatefulWidget {
  const PatientCounterScreen({super.key});

  @override
  ConsumerState<PatientCounterScreen> createState() =>
      _PatientCounterScreenState();
}

class _PatientCounterScreenState extends ConsumerState<PatientCounterScreen> {
  bool _showAddPatientForm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(counterProvider.notifier).loadCounters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(counterProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      appBar: _buildAppBar(),
      body: KeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Column(
          children: [
            // Action Bar
            _buildActionBar(),

            // Success/Error Messages
            if (state.successMessage != null)
              _buildSuccessMessage(state.successMessage!),
            if (state.error != null) _buildErrorMessage(state.error!),

            // Main Content
            Expanded(
              child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
            ),
          ],
        ),
      ),
      floatingActionButton: HospitalTheme.buildFloatingActionButton(
        icon: _showAddPatientForm ? Icons.close : Icons.person_add,
        onPressed: () {
          setState(() {
            _showAddPatientForm = !_showAddPatientForm;
          });
        },
        tooltip:
            _showAddPatientForm ? 'Close Form (Esc)' : 'Add Patient (Ctrl+N)',
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return HospitalTheme.buildAppBar(
      context: context,
      title: 'Patient Counter Management',
      showBackButton: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.read(counterProvider.notifier).loadCounters(),
          tooltip: 'Refresh Data (F5)',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: HospitalTheme.surfaceLight,
        border: Border(
          bottom: BorderSide(color: HospitalTheme.border),
        ),
      ),
      child: Row(
        children: [
          HospitalTheme.buildGradientButton(
            label: 'Add Patient',
            icon: Icons.person_add,
            onPressed: () {
              setState(() {
                _showAddPatientForm = !_showAddPatientForm;
              });
            },
            isLoading: false,
          ),
          const SizedBox(width: 16),
          HospitalTheme.buildGradientButton(
            label: 'Refresh Data',
            icon: Icons.refresh,
            onPressed: () => ref.read(counterProvider.notifier).loadCounters(),
            startColor: HospitalTheme.secondary,
            endColor: HospitalTheme.secondaryLight,
            isLoading: false,
          ),
          const Spacer(),
          Text(
            'Use Ctrl+N to add patient, F5 to refresh',
            style: TextStyle(
              fontSize: 12,
              color: HospitalTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage(String message) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HospitalTheme.success.withOpacity(0.1),
        borderRadius: HospitalTheme.radiusSmall,
        border: Border.all(color: HospitalTheme.success),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: HospitalTheme.success, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: HospitalTheme.success, fontSize: 14),
            ),
          ),
          IconButton(
            onPressed: () =>
                ref.read(counterProvider.notifier).clearSuccessMessage(),
            icon: Icon(Icons.close, size: 16, color: HospitalTheme.success),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HospitalTheme.error.withOpacity(0.1),
        borderRadius: HospitalTheme.radiusSmall,
        border: Border.all(color: HospitalTheme.error),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: HospitalTheme.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: HospitalTheme.error, fontSize: 14),
            ),
          ),
          IconButton(
            onPressed: () => ref.read(counterProvider.notifier).clearError(),
            icon: Icon(Icons.close, size: 16, color: HospitalTheme.error),
          ),
        ],
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrlOrCmd = HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;

      if (event.logicalKey == LogicalKeyboardKey.f5 ||
          (event.logicalKey == LogicalKeyboardKey.keyR && isCtrlOrCmd)) {
        ref.read(counterProvider.notifier).loadCounters();
      } else if (event.logicalKey == LogicalKeyboardKey.keyN && isCtrlOrCmd) {
        setState(() {
          _showAddPatientForm = !_showAddPatientForm;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        setState(() {
          _showAddPatientForm = false;
        });
      }
    }
  }

  Widget _buildMobileLayout() {
    final state = ref.watch(counterProvider);

    return Column(
      children: [
        if (state.summary != null) _buildSummaryCards(),
        if (_showAddPatientForm) ...[
          const Divider(height: 1),
          Expanded(child: _AddPatientForm()),
        ] else ...[
          const Divider(height: 1),
          Expanded(child: _buildCountersList()),
        ],
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Master Panel
        SizedBox(
          width: 400,
          child: _buildMasterPanel(),
        ),
        const VerticalDivider(width: 1),
        // Detail Panel
        Expanded(
          child: _showAddPatientForm ? _AddPatientForm() : _buildDetailPanel(),
        ),
      ],
    );
  }

  Widget _buildMasterPanel() {
    final state = ref.watch(counterProvider);

    return Column(
      children: [
        if (state.summary != null) _buildSummaryCards(),
        const Divider(height: 1),
        Expanded(child: _buildCountersList()),
      ],
    );
  }

  Widget _buildDetailPanel() {
    final state = ref.watch(counterProvider);

    if (state.selectedCounter == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.numbers,
              size: 64,
              color: HospitalTheme.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a counter to view details',
              style: TextStyle(
                fontSize: 16,
                color: HospitalTheme.textMedium,
              ),
            ),
            const SizedBox(height: 24),
            HospitalTheme.buildGradientButton(
              label: 'Add Patient',
              icon: Icons.person_add,
              onPressed: () {
                setState(() {
                  _showAddPatientForm = true;
                });
              },
              isLoading: false,
            ),
          ],
        ),
      );
    }

    return _CounterDetailPanel(counter: state.selectedCounter!);
  }

  Widget _buildSummaryCards() {
    final state = ref.watch(counterProvider);
    final summary = state.summary!;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: HospitalTheme.buildStatCard(
              title: 'OPD Counter',
              value: summary.opdCurrentValue.toString(),
              subtitle: 'Next: ${summary.opdNextValue}',
              icon: Icons.local_hospital,
              iconColor: HospitalTheme.secondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: HospitalTheme.buildStatCard(
              title: 'IPD Counter',
              value: summary.ipdCurrentValue.toString(),
              subtitle: 'Next: ${summary.ipdNextValue}',
              icon: Icons.hotel,
              iconColor: HospitalTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountersList() {
    final state = ref.watch(counterProvider);

    if (state.isLoading && state.counters.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading counters...'),
          ],
        ),
      );
    }

    if (state.counters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.numbers,
              size: 64,
              color: HospitalTheme.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No counters found',
              style: TextStyle(
                fontSize: 16,
                color: HospitalTheme.textMedium,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () =>
                  ref.read(counterProvider.notifier).loadCounters(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.counters.length,
      itemBuilder: (context, index) {
        final counter = state.counters[index];
        final isSelected = state.selectedCounter?.id == counter.id;

        return _CounterListItem(
          counter: counter,
          isSelected: isSelected,
          onTap: () =>
              ref.read(counterProvider.notifier).selectCounter(counter),
        );
      },
    );
  }
}

// ==================== COUNTER LIST ITEM ====================

class _CounterListItem extends StatelessWidget {
  final PatientCounter counter;
  final bool isSelected;
  final VoidCallback onTap;

  const _CounterListItem({
    required this.counter,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: HospitalTheme.buildListTile(
        title: counter.name,
        subtitle:
            'Current: ${counter.currentValue} • Next: ${counter.nextValue}',
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getCounterColor(counter.id).withOpacity(0.1),
            borderRadius: HospitalTheme.radiusSmall,
          ),
          child: Icon(
            _getCounterIcon(counter.id),
            color: _getCounterColor(counter.id),
            size: 24,
          ),
        ),
        trailing: HospitalTheme.buildStatusBadge(
          counter.resetPeriod.toUpperCase(),
          color: _getResetPeriodColor(counter.resetPeriod),
        ),
        onTap: onTap,
        isSelected: isSelected,
      ),
    );
  }

  Color _getCounterColor(String id) {
    switch (id.toLowerCase()) {
      case 'opdnumber':
        return HospitalTheme.secondary;
      case 'ipdnumber':
        return HospitalTheme.primary;
      default:
        return HospitalTheme.medical;
    }
  }

  IconData _getCounterIcon(String id) {
    switch (id.toLowerCase()) {
      case 'opdnumber':
        return Icons.local_hospital;
      case 'ipdnumber':
        return Icons.hotel;
      default:
        return Icons.numbers;
    }
  }

  Color _getResetPeriodColor(String period) {
    switch (period.toLowerCase()) {
      case 'yearly':
        return HospitalTheme.medical;
      case 'monthly':
        return HospitalTheme.secondary;
      case 'daily':
        return HospitalTheme.success;
      case 'never':
        return HospitalTheme.textLight;
      default:
        return HospitalTheme.textMedium;
    }
  }
}

// ==================== COUNTER DETAIL PANEL ====================

class _CounterDetailPanel extends ConsumerStatefulWidget {
  final PatientCounter counter;

  const _CounterDetailPanel({required this.counter});

  @override
  ConsumerState<_CounterDetailPanel> createState() =>
      _CounterDetailPanelState();
}

class _CounterDetailPanelState extends ConsumerState<_CounterDetailPanel> {
  late TextEditingController _valueController;
  late String _selectedResetPeriod;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _valueController =
        TextEditingController(text: widget.counter.currentValue.toString());
    _selectedResetPeriod = widget.counter.resetPeriod;
  }

  @override
  void didUpdateWidget(_CounterDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.counter.id != widget.counter.id) {
      _valueController.text = widget.counter.currentValue.toString();
      _selectedResetPeriod = widget.counter.resetPeriod;
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(counterProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: screenHeight - 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HospitalTheme.buildSectionHeader(
              '${widget.counter.name} Details',
              trailing: HospitalTheme.buildStatusBadge(
                widget.counter.resetPeriod.toUpperCase(),
                color: _getResetPeriodColor(widget.counter.resetPeriod),
              ),
            ),
            _buildInfoCards(),
            const SizedBox(height: 24),
            _buildUpdateForm(),
            if (widget.counter.changedAt != null) ...[
              const SizedBox(height: 24),
              _buildLastUpdateInfo(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        Expanded(
          child: HospitalTheme.buildStatCard(
            title: 'Current Value',
            value: widget.counter.currentValue.toString(),
            icon: Icons.numbers,
            iconColor: HospitalTheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: HospitalTheme.buildStatCard(
            title: 'Next Value',
            value: widget.counter.nextValue.toString(),
            icon: Icons.arrow_forward,
            iconColor: HospitalTheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateForm() {
    final state = ref.watch(counterProvider);

    return HospitalTheme.buildCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HospitalTheme.buildSectionHeader('Update Counter'),
            TextFormField(
              controller: _valueController,
              decoration: const InputDecoration(
                labelText: 'New Value',
                hintText: 'Enter new counter value',
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a value';
                }
                final intValue = int.tryParse(value);
                if (intValue == null || intValue < 0) {
                  return 'Please enter a valid positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.isUpdating ? null : _handleUpdate,
                icon: state.isUpdating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.update),
                label:
                    Text(state.isUpdating ? 'Updating...' : 'Update Counter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HospitalTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastUpdateInfo() {
    return HospitalTheme.buildCard(
      backgroundColor: HospitalTheme.surfaceLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: HospitalTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Last Updated',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatDateTime(widget.counter.changedAt!),
            style: TextStyle(
              fontSize: 14,
              color: HospitalTheme.textMedium,
            ),
          ),
          if (widget.counter.previousValue != null) ...[
            const SizedBox(height: 8),
            Text(
              'Previous value: ${widget.counter.previousValue}',
              style: TextStyle(
                fontSize: 14,
                color: HospitalTheme.textMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleUpdate() {
    if (!_formKey.currentState!.validate()) return;

    final newValue = int.parse(_valueController.text);
    ref.read(counterProvider.notifier).updateCounter(
          widget.counter.id,
          newValue,
          _selectedResetPeriod,
        );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getResetPeriodColor(String period) {
    switch (period.toLowerCase()) {
      case 'yearly':
        return HospitalTheme.medical;
      case 'monthly':
        return HospitalTheme.secondary;
      case 'daily':
        return HospitalTheme.success;
      case 'never':
        return HospitalTheme.textLight;
      default:
        return HospitalTheme.textMedium;
    }
  }
}

// ==================== ADD PATIENT FORM ====================

class _AddPatientForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddPatientForm> createState() => _AddPatientFormState();
}

class _AddPatientFormState extends ConsumerState<_AddPatientForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();
  final _opdController = TextEditingController();
  final _ipdController = TextEditingController();

  String _selectedGender = 'Male';
  DateTime _admissionDate = DateTime.now();
  DateTime _dischargeDate = DateTime.now();
  bool _autoGenerate = true;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    _opdController.dispose();
    _ipdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(counterProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1200;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HospitalTheme.buildSectionHeader(
              'Add New Patient Record',
              trailing: IconButton(
                onPressed: () {
                  // Clear form or close
                  _resetForm();
                },
                icon: const Icon(Icons.refresh),
                tooltip: 'Reset Form',
              ),
            ),

            if (state.recentlyAddedPatient != null) ...[
              _buildRecentPatientCard(),
              const SizedBox(height: 24),
            ],

            // Form Fields in Grid Layout for Desktop
            if (isWideScreen)
              _buildWideScreenLayout()
            else
              _buildNormalLayout(),

            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildWideScreenLayout() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildNameField()),
            const SizedBox(width: 16),
            Expanded(child: _buildAgeField()),
            const SizedBox(width: 16),
            Expanded(child: _buildGenderField()),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildContactField()),
            const SizedBox(width: 16),
            Expanded(child: _buildAdmissionDateField()),
            const SizedBox(width: 16),
            Expanded(child: _buildDischargeDateField()),
          ],
        ),
        const SizedBox(height: 16),
        _buildAutoGenerateSwitch(),
        if (!_autoGenerate) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildOpdField()),
              const SizedBox(width: 16),
              Expanded(child: _buildIpdField()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildNormalLayout() {
    return Column(
      children: [
        _buildNameField(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildAgeField()),
            const SizedBox(width: 16),
            Expanded(child: _buildGenderField()),
          ],
        ),
        const SizedBox(height: 16),
        _buildContactField(),
        const SizedBox(height: 16),
        _buildAdmissionDateField(),
        const SizedBox(height: 16),
        _buildDischargeDateField(),
        const SizedBox(height: 16),
        _buildAutoGenerateSwitch(),
        if (!_autoGenerate) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildOpdField()),
              const SizedBox(width: 16),
              Expanded(child: _buildIpdField()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Patient Name *',
        hintText: 'Enter patient full name',
        prefixIcon: Icon(Icons.person),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter patient name';
        }
        if (value.trim().length < 2) {
          return 'Name must be at least 2 characters';
        }
        return null;
      },
      textCapitalization: TextCapitalization.words,
    );
  }

  Widget _buildAgeField() {
    return TextFormField(
      controller: _ageController,
      decoration: const InputDecoration(
        labelText: 'Age *',
        hintText: 'Age in years',
        prefixIcon: Icon(Icons.calendar_today),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter age';
        }
        final age = int.tryParse(value);
        if (age == null || age < 0 || age > 150) {
          return 'Please enter valid age (0-150)';
        }
        return null;
      },
    );
  }

  Widget _buildGenderField() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: const InputDecoration(
        labelText: 'Gender *',
        prefixIcon: Icon(Icons.people),
      ),
      items: const [
        DropdownMenuItem(value: 'Male', child: Text('Male')),
        DropdownMenuItem(value: 'Female', child: Text('Female')),
        DropdownMenuItem(value: 'Other', child: Text('Other')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedGender = value;
          });
        }
      },
    );
  }

  Widget _buildContactField() {
    return TextFormField(
      controller: _contactController,
      decoration: const InputDecoration(
        labelText: 'Contact Number *',
        hintText: 'Enter phone number',
        prefixIcon: Icon(Icons.phone),
      ),
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter contact number';
        }
        if (value.length < 10) {
          return 'Contact number must be at least 10 digits';
        }
        return null;
      },
    );
  }

  Widget _buildAdmissionDateField() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _admissionDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() {
            _admissionDate = date;
          });
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Admission Date *',
          prefixIcon: Icon(Icons.event),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          '${_admissionDate.day}/${_admissionDate.month}/${_admissionDate.year}',
        ),
      ),
    );
  }

  Widget _buildDischargeDateField() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _dischargeDate,
          firstDate: _admissionDate,
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() {
            _dischargeDate = date;
          });
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Discharge Date *',
          prefixIcon: Icon(Icons.event_available),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          '${_dischargeDate.day}/${_dischargeDate.month}/${_dischargeDate.year}',
        ),
      ),
    );
  }

  Widget _buildAutoGenerateSwitch() {
    return HospitalTheme.buildCard(
      backgroundColor: HospitalTheme.surfaceLight,
      child: SwitchListTile(
        title: const Text('Auto Generate Patient Numbers'),
        subtitle: Text(
          _autoGenerate
              ? 'System will automatically assign OPD/IPD numbers'
              : 'Manually enter OPD/IPD numbers',
        ),
        value: _autoGenerate,
        onChanged: (value) {
          setState(() {
            _autoGenerate = value;
          });
        },
        activeColor: HospitalTheme.primary,
      ),
    );
  }

  Widget _buildOpdField() {
    return TextFormField(
      controller: _opdController,
      decoration: const InputDecoration(
        labelText: 'OPD Number',
        hintText: 'Enter OPD number',
        prefixIcon: Icon(Icons.local_hospital),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: !_autoGenerate
          ? (value) {
              if (value != null && value.isNotEmpty) {
                final number = int.tryParse(value);
                if (number == null || number <= 0) {
                  return 'Please enter valid OPD number';
                }
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildIpdField() {
    return TextFormField(
      controller: _ipdController,
      decoration: const InputDecoration(
        labelText: 'IPD Number',
        hintText: 'Enter IPD number',
        prefixIcon: Icon(Icons.hotel),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: !_autoGenerate
          ? (value) {
              if (value != null && value.isNotEmpty) {
                final number = int.tryParse(value);
                if (number == null || number <= 0) {
                  return 'Please enter valid IPD number';
                }
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildSubmitButton() {
    final state = ref.watch(counterProvider);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: state.isAddingPatient ? null : _handleSubmit,
        icon: state.isAddingPatient
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.person_add),
        label: Text(
            state.isAddingPatient ? 'Adding Patient...' : 'Add Patient Record'),
        style: ElevatedButton.styleFrom(
          backgroundColor: HospitalTheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildRecentPatientCard() {
    final patient = ref.watch(counterProvider).recentlyAddedPatient!;

    return HospitalTheme.buildCard(
      backgroundColor: HospitalTheme.success.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: HospitalTheme.success),
              const SizedBox(width: 8),
              const Text(
                'Recently Added Patient',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  ref.read(counterProvider.notifier).clearRecentPatient();
                },
                icon: const Icon(Icons.close, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Patient ID: ${patient.patientId}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('Name: ${patient.name}'),
          if (patient.opdNumber != null)
            Text('OPD Number: ${patient.opdNumber}'),
          if (patient.ipdNumber != null)
            Text('IPD Number: ${patient.ipdNumber}'),
        ],
      ),
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final admissionDateString = _admissionDate.toIso8601String().split('T')[0];
    final dischargeDateString = _dischargeDate.toIso8601String().split('T')[0];

    ref.read(counterProvider.notifier).addPatientRecord(
          name: _nameController.text.trim(),
          age: int.parse(_ageController.text),
          gender: _selectedGender,
          contact: _contactController.text.trim(),
          admissionDate: admissionDateString,
          dischargeDate: dischargeDateString,
          opdNumber: _opdController.text.isNotEmpty
              ? int.parse(_opdController.text)
              : null,
          ipdNumber: _ipdController.text.isNotEmpty
              ? int.parse(_ipdController.text)
              : null,
          autoGenerate: _autoGenerate,
        );

    // Clear form after successful submission
    _resetForm();
  }

  void _resetForm() {
    _nameController.clear();
    _ageController.clear();
    _contactController.clear();
    _opdController.clear();
    _ipdController.clear();
    setState(() {
      _selectedGender = 'Male';
      _admissionDate = DateTime.now();
      _dischargeDate = DateTime.now();
      _autoGenerate = true;
    });
  }
}
