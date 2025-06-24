import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Models
class PatientDeposit {
  final String id;
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String patientContact;
  final String patientType;
  final int totalDeposits;
  final double totalAmount;
  final String formattedTotalAmount;
  final DateTime firstDepositDate;
  final DateTime lastDepositDate;
  final List<String> admissions;
  final List<String> paymentMethods;
  final List<Deposit> deposits;
  final int totalAdmissions;
  final double averageDepositAmount;

  PatientDeposit({
    required this.id,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.patientContact,
    required this.patientType,
    required this.totalDeposits,
    required this.totalAmount,
    required this.formattedTotalAmount,
    required this.firstDepositDate,
    required this.lastDepositDate,
    required this.admissions,
    required this.paymentMethods,
    required this.deposits,
    required this.totalAdmissions,
    required this.averageDepositAmount,
  });

  factory PatientDeposit.fromJson(Map<String, dynamic> json) {
    return PatientDeposit(
      id: json['_id'] ?? '',
      patientName: json['patientName'] ?? '',
      patientAge: json['patientAge']?.toInt() ?? 0,
      patientGender: json['patientGender'] ?? '',
      patientContact: json['patientContact'] ?? '',
      patientType: json['patientType'] ?? '',
      totalDeposits: json['totalDeposits']?.toInt() ?? 0,
      totalAmount: (json['totalAmount']?.toDouble()) ?? 0.0,
      formattedTotalAmount: json['formattedTotalAmount'] ?? '₹0',
      firstDepositDate:
          DateTime.tryParse(json['firstDepositDate'] ?? '') ?? DateTime.now(),
      lastDepositDate:
          DateTime.tryParse(json['lastDepositDate'] ?? '') ?? DateTime.now(),
      admissions: List<String>.from(json['admissions'] ?? []),
      paymentMethods: List<String>.from(json['paymentMethods'] ?? []),
      deposits: (json['deposits'] as List<dynamic>?)
              ?.map((d) => Deposit.fromJson(d))
              .toList() ??
          [],
      totalAdmissions: json['totalAdmissions']?.toInt() ?? 0,
      averageDepositAmount: (json['averageDepositAmount']?.toDouble()) ?? 0.0,
    );
  }
}

class Deposit {
  final String receiptId;
  final String admissionId;
  final double amount;
  final String paymentMethod;
  final DateTime generatedAt;
  final String? receiptUrl;
  final int? sequenceNumber;

  Deposit({
    required this.receiptId,
    required this.admissionId,
    required this.amount,
    required this.paymentMethod,
    required this.generatedAt,
    this.receiptUrl,
    this.sequenceNumber,
  });

  factory Deposit.fromJson(Map<String, dynamic> json) {
    return Deposit(
      receiptId: json['receiptId'] ?? '',
      admissionId: json['admissionId'] ?? '',
      amount: (json['amount']?.toDouble()) ?? 0.0,
      paymentMethod: json['paymentMethod'] ?? '',
      generatedAt:
          DateTime.tryParse(json['generatedAt'] ?? '') ?? DateTime.now(),
      receiptUrl: json['receiptUrl'],
      sequenceNumber: json['sequenceNumber']?.toInt(),
    );
  }
}

class DepositSummary {
  final int totalPatients;
  final int totalDeposits;
  final double totalAmount;
  final String formattedTotalAmount;
  final double averageDepositAmount;
  final String formattedAverageDepositAmount;
  final double minDepositAmount;
  final double maxDepositAmount;
  final double averageDepositsPerPatient;

  DepositSummary({
    required this.totalPatients,
    required this.totalDeposits,
    required this.totalAmount,
    required this.formattedTotalAmount,
    required this.averageDepositAmount,
    required this.formattedAverageDepositAmount,
    required this.minDepositAmount,
    required this.maxDepositAmount,
    required this.averageDepositsPerPatient,
  });

  factory DepositSummary.fromJson(Map<String, dynamic> json) {
    return DepositSummary(
      totalPatients: json['totalPatients']?.toInt() ?? 0,
      totalDeposits: json['totalDeposits']?.toInt() ?? 0,
      totalAmount: (json['totalAmount']?.toDouble()) ?? 0.0,
      formattedTotalAmount: json['formattedTotalAmount'] ?? '₹0',
      averageDepositAmount: (json['averageDepositAmount']?.toDouble()) ?? 0.0,
      formattedAverageDepositAmount:
          json['formattedAverageDepositAmount'] ?? '₹0',
      minDepositAmount: (json['minDepositAmount']?.toDouble()) ?? 0.0,
      maxDepositAmount: (json['maxDepositAmount']?.toDouble()) ?? 0.0,
      averageDepositsPerPatient:
          (json['averageDepositsPerPatient']?.toDouble()) ?? 0.0,
    );
  }
}

class DepositsResponse {
  final bool success;
  final List<PatientDeposit> patients;
  final DepositSummary summary;

  DepositsResponse({
    required this.success,
    required this.patients,
    required this.summary,
  });

  factory DepositsResponse.fromJson(Map<String, dynamic> json) {
    return DepositsResponse(
      success: json['success'] ?? false,
      patients: (json['data']?['patients'] as List<dynamic>?)
              ?.map((p) => PatientDeposit.fromJson(p))
              .toList() ??
          [],
      summary: DepositSummary.fromJson(json['data']?['summary'] ?? {}),
    );
  }
}

// Filter states
class DepositFilters {
  final String? genderFilter;
  final String? patientTypeFilter;
  final String? paymentMethodFilter;
  final DateTimeRange? dateRange;
  final double? minAmount;
  final double? maxAmount;
  final bool showHighValueDeposits;

  const DepositFilters({
    this.genderFilter,
    this.patientTypeFilter,
    this.paymentMethodFilter,
    this.dateRange,
    this.minAmount,
    this.maxAmount,
    this.showHighValueDeposits = false,
  });

  DepositFilters copyWith({
    String? genderFilter,
    String? patientTypeFilter,
    String? paymentMethodFilter,
    DateTimeRange? dateRange,
    double? minAmount,
    double? maxAmount,
    bool? showHighValueDeposits,
  }) {
    return DepositFilters(
      genderFilter: genderFilter ?? this.genderFilter,
      patientTypeFilter: patientTypeFilter ?? this.patientTypeFilter,
      paymentMethodFilter: paymentMethodFilter ?? this.paymentMethodFilter,
      dateRange: dateRange ?? this.dateRange,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      showHighValueDeposits:
          showHighValueDeposits ?? this.showHighValueDeposits,
    );
  }

  bool get hasActiveFilters =>
      genderFilter != null ||
      patientTypeFilter != null ||
      paymentMethodFilter != null ||
      dateRange != null ||
      minAmount != null ||
      maxAmount != null ||
      showHighValueDeposits;
}

// Providers
final depositsProvider = FutureProvider<DepositsResponse>((ref) async {
  final response = await http.get(
    Uri.parse('${KVM_URL}/reception/getAllPatientsDeposits'),
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    return DepositsResponse.fromJson(jsonData);
  } else {
    throw Exception('Failed to load deposits: ${response.statusCode}');
  }
});

final selectedPatientProvider = StateProvider<PatientDeposit?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');
final sortColumnProvider = StateProvider<String>((ref) => 'patientName');
final sortAscendingProvider = StateProvider<bool>((ref) => true);
final depositFiltersProvider =
    StateProvider<DepositFilters>((ref) => const DepositFilters());
final showFiltersProvider = StateProvider<bool>((ref) => false);

// Main Screen Widget
class PatientDepositsScreen extends ConsumerStatefulWidget {
  const PatientDepositsScreen({super.key});

  @override
  ConsumerState<PatientDepositsScreen> createState() =>
      _PatientDepositsScreenState();
}

class _PatientDepositsScreenState extends ConsumerState<PatientDepositsScreen> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: HospitalTheme.background,
      appBar: HospitalTheme.buildAppBar(
        context: context,
        title: 'Patient Deposits',
        showBackButton: false,
        actions: [
          Semantics(
            label: 'Refresh deposits data',
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.refresh(depositsProvider),
              tooltip: 'Refresh (Ctrl+R)',
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
            _searchFocusNode.requestFocus();
          },
          const SingleActivator(LogicalKeyboardKey.keyR, control: true): () {
            ref.refresh(depositsProvider);
          },
          const SingleActivator(LogicalKeyboardKey.escape): () {
            ref.read(selectedPatientProvider.notifier).state = null;
            ref.read(showFiltersProvider.notifier).state = false;
          },
          const SingleActivator(LogicalKeyboardKey.keyT, control: true): () {
            ref.read(showFiltersProvider.notifier).update((state) => !state);
          },
        },
        child: Focus(
          autofocus: true,
          child: isMobile
              ? _buildMobileLayout()
              : _buildDesktopLayout(screenWidth),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Semantics(
      label: 'Mobile view notice',
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.tablet_mac, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Mobile view - Use tablet or desktop for full functionality',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(double screenWidth) {
    final selectedPatient = ref.watch(selectedPatientProvider);
    final showDetailPanel = selectedPatient != null && screenWidth > 1200;

    return Row(
      children: [
        // Main content
        Expanded(
          flex: showDetailPanel ? 3 : 1,
          child: Column(
            children: [
              _buildCompactSummaryCards(),
              _buildFiltersSection(),
              const SizedBox(height: 8),
              _buildSearchAndActions(),
              const SizedBox(height: 12),
              Expanded(child: _buildDepositsTable()),
            ],
          ),
        ),

        // Detail panel
        if (showDetailPanel) ...[
          const VerticalDivider(width: 1),
          Expanded(
            flex: 2,
            child: _buildDetailPanel(selectedPatient),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactSummaryCards() {
    return Consumer(
      builder: (context, ref, child) {
        final depositsAsync = ref.watch(depositsProvider);

        return depositsAsync.when(
          data: (response) => _buildCompactSummaryContent(response.summary),
          loading: () => _buildSummaryLoading(),
          error: (error, stack) => _buildSummaryError(),
        );
      },
    );
  }

  Widget _buildCompactSummaryContent(DepositSummary summary) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HospitalTheme.cardBackground,
        borderRadius: HospitalTheme.radiusSmall,
        border: Border.all(color: HospitalTheme.border),
        boxShadow: HospitalTheme.shadowSmall,
      ),
      child: Semantics(
        label: 'Deposit summary statistics',
        child: Row(
          children: [
            Expanded(
                child: _buildCompactStatItem(
              'Patients',
              summary.totalPatients.toString(),
              Icons.people_outline,
              HospitalTheme.primary,
            )),
            _buildDivider(),
            Expanded(
                child: _buildCompactStatItem(
              'Deposits',
              summary.totalDeposits.toString(),
              Icons.receipt_long_outlined,
              HospitalTheme.secondary,
            )),
            _buildDivider(),
            Expanded(
                child: _buildCompactStatItem(
              'Total Amount',
              summary.formattedTotalAmount,
              Icons.currency_rupee,
              HospitalTheme.success,
            )),
            if (screenWidth > 1200) ...[
              _buildDivider(),
              Expanded(
                  child: _buildCompactStatItem(
                'Avg Amount',
                summary.formattedAverageDepositAmount,
                Icons.analytics_outlined,
                HospitalTheme.info,
              )),
            ],
            if (screenWidth > 1400) ...[
              _buildDivider(),
              Expanded(
                  child: _buildCompactStatItem(
                'Avg/Patient',
                '${summary.averageDepositsPerPatient.toStringAsFixed(1)}',
                Icons.person_pin_outlined,
                HospitalTheme.warning,
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStatItem(
      String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: HospitalTheme.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: HospitalTheme.border,
    );
  }

  Widget _buildFiltersSection() {
    final showFilters = ref.watch(showFiltersProvider);
    final filters = ref.watch(depositFiltersProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: showFilters ? null : 0,
      child: showFilters
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HospitalTheme.surfaceLight,
                borderRadius: HospitalTheme.radiusSmall,
                border: Border.all(color: HospitalTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.filter_list,
                          size: 16, color: HospitalTheme.textMedium),
                      const SizedBox(width: 8),
                      Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: HospitalTheme.textDark,
                        ),
                      ),
                      const Spacer(),
                      if (filters.hasActiveFilters)
                        TextButton.icon(
                          onPressed: () {
                            ref.read(depositFiltersProvider.notifier).state =
                                const DepositFilters();
                          },
                          icon: const Icon(Icons.clear_all, size: 16),
                          label: const Text('Clear All'),
                          style: TextButton.styleFrom(
                            foregroundColor: HospitalTheme.error,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      _buildFilterDropdown(
                        'Gender',
                        filters.genderFilter,
                        ['Male', 'Female'],
                        (value) => ref
                            .read(depositFiltersProvider.notifier)
                            .state = filters.copyWith(genderFilter: value),
                      ),
                      _buildFilterDropdown(
                        'Patient Type',
                        filters.patientTypeFilter,
                        ['Internal', 'External'],
                        (value) => ref
                            .read(depositFiltersProvider.notifier)
                            .state = filters.copyWith(patientTypeFilter: value),
                      ),
                      _buildFilterDropdown(
                        'Payment Method',
                        filters.paymentMethodFilter,
                        ['Cash', 'Card', 'UPI', 'Bank Transfer', 'Cheque'],
                        (value) =>
                            ref.read(depositFiltersProvider.notifier).state =
                                filters.copyWith(paymentMethodFilter: value),
                      ),
                      _buildAmountRangeFilter(filters),
                      _buildDateRangeFilter(filters),
                      _buildHighValueToggle(filters),
                    ],
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String? currentValue,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return SizedBox(
      width: 140,
      child: DropdownButtonFormField<String>(
        value: currentValue,
        decoration: InputDecoration(
          labelText: label,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('All'),
          ),
          ...options.map((option) => DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              )),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildAmountRangeFilter(DepositFilters filters) {
    return SizedBox(
      width: 200,
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Min Amount',
                prefixText: '₹',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final amount = double.tryParse(value);
                ref.read(depositFiltersProvider.notifier).state =
                    filters.copyWith(minAmount: amount);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Max Amount',
                prefixText: '₹',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final amount = double.tryParse(value);
                ref.read(depositFiltersProvider.notifier).state =
                    filters.copyWith(maxAmount: amount);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeFilter(DepositFilters filters) {
    return SizedBox(
      width: 180,
      child: OutlinedButton.icon(
        onPressed: () async {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            initialDateRange: filters.dateRange,
          );
          if (picked != null) {
            ref.read(depositFiltersProvider.notifier).state =
                filters.copyWith(dateRange: picked);
          }
        },
        icon: const Icon(Icons.date_range, size: 16),
        label: Text(
          filters.dateRange != null
              ? '${_formatDate(filters.dateRange!.start)} - ${_formatDate(filters.dateRange!.end)}'
              : 'Date Range',
          style: const TextStyle(fontSize: 12),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildHighValueToggle(DepositFilters filters) {
    return SizedBox(
      width: 140,
      child: CheckboxListTile(
        value: filters.showHighValueDeposits,
        onChanged: (value) {
          ref.read(depositFiltersProvider.notifier).state =
              filters.copyWith(showHighValueDeposits: value ?? false);
        },
        title: const Text('High Value (>₹10k)', style: TextStyle(fontSize: 12)),
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    );
  }

  Widget _buildSearchAndActions() {
    final showFilters = ref.watch(showFiltersProvider);
    final filters = ref.watch(depositFiltersProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: 'Search patients by name, ID, or contact',
              child: TextField(
                focusNode: _searchFocusNode,
                onChanged: (value) =>
                    ref.read(searchQueryProvider.notifier).state = value,
                decoration: InputDecoration(
                  labelText: 'Search patients... (Ctrl+F)',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: ref.watch(searchQueryProvider).isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Semantics(
            label: 'Toggle filters panel',
            child: OutlinedButton.icon(
              onPressed: () {
                ref
                    .read(showFiltersProvider.notifier)
                    .update((state) => !state);
              },
              icon: Icon(
                showFilters ? Icons.filter_list_off : Icons.filter_list,
                size: 18,
              ),
              label: Text(showFilters ? 'Hide Filters' : 'Show Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: filters.hasActiveFilters
                    ? HospitalTheme.primary
                    : HospitalTheme.textMedium,
                side: BorderSide(
                  color: filters.hasActiveFilters
                      ? HospitalTheme.primary
                      : HospitalTheme.border,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            label: 'Refresh deposits data',
            child: ElevatedButton.icon(
              onPressed: () => ref.refresh(depositsProvider),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLoading() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: HospitalTheme.radiusSmall,
      ),
    );
  }

  Widget _buildSummaryError() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HospitalTheme.error.withOpacity(0.1),
        borderRadius: HospitalTheme.radiusSmall,
        border: Border.all(color: HospitalTheme.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: HospitalTheme.error, size: 20),
          const SizedBox(width: 12),
          Text(
            'Error loading summary',
            style: TextStyle(
              color: HospitalTheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepositsTable() {
    return Consumer(
      builder: (context, ref, child) {
        final depositsAsync = ref.watch(depositsProvider);
        final searchQuery = ref.watch(searchQueryProvider);
        final sortColumn = ref.watch(sortColumnProvider);
        final sortAscending = ref.watch(sortAscendingProvider);
        final filters = ref.watch(depositFiltersProvider);

        return depositsAsync.when(
          data: (response) {
            var filteredPatients = response.patients;

            // Apply search filter
            if (searchQuery.isNotEmpty) {
              filteredPatients = filteredPatients
                  .where((patient) =>
                      patient.patientName
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()) ||
                      patient.id
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()) ||
                      patient.patientContact.contains(searchQuery))
                  .toList();
            }

            // Apply filters
            filteredPatients = _applyFilters(filteredPatients, filters);

            // Apply sorting
            filteredPatients.sort((a, b) {
              int comparison = 0;
              switch (sortColumn) {
                case 'patientName':
                  comparison = a.patientName.compareTo(b.patientName);
                  break;
                case 'totalAmount':
                  comparison = a.totalAmount.compareTo(b.totalAmount);
                  break;
                case 'totalDeposits':
                  comparison = a.totalDeposits.compareTo(b.totalDeposits);
                  break;
                case 'lastDepositDate':
                  comparison = a.lastDepositDate.compareTo(b.lastDepositDate);
                  break;
                default:
                  comparison = a.patientName.compareTo(b.patientName);
              }
              return sortAscending ? comparison : -comparison;
            });

            return _buildTable(filteredPatients, response.patients.length);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(depositsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<PatientDeposit> _applyFilters(
      List<PatientDeposit> patients, DepositFilters filters) {
    return patients.where((patient) {
      // Gender filter
      if (filters.genderFilter != null &&
          patient.patientGender != filters.genderFilter) {
        return false;
      }

      // Patient type filter
      if (filters.patientTypeFilter != null &&
          patient.patientType != filters.patientTypeFilter) {
        return false;
      }

      // Payment method filter
      if (filters.paymentMethodFilter != null &&
          !patient.paymentMethods.contains(filters.paymentMethodFilter)) {
        return false;
      }

      // Amount range filter
      if (filters.minAmount != null &&
          patient.totalAmount < filters.minAmount!) {
        return false;
      }
      if (filters.maxAmount != null &&
          patient.totalAmount > filters.maxAmount!) {
        return false;
      }

      // Date range filter
      if (filters.dateRange != null &&
          (patient.lastDepositDate.isBefore(filters.dateRange!.start) ||
              patient.lastDepositDate.isAfter(
                  filters.dateRange!.end.add(const Duration(days: 1))))) {
        return false;
      }

      // High value deposits filter
      if (filters.showHighValueDeposits && patient.totalAmount <= 10000) {
        return false;
      }

      return true;
    }).toList();
  }

  Widget _buildTable(List<PatientDeposit> patients, int totalCount) {
    final filteredCount = patients.length;
    final hasFilters = totalCount != filteredCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasFilters)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Showing $filteredCount of $totalCount patients',
                style: TextStyle(
                  color: HospitalTheme.textMedium,
                  fontSize: 14,
                ),
              ),
            ),
          Expanded(
            child: HospitalTheme.buildCard(
              padding: EdgeInsets.zero,
              child: Scrollbar(
                controller: _horizontalScrollController,
                thumbVisibility: true,
                child: Scrollbar(
                  controller: _verticalScrollController,
                  thumbVisibility: true,
                  notificationPredicate: (notification) =>
                      notification.depth == 1,
                  child: SingleChildScrollView(
                    controller: _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      controller: _verticalScrollController,
                      child: DataTable(
                        sortColumnIndex:
                            _getSortColumnIndex(ref.watch(sortColumnProvider)),
                        sortAscending: ref.watch(sortAscendingProvider),
                        showCheckboxColumn: false,
                        columns: _buildTableColumns(),
                        rows: patients
                            .map((patient) => _buildTableRow(patient))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DataColumn> _buildTableColumns() {
    return [
      DataColumn(
        label: const Text('Patient ID'),
        onSort: (columnIndex, ascending) => _onSort('id', ascending),
      ),
      DataColumn(
        label: const Text('Patient Name'),
        onSort: (columnIndex, ascending) => _onSort('patientName', ascending),
      ),
      DataColumn(
        label: const Text('Age'),
        numeric: true,
      ),
      DataColumn(
        label: const Text('Gender'),
      ),
      DataColumn(
        label: const Text('Contact'),
      ),
      DataColumn(
        label: const Text('Type'),
      ),
      DataColumn(
        label: const Text('Total Deposits'),
        numeric: true,
        onSort: (columnIndex, ascending) => _onSort('totalDeposits', ascending),
      ),
      DataColumn(
        label: const Text('Total Amount'),
        numeric: true,
        onSort: (columnIndex, ascending) => _onSort('totalAmount', ascending),
      ),
      DataColumn(
        label: const Text('Last Deposit'),
        onSort: (columnIndex, ascending) =>
            _onSort('lastDepositDate', ascending),
      ),
      const DataColumn(
        label: Text('Actions'),
      ),
    ];
  }

  DataRow _buildTableRow(PatientDeposit patient) {
    final isSelected = ref.watch(selectedPatientProvider)?.id == patient.id;

    return DataRow(
      selected: isSelected,
      onSelectChanged: (selected) {
        if (selected == true) {
          ref.read(selectedPatientProvider.notifier).state = patient;
        } else {
          ref.read(selectedPatientProvider.notifier).state = null;
        }
      },
      cells: [
        DataCell(
          Semantics(
            label: 'Patient ID ${patient.id}',
            child: Text(
              patient.id,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: HospitalTheme.primary,
              ),
            ),
          ),
        ),
        DataCell(
          Semantics(
            label: 'Patient name ${patient.patientName}',
            child: Text(patient.patientName),
          ),
        ),
        DataCell(
          Semantics(
            label: 'Age ${patient.patientAge} years',
            child: Text(patient.patientAge.toString()),
          ),
        ),
        DataCell(
          Semantics(
            label: 'Gender ${patient.patientGender}',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: patient.patientGender.toLowerCase() == 'male'
                    ? Colors.blue.shade50
                    : Colors.pink.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                patient.patientGender,
                style: TextStyle(
                  color: patient.patientGender.toLowerCase() == 'male'
                      ? Colors.blue.shade700
                      : Colors.pink.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        DataCell(
          Semantics(
            label: 'Contact ${patient.patientContact}',
            child: Text(patient.patientContact),
          ),
        ),
        DataCell(
          Semantics(
            label: 'Patient type ${patient.patientType}',
            child: HospitalTheme.buildStatusBadge(
              patient.patientType,
              color: patient.patientType == 'Internal'
                  ? HospitalTheme.primary
                  : HospitalTheme.secondary,
            ),
          ),
        ),
        DataCell(
          Semantics(
            label: '${patient.totalDeposits} total deposits',
            child: Text(
              patient.totalDeposits.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        DataCell(
          Semantics(
            label: 'Total amount ${patient.formattedTotalAmount}',
            child: Text(
              patient.formattedTotalAmount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: HospitalTheme.success,
              ),
            ),
          ),
        ),
        DataCell(
          Semantics(
            label: 'Last deposit on ${_formatDate(patient.lastDepositDate)}',
            child: Text(
              _formatDate(patient.lastDepositDate),
              style: TextStyle(color: HospitalTheme.textMedium),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: 'View details for ${patient.patientName}',
                child: IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () {
                    ref.read(selectedPatientProvider.notifier).state = patient;
                  },
                  tooltip: 'View Details',
                ),
              ),
              PopupMenuButton<String>(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'receipts',
                    child: Row(
                      children: [
                        Icon(Icons.receipt),
                        SizedBox(width: 8),
                        Text('View Receipts'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.download),
                        SizedBox(width: 8),
                        Text('Export'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'receipts':
                      _showReceiptsDialog(patient);
                      break;
                    case 'export':
                      _exportPatientData(patient);
                      break;
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailPanel(PatientDeposit patient) {
    return Container(
      color: HospitalTheme.cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight,
              border: Border(bottom: BorderSide(color: HospitalTheme.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.patientName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${patient.id}',
                        style: TextStyle(
                          color: HospitalTheme.textMedium,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  label: 'Close detail panel',
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      ref.read(selectedPatientProvider.notifier).state = null;
                    },
                    tooltip: 'Close (Esc)',
                  ),
                ),
              ],
            ),
          ),

          // Patient Info
          Padding(
            padding: const EdgeInsets.all(24),
            child: Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _buildDetailItem('Age', patient.patientAge.toString()),
                _buildDetailItem('Gender', patient.patientGender),
                _buildDetailItem('Contact', patient.patientContact),
                _buildDetailItem('Type', patient.patientType),
                _buildDetailItem(
                    'Total Deposits', patient.totalDeposits.toString()),
                _buildDetailItem('Total Amount', patient.formattedTotalAmount),
                _buildDetailItem('Average Amount',
                    '₹${patient.averageDepositAmount.toStringAsFixed(2)}'),
                _buildDetailItem(
                    'Admissions', patient.totalAdmissions.toString()),
              ],
            ),
          ),

          // Deposits List
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Deposit History (${patient.deposits.length} deposits)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: patient.deposits.length,
                    itemBuilder: (context, index) {
                      final deposit = patient.deposits[index];
                      return _buildDepositCard(deposit);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: HospitalTheme.textMedium,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDepositCard(Deposit deposit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${deposit.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.success,
                  ),
                ),
                if (deposit.sequenceNumber != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: HospitalTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#${deposit.sequenceNumber}',
                      style: TextStyle(
                        color: HospitalTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Receipt ID: ${deposit.receiptId}',
              style: TextStyle(
                color: HospitalTheme.textMedium,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Payment: ${deposit.paymentMethod}',
              style: TextStyle(
                color: HospitalTheme.textMedium,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Date: ${_formatDateTime(deposit.generatedAt)}',
              style: TextStyle(
                color: HospitalTheme.textMedium,
                fontSize: 12,
              ),
            ),
            if (deposit.receiptUrl != null) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Methods().openPdf(deposit.receiptUrl!),
                icon: const Icon(Icons.receipt, size: 16),
                label: const Text('View Receipt'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(120, 32),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onSort(String column, bool ascending) {
    ref.read(sortColumnProvider.notifier).state = column;
    ref.read(sortAscendingProvider.notifier).state = ascending;
  }

  int _getSortColumnIndex(String column) {
    switch (column) {
      case 'id':
        return 0;
      case 'patientName':
        return 1;
      case 'totalDeposits':
        return 6;
      case 'totalAmount':
        return 7;
      case 'lastDepositDate':
        return 8;
      default:
        return 0;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showReceiptsDialog(PatientDeposit patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Receipts for ${patient.patientName}'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: ListView.builder(
            itemCount: patient.deposits.length,
            itemBuilder: (context, index) {
              final deposit = patient.deposits[index];
              return ListTile(
                title: Text(deposit.receiptId),
                subtitle: Text(
                    '₹${deposit.amount} - ${_formatDateTime(deposit.generatedAt)}'),
                trailing: deposit.receiptUrl != null
                    ? IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () => Methods().openPdf(deposit.receiptUrl!),
                      )
                    : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _exportPatientData(PatientDeposit patient) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting data for ${patient.patientName}...'),
        backgroundColor: HospitalTheme.success,
      ),
    );
  }
}
