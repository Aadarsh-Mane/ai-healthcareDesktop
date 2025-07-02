// admin/BillTrackScreen.dart

import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Models
class Bill {
  final String id;
  final String billNumber;
  final String billType;
  final Patient patient;
  final Admission admission;
  final List<Service> services;
  final Financials financials;
  final List<Payment> payments;
  final String paymentStatus;
  final String status;
  final Files? files;
  final DateTime generatedAt;
  final String? notes;
  final int billNo;
  final int printCount;
  final bool emailSent;
  final bool smsSent;

  const Bill({
    required this.id,
    required this.billNumber,
    required this.billType,
    required this.patient,
    required this.admission,
    required this.services,
    required this.financials,
    required this.payments,
    required this.paymentStatus,
    required this.status,
    this.files,
    required this.generatedAt,
    this.notes,
    required this.billNo,
    required this.printCount,
    required this.emailSent,
    required this.smsSent,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['_id'] ?? '',
      billNumber: json['billNumber'] ?? '',
      billType: json['billType'] ?? '',
      patient: Patient.fromJson(json['patient'] ?? {}),
      admission: Admission.fromJson(json['admission'] ?? {}),
      services: (json['services'] as List?)
              ?.map((s) => Service.fromJson(s))
              .toList() ??
          [],
      financials: Financials.fromJson(json['financials'] ?? {}),
      payments: (json['payments'] as List?)
              ?.map((p) => Payment.fromJson(p))
              .toList() ??
          [],
      paymentStatus: json['paymentStatus'] ?? '',
      status: json['status'] ?? '',
      files: json['files'] != null ? Files.fromJson(json['files']) : null,
      generatedAt:
          DateTime.tryParse(json['generatedAt'] ?? '') ?? DateTime.now(),
      notes: json['notes'],
      billNo: json['billNo'] ?? 0,
      printCount: json['printCount'] ?? 0,
      emailSent: json['emailSent'] ?? false,
      smsSent: json['smsSent'] ?? false,
    );
  }
}

class Patient {
  final String patientId;
  final String name;
  final int age;
  final String gender;
  final String contact;
  final String address;

  const Patient({
    required this.patientId,
    required this.name,
    required this.age,
    required this.gender,
    required this.contact,
    required this.address,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      patientId: json['patientId'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      contact: json['contact'] ?? '',
      address: json['address'] ?? '',
    );
  }
}

class Admission {
  final String? admissionId;
  final DateTime? admissionDate;
  final DateTime? dischargeDate;
  final int? lengthOfStay;
  final Doctor? attendingDoctor;
  final Department? department;
  final String? roomType;

  const Admission({
    this.admissionId,
    this.admissionDate,
    this.dischargeDate,
    this.lengthOfStay,
    this.attendingDoctor,
    this.department,
    this.roomType,
  });

  factory Admission.fromJson(Map<String, dynamic> json) {
    return Admission(
      admissionId: json['admissionId'],
      admissionDate: json['admissionDate'] != null
          ? DateTime.tryParse(json['admissionDate'])
          : null,
      dischargeDate: json['dischargeDate'] != null
          ? DateTime.tryParse(json['dischargeDate'])
          : null,
      lengthOfStay: json['lengthOfStay'],
      attendingDoctor: json['attendingDoctor'] != null
          ? Doctor.fromJson(json['attendingDoctor'])
          : null,
      department: json['department'] != null
          ? Department.fromJson(json['department'])
          : null,
      roomType: json['roomType'],
    );
  }
}

class Doctor {
  final String id;
  final String name;

  const Doctor({required this.id, required this.name});

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id']?['_id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class Department {
  final String name;
  final String? type;

  const Department({required this.name, this.type});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      name: json['name'] ?? '',
      type: json['type'],
    );
  }
}

class Service {
  final String name;
  final String description;
  final int quantity;
  final double rate;
  final double total;
  final String category;

  const Service({
    required this.name,
    required this.description,
    required this.quantity,
    required this.rate,
    required this.total,
    required this.category,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? 0,
      rate: (json['rate'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      category: json['category'] ?? '',
    );
  }
}

class Financials {
  final double subTotal;
  final double discountPercent;
  final double discountAmount;
  final double grandTotal;
  final double dueAmount;
  final double paidAmount;
  final double advance;
  final double servicesTotal;
  final double consultationFee;
  final double doctorCharges;
  final double taxPercent;
  final double taxAmount;

  const Financials({
    required this.subTotal,
    required this.discountPercent,
    required this.discountAmount,
    required this.grandTotal,
    required this.dueAmount,
    required this.paidAmount,
    required this.advance,
    required this.servicesTotal,
    required this.consultationFee,
    required this.doctorCharges,
    required this.taxPercent,
    required this.taxAmount,
  });

  factory Financials.fromJson(Map<String, dynamic> json) {
    return Financials(
      subTotal: (json['subTotal'] ?? 0).toDouble(),
      discountPercent: (json['discountPercent'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      grandTotal: (json['grandTotal'] ?? 0).toDouble(),
      dueAmount: (json['dueAmount'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      advance: (json['advance'] ?? 0).toDouble(),
      servicesTotal: (json['servicesTotal'] ?? 0).toDouble(),
      consultationFee: (json['consultationFee'] ?? 0).toDouble(),
      doctorCharges: (json['doctorCharges'] ?? 0).toDouble(),
      taxPercent: (json['taxPercent'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
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

class Files {
  final String pdfFileName;
  final String driveLink;
  final int pdfSize;
  final DateTime uploadedAt;

  const Files({
    required this.pdfFileName,
    required this.driveLink,
    required this.pdfSize,
    required this.uploadedAt,
  });

  factory Files.fromJson(Map<String, dynamic> json) {
    return Files(
      pdfFileName: json['pdfFileName'] ?? '',
      driveLink: json['driveLink'] ?? '',
      pdfSize: json['pdfSize'] ?? 0,
      uploadedAt: DateTime.tryParse(json['uploadedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class BillsResponse {
  final List<Bill> bills;
  final Pagination pagination;

  const BillsResponse({required this.bills, required this.pagination});

  factory BillsResponse.fromJson(Map<String, dynamic> json) {
    return BillsResponse(
      bills: (json['data']?['bills'] as List?)
              ?.map((b) => Bill.fromJson(b))
              .toList() ??
          [],
      pagination: Pagination.fromJson(json['data']?['pagination'] ?? {}),
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

// Filters State
class BillFilters {
  final String? billType;
  final String? paymentStatus;
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? patientId;
  final String? search;
  final int page;
  final int limit;

  const BillFilters({
    this.billType,
    this.paymentStatus,
    this.status,
    this.startDate,
    this.endDate,
    this.patientId,
    this.search,
    this.page = 1,
    this.limit = 20,
  });

  BillFilters copyWith({
    String? billType,
    String? paymentStatus,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? patientId,
    String? search,
    int? page,
    int? limit,
  }) {
    return BillFilters(
      billType: billType ?? this.billType,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      patientId: patientId ?? this.patientId,
      search: search ?? this.search,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  Map<String, String> toQueryParams() {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (billType != null) params['billType'] = billType!;
    if (paymentStatus != null) params['paymentStatus'] = paymentStatus!;
    if (status != null) params['status'] = status!;
    if (startDate != null) params['startDate'] = startDate!.toIso8601String();
    if (endDate != null) params['endDate'] = endDate!.toIso8601String();
    if (patientId != null) params['patientId'] = patientId!;
    if (search != null && search!.isNotEmpty) params['search'] = search!;

    return params;
  }
}

// Providers
final billFiltersProvider =
    StateProvider<BillFilters>((ref) => const BillFilters());
final selectedBillProvider = StateProvider<Bill?>((ref) => null);

final billsProvider =
    FutureProvider.family<BillsResponse, BillFilters>((ref, filters) async {
  final uri = Uri.parse('${KVM_URL}/reception/getAllBills')
      .replace(queryParameters: filters.toQueryParams());

  final response = await http.get(uri);
  print(response.body);
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return BillsResponse.fromJson(data);
  } else {
    throw Exception('Failed to load bills');
  }
});

// Main Bills Track Screen
class BillsTrackScreen extends ConsumerWidget {
  const BillsTrackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedBill = ref.watch(selectedBillProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: HospitalTheme.background,
      appBar: HospitalTheme.buildAppBar(
        context: context,
        title: 'Bills Management',
        showBackButton: false,
      ),
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
              _showSearchDialog(context, ref),
          const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () =>
              _showSearchDialog(context, ref),
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              ref.read(selectedBillProvider.notifier).state = null,
        },
        child: Focus(
          autofocus: true,
          child: isMobile
              ? (selectedBill != null
                  ? BillDetailView(bill: selectedBill)
                  : const BillsListView())
              : Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: BillsListView(),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      flex: 3,
                      child: selectedBill != null
                          ? BillDetailView(bill: selectedBill)
                          : const BillDetailPlaceholder(),
                    ),
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
}

// Bills List View
class BillsListView extends ConsumerWidget {
  const BillsListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(billFiltersProvider);
    final billsAsync = ref.watch(billsProvider(filters));

    return Column(
      children: [
        const BillsFilterBar(),
        Expanded(
          child: billsAsync.when(
            data: (billsResponse) =>
                _buildBillsList(context, ref, billsResponse),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: HospitalTheme.error),
                  const SizedBox(height: 16),
                  Text('Error loading bills: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(billsProvider(filters)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillsList(
      BuildContext context, WidgetRef ref, BillsResponse response) {
    if (response.bills.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No bills found'),
            Text('Try adjusting your filters',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Showing ${response.bills.length} of ${response.pagination.total} bills',
                style: TextStyle(color: HospitalTheme.textMedium),
              ),
              const Spacer(),
              if (response.pagination.pages > 1)
                BillsPaginationWidget(pagination: response.pagination),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: response.bills.length,
            itemBuilder: (context, index) {
              final bill = response.bills[index];
              return BillListTile(bill: bill);
            },
          ),
        ),
      ],
    );
  }
}

// Bill List Tile
class BillListTile extends ConsumerWidget {
  final Bill bill;

  const BillListTile({super.key, required this.bill});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedBill = ref.watch(selectedBillProvider);
    final isSelected = selectedBill?.id == bill.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: HospitalTheme.buildCard(
        backgroundColor: isSelected ? HospitalTheme.surfaceLight : null,
        child: InkWell(
          onTap: () => ref.read(selectedBillProvider.notifier).state = bill,
          borderRadius: HospitalTheme.radiusMedium,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            _getBillTypeColor(bill.billType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        bill.billType,
                        style: TextStyle(
                          color: _getBillTypeColor(bill.billType),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      bill.billNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    HospitalTheme.buildStatusBadge(
                      bill.paymentStatus,
                      color: _getPaymentStatusColor(bill.paymentStatus),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 16, color: HospitalTheme.textMedium),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${bill.patient.name} (${bill.patient.patientId})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: HospitalTheme.textMedium),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM dd, yyyy').format(bill.generatedAt),
                      style: TextStyle(color: HospitalTheme.textMedium),
                    ),
                    const SizedBox(width: 24),
                    Icon(Icons.currency_rupee,
                        size: 16, color: HospitalTheme.textMedium),
                    const SizedBox(width: 4),
                    Text(
                      '₹${NumberFormat('#,##,###').format(bill.financials.grandTotal)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                if (bill.financials.dueAmount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.warning_amber,
                          size: 16, color: HospitalTheme.warning),
                      const SizedBox(width: 8),
                      Text(
                        'Due: ₹${NumberFormat('#,##,###').format(bill.financials.dueAmount)}',
                        style: TextStyle(
                          color: HospitalTheme.warning,
                          fontWeight: FontWeight.w600,
                        ),
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
}

// Filters Bar
class BillsFilterBar extends ConsumerWidget {
  const BillsFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(billFiltersProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: HospitalTheme.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    ref.read(billFiltersProvider.notifier).state =
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
              IconButton(
                onPressed: () => _showFilterDialog(context, ref),
                icon: Badge(
                  isLabelVisible: _hasActiveFilters(filters),
                  child: const Icon(Icons.filter_list),
                ),
                tooltip: 'Advanced Filters',
              ),
              IconButton(
                onPressed: () => _clearFilters(ref),
                icon: const Icon(Icons.clear_all),
                tooltip: 'Clear Filters',
              ),
            ],
          ),
          if (_hasActiveFilters(filters)) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildActiveFilterChips(ref, filters),
            ),
          ],
        ],
      ),
    );
  }

  bool _hasActiveFilters(BillFilters filters) {
    return filters.billType != null ||
        filters.paymentStatus != null ||
        filters.status != null ||
        filters.startDate != null ||
        filters.endDate != null ||
        filters.patientId != null;
  }

  List<Widget> _buildActiveFilterChips(WidgetRef ref, BillFilters filters) {
    final chips = <Widget>[];

    if (filters.billType != null) {
      chips.add(_buildFilterChip(
        label: 'Type: ${filters.billType}',
        onRemove: () => ref.read(billFiltersProvider.notifier).state =
            filters.copyWith(billType: null, page: 1),
      ));
    }

    if (filters.paymentStatus != null) {
      chips.add(_buildFilterChip(
        label: 'Payment: ${filters.paymentStatus}',
        onRemove: () => ref.read(billFiltersProvider.notifier).state =
            filters.copyWith(paymentStatus: null, page: 1),
      ));
    }

    if (filters.status != null) {
      chips.add(_buildFilterChip(
        label: 'Status: ${filters.status}',
        onRemove: () => ref.read(billFiltersProvider.notifier).state =
            filters.copyWith(status: null, page: 1),
      ));
    }

    if (filters.startDate != null || filters.endDate != null) {
      final start = filters.startDate != null
          ? DateFormat('MMM dd').format(filters.startDate!)
          : '';
      final end = filters.endDate != null
          ? DateFormat('MMM dd').format(filters.endDate!)
          : '';
      chips.add(_buildFilterChip(
        label: 'Date: $start - $end',
        onRemove: () => ref.read(billFiltersProvider.notifier).state =
            filters.copyWith(startDate: null, endDate: null, page: 1),
      ));
    }

    return chips;
  }

  Widget _buildFilterChip(
      {required String label, required VoidCallback onRemove}) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const BillAdvancedFiltersDialog(),
    );
  }

  void _clearFilters(WidgetRef ref) {
    ref.read(billFiltersProvider.notifier).state = const BillFilters();
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
  late BillFilters tempFilters;

  @override
  void initState() {
    super.initState();
    tempFilters = ref.read(billFiltersProvider);
  }

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
              value: tempFilters.billType,
              decoration: const InputDecoration(labelText: 'Bill Type'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'IPD', child: Text('IPD')),
                DropdownMenuItem(value: 'OPD', child: Text('OPD')),
              ],
              onChanged: (value) {
                setState(() {
                  tempFilters = tempFilters.copyWith(billType: value);
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: tempFilters.paymentStatus,
              decoration: const InputDecoration(labelText: 'Payment Status'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                DropdownMenuItem(value: 'Partial', child: Text('Partial')),
                DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
              ],
              onChanged: (value) {
                setState(() {
                  tempFilters = tempFilters.copyWith(paymentStatus: value);
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: tempFilters.status,
              decoration: const InputDecoration(labelText: 'Bill Status'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'Generated', child: Text('Generated')),
                DropdownMenuItem(value: 'Draft', child: Text('Draft')),
                DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
              ],
              onChanged: (value) {
                setState(() {
                  tempFilters = tempFilters.copyWith(status: value);
                });
              },
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
                    controller: TextEditingController(
                      text: tempFilters.startDate != null
                          ? DateFormat('MMM dd, yyyy')
                              .format(tempFilters.startDate!)
                          : '',
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: tempFilters.startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          tempFilters = tempFilters.copyWith(startDate: date);
                        });
                      }
                    },
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
                    controller: TextEditingController(
                      text: tempFilters.endDate != null
                          ? DateFormat('MMM dd, yyyy')
                              .format(tempFilters.endDate!)
                          : '',
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: tempFilters.endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          tempFilters = tempFilters.copyWith(endDate: date);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: tempFilters.patientId,
              decoration: const InputDecoration(labelText: 'Patient ID'),
              onChanged: (value) {
                tempFilters = tempFilters.copyWith(
                    patientId: value.isEmpty ? null : value);
              },
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
          onPressed: () {
            setState(() {
              tempFilters = const BillFilters();
            });
          },
          child: const Text('Clear All'),
        ),
        ElevatedButton(
          onPressed: () {
            ref.read(billFiltersProvider.notifier).state =
                tempFilters.copyWith(page: 1);
            Navigator.of(context).pop();
          },
          child: const Text('Apply Filters'),
        ),
      ],
    );
  }
}

// Search Dialog
class BillSearchDialog extends ConsumerStatefulWidget {
  const BillSearchDialog({super.key});

  @override
  ConsumerState<BillSearchDialog> createState() => _BillSearchDialogState();
}

class _BillSearchDialogState extends ConsumerState<BillSearchDialog> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quick Search'),
      content: SizedBox(
        width: 400,
        child: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search by bill number, patient name, or patient ID...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            _performSearch();
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _performSearch,
          child: const Text('Search'),
        ),
      ],
    );
  }

  void _performSearch() {
    final filters = ref.read(billFiltersProvider);
    ref.read(billFiltersProvider.notifier).state =
        filters.copyWith(search: _searchController.text, page: 1);
    Navigator.of(context).pop();
  }
}

// Pagination Widget
class BillsPaginationWidget extends ConsumerWidget {
  final Pagination pagination;

  const BillsPaginationWidget({super.key, required this.pagination});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: pagination.page > 1
              ? () => _changePage(ref, pagination.page - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous Page',
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: HospitalTheme.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text('${pagination.page} of ${pagination.pages}'),
        ),
        IconButton(
          onPressed: pagination.page < pagination.pages
              ? () => _changePage(ref, pagination.page + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next Page',
        ),
      ],
    );
  }

  void _changePage(WidgetRef ref, int page) {
    final filters = ref.read(billFiltersProvider);
    ref.read(billFiltersProvider.notifier).state = filters.copyWith(page: page);
  }
}

// Bill Detail View
class BillDetailView extends ConsumerWidget {
  final Bill bill;

  const BillDetailView({super.key, required this.bill});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      color: HospitalTheme.background,
      child: Column(
        children: [
          if (isMobile)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: HospitalTheme.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        ref.read(selectedBillProvider.notifier).state = null,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Text('Bill Details',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBillHeader(),
                  const SizedBox(height: 24),
                  _buildPatientInfo(),
                  const SizedBox(height: 24),
                  if (bill.admission.admissionId != null) ...[
                    _buildAdmissionInfo(),
                    const SizedBox(height: 24),
                  ],
                  if (bill.services.isNotEmpty) ...[
                    _buildServicesSection(),
                    const SizedBox(height: 24),
                  ],
                  _buildFinancialsSection(),
                  const SizedBox(height: 24),
                  if (bill.payments.isNotEmpty) ...[
                    _buildPaymentsSection(),
                    const SizedBox(height: 24),
                  ],
                  _buildActionsSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillHeader() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getBillTypeColor(bill.billType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  bill.billType,
                  style: TextStyle(
                    color: _getBillTypeColor(bill.billType),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              HospitalTheme.buildStatusBadge(
                bill.paymentStatus,
                color: _getPaymentStatusColor(bill.paymentStatus),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            bill.billNumber,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today,
                  size: 16, color: HospitalTheme.textMedium),
              const SizedBox(width: 8),
              Text(
                'Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(bill.generatedAt)}',
                style: TextStyle(color: HospitalTheme.textMedium),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.receipt, size: 16, color: HospitalTheme.textMedium),
              const SizedBox(width: 8),
              Text(
                'Bill No: ${bill.billNo}',
                style: TextStyle(color: HospitalTheme.textMedium),
              ),
              const SizedBox(width: 24),
              Icon(Icons.print, size: 16, color: HospitalTheme.textMedium),
              const SizedBox(width: 8),
              Text(
                'Printed: ${bill.printCount} times',
                style: TextStyle(color: HospitalTheme.textMedium),
              ),
            ],
          ),
          if (bill.notes != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HospitalTheme.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bill.notes!,
                    style: TextStyle(color: HospitalTheme.textMedium),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPatientInfo() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('Patient Information'),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: HospitalTheme.surfaceLight,
                ),
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
                    Text(
                      bill.patient.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Patient ID: ${bill.patient.patientId}',
                      style: TextStyle(
                        color: HospitalTheme.textMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  icon: Icons.cake,
                  label: 'Age',
                  value: '${bill.patient.age} years',
                ),
              ),
              Expanded(
                child: _buildInfoRow(
                  icon: bill.patient.gender.toLowerCase() == 'male'
                      ? Icons.male
                      : Icons.female,
                  label: 'Gender',
                  value: bill.patient.gender,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  icon: Icons.phone,
                  label: 'Contact',
                  value: bill.patient.contact,
                ),
              ),
              Expanded(
                child: _buildInfoRow(
                  icon: Icons.location_on,
                  label: 'Address',
                  value: bill.patient.address,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdmissionInfo() {
    final admission = bill.admission;
    if (admission.admissionId == null) return const SizedBox.shrink();

    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('Admission Information'),
          _buildInfoRow(
            icon: Icons.local_hospital,
            label: 'Admission ID',
            value: admission.admissionId!,
          ),
          const SizedBox(height: 12),
          if (admission.attendingDoctor != null)
            _buildInfoRow(
              icon: Icons.medical_services,
              label: 'Attending Doctor',
              value: 'Dr. ${admission.attendingDoctor!.name}',
            ),
          if (admission.department != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.business,
              label: 'Department',
              value: admission.department!.name,
            ),
          ],
          if (admission.roomType != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.bed,
              label: 'Room Type',
              value: admission.roomType!,
            ),
          ],
          if (admission.admissionDate != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    icon: Icons.login,
                    label: 'Admission Date',
                    value: DateFormat('MMM dd, yyyy')
                        .format(admission.admissionDate!),
                  ),
                ),
                if (admission.dischargeDate != null)
                  Expanded(
                    child: _buildInfoRow(
                      icon: Icons.logout,
                      label: 'Discharge Date',
                      value: DateFormat('MMM dd, yyyy')
                          .format(admission.dischargeDate!),
                    ),
                  ),
              ],
            ),
          ],
          if (admission.lengthOfStay != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.access_time,
              label: 'Length of Stay',
              value:
                  '${admission.lengthOfStay} day${admission.lengthOfStay! > 1 ? 's' : ''}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('Services & Charges'),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bill.services.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final service = bill.services[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (service.description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              service.description,
                              style: TextStyle(
                                color: HospitalTheme.textMedium,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(service.category)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              service.category.toUpperCase(),
                              style: TextStyle(
                                color: _getCategoryColor(service.category),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${service.quantity}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: HospitalTheme.textMedium),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '₹${NumberFormat('#,##,###').format(service.rate)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: HospitalTheme.textMedium),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '₹${NumberFormat('#,##,###').format(service.total)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialsSection() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('Financial Summary'),
          _buildFinancialRow('Subtotal', bill.financials.subTotal),
          if (bill.financials.servicesTotal > 0)
            _buildFinancialRow('Services Total', bill.financials.servicesTotal),
          if (bill.financials.consultationFee > 0)
            _buildFinancialRow(
                'Consultation Fee', bill.financials.consultationFee),
          if (bill.financials.doctorCharges > 0)
            _buildFinancialRow('Doctor Charges', bill.financials.doctorCharges),
          if (bill.financials.discountAmount > 0)
            _buildFinancialRow(
              'Discount (${bill.financials.discountPercent.toStringAsFixed(1)}%)',
              -bill.financials.discountAmount,
              isNegative: true,
            ),
          if (bill.financials.taxAmount > 0)
            _buildFinancialRow(
                'Tax (${bill.financials.taxPercent.toStringAsFixed(1)}%)',
                bill.financials.taxAmount),
          const Divider(thickness: 2),
          _buildFinancialRow('Grand Total', bill.financials.grandTotal,
              isTotal: true),
          if (bill.financials.advance > 0)
            _buildFinancialRow('Advance Paid', bill.financials.advance,
                isNegative: true),
          _buildFinancialRow('Paid Amount', bill.financials.paidAmount,
              isNegative: true),
          const Divider(),
          _buildFinancialRow(
            'Due Amount',
            bill.financials.dueAmount,
            isTotal: true,
            color: bill.financials.dueAmount > 0
                ? HospitalTheme.warning
                : HospitalTheme.success,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsSection() {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('Payment History'),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bill.payments.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final payment = bill.payments[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: HospitalTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.payment,
                        color: HospitalTheme.success,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '₹${NumberFormat('#,##,###').format(payment.amount)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: HospitalTheme.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  payment.paymentMode,
                                  style: TextStyle(
                                    color: HospitalTheme.info,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy HH:mm')
                                .format(payment.paymentDate),
                            style: TextStyle(
                              color: HospitalTheme.textMedium,
                              fontSize: 13,
                            ),
                          ),
                          if (payment.notes.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              payment.notes,
                              style: TextStyle(
                                color: HospitalTheme.textMedium,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('Actions'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: bill.files != null
                    ? () => _openPDF(bill.files!.driveLink)
                    : null,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('View PDF'),
              ),
              // ElevatedButton.icon(
              //   onPressed: () => _printBill(),
              //   icon: const Icon(Icons.print),
              //   label: const Text('Print'),
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: HospitalTheme.info,
              //   ),
              // ),
              // ElevatedButton.icon(
              //   onPressed: () => _sendEmail(),
              //   icon:
              //       Icon(bill.emailSent ? Icons.mark_email_read : Icons.email),
              //   label: Text(bill.emailSent ? 'Email Sent' : 'Send Email'),
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: bill.emailSent
              //         ? HospitalTheme.success
              //         : HospitalTheme.secondary,
              //   ),
              // ),
              // ElevatedButton.icon(
              //   onPressed: () => _sendSMS(),
              //   icon: Icon(bill.smsSent ? Icons.check_circle : Icons.sms),
              //   label: Text(bill.smsSent ? 'SMS Sent' : 'Send SMS'),
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: bill.smsSent
              //         ? HospitalTheme.success
              //         : HospitalTheme.pharmacy,
              //   ),
              // ),
              // if (bill.financials.dueAmount > 0)
              //   ElevatedButton.icon(
              //     onPressed: () => _addPayment(),
              //     icon: const Icon(Icons.payment),
              //     label: const Text('Add Payment'),
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: HospitalTheme.warning,
              //     ),
              //   ),
            ],
          ),
          if (bill.files != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HospitalTheme.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'File Information:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.file_present,
                          size: 16, color: HospitalTheme.textMedium),
                      const SizedBox(width: 8),
                      Expanded(child: Text(bill.files!.pdfFileName)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.storage,
                          size: 16, color: HospitalTheme.textMedium),
                      const SizedBox(width: 8),
                      Text(
                          '${(bill.files!.pdfSize / 1024).toStringAsFixed(1)} KB'),
                      const SizedBox(width: 24),
                      Icon(Icons.access_time,
                          size: 16, color: HospitalTheme.textMedium),
                      const SizedBox(width: 8),
                      Text(DateFormat('MMM dd, yyyy HH:mm')
                          .format(bill.files!.uploadedAt)),
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: HospitalTheme.textMedium),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: HospitalTheme.textMedium,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isNegative = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: color ?? HospitalTheme.textDark,
            ),
          ),
          Text(
            '${isNegative ? '-' : ''}₹${NumberFormat('#,##,###').format(amount.abs())}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 16 : 14,
              color: color ??
                  (isNegative ? HospitalTheme.success : HospitalTheme.textDark),
            ),
          ),
        ],
      ),
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

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'diagnostic':
        return HospitalTheme.info;
      case 'treatment':
        return HospitalTheme.medical;
      case 'consultation':
        return HospitalTheme.primary;
      case 'pharmacy':
        return HospitalTheme.pharmacy;
      case 'laboratory':
        return HospitalTheme.laboratory;
      default:
        return HospitalTheme.textMedium;
    }
  }

  void _openPDF(String url) {
    // Use Methods().pdfUrl(url) as specified in requirements
    Methods().openPdf(url);
    print('Opening PDF: $url');
  }

  void _printBill() {
    // Implement print functionality
    print('Printing bill: ${bill.billNumber}');
  }

  void _sendEmail() {
    // Implement email functionality
    print('Sending email for bill: ${bill.billNumber}');
  }

  void _sendSMS() {
    // Implement SMS functionality
    print('Sending SMS for bill: ${bill.billNumber}');
  }

  void _addPayment() {
    // Implement add payment functionality
    print('Adding payment for bill: ${bill.billNumber}');
  }
}

// Bill Detail Placeholder
class BillDetailPlaceholder extends StatelessWidget {
  const BillDetailPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: HospitalTheme.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Select a bill to view details',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose from the list on the left to see detailed information',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HospitalTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: HospitalTheme.border),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.keyboard,
                    size: 24,
                    color: HospitalTheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Keyboard Shortcuts',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildShortcut('Ctrl/Cmd + F', 'Quick Search'),
                  _buildShortcut('Escape', 'Clear Selection'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcut(String keys, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              keys,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: HospitalTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}
