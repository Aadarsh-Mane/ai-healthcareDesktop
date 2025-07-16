import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/core/utils/PdfViewerScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart';

// Data Models
class ChargeItem {
  final String key;
  final String displayName;
  final double rate;
  final int days;
  final bool isActive;

  const ChargeItem({
    required this.key,
    required this.displayName,
    required this.rate,
    required this.days,
    this.isActive = false,
  });

  ChargeItem copyWith({
    String? key,
    String? displayName,
    double? rate,
    int? days,
    bool? isActive,
  }) {
    return ChargeItem(
      key: key ?? this.key,
      displayName: displayName ?? this.displayName,
      rate: rate ?? this.rate,
      days: days ?? this.days,
      isActive: isActive ?? this.isActive,
    );
  }

  double get total => rate * days;

  Map<String, dynamic> toJson() {
    return {
      'rate': rate,
      'days': days,
    };
  }
}

// Custom Charge Item
class CustomChargeItem {
  final String id;
  final String description;
  final double rate;
  final int days;

  const CustomChargeItem({
    required this.id,
    required this.description,
    required this.rate,
    required this.days,
  });

  CustomChargeItem copyWith({
    String? id,
    String? description,
    double? rate,
    int? days,
  }) {
    return CustomChargeItem(
      id: id ?? this.id,
      description: description ?? this.description,
      rate: rate ?? this.rate,
      days: days ?? this.days,
    );
  }

  double get total => rate * days;

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'rate': rate,
      'days': days,
    };
  }
}

class BillSummary {
  final double totalCharges;
  final double discount;
  final double advance;
  final double finalAmount;

  const BillSummary({
    required this.totalCharges,
    required this.discount,
    required this.advance,
    required this.finalAmount,
  });
}

class GeneratedBillResponse {
  final String fileName;
  final String driveLink;
  final int pdfSize;
  final DateTime generatedAt;
  final Map<String, dynamic> patientInfo;
  final Map<String, dynamic> admissionDetails;
  final BillSummary billSummary;
  final Map<String, dynamic> billData;

  const GeneratedBillResponse({
    required this.fileName,
    required this.driveLink,
    required this.pdfSize,
    required this.generatedAt,
    required this.patientInfo,
    required this.admissionDetails,
    required this.billSummary,
    required this.billData,
  });

  factory GeneratedBillResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return GeneratedBillResponse(
      fileName: data['fileName'] ?? '',
      driveLink: data['driveLink'] ?? '',
      pdfSize: data['pdfSize'] ?? 0,
      generatedAt: DateTime.parse(
          data['generatedAt'] ?? DateTime.now().toIso8601String()),
      patientInfo: data['patientInfo'] ?? {},
      admissionDetails: data['admissionDetails'] ?? {},
      billSummary: BillSummary(
        totalCharges: (data['billSummary']['totalCharges'] ?? 0).toDouble(),
        discount: (data['billSummary']['discount'] ?? 0).toDouble(),
        advance: (data['billSummary']['advance'] ?? 0).toDouble(),
        finalAmount: (data['billSummary']['finalAmount'] ?? 0).toDouble(),
      ),
      billData: data['billData'] ?? {},
    );
  }
}

class IpdReceiptResponse {
  final String message;
  final Map<String, dynamic> updatedPatient;
  final Map<String, dynamic> updatedHistory;
  final String fileLink;

  const IpdReceiptResponse({
    required this.message,
    required this.updatedPatient,
    required this.updatedHistory,
    required this.fileLink,
  });

  factory IpdReceiptResponse.fromJson(Map<String, dynamic> json) {
    return IpdReceiptResponse(
      message: json['message'] ?? '',
      updatedPatient: json['updatedPatient'] ?? {},
      updatedHistory: json['updatedHistory'] ?? {},
      fileLink: json['fileLink'] ?? '',
    );
  }
}

class StoredBillResponse {
  final String billId;
  final String billNumber;
  final int billNo;
  final String patientId;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final DateTime storedAt;

  const StoredBillResponse({
    required this.billId,
    required this.billNumber,
    required this.billNo,
    required this.patientId,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.storedAt,
  });

  factory StoredBillResponse.fromJson(Map<String, dynamic> json) {
    return StoredBillResponse(
      billId: json['billId'] ?? '',
      billNumber: json['billNumber'] ?? '',
      billNo: json['billNo'] ?? 0,
      patientId: json['patientId'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      paymentStatus: json['paymentStatus'] ?? '',
      storedAt: DateTime.tryParse(json['storedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

// State Providers
final ipdBillStateProvider =
    StateNotifierProvider.family<IpdBillNotifier, IpdBillState, String>(
  (ref, patientId) => IpdBillNotifier(patientId),
);

class IpdBillState {
  final String patientId;
  final List<ChargeItem> charges;
  final List<CustomChargeItem> customCharges;
  final double discount;
  final double advance;
  final bool isLoading;
  final String? error;
  final GeneratedBillResponse? generatedBill;
  final bool showPreview;
  final bool isGeneratingReceipt;
  final IpdReceiptResponse? generatedReceipt;
  final double receiptAmount;
  final double amountPaid;
  final bool isStoringBill;
  final StoredBillResponse? storedBill;

  const IpdBillState({
    required this.patientId,
    required this.charges,
    required this.customCharges,
    this.discount = 0,
    this.advance = 0,
    this.isLoading = false,
    this.error,
    this.generatedBill,
    this.showPreview = false,
    this.isGeneratingReceipt = false,
    this.generatedReceipt,
    this.receiptAmount = 0,
    this.amountPaid = 0,
    this.isStoringBill = false,
    this.storedBill,
  });

  IpdBillState copyWith({
    String? patientId,
    List<ChargeItem>? charges,
    List<CustomChargeItem>? customCharges,
    double? discount,
    double? advance,
    bool? isLoading,
    String? error,
    GeneratedBillResponse? generatedBill,
    bool clearGeneratedBill = false,
    bool? showPreview,
    bool? isGeneratingReceipt,
    IpdReceiptResponse? generatedReceipt,
    bool clearGeneratedReceipt = false,
    double? receiptAmount,
    double? amountPaid,
    bool? isStoringBill,
    StoredBillResponse? storedBill,
    bool clearStoredBill = false,
  }) {
    return IpdBillState(
      patientId: patientId ?? this.patientId,
      charges: charges ?? this.charges,
      customCharges: customCharges ?? this.customCharges,
      discount: discount ?? this.discount,
      advance: advance ?? this.advance,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      generatedBill:
          clearGeneratedBill ? null : (generatedBill ?? this.generatedBill),
      showPreview: showPreview ?? this.showPreview,
      isGeneratingReceipt: isGeneratingReceipt ?? this.isGeneratingReceipt,
      generatedReceipt: clearGeneratedReceipt
          ? null
          : (generatedReceipt ?? this.generatedReceipt),
      receiptAmount: receiptAmount ?? this.receiptAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      isStoringBill: isStoringBill ?? this.isStoringBill,
      storedBill: clearStoredBill ? null : (storedBill ?? this.storedBill),
    );
  }

  double get totalCharges {
    double total = charges
        .where((c) => c.isActive)
        .fold(0, (sum, item) => sum + item.total);
    total += customCharges.fold(0, (sum, item) => sum + item.total);
    return total;
  }

  double get finalAmount => totalCharges - discount - advance;
}

class IpdBillNotifier extends StateNotifier<IpdBillState> {
  IpdBillNotifier(String patientId)
      : super(IpdBillState(
          patientId: patientId,
          charges: _getDefaultCharges(),
          customCharges: [],
        ));

  static List<ChargeItem> _getDefaultCharges() {
    return [
      const ChargeItem(
          key: 'admissionFees',
          displayName: 'Admission Fees',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'icuCharges', displayName: 'ICU Charges', rate: 0, days: 1),
      const ChargeItem(
          key: 'specialCharges',
          displayName: 'Special Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'generalWardCharges',
          displayName: 'General Ward Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'surgeonCharges',
          displayName: 'Surgeon Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'assistantSurgeonCharges',
          displayName: 'Assistant Surgeon Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'operationTheatreCharges',
          displayName: 'Operation Theatre Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'operationTheatreMedicines',
          displayName: 'OT Medicines',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'anaesthesiaCharges',
          displayName: 'Anaesthesia Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'localAnaesthesiaCharges',
          displayName: 'Local Anaesthesia Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'o2Charges', displayName: 'Oxygen Charges', rate: 0, days: 1),
      const ChargeItem(
          key: 'monitorCharges',
          displayName: 'Monitor Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'tapping', displayName: 'Tapping', rate: 0, days: 1),
      const ChargeItem(
          key: 'ventilatorCharges',
          displayName: 'Ventilator Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'emergencyCharges',
          displayName: 'Emergency Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'micCharges', displayName: 'MIC Charges', rate: 0, days: 1),
      const ChargeItem(
          key: 'ivFluids', displayName: 'IV Fluids', rate: 0, days: 1),
      const ChargeItem(
          key: 'bloodTransfusionCharges',
          displayName: 'Blood Transfusion Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'physioTherapyCharges',
          displayName: 'Physiotherapy Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'xrayFilmCharges',
          displayName: 'X-Ray Film Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'ecgCharges', displayName: 'ECG Charges', rate: 0, days: 1),
      const ChargeItem(
          key: 'specialVisitCharges',
          displayName: 'Special Visit Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'doctorCharges',
          displayName: 'Doctor Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'nursingCharges',
          displayName: 'Nursing Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'injMedicines',
          displayName: 'Injectable Medicines',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'catheterCharges',
          displayName: 'Catheter Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'rylesTubeCharges',
          displayName: 'Ryles Tube Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'miscellaneousCharges',
          displayName: 'Miscellaneous Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'dressingCharges',
          displayName: 'Dressing Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'professionalCharges',
          displayName: 'Professional Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'serviceTaxCharges',
          displayName: 'Service Tax Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'tractionCharges',
          displayName: 'Traction Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'gastricLavageCharges',
          displayName: 'Gastric Lavage Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'plateletCharges',
          displayName: 'Platelet Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'nebulizerCharges',
          displayName: 'Nebulizer Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'implantCharges',
          displayName: 'Implant Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'physicianCharges',
          displayName: 'Physician Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'slabCastCharges',
          displayName: 'Slab Cast Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'mrfCharges', displayName: 'MRF Charges', rate: 0, days: 1),
      const ChargeItem(
          key: 'procCharges',
          displayName: 'Procedure Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'staplingCharges',
          displayName: 'Stapling Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'enemaCharges', displayName: 'Enema Charges', rate: 0, days: 1),
      const ChargeItem(
          key: 'gastroscopyCharges',
          displayName: 'Gastroscopy Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'endoscopicCharges',
          displayName: 'Endoscopic Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'velixCharges', displayName: 'Velix Charges', rate: 0, days: 1),
      const ChargeItem(
          key: 'bslCharges', displayName: 'BSL Charges', rate: 0, days: 1),
      const ChargeItem(
          key: 'icdtCharges', displayName: 'ICDT Charges', rate: 0, days: 1),
      const ChargeItem(
          key: 'ophthalmologistCharges',
          displayName: 'Ophthalmologist Charges',
          rate: 0,
          days: 1),
      // NEW: Add the new fixed charges
      const ChargeItem(
          key: 'pharmacyCharges',
          displayName: 'Pharmacy Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'pathologyCharges',
          displayName: 'Pathology Charges',
          rate: 0,
          days: 1),
      const ChargeItem(
          key: 'otherCharges', displayName: 'Other Charges', rate: 0, days: 1),
    ];
  }

  void updateCharge(int index, {double? rate, int? days, bool? isActive}) {
    if (index < 0 || index >= state.charges.length) return;

    final updatedCharges = List<ChargeItem>.from(state.charges);
    updatedCharges[index] = updatedCharges[index].copyWith(
      rate: rate,
      days: days,
      isActive: isActive,
    );

    state = state.copyWith(charges: updatedCharges);
  }

  void addCustomCharge() {
    final newCustomCharge = CustomChargeItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: '',
      rate: 0,
      days: 1,
    );

    final updatedCustomCharges =
        List<CustomChargeItem>.from(state.customCharges)..add(newCustomCharge);

    state = state.copyWith(customCharges: updatedCustomCharges);
  }

  void updateCustomCharge(int index,
      {String? description, double? rate, int? days}) {
    if (index < 0 || index >= state.customCharges.length) return;

    final updatedCustomCharges =
        List<CustomChargeItem>.from(state.customCharges);
    updatedCustomCharges[index] = updatedCustomCharges[index].copyWith(
      description: description,
      rate: rate,
      days: days,
    );

    state = state.copyWith(customCharges: updatedCustomCharges);
  }

  void removeCustomCharge(int index) {
    if (index < 0 || index >= state.customCharges.length) return;

    final updatedCustomCharges =
        List<CustomChargeItem>.from(state.customCharges)..removeAt(index);

    state = state.copyWith(customCharges: updatedCustomCharges);
  }

  void updateDiscount(double discount) {
    state = state.copyWith(discount: discount);
  }

  void updateAdvance(double advance) {
    state = state.copyWith(advance: advance);
  }

  void updateReceiptAmount(double amount) {
    state = state.copyWith(receiptAmount: amount);
  }

  void updateAmountPaid(double amount) {
    state = state.copyWith(amountPaid: amount);
  }

  void togglePreview() {
    state = state.copyWith(showPreview: !state.showPreview);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  String? validateCharges() {
    final activeCharges = state.charges.where((c) => c.isActive).toList();
    final validCustomCharges = state.customCharges
        .where((c) => c.description.isNotEmpty && c.rate > 0)
        .toList();

    if (activeCharges.isEmpty && validCustomCharges.isEmpty) {
      return 'Please select at least one charge item or add a custom charge';
    }

    final chargesWithoutRate = activeCharges.where((c) => c.rate <= 0).toList();
    if (chargesWithoutRate.isNotEmpty) {
      final invalidItems =
          chargesWithoutRate.map((c) => c.displayName).take(3).join(', ');
      final additionalCount = chargesWithoutRate.length - 3;
      return 'Selected charges must have valid rates. Items without rates: $invalidItems${additionalCount > 0 ? ' and ${additionalCount} more' : ''}';
    }

    final invalidCustomCharges = state.customCharges
        .where((c) => c.description.isNotEmpty && c.rate <= 0)
        .toList();
    if (invalidCustomCharges.isNotEmpty) {
      return 'Custom charges must have valid rates and descriptions';
    }

    return null;
  }

  Future<void> generateBill() async {
    final validationError = validateCharges();
    if (validationError != null) {
      state = state.copyWith(error: validationError);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final activeCharges = <String, Map<String, dynamic>>{};
      for (final charge in state.charges) {
        if (charge.isActive && charge.total > 0) {
          activeCharges[charge.key] = charge.toJson();
        }
      }

      final customCharges = state.customCharges
          .where((c) => c.description.isNotEmpty && c.rate > 0)
          .map((c) => c.toJson())
          .toList();

      final requestBody = {
        'charges': activeCharges,
        'customCharges': customCharges,
        'discount': state.discount,
        'advance': state.advance,
      };

      final response = await http.post(
        Uri.parse('${KVM_URL}/reception/generateIpdBill/${state.patientId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final generatedBill = GeneratedBillResponse.fromJson(responseData);

          state = state.copyWith(
            isLoading: false,
            generatedBill: generatedBill,
            receiptAmount: generatedBill.billSummary.finalAmount,
            amountPaid: generatedBill.billSummary.finalAmount,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: responseData['message'] ?? 'Failed to generate bill',
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to generate bill: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error generating bill: $e',
      );
    }
  }

  Future<void> storeBill() async {
    if (state.generatedBill == null) {
      state = state.copyWith(error: 'No bill generated to store');
      return;
    }

    state = state.copyWith(isStoringBill: true, error: null);

    try {
      final requestBody = {
        'billData': state.generatedBill!.billData,
      };

      final response = await http.post(
        Uri.parse('${KVM_URL}/reception/storeIpdBill'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final storedBill = StoredBillResponse.fromJson(responseData['data']);
          state = state.copyWith(
            isStoringBill: false,
            storedBill: storedBill,
          );
        } else {
          state = state.copyWith(
            isStoringBill: false,
            error: responseData['message'] ?? 'Failed to store bill',
          );
        }
      } else {
        final errorData = json.decode(response.body);
        state = state.copyWith(
          isStoringBill: false,
          error: errorData['message'] ??
              'Failed to store bill: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isStoringBill: false,
        error: 'Error storing bill: $e',
      );
    }
  }

  Future<void> generateReceipt() async {
    if (state.receiptAmount <= 0) {
      state = state.copyWith(error: 'Please enter a valid billing amount');
      return;
    }

    if (state.amountPaid < 0) {
      state = state.copyWith(error: 'Amount paid cannot be negative');
      return;
    }

    state = state.copyWith(isGeneratingReceipt: true, error: null);

    try {
      final requestBody = {
        'patientId': state.patientId,
        'billingAmount': state.receiptAmount.toString(),
        'amountPaid': state.amountPaid.toString(),
      };

      final response = await http.post(
        Uri.parse('${KVM_URL}/reception/generateOpdReceipt'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final generatedReceipt = IpdReceiptResponse.fromJson(responseData);

        state = state.copyWith(
          isGeneratingReceipt: false,
          generatedReceipt: generatedReceipt,
        );
      } else {
        state = state.copyWith(
          isGeneratingReceipt: false,
          error: 'Failed to generate receipt: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isGeneratingReceipt: false,
        error: 'Error generating receipt: $e',
      );
    }
  }

  void reset() {
    state = IpdBillState(
      patientId: state.patientId,
      charges: _getDefaultCharges(),
      customCharges: [],
    );
  }
}

// Main Screen Widget
class GenerateIpdBillScreen extends ConsumerStatefulWidget {
  final String patientId;

  const GenerateIpdBillScreen({
    super.key,
    required this.patientId,
  });

  @override
  ConsumerState<GenerateIpdBillScreen> createState() =>
      _GenerateIpdBillScreenState();
}

class _GenerateIpdBillScreenState extends ConsumerState<GenerateIpdBillScreen> {
  final _scrollController = ScrollController();
  final _discountController = TextEditingController();
  final _advanceController = TextEditingController();
  final _receiptAmountController = TextEditingController();
  final _amountPaidController = TextEditingController();

  // Controllers for custom charges
  final List<TextEditingController> _customDescriptionControllers = [];
  final List<TextEditingController> _customRateControllers = [];
  final List<TextEditingController> _customDaysControllers = [];

  @override
  void dispose() {
    _scrollController.dispose();
    _discountController.dispose();
    _advanceController.dispose();
    _receiptAmountController.dispose();
    _amountPaidController.dispose();

    // Dispose custom charge controllers
    for (final controller in _customDescriptionControllers) {
      controller.dispose();
    }
    for (final controller in _customRateControllers) {
      controller.dispose();
    }
    for (final controller in _customDaysControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final state = ref.watch(ipdBillStateProvider(widget.patientId));
    final notifier = ref.read(ipdBillStateProvider(widget.patientId).notifier);

    // Update receipt amount controller when bill is generated
    if (state.generatedBill != null && _receiptAmountController.text.isEmpty) {
      _receiptAmountController.text = state.receiptAmount.toString();
      _amountPaidController.text = state.amountPaid.toString();
    }

    // Sync custom charge controllers
    _ensureCustomChargeControllers(state.customCharges.length);

    return PdfViewerWidget(
      primaryColor: HospitalTheme.primary,
      appBarTitle: 'IPD Bill Preview',
      child: Scaffold(
        backgroundColor: HospitalTheme.background,
        appBar: HospitalTheme.buildAppBar(
          context: context,
          title: 'Generate IPD Bill - ${widget.patientId}',
          actions: [
            IconButton(
              icon: Icon(
                state.showPreview ? Icons.edit : Icons.preview,
                color: Colors.white,
              ),
              onPressed: () => notifier.togglePreview(),
              tooltip: state.showPreview ? 'Edit Bill' : 'Preview Bill',
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
                notifier.generateBill(),
            const SingleActivator(LogicalKeyboardKey.keyP, control: true): () =>
                notifier.togglePreview(),
            const SingleActivator(LogicalKeyboardKey.keyR, control: true): () =>
                notifier.generateReceipt(),
            const SingleActivator(LogicalKeyboardKey.f5): () =>
                notifier.reset(),
            const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
                notifier.storeBill(),
          },
          child: Focus(
            autofocus: true,
            child: _buildBody(context, size, state, notifier),
          ),
        ),
      ),
    );
  }

  // FIXED: Ensure controllers match the number of custom charges
  void _ensureCustomChargeControllers(int requiredCount) {
    // Add controllers if needed
    while (_customDescriptionControllers.length < requiredCount) {
      _customDescriptionControllers.add(TextEditingController());
      _customRateControllers.add(TextEditingController());
      _customDaysControllers.add(TextEditingController(text: '1'));
    }

    // Remove excess controllers
    while (_customDescriptionControllers.length > requiredCount) {
      _customDescriptionControllers.removeLast().dispose();
      _customRateControllers.removeLast().dispose();
      _customDaysControllers.removeLast().dispose();
    }
  }

  // Add custom charge method
  void _addCustomCharge() {
    final notifier = ref.read(ipdBillStateProvider(widget.patientId).notifier);
    notifier.addCustomCharge();
  }

  // Remove custom charge method
  void _removeCustomCharge(int index) {
    final notifier = ref.read(ipdBillStateProvider(widget.patientId).notifier);
    notifier.removeCustomCharge(index);
  }

  Widget _buildBody(BuildContext context, Size size, IpdBillState state,
      IpdBillNotifier notifier) {
    if (state.generatedBill != null) {
      return _buildGeneratedBillView(context, size, state, notifier);
    }

    if (state.showPreview) {
      return _buildPreviewView(context, size, state, notifier);
    }

    return _buildEditView(context, size, state, notifier);
  }

  Widget _buildEditView(BuildContext context, Size size, IpdBillState state,
      IpdBillNotifier notifier) {
    final isWideScreen = size.width > 1200;

    return Row(
      children: [
        // Main content
        Expanded(
          flex: isWideScreen ? 3 : 1,
          child: _buildChargesSection(context, size, state, notifier),
        ),

        // Sidebar for summary
        if (isWideScreen) ...[
          const SizedBox(width: 16),
          SizedBox(
            width: 320,
            child: _buildSummarySection(context, state, notifier),
          ),
        ],
      ],
    );
  }

  Widget _buildChargesSection(BuildContext context, Size size,
      IpdBillState state, IpdBillNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader(
            'Medical Charges',
            trailing: Text(
              'Active: ${state.charges.where((c) => c.isActive).length}/${state.charges.length} + ${state.customCharges.where((c) => c.description.isNotEmpty && c.rate > 0).length} custom',
              style: TextStyle(
                color: HospitalTheme.textMedium,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Card(
              color: HospitalTheme.background,
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: HospitalTheme.surfaceLight,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 40),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Service',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Rate',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Days',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(width: 40), // Space for actions
                      ],
                    ),
                  ),

                  // Charges list
                  Expanded(
                    child: Scrollbar(
                      controller: _scrollController,
                      child: ListView(
                        controller: _scrollController,
                        children: [
                          // Regular charges
                          ...state.charges.asMap().entries.map((entry) {
                            final index = entry.key;
                            final charge = entry.value;
                            return _buildChargeRow(
                                context, charge, index, notifier);
                          }),

                          // Divider for custom charges
                          if (state.customCharges.isNotEmpty) ...[
                            const Divider(height: 1),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: HospitalTheme.info.withOpacity(0.1),
                                border: const Border(
                                  bottom:
                                      BorderSide(color: HospitalTheme.border),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.add_circle,
                                      color: HospitalTheme.info, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Custom Charges',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: HospitalTheme.info,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Custom charges
                          ...state.customCharges.asMap().entries.map((entry) {
                            final index = entry.key;
                            final charge = entry.value;
                            return _buildCustomChargeRow(
                                context, charge, index, notifier);
                          }),

                          // Add custom charge button
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: HospitalTheme.border),
                              ),
                            ),
                            child: Center(
                              child: OutlinedButton.icon(
                                onPressed: _addCustomCharge,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Custom Charge'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: HospitalTheme.primary,
                                  side:
                                      BorderSide(color: HospitalTheme.primary),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (MediaQuery.of(context).size.width <= 1200) ...[
            const SizedBox(height: 16),
            _buildSummarySection(context, state, notifier),
          ],
        ],
      ),
    );
  }

  Widget _buildChargeRow(BuildContext context, ChargeItem charge, int index,
      IpdBillNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: charge.isActive
            ? HospitalTheme.surfaceLight.withOpacity(0.3)
            : null,
        border: const Border(
          bottom: BorderSide(color: HospitalTheme.border),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Checkbox
          SizedBox(
            width: 40,
            child: Checkbox(
              value: charge.isActive,
              onChanged: (value) =>
                  notifier.updateCharge(index, isActive: value),
            ),
          ),

          // Service name
          Expanded(
            flex: 3,
            child: Text(
              charge.displayName,
              style: TextStyle(
                fontWeight:
                    charge.isActive ? FontWeight.w600 : FontWeight.normal,
                color: charge.isActive
                    ? HospitalTheme.textDark
                    : HospitalTheme.primaryLight,
              ),
            ),
          ),

          // Rate input
          Expanded(
            child: _buildNumberInput(
              value: charge.rate,
              enabled: charge.isActive,
              onChanged: (value) => notifier.updateCharge(index, rate: value),
              prefix: '₹',
            ),
          ),

          // Days input
          Expanded(
            child: _buildNumberInput(
              value: charge.days.toDouble(),
              enabled: charge.isActive,
              onChanged: (value) =>
                  notifier.updateCharge(index, days: value.toInt()),
              isInteger: true,
            ),
          ),

          // Total
          Expanded(
            child: Text(
              '₹${charge.total.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: charge.isActive
                    ? HospitalTheme.primary
                    : HospitalTheme.textLight,
              ),
            ),
          ),

          // Actions placeholder (to align with custom charges)
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // FIXED: Custom charge row widget
  Widget _buildCustomChargeRow(BuildContext context, CustomChargeItem charge,
      int index, IpdBillNotifier notifier) {
    // Ensure we have controllers for this index
    if (index >= _customDescriptionControllers.length) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: charge.description.isNotEmpty && charge.rate > 0
            ? HospitalTheme.success.withOpacity(0.1)
            : HospitalTheme.warning.withOpacity(0.1),
        border: const Border(
          bottom: BorderSide(color: HospitalTheme.border),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Custom indicator
          SizedBox(
            width: 40,
            child: Icon(
              Icons.star,
              color: charge.description.isNotEmpty && charge.rate > 0
                  ? HospitalTheme.success
                  : HospitalTheme.warning,
              size: 16,
            ),
          ),

          // Description input
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: _customDescriptionControllers[index],
              decoration: const InputDecoration(
                hintText: 'Enter service description',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: (value) =>
                  notifier.updateCustomCharge(index, description: value),
            ),
          ),
          const SizedBox(width: 8),

          // Rate input
          Expanded(
            child: TextFormField(
              controller: _customRateControllers[index],
              decoration: const InputDecoration(
                prefixText: '₹',
                hintText: '0.00',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
              onChanged: (value) {
                final rate = double.tryParse(value) ?? 0.0;
                notifier.updateCustomCharge(index, rate: rate);
              },
            ),
          ),
          const SizedBox(width: 8),

          // Days input
          Expanded(
            child: TextFormField(
              controller: _customDaysControllers[index],
              decoration: const InputDecoration(
                hintText: '1',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
              onChanged: (value) {
                final days = int.tryParse(value) ?? 1;
                notifier.updateCustomCharge(index, days: days);
              },
            ),
          ),
          const SizedBox(width: 8),

          // Total
          Expanded(
            child: Text(
              '₹${charge.total.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: charge.description.isNotEmpty && charge.rate > 0
                    ? HospitalTheme.success
                    : HospitalTheme.textLight,
              ),
            ),
          ),

          // Delete button
          SizedBox(
            width: 40,
            child: IconButton(
              icon: Icon(Icons.delete, color: HospitalTheme.error, size: 18),
              onPressed: () => _removeCustomCharge(index),
              tooltip: 'Remove custom charge',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInput({
    required double value,
    required bool enabled,
    required Function(double) onChanged,
    String? prefix,
    bool isInteger = false,
  }) {
    return Container(
      width: 80,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: TextFormField(
        initialValue: value == 0
            ? ''
            : (isInteger ? value.toInt().toString() : value.toString()),
        enabled: enabled,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          prefixText: prefix,
          prefixStyle: const TextStyle(fontSize: 12),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: HospitalTheme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: HospitalTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: HospitalTheme.primary),
          ),
        ),
        onChanged: (text) {
          final parsed = double.tryParse(text) ?? 0.0;
          onChanged(parsed);
        },
      ),
    );
  }

  Widget _buildSummarySection(
      BuildContext context, IpdBillState state, IpdBillNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('Bill Summary'),

          HospitalTheme.buildCard(
            child: Column(
              children: [
                _buildSummaryRow('Total Charges',
                    '₹${state.totalCharges.toStringAsFixed(2)}'),
                const Divider(),

                // Discount input
                Row(
                  children: [
                    const Expanded(child: Text('Discount')),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        controller: _discountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(
                          prefixText: '₹',
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (value) {
                          final discount = double.tryParse(value) ?? 0.0;
                          notifier.updateDiscount(discount);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Advance input
                Row(
                  children: [
                    const Expanded(child: Text('Advance Paid')),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        controller: _advanceController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(
                          prefixText: '₹',
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (value) {
                          final advance = double.tryParse(value) ?? 0.0;
                          notifier.updateAdvance(advance);
                        },
                      ),
                    ),
                  ],
                ),

                const Divider(),
                _buildSummaryRow(
                  'Final Amount',
                  '₹${state.finalAmount.toStringAsFixed(2)}',
                  isTotal: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed:
                      state.isLoading ? null : () => notifier.togglePreview(),
                  icon: const Icon(Icons.preview),
                  label: const Text('Preview Bill'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed:
                      state.isLoading ? null : () => notifier.generateBill(),
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.receipt_long),
                  label:
                      Text(state.isLoading ? 'Generating...' : 'Generate Bill'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HospitalTheme.success,
                  ),
                ),
              ),
            ],
          ),

          // Keyboard shortcuts hint
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HospitalTheme.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: HospitalTheme.info.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keyboard Shortcuts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.info,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ctrl+P: Preview\nCtrl+S: Generate Bill\nCtrl+R: Generate Receipt\nCtrl+F: Store Final Bill\nF5: Reset',
                  style: TextStyle(
                    color: HospitalTheme.textMedium,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          if (state.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HospitalTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: HospitalTheme.error),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: HospitalTheme.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: TextStyle(
                        color: HospitalTheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => notifier.clearError(),
                    icon:
                        Icon(Icons.close, size: 16, color: HospitalTheme.error),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color:
                  isTotal ? HospitalTheme.textDark : HospitalTheme.textMedium,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? HospitalTheme.primary : HospitalTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewView(BuildContext context, Size size, IpdBillState state,
      IpdBillNotifier notifier) {
    final activeCharges =
        state.charges.where((c) => c.isActive && c.total > 0).toList();
    final validCustomCharges = state.customCharges
        .where((c) => c.description.isNotEmpty && c.rate > 0)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HospitalTheme.buildSectionHeader('Bill Preview'),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => notifier.togglePreview(),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Bill'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed:
                    state.isLoading ? null : () => notifier.generateBill(),
                icon: state.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.receipt_long),
                label: Text(
                    state.isLoading ? 'Generating...' : 'Generate Final Bill'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HospitalTheme.success,
                ),
              ),
            ],
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preview content
                Expanded(
                  flex: 2,
                  child: HospitalTheme.buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: HospitalTheme.primary.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.receipt_long,
                                      color: HospitalTheme.primary, size: 28),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'IPD Discharge Bill',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: HospitalTheme.primary,
                                        ),
                                      ),
                                      Text(
                                        'Patient ID: ${state.patientId}',
                                        style: TextStyle(
                                          color: HospitalTheme.textMedium,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Date: ${DateTime.now().toString().split(' ')[0]}',
                                    style: TextStyle(
                                      color: HospitalTheme.textMedium,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Charges table
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Medical Charges',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: HospitalTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Table header
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: HospitalTheme.surfaceLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Expanded(
                                          flex: 3,
                                          child: Text('Description',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      Expanded(
                                          child: Text('Rate',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center)),
                                      Expanded(
                                          child: Text('Days',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center)),
                                      Expanded(
                                          child: Text('Amount',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.right)),
                                    ],
                                  ),
                                ),

                                // Table rows
                                Expanded(
                                  child: ListView(
                                    children: [
                                      // Regular charges
                                      ...activeCharges.map((charge) {
                                        return Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: const BoxDecoration(
                                            border: Border(
                                                bottom: BorderSide(
                                                    color:
                                                        HospitalTheme.border)),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: Text(charge.displayName,
                                                    style: const TextStyle(
                                                        fontSize: 14)),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  '₹${charge.rate.toStringAsFixed(2)}',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  '${charge.days}',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  '₹${charge.total.toStringAsFixed(2)}',
                                                  textAlign: TextAlign.right,
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),

                                      // Custom charges
                                      ...validCustomCharges.map((charge) {
                                        return Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: HospitalTheme.success
                                                .withOpacity(0.05),
                                            border: const Border(
                                                bottom: BorderSide(
                                                    color:
                                                        HospitalTheme.border)),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.star,
                                                        color: HospitalTheme
                                                            .success,
                                                        size: 16),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                          charge.description,
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  HospitalTheme
                                                                      .success,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  '₹${charge.rate.toStringAsFixed(2)}',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  '${charge.days}',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  '₹${charge.total.toStringAsFixed(2)}',
                                                  textAlign: TextAlign.right,
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: HospitalTheme
                                                          .success),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Summary sidebar
                SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      HospitalTheme.buildCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bill Summary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: HospitalTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSummaryRow('Subtotal',
                                '₹${state.totalCharges.toStringAsFixed(2)}'),
                            _buildSummaryRow('Discount',
                                '-₹${state.discount.toStringAsFixed(2)}'),
                            _buildSummaryRow('Advance Paid',
                                '-₹${state.advance.toStringAsFixed(2)}'),
                            const Divider(height: 24),
                            _buildSummaryRow('Final Amount',
                                '₹${state.finalAmount.toStringAsFixed(2)}',
                                isTotal: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      HospitalTheme.buildCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Charges Summary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: HospitalTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Regular Items:',
                                    style: TextStyle(
                                        color: HospitalTheme.textMedium)),
                                Text('${activeCharges.length}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Custom Items:',
                                    style: TextStyle(
                                        color: HospitalTheme.textMedium)),
                                Text('${validCustomCharges.length}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: HospitalTheme.success)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Services:',
                                    style: TextStyle(
                                        color: HospitalTheme.textMedium)),
                                Text(
                                    '${activeCharges.length + validCustomCharges.length}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (state.error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: HospitalTheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: HospitalTheme.error),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: HospitalTheme.error, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.error!,
                                  style: TextStyle(
                                    color: HospitalTheme.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => notifier.clearError(),
                                icon: Icon(Icons.close,
                                    size: 16, color: HospitalTheme.error),
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
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedBillView(BuildContext context, Size size,
      IpdBillState state, IpdBillNotifier notifier) {
    final bill = state.generatedBill!;

    return Row(
      children: [
        // Left Panel - Bill Details
        Expanded(
          flex: 3,
          child: _buildBillDetailsPanel(context, state, notifier),
        ),

        // Divider
        Container(
          width: 1,
          color: HospitalTheme.border,
        ),

        // Right Panel - Receipt and Actions
        Expanded(
          flex: 2,
          child: _buildRightPanel(context, state, notifier),
        ),
      ],
    );
  }

  Widget _buildBillDetailsPanel(
      BuildContext context, IpdBillState state, IpdBillNotifier notifier) {
    final bill = state.generatedBill!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: HospitalTheme.success, size: 28),
              const SizedBox(width: 12),
              Text(
                'Bill Generated Successfully',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.success,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => notifier.reset(),
                icon: const Icon(Icons.refresh),
                label: const Text('Generate Another Bill'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          HospitalTheme.buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: HospitalTheme.success.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long,
                          color: HospitalTheme.success, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bill Generated',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: HospitalTheme.success,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'File: ${bill.fileName}',
                              style: TextStyle(
                                color: HospitalTheme.textMedium,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Generated: ${bill.generatedAt.toString().split('.')[0]}',
                              style: TextStyle(
                                color: HospitalTheme.textMedium,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: HospitalTheme.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: HospitalTheme.info),
                        ),
                        child: Text(
                          '${(bill.pdfSize / 1024).toStringAsFixed(1)} KB',
                          style: TextStyle(
                            color: HospitalTheme.info,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient Info
                      _buildInfoSection(
                        'Patient Information',
                        [
                          'Name: ${bill.patientInfo['name'] ?? 'N/A'}',
                          'Patient ID: ${bill.patientInfo['patientId'] ?? 'N/A'}',
                          'Age: ${bill.patientInfo['age'] ?? 'N/A'}',
                          'Gender: ${bill.patientInfo['gender'] ?? 'N/A'}',
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Admission Details
                      _buildInfoSection(
                        'Admission Details',
                        [
                          'Admission ID: ${bill.admissionDetails['admissionId'] ?? 'N/A'}',
                          'Admission Date: ${_formatDate(bill.admissionDetails['admissionDate'])}',
                          'Discharge Date: ${_formatDate(bill.admissionDetails['dischargeDate'])}',
                          'Length of Stay: ${bill.admissionDetails['lengthOfStay'] ?? 'N/A'} days',
                          'Attending Doctor: ${bill.admissionDetails['attendingDoctor'] ?? 'N/A'}',
                          'Department: ${bill.admissionDetails['department'] ?? 'N/A'}',
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Download Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: HospitalTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: HospitalTheme.primary.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.cloud_download,
                                    color: HospitalTheme.primary),
                                const SizedBox(width: 12),
                                Text(
                                  'Download Bill',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: HospitalTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        Methods().openPdf(bill.driveLink),
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text('Open PDF'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: HospitalTheme.success,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _openPdfPreview(state, 'bill'),
                                    icon: const Icon(Icons.preview),
                                    label: const Text('Preview & Print'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: HospitalTheme.warning,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel(
      BuildContext context, IpdBillState state, IpdBillNotifier notifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bill Summary
          _buildBillSummarySection(state),

          const SizedBox(height: 24),

          // PDF Status
          const PdfStatusBar(),

          // Bill Response Section - Always show if bill exists
          if (state.generatedBill != null) ...[
            const SizedBox(height: 24),
            _buildGeneratedBillSection(state, notifier),
          ],

          // Store Bill Section - Show if bill exists but not stored yet
          if (state.generatedBill != null && state.storedBill == null) ...[
            const SizedBox(height: 24),
            _buildStoreBillSection(state, notifier),
          ],

          // Stored Bill Section - Show if bill is stored
          if (state.storedBill != null) ...[
            const SizedBox(height: 24),
            _buildStoredBillSection(state),
          ],

          // Receipt Generation Section - Show if bill exists and is stored
          if (state.generatedBill != null && state.storedBill != null) ...[
            const SizedBox(height: 24),
            _buildReceiptGenerationSection(state, notifier),
          ],

          // Receipt Response Section - Show if receipt exists
          if (state.generatedReceipt != null) ...[
            const SizedBox(height: 24),
            _buildReceiptGeneratedSection(context, state),
          ],
        ],
      ),
    );
  }

  Widget _buildBillSummarySection(IpdBillState state) {
    final bill = state.generatedBill!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HospitalTheme.buildSectionHeader('Final Bill Summary'),
        HospitalTheme.buildCard(
          child: Column(
            children: [
              _buildSummaryRow('Total Charges',
                  '₹${bill.billSummary.totalCharges.toStringAsFixed(2)}'),
              _buildSummaryRow('Discount Applied',
                  '-₹${bill.billSummary.discount.toStringAsFixed(2)}'),
              _buildSummaryRow('Advance Paid',
                  '-₹${bill.billSummary.advance.toStringAsFixed(2)}'),
              const Divider(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HospitalTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: HospitalTheme.success.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Amount Due',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.success,
                      ),
                    ),
                    Text(
                      '₹${bill.billSummary.finalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratedBillSection(
      IpdBillState state, IpdBillNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HospitalTheme.buildSectionHeader('Generated Bill'),
        HospitalTheme.buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: HospitalTheme.success),
                  const SizedBox(width: 8),
                  const Text(
                    'Bill Generated Successfully!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow('File Name', state.generatedBill!.fileName),
              _buildInfoRow('Generated At',
                  state.generatedBill!.generatedAt.toString().split('.')[0]),
              _buildInfoRow('File Size',
                  '${(state.generatedBill!.pdfSize / 1024).toStringAsFixed(1)} KB'),
              const SizedBox(height: 16),

              // Enhanced PDF action buttons with unified preview
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 400) {
                    return Row(
                      children: [
                        Expanded(child: _buildViewPdfButton(state)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildPreviewPdfButton(state, 'bill')),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: _buildViewPdfButton(state),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: _buildPreviewPdfButton(state, 'bill'),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Store Bill Section
  Widget _buildStoreBillSection(IpdBillState state, IpdBillNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HospitalTheme.buildSectionHeader('Store Final Bill'),
        HospitalTheme.buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.save, color: HospitalTheme.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Store Bill in Database',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Review the generated bill and store it permanently in the database. This action will make the bill official and ready for payment processing.',
                style: TextStyle(
                  color: HospitalTheme.textMedium,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              // Show loading state during bill storage
              if (state.isStoringBill) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HospitalTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Storing bill in database, please wait...',
                        style: TextStyle(
                          color: HospitalTheme.textMedium,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      state.isStoringBill ? null : () => notifier.storeBill(),
                  icon: state.isStoringBill
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(state.isStoringBill
                      ? 'Storing Bill...'
                      : 'Generate Final Bill (Ctrl+F)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HospitalTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Note: Once stored, the bill cannot be modified.',
                style: TextStyle(
                  color: HospitalTheme.warning,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Stored Bill Section
  Widget _buildStoredBillSection(IpdBillState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HospitalTheme.buildSectionHeader('Bill Stored Successfully'),
        HospitalTheme.buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: HospitalTheme.success),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Bill Stored in Database!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stored Bill Details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HospitalTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: HospitalTheme.success.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Bill ID', state.storedBill!.billId),
                    _buildInfoRow('Bill Number', state.storedBill!.billNumber),
                    _buildInfoRow(
                        'Bill No.', state.storedBill!.billNo.toString()),
                    _buildInfoRow('Patient ID', state.storedBill!.patientId),
                    _buildInfoRow('Total Amount',
                        '₹${state.storedBill!.totalAmount.toStringAsFixed(2)}'),
                    _buildInfoRow('Status', state.storedBill!.status),
                    _buildInfoRow(
                        'Payment Status', state.storedBill!.paymentStatus),
                    _buildInfoRow('Stored At',
                        _formatDate(state.storedBill!.storedAt.toString())),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HospitalTheme.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: HospitalTheme.info, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Bill has been permanently stored in the database. You can now generate receipt for payment processing.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewPdfButton(IpdBillState state) {
    return OutlinedButton.icon(
      onPressed: () => Methods().openPdf(state.generatedBill!.driveLink),
      icon: const Icon(Icons.open_in_new),
      label: const Text('Open PDF'),
    );
  }

  Widget _buildPreviewPdfButton(IpdBillState state, String type) {
    final url = type == 'bill'
        ? state.generatedBill?.driveLink
        : state.generatedReceipt?.fileLink;
    final title = type == 'bill'
        ? 'Bill - ${state.generatedBill?.fileName ?? ''}'
        : 'Receipt - ${widget.patientId}';

    return ElevatedButton.icon(
      onPressed: () => _openPdfPreview(state, type),
      icon: const Icon(Icons.preview),
      label: const Text('Preview & Print'),
      style: ElevatedButton.styleFrom(
        backgroundColor: HospitalTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildReceiptGenerationSection(
      IpdBillState state, IpdBillNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HospitalTheme.buildSectionHeader('Generate Receipt'),
        HospitalTheme.buildCard(
          child: Column(
            children: [
              TextFormField(
                controller: _receiptAmountController,
                decoration: const InputDecoration(
                  labelText: 'Billing Amount',
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ],
                onChanged: (value) {
                  final amount = double.tryParse(value) ?? 0;
                  notifier.updateReceiptAmount(amount);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountPaidController,
                decoration: const InputDecoration(
                  labelText: 'Amount Paid',
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ],
                onChanged: (value) {
                  final amount = double.tryParse(value) ?? 0;
                  notifier.updateAmountPaid(amount);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Balance: ',
                    style: TextStyle(
                      color: HospitalTheme.textMedium,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '₹${(state.receiptAmount - state.amountPaid).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: (state.receiptAmount - state.amountPaid) > 0
                          ? HospitalTheme.warning
                          : HospitalTheme.success,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Show loading state during receipt generation
              if (state.isGeneratingReceipt) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HospitalTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Generating receipt, please wait...',
                        style: TextStyle(
                          color: HospitalTheme.textMedium,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: state.isGeneratingReceipt
                      ? null
                      : () => _generateReceipt(notifier),
                  icon: state.isGeneratingReceipt
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.receipt),
                  label: Text(state.isGeneratingReceipt
                      ? 'Generating Receipt...'
                      : 'Generate Receipt (Ctrl+R)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HospitalTheme.success,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptGeneratedSection(
      BuildContext context, IpdBillState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HospitalTheme.buildSectionHeader('Receipt Generated'),
        HospitalTheme.buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: HospitalTheme.success),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Receipt Generated Successfully!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                state.generatedReceipt!.message,
                style: TextStyle(
                  color: HospitalTheme.textMedium,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              // Receipt Details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HospitalTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: HospitalTheme.success.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                        'Patient ID',
                        state.generatedReceipt!.updatedPatient['patientId'] ??
                            'N/A'),
                    _buildInfoRow('Last Billing',
                        '₹${state.generatedReceipt!.updatedHistory['lastBillingAmount'] ?? '0'}'),
                    _buildInfoRow('Payment Received',
                        '₹${state.generatedReceipt!.updatedHistory['lastPaymentReceived'] ?? '0'}'),
                    _buildInfoRow('Remaining Amount',
                        '₹${state.generatedReceipt!.updatedHistory['remainingAmount'] ?? '0'}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Enhanced receipt action buttons with unified preview
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 400) {
                    return Row(
                      children: [
                        Expanded(child: _buildViewReceiptButton(state)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildPreviewPdfButton(state, 'receipt')),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: _buildViewReceiptButton(state),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: _buildPreviewPdfButton(state, 'receipt'),
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showSuccessDialog(context),
                  icon: const Icon(Icons.done_all),
                  label: const Text('Complete Billing'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HospitalTheme.success,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewReceiptButton(IpdBillState state) {
    return OutlinedButton.icon(
      onPressed: () => Methods().openPdf(state.generatedReceipt!.fileLink),
      icon: const Icon(Icons.open_in_new),
      label: const Text('Open Receipt'),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: HospitalTheme.textMedium,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: HospitalTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item,
                    style: TextStyle(
                      color: HospitalTheme.textMedium,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString.toString());
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString.toString();
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.check_circle,
          color: HospitalTheme.success,
          size: 48,
        ),
        title: const Text('Billing Complete'),
        content: const Text(
          'IPD billing and receipt generation completed successfully.\n\nWould you like to create another bill or return to the main screen?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Return to Main'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(ipdBillStateProvider(widget.patientId).notifier).reset();
            },
            child: const Text('New Bill'),
          ),
        ],
      ),
    );
  }

  /// Unified PDF preview method that handles both bill and receipt
  void _openPdfPreview(IpdBillState state, [String? type]) {
    String? url;
    String title = 'PDF Document'; // Initialize with default value

    // Determine which PDF to preview based on type or availability
    if (type == 'receipt' && state.generatedReceipt?.fileLink != null) {
      url = state.generatedReceipt!.fileLink;
      title = 'Receipt - ${widget.patientId}';
    } else if (type == 'bill' && state.generatedBill?.driveLink != null) {
      url = state.generatedBill!.driveLink;
      title = 'Bill - ${state.generatedBill!.fileName}';
    } else if (state.generatedReceipt?.fileLink != null) {
      // Default to receipt if available
      url = state.generatedReceipt!.fileLink;
      title = 'Receipt - ${widget.patientId}';
    } else if (state.generatedBill?.driveLink != null) {
      // Fallback to bill if receipt not available
      url = state.generatedBill!.driveLink;
      title = 'Bill - ${state.generatedBill!.fileName}';
    }

    if (url != null && url.isNotEmpty) {
      try {
        final pdfNotifier = ref.read(pdfViewerProvider.notifier);
        pdfNotifier.loadAndShowPdf(url, title: title);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error opening PDF: $e'),
              backgroundColor: HospitalTheme.error,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(type == 'receipt'
                ? 'Receipt not available yet. Please generate receipt first.'
                : 'No PDF available to preview'),
            backgroundColor: HospitalTheme.warning,
          ),
        );
      }
    }
  }

  Future<void> _generateReceipt(IpdBillNotifier notifier) async {
    final state = ref.read(ipdBillStateProvider(widget.patientId));

    if (state.receiptAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid billing amount'),
          backgroundColor: HospitalTheme.warning,
        ),
      );
      return;
    }

    try {
      await notifier.generateReceipt();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Receipt generated successfully!'),
            backgroundColor: HospitalTheme.success,
            action: SnackBarAction(
              label: 'Preview',
              textColor: Colors.white,
              onPressed: () => _openPdfPreview(
                  ref.read(ipdBillStateProvider(widget.patientId)), 'receipt'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate receipt: $e'),
            backgroundColor: HospitalTheme.error,
          ),
        );
      }
    }
  }
}
