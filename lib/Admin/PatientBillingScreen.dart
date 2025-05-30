import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Models
class PatientBillingData {
  final String patientId;
  final String name;
  final String contact;
  final int age;
  final String gender;
  final double currentPendingAmount;
  final double previousRemainingAmount;
  final double totalOutstanding;
  final bool isCurrentlyAdmitted;
  final int totalAdmissions;
  final double totalHistoricalAmount;
  final double totalBillingAmount;
  final double currentAdmissionAmount;
  final bool hasOutstandingBalance;
  final int totalBillingRecords;

  const PatientBillingData({
    required this.patientId,
    required this.name,
    required this.contact,
    required this.age,
    required this.gender,
    required this.currentPendingAmount,
    required this.previousRemainingAmount,
    required this.totalOutstanding,
    required this.isCurrentlyAdmitted,
    required this.totalAdmissions,
    required this.totalHistoricalAmount,
    required this.totalBillingAmount,
    required this.currentAdmissionAmount,
    required this.hasOutstandingBalance,
    required this.totalBillingRecords,
  });

  factory PatientBillingData.fromJson(Map<String, dynamic> json) {
    return PatientBillingData(
      patientId: json['patientId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Patient',
      contact: json['contact']?.toString() ?? '',
      age: int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      gender: json['gender']?.toString() ?? 'Unknown',
      currentPendingAmount:
          double.tryParse(json['currentPendingAmount']?.toString() ?? '0') ??
              0.0,
      previousRemainingAmount:
          double.tryParse(json['previousRemainingAmount']?.toString() ?? '0') ??
              0.0,
      totalOutstanding:
          double.tryParse(json['totalOutstanding']?.toString() ?? '0') ?? 0.0,
      isCurrentlyAdmitted: json['isCurrentlyAdmitted'] ?? false,
      totalAdmissions:
          int.tryParse(json['totalAdmissions']?.toString() ?? '0') ?? 0,
      totalHistoricalAmount:
          double.tryParse(json['totalHistoricalAmount']?.toString() ?? '0') ??
              0.0,
      totalBillingAmount:
          double.tryParse(json['totalBillingAmount']?.toString() ?? '0') ?? 0.0,
      currentAdmissionAmount:
          double.tryParse(json['currentAdmissionAmount']?.toString() ?? '0') ??
              0.0,
      hasOutstandingBalance: json['hasOutstandingBalance'] ?? false,
      totalBillingRecords:
          int.tryParse(json['totalBillingRecords']?.toString() ?? '0') ?? 0,
    );
  }
}

class BillingSummary {
  final int totalPatients;
  final int patientsWithOutstandingBalance;
  final int currentlyAdmittedPatients;
  final double totalOutstandingAmount;
  final double totalHistoricalAmount;
  final double totalBillingAmount;

  const BillingSummary({
    required this.totalPatients,
    required this.patientsWithOutstandingBalance,
    required this.currentlyAdmittedPatients,
    required this.totalOutstandingAmount,
    required this.totalHistoricalAmount,
    required this.totalBillingAmount,
  });

  factory BillingSummary.fromJson(Map<String, dynamic> json) {
    return BillingSummary(
      totalPatients:
          int.tryParse(json['totalPatients']?.toString() ?? '0') ?? 0,
      patientsWithOutstandingBalance: int.tryParse(
              json['patientsWithOutstandingBalance']?.toString() ?? '0') ??
          0,
      currentlyAdmittedPatients:
          int.tryParse(json['currentlyAdmittedPatients']?.toString() ?? '0') ??
              0,
      totalOutstandingAmount:
          double.tryParse(json['totalOutstandingAmount']?.toString() ?? '0') ??
              0.0,
      totalHistoricalAmount:
          double.tryParse(json['totalHistoricalAmount']?.toString() ?? '0') ??
              0.0,
      totalBillingAmount:
          double.tryParse(json['totalBillingAmount']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class BillingResponse {
  final String message;
  final BillingSummary summary;
  final List<PatientBillingData> data;

  const BillingResponse({
    required this.message,
    required this.summary,
    required this.data,
  });

  factory BillingResponse.fromJson(Map<String, dynamic> json) {
    return BillingResponse(
      message: json['message']?.toString() ?? '',
      summary: BillingSummary.fromJson(json['summary'] ?? {}),
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => PatientBillingData.fromJson(item))
              .toList() ??
          [],
    );
  }
}

// Providers
final billingDataProvider = FutureProvider<BillingResponse>((ref) async {
  try {
    final response = await http.get(
      Uri.parse('$KVM_URL/reception/getAllPatientAmountDetailsWithBilling'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      return BillingResponse.fromJson(jsonData);
    } else {
      throw Exception('Failed to load billing data: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Network error: $e');
  }
});

final selectedPatientProvider =
    StateProvider<PatientBillingData?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');
final sortOptionProvider = StateProvider<String>((ref) => 'name');

// Main Screen
class PatientBillingScreen extends ConsumerStatefulWidget {
  const PatientBillingScreen({super.key});

  @override
  ConsumerState<PatientBillingScreen> createState() =>
      _PatientBillingScreenState();
}

class _PatientBillingScreenState extends ConsumerState<PatientBillingScreen> {
  final ScrollController _masterScrollController = ScrollController();
  final ScrollController _detailScrollController = ScrollController();
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
    _masterScrollController.dispose();
    _detailScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width > 1200;

    return Scaffold(
      backgroundColor: HospitalTheme.background,
      appBar: HospitalTheme.buildAppBar(
        context: context,
        title: 'Patient Billing Management',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(billingDataProvider),
            tooltip: 'Refresh Data (Ctrl+R)',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _exportBillingReport,
            tooltip: 'Export Report (Ctrl+P)',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: _handleKeyPress,
        child: isLargeScreen
            ? _buildDesktopLayout(screenSize)
            : _buildMobileLayout(screenSize),
      ),
    );
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrlPressed = HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;

      if (isCtrlPressed) {
        switch (event.logicalKey) {
          case LogicalKeyboardKey.keyR:
            ref.invalidate(billingDataProvider);
            break;
          case LogicalKeyboardKey.keyP:
            _exportBillingReport();
            break;
          case LogicalKeyboardKey.keyF:
            _focusSearch();
            break;
        }
      }
    }
  }

  void _focusSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
  }

  void _exportBillingReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Billing report export functionality would be implemented here'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildDesktopLayout(Size screenSize) {
    return Row(
      children: [
        // Master Panel (Patient List)
        SizedBox(
          width: screenSize.width * 0.35,
          child: _buildMasterPanel(),
        ),
        // Divider
        Container(
          width: 1,
          color: HospitalTheme.border,
        ),
        // Detail Panel
        Expanded(
          child: _buildDetailPanel(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(Size screenSize) {
    return const Center(
      child:
          Text('Mobile layout not implemented for this complex billing screen'),
    );
  }

  Widget _buildMasterPanel() {
    return Column(
      children: [
        // Summary Cards
        _buildSummarySection(),
        const SizedBox(height: 16),
        // Search and Filter Bar
        _buildSearchAndFilterBar(),
        const SizedBox(height: 16),
        // Patient List
        Expanded(
          child: _buildPatientList(),
        ),
      ],
    );
  }

  Widget _buildSummarySection() {
    final billingData = ref.watch(billingDataProvider);

    return billingData.when(
      data: (data) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: HospitalTheme.buildStatCard(
                    title: 'Total Patients',
                    value: data.summary.totalPatients.toString(),
                    icon: Icons.people,
                    iconColor: HospitalTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HospitalTheme.buildStatCard(
                    title: 'Outstanding',
                    value:
                        data.summary.patientsWithOutstandingBalance.toString(),
                    icon: Icons.warning,
                    iconColor: HospitalTheme.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: HospitalTheme.buildStatCard(
                    title: 'Total Outstanding',
                    value:
                        '₹${data.summary.totalOutstandingAmount.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet,
                    iconColor: HospitalTheme.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HospitalTheme.buildStatCard(
                    title: 'Total Billing',
                    value:
                        '₹${data.summary.totalBillingAmount.toStringAsFixed(0)}',
                    icon: Icons.receipt_long,
                    iconColor: HospitalTheme.success,
                  ),
                ),
              ],
            ),
          ],
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
  }

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search patients... (Ctrl+F)',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Sort by: '),
              Expanded(
                child: DropdownButton<String>(
                  value: ref.watch(sortOptionProvider),
                  isExpanded: true,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(sortOptionProvider.notifier).state = value;
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                    DropdownMenuItem(
                        value: 'outstanding',
                        child: Text('Outstanding Amount')),
                    DropdownMenuItem(
                        value: 'billing', child: Text('Total Billing')),
                    DropdownMenuItem(
                        value: 'admissions', child: Text('Admissions')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientList() {
    final billingData = ref.watch(billingDataProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final sortOption = ref.watch(sortOptionProvider);
    final selectedPatient = ref.watch(selectedPatientProvider);

    return billingData.when(
      data: (data) {
        var filteredPatients = data.data;

        // Apply search filter
        if (searchQuery.isNotEmpty) {
          filteredPatients = filteredPatients.where((patient) {
            return patient.name
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()) ||
                patient.patientId
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()) ||
                patient.contact.contains(searchQuery);
          }).toList();
        }

        // Apply sorting
        filteredPatients.sort((a, b) {
          switch (sortOption) {
            case 'outstanding':
              return b.totalOutstanding.compareTo(a.totalOutstanding);
            case 'billing':
              return b.totalBillingAmount.compareTo(a.totalBillingAmount);
            case 'admissions':
              return b.totalAdmissions.compareTo(a.totalAdmissions);
            case 'name':
            default:
              return a.name.compareTo(b.name);
          }
        });

        return ListView.builder(
          controller: _masterScrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredPatients.length,
          itemBuilder: (context, index) {
            final patient = filteredPatients[index];
            final isSelected = selectedPatient?.patientId == patient.patientId;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: HospitalTheme.buildCard(
                backgroundColor: isSelected ? HospitalTheme.surfaceLight : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: patient.hasOutstandingBalance
                        ? HospitalTheme.error.withOpacity(0.1)
                        : HospitalTheme.success.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      color: patient.hasOutstandingBalance
                          ? HospitalTheme.error
                          : HospitalTheme.success,
                    ),
                  ),
                  title: Text(
                    patient.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: ${patient.patientId}'),
                      Text('Contact: ${patient.contact}'),
                      if (patient.hasOutstandingBalance)
                        Text(
                          'Outstanding: ₹${patient.totalOutstanding.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: HospitalTheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${patient.totalBillingAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${patient.totalAdmissions} admissions',
                        style: TextStyle(
                          color: HospitalTheme.textMedium,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    ref.read(selectedPatientProvider.notifier).state = patient;
                  },
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(billingDataProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailPanel() {
    final selectedPatient = ref.watch(selectedPatientProvider);
    final billingData = ref.watch(billingDataProvider);

    if (selectedPatient == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Select a patient to view billing details',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: _detailScrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPatientHeader(selectedPatient),
          const SizedBox(height: 24),
          _buildBillingOverview(selectedPatient),
          const SizedBox(height: 24),
          _buildBillingCharts(selectedPatient, billingData),
          const SizedBox(height: 24),
          _buildActionButtons(selectedPatient),
        ],
      ),
    );
  }

  Widget _buildPatientHeader(PatientBillingData patient) {
    return HospitalTheme.buildCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: HospitalTheme.primary.withOpacity(0.1),
            child: Icon(
              Icons.person,
              size: 40,
              color: HospitalTheme.primary,
            ),
          ),
          const SizedBox(width: 20),
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
                const SizedBox(height: 8),
                Text(
                  'Patient ID: ${patient.patientId}',
                  style: TextStyle(
                    fontSize: 16,
                    color: HospitalTheme.textMedium,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone,
                        size: 16, color: HospitalTheme.textMedium),
                    const SizedBox(width: 8),
                    Text(patient.contact),
                    const SizedBox(width: 24),
                    Icon(Icons.cake, size: 16, color: HospitalTheme.textMedium),
                    const SizedBox(width: 8),
                    Text('${patient.age} years'),
                    const SizedBox(width: 24),
                    Icon(
                      patient.gender.toLowerCase() == 'male'
                          ? Icons.male
                          : Icons.female,
                      size: 16,
                      color: HospitalTheme.textMedium,
                    ),
                    const SizedBox(width: 8),
                    Text(patient.gender),
                  ],
                ),
              ],
            ),
          ),
          if (patient.hasOutstandingBalance)
            HospitalTheme.buildStatusBadge(
              'Outstanding Balance',
              color: HospitalTheme.error,
            ),
          if (patient.isCurrentlyAdmitted)
            HospitalTheme.buildStatusBadge(
              'Currently Admitted',
              color: HospitalTheme.warning,
            ),
        ],
      ),
    );
  }

  Widget _buildBillingOverview(PatientBillingData patient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Billing Overview',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: HospitalTheme.buildStatCard(
                title: 'Total Billing Amount',
                value: '₹${patient.totalBillingAmount.toStringAsFixed(0)}',
                icon: Icons.receipt_long,
                iconColor: HospitalTheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: HospitalTheme.buildStatCard(
                title: 'Outstanding Amount',
                value: '₹${patient.totalOutstanding.toStringAsFixed(0)}',
                icon: Icons.warning,
                iconColor: HospitalTheme.error,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: HospitalTheme.buildStatCard(
                title: 'Historical Amount',
                value: '₹${patient.totalHistoricalAmount.toStringAsFixed(0)}',
                icon: Icons.history,
                iconColor: HospitalTheme.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: HospitalTheme.buildStatCard(
                title: 'Total Admissions',
                value: patient.totalAdmissions.toString(),
                icon: Icons.local_hospital,
                iconColor: HospitalTheme.medical,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: HospitalTheme.buildStatCard(
                title: 'Billing Records',
                value: patient.totalBillingRecords.toString(),
                icon: Icons.description,
                iconColor: HospitalTheme.info,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: HospitalTheme.buildStatCard(
                title: 'Previous Remaining',
                value: '₹${patient.previousRemainingAmount.toStringAsFixed(0)}',
                icon: Icons.schedule,
                iconColor: HospitalTheme.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBillingCharts(
      PatientBillingData patient, AsyncValue<BillingResponse> billingData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Billing Analysis',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: HospitalTheme.buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Status',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: patient.totalHistoricalAmount,
                              title:
                                  'Paid\n₹${patient.totalHistoricalAmount.toStringAsFixed(0)}',
                              color: HospitalTheme.success,
                              radius: 80,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              value: patient.totalOutstanding,
                              title:
                                  'Outstanding\n₹${patient.totalOutstanding.toStringAsFixed(0)}',
                              color: HospitalTheme.error,
                              radius: 80,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: HospitalTheme.buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Comparative Analysis',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: billingData.when(
                        data: (data) {
                          final avgBilling = data.summary.totalBillingAmount /
                              data.summary.totalPatients;
                          final avgOutstanding =
                              data.summary.totalOutstandingAmount /
                                  data.summary.patientsWithOutstandingBalance;

                          return BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceEvenly,
                              maxY: [
                                    patient.totalBillingAmount,
                                    avgBilling,
                                    patient.totalOutstanding,
                                    avgOutstanding
                                  ].reduce((a, b) => a > b ? a : b) *
                                  1.2,
                              barGroups: [
                                BarChartGroupData(
                                  x: 0,
                                  barRods: [
                                    BarChartRodData(
                                      toY: patient.totalBillingAmount,
                                      color: HospitalTheme.primary,
                                      width: 20,
                                    ),
                                  ],
                                ),
                                BarChartGroupData(
                                  x: 1,
                                  barRods: [
                                    BarChartRodData(
                                      toY: avgBilling,
                                      color: HospitalTheme.primary
                                          .withOpacity(0.5),
                                      width: 20,
                                    ),
                                  ],
                                ),
                                BarChartGroupData(
                                  x: 2,
                                  barRods: [
                                    BarChartRodData(
                                      toY: patient.totalOutstanding,
                                      color: HospitalTheme.error,
                                      width: 20,
                                    ),
                                  ],
                                ),
                                BarChartGroupData(
                                  x: 3,
                                  barRods: [
                                    BarChartRodData(
                                      toY: avgOutstanding,
                                      color:
                                          HospitalTheme.error.withOpacity(0.5),
                                      width: 20,
                                    ),
                                  ],
                                ),
                              ],
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      switch (value.toInt()) {
                                        case 0:
                                          return const Text('Patient\nBilling',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: 10));
                                        case 1:
                                          return const Text('Avg\nBilling',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: 10));
                                        case 2:
                                          return const Text(
                                              'Patient\nOutstanding',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: 10));
                                        case 3:
                                          return const Text('Avg\nOutstanding',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: 10));
                                        default:
                                          return const Text('');
                                      }
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Text('₹${value.toInt()}',
                                          style: const TextStyle(fontSize: 10));
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: false),
                            ),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const Center(
                            child: Text('Error loading chart data')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(PatientBillingData patient) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              HospitalTheme.buildGradientButton(
                label: 'View Bills',
                icon: Icons.receipt_long,
                onPressed: () => _viewPatientBills(patient),
                startColor: HospitalTheme.primary,
                endColor: HospitalTheme.primaryLight,
              ),
              HospitalTheme.buildGradientButton(
                label: 'Payment History',
                icon: Icons.history,
                onPressed: () => _viewPaymentHistory(patient),
                startColor: HospitalTheme.success,
                endColor: HospitalTheme.success.withOpacity(0.8),
              ),
              HospitalTheme.buildGradientButton(
                label: 'Send Reminder',
                icon: Icons.notification_important,
                onPressed: patient.hasOutstandingBalance
                    ? () => _sendPaymentReminder(patient)
                    : () {}, // Provide an empty function instead of null
                startColor: patient.hasOutstandingBalance
                    ? HospitalTheme.warning
                    : Colors.grey,
                endColor: patient.hasOutstandingBalance
                    ? HospitalTheme.warning.withOpacity(0.8)
                    : Colors.grey.withOpacity(0.8),
              ),
              HospitalTheme.buildGradientButton(
                label: 'Generate Invoice',
                icon: Icons.description,
                onPressed: () => _generateInvoice(patient),
                startColor: HospitalTheme.info,
                endColor: HospitalTheme.info.withOpacity(0.8),
              ),
              HospitalTheme.buildGradientButton(
                label: 'Record Payment',
                icon: Icons.payment,
                onPressed: () => _recordPayment(patient),
                startColor: HospitalTheme.medical,
                endColor: HospitalTheme.medical.withOpacity(0.8),
              ),
              HospitalTheme.buildGradientButton(
                label: 'Patient Profile',
                icon: Icons.person,
                onPressed: () => _viewPatientProfile(patient),
                startColor: HospitalTheme.secondary,
                endColor: HospitalTheme.secondaryLight,
              ),
            ],
          ),
          if (patient.hasOutstandingBalance) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HospitalTheme.error.withOpacity(0.1),
                borderRadius: HospitalTheme.radiusSmall,
                border: Border.all(color: HospitalTheme.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: HospitalTheme.error,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Outstanding Balance Alert',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: HospitalTheme.error,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This patient has an outstanding balance of ₹${patient.totalOutstanding.toStringAsFixed(0)}. Consider sending a payment reminder.',
                          style: TextStyle(
                            color: HospitalTheme.textDark,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Action methods
  void _viewPatientBills(PatientBillingData patient) {
    _showActionDialog('View Bills', 'Viewing all bills for ${patient.name}');
  }

  void _viewPaymentHistory(PatientBillingData patient) {
    _showActionDialog(
        'Payment History', 'Viewing payment history for ${patient.name}');
  }

  void _sendPaymentReminder(PatientBillingData patient) {
    _showActionDialog('Send Payment Reminder',
        'Sending payment reminder to ${patient.name} for outstanding amount of ₹${patient.totalOutstanding.toStringAsFixed(0)}');
  }

  void _generateInvoice(PatientBillingData patient) {
    _showActionDialog(
        'Generate Invoice', 'Generating invoice for ${patient.name}');
  }

  void _recordPayment(PatientBillingData patient) {
    _showPaymentDialog(patient);
  }

  void _viewPatientProfile(PatientBillingData patient) {
    _showActionDialog('Patient Profile', 'Opening profile for ${patient.name}');
  }

  void _showActionDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(PatientBillingData patient) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Record Payment - ${patient.name}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Outstanding Amount: ₹${patient.totalOutstanding.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.error,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Payment Amount',
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Payment Notes (Optional)',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Here you would typically make an API call to record the payment
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Payment of ₹${amountController.text} recorded for ${patient.name}'),
                  backgroundColor: HospitalTheme.success,
                ),
              );
              // Refresh the data after recording payment
              ref.invalidate(billingDataProvider);
            },
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );
  }
}

// Additional helper widgets
class _ChartLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _ChartLegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $value',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

// Usage Example Widget (for testing)
class BillingManagementApp extends StatelessWidget {
  const BillingManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Hospital Billing Management',
        theme: HospitalTheme.themeData,
        home: const PatientBillingScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
