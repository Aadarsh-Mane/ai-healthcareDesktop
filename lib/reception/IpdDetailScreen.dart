import 'dart:convert';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';

// State providers for better state management with Riverpod
final patientsProvider = StateNotifierProvider<PatientsNotifier, List<Patient>>(
    (ref) => PatientsNotifier());
final sectionsProvider = StateNotifierProvider<SectionsNotifier, List<Section>>(
    (ref) => SectionsNotifier());
final selectedPatientProvider =
    StateNotifierProvider<SelectedPatientNotifier, Patient?>(
        (ref) => SelectedPatientNotifier());
final uiStateProvider =
    StateNotifierProvider<UIStateNotifier, UIState>((ref) => UIStateNotifier());

// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Form data provider
final formDataProvider = StateNotifierProvider<FormDataNotifier, FormData>(
    (ref) => FormDataNotifier());

// Available beds provider
final availableBedsProvider =
    StateNotifierProvider<AvailableBedsNotifier, List<int>>(
        (ref) => AvailableBedsNotifier());

// Deposit providers - Updated for multiple deposits
final depositFormProvider =
    StateNotifierProvider<DepositFormNotifier, DepositFormData>(
        (ref) => DepositFormNotifier());
final depositSummaryProvider =
    StateNotifierProvider<DepositSummaryNotifier, DepositSummary?>(
        (ref) => DepositSummaryNotifier());

// Filtered patients provider
final filteredPatientsProvider = Provider<List<Patient>>((ref) {
  final patients = ref.watch(patientsProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

  if (searchQuery.isEmpty) {
    return patients;
  }

  return patients.where((patient) {
    return patient.name.toLowerCase().contains(searchQuery) ||
        patient.patientId.toLowerCase().contains(searchQuery);
  }).toList();
});

// State classes
class UIState {
  final bool isLoadingPatients;
  final bool isLoadingSections;
  final bool isProcessing;
  final bool isLoadingDepositSummary;
  final bool isCreatingDeposit;

  const UIState({
    this.isLoadingPatients = false,
    this.isLoadingSections = false,
    this.isProcessing = false,
    this.isLoadingDepositSummary = false,
    this.isCreatingDeposit = false,
  });

  UIState copyWith({
    bool? isLoadingPatients,
    bool? isLoadingSections,
    bool? isProcessing,
    bool? isLoadingDepositSummary,
    bool? isCreatingDeposit,
  }) {
    return UIState(
      isLoadingPatients: isLoadingPatients ?? this.isLoadingPatients,
      isLoadingSections: isLoadingSections ?? this.isLoadingSections,
      isProcessing: isProcessing ?? this.isProcessing,
      isLoadingDepositSummary:
          isLoadingDepositSummary ?? this.isLoadingDepositSummary,
      isCreatingDeposit: isCreatingDeposit ?? this.isCreatingDeposit,
    );
  }
}

class FormData {
  final String? reason;
  final String? symptoms;
  final String? diagnosis;
  final String? selectedSectionId;
  final int? selectedBedNumber;

  const FormData({
    this.reason,
    this.symptoms,
    this.diagnosis,
    this.selectedSectionId,
    this.selectedBedNumber,
  });

  FormData copyWith({
    String? reason,
    String? symptoms,
    String? diagnosis,
    String? selectedSectionId,
    int? selectedBedNumber,
    bool clearSelectedSection = false,
    bool clearSelectedBed = false,
    bool clearAll = false,
  }) {
    if (clearAll) {
      return const FormData();
    }

    return FormData(
      reason: reason ?? this.reason,
      symptoms: symptoms ?? this.symptoms,
      diagnosis: diagnosis ?? this.diagnosis,
      selectedSectionId: clearSelectedSection
          ? null
          : selectedSectionId ?? this.selectedSectionId,
      selectedBedNumber:
          clearSelectedBed ? null : selectedBedNumber ?? this.selectedBedNumber,
    );
  }
}

class DepositFormData {
  final double? depositAmount;
  final String? paymentMethod;
  final String? remarks;
  final String? transactionId;
  final String? chequeNumber;
  final String? bankName;

  const DepositFormData({
    this.depositAmount,
    this.paymentMethod,
    this.remarks,
    this.transactionId,
    this.chequeNumber,
    this.bankName,
  });

  DepositFormData copyWith({
    double? depositAmount,
    String? paymentMethod,
    String? remarks,
    String? transactionId,
    String? chequeNumber,
    String? bankName,
    bool clearAll = false,
  }) {
    if (clearAll) {
      return const DepositFormData();
    }

    return DepositFormData(
      depositAmount: depositAmount ?? this.depositAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      remarks: remarks ?? this.remarks,
      transactionId: transactionId ?? this.transactionId,
      chequeNumber: chequeNumber ?? this.chequeNumber,
      bankName: bankName ?? this.bankName,
    );
  }

  bool get isValid {
    return depositAmount != null &&
        depositAmount! > 0 &&
        paymentMethod != null &&
        paymentMethod!.isNotEmpty;
  }
}

// New classes for multiple deposits
class DepositSummary {
  final bool hasDeposits;
  final double totalAmount;
  final String formattedTotalAmount;
  final int depositsCount;
  final List<DepositRecord> deposits;
  final DateTime? firstDeposit;
  final DateTime? lastDeposit;

  const DepositSummary({
    required this.hasDeposits,
    required this.totalAmount,
    required this.formattedTotalAmount,
    required this.depositsCount,
    required this.deposits,
    this.firstDeposit,
    this.lastDeposit,
  });

  factory DepositSummary.fromJson(Map<String, dynamic> json) {
    return DepositSummary(
      hasDeposits: json['hasDeposits'] ?? false,
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      formattedTotalAmount: json['formattedTotalAmount'] ?? '₹0.00',
      depositsCount: json['depositsCount'] ?? 0,
      deposits: json['deposits'] != null
          ? (json['deposits'] as List)
              .map((deposit) => DepositRecord.fromJson(deposit))
              .toList()
          : [],
      firstDeposit: json['firstDeposit'] != null
          ? DateTime.tryParse(json['firstDeposit'])
          : null,
      lastDeposit: json['lastDeposit'] != null
          ? DateTime.tryParse(json['lastDeposit'])
          : null,
    );
  }
}

class DepositRecord {
  final String receiptId;
  final double amount;
  final String formattedAmount;
  final String paymentMethod;
  final DateTime generatedAt;
  final int sequenceNumber;

  const DepositRecord({
    required this.receiptId,
    required this.amount,
    required this.formattedAmount,
    required this.paymentMethod,
    required this.generatedAt,
    required this.sequenceNumber,
  });

  factory DepositRecord.fromJson(Map<String, dynamic> json) {
    return DepositRecord(
      receiptId: json['receiptId'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      formattedAmount: json['formattedAmount'] ?? '₹0.00',
      paymentMethod: json['paymentMethod'] ?? '',
      generatedAt:
          DateTime.tryParse(json['generatedAt'] ?? '') ?? DateTime.now(),
      sequenceNumber: json['sequenceNumber'] ?? 0,
    );
  }
}

// State notifier classes
class PatientsNotifier extends StateNotifier<List<Patient>> {
  PatientsNotifier() : super([]);

  void setPatients(List<Patient> patients) {
    state = patients;
  }
}

class SectionsNotifier extends StateNotifier<List<Section>> {
  SectionsNotifier() : super([]);

  void setSections(List<Section> sections) {
    state = sections;
  }
}

class SelectedPatientNotifier extends StateNotifier<Patient?> {
  SelectedPatientNotifier() : super(null);

  void setPatient(Patient? patient) {
    state = patient;
  }
}

class UIStateNotifier extends StateNotifier<UIState> {
  UIStateNotifier() : super(const UIState());

  void setLoadingPatients(bool isLoading) {
    state = state.copyWith(isLoadingPatients: isLoading);
  }

  void setLoadingSections(bool isLoading) {
    state = state.copyWith(isLoadingSections: isLoading);
  }

  void setProcessing(bool isProcessing) {
    state = state.copyWith(isProcessing: isProcessing);
  }

  void setLoadingDepositSummary(bool isLoading) {
    state = state.copyWith(isLoadingDepositSummary: isLoading);
  }

  void setCreatingDeposit(bool isCreating) {
    state = state.copyWith(isCreatingDeposit: isCreating);
  }
}

class FormDataNotifier extends StateNotifier<FormData> {
  FormDataNotifier() : super(const FormData());

  void setReason(String reason) {
    state = state.copyWith(reason: reason);
  }

  void setSymptoms(String symptoms) {
    state = state.copyWith(symptoms: symptoms);
  }

  void setDiagnosis(String diagnosis) {
    state = state.copyWith(diagnosis: diagnosis);
  }

  void setSelectedSection(String sectionId) {
    state =
        state.copyWith(selectedSectionId: sectionId, clearSelectedBed: true);
  }

  void setSelectedBed(int bedNumber) {
    state = state.copyWith(selectedBedNumber: bedNumber);
  }

  void clearForm() {
    state = state.copyWith(clearAll: true);
  }

  void prepopulateForm(Patient patient) {
    final admissionRecord = patient.admissionRecords.isNotEmpty
        ? patient.admissionRecords.first
        : null;

    if (admissionRecord != null) {
      state = FormData(
        reason: admissionRecord.reasonForAdmission ?? '',
        symptoms: admissionRecord.symptoms ?? '',
        diagnosis: admissionRecord.initialDiagnosis ?? '',
        selectedSectionId: admissionRecord.section?.id,
        selectedBedNumber: admissionRecord.bedNumber,
      );
    } else {
      clearForm();
    }
  }
}

class AvailableBedsNotifier extends StateNotifier<List<int>> {
  AvailableBedsNotifier() : super([]);

  void setBeds(List<int> beds) {
    state = beds;
  }
}

class DepositFormNotifier extends StateNotifier<DepositFormData> {
  DepositFormNotifier() : super(const DepositFormData());

  void setDepositAmount(double amount) {
    state = state.copyWith(depositAmount: amount);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setRemarks(String remarks) {
    state = state.copyWith(remarks: remarks);
  }

  void setTransactionId(String transactionId) {
    state = state.copyWith(transactionId: transactionId);
  }

  void setChequeNumber(String chequeNumber) {
    state = state.copyWith(chequeNumber: chequeNumber);
  }

  void setBankName(String bankName) {
    state = state.copyWith(bankName: bankName);
  }

  void clearForm() {
    state = state.copyWith(clearAll: true);
  }
}

class DepositSummaryNotifier extends StateNotifier<DepositSummary?> {
  DepositSummaryNotifier() : super(null);

  void setSummary(DepositSummary? summary) {
    state = summary;
  }

  void clearSummary() {
    state = null;
  }
}

class IpdDetailScreen extends ConsumerStatefulWidget {
  const IpdDetailScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<IpdDetailScreen> createState() => _IpdDetailScreenState();
}

class _IpdDetailScreenState extends ConsumerState<IpdDetailScreen> {
  // Form controllers
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController symptomsController = TextEditingController();
  final TextEditingController diagnosisController = TextEditingController();

  // Deposit form controllers
  final TextEditingController depositAmountController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController transactionIdController = TextEditingController();
  final TextEditingController chequeNumberController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();

  // Focus node for keyboard shortcuts
  final FocusNode _shortcutFocusNode = FocusNode();

  // Payment methods
  final List<String> paymentMethods = [
    'Cash',
    'Card',
    'UPI',
    'Net Banking',
    'Cheque'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize data fetching after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });

    // Set up controller listeners
    reasonController.addListener(() {
      ref.read(formDataProvider.notifier).setReason(reasonController.text);
    });

    symptomsController.addListener(() {
      ref.read(formDataProvider.notifier).setSymptoms(symptomsController.text);
    });

    diagnosisController.addListener(() {
      ref
          .read(formDataProvider.notifier)
          .setDiagnosis(diagnosisController.text);
    });

    // Deposit form listeners
    depositAmountController.addListener(() {
      final amount = double.tryParse(depositAmountController.text) ?? 0.0;
      ref.read(depositFormProvider.notifier).setDepositAmount(amount);
    });

    remarksController.addListener(() {
      ref.read(depositFormProvider.notifier).setRemarks(remarksController.text);
    });

    transactionIdController.addListener(() {
      ref
          .read(depositFormProvider.notifier)
          .setTransactionId(transactionIdController.text);
    });

    chequeNumberController.addListener(() {
      ref
          .read(depositFormProvider.notifier)
          .setChequeNumber(chequeNumberController.text);
    });

    bankNameController.addListener(() {
      ref
          .read(depositFormProvider.notifier)
          .setBankName(bankNameController.text);
    });
  }

  Future<void> _fetchInitialData() async {
    try {
      // Show loading indicators
      ref.read(uiStateProvider.notifier).setLoadingPatients(true);
      ref.read(uiStateProvider.notifier).setLoadingSections(true);

      // Fetch data in parallel for better performance
      await Future.wait([
        fetchAdmittedPatients(),
        fetchAvailableSections(),
      ]);
    } catch (e) {
      showErrorSnackBar('Error loading initial data: $e');
    } finally {
      // Ensure loading indicators are turned off
      ref.read(uiStateProvider.notifier).setLoadingPatients(false);
      ref.read(uiStateProvider.notifier).setLoadingSections(false);
    }
  }

  @override
  void dispose() {
    reasonController.dispose();
    symptomsController.dispose();
    diagnosisController.dispose();
    depositAmountController.dispose();
    remarksController.dispose();
    transactionIdController.dispose();
    chequeNumberController.dispose();
    bankNameController.dispose();
    _shortcutFocusNode.dispose();
    super.dispose();
  }

  Future<void> fetchAdmittedPatients() async {
    try {
      final response =
          await http.get(Uri.parse('${KVM_URL}/reception/getAdmittedPatients'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final patients = (data['data'] as List)
            .map((json) => Patient.fromJson(json))
            .toList();

        ref.read(patientsProvider.notifier).setPatients(patients);
      } else {
        throw Exception('Failed to load admitted patients');
      }
    } catch (e) {
      throw Exception('Error loading patients: $e');
    }
  }

  Future<void> fetchAvailableSections() async {
    try {
      final response =
          await http.get(Uri.parse('${KVM_URL}/admin/getAllSections'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final sections = (data['data'] as List)
            .map((json) => Section.fromJson(json))
            .toList();

        ref.read(sectionsProvider.notifier).setSections(sections);
      } else {
        throw Exception('Failed to load sections');
      }
    } catch (e) {
      throw Exception('Error loading sections: $e');
    }
  }

  Future<void> fetchAvailableBeds(String sectionId) async {
    ref.read(uiStateProvider.notifier).setProcessing(true);
    ref.read(availableBedsProvider.notifier).setBeds([]);

    try {
      final response = await http.get(
        Uri.parse('${KVM_URL}/reception/availableBeds/$sectionId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final beds = List<int>.from(data['data']['availableBedNumbers']);
        ref.read(availableBedsProvider.notifier).setBeds(beds);
      } else {
        throw Exception('Failed to load available beds');
      }
    } catch (e) {
      showErrorSnackBar('Error: $e');
    } finally {
      ref.read(uiStateProvider.notifier).setProcessing(false);
    }
  }

  // Updated method to fetch deposit summary instead of checking single receipt
  Future<void> fetchDepositSummary(String admissionId) async {
    ref.read(uiStateProvider.notifier).setLoadingDepositSummary(true);
    ref.read(depositSummaryProvider.notifier).clearSummary();

    try {
      final response = await http.get(
        Uri.parse(
            '${KVM_URL}/reception/getAdmissionDepositSummary/$admissionId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final summary = DepositSummary.fromJson(data['data']);
          ref.read(depositSummaryProvider.notifier).setSummary(summary);
        } else {
          ref.read(depositSummaryProvider.notifier).clearSummary();
        }
      } else {
        throw Exception('Failed to fetch deposit summary');
      }
    } catch (e) {
      showErrorSnackBar('Error fetching deposit summary: $e');
    } finally {
      ref.read(uiStateProvider.notifier).setLoadingDepositSummary(false);
    }
  }

  Future<void> createDepositReceipt() async {
    final patient = ref.read(selectedPatientProvider);
    final depositForm = ref.read(depositFormProvider);

    if (patient == null || patient.admissionRecords.isEmpty) {
      showErrorSnackBar('No patient or admission record selected');
      return;
    }

    if (!depositForm.isValid) {
      showErrorSnackBar('Please fill in all required deposit fields');
      return;
    }

    final admissionId = patient.admissionRecords.first.id;

    ref.read(uiStateProvider.notifier).setCreatingDeposit(true);

    try {
      final requestBody = {
        'patientId': patient.patientId,
        'admissionId': admissionId,
        'depositAmount': depositForm.depositAmount,
        'paymentMethod': depositForm.paymentMethod,
        'remarks': depositForm.remarks ?? '',
      };

      // Add optional fields based on payment method
      if (depositForm.paymentMethod == 'UPI' ||
          depositForm.paymentMethod == 'Net Banking') {
        if (depositForm.transactionId?.isNotEmpty == true) {
          requestBody['transactionId'] = depositForm.transactionId;
        }
      }

      if (depositForm.paymentMethod == 'Cheque') {
        if (depositForm.chequeNumber?.isNotEmpty == true) {
          requestBody['chequeNumber'] = depositForm.chequeNumber;
        }
        if (depositForm.bankName?.isNotEmpty == true) {
          requestBody['bankName'] = depositForm.bankName;
        }
      }

      final response = await http.post(
        Uri.parse('${KVM_URL}/reception/createDepositReceipt'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          showSuccessSnackBar('Deposit receipt created successfully!');

          // Clear the deposit form
          clearDepositForm();

          // Refresh the deposit summary to show the new deposit
          await fetchDepositSummary(admissionId);

          // Show the success dialog
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && context.mounted) {
              _showReceiptDetailsDialog(data);
            }
          });
        } else {
          throw Exception(
              data['message'] ?? 'Failed to create deposit receipt');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Failed to create deposit receipt');
      }
    } catch (e) {
      showErrorSnackBar('Error creating deposit receipt: $e');
    } finally {
      ref.read(uiStateProvider.notifier).setCreatingDeposit(false);
    }
  }

  void _showReceiptDetailsDialog(Map<String, dynamic> receiptData) {
    // Extract data safely with null checks
    final data = receiptData['data'] as Map<String, dynamic>? ?? {};
    final receipt = receiptData['receipt'] as Map<String, dynamic>? ?? {};

    final receiptId = data['receiptId'] ?? receipt['receiptId'] ?? 'N/A';
    final depositAmount = data['depositAmount'] ??
        receipt['depositDetails']?['depositAmount'] ??
        0;
    final receiptUrl =
        data['receiptUrl'] ?? receipt['depositDetails']?['receiptUrl'];
    final generatedAt =
        data['generatedAt'] ?? receipt['depositDetails']?['generatedAt'] ?? '';
    final paymentMethod = data['paymentMethod'] ??
        receipt['depositDetails']?['paymentMethod'] ??
        'N/A';

    // Format date
    String formattedDate = 'N/A';
    if (generatedAt.toString().isNotEmpty) {
      try {
        final dateTime = DateTime.parse(generatedAt.toString());
        formattedDate =
            '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        formattedDate = generatedAt.toString().split('.')[0]; // Fallback
      }
    }

    if (mounted && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: MediaQuery.of(dialogContext).size.width * 0.6,
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: HospitalTheme.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: HospitalTheme.success,
                      size: 48,
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Deposit Receipt Created Successfully!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Receipt details
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: HospitalTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: HospitalTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildReceiptDetailRow('Receipt ID', receiptId),
                        _buildReceiptDetailRow(
                            'Amount', '₹${depositAmount.toString()}'),
                        _buildReceiptDetailRow('Payment Method', paymentMethod),
                        _buildReceiptDetailRow('Date & Time', formattedDate),
                        if (receipt['patientDetails'] != null)
                          _buildReceiptDetailRow('Patient',
                              receipt['patientDetails']['name'] ?? 'N/A'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (receiptUrl != null &&
                          receiptUrl.toString().isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () {
                            Methods().openPdf(receiptUrl.toString());
                            showSuccessSnackBar('Opening receipt...');
                          },
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('View Receipt'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HospitalTheme.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HospitalTheme.textMedium,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildReceiptDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: HospitalTheme.textMedium,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: HospitalTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> updateIpdDetails() async {
    final patient = ref.read(selectedPatientProvider);
    final formData = ref.read(formDataProvider);

    if (patient == null || patient.admissionRecords.isEmpty) {
      showErrorSnackBar('No patient or admission record selected');
      return;
    }

    final admissionId = patient.admissionRecords.first.id;

    // Validate input
    if (formData.reason == null ||
        formData.reason!.isEmpty ||
        formData.symptoms == null ||
        formData.symptoms!.isEmpty ||
        formData.diagnosis == null ||
        formData.diagnosis!.isEmpty) {
      showErrorSnackBar('Please fill in all required fields');
      return;
    }

    ref.read(uiStateProvider.notifier).setProcessing(true);

    try {
      final response = await http.post(
        Uri.parse('${KVM_URL}/reception/addIpdDetails'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'patientId': patient.patientId,
          'admissionId': admissionId,
          'reasonForAdmission': formData.reason,
          'symptoms': formData.symptoms,
          'initialDiagnosis': formData.diagnosis,
          'ipdDetailsUpdated': true, // Mark as updated
        }),
      );

      if (response.statusCode == 200) {
        showSuccessSnackBar('IPD details updated successfully');

        // If a bed is also selected, assign it
        if (formData.selectedSectionId != null &&
            formData.selectedBedNumber != null) {
          await assignBedToPatient();
        } else {
          // Just refresh the patients list if no bed assignment
          await fetchAdmittedPatients();
        }

        // Reset form
        clearForm();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update IPD details');
      }
    } catch (e) {
      showErrorSnackBar('Error updating IPD details: $e');
    } finally {
      ref.read(uiStateProvider.notifier).setProcessing(false);
    }
  }

  Future<void> assignBedToPatient() async {
    final patient = ref.read(selectedPatientProvider);
    final formData = ref.read(formDataProvider);

    if (patient == null ||
        formData.selectedSectionId == null ||
        formData.selectedBedNumber == null) {
      showErrorSnackBar('Please select a section and bed');
      return;
    }

    final admissionId = patient.admissionRecords.isNotEmpty
        ? patient.admissionRecords.first.id
        : null;

    if (admissionId == null) {
      showErrorSnackBar('No admission record found');
      return;
    }

    ref.read(uiStateProvider.notifier).setProcessing(true);

    try {
      final response = await http.post(
        Uri.parse('${KVM_URL}/reception/assignBedToPatient'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'patientId': patient.patientId,
          'sectionId': formData.selectedSectionId,
          'bedNumber': formData.selectedBedNumber,
          'admissionRecordId': admissionId,
        }),
      );

      if (response.statusCode == 200) {
        showSuccessSnackBar('Bed assigned successfully');
        await fetchAdmittedPatients(); // Refresh the list
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to assign bed');
      }
    } catch (e) {
      showErrorSnackBar('Error assigning bed: $e');
    } finally {
      ref.read(uiStateProvider.notifier).setProcessing(false);
    }
  }

  void selectPatient(Patient patient) {
    ref.read(selectedPatientProvider.notifier).setPatient(patient);
    ref.read(formDataProvider.notifier).prepopulateForm(patient);

    // Update the text controllers
    final formData = ref.read(formDataProvider);
    reasonController.text = formData.reason ?? '';
    symptomsController.text = formData.symptoms ?? '';
    diagnosisController.text = formData.diagnosis ?? '';

    // If a section is selected, fetch available beds
    if (formData.selectedSectionId != null &&
        formData.selectedBedNumber == null) {
      fetchAvailableBeds(formData.selectedSectionId!);
    }

    // Fetch deposit summary for this admission
    if (patient.admissionRecords.isNotEmpty) {
      fetchDepositSummary(patient.admissionRecords.first.id);
    }
  }

  void clearForm() {
    reasonController.clear();
    symptomsController.clear();
    diagnosisController.clear();
    ref.read(formDataProvider.notifier).clearForm();
    ref.read(selectedPatientProvider.notifier).setPatient(null);
    ref.read(availableBedsProvider.notifier).setBeds([]);
    clearDepositForm();
  }

  void clearDepositForm() {
    depositAmountController.clear();
    remarksController.clear();
    transactionIdController.clear();
    chequeNumberController.clear();
    bankNameController.clear();
    ref.read(depositFormProvider.notifier).clearForm();
  }

  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: HospitalTheme.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: HospitalTheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get dimensions to ensure responsiveness
    final size = MediaQuery.of(context).size;

    return KeyboardListener(
      focusNode: _shortcutFocusNode,
      autofocus: true,
      onKeyEvent: (keyEvent) {
        if (keyEvent is KeyDownEvent) {
          // Refresh data with F5
          if (keyEvent.logicalKey == LogicalKeyboardKey.f5) {
            _fetchInitialData();
          }

          // Ctrl+F for search focus
          if (keyEvent.logicalKey == LogicalKeyboardKey.keyF &&
              (HardwareKeyboard.instance.isControlPressed ||
                  HardwareKeyboard.instance.isMetaPressed)) {
            // Could implement search focus
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('IPD Patient Management'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchInitialData,
              tooltip: 'Refresh data (F5)',
            ),
          ],
        ),
        body: Row(
          children: [
            // Patient list panel
            Container(
              width: 320,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSearchBar(),
                  Expanded(
                    child: _buildPatientsList(),
                  ),
                ],
              ),
            ),

            // IPD details form panel
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final selectedPatient = ref.watch(selectedPatientProvider);
                  return selectedPatient != null
                      ? _buildPatientDetailsForm()
                      : _buildNoPatientSelectedView();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Consumer(
      builder: (context, ref, _) {
        final patients = ref.watch(patientsProvider);
        final filteredPatients = ref.watch(filteredPatientsProvider);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HospitalTheme.surfaceLight,
            border: Border(
              bottom: BorderSide(color: HospitalTheme.border),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Admitted Patients',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: HospitalTheme.textDark,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by name or ID',
                  prefixIcon:
                      const Icon(Icons.search, color: HospitalTheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Showing ${filteredPatients.length} of ${patients.length} patients',
                style: const TextStyle(
                  color: HospitalTheme.textMedium,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPatientsList() {
    return Consumer(
      builder: (context, ref, _) {
        final uiState = ref.watch(uiStateProvider);
        final filteredPatients = ref.watch(filteredPatientsProvider);
        final selectedPatient = ref.watch(selectedPatientProvider);

        if (uiState.isLoadingPatients) {
          return const Center(child: CircularProgressIndicator());
        }

        if (filteredPatients.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off,
                    size: 48, color: HospitalTheme.textMedium),
                SizedBox(height: 16),
                Text(
                  'No patients match your search',
                  style: TextStyle(color: HospitalTheme.textMedium),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filteredPatients.length,
          itemBuilder: (context, index) {
            final patient = filteredPatients[index];
            final isSelected = selectedPatient?.id == patient.id;
            return _buildPatientCard(patient, isSelected);
          },
        );
      },
    );
  }

  Widget _buildPatientCard(Patient patient, bool isSelected) {
    final hasAdmission = patient.admissionRecords.isNotEmpty;
    final hasBed =
        hasAdmission && patient.admissionRecords.first.bedNumber != null;
    final ipdUpdated =
        hasAdmission && patient.admissionRecords.first.ipdDetailsUpdated;

    final bedInfo = hasBed
        ? 'Bed: ${patient.admissionRecords.first.bedNumber}'
        : 'No bed assigned';

    final sectionInfo =
        hasAdmission && patient.admissionRecords.first.section != null
            ? '${patient.admissionRecords.first.section!.name}'
            : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isSelected ? HospitalTheme.surfaceLight : Colors.white,
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? HospitalTheme.primary : HospitalTheme.border,
          width: isSelected ? 1.5 : 0.5,
        ),
      ),
      child: InkWell(
        onTap: () => selectPatient(patient),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: hasBed
                        ? HospitalTheme.success.withOpacity(0.2)
                        : HospitalTheme.warning.withOpacity(0.2),
                    radius: 18,
                    child: Text(
                      patient.name.isNotEmpty
                          ? patient.name.substring(0, 1).toUpperCase()
                          : 'P',
                      style: TextStyle(
                        color: hasBed
                            ? HospitalTheme.success
                            : HospitalTheme.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'ID: ${patient.patientId}',
                          style: const TextStyle(
                            color: HospitalTheme.textMedium,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Status badges in a separate row to prevent overflow
              const SizedBox(height: 8),
              Row(
                children: [
                  // Bed status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasBed
                          ? HospitalTheme.success.withOpacity(0.1)
                          : HospitalTheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasBed
                            ? HospitalTheme.success
                            : HospitalTheme.warning,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasBed ? Icons.bed : Icons.bed_outlined,
                          size: 14,
                          color: hasBed
                              ? HospitalTheme.success
                              : HospitalTheme.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          bedInfo,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: hasBed
                                ? HospitalTheme.success
                                : HospitalTheme.warning,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // IPD status indicator
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ipdUpdated
                          ? HospitalTheme.info.withOpacity(0.1)
                          : HospitalTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ipdUpdated
                            ? HospitalTheme.info
                            : HospitalTheme.error,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          ipdUpdated ? Icons.check_circle : Icons.warning,
                          size: 14,
                          color: ipdUpdated
                              ? HospitalTheme.info
                              : HospitalTheme.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ipdUpdated ? 'IPD Updated' : 'Needs Update',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: ipdUpdated
                                ? HospitalTheme.info
                                : HospitalTheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Optional section info
              if (sectionInfo.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.business,
                        size: 14,
                        color: HospitalTheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sectionInfo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: HospitalTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.person,
                    size: 14,
                    color: HospitalTheme.textMedium,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${patient.gender}, ${patient.age} yrs',
                    style: const TextStyle(
                      fontSize: 12,
                      color: HospitalTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoPatientSelectedView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.personal_injury,
            size: 80,
            color: HospitalTheme.primary,
            semanticLabel: 'Select patient',
          ),
          SizedBox(height: 24),
          Text(
            'Select a patient from the list',
            style: TextStyle(
              fontSize: 20,
              color: HospitalTheme.textMedium,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'to update IPD details and manage deposits',
            style: TextStyle(
              fontSize: 16,
              color: HospitalTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientDetailsForm() {
    return Consumer(
      builder: (context, ref, child) {
        final patient = ref.watch(selectedPatientProvider);
        if (patient == null) return const SizedBox.shrink();

        final formData = ref.watch(formDataProvider);
        final uiState = ref.watch(uiStateProvider);
        final sections = ref.watch(sectionsProvider);
        final availableBeds = ref.watch(availableBedsProvider);

        final hasAdmission = patient.admissionRecords.isNotEmpty;
        final hasBed =
            hasAdmission && patient.admissionRecords.first.bedNumber != null;
        final ipdDetailsUpdated =
            hasAdmission && patient.admissionRecords.first.ipdDetailsUpdated;

        final currentSection =
            hasAdmission && patient.admissionRecords.first.section != null
                ? patient.admissionRecords.first.section
                : null;

        final currentBed =
            hasAdmission ? patient.admissionRecords.first.bedNumber : null;

        final admitNotes =
            hasAdmission ? patient.admissionRecords.first.admitNotes ?? '' : '';

        return Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with patient name
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HospitalTheme.primaryLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: HospitalTheme.primaryLight),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: HospitalTheme.primary,
                        child: Text(
                          patient.name.isNotEmpty
                              ? patient.name.substring(0, 1).toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: HospitalTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${patient.patientId} • Gender: ${patient.gender} • Age: ${patient.age}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: HospitalTheme.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // IPD Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: ipdDetailsUpdated
                                  ? HospitalTheme.success.withOpacity(0.1)
                                  : HospitalTheme.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: ipdDetailsUpdated
                                    ? HospitalTheme.success
                                    : HospitalTheme.warning,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  ipdDetailsUpdated
                                      ? Icons.check_circle
                                      : Icons.pending_actions,
                                  size: 16,
                                  color: ipdDetailsUpdated
                                      ? HospitalTheme.success
                                      : HospitalTheme.warning,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  ipdDetailsUpdated
                                      ? 'IPD Details Complete'
                                      : 'IPD Details Pending',
                                  style: TextStyle(
                                    color: ipdDetailsUpdated
                                        ? HospitalTheme.success
                                        : HospitalTheme.warning,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Admit Note Badge
                          if (admitNotes.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: HospitalTheme.info.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: HospitalTheme.info),
                              ),
                              child: Text(
                                'Admit Note: $admitNotes',
                                style: const TextStyle(
                                  color: HospitalTheme.info,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),

                          // Bed Assignment Badge
                          if (currentSection != null && currentBed != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: HospitalTheme.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: HospitalTheme.success),
                              ),
                              child: Text(
                                '${currentSection.name} - Bed $currentBed',
                                style: const TextStyle(
                                  color: HospitalTheme.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // IPD Details Form
                _buildIpdDetailsSection(
                    formData, uiState, sections, availableBeds),

                const SizedBox(height: 32),

                // Deposit Management Section
                _buildDepositManagementSection(),

                const SizedBox(height: 32),

                // Action Buttons
                _buildActionButtons(uiState, formData, hasBed),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIpdDetailsSection(FormData formData, UIState uiState,
      List<Section> sections, List<int> availableBeds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'IPD Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        const SizedBox(height: 16),

        // Reason for Admission
        _buildFormField(
          label: 'Reason for Admission',
          hint: 'Enter reason for admission',
          controller: reasonController,
          icon: Icons.medical_services,
        ),
        const SizedBox(height: 16),

        // Symptoms
        _buildFormField(
          label: 'Symptoms',
          hint: 'Enter patient symptoms',
          controller: symptomsController,
          icon: Icons.sick,
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Initial Diagnosis
        _buildFormField(
          label: 'Initial Diagnosis',
          hint: 'Enter initial diagnosis',
          controller: diagnosisController,
          icon: Icons.medical_information,
          maxLines: 3,
        ),

        const SizedBox(height: 24),

        // Bed Assignment Section
        const Text(
          'Bed Assignment',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        const SizedBox(height: 16),

        uiState.isLoadingSections
            ? const Center(child: CircularProgressIndicator())
            : sections.isEmpty
                ? const Center(
                    child: Text(
                      'No available sections found',
                      style: TextStyle(color: HospitalTheme.textMedium),
                    ),
                  )
                : Column(
                    children: [
                      // Section Dropdown
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Select Section',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        value: formData.selectedSectionId,
                        onChanged: (value) {
                          if (value != null) {
                            ref
                                .read(formDataProvider.notifier)
                                .setSelectedSection(value);
                            fetchAvailableBeds(value);
                          }
                        },
                        items: sections.map((section) {
                          return DropdownMenuItem<String>(
                            value: section.id,
                            child: Text(
                                '${section.name} (${section.type}) - ${section.availableBeds} beds available'),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Bed Selection
                      if (formData.selectedSectionId != null)
                        uiState.isProcessing
                            ? const Center(child: CircularProgressIndicator())
                            : availableBeds.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        'No available beds in this section',
                                        style: TextStyle(
                                            color: HospitalTheme.textMedium),
                                      ),
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: HospitalTheme.border),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Available Beds',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: HospitalTheme.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 12,
                                          children:
                                              availableBeds.map((bedNumber) {
                                            final isSelected =
                                                formData.selectedBedNumber ==
                                                    bedNumber;
                                            return InkWell(
                                              onTap: () {
                                                ref
                                                    .read(formDataProvider
                                                        .notifier)
                                                    .setSelectedBed(bedNumber);
                                              },
                                              child: Container(
                                                width: 80,
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? HospitalTheme.primary
                                                          .withOpacity(0.2)
                                                      : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? HospitalTheme.primary
                                                        : HospitalTheme.border,
                                                    width: isSelected ? 2 : 1,
                                                  ),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.bed,
                                                      size: 20,
                                                      color: isSelected
                                                          ? HospitalTheme
                                                              .primary
                                                          : HospitalTheme
                                                              .textMedium,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Bed $bedNumber',
                                                      style: TextStyle(
                                                        fontWeight: isSelected
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                        color: isSelected
                                                            ? HospitalTheme
                                                                .primary
                                                            : HospitalTheme
                                                                .textDark,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                    ],
                  ),
      ],
    );
  }

  // Updated deposit management section to show all deposits
  Widget _buildDepositManagementSection() {
    return Consumer(
      builder: (context, ref, _) {
        final patient = ref.watch(selectedPatientProvider);
        final uiState = ref.watch(uiStateProvider);
        final depositForm = ref.watch(depositFormProvider);
        final depositSummary = ref.watch(depositSummaryProvider);

        if (patient == null || patient.admissionRecords.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Deposit Management',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
                if (uiState.isLoadingDepositSummary)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Existing deposits display
            if (depositSummary != null && depositSummary.hasDeposits) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HospitalTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HospitalTheme.success),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          color: HospitalTheme.success,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Deposit Summary (${depositSummary.depositsCount} ${depositSummary.depositsCount == 1 ? 'Receipt' : 'Receipts'})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: HospitalTheme.success,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: HospitalTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: HospitalTheme.primary),
                          ),
                          child: Text(
                            'Total: ${depositSummary.formattedTotalAmount}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: HospitalTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // List of all deposits
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: depositSummary.deposits.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final deposit = depositSummary.deposits[index];
                        return _buildDepositCard(deposit);
                      },
                    ),

                    const SizedBox(height: 12),

                    // Summary info
                    if (depositSummary.firstDeposit != null &&
                        depositSummary.lastDeposit != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'First Deposit',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: HospitalTheme.textMedium,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    _formatDateTime(
                                        depositSummary.firstDeposit!),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: HospitalTheme.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (depositSummary.depositsCount > 1)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Last Deposit',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: HospitalTheme.textMedium,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _formatDateTime(
                                          depositSummary.lastDeposit!),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: HospitalTheme.textDark,
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
              const SizedBox(height: 20),
            ],

            // New deposit form
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: HospitalTheme.border),
                boxShadow: HospitalTheme.shadowSmall,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.add_card,
                        color: HospitalTheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        depositSummary?.hasDeposits == true
                            ? 'Add New Deposit Receipt'
                            : 'Create Deposit Receipt',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: HospitalTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Deposit Amount
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: 'Deposit Amount *',
                          hint: 'Enter deposit amount',
                          controller: depositAmountController,
                          icon: Icons.currency_rupee,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment Method *',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: HospitalTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.payment),
                              ),
                              value: depositForm.paymentMethod,
                              hint: const Text('Select payment method'),
                              onChanged: (value) {
                                if (value != null) {
                                  ref
                                      .read(depositFormProvider.notifier)
                                      .setPaymentMethod(value);
                                }
                              },
                              items: paymentMethods.map((method) {
                                return DropdownMenuItem<String>(
                                  value: method,
                                  child: Text(method),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Conditional fields based on payment method
                  if (depositForm.paymentMethod == 'UPI' ||
                      depositForm.paymentMethod == 'Net Banking')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildFormField(
                        label: 'Transaction ID',
                        hint: 'Enter transaction ID',
                        controller: transactionIdController,
                        icon: Icons.receipt_long,
                      ),
                    ),

                  if (depositForm.paymentMethod == 'Cheque')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildFormField(
                              label: 'Cheque Number',
                              hint: 'Enter cheque number',
                              controller: chequeNumberController,
                              icon: Icons.receipt,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFormField(
                              label: 'Bank Name',
                              hint: 'Enter bank name',
                              controller: bankNameController,
                              icon: Icons.account_balance,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Remarks
                  _buildFormField(
                    label: 'Remarks',
                    hint: 'Enter any remarks (optional)',
                    controller: remarksController,
                    icon: Icons.note,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 20),

                  // Create deposit button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed:
                          (uiState.isCreatingDeposit || !depositForm.isValid)
                              ? null
                              : createDepositReceipt,
                      icon: uiState.isCreatingDeposit
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.receipt_long),
                      label: Text(
                        uiState.isCreatingDeposit
                            ? 'Creating Receipt...'
                            : depositSummary?.hasDeposits == true
                                ? 'Add Another Deposit'
                                : 'Create Deposit Receipt',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HospitalTheme.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  if (!depositForm.isValid && depositForm.paymentMethod != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.info,
                              color: HospitalTheme.warning, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            depositForm.depositAmount == null ||
                                    depositForm.depositAmount! <= 0
                                ? 'Please enter a valid deposit amount'
                                : 'Please fill in all required fields',
                            style: const TextStyle(
                              color: HospitalTheme.warning,
                              fontSize: 14,
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
      },
    );
  }

  Widget _buildDepositCard(DepositRecord deposit) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HospitalTheme.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Sequence number circle
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: HospitalTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: HospitalTheme.primary),
            ),
            child: Center(
              child: Text(
                '${deposit.sequenceNumber}',
                style: const TextStyle(
                  color: HospitalTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Deposit details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      deposit.formattedAmount,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPaymentMethodColor(deposit.paymentMethod)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                _getPaymentMethodColor(deposit.paymentMethod)),
                      ),
                      child: Text(
                        deposit.paymentMethod,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getPaymentMethodColor(deposit.paymentMethod),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Receipt ID: ${deposit.receiptId}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: HospitalTheme.textMedium,
                  ),
                ),
                Text(
                  _formatDateTime(deposit.generatedAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: HospitalTheme.textMedium,
                  ),
                ),
              ],
            ),
          ),

          // View receipt button
          IconButton(
            onPressed: () {
              // You can implement view receipt functionality here
              showSuccessSnackBar('Receipt viewing feature coming soon');
            },
            icon: const Icon(
              Icons.visibility_outlined,
              color: HospitalTheme.primary,
              size: 20,
            ),
            tooltip: 'View Receipt',
          ),
        ],
      ),
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
      case 'net banking':
        return HospitalTheme.info;
      case 'cheque':
        return HospitalTheme.warning;
      default:
        return HospitalTheme.textMedium;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildActionButtons(UIState uiState, FormData formData, bool hasBed) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: uiState.isProcessing ? null : updateIpdDetails,
          icon: uiState.isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.save),
          label: Text(hasBed && formData.selectedSectionId == null
              ? 'Update IPD Details'
              : 'Update & Assign Bed'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            backgroundColor: HospitalTheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: uiState.isProcessing ? null : clearForm,
          icon: const Icon(Icons.clear),
          label: const Text('Clear Form'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            side: const BorderSide(color: HospitalTheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: HospitalTheme.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: HospitalTheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// Model Classes with null safety
class Patient {
  final String id;
  final String patientId;
  final String name;
  final int age;
  final String gender;
  final String? contact;
  final String? address;
  final String? imageUrl;
  final bool discharged;
  final int pendingAmount;
  final List<AdmissionRecord> admissionRecords;

  const Patient({
    required this.id,
    required this.patientId,
    required this.name,
    required this.age,
    required this.gender,
    this.contact,
    this.address,
    this.imageUrl,
    required this.discharged,
    required this.pendingAmount,
    required this.admissionRecords,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['_id'] ?? '',
      patientId: json['patientId'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      contact: json['contact'],
      address: json['address'],
      imageUrl: json['imageUrl'],
      discharged: json['discharged'] ?? false,
      pendingAmount: json['pendingAmount'] ?? 0,
      admissionRecords: json['admissionRecords'] != null
          ? (json['admissionRecords'] as List)
              .map((record) => AdmissionRecord.fromJson(record))
              .toList()
          : [],
    );
  }
}

class SectionInfo {
  final String id;
  final String name;
  final String type;

  const SectionInfo({
    required this.id,
    required this.name,
    required this.type,
  });

  factory SectionInfo.fromJson(Map<String, dynamic> json) {
    return SectionInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
    );
  }
}

class AdmissionRecord {
  final String id;
  final DateTime admissionDate;
  final String status;
  final String? admitNotes;
  final String? reasonForAdmission;
  final String? symptoms;
  final String? initialDiagnosis;
  final int? bedNumber;
  final SectionInfo? section;
  final bool ipdDetailsUpdated;

  const AdmissionRecord({
    required this.id,
    required this.admissionDate,
    required this.status,
    this.admitNotes,
    this.reasonForAdmission,
    this.symptoms,
    this.initialDiagnosis,
    this.bedNumber,
    this.section,
    required this.ipdDetailsUpdated,
  });

  factory AdmissionRecord.fromJson(Map<String, dynamic> json) {
    return AdmissionRecord(
      id: json['_id'] ?? '',
      admissionDate:
          DateTime.tryParse(json['admissionDate'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? '',
      admitNotes: json['admitNotes'],
      reasonForAdmission: json['reasonForAdmission'],
      symptoms: json['symptoms'],
      initialDiagnosis: json['initialDiagnosis'],
      bedNumber: json['bedNumber'],
      section: json['section'] != null
          ? SectionInfo.fromJson(json['section'])
          : null,
      ipdDetailsUpdated: json['ipdDetailsUpdated'] ?? false,
    );
  }
}

class Section {
  final String id;
  final String name;
  final String type;
  final int totalBeds;
  final int availableBeds;
  final bool isActive;

  const Section({
    required this.id,
    required this.name,
    required this.type,
    required this.totalBeds,
    required this.availableBeds,
    required this.isActive,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      totalBeds: json['totalBeds'] ?? 0,
      availableBeds: json['availableBeds'] ?? 0,
      isActive: json['isActive'] ?? false,
    );
  }
}
