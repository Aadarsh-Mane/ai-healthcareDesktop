import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/core/utils/PdfViewerScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Models (keeping existing models)
class ServiceItem {
  final String name;
  final int quantity;
  final double rate;

  const ServiceItem({
    required this.name,
    required this.quantity,
    required this.rate,
  });

  double get total => quantity * rate;
}

class AdditionalCharge {
  final String name;
  final int quantity;
  final double rate;

  const AdditionalCharge({
    required this.name,
    required this.quantity,
    required this.rate,
  });

  double get total => quantity * rate;

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'rate': rate,
      };
}

class BillResponse {
  final String fileName;
  final String driveLink;
  final String billNumber;
  final String patientName;
  final double grandTotal;
  final String paymentMode;
  final Map<String, dynamic> billBreakdown;

  const BillResponse({
    required this.fileName,
    required this.driveLink,
    required this.billNumber,
    required this.patientName,
    required this.grandTotal,
    required this.paymentMode,
    required this.billBreakdown,
  });

  factory BillResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final billInfo = data['billInfo'] ?? {};

    return BillResponse(
      fileName: data['fileName'] ?? '',
      driveLink: data['driveLink'] ?? '',
      billNumber: billInfo['billNumber'] ?? '',
      patientName: billInfo['patientName'] ?? '',
      grandTotal: (billInfo['grandTotal'] ?? 0).toDouble(),
      paymentMode: billInfo['paymentMode'] ?? '',
      billBreakdown: data['billBreakdown'] ?? {},
    );
  }
}

class ReceiptResponse {
  final String message;
  final String fileLink;
  final double pendingAmount;
  final double remainingAmount;

  const ReceiptResponse({
    required this.message,
    required this.fileLink,
    required this.pendingAmount,
    required this.remainingAmount,
  });

  factory ReceiptResponse.fromJson(Map<String, dynamic> json) {
    return ReceiptResponse(
      message: json['message'] ?? '',
      fileLink: json['fileLink'] ?? '',
      pendingAmount: (json['updatedPatient']?['pendingAmount'] ?? 0).toDouble(),
      remainingAmount:
          (json['updatedHistory']?['remainingAmount'] ?? 0).toDouble(),
    );
  }
}

// State Management (keeping existing state)
class OpdBillingState {
  final Map<String, ServiceItem> services;
  final double consultationFee;
  final List<AdditionalCharge> additionalCharges;
  final double discount;
  final String paymentMode;
  final String notes;
  final bool uploadToDriveFlag;
  final bool isLoading;
  final BillResponse? billResponse;
  final ReceiptResponse? receiptResponse;
  final double billingAmount;
  final double amountPaid;
  final bool isGeneratingReceipt;

  const OpdBillingState({
    required this.services,
    this.consultationFee = 500,
    this.additionalCharges = const [],
    this.discount = 0,
    this.paymentMode = 'Cash',
    this.notes = '',
    this.uploadToDriveFlag = true,
    this.isLoading = false,
    this.billResponse,
    this.receiptResponse,
    this.billingAmount = 0,
    this.amountPaid = 0,
    this.isGeneratingReceipt = false,
  });

  OpdBillingState copyWith({
    Map<String, ServiceItem>? services,
    double? consultationFee,
    List<AdditionalCharge>? additionalCharges,
    double? discount,
    String? paymentMode,
    String? notes,
    bool? uploadToDriveFlag,
    bool? isLoading,
    BillResponse? billResponse,
    bool clearBillResponse = false,
    ReceiptResponse? receiptResponse,
    bool clearReceiptResponse = false,
    double? billingAmount,
    double? amountPaid,
    bool? isGeneratingReceipt,
  }) {
    return OpdBillingState(
      services: services ?? this.services,
      consultationFee: consultationFee ?? this.consultationFee,
      additionalCharges: additionalCharges ?? this.additionalCharges,
      discount: discount ?? this.discount,
      paymentMode: paymentMode ?? this.paymentMode,
      notes: notes ?? this.notes,
      uploadToDriveFlag: uploadToDriveFlag ?? this.uploadToDriveFlag,
      isLoading: isLoading ?? this.isLoading,
      billResponse:
          clearBillResponse ? null : (billResponse ?? this.billResponse),
      receiptResponse: clearReceiptResponse
          ? null
          : (receiptResponse ?? this.receiptResponse),
      billingAmount: billingAmount ?? this.billingAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      isGeneratingReceipt: isGeneratingReceipt ?? this.isGeneratingReceipt,
    );
  }

  double get servicesTotal {
    return services.values.fold(0, (sum, service) => sum + service.total);
  }

  double get additionalChargesTotal {
    return additionalCharges.fold(0, (sum, charge) => sum + charge.total);
  }

  double get subtotal {
    return servicesTotal + consultationFee + additionalChargesTotal;
  }

  double get discountAmount {
    return subtotal * (discount / 100);
  }

  double get grandTotal {
    return subtotal - discountAmount;
  }
}

final opdBillingProvider =
    StateNotifierProvider.family<OpdBillingNotifier, OpdBillingState, String>(
  (ref, patientId) => OpdBillingNotifier(patientId),
);

class OpdBillingNotifier extends StateNotifier<OpdBillingState> {
  final String patientId;

  OpdBillingNotifier(this.patientId)
      : super(OpdBillingState(
          services: {
            'ecg': const ServiceItem(name: 'ECG', quantity: 0, rate: 150),
            'xray': const ServiceItem(name: 'X-Ray', quantity: 0, rate: 300),
            'injection':
                const ServiceItem(name: 'Injection', quantity: 0, rate: 50),
            'dialysis':
                const ServiceItem(name: 'Dialysis', quantity: 0, rate: 800),
            'dressing':
                const ServiceItem(name: 'Dressing', quantity: 0, rate: 100),
          },
        ));

  void updateServiceQuantity(String serviceKey, int quantity) {
    final currentService = state.services[serviceKey];
    if (currentService == null) return;

    final updatedServices = Map<String, ServiceItem>.from(state.services);
    updatedServices[serviceKey] = ServiceItem(
      name: currentService.name,
      quantity: quantity,
      rate: currentService.rate,
    );

    state = state.copyWith(services: updatedServices);
  }

  void updateServiceRate(String serviceKey, double rate) {
    final currentService = state.services[serviceKey];
    if (currentService == null) return;

    final updatedServices = Map<String, ServiceItem>.from(state.services);
    updatedServices[serviceKey] = ServiceItem(
      name: currentService.name,
      quantity: currentService.quantity,
      rate: rate,
    );

    state = state.copyWith(services: updatedServices);
  }

  void updateConsultationFee(double fee) {
    state = state.copyWith(consultationFee: fee);
  }

  void addAdditionalCharge(String name, int quantity, double rate) {
    final updatedCharges = List<AdditionalCharge>.from(state.additionalCharges);
    updatedCharges
        .add(AdditionalCharge(name: name, quantity: quantity, rate: rate));
    state = state.copyWith(additionalCharges: updatedCharges);
  }

  void removeAdditionalCharge(int index) {
    if (index < 0 || index >= state.additionalCharges.length) return;

    final updatedCharges = List<AdditionalCharge>.from(state.additionalCharges);
    updatedCharges.removeAt(index);
    state = state.copyWith(additionalCharges: updatedCharges);
  }

  void updateDiscount(double discount) {
    state = state.copyWith(discount: discount);
  }

  void updatePaymentMode(String mode) {
    state = state.copyWith(paymentMode: mode);
  }

  void updateNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void updateUploadToDriveFlag(bool flag) {
    state = state.copyWith(uploadToDriveFlag: flag);
  }

  void updateBillingAmount(double amount) {
    state = state.copyWith(billingAmount: amount);
  }

  void updateAmountPaid(double amount) {
    state = state.copyWith(amountPaid: amount);
  }

  Future<void> generateBill() async {
    state = state.copyWith(isLoading: true);

    try {
      final requestBody = {
        'services': {
          for (var entry in state.services.entries)
            entry.key: {
              'quantity': entry.value.quantity,
              'rate': entry.value.rate,
            }
        },
        'consultationFee': state.consultationFee,
        'additionalCharges':
            state.additionalCharges.map((charge) => charge.toJson()).toList(),
        'discount': state.discount,
        'paymentMode': state.paymentMode,
        'notes': state.notes,
        'uploadToDriveFlag': state.uploadToDriveFlag,
      };

      final response = await http.post(
        Uri.parse('${KVM_URL}/reception/generateOPDBill/$patientId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final billResponse = BillResponse.fromJson(responseData);

        state = state.copyWith(
          billResponse: billResponse,
          billingAmount: billResponse.grandTotal,
          amountPaid: billResponse.grandTotal,
          isLoading: false,
        );
      } else {
        throw Exception('Failed to generate bill: ${response.statusCode}');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> generateReceipt() async {
    state = state.copyWith(isGeneratingReceipt: true);

    try {
      final requestBody = {
        'patientId': patientId,
        'billingAmount': state.billingAmount.toString(),
        'amountPaid': state.amountPaid.toString(),
      };

      final response = await http.post(
        Uri.parse('${KVM_URL}/reception/generateOpdReceipt'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final receiptResponse = ReceiptResponse.fromJson(responseData);

        // Keep the existing billResponse and only update receiptResponse
        state = state.copyWith(
          receiptResponse: receiptResponse,
          isGeneratingReceipt: false,
          // Don't clear billResponse - keep it as is
        );
      } else {
        throw Exception('Failed to generate receipt: ${response.statusCode}');
      }
    } catch (e) {
      state = state.copyWith(isGeneratingReceipt: false);
      rethrow;
    }
  }

  void reset() {
    state = OpdBillingState(
      services: {
        'ecg': const ServiceItem(name: 'ECG', quantity: 0, rate: 150),
        'xray': const ServiceItem(name: 'X-Ray', quantity: 0, rate: 300),
        'injection':
            const ServiceItem(name: 'Injection', quantity: 0, rate: 50),
        'dialysis': const ServiceItem(name: 'Dialysis', quantity: 0, rate: 800),
        'dressing': const ServiceItem(name: 'Dressing', quantity: 0, rate: 100),
      },
    );
  }
}

// Enhanced Main Screen with PDF Viewer Integration
class OpdBillingScreen extends ConsumerStatefulWidget {
  final String patientId;

  const OpdBillingScreen({
    super.key,
    required this.patientId,
  });

  @override
  ConsumerState<OpdBillingScreen> createState() => _OpdBillingScreenState();
}

class _OpdBillingScreenState extends ConsumerState<OpdBillingScreen> {
  final _additionalChargeNameController = TextEditingController();
  final _additionalChargeQuantityController = TextEditingController();
  final _additionalChargeRateController = TextEditingController();
  final _notesController = TextEditingController();
  final _billingAmountController = TextEditingController();
  final _amountPaidController = TextEditingController();

  @override
  void dispose() {
    _additionalChargeNameController.dispose();
    _additionalChargeQuantityController.dispose();
    _additionalChargeRateController.dispose();
    _notesController.dispose();
    _billingAmountController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(opdBillingProvider(widget.patientId));
    final notifier = ref.read(opdBillingProvider(widget.patientId).notifier);
    final screenSize = MediaQuery.of(context).size;

    // Update controllers when state changes
    if (_billingAmountController.text != state.billingAmount.toString()) {
      _billingAmountController.text = state.billingAmount.toString();
    }
    if (_amountPaidController.text != state.amountPaid.toString()) {
      _amountPaidController.text = state.amountPaid.toString();
    }

    return PdfViewerWidget(
      primaryColor: HospitalTheme.primary,
      appBarTitle: 'OPD Bill Preview',
      child: Scaffold(
        appBar: HospitalTheme.buildAppBar(
          context: context,
          title: 'OPD Billing - ${widget.patientId}',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => notifier.reset(),
              tooltip: 'Reset Form (F5)',
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
                _generateBill(notifier),
            const SingleActivator(LogicalKeyboardKey.keyR, control: true): () =>
                _generateReceipt(notifier),
            const SingleActivator(LogicalKeyboardKey.keyP, control: true): () =>
                _openPdfPreview(state),
            const SingleActivator(LogicalKeyboardKey.f5): () =>
                notifier.reset(),
          },
          child: Focus(
            autofocus: true,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Responsive layout based on screen width
                if (constraints.maxWidth > 1200) {
                  return _buildDesktopLayout(context, state, notifier);
                } else if (constraints.maxWidth > 800) {
                  return _buildTabletLayout(context, state, notifier);
                } else {
                  return _buildMobileLayout(context, state, notifier);
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, OpdBillingState state,
      OpdBillingNotifier notifier) {
    return Row(
      children: [
        // Left Panel - Billing Form
        Expanded(
          flex: 3,
          child: _buildBillingForm(context, state, notifier),
        ),

        // Divider
        Container(
          width: 1,
          color: HospitalTheme.border,
        ),

        // Right Panel - Bill Preview & Receipt Generation
        Expanded(
          flex: 2,
          child: _buildRightPanel(context, state, notifier),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, OpdBillingState state,
      OpdBillingNotifier notifier) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildBillingForm(context, state, notifier),
        ),
        Container(width: 1, color: HospitalTheme.border),
        Expanded(
          child: _buildRightPanel(context, state, notifier),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, OpdBillingState state,
      OpdBillingNotifier notifier) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'Billing Form', icon: Icon(Icons.edit_document)),
              Tab(text: 'Bill Summary', icon: Icon(Icons.receipt_long)),
            ],
            labelColor: HospitalTheme.primary,
            unselectedLabelColor: HospitalTheme.textMedium,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildBillingForm(context, state, notifier),
                _buildRightPanel(context, state, notifier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingForm(BuildContext context, OpdBillingState state,
      OpdBillingNotifier notifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('Medical Services'),

          // Services Grid - Responsive grid
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 800 ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: crossAxisCount == 2 ? 2.5 : 3.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: state.services.length,
                itemBuilder: (context, index) {
                  final entry = state.services.entries.elementAt(index);
                  final service = entry.value;

                  return _buildServiceCard(entry.key, service, notifier);
                },
              );
            },
          ),

          const SizedBox(height: 32),

          // Consultation Fee
          HospitalTheme.buildSectionHeader('Consultation Details'),
          HospitalTheme.buildCard(
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      return Row(
                        children: [
                          Expanded(
                              child:
                                  _buildConsultationFeeField(state, notifier)),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _buildPaymentModeField(state, notifier)),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildConsultationFeeField(state, notifier),
                          const SizedBox(height: 16),
                          _buildPaymentModeField(state, notifier),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildNotesField(notifier),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Additional Charges
          _buildAdditionalChargesSection(context, state, notifier),

          const SizedBox(height: 32),

          // Discount and Options
          _buildDiscountSection(state, notifier),

          const SizedBox(height: 32),

          // Generate Bill Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: state.isLoading ? null : () => _generateBill(notifier),
              icon: state.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.receipt_long),
              label: Text(state.isLoading
                  ? 'Generating Bill...'
                  : 'Generate Bill (Ctrl+S)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
      String serviceKey, ServiceItem service, OpdBillingNotifier notifier) {
    return HospitalTheme.buildCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getServiceIcon(serviceKey),
                size: 20,
                color: HospitalTheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  service.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: service.quantity.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    final quantity = int.tryParse(value) ?? 0;
                    notifier.updateServiceQuantity(serviceKey, quantity);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: service.rate.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Rate',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                  onChanged: (value) {
                    final rate = double.tryParse(value) ?? 0;
                    notifier.updateServiceRate(serviceKey, rate);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total: ₹${service.total.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: HospitalTheme.primary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationFeeField(
      OpdBillingState state, OpdBillingNotifier notifier) {
    return TextFormField(
      initialValue: state.consultationFee.toString(),
      decoration: const InputDecoration(
        labelText: 'Consultation Fee',
        prefixText: '₹ ',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      onChanged: (value) {
        final fee = double.tryParse(value) ?? 0;
        notifier.updateConsultationFee(fee);
      },
    );
  }

  Widget _buildPaymentModeField(
      OpdBillingState state, OpdBillingNotifier notifier) {
    return DropdownButtonFormField<String>(
      value: state.paymentMode,
      decoration: const InputDecoration(
        labelText: 'Payment Mode',
      ),
      items: ['Cash', 'Card', 'UPI', 'Bank Transfer']
          .map((mode) => DropdownMenuItem(
                value: mode,
                child: Text(mode),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) notifier.updatePaymentMode(value);
      },
    );
  }

  Widget _buildNotesField(OpdBillingNotifier notifier) {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notes (Optional)',
        hintText: 'Add any additional notes for this bill',
      ),
      maxLines: 3,
      onChanged: notifier.updateNotes,
    );
  }

  Widget _buildAdditionalChargesSection(BuildContext context,
      OpdBillingState state, OpdBillingNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HospitalTheme.buildSectionHeader(
          'Additional Charges',
          trailing: IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddChargeDialog(context, notifier),
            tooltip: 'Add Charge',
          ),
        ),
        if (state.additionalCharges.isNotEmpty) ...[
          HospitalTheme.buildCard(
            child: Column(
              children: state.additionalCharges.asMap().entries.map((entry) {
                final index = entry.key;
                final charge = entry.value;

                return _buildAdditionalChargeItem(charge, index, notifier,
                    isLast: index == state.additionalCharges.length - 1);
              }).toList(),
            ),
          ),
        ] else ...[
          _buildEmptyAdditionalCharges(),
        ],
      ],
    );
  }

  Widget _buildAdditionalChargeItem(
      AdditionalCharge charge, int index, OpdBillingNotifier notifier,
      {required bool isLast}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    charge.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(child: Text('Qty: ${charge.quantity}')),
                Expanded(child: Text('Rate: ₹${charge.rate}')),
                Expanded(
                  child: Text(
                    'Total: ₹${charge.total}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: HospitalTheme.error),
                  onPressed: () => notifier.removeAdditionalCharge(index),
                  tooltip: 'Remove',
                ),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        charge.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: HospitalTheme.error),
                      onPressed: () => notifier.removeAdditionalCharge(index),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Qty: ${charge.quantity}'),
                    Text('Rate: ₹${charge.rate}'),
                    Text(
                      'Total: ₹${charge.total}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildEmptyAdditionalCharges() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: HospitalTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No additional charges added',
            style: TextStyle(
              color: HospitalTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountSection(
      OpdBillingState state, OpdBillingNotifier notifier) {
    return HospitalTheme.buildCard(
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Row(
                  children: [
                    Expanded(child: _buildDiscountField(state, notifier)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDiscountAmountDisplay(state)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildDiscountField(state, notifier),
                    const SizedBox(height: 16),
                    _buildDiscountAmountDisplay(state),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _buildUploadToDriveCheckbox(state, notifier),
        ],
      ),
    );
  }

  Widget _buildDiscountField(
      OpdBillingState state, OpdBillingNotifier notifier) {
    return TextFormField(
      initialValue: state.discount.toString(),
      decoration: const InputDecoration(
        labelText: 'Discount (%)',
        suffixText: '%',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      onChanged: (value) {
        final discount = double.tryParse(value) ?? 0;
        notifier.updateDiscount(discount);
      },
    );
  }

  Widget _buildDiscountAmountDisplay(OpdBillingState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HospitalTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discount Amount',
            style: TextStyle(
              fontSize: 12,
              color: HospitalTheme.textMedium,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${state.discountAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadToDriveCheckbox(
      OpdBillingState state, OpdBillingNotifier notifier) {
    return Row(
      children: [
        Checkbox(
          value: state.uploadToDriveFlag,
          onChanged: (value) => notifier.updateUploadToDriveFlag(value ?? true),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Text('Upload bill to Google Drive')),
      ],
    );
  }

  Widget _buildRightPanel(BuildContext context, OpdBillingState state,
      OpdBillingNotifier notifier) {
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
          if (state.billResponse != null) ...[
            const SizedBox(height: 24),
            _buildGeneratedBillSection(state),
          ],

          // Receipt Generation Section - Show if bill exists
          if (state.billResponse != null) ...[
            const SizedBox(height: 24),
            _buildReceiptGenerationSection(state, notifier),
          ],

          // Receipt Response Section - Show if receipt exists
          if (state.receiptResponse != null) ...[
            const SizedBox(height: 24),
            _buildReceiptGeneratedSection(context, state),
          ],

          // Empty state for right panel - Only show if no bill
          if (state.billResponse == null) ...[
            const SizedBox(height: 24),
            _buildEmptyBillState(),
          ],
        ],
      ),
    );
  }

  Widget _buildBillSummarySection(OpdBillingState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HospitalTheme.buildSectionHeader('Bill Summary'),
        HospitalTheme.buildCard(
          child: Column(
            children: [
              _buildSummaryRow('Services Total',
                  '₹${state.servicesTotal.toStringAsFixed(2)}'),
              _buildSummaryRow('Consultation Fee',
                  '₹${state.consultationFee.toStringAsFixed(2)}'),
              if (state.additionalChargesTotal > 0)
                _buildSummaryRow('Additional Charges',
                    '₹${state.additionalChargesTotal.toStringAsFixed(2)}'),
              const Divider(),
              _buildSummaryRow(
                  'Subtotal', '₹${state.subtotal.toStringAsFixed(2)}'),
              if (state.discount > 0)
                _buildSummaryRow('Discount (${state.discount}%)',
                    '-₹${state.discountAmount.toStringAsFixed(2)}',
                    isNegative: true),
              const Divider(),
              _buildSummaryRow(
                'Grand Total',
                '₹${state.grandTotal.toStringAsFixed(2)}',
                isTotal: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratedBillSection(OpdBillingState state) {
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
              _buildInfoRow('Bill Number', state.billResponse!.billNumber),
              _buildInfoRow('Patient Name', state.billResponse!.patientName),
              _buildInfoRow('Payment Mode', state.billResponse!.paymentMode),
              _buildInfoRow('Grand Total',
                  '₹${state.billResponse!.grandTotal.toStringAsFixed(2)}'),
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

  Widget _buildViewPdfButton(OpdBillingState state) {
    return OutlinedButton.icon(
      onPressed: () => Methods().openPdf(state.billResponse!.driveLink),
      icon: const Icon(Icons.open_in_new),
      label: const Text('Open PDF'),
    );
  }

  Widget _buildPreviewPdfButton(OpdBillingState state, String type) {
    final url = type == 'bill'
        ? state.billResponse?.driveLink
        : state.receiptResponse?.fileLink;
    final title = type == 'bill'
        ? 'Bill - ${state.billResponse?.billNumber ?? ''}'
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
      OpdBillingState state, OpdBillingNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HospitalTheme.buildSectionHeader('Generate Receipt'),
        HospitalTheme.buildCard(
          child: Column(
            children: [
              TextFormField(
                controller: _billingAmountController,
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
                  notifier.updateBillingAmount(amount);
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
                    '₹${(state.billingAmount - state.amountPaid).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: (state.billingAmount - state.amountPaid) > 0
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
      BuildContext context, OpdBillingState state) {
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
              _buildInfoRow('Pending Amount',
                  '₹${state.receiptResponse!.pendingAmount.toStringAsFixed(2)}'),
              _buildInfoRow('Remaining Amount',
                  '₹${state.receiptResponse!.remainingAmount.toStringAsFixed(2)}'),
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

  Widget _buildViewReceiptButton(OpdBillingState state) {
    return OutlinedButton.icon(
      onPressed: () => Methods().openPdf(state.receiptResponse!.fileLink),
      icon: const Icon(Icons.open_in_new),
      label: const Text('Open Receipt'),
    );
  }

  Widget _buildEmptyBillState() {
    return SizedBox(
      height: 300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: HospitalTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'Generate Bill',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: HospitalTheme.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fill in the billing details and click\n"Generate Bill" to create the bill',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: HospitalTheme.textLight,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Shortcuts: Ctrl+S to Generate • Ctrl+P to Preview',
            style: TextStyle(
              fontSize: 12,
              color: HospitalTheme.textLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isNegative = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
              color: isTotal
                  ? HospitalTheme.primary
                  : isNegative
                      ? HospitalTheme.error
                      : HospitalTheme.textDark,
            ),
          ),
        ],
      ),
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

  IconData _getServiceIcon(String serviceKey) {
    switch (serviceKey) {
      case 'ecg':
        return Icons.monitor_heart_outlined;
      case 'xray':
        return Icons.camera_alt_outlined;
      case 'injection':
        return Icons.vaccines_outlined;
      case 'dialysis':
        return Icons.water_drop_outlined;
      case 'dressing':
        return Icons.healing_outlined;
      default:
        return Icons.medical_services_outlined;
    }
  }

  void _showAddChargeDialog(BuildContext context, OpdBillingNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Additional Charge'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _additionalChargeNameController,
                decoration: const InputDecoration(
                  labelText: 'Charge Name',
                  hintText: 'e.g., Pharmacy Charges, Lab Test',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _additionalChargeQuantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _additionalChargeRateController,
                      decoration: const InputDecoration(
                        labelText: 'Rate',
                        prefixText: '₹ ',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _additionalChargeNameController.clear();
              _additionalChargeQuantityController.clear();
              _additionalChargeRateController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _additionalChargeNameController.text.trim();
              final quantity =
                  int.tryParse(_additionalChargeQuantityController.text) ?? 0;
              final rate =
                  double.tryParse(_additionalChargeRateController.text) ?? 0;

              if (name.isNotEmpty && quantity > 0 && rate > 0) {
                notifier.addAdditionalCharge(name, quantity, rate);
                _additionalChargeNameController.clear();
                _additionalChargeQuantityController.clear();
                _additionalChargeRateController.clear();
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        const Text('Please fill all fields with valid values'),
                    backgroundColor: HospitalTheme.error,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
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
          'OPD billing and receipt generation completed successfully.\n\nWould you like to create another bill or return to the main screen?',
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
              ref.read(opdBillingProvider(widget.patientId).notifier).reset();
            },
            child: const Text('New Bill'),
          ),
        ],
      ),
    );
  }

  /// Unified PDF preview method that handles both bill and receipt
  /// Unified PDF preview method that handles both bill and receipt
  void _openPdfPreview(OpdBillingState state, [String? type]) {
    String? url;
    String title = 'PDF Document'; // Initialize with default value

    // Determine which PDF to preview based on type or availability
    if (type == 'receipt' && state.receiptResponse?.fileLink != null) {
      url = state.receiptResponse!.fileLink;
      title = 'Receipt - ${widget.patientId}';
    } else if (type == 'bill' && state.billResponse?.driveLink != null) {
      url = state.billResponse!.driveLink;
      title = 'Bill - ${state.billResponse!.billNumber}';
    } else if (state.receiptResponse?.fileLink != null) {
      // Default to receipt if available
      url = state.receiptResponse!.fileLink;
      title = 'Receipt - ${widget.patientId}';
    } else if (state.billResponse?.driveLink != null) {
      // Fallback to bill if receipt not available
      url = state.billResponse!.driveLink;
      title = 'Bill - ${state.billResponse!.billNumber}';
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

  Future<void> _generateBill(OpdBillingNotifier notifier) async {
    try {
      await notifier.generateBill();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bill generated successfully!'),
            backgroundColor: HospitalTheme.success,
            action: SnackBarAction(
              label: 'Preview',
              textColor: Colors.white,
              onPressed: () => _openPdfPreview(
                  ref.read(opdBillingProvider(widget.patientId)), 'bill'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate bill: $e'),
            backgroundColor: HospitalTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _generateReceipt(OpdBillingNotifier notifier) async {
    final state = ref.read(opdBillingProvider(widget.patientId));

    if (state.billingAmount <= 0) {
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
                  ref.read(opdBillingProvider(widget.patientId)), 'receipt'),
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
