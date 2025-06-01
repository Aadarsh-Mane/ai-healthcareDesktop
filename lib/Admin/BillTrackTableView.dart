import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// API Configuration
class ApiConfig {
  static const String baseUrl = '${KVM_URL}';
  static const String getBillsEndpoint = '/reception/getAllBills';
}

// Table Configuration - Responsive
class TableConfig {
  static const double rowHeight = 60.0;
  static const double headerHeight = 56.0;
  static const double actionColumnWidth = 120.0;
  static const double minColumnWidth = 80.0;
  static const double maxColumnWidth = 200.0;
  static const double checkboxWidth = 50.0;
}

// Column Configuration with responsive widths
enum BillTableColumn {
  billNumber,
  billType,
  patientName,
  patientId,
  generatedDate,
  paymentStatus,
  status,
  grandTotal,
  dueAmount,
  actions,
}

extension BillTableColumnExt on BillTableColumn {
  String get label {
    switch (this) {
      case BillTableColumn.billNumber:
        return 'Bill Number';
      case BillTableColumn.billType:
        return 'Type';
      case BillTableColumn.patientName:
        return 'Patient Name';
      case BillTableColumn.patientId:
        return 'Patient ID';
      case BillTableColumn.generatedDate:
        return 'Generated Date';
      case BillTableColumn.paymentStatus:
        return 'Payment Status';
      case BillTableColumn.status:
        return 'Status';
      case BillTableColumn.grandTotal:
        return 'Grand Total';
      case BillTableColumn.dueAmount:
        return 'Due Amount';
      case BillTableColumn.actions:
        return 'Actions';
    }
  }

  // Responsive width calculation based on screen size
  double getWidth(double screenWidth) {
    final availableWidth = screenWidth - TableConfig.checkboxWidth;
    final flexUnit = availableWidth / _getTotalFlex();

    switch (this) {
      case BillTableColumn.billNumber:
        return (flexUnit * 2).clamp(100.0, 160.0);
      case BillTableColumn.billType:
        return (flexUnit * 1).clamp(70.0, 100.0);
      case BillTableColumn.patientName:
        return (flexUnit * 2.5).clamp(120.0, 200.0);
      case BillTableColumn.patientId:
        return (flexUnit * 1.5).clamp(90.0, 130.0);
      case BillTableColumn.generatedDate:
        return (flexUnit * 1.8).clamp(100.0, 140.0);
      case BillTableColumn.paymentStatus:
        return (flexUnit * 1.5).clamp(100.0, 130.0);
      case BillTableColumn.status:
        return (flexUnit * 1.2).clamp(80.0, 110.0);
      case BillTableColumn.grandTotal:
        return (flexUnit * 1.5).clamp(100.0, 130.0);
      case BillTableColumn.dueAmount:
        return (flexUnit * 1.5).clamp(100.0, 130.0);
      case BillTableColumn.actions:
        return TableConfig.actionColumnWidth;
    }
  }

  static double _getTotalFlex() => 14.5; // Sum of all flex values

  bool get sortable {
    switch (this) {
      case BillTableColumn.actions:
        return false;
      default:
        return true;
    }
  }
}

// Data Models
class BillsResponse {
  final bool success;
  final BillsData data;

  const BillsResponse({
    required this.success,
    required this.data,
  });

  factory BillsResponse.fromJson(Map<String, dynamic> json) {
    return BillsResponse(
      success: json['success'] ?? false,
      data: BillsData.fromJson(json['data'] ?? {}),
    );
  }
}

class BillsData {
  final List<Bill> bills;
  final Pagination pagination;

  const BillsData({
    required this.bills,
    required this.pagination,
  });

  factory BillsData.fromJson(Map<String, dynamic> json) {
    return BillsData(
      bills: (json['bills'] as List<dynamic>? ?? [])
          .map((bill) => Bill.fromJson(bill as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class Bill {
  final String id;
  final String billNumber;
  final int billNo;
  final String billType;
  final DateTime generatedAt;
  final String paymentStatus;
  final String status;
  final Patient patient;
  final Financials financials;
  final BillFiles? files;
  final List<Payment> payments;
  final bool emailSent;
  final bool smsSent;
  final int printCount;

  const Bill({
    required this.id,
    required this.billNumber,
    required this.billNo,
    required this.billType,
    required this.generatedAt,
    required this.paymentStatus,
    required this.status,
    required this.patient,
    required this.financials,
    this.files,
    required this.payments,
    required this.emailSent,
    required this.smsSent,
    required this.printCount,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['_id'] ?? '',
      billNumber: json['billNumber'] ?? '',
      billNo: json['billNo'] ?? 0,
      billType: json['billType'] ?? '',
      generatedAt:
          DateTime.tryParse(json['generatedAt'] ?? '') ?? DateTime.now(),
      paymentStatus: json['paymentStatus'] ?? 'Pending',
      status: json['status'] ?? 'Generated',
      patient: Patient.fromJson(json['patient'] ?? {}),
      financials: Financials.fromJson(json['financials'] ?? {}),
      files: json['files'] != null ? BillFiles.fromJson(json['files']) : null,
      payments: (json['payments'] as List<dynamic>? ?? [])
          .map((payment) => Payment.fromJson(payment as Map<String, dynamic>))
          .toList(),
      emailSent: json['emailSent'] ?? false,
      smsSent: json['smsSent'] ?? false,
      printCount: json['printCount'] ?? 0,
    );
  }
}

class Patient {
  final String name;
  final String patientId;
  final int age;
  final String gender;
  final String contact;
  final String address;

  const Patient({
    required this.name,
    required this.patientId,
    required this.age,
    required this.gender,
    required this.contact,
    required this.address,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      name: json['name'] ?? '',
      patientId: json['patientId'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      contact: json['contact'] ?? '',
      address: json['address'] ?? '',
    );
  }
}

class Financials {
  final double grandTotal;
  final double dueAmount;
  final double discountAmount;
  final double paidAmount;
  final double subTotal;
  final double advance;
  final double taxAmount;
  final double servicesTotal;
  final double consultationFee;
  final double doctorCharges;

  const Financials({
    required this.grandTotal,
    required this.dueAmount,
    required this.discountAmount,
    required this.paidAmount,
    required this.subTotal,
    required this.advance,
    required this.taxAmount,
    required this.servicesTotal,
    required this.consultationFee,
    required this.doctorCharges,
  });

  factory Financials.fromJson(Map<String, dynamic> json) {
    return Financials(
      grandTotal: (json['grandTotal'] ?? 0).toDouble(),
      dueAmount: (json['dueAmount'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      subTotal: (json['subTotal'] ?? 0).toDouble(),
      advance: (json['advance'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      servicesTotal: (json['servicesTotal'] ?? 0).toDouble(),
      consultationFee: (json['consultationFee'] ?? 0).toDouble(),
      doctorCharges: (json['doctorCharges'] ?? 0).toDouble(),
    );
  }
}

class BillFiles {
  final String pdfFileName;
  final String driveLink;
  final int pdfSize;
  final DateTime uploadedAt;

  const BillFiles({
    required this.pdfFileName,
    required this.driveLink,
    required this.pdfSize,
    required this.uploadedAt,
  });

  factory BillFiles.fromJson(Map<String, dynamic> json) {
    return BillFiles(
      pdfFileName: json['pdfFileName'] ?? '',
      driveLink: json['driveLink'] ?? '',
      pdfSize: json['pdfSize'] ?? 0,
      uploadedAt: DateTime.tryParse(json['uploadedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class Payment {
  final double amount;
  final String paymentMode;
  final DateTime paymentDate;
  final String notes;

  const Payment({
    required this.amount,
    required this.paymentMode,
    required this.paymentDate,
    required this.notes,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMode: json['paymentMode'] ?? '',
      paymentDate:
          DateTime.tryParse(json['paymentDate'] ?? '') ?? DateTime.now(),
      notes: json['notes'] ?? '',
    );
  }
}

class Pagination {
  final int total;
  final int page;
  final int limit;
  final int pages;

  const Pagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      pages: json['pages'] ?? 1,
    );
  }
}

// Filter Models
class BillFilters {
  final String? search;
  final String? billType;
  final String? paymentStatus;
  final String? status;
  final String? patientId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int page;
  final int limit;

  const BillFilters({
    this.search,
    this.billType,
    this.paymentStatus,
    this.status,
    this.patientId,
    this.startDate,
    this.endDate,
    this.page = 1,
    this.limit = 20,
  });

  BillFilters copyWith({
    String? search,
    String? billType,
    String? paymentStatus,
    String? status,
    String? patientId,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? limit,
  }) {
    return BillFilters(
      search: search ?? this.search,
      billType: billType ?? this.billType,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      patientId: patientId ?? this.patientId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final Map<String, dynamic> params = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search!.isNotEmpty) {
      params['search'] = search!;
    }
    if (billType != null && billType!.isNotEmpty) {
      params['billType'] = billType!;
    }
    if (paymentStatus != null && paymentStatus!.isNotEmpty) {
      params['paymentStatus'] = paymentStatus!;
    }
    if (status != null && status!.isNotEmpty) {
      params['status'] = status!;
    }
    if (patientId != null && patientId!.isNotEmpty) {
      params['patientId'] = patientId!;
    }
    if (startDate != null) {
      params['startDate'] = DateFormat('yyyy-MM-dd').format(startDate!);
    }
    if (endDate != null) {
      params['endDate'] = DateFormat('yyyy-MM-dd').format(endDate!);
    }

    return params;
  }
}

// Sort Configuration
class SortConfig {
  final BillTableColumn column;
  final bool ascending;

  const SortConfig({
    required this.column,
    this.ascending = true,
  });

  SortConfig copyWith({
    BillTableColumn? column,
    bool? ascending,
  }) {
    return SortConfig(
      column: column ?? this.column,
      ascending: ascending ?? this.ascending,
    );
  }
}

// API Service
class BillsApiService {
  static Future<BillsResponse> getAllBills(BillFilters filters) async {
    try {
      final queryParams = filters.toQueryParams();
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getBillsEndpoint}')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return BillsResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load bills: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching bills: $e');
    }
  }
}

// Providers
final sortConfigProvider = StateProvider<SortConfig?>((ref) => null);
final selectedRowsProvider = StateProvider<Set<String>>((ref) => {});
final tableFiltersProvider =
    StateProvider<BillFilters>((ref) => const BillFilters());

final billsProvider =
    FutureProvider.family<BillsData, BillFilters>((ref, filters) async {
  final response = await BillsApiService.getAllBills(filters);
  if (!response.success) {
    throw Exception('API returned failure status');
  }
  return response.data;
});

// Main Bills Table Screen
class BillsTableScreen extends ConsumerWidget {
  const BillsTableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: HospitalTheme.background,
      appBar: HospitalTheme.buildAppBar(
        context: context,
        title: 'Bills Management - Table View',
        showBackButton: false,
        actions: [
          IconButton(
            onPressed: () => _showColumnSettings(context, ref),
            icon: const Icon(Icons.view_column),
            tooltip: 'Column Settings',
          ),
          IconButton(
            onPressed: () => _exportData(ref),
            icon: const Icon(Icons.download),
            tooltip: 'Export Data',
          ),
          IconButton(
            onPressed: () => _refreshData(ref),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
              _showSearchDialog(context, ref),
          const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () =>
              _showSearchDialog(context, ref),
          const SingleActivator(LogicalKeyboardKey.keyA, control: true): () =>
              _selectAllRows(ref),
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              _clearSelection(ref),
          const SingleActivator(LogicalKeyboardKey.keyR, control: true): () =>
              _refreshData(ref),
        },
        child: Focus(
          autofocus: true,
          child: const Column(
            children: [
              BillsTableFilterBar(),
              BillsTableHeader(),
              Expanded(child: BillsTableBody()),
              BillsTableFooter(),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const BillSearchDialog(),
    );
  }

  void _showColumnSettings(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const ColumnSettingsDialog(),
    );
  }

  void _exportData(WidgetRef ref) {
    print('Exporting bills data...');
  }

  void _refreshData(WidgetRef ref) {
    final filters = ref.read(tableFiltersProvider);
    ref.refresh(billsProvider(filters));
    ref.read(selectedRowsProvider.notifier).state = {};
  }

  void _selectAllRows(WidgetRef ref) {
    final filters = ref.read(tableFiltersProvider);
    ref.read(billsProvider(filters)).whenData((data) {
      final allIds = data.bills.map((bill) => bill.id).toSet();
      ref.read(selectedRowsProvider.notifier).state = allIds;
    });
  }

  void _clearSelection(WidgetRef ref) {
    ref.read(selectedRowsProvider.notifier).state = {};
  }
}

// Table Filter Bar
class BillsTableFilterBar extends ConsumerWidget {
  const BillsTableFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(tableFiltersProvider);
    final selectedRows = ref.watch(selectedRowsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: HospitalTheme.border)),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 1200;

              if (isSmallScreen) {
                return _buildCompactFilterRow(context, ref, filters);
              } else {
                return _buildFullFilterRow(context, ref, filters);
              }
            },
          ),
          if (selectedRows.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSelectionBar(context, ref, selectedRows),
          ],
        ],
      ),
    );
  }

  Widget _buildFullFilterRow(
      BuildContext context, WidgetRef ref, BillFilters filters) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            onChanged: (value) {
              ref.read(tableFiltersProvider.notifier).state =
                  filters.copyWith(search: value, page: 1);
            },
            decoration: const InputDecoration(
              hintText: 'Search bills, patients, bill numbers...',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 140,
          child: DropdownButtonFormField<String>(
            value: filters.billType,
            decoration: const InputDecoration(
              labelText: 'Bill Type',
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('All Types')),
              DropdownMenuItem(value: 'IPD', child: Text('IPD')),
              DropdownMenuItem(value: 'OPD', child: Text('OPD')),
            ],
            onChanged: (value) {
              ref.read(tableFiltersProvider.notifier).state =
                  filters.copyWith(billType: value, page: 1);
            },
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<String>(
            value: filters.paymentStatus,
            decoration: const InputDecoration(
              labelText: 'Payment Status',
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('All Status')),
              DropdownMenuItem(value: 'Paid', child: Text('Paid')),
              DropdownMenuItem(value: 'Pending', child: Text('Pending')),
              DropdownMenuItem(value: 'Partial', child: Text('Partial')),
              DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
            ],
            onChanged: (value) {
              ref.read(tableFiltersProvider.notifier).state =
                  filters.copyWith(paymentStatus: value, page: 1);
            },
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: () => _showAdvancedFilters(context, ref),
          icon: Badge(
            isLabelVisible: _hasAdvancedFilters(filters),
            child: const Icon(Icons.filter_list),
          ),
          tooltip: 'More Filters',
        ),
        IconButton(
          onPressed: () => _clearAllFilters(ref),
          icon: const Icon(Icons.clear_all),
          tooltip: 'Clear All',
        ),
      ],
    );
  }

  Widget _buildCompactFilterRow(
      BuildContext context, WidgetRef ref, BillFilters filters) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (value) {
                  ref.read(tableFiltersProvider.notifier).state =
                      filters.copyWith(search: value, page: 1);
                },
                decoration: const InputDecoration(
                  hintText: 'Search bills...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _showAdvancedFilters(context, ref),
              icon: Badge(
                isLabelVisible: _hasAdvancedFilters(filters),
                child: const Icon(Icons.filter_list),
              ),
              tooltip: 'Filters',
            ),
            IconButton(
              onPressed: () => _clearAllFilters(ref),
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: filters.billType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'IPD', child: Text('IPD')),
                  DropdownMenuItem(value: 'OPD', child: Text('OPD')),
                ],
                onChanged: (value) {
                  ref.read(tableFiltersProvider.notifier).state =
                      filters.copyWith(billType: value, page: 1);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: filters.paymentStatus,
                decoration: const InputDecoration(
                  labelText: 'Payment',
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'Partial', child: Text('Partial')),
                ],
                onChanged: (value) {
                  ref.read(tableFiltersProvider.notifier).state =
                      filters.copyWith(paymentStatus: value, page: 1);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionBar(
      BuildContext context, WidgetRef ref, Set<String> selectedRows) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HospitalTheme.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HospitalTheme.info.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: HospitalTheme.info, size: 20),
          const SizedBox(width: 8),
          Text(
            '${selectedRows.length} bills selected',
            style: TextStyle(
              color: HospitalTheme.info,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _bulkActions(context, ref),
            icon: const Icon(Icons.more_horiz, size: 18),
            label: const Text('Actions'),
            style: TextButton.styleFrom(foregroundColor: HospitalTheme.info),
          ),
          TextButton.icon(
            onPressed: () => ref.read(selectedRowsProvider.notifier).state = {},
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Clear'),
            style: TextButton.styleFrom(foregroundColor: HospitalTheme.error),
          ),
        ],
      ),
    );
  }

  bool _hasAdvancedFilters(BillFilters filters) {
    return filters.status != null ||
        filters.startDate != null ||
        filters.endDate != null ||
        filters.patientId != null;
  }

  void _showAdvancedFilters(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const BillAdvancedFiltersDialog(),
    );
  }

  void _clearAllFilters(WidgetRef ref) {
    ref.read(tableFiltersProvider.notifier).state = const BillFilters();
  }

  void _bulkActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const BulkActionsSheet(),
    );
  }
}

// Responsive Table Header
class BillsTableHeader extends ConsumerWidget {
  const BillsTableHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortConfig = ref.watch(sortConfigProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: TableConfig.headerHeight,
      decoration: BoxDecoration(
        color: HospitalTheme.surfaceLight,
        border:
            Border(bottom: BorderSide(color: HospitalTheme.border, width: 2)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _calculateTotalWidth(screenWidth),
          child: Row(
            children: [
              // Select All Checkbox
              SizedBox(
                width: TableConfig.checkboxWidth,
                child: Checkbox(
                  value: _getSelectAllState(ref),
                  tristate: true,
                  onChanged: (value) => _toggleSelectAll(ref),
                ),
              ),
              // Column Headers
              ...BillTableColumn.values.map((column) => _buildColumnHeader(
                    context,
                    ref,
                    column,
                    sortConfig,
                    screenWidth,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColumnHeader(
    BuildContext context,
    WidgetRef ref,
    BillTableColumn column,
    SortConfig? sortConfig,
    double screenWidth,
  ) {
    final isActive = sortConfig?.column == column;
    final columnWidth = column.getWidth(screenWidth);

    return SizedBox(
      width: columnWidth,
      child: InkWell(
        onTap: column.sortable ? () => _onSort(ref, column, sortConfig) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  column.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (column.sortable) ...[
                const SizedBox(width: 4),
                Icon(
                  isActive
                      ? (sortConfig!.ascending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward)
                      : Icons.unfold_more,
                  size: 16,
                  color: isActive
                      ? HospitalTheme.primary
                      : HospitalTheme.textMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double _calculateTotalWidth(double screenWidth) {
    double totalWidth = TableConfig.checkboxWidth;
    for (var column in BillTableColumn.values) {
      totalWidth += column.getWidth(screenWidth);
    }
    return totalWidth;
  }

  bool? _getSelectAllState(WidgetRef ref) {
    final selectedRows = ref.watch(selectedRowsProvider);
    final filters = ref.read(tableFiltersProvider);

    return ref.watch(billsProvider(filters)).when(
          data: (data) {
            if (data.bills.isEmpty) return false;
            final allIds = data.bills.map((bill) => bill.id).toSet();
            final selectedCount = selectedRows.intersection(allIds).length;

            if (selectedCount == 0) return false;
            if (selectedCount == allIds.length) return true;
            return null; // Indeterminate
          },
          loading: () => false,
          error: (_, __) => false,
        );
  }

  void _toggleSelectAll(WidgetRef ref) {
    final selectedRows = ref.read(selectedRowsProvider);
    final filters = ref.read(tableFiltersProvider);

    ref.read(billsProvider(filters)).whenData((data) {
      final allIds = data.bills.map((bill) => bill.id).toSet();
      final hasAll = allIds.every((id) => selectedRows.contains(id));

      if (hasAll) {
        ref.read(selectedRowsProvider.notifier).state =
            selectedRows.difference(allIds);
      } else {
        ref.read(selectedRowsProvider.notifier).state =
            selectedRows.union(allIds);
      }
    });
  }

  void _onSort(WidgetRef ref, BillTableColumn column, SortConfig? currentSort) {
    final newSort = currentSort?.column == column
        ? currentSort!.copyWith(ascending: !currentSort.ascending)
        : SortConfig(column: column, ascending: true);

    ref.read(sortConfigProvider.notifier).state = newSort;
  }
}

// Responsive Table Body
class BillsTableBody extends ConsumerWidget {
  const BillsTableBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(tableFiltersProvider);
    final sortConfig = ref.watch(sortConfigProvider);
    final billsAsync = ref.watch(billsProvider(filters));

    return billsAsync.when(
      data: (data) => _buildTable(context, ref, data, sortConfig),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(context, ref, error),
    );
  }

  Widget _buildTable(
    BuildContext context,
    WidgetRef ref,
    BillsData data,
    SortConfig? sortConfig,
  ) {
    if (data.bills.isEmpty) {
      return _buildEmptyState();
    }

    var bills = data.bills;
    if (sortConfig != null) {
      bills = _sortBills(bills, sortConfig);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Column(
          children: bills.asMap().entries.map((entry) {
            final index = entry.key;
            final bill = entry.value;
            return BillTableRow(
              bill: bill,
              index: index,
              isEven: index % 2 == 0,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: HospitalTheme.error),
          const SizedBox(height: 16),
          Text(
            'Error loading bills',
            style: TextStyle(fontSize: 18, color: HospitalTheme.error),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(color: HospitalTheme.textMedium),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              final filters = ref.read(tableFiltersProvider);
              ref.refresh(billsProvider(filters));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No bills found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria or filters',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  List<Bill> _sortBills(List<Bill> bills, SortConfig sortConfig) {
    final sorted = List<Bill>.from(bills);

    sorted.sort((a, b) {
      int comparison = 0;

      switch (sortConfig.column) {
        case BillTableColumn.billNumber:
          comparison = a.billNumber.compareTo(b.billNumber);
          break;
        case BillTableColumn.billType:
          comparison = a.billType.compareTo(b.billType);
          break;
        case BillTableColumn.patientName:
          comparison = a.patient.name.compareTo(b.patient.name);
          break;
        case BillTableColumn.patientId:
          comparison = a.patient.patientId.compareTo(b.patient.patientId);
          break;
        case BillTableColumn.generatedDate:
          comparison = a.generatedAt.compareTo(b.generatedAt);
          break;
        case BillTableColumn.paymentStatus:
          comparison = a.paymentStatus.compareTo(b.paymentStatus);
          break;
        case BillTableColumn.status:
          comparison = a.status.compareTo(b.status);
          break;
        case BillTableColumn.grandTotal:
          comparison =
              a.financials.grandTotal.compareTo(b.financials.grandTotal);
          break;
        case BillTableColumn.dueAmount:
          comparison = a.financials.dueAmount.compareTo(b.financials.dueAmount);
          break;
        case BillTableColumn.actions:
          break;
      }

      return sortConfig.ascending ? comparison : -comparison;
    });

    return sorted;
  }
}

// Responsive Table Row
class BillTableRow extends ConsumerWidget {
  final Bill bill;
  final int index;
  final bool isEven;

  const BillTableRow({
    super.key,
    required this.bill,
    required this.index,
    required this.isEven,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRows = ref.watch(selectedRowsProvider);
    final isSelected = selectedRows.contains(bill.id);
    final screenWidth = MediaQuery.of(context).size.width;

    return InkWell(
      onTap: () => _showBillDetail(context),
      onLongPress: () => _toggleSelection(ref),
      child: Container(
        height: TableConfig.rowHeight,
        width: _calculateTotalWidth(screenWidth),
        decoration: BoxDecoration(
          color: isSelected
              ? HospitalTheme.primary.withOpacity(0.1)
              : isEven
                  ? Colors.white
                  : HospitalTheme.background,
          border: Border(
            bottom: BorderSide(color: HospitalTheme.border.withOpacity(0.5)),
          ),
        ),
        child: Row(
          children: [
            // Select Checkbox
            SizedBox(
              width: TableConfig.checkboxWidth,
              child: Checkbox(
                value: isSelected,
                onChanged: (value) => _toggleSelection(ref),
              ),
            ),
            // Data Columns
            _buildCell(BillTableColumn.billNumber, _buildBillNumberCell(),
                screenWidth),
            _buildCell(
                BillTableColumn.billType, _buildBillTypeCell(), screenWidth),
            _buildCell(BillTableColumn.patientName, _buildPatientNameCell(),
                screenWidth),
            _buildCell(
                BillTableColumn.patientId, _buildPatientIdCell(), screenWidth),
            _buildCell(BillTableColumn.generatedDate, _buildGeneratedDateCell(),
                screenWidth),
            _buildCell(BillTableColumn.paymentStatus, _buildPaymentStatusCell(),
                screenWidth),
            _buildCell(BillTableColumn.status, _buildStatusCell(), screenWidth),
            _buildCell(BillTableColumn.grandTotal, _buildGrandTotalCell(),
                screenWidth),
            _buildCell(
                BillTableColumn.dueAmount, _buildDueAmountCell(), screenWidth),
            _buildCell(BillTableColumn.actions, _buildActionsCell(context),
                screenWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(BillTableColumn column, Widget child, double screenWidth) {
    return SizedBox(
      width: column.getWidth(screenWidth),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: child,
      ),
    );
  }

  double _calculateTotalWidth(double screenWidth) {
    double totalWidth = TableConfig.checkboxWidth;
    for (var column in BillTableColumn.values) {
      totalWidth += column.getWidth(screenWidth);
    }
    return totalWidth;
  }

  Widget _buildBillNumberCell() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          bill.billNumber,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          'Bill #${bill.billNo}',
          style: TextStyle(
            color: HospitalTheme.textMedium,
            fontSize: 11,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildBillTypeCell() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: _getBillTypeColor(bill.billType).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: _getBillTypeColor(bill.billType).withOpacity(0.3)),
      ),
      child: Text(
        bill.billType,
        style: TextStyle(
          color: _getBillTypeColor(bill.billType),
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPatientNameCell() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          bill.patient.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Row(
          children: [
            Icon(
              bill.patient.gender.toLowerCase() == 'male'
                  ? Icons.male
                  : Icons.female,
              size: 11,
              color: HospitalTheme.textMedium,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${bill.patient.age}y, ${bill.patient.gender}',
                style: TextStyle(
                  color: HospitalTheme.textMedium,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPatientIdCell() {
    return Text(
      bill.patient.patientId,
      style: TextStyle(
        fontWeight: FontWeight.w500,
        color: HospitalTheme.primary,
        fontSize: 13,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildGeneratedDateCell() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          DateFormat('MMM dd, yyyy').format(bill.generatedAt),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          DateFormat('HH:mm').format(bill.generatedAt),
          style: TextStyle(
            color: HospitalTheme.textMedium,
            fontSize: 11,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPaymentStatusCell() {
    return HospitalTheme.buildStatusBadge(
      bill.paymentStatus,
      color: _getPaymentStatusColor(bill.paymentStatus),
    );
  }

  Widget _buildStatusCell() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: _getStatusColor(bill.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        bill.status,
        style: TextStyle(
          color: _getStatusColor(bill.status),
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildGrandTotalCell() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '₹${NumberFormat('#,##,###').format(bill.financials.grandTotal)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (bill.financials.discountAmount > 0)
          Text(
            'Disc: ₹${NumberFormat('#,###').format(bill.financials.discountAmount)}',
            style: TextStyle(
              color: HospitalTheme.success,
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildDueAmountCell() {
    final dueAmount = bill.financials.dueAmount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '₹${NumberFormat('#,##,###').format(dueAmount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color:
                dueAmount > 0 ? HospitalTheme.warning : HospitalTheme.success,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (dueAmount > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber,
                size: 10,
                color: HospitalTheme.warning,
              ),
              const SizedBox(width: 2),
              Text(
                'Pending',
                style: TextStyle(
                  color: HospitalTheme.warning,
                  fontSize: 10,
                ),
              ),
            ],
          )
        else
          Text(
            'Paid',
            style: TextStyle(
              color: HospitalTheme.success,
              fontSize: 10,
            ),
          ),
      ],
    );
  }

  Widget _buildActionsCell(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'View Details',
          child: IconButton(
            onPressed: () => _showBillDetail(context),
            icon: const Icon(Icons.visibility_outlined),
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ),
        Tooltip(
          message: 'View PDF',
          child: IconButton(
            onPressed: bill.files != null
                ? () => _openPDF(bill.files!.driveLink)
                : null,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 16),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'print',
              child: Row(
                children: [
                  Icon(Icons.print, size: 16),
                  SizedBox(width: 8),
                  Text('Print'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'email',
              child: Row(
                children: [
                  Icon(Icons.email, size: 16),
                  SizedBox(width: 8),
                  Text('Send Email'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'sms',
              child: Row(
                children: [
                  Icon(Icons.sms, size: 16),
                  SizedBox(width: 8),
                  Text('Send SMS'),
                ],
              ),
            ),
            if (bill.financials.dueAmount > 0)
              const PopupMenuItem(
                value: 'payment',
                child: Row(
                  children: [
                    Icon(Icons.payment, size: 16),
                    SizedBox(width: 8),
                    Text('Add Payment'),
                  ],
                ),
              ),
          ],
          onSelected: (value) => _handleAction(context, value),
        ),
      ],
    );
  }

  void _toggleSelection(WidgetRef ref) {
    final selectedRows = ref.read(selectedRowsProvider);
    final newSelection = Set<String>.from(selectedRows);

    if (selectedRows.contains(bill.id)) {
      newSelection.remove(bill.id);
    } else {
      newSelection.add(bill.id);
    }

    ref.read(selectedRowsProvider.notifier).state = newSelection;
  }

  void _showBillDetail(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => BillDetailDialog(bill: bill),
    );
  }

  void _openPDF(String url) {
    // Use Methods().pdfUrl(url) as specified in requirements
    Methods().openPdf(url);
    print('Opening PDF: $url');
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'print':
        print('Printing bill: ${bill.billNumber}');
        break;
      case 'email':
        print('Sending email for bill: ${bill.billNumber}');
        break;
      case 'sms':
        print('Sending SMS for bill: ${bill.billNumber}');
        break;
      case 'payment':
        _showAddPaymentDialog(context);
        break;
    }
  }

  void _showAddPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddPaymentDialog(bill: bill),
    );
  }

  Color _getBillTypeColor(String billType) {
    switch (billType.toUpperCase()) {
      case 'IPD':
        return HospitalTheme.emergency;
      case 'OPD':
        return HospitalTheme.info;
      default:
        return HospitalTheme.primary;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
        return HospitalTheme.success;
      case 'pending':
        return HospitalTheme.warning;
      case 'partial':
        return HospitalTheme.info;
      case 'cancelled':
        return HospitalTheme.error;
      default:
        return HospitalTheme.textMedium;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'generated':
        return HospitalTheme.success;
      case 'draft':
        return HospitalTheme.warning;
      case 'cancelled':
        return HospitalTheme.error;
      default:
        return HospitalTheme.textMedium;
    }
  }
}

// Responsive Table Footer
class BillsTableFooter extends ConsumerWidget {
  const BillsTableFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(tableFiltersProvider);
    final billsAsync = ref.watch(billsProvider(filters));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: HospitalTheme.border)),
      ),
      child: billsAsync.when(
        data: (data) => _buildFooterContent(context, ref, data),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildFooterContent(
      BuildContext context, WidgetRef ref, BillsData data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1200;

    if (isSmallScreen) {
      return _buildCompactFooter(context, ref, data);
    } else {
      return _buildFullFooter(context, ref, data);
    }
  }

  Widget _buildFullFooter(BuildContext context, WidgetRef ref, BillsData data) {
    return Row(
      children: [
        Text(
          'Showing ${data.bills.length} of ${data.pagination.total} bills',
          style: TextStyle(color: HospitalTheme.textMedium),
        ),
        const SizedBox(width: 24),
        _buildSummaryStats(data.bills),
        const Spacer(),
        if (data.pagination.pages > 1) ...[
          _buildPageSizeSelector(ref),
          const SizedBox(width: 16),
          BillsPaginationWidget(pagination: data.pagination),
        ],
      ],
    );
  }

  Widget _buildCompactFooter(
      BuildContext context, WidgetRef ref, BillsData data) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Showing ${data.bills.length} of ${data.pagination.total}',
              style: TextStyle(color: HospitalTheme.textMedium, fontSize: 13),
            ),
            const Spacer(),
            if (data.pagination.pages > 1) _buildPageSizeSelector(ref),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSummaryStats(data.bills)),
            if (data.pagination.pages > 1) ...[
              const SizedBox(width: 16),
              BillsPaginationWidget(pagination: data.pagination),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryStats(List<Bill> bills) {
    final totalAmount =
        bills.fold<double>(0, (sum, bill) => sum + bill.financials.grandTotal);
    final totalDue =
        bills.fold<double>(0, (sum, bill) => sum + bill.financials.dueAmount);

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildStatChip(
          label: 'Total Amount',
          value: '₹${NumberFormat('#,##,###').format(totalAmount)}',
          color: HospitalTheme.primary,
        ),
        _buildStatChip(
          label: 'Total Due',
          value: '₹${NumberFormat('#,##,###').format(totalDue)}',
          color: totalDue > 0 ? HospitalTheme.warning : HospitalTheme.success,
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageSizeSelector(WidgetRef ref) {
    final filters = ref.watch(tableFiltersProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Rows:',
          style: TextStyle(color: HospitalTheme.textMedium, fontSize: 13),
        ),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: filters.limit,
          underline: const SizedBox.shrink(),
          style: TextStyle(color: HospitalTheme.textDark, fontSize: 13),
          items: const [
            DropdownMenuItem(value: 10, child: Text('10')),
            DropdownMenuItem(value: 20, child: Text('20')),
            DropdownMenuItem(value: 50, child: Text('50')),
            DropdownMenuItem(value: 100, child: Text('100')),
          ],
          onChanged: (value) {
            if (value != null) {
              ref.read(tableFiltersProvider.notifier).state =
                  filters.copyWith(limit: value, page: 1);
            }
          },
        ),
      ],
    );
  }
}

// Pagination Widget
class BillsPaginationWidget extends ConsumerWidget {
  final Pagination pagination;

  const BillsPaginationWidget({super.key, required this.pagination});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 800;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: pagination.page > 1
              ? () => _goToPage(ref, pagination.page - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
          iconSize: 20,
        ),
        if (!isSmallScreen) ..._buildPageNumbers(ref),
        if (isSmallScreen) _buildCompactPageInfo(),
        IconButton(
          onPressed: pagination.page < pagination.pages
              ? () => _goToPage(ref, pagination.page + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
          iconSize: 20,
        ),
      ],
    );
  }

  List<Widget> _buildPageNumbers(WidgetRef ref) {
    final List<Widget> pages = [];
    final currentPage = pagination.page;
    final totalPages = pagination.pages;

    // Show first page
    if (currentPage > 3) {
      pages.add(_buildPageButton(ref, 1));
      if (currentPage > 4) {
        pages.add(const Text('...', style: TextStyle(fontSize: 12)));
      }
    }

    // Show current page and surrounding pages
    final start = (currentPage - 2).clamp(1, totalPages);
    final end = (currentPage + 2).clamp(1, totalPages);

    for (int i = start; i <= end; i++) {
      pages.add(_buildPageButton(ref, i));
    }

    // Show last page
    if (currentPage < totalPages - 2) {
      if (currentPage < totalPages - 3) {
        pages.add(const Text('...', style: TextStyle(fontSize: 12)));
      }
      pages.add(_buildPageButton(ref, totalPages));
    }

    return pages;
  }

  Widget _buildPageButton(WidgetRef ref, int pageNumber) {
    final isCurrentPage = pageNumber == pagination.page;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () => _goToPage(ref, pageNumber),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCurrentPage ? HospitalTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color:
                  isCurrentPage ? HospitalTheme.primary : HospitalTheme.border,
            ),
          ),
          child: Center(
            child: Text(
              pageNumber.toString(),
              style: TextStyle(
                color: isCurrentPage ? Colors.white : HospitalTheme.textDark,
                fontSize: 12,
                fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactPageInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '${pagination.page} / ${pagination.pages}',
        style: TextStyle(
          color: HospitalTheme.textMedium,
          fontSize: 12,
        ),
      ),
    );
  }

  void _goToPage(WidgetRef ref, int page) {
    final filters = ref.read(tableFiltersProvider);
    ref.read(tableFiltersProvider.notifier).state =
        filters.copyWith(page: page);
  }
}

// Bill Detail Dialog
class BillDetailDialog extends StatelessWidget {
  final Bill bill;

  const BillDetailDialog({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.9;
    final dialogHeight = screenSize.height * 0.9;

    return Dialog(
      child: Container(
        width: dialogWidth.clamp(600.0, 1200.0),
        height: dialogHeight.clamp(500.0, 800.0),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Bill Details - ${bill.billNumber}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: BillDetailView(bill: bill),
            ),
          ],
        ),
      ),
    );
  }
}

// Bill Detail View
class BillDetailView extends StatelessWidget {
  final Bill bill;

  const BillDetailView({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bill Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem('Bill Number', bill.billNumber),
                    ),
                    Expanded(
                      child: _buildDetailItem('Bill Type', bill.billType),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                          'Payment Status', bill.paymentStatus),
                    ),
                    Expanded(
                      child: _buildDetailItem('Status', bill.status),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDetailItem('Generated Date',
                    DateFormat('MMM dd, yyyy HH:mm').format(bill.generatedAt)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HospitalTheme.buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patient Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child:
                          _buildDetailItem('Patient Name', bill.patient.name),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                          'Patient ID', bill.patient.patientId),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child:
                          _buildDetailItem('Age', '${bill.patient.age} years'),
                    ),
                    Expanded(
                      child: _buildDetailItem('Gender', bill.patient.gender),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem('Contact', bill.patient.contact),
                    ),
                    Expanded(
                      child: _buildDetailItem('Address', bill.patient.address),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HospitalTheme.buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        'Sub Total',
                        '₹${NumberFormat('#,##,###').format(bill.financials.subTotal)}',
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Discount Amount',
                        '₹${NumberFormat('#,##,###').format(bill.financials.discountAmount)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        'Grand Total',
                        '₹${NumberFormat('#,##,###').format(bill.financials.grandTotal)}',
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Due Amount',
                        '₹${NumberFormat('#,##,###').format(bill.financials.dueAmount)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        'Paid Amount',
                        '₹${NumberFormat('#,##,###').format(bill.financials.paidAmount)}',
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Advance',
                        '₹${NumberFormat('#,##,###').format(bill.financials.advance)}',
                      ),
                    ),
                  ],
                ),
                if (bill.financials.servicesTotal > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          'Services Total',
                          '₹${NumberFormat('#,##,###').format(bill.financials.servicesTotal)}',
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          'Consultation Fee',
                          '₹${NumberFormat('#,##,###').format(bill.financials.consultationFee)}',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (bill.payments.isNotEmpty) ...[
            const SizedBox(height: 16),
            HospitalTheme.buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...bill.payments.map((payment) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '₹${NumberFormat('#,##,###').format(payment.amount)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    payment.paymentMode,
                                    style: TextStyle(
                                      color: HospitalTheme.textMedium,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('MMM dd, yyyy')
                                        .format(payment.paymentDate),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (payment.notes.isNotEmpty)
                                    Text(
                                      payment.notes,
                                      style: TextStyle(
                                        color: HospitalTheme.textMedium,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
          if (bill.files != null) ...[
            const SizedBox(height: 16),
            HospitalTheme.buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Files & Documents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: HospitalTheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bill.files!.pdfFileName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Size: ${(bill.files!.pdfSize / 1024).toStringAsFixed(1)} KB',
                              style: TextStyle(
                                color: HospitalTheme.textMedium,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Methods().pdfUrl(bill.files!.driveLink);
                          print('Opening PDF: ${bill.files!.driveLink}');
                        },
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Open PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HospitalTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: HospitalTheme.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// Add Payment Dialog
class AddPaymentDialog extends StatefulWidget {
  final Bill bill;

  const AddPaymentDialog({super.key, required this.bill});

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMode = 'Cash';

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.bill.financials.dueAmount.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Payment - ${widget.bill.billNumber}'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HospitalTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Due Amount:'),
                    Text(
                      '₹${NumberFormat('#,##,###').format(widget.bill.financials.dueAmount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.warning,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Payment Amount',
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter valid amount';
                  }
                  if (amount > widget.bill.financials.dueAmount) {
                    return 'Amount cannot exceed due amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _paymentMode,
                decoration: const InputDecoration(labelText: 'Payment Mode'),
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'Card', child: Text('Card')),
                  DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                  DropdownMenuItem(
                      value: 'Bank Transfer', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _paymentMode = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addPayment,
          child: const Text('Add Payment'),
        ),
      ],
    );
  }

  void _addPayment() {
    if (_formKey.currentState!.validate()) {
      print('Adding payment: ₹${_amountController.text} via $_paymentMode');
      Navigator.of(context).pop();
    }
  }
}

// Bulk Actions Sheet
class BulkActionsSheet extends ConsumerWidget {
  const BulkActionsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRows = ref.watch(selectedRowsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bulk Actions (${selectedRows.length} bills)',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.print),
            title: const Text('Print All'),
            onTap: () => _printAll(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Send Email to All'),
            onTap: () => _emailAll(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.sms),
            title: const Text('Send SMS to All'),
            onTap: () => _smsAll(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export Selected'),
            onTap: () => _exportSelected(context, ref),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.close, color: HospitalTheme.error),
            title: Text('Cancel', style: TextStyle(color: HospitalTheme.error)),
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _printAll(BuildContext context, WidgetRef ref) {
    final selectedRows = ref.read(selectedRowsProvider);
    print('Printing ${selectedRows.length} bills');
    Navigator.of(context).pop();
  }

  void _emailAll(BuildContext context, WidgetRef ref) {
    final selectedRows = ref.read(selectedRowsProvider);
    print('Sending emails for ${selectedRows.length} bills');
    Navigator.of(context).pop();
  }

  void _smsAll(BuildContext context, WidgetRef ref) {
    final selectedRows = ref.read(selectedRowsProvider);
    print('Sending SMS for ${selectedRows.length} bills');
    Navigator.of(context).pop();
  }

  void _exportSelected(BuildContext context, WidgetRef ref) {
    final selectedRows = ref.read(selectedRowsProvider);
    print('Exporting ${selectedRows.length} bills');
    Navigator.of(context).pop();
  }
}

// Column Settings Dialog
class ColumnSettingsDialog extends StatefulWidget {
  const ColumnSettingsDialog({super.key});

  @override
  State<ColumnSettingsDialog> createState() => _ColumnSettingsDialogState();
}

class _ColumnSettingsDialogState extends State<ColumnSettingsDialog> {
  final Map<BillTableColumn, bool> _columnVisibility = {
    for (var column in BillTableColumn.values) column: true,
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Column Settings'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select columns to display:'),
            const SizedBox(height: 16),
            ...BillTableColumn.values.map((column) => CheckboxListTile(
                  title: Text(column.label),
                  value: _columnVisibility[column],
                  onChanged: column == BillTableColumn.actions
                      ? null // Actions column is always visible
                      : (value) {
                          setState(() {
                            _columnVisibility[column] = value ?? false;
                          });
                        },
                )),
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
            print('Column settings: $_columnVisibility');
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

// Search Dialog
class BillSearchDialog extends StatefulWidget {
  const BillSearchDialog({super.key});

  @override
  State<BillSearchDialog> createState() => _BillSearchDialogState();
}

class _BillSearchDialogState extends State<BillSearchDialog> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search Bills'),
      content: SizedBox(
        width: 400,
        child: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search bills, patients, bill numbers...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) => _performSearch(context),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _performSearch(context),
          child: const Text('Search'),
        ),
      ],
    );
  }

  void _performSearch(BuildContext context) {
    // Implement search logic
    print('Searching for: ${_searchController.text}');
    Navigator.of(context).pop();
  }
}

// Advanced Filters Dialog
class BillAdvancedFiltersDialog extends ConsumerStatefulWidget {
  const BillAdvancedFiltersDialog({super.key});

  @override
  ConsumerState<BillAdvancedFiltersDialog> createState() =>
      _BillAdvancedFiltersDialogState();
}

class _BillAdvancedFiltersDialogState
    extends ConsumerState<BillAdvancedFiltersDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _status;
  String? _patientId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Advanced Filters'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Status')),
                DropdownMenuItem(value: 'Generated', child: Text('Generated')),
                DropdownMenuItem(value: 'Draft', child: Text('Draft')),
                DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
              ],
              onChanged: (value) => setState(() => _status = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Patient ID'),
              onChanged: (value) => _patientId = value.isEmpty ? null : value,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context, true),
                    controller: TextEditingController(
                      text: _startDate != null
                          ? DateFormat('yyyy-MM-dd').format(_startDate!)
                          : '',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context, false),
                    controller: TextEditingController(
                      text: _endDate != null
                          ? DateFormat('yyyy-MM-dd').format(_endDate!)
                          : '',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _clearFilters,
          child: const Text('Clear'),
        ),
        ElevatedButton(
          onPressed: _applyFilters,
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _status = null;
      _patientId = null;
    });
  }

  void _applyFilters() {
    final currentFilters = ref.read(tableFiltersProvider);
    ref.read(tableFiltersProvider.notifier).state = currentFilters.copyWith(
      status: _status,
      patientId: _patientId,
      startDate: _startDate,
      endDate: _endDate,
      page: 1,
    );
    Navigator.of(context).pop();
  }
}
