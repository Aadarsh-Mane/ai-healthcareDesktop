import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

// Data Models
class DepositRecord {
  final String id;
  final String receiptId;
  final String patientId;
  final PatientDetails patientDetails;
  final AdmissionDetails admissionDetails;
  final DepositDetails depositDetails;
  final ReceiptDetails receiptDetails;
  final HospitalDetails hospitalDetails;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DepositRecord({
    required this.id,
    required this.receiptId,
    required this.patientId,
    required this.patientDetails,
    required this.admissionDetails,
    required this.depositDetails,
    required this.receiptDetails,
    required this.hospitalDetails,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DepositRecord.fromJson(Map<String, dynamic> json) {
    return DepositRecord(
      id: json['_id'] ?? '',
      receiptId: json['receiptId'] ?? '',
      patientId: json['patientId'] ?? '',
      patientDetails: PatientDetails.fromJson(json['patientDetails'] ?? {}),
      admissionDetails:
          AdmissionDetails.fromJson(json['admissionDetails'] ?? {}),
      depositDetails: DepositDetails.fromJson(json['depositDetails'] ?? {}),
      receiptDetails: ReceiptDetails.fromJson(json['receiptDetails'] ?? {}),
      hospitalDetails: HospitalDetails.fromJson(json['hospitalDetails'] ?? {}),
      createdAt: DateTime.tryParse(json['metadata']?['createdAt'] ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['metadata']?['updatedAt'] ?? '') ??
          DateTime.now(),
    );
  }
}

class PatientDetails {
  final String name;
  final int age;
  final String gender;
  final String contact;
  final String address;
  final String patientType;

  const PatientDetails({
    required this.name,
    required this.age,
    required this.gender,
    required this.contact,
    required this.address,
    required this.patientType,
  });

  factory PatientDetails.fromJson(Map<String, dynamic> json) {
    return PatientDetails(
      name: json['name'] ?? 'Unknown',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? 'Unknown',
      contact: json['contact'] ?? '',
      address: json['address'] ?? '',
      patientType: json['patientType'] ?? 'External',
    );
  }
}

class AdmissionDetails {
  final DateTime admissionDate;
  final String doctorName;
  final String sectionName;
  final String? reasonForAdmission;
  final int? bedNumber;

  const AdmissionDetails({
    required this.admissionDate,
    required this.doctorName,
    required this.sectionName,
    this.reasonForAdmission,
    this.bedNumber,
  });

  factory AdmissionDetails.fromJson(Map<String, dynamic> json) {
    return AdmissionDetails(
      admissionDate:
          DateTime.tryParse(json['admissionDate'] ?? '') ?? DateTime.now(),
      doctorName: json['doctorName'] ?? 'Unknown',
      sectionName: json['sectionName'] ?? 'General',
      reasonForAdmission: json['reasonForAdmission'],
      bedNumber: json['bedNumber'],
    );
  }
}

class DepositDetails {
  final double depositAmount;
  final String paymentMethod;
  final String? transactionId;
  final String? chequeNumber;
  final String? bankName;
  final String remarks;

  const DepositDetails({
    required this.depositAmount,
    required this.paymentMethod,
    this.transactionId,
    this.chequeNumber,
    this.bankName,
    required this.remarks,
  });

  factory DepositDetails.fromJson(Map<String, dynamic> json) {
    return DepositDetails(
      depositAmount: (json['depositAmount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? 'Cash',
      transactionId: json['transactionId'],
      chequeNumber: json['chequeNumber'],
      bankName: json['bankName'],
      remarks: json['remarks'] ?? '',
    );
  }
}

class ReceiptDetails {
  final GeneratedBy generatedBy;
  final DateTime generatedAt;
  final bool isActive;
  final String receiptUrl;

  const ReceiptDetails({
    required this.generatedBy,
    required this.generatedAt,
    required this.isActive,
    required this.receiptUrl,
  });

  factory ReceiptDetails.fromJson(Map<String, dynamic> json) {
    return ReceiptDetails(
      generatedBy: GeneratedBy.fromJson(json['generatedBy'] ?? {}),
      generatedAt:
          DateTime.tryParse(json['generatedAt'] ?? '') ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
      receiptUrl: json['receiptUrl'] ?? '',
    );
  }
}

class GeneratedBy {
  final String userName;
  final String userType;

  const GeneratedBy({
    required this.userName,
    required this.userType,
  });

  factory GeneratedBy.fromJson(Map<String, dynamic> json) {
    return GeneratedBy(
      userName: json['userName'] ?? 'Unknown',
      userType: json['userType'] ?? 'System',
    );
  }
}

class HospitalDetails {
  final String hospitalName;
  final String hospitalAddress;
  final String hospitalContact;
  final String hospitalEmail;
  final String registrationNumber;

  const HospitalDetails({
    required this.hospitalName,
    required this.hospitalAddress,
    required this.hospitalContact,
    required this.hospitalEmail,
    required this.registrationNumber,
  });

  factory HospitalDetails.fromJson(Map<String, dynamic> json) {
    return HospitalDetails(
      hospitalName: json['hospitalName'] ?? 'Unknown Hospital',
      hospitalAddress: json['hospitalAddress'] ?? '',
      hospitalContact: json['hospitalContact'] ?? '',
      hospitalEmail: json['hospitalEmail'] ?? '',
      registrationNumber: json['registrationNumber'] ?? '',
    );
  }
}

class DepositSummary {
  final int totalReceipts;
  final double totalAmount;
  final double avgAmount;
  final double minAmount;
  final double maxAmount;
  final List<RecentDeposit> recentDeposits;
  final List<TopDoctor> topDoctors;
  final List<PaymentMethodStat> paymentMethodStats;
  final List<DailyTrend> dailyTrends;

  const DepositSummary({
    required this.totalReceipts,
    required this.totalAmount,
    required this.avgAmount,
    required this.minAmount,
    required this.maxAmount,
    required this.recentDeposits,
    required this.topDoctors,
    required this.paymentMethodStats,
    required this.dailyTrends,
  });

  factory DepositSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final overview = data['overview'] ?? {};

    return DepositSummary(
      totalReceipts: overview['totalReceipts'] ?? 0,
      totalAmount: (overview['totalAmount'] ?? 0).toDouble(),
      avgAmount: (overview['avgAmount'] ?? 0).toDouble(),
      minAmount: (overview['minAmount'] ?? 0).toDouble(),
      maxAmount: (overview['maxAmount'] ?? 0).toDouble(),
      recentDeposits: (data['recentDeposits'] as List<dynamic>? ?? [])
          .map((item) => RecentDeposit.fromJson(item))
          .toList(),
      topDoctors: (data['topDoctors'] as List<dynamic>? ?? [])
          .map((item) => TopDoctor.fromJson(item))
          .toList(),
      paymentMethodStats: (data['paymentMethodStats'] as List<dynamic>? ?? [])
          .map((item) => PaymentMethodStat.fromJson(item))
          .toList(),
      dailyTrends: (data['dailyTrends'] as List<dynamic>? ?? [])
          .map((item) => DailyTrend.fromJson(item))
          .toList(),
    );
  }
}

class RecentDeposit {
  final String receiptId;
  final String patientId;
  final String patientName;
  final double amount;
  final String formattedAmount;
  final String paymentMethod;
  final DateTime generatedAt;
  final int daysAgo;

  const RecentDeposit({
    required this.receiptId,
    required this.patientId,
    required this.patientName,
    required this.amount,
    required this.formattedAmount,
    required this.paymentMethod,
    required this.generatedAt,
    required this.daysAgo,
  });

  factory RecentDeposit.fromJson(Map<String, dynamic> json) {
    return RecentDeposit(
      receiptId: json['receiptId'] ?? '',
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? 'Unknown',
      amount: (json['amount'] ?? 0).toDouble(),
      formattedAmount: json['formattedAmount'] ?? '₹0.00',
      paymentMethod: json['paymentMethod'] ?? 'Cash',
      generatedAt:
          DateTime.tryParse(json['generatedAt'] ?? '') ?? DateTime.now(),
      daysAgo: json['daysAgo'] ?? 0,
    );
  }
}

class TopDoctor {
  final String doctorName;
  final int depositCount;
  final double totalAmount;
  final String formattedAmount;

  const TopDoctor({
    required this.doctorName,
    required this.depositCount,
    required this.totalAmount,
    required this.formattedAmount,
  });

  factory TopDoctor.fromJson(Map<String, dynamic> json) {
    return TopDoctor(
      doctorName: json['doctorName'] ?? 'Unknown',
      depositCount: json['depositCount'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      formattedAmount: json['formattedAmount'] ?? '₹0.00',
    );
  }
}

class PaymentMethodStat {
  final String paymentMethod;
  final int count;
  final double totalAmount;
  final String formattedAmount;
  final double percentage;

  const PaymentMethodStat({
    required this.paymentMethod,
    required this.count,
    required this.totalAmount,
    required this.formattedAmount,
    required this.percentage,
  });

  factory PaymentMethodStat.fromJson(Map<String, dynamic> json) {
    return PaymentMethodStat(
      paymentMethod: json['paymentMethod'] ?? 'Unknown',
      count: json['count'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      formattedAmount: json['formattedAmount'] ?? '₹0.00',
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class DailyTrend {
  final DateTime date;
  final int count;
  final double amount;
  final String formattedAmount;

  const DailyTrend({
    required this.date,
    required this.count,
    required this.amount,
    required this.formattedAmount,
  });

  factory DailyTrend.fromJson(Map<String, dynamic> json) {
    return DailyTrend(
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      count: json['count'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      formattedAmount: json['formattedAmount'] ?? '₹0.00',
    );
  }
}

// Providers
final depositsProvider =
    StateNotifierProvider<DepositsNotifier, AsyncValue<List<DepositRecord>>>(
        (ref) {
  return DepositsNotifier();
});

final depositSummaryProvider =
    StateNotifierProvider<DepositSummaryNotifier, AsyncValue<DepositSummary>>(
        (ref) {
  return DepositSummaryNotifier();
});

final selectedDepositProvider = StateProvider<DepositRecord?>((ref) => null);

final searchQueryProvider = StateProvider<String>((ref) => '');

final selectedPaymentMethodFilterProvider =
    StateProvider<String?>((ref) => null);

final selectedDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

class DepositsNotifier extends StateNotifier<AsyncValue<List<DepositRecord>>> {
  DepositsNotifier() : super(const AsyncValue.loading()) {
    loadDeposits();
  }

  Future<void> loadDeposits() async {
    try {
      state = const AsyncValue.loading();
      final response = await http.get(
        Uri.parse('${KVM_URL}/reception/getAllDeposits'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final deposits = (jsonData['data'] as List<dynamic>? ?? [])
            .map((item) => DepositRecord.fromJson(item))
            .toList();
        state = AsyncValue.data(deposits);
      } else {
        state = AsyncValue.error('Failed to load deposits', StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refreshDeposits() async {
    await loadDeposits();
  }
}

class DepositSummaryNotifier extends StateNotifier<AsyncValue<DepositSummary>> {
  DepositSummaryNotifier() : super(const AsyncValue.loading()) {
    loadSummary();
  }

  Future<void> loadSummary() async {
    try {
      state = const AsyncValue.loading();
      final response = await http.get(
        Uri.parse('${KVM_URL}/reception/getDepositSummaryDashboard'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final summary = DepositSummary.fromJson(jsonData);
        state = AsyncValue.data(summary);
      } else {
        state = AsyncValue.error('Failed to load summary', StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refreshSummary() async {
    await loadSummary();
  }
}

// Utility Methods Class

// Main Screen Widget
class DepositsTrackingScreen extends ConsumerStatefulWidget {
  const DepositsTrackingScreen({super.key});

  @override
  ConsumerState<DepositsTrackingScreen> createState() =>
      _DepositsTrackingScreenState();
}

class _DepositsTrackingScreenState
    extends ConsumerState<DepositsTrackingScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(searchQueryProvider.notifier).state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HospitalTheme.buildAppBar(
        context: context,
        title: 'Deposits Management',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(depositsProvider.notifier).refreshDeposits();
              ref.read(depositSummaryProvider.notifier).refreshSummary();
            },
            tooltip: 'Refresh Data',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if ((HardwareKeyboard.instance.isControlPressed ||
                    HardwareKeyboard.instance.isMetaPressed) &&
                event.logicalKey == LogicalKeyboardKey.keyF) {
              FocusScope.of(context).requestFocus(FocusNode());
              _searchController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _searchController.text.length,
              );
            }
          }
        },
        child: Consumer(
          builder: (context, ref, child) {
            final selectedDeposit = ref.watch(selectedDepositProvider);

            if (selectedDeposit == null) {
              // Show full width table when no deposit is selected
              return _buildFullWidthView();
            } else {
              // Show master-detail layout when deposit is selected
              return Row(
                children: [
                  // Master Panel (Table)
                  Expanded(
                    flex: 6,
                    child: _buildMasterPanel(),
                  ),

                  // Detail Panel
                  Expanded(
                    flex: 4,
                    child: _buildDetailPanel(),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildFullWidthView() {
    return Container(
      color: HospitalTheme.background,
      child: Column(
        children: [
          // Summary Cards
          _buildSummarySection(),

          // Filters and Search
          _buildFiltersSection(),

          // Deposits Table (Full Width)
          Expanded(
            child: _buildDepositsTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterPanel() {
    return Container(
      color: HospitalTheme.background,
      child: Column(
        children: [
          // Summary Cards (Compact)
          _buildCompactSummarySection(),

          // Filters and Search
          _buildCompactFiltersSection(),

          // Deposits Table
          Expanded(
            child: _buildDepositsTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Consumer(
      builder: (context, ref, child) {
        final summaryAsync = ref.watch(depositSummaryProvider);

        return summaryAsync.when(
          data: (summary) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    Expanded(
                      child: HospitalTheme.buildStatCard(
                        title: 'Total Receipts',
                        value: summary.totalReceipts.toString(),
                        icon: Icons.receipt_long,
                        iconColor: HospitalTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: HospitalTheme.buildStatCard(
                        title: 'Total Amount',
                        value:
                            '₹${NumberFormat('#,##,##0.00').format(summary.totalAmount)}',
                        icon: Icons.account_balance_wallet,
                        iconColor: HospitalTheme.success,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: HospitalTheme.buildStatCard(
                        title: 'Average Amount',
                        value:
                            '₹${NumberFormat('#,##,##0.00').format(summary.avgAmount)}',
                        icon: Icons.trending_up,
                        iconColor: HospitalTheme.info,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: HospitalTheme.buildStatCard(
                        title: 'Payment Methods',
                        value: summary.paymentMethodStats.length.toString(),
                        icon: Icons.payment,
                        iconColor: HospitalTheme.secondary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error loading summary: $error'),
          ),
        );
      },
    );
  }

  Widget _buildCompactSummarySection() {
    return Consumer(
      builder: (context, ref, child) {
        final summaryAsync = ref.watch(depositSummaryProvider);

        return summaryAsync.when(
          data: (summary) => Container(
            padding: const EdgeInsets.all(12.0),
            color: HospitalTheme.surfaceLight,
            child: Row(
              children: [
                _buildCompactStatItem(
                  'Total: ${summary.totalReceipts}',
                  Icons.receipt_long,
                  HospitalTheme.primary,
                ),
                const SizedBox(width: 16),
                _buildCompactStatItem(
                  '₹${NumberFormat('#,##,##0').format(summary.totalAmount)}',
                  Icons.account_balance_wallet,
                  HospitalTheme.success,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.fullscreen_exit),
                  onPressed: () {
                    ref.read(selectedDepositProvider.notifier).state = null;
                  },
                  tooltip: 'Exit Detail View',
                ),
              ],
            ),
          ),
          loading: () => Container(
            padding: const EdgeInsets.all(12.0),
            color: HospitalTheme.surfaceLight,
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Container(
            padding: const EdgeInsets.all(12.0),
            color: HospitalTheme.surfaceLight,
            child: Text('Error: $error'),
          ),
        );
      },
    );
  }

  Widget _buildCompactStatItem(String text, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // Search Field
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by patient name, ID, or receipt ID (Ctrl+F)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Payment Method Filter
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final selectedMethod =
                    ref.watch(selectedPaymentMethodFilterProvider);
                return DropdownButtonFormField<String>(
                  value: selectedMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    prefixIcon: Icon(Icons.payment),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All Methods')),
                    const DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                    const DropdownMenuItem(value: 'Card', child: Text('Card')),
                    const DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                    const DropdownMenuItem(
                        value: 'Cheque', child: Text('Cheque')),
                    const DropdownMenuItem(
                        value: 'Bank Transfer', child: Text('Bank Transfer')),
                  ],
                  onChanged: (value) {
                    ref
                        .read(selectedPaymentMethodFilterProvider.notifier)
                        .state = value;
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 16),

          // Date Range Filter
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final dateRange = ref.watch(selectedDateRangeProvider);
                return InkWell(
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                      initialDateRange: dateRange,
                    );
                    if (picked != null) {
                      ref.read(selectedDateRangeProvider.notifier).state =
                          picked;
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date Range',
                      prefixIcon: Icon(Icons.date_range),
                    ),
                    child: Text(
                      dateRange != null
                          ? '${DateFormat('MMM dd').format(dateRange.start)} - ${DateFormat('MMM dd').format(dateRange.end)}'
                          : 'Select date range',
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),

          // Clear Filters Button
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              ref.read(selectedPaymentMethodFilterProvider.notifier).state =
                  null;
              ref.read(selectedDateRangeProvider.notifier).state = null;
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFiltersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          // Search Field (Compact)
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(Icons.search, size: 18),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Payment Method Filter (Compact)
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final selectedMethod =
                    ref.watch(selectedPaymentMethodFilterProvider);
                return SizedBox(
                  height: 40,
                  child: DropdownButtonFormField<String>(
                    value: selectedMethod,
                    decoration: const InputDecoration(
                      labelText: 'Payment',
                      prefixIcon: Icon(Icons.payment, size: 18),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      const DropdownMenuItem(
                          value: 'Cash', child: Text('Cash')),
                      const DropdownMenuItem(
                          value: 'Card', child: Text('Card')),
                      const DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                    ],
                    onChanged: (value) {
                      ref
                          .read(selectedPaymentMethodFilterProvider.notifier)
                          .state = value;
                    },
                  ),
                );
              },
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
        final selectedPaymentMethod =
            ref.watch(selectedPaymentMethodFilterProvider);
        final selectedDateRange = ref.watch(selectedDateRangeProvider);

        return depositsAsync.when(
          data: (deposits) {
            // Apply filters
            var filteredDeposits = deposits.where((deposit) {
              final matchesSearch = searchQuery.isEmpty ||
                  deposit.patientDetails.name
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()) ||
                  deposit.patientId
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()) ||
                  deposit.receiptId
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase());

              final matchesPaymentMethod = selectedPaymentMethod == null ||
                  deposit.depositDetails.paymentMethod == selectedPaymentMethod;

              final matchesDateRange = selectedDateRange == null ||
                  (deposit.receiptDetails.generatedAt
                          .isAfter(selectedDateRange.start) &&
                      deposit.receiptDetails.generatedAt.isBefore(
                          selectedDateRange.end.add(const Duration(days: 1))));

              return matchesSearch && matchesPaymentMethod && matchesDateRange;
            }).toList();

            if (filteredDeposits.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No deposits found matching your criteria'),
                  ],
                ),
              );
            }

            return _buildDataTable(filteredDeposits);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading deposits: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(depositsProvider.notifier).refreshDeposits(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataTable(List<DepositRecord> deposits) {
    final selectedDeposit = ref.watch(selectedDepositProvider);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: HospitalTheme.radiusMedium,
        border: Border.all(color: HospitalTheme.border),
        boxShadow: HospitalTheme.shadowSmall,
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Deposits (${deposits.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (selectedDeposit != null)
                  TextButton.icon(
                    onPressed: () {
                      ref.read(selectedDepositProvider.notifier).state = null;
                    },
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Close Details'),
                    style: TextButton.styleFrom(
                      foregroundColor: HospitalTheme.primary,
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {
                    // Export functionality
                  },
                  tooltip: 'Export to Excel',
                ),
              ],
            ),
          ),

          // Table Content
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingRowColor:
                        MaterialStateProperty.all(HospitalTheme.surfaceLight),
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 80,
                    columns: const [
                      DataColumn(
                          label: Text('Receipt ID',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Patient',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Amount',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Payment Method',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Doctor',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Section',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Date',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Status',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Actions',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: deposits
                        .map((deposit) => _buildDataRow(deposit))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(DepositRecord deposit) {
    final selectedDeposit = ref.watch(selectedDepositProvider);
    final isSelected = selectedDeposit?.id == deposit.id;

    return DataRow(
      selected: isSelected,
      color: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return HospitalTheme.primary.withOpacity(0.1);
        }
        return null;
      }),
      onSelectChanged: (selected) {
        if (selected == true) {
          ref.read(selectedDepositProvider.notifier).state = deposit;
        } else {
          ref.read(selectedDepositProvider.notifier).state = null;
        }
      },
      cells: [
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? HospitalTheme.primary.withOpacity(0.2)
                  : HospitalTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              deposit.receiptId,
              style: TextStyle(
                fontFamily: 'monospace',
                color: HospitalTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                deposit.patientDetails.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'ID: ${deposit.patientId}',
                style: TextStyle(
                  fontSize: 12,
                  color: HospitalTheme.textMedium,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Text(
            '₹${NumberFormat('#,##,##0.00').format(deposit.depositDetails.depositAmount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: HospitalTheme.success,
              fontSize: 16,
            ),
          ),
        ),
        DataCell(
          HospitalTheme.buildStatusBadge(
            deposit.depositDetails.paymentMethod,
            color: _getPaymentMethodColor(deposit.depositDetails.paymentMethod),
          ),
        ),
        DataCell(
          Text(
            'Dr. ${deposit.admissionDetails.doctorName}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(
          Text(deposit.admissionDetails.sectionName),
        ),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('MMM dd, yyyy')
                    .format(deposit.receiptDetails.generatedAt),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                DateFormat('hh:mm a')
                    .format(deposit.receiptDetails.generatedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: HospitalTheme.textMedium,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          HospitalTheme.buildStatusBadge(
            deposit.receiptDetails.isActive ? 'Active' : 'Inactive',
            color: deposit.receiptDetails.isActive
                ? HospitalTheme.success
                : HospitalTheme.error,
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isSelected ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                ),
                onPressed: () {
                  if (isSelected) {
                    ref.read(selectedDepositProvider.notifier).state = null;
                  } else {
                    ref.read(selectedDepositProvider.notifier).state = deposit;
                  }
                },
                tooltip: isSelected ? 'Hide Details' : 'View Details',
                color: HospitalTheme.primary,
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                onPressed: () {
                  Methods().openPdf(deposit.receiptDetails.receiptUrl);
                },
                tooltip: 'View Receipt',
                color: HospitalTheme.error,
              ),
              IconButton(
                icon: const Icon(Icons.print, size: 18),
                onPressed: () {
                  _printReceipt(deposit);
                },
                tooltip: 'Print Receipt',
                color: HospitalTheme.info,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getPaymentMethodColor(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'cash':
        return HospitalTheme.success;
      case 'card':
        return HospitalTheme.primary;
      case 'upi':
        return HospitalTheme.secondary;
      case 'cheque':
        return HospitalTheme.warning;
      case 'bank transfer':
        return HospitalTheme.info;
      default:
        return HospitalTheme.textMedium;
    }
  }

  Widget _buildDetailPanel() {
    return Consumer(
      builder: (context, ref, child) {
        final selectedDeposit = ref.watch(selectedDepositProvider);

        if (selectedDeposit == null) {
          return Container(
            color: Colors.white,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Select a deposit to view details',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: HospitalTheme.border, width: 1),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: HospitalTheme.primary,
                  boxShadow: HospitalTheme.shadowSmall,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Deposit Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            selectedDeposit.receiptId,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        ref.read(selectedDepositProvider.notifier).state = null;
                      },
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient Information
                      _buildDetailSection(
                        'Patient Information',
                        Icons.person,
                        [
                          _buildDetailRow(
                              'Name', selectedDeposit.patientDetails.name),
                          _buildDetailRow(
                              'Patient ID', selectedDeposit.patientId),
                          _buildDetailRow('Age',
                              '${selectedDeposit.patientDetails.age} years'),
                          _buildDetailRow(
                              'Gender', selectedDeposit.patientDetails.gender),
                          _buildDetailRow('Contact',
                              selectedDeposit.patientDetails.contact),
                          _buildDetailRow('Address',
                              selectedDeposit.patientDetails.address),
                          _buildDetailRow('Patient Type',
                              selectedDeposit.patientDetails.patientType),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Admission Information
                      _buildDetailSection(
                        'Admission Information',
                        Icons.local_hospital,
                        [
                          _buildDetailRow('Doctor',
                              'Dr. ${selectedDeposit.admissionDetails.doctorName}'),
                          _buildDetailRow('Section',
                              selectedDeposit.admissionDetails.sectionName),
                          _buildDetailRow(
                              'Admission Date',
                              DateFormat('MMM dd, yyyy hh:mm a').format(
                                  selectedDeposit
                                      .admissionDetails.admissionDate)),
                          if (selectedDeposit.admissionDetails.bedNumber !=
                              null)
                            _buildDetailRow(
                                'Bed Number',
                                selectedDeposit.admissionDetails.bedNumber
                                    .toString()),
                          if (selectedDeposit
                                  .admissionDetails.reasonForAdmission !=
                              null)
                            _buildDetailRow(
                                'Reason',
                                selectedDeposit
                                    .admissionDetails.reasonForAdmission!),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Deposit Information
                      _buildDetailSection(
                        'Deposit Information',
                        Icons.account_balance_wallet,
                        [
                          _buildDetailRow(
                            'Amount',
                            '₹${NumberFormat('#,##,##0.00').format(selectedDeposit.depositDetails.depositAmount)}',
                            valueColor: HospitalTheme.success,
                            isHighlighted: true,
                          ),
                          _buildDetailRow('Payment Method',
                              selectedDeposit.depositDetails.paymentMethod),
                          if (selectedDeposit.depositDetails.transactionId !=
                              null)
                            _buildDetailRow('Transaction ID',
                                selectedDeposit.depositDetails.transactionId!),
                          if (selectedDeposit.depositDetails.chequeNumber !=
                              null)
                            _buildDetailRow('Cheque Number',
                                selectedDeposit.depositDetails.chequeNumber!),
                          if (selectedDeposit.depositDetails.bankName != null)
                            _buildDetailRow('Bank Name',
                                selectedDeposit.depositDetails.bankName!),
                          if (selectedDeposit.depositDetails.remarks.isNotEmpty)
                            _buildDetailRow('Remarks',
                                selectedDeposit.depositDetails.remarks),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Receipt Information
                      _buildDetailSection(
                        'Receipt Information',
                        Icons.receipt,
                        [
                          _buildDetailRow(
                              'Generated By',
                              selectedDeposit
                                  .receiptDetails.generatedBy.userName),
                          _buildDetailRow(
                              'User Type',
                              selectedDeposit
                                  .receiptDetails.generatedBy.userType),
                          _buildDetailRow(
                              'Generated At',
                              DateFormat('MMM dd, yyyy hh:mm a').format(
                                  selectedDeposit.receiptDetails.generatedAt)),
                          _buildDetailRow(
                              'Status',
                              selectedDeposit.receiptDetails.isActive
                                  ? 'Active'
                                  : 'Inactive'),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Hospital Information
                      _buildDetailSection(
                        'Hospital Information',
                        Icons.local_hospital,
                        [
                          _buildDetailRow('Hospital Name',
                              selectedDeposit.hospitalDetails.hospitalName),
                          _buildDetailRow('Address',
                              selectedDeposit.hospitalDetails.hospitalAddress),
                          _buildDetailRow('Contact',
                              selectedDeposit.hospitalDetails.hospitalContact),
                          _buildDetailRow('Email',
                              selectedDeposit.hospitalDetails.hospitalEmail),
                          _buildDetailRow(
                              'Registration',
                              selectedDeposit
                                  .hospitalDetails.registrationNumber),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Methods().openPdf(
                                    selectedDeposit.receiptDetails.receiptUrl);
                              },
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('View Receipt'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: HospitalTheme.error,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _printReceipt(selectedDeposit);
                              },
                              icon: const Icon(Icons.print),
                              label: const Text('Print'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _shareReceipt(selectedDeposit);
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Share Receipt'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(
      String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: HospitalTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: HospitalTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HospitalTheme.surfaceLight,
            borderRadius: HospitalTheme.radiusMedium,
            border: Border.all(color: HospitalTheme.border),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: HospitalTheme.textMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: isHighlighted
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
                  : EdgeInsets.zero,
              decoration: isHighlighted
                  ? BoxDecoration(
                      color: (valueColor ?? HospitalTheme.success)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    )
                  : null,
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor ?? HospitalTheme.textDark,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                  fontSize: isHighlighted ? 16 : 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _printReceipt(DepositRecord deposit) {
    // Implementation for printing receipt
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Print Receipt'),
        content: Text('Printing receipt for ${deposit.receiptId}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _shareReceipt(DepositRecord deposit) {
    // Implementation for sharing receipt
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Receipt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              onTap: () {
                Navigator.pop(context);
                // Email implementation
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('SMS'),
              onTap: () {
                Navigator.pop(context);
                // SMS implementation
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('WhatsApp'),
              onTap: () {
                Navigator.pop(context);
                // WhatsApp implementation
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
