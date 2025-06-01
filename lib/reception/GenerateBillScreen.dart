import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  const GeneratedBillResponse({
    required this.fileName,
    required this.driveLink,
    required this.pdfSize,
    required this.generatedAt,
    required this.patientInfo,
    required this.admissionDetails,
    required this.billSummary,
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
    );
  }
}

class OpdReceiptResponse {
  final String message;
  final Map<String, dynamic> updatedPatient;
  final Map<String, dynamic> updatedHistory;
  final String fileLink;

  const OpdReceiptResponse({
    required this.message,
    required this.updatedPatient,
    required this.updatedHistory,
    required this.fileLink,
  });

  factory OpdReceiptResponse.fromJson(Map<String, dynamic> json) {
    return OpdReceiptResponse(
      message: json['message'] ?? '',
      updatedPatient: json['updatedPatient'] ?? {},
      updatedHistory: json['updatedHistory'] ?? {},
      fileLink: json['fileLink'] ?? '',
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
  final double discount;
  final double advance;
  final bool isLoading;
  final String? error;
  final GeneratedBillResponse? generatedBill;
  final bool showPreview;
  final bool isGeneratingReceipt;
  final OpdReceiptResponse? generatedReceipt;
  final double receiptAmount;
  final double amountPaid;

  const IpdBillState({
    required this.patientId,
    required this.charges,
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
  });

  IpdBillState copyWith({
    String? patientId,
    List<ChargeItem>? charges,
    double? discount,
    double? advance,
    bool? isLoading,
    String? error,
    GeneratedBillResponse? generatedBill,
    bool? showPreview,
    bool? isGeneratingReceipt,
    OpdReceiptResponse? generatedReceipt,
    double? receiptAmount,
    double? amountPaid,
  }) {
    return IpdBillState(
      patientId: patientId ?? this.patientId,
      charges: charges ?? this.charges,
      discount: discount ?? this.discount,
      advance: advance ?? this.advance,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      generatedBill: generatedBill ?? this.generatedBill,
      showPreview: showPreview ?? this.showPreview,
      isGeneratingReceipt: isGeneratingReceipt ?? this.isGeneratingReceipt,
      generatedReceipt: generatedReceipt ?? this.generatedReceipt,
      receiptAmount: receiptAmount ?? this.receiptAmount,
      amountPaid: amountPaid ?? this.amountPaid,
    );
  }

  double get totalCharges =>
      charges.where((c) => c.isActive).fold(0, (sum, item) => sum + item.total);
  double get finalAmount => totalCharges - discount - advance;
}

class IpdBillNotifier extends StateNotifier<IpdBillState> {
  IpdBillNotifier(String patientId)
      : super(IpdBillState(
          patientId: patientId,
          charges: _getDefaultCharges(),
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

  // Validation method for charges
  String? validateCharges() {
    final activeCharges = state.charges.where((c) => c.isActive).toList();

    if (activeCharges.isEmpty) {
      return 'Please select at least one charge item';
    }

    final chargesWithoutRate = activeCharges.where((c) => c.rate <= 0).toList();

    if (chargesWithoutRate.isNotEmpty) {
      final invalidItems =
          chargesWithoutRate.map((c) => c.displayName).take(3).join(', ');
      final additionalCount = chargesWithoutRate.length - 3;

      return 'Selected charges must have valid rates. Items without rates: $invalidItems${additionalCount > 0 ? ' and ${additionalCount} more' : ''}';
    }

    return null;
  }

  Future<void> generateBill() async {
    // Validate charges first
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

      final requestBody = {
        'charges': activeCharges,
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

          // Auto-populate receipt amount with final amount from bill
          state = state.copyWith(
            isLoading: false,
            generatedBill: generatedBill,
            receiptAmount: generatedBill.billSummary.finalAmount,
            amountPaid: generatedBill
                .billSummary.finalAmount, // Default to full payment
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
        Uri.parse('${KVM_URL}/reception/generateOpdReceiptx'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final generatedReceipt = OpdReceiptResponse.fromJson(responseData);

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

  @override
  void dispose() {
    _scrollController.dispose();
    _discountController.dispose();
    _advanceController.dispose();
    _receiptAmountController.dispose();
    _amountPaidController.dispose();
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

    return Scaffold(
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
        },
        child: Focus(
          autofocus: true,
          child: _buildBody(context, size, state, notifier),
        ),
      ),
    );
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
              'Active: ${state.charges.where((c) => c.isActive).length}/${state.charges.length}',
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
                    child: Row(
                      children: [
                        const SizedBox(width: 40),
                        const Expanded(
                          flex: 3,
                          child: Text(
                            'Service',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Rate',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Days',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Charges list
                  Expanded(
                    child: Scrollbar(
                      controller: _scrollController,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: state.charges.length,
                        itemBuilder: (context, index) => _buildChargeRow(
                          context,
                          state.charges[index],
                          index,
                          notifier,
                        ),
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
                  'Ctrl+P: Preview\nCtrl+S: Generate Bill\nCtrl+R: Generate Receipt',
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
                                  child: ListView.builder(
                                    itemCount: activeCharges.length,
                                    itemBuilder: (context, index) {
                                      final charge = activeCharges[index];
                                      return Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: const BoxDecoration(
                                          border: Border(
                                              bottom: BorderSide(
                                                  color: HospitalTheme.border)),
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
                                    },
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
                                Text('Total Items:',
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
                                Text('Active Services:',
                                    style: TextStyle(
                                        color: HospitalTheme.textMedium)),
                                Text(
                                    '${state.charges.where((c) => c.isActive).length}',
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

    return Padding(
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
                onPressed: () {
                  // Reset state to start over
                  ref.invalidate(ipdBillStateProvider(widget.patientId));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Generate Another Bill'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Bill details (Scrollable)
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    child: HospitalTheme.buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                    border:
                                        Border.all(color: HospitalTheme.info),
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
                                    color:
                                        HospitalTheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: HospitalTheme.primary
                                            .withOpacity(0.3)),
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
                                      SizedBox(
                                        width: double.infinity,
                                        height: 44,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            // Use Methods().pdfUrl(bill.driveLink) as specified
                                            Methods().openPdf(bill.driveLink);
                                          },
                                          icon: const Icon(Icons.open_in_new),
                                          label: const Text('Open PDF Bill'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                HospitalTheme.success,
                                          ),
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
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Right side - Receipt and Actions (Scrollable)
                SizedBox(
                  width: 300,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        HospitalTheme.buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.account_balance_wallet,
                                      color: HospitalTheme.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Final Bill Summary',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: HospitalTheme.textDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildSummaryRow('Total Charges',
                                  '₹${bill.billSummary.totalCharges.toStringAsFixed(2)}'),
                              _buildSummaryRow('Discount Applied',
                                  '-₹${bill.billSummary.discount.toStringAsFixed(2)}'),
                              _buildSummaryRow('Advance Paid',
                                  '-₹${bill.billSummary.advance.toStringAsFixed(2)}'),
                              const Divider(height: 24),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: HospitalTheme.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: HospitalTheme.success
                                          .withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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

                        const SizedBox(height: 16),

                        // Receipt Generation Section
                        if (state.generatedReceipt == null) ...[
                          HospitalTheme.buildCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.receipt,
                                        color: HospitalTheme.secondary,
                                        size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Generate Receipt',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: HospitalTheme.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Billing Amount
                                Text(
                                  'Billing Amount',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: HospitalTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _receiptAmountController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    prefixText: '₹',
                                    hintText: 'Enter billing amount',
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  onChanged: (value) {
                                    final amount =
                                        double.tryParse(value) ?? 0.0;
                                    notifier.updateReceiptAmount(amount);
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Amount Paid
                                Text(
                                  'Amount Paid',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: HospitalTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _amountPaidController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    prefixText: '₹',
                                    hintText: 'Enter amount paid',
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  onChanged: (value) {
                                    final amount =
                                        double.tryParse(value) ?? 0.0;
                                    notifier.updateAmountPaid(amount);
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Pending Amount Display
                                if (state.receiptAmount > 0 &&
                                    state.amountPaid >= 0)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: (state.receiptAmount -
                                                  state.amountPaid) <=
                                              0
                                          ? HospitalTheme.success
                                              .withOpacity(0.1)
                                          : HospitalTheme.warning
                                              .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: (state.receiptAmount -
                                                    state.amountPaid) <=
                                                0
                                            ? HospitalTheme.success
                                            : HospitalTheme.warning,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Pending Amount:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: (state.receiptAmount -
                                                        state.amountPaid) <=
                                                    0
                                                ? HospitalTheme.success
                                                : HospitalTheme.warning,
                                          ),
                                        ),
                                        Text(
                                          '₹${(state.receiptAmount - state.amountPaid).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: (state.receiptAmount -
                                                        state.amountPaid) <=
                                                    0
                                                ? HospitalTheme.success
                                                : HospitalTheme.warning,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                const SizedBox(height: 16),

                                // Generate Receipt Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    onPressed: state.isGeneratingReceipt
                                        ? null
                                        : () => notifier.generateReceipt(),
                                    icon: state.isGeneratingReceipt
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : const Icon(Icons.receipt_long),
                                    label: Text(
                                      state.isGeneratingReceipt
                                          ? 'Generating...'
                                          : 'Generate Receipt',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: HospitalTheme.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Receipt Generated Section
                          HospitalTheme.buildCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: HospitalTheme.success, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Receipt Generated',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: HospitalTheme.success,
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
                                    color:
                                        HospitalTheme.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: HospitalTheme.success
                                            .withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Patient ID:',
                                              style: TextStyle(
                                                  color: HospitalTheme
                                                      .textMedium)),
                                          Text(
                                            state.generatedReceipt!
                                                        .updatedPatient[
                                                    'patientId'] ??
                                                'N/A',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Last Billing:',
                                              style: TextStyle(
                                                  color: HospitalTheme
                                                      .textMedium)),
                                          Text(
                                            '₹${state.generatedReceipt!.updatedHistory['lastBillingAmount'] ?? '0'}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Payment Received:',
                                              style: TextStyle(
                                                  color: HospitalTheme
                                                      .textMedium)),
                                          Text(
                                            '₹${state.generatedReceipt!.updatedHistory['lastPaymentReceived'] ?? '0'}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Remaining Amount:',
                                              style: TextStyle(
                                                  color: HospitalTheme
                                                      .textMedium)),
                                          Text(
                                            '₹${state.generatedReceipt!.updatedHistory['remainingAmount'] ?? '0'}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: (state.generatedReceipt!
                                                                  .updatedHistory[
                                                              'remainingAmount'] ??
                                                          0) <=
                                                      0
                                                  ? HospitalTheme.success
                                                  : HospitalTheme.warning,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Open Receipt Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Methods().openPdf(
                                          state.generatedReceipt!.fileLink);
                                    },
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text('Open Receipt'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: HospitalTheme.secondary,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Generate Another Receipt Button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      // Reset receipt state
                                      notifier.state = notifier.state.copyWith(
                                        generatedReceipt: null,
                                        receiptAmount:
                                            bill.billSummary.finalAmount,
                                        amountPaid:
                                            bill.billSummary.finalAmount,
                                      );
                                      _receiptAmountController.text = bill
                                          .billSummary.finalAmount
                                          .toString();
                                      _amountPaidController.text = bill
                                          .billSummary.finalAmount
                                          .toString();
                                    },
                                    icon: const Icon(Icons.add),
                                    label:
                                        const Text('Generate Another Receipt'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Actions
                        HospitalTheme.buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Actions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: HospitalTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    // Copy link to clipboard
                                    Clipboard.setData(
                                        ClipboardData(text: bill.driveLink));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Link copied to clipboard')),
                                    );
                                  },
                                  icon: const Icon(Icons.copy),
                                  label: const Text('Copy Bill Link'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (state.generatedReceipt != null)
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      // Copy receipt link to clipboard
                                      Clipboard.setData(ClipboardData(
                                          text: state
                                              .generatedReceipt!.fileLink));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Receipt link copied to clipboard')),
                                      );
                                    },
                                    icon: const Icon(Icons.copy),
                                    label: const Text('Copy Receipt Link'),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    final emailSubject =
                                        'IPD Discharge Bill - ${bill.patientInfo['name'] ?? 'Patient'} (${bill.patientInfo['patientId'] ?? 'N/A'})';
                                    final emailBody = '''
Dear Recipient,

Please find the IPD Discharge Bill details below:

Patient Information:
- Name: ${bill.patientInfo['name'] ?? 'N/A'}
- Patient ID: ${bill.patientInfo['patientId'] ?? 'N/A'}
- Age: ${bill.patientInfo['age'] ?? 'N/A'}
- Gender: ${bill.patientInfo['gender'] ?? 'N/A'}

Admission Details:
- Admission Date: ${_formatDate(bill.admissionDetails['admissionDate'])}
- Discharge Date: ${_formatDate(bill.admissionDetails['dischargeDate'])}
- Length of Stay: ${bill.admissionDetails['lengthOfStay'] ?? 'N/A'} days
- Attending Doctor: ${bill.admissionDetails['attendingDoctor'] ?? 'N/A'}

Bill Summary:
- Total Charges: ₹${bill.billSummary.totalCharges.toStringAsFixed(2)}
- Discount: ₹${bill.billSummary.discount.toStringAsFixed(2)}
- Advance Paid: ₹${bill.billSummary.advance.toStringAsFixed(2)}
- Final Amount: ₹${bill.billSummary.finalAmount.toStringAsFixed(2)}

You can access the complete PDF bill using the following link:
${bill.driveLink}

${state.generatedReceipt != null ? 'Receipt Link: ${state.generatedReceipt!.fileLink}' : ''}

Bill Generated: ${bill.generatedAt.toString().split('.')[0]}
File: ${bill.fileName}

Best regards,
Bhosale Hospital Team
                                  ''';

                                    Methods().openMail(
                                      subject: emailSubject,
                                      body: emailBody,
                                    );
                                  },
                                  icon: const Icon(Icons.share),
                                  label: const Text('Share Bill'),
                                ),
                              ),
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
}
