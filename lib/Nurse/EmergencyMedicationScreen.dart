// emergency_medication_screen.dart
import 'package:doctordesktop/Nurse/NurseLoginScreen.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Emergency Medication Model
class EmergencyMedication {
  final String medicationName;
  final String dosage;
  final String reason;

  const EmergencyMedication({
    required this.medicationName,
    required this.dosage,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'medicationName': medicationName,
      'dosage': dosage,
      'reason': reason,
    };
  }
}

// Form State Provider
final emergencyMedicationFormProvider = StateNotifierProvider<
    EmergencyMedicationFormNotifier, EmergencyMedicationFormState>((ref) {
  return EmergencyMedicationFormNotifier();
});

class EmergencyMedicationFormState {
  final String medicationName;
  final String dosage;
  final String reason;
  final bool isLoading;
  final String? errorMessage;
  final bool isSubmitted;

  const EmergencyMedicationFormState({
    this.medicationName = '',
    this.dosage = '',
    this.reason = '',
    this.isLoading = false,
    this.errorMessage,
    this.isSubmitted = false,
  });

  EmergencyMedicationFormState copyWith({
    String? medicationName,
    String? dosage,
    String? reason,
    bool? isLoading,
    String? errorMessage,
    bool? isSubmitted,
  }) {
    return EmergencyMedicationFormState(
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      reason: reason ?? this.reason,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSubmitted: isSubmitted ?? this.isSubmitted,
    );
  }

  bool get isFormValid =>
      medicationName.trim().isNotEmpty &&
      dosage.trim().isNotEmpty &&
      reason.trim().isNotEmpty;
}

class EmergencyMedicationFormNotifier
    extends StateNotifier<EmergencyMedicationFormState> {
  EmergencyMedicationFormNotifier()
      : super(const EmergencyMedicationFormState());

  void updateMedicationName(String value) {
    state = state.copyWith(medicationName: value, errorMessage: null);
  }

  void updateDosage(String value) {
    state = state.copyWith(dosage: value, errorMessage: null);
  }

  void updateReason(String value) {
    state = state.copyWith(reason: value, errorMessage: null);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? error) {
    state = state.copyWith(errorMessage: error, isLoading: false);
  }

  void setSubmitted(bool isSubmitted) {
    state = state.copyWith(isSubmitted: isSubmitted, isLoading: false);
  }

  void resetForm() {
    state = const EmergencyMedicationFormState();
  }
}

// API Service Provider
final emergencyMedicationServiceProvider =
    Provider<EmergencyMedicationService>((ref) {
  return EmergencyMedicationService(ref.read(httpClientProvider));
});

class EmergencyMedicationService {
  final http.Client _httpClient;

  EmergencyMedicationService(this._httpClient);

  Future<bool> recordEmergencyMedication({
    required String patientId,
    required String admissionId,
    required EmergencyMedication medication,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('nurse_token') ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final url = Uri.parse(
          '$KVM_URL/nurse/recordEmergencyMedication/$patientId/$admissionId');
      final response = await _httpClient
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(medication.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        String errorMessage = 'Failed to record emergency medication';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // Use default error message
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout. Please check your network');
      } else if (e.toString().contains('SocketException')) {
        throw Exception('Network error. Please check your connection');
      }
      rethrow;
    }
  }
}

// Emergency Medication Screen Widget
class EmergencyMedicationScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String admissionId;
  final String patientName;

  const EmergencyMedicationScreen({
    super.key,
    required this.patientId,
    required this.admissionId,
    required this.patientName,
  });

  @override
  ConsumerState<EmergencyMedicationScreen> createState() =>
      _EmergencyMedicationScreenState();
}

class _EmergencyMedicationScreenState
    extends ConsumerState<EmergencyMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medicationController = TextEditingController();
  final _dosageController = TextEditingController();
  final _reasonController = TextEditingController();

  final _medicationFocusNode = FocusNode();
  final _dosageFocusNode = FocusNode();
  final _reasonFocusNode = FocusNode();

  // Common emergency medications for quick selection
  final List<String> _commonMedications = [
    'Epinephrine',
    'Atropine',
    'Lidocaine',
    'Amiodarone',
    'Dopamine',
    'Norepinephrine',
    'Morphine',
    'Diazepam',
    'Lorazepam',
    'Furosemide',
    'Nitroglycerin',
    'Aspirin',
  ];

  // Common dosage formats
  final List<String> _commonDosages = [
    '0.3mg IM',
    '0.5mg IV',
    '1mg IV',
    '2mg IV',
    '5mg IV',
    '10mg IV',
    '25mg IV',
    '50mg IV',
    '100mg IV',
    '1mg/kg IV',
    '0.1mg/kg IV',
    '0.01mg/kg IV',
  ];

  @override
  void initState() {
    super.initState();
    // Reset form when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(emergencyMedicationFormProvider.notifier).resetForm();
    });
  }

  @override
  void dispose() {
    _medicationController.dispose();
    _dosageController.dispose();
    _reasonController.dispose();
    _medicationFocusNode.dispose();
    _dosageFocusNode.dispose();
    _reasonFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyboardShortcuts(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Ctrl/Cmd + Enter to submit form
      if ((HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed) &&
          event.logicalKey == LogicalKeyboardKey.enter) {
        _handleSubmit();
      }
      // Escape to go back
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final formState = ref.read(emergencyMedicationFormProvider);
    if (!formState.isFormValid) return;

    ref.read(emergencyMedicationFormProvider.notifier).setLoading(true);

    try {
      final medication = EmergencyMedication(
        medicationName: formState.medicationName.trim(),
        dosage: formState.dosage.trim(),
        reason: formState.reason.trim(),
      );

      final service = ref.read(emergencyMedicationServiceProvider);
      final success = await service.recordEmergencyMedication(
        patientId: widget.patientId,
        admissionId: widget.admissionId,
        medication: medication,
      );

      if (success) {
        ref.read(emergencyMedicationFormProvider.notifier).setSubmitted(true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Emergency medication recorded successfully'),
              backgroundColor: HospitalTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Navigate back after short delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      }
    } catch (e) {
      ref.read(emergencyMedicationFormProvider.notifier).setError(e.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: HospitalTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _selectMedication(String medication) {
    _medicationController.text = medication;
    ref
        .read(emergencyMedicationFormProvider.notifier)
        .updateMedicationName(medication);
    _dosageFocusNode.requestFocus();
  }

  void _selectDosage(String dosage) {
    _dosageController.text = dosage;
    ref.read(emergencyMedicationFormProvider.notifier).updateDosage(dosage);
    _reasonFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 768;
    final formState = ref.watch(emergencyMedicationFormProvider);

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyboardShortcuts,
      child: Scaffold(
        backgroundColor: HospitalTheme.background,
        appBar: HospitalTheme.buildAppBar(
          context: context,
          title: 'Emergency Medication',
          actions: [
            if (formState.isSubmitted)
              Container(
                margin: const EdgeInsets.only(right: 16.0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: HospitalTheme.success.withOpacity(0.2),
                  borderRadius: HospitalTheme.radiusSmall,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: HospitalTheme.success,
                      size: 16.0,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      'Recorded',
                      style: TextStyle(
                        color: HospitalTheme.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 800.0 : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient Info Header
                  _buildPatientInfoHeader(context, isDesktop),

                  SizedBox(height: isDesktop ? 32.0 : 24.0),

                  // Emergency Alert
                  _buildEmergencyAlert(context, isDesktop),

                  SizedBox(height: isDesktop ? 24.0 : 16.0),

                  // Form Section
                  _buildFormSection(context, formState, isDesktop),

                  SizedBox(height: isDesktop ? 32.0 : 24.0),

                  // Submit Button
                  _buildSubmitButton(context, formState, isDesktop),

                  SizedBox(height: isDesktop ? 24.0 : 16.0),

                  // Keyboard Shortcuts (Desktop only)
                  if (isDesktop) _buildKeyboardShortcuts(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientInfoHeader(BuildContext context, bool isDesktop) {
    return HospitalTheme.buildCard(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: Row(
        children: [
          Container(
            width: isDesktop ? 60.0 : 50.0,
            height: isDesktop ? 60.0 : 50.0,
            decoration: BoxDecoration(
              color: HospitalTheme.emergency.withOpacity(0.1),
              borderRadius: HospitalTheme.radiusMedium,
            ),
            child: Icon(
              Icons.emergency,
              color: HospitalTheme.emergency,
              size: isDesktop ? 30.0 : 25.0,
            ),
          ),
          SizedBox(width: isDesktop ? 16.0 : 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patientName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: HospitalTheme.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Patient ID: ${widget.patientId}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: HospitalTheme.textMedium,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Admission ID: ${widget.admissionId}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HospitalTheme.textLight,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: HospitalTheme.emergency.withOpacity(0.1),
              borderRadius: HospitalTheme.radiusSmall,
            ),
            child: Text(
              'EMERGENCY',
              style: TextStyle(
                color: HospitalTheme.emergency,
                fontWeight: FontWeight.bold,
                fontSize: 12.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyAlert(BuildContext context, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 16.0 : 12.0),
      decoration: BoxDecoration(
        color: HospitalTheme.warning.withOpacity(0.1),
        borderRadius: HospitalTheme.radiusMedium,
        border: Border.all(
          color: HospitalTheme.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber,
            color: HospitalTheme.warning,
            size: isDesktop ? 24.0 : 20.0,
          ),
          SizedBox(width: isDesktop ? 12.0 : 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Medication Protocol',
                  style: TextStyle(
                    color: HospitalTheme.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: isDesktop ? 14.0 : 13.0,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Ensure proper verification of patient identity and medication before administration. Document all emergency interventions immediately.',
                  style: TextStyle(
                    color: HospitalTheme.textMedium,
                    fontSize: isDesktop ? 13.0 : 12.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection(BuildContext context,
      EmergencyMedicationFormState formState, bool isDesktop) {
    return HospitalTheme.buildCard(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medication Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: HospitalTheme.textDark,
                    fontWeight: FontWeight.bold,
                  ),
            ),

            SizedBox(height: isDesktop ? 24.0 : 16.0),

            // Medication Name Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _medicationController,
                  focusNode: _medicationFocusNode,
                  textInputAction: TextInputAction.next,
                  enabled: !formState.isLoading && !formState.isSubmitted,
                  onChanged: (value) => ref
                      .read(emergencyMedicationFormProvider.notifier)
                      .updateMedicationName(value),
                  onFieldSubmitted: (_) => _dosageFocusNode.requestFocus(),
                  decoration: const InputDecoration(
                    labelText: 'Medication Name *',
                    hintText: 'Enter medication name',
                    prefixIcon: Icon(Icons.medication),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Medication name is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12.0),

                // Quick Selection for Medications
                Text(
                  'Quick Select:',
                  style: TextStyle(
                    color: HospitalTheme.textMedium,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _commonMedications
                      .map(
                        (med) => InkWell(
                          onTap: formState.isLoading || formState.isSubmitted
                              ? null
                              : () => _selectMedication(med),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 6.0),
                            decoration: BoxDecoration(
                              color: _medicationController.text == med
                                  ? HospitalTheme.primary.withOpacity(0.1)
                                  : HospitalTheme.surfaceLight,
                              borderRadius: HospitalTheme.radiusSmall,
                              border: Border.all(
                                color: _medicationController.text == med
                                    ? HospitalTheme.primary
                                    : HospitalTheme.border,
                              ),
                            ),
                            child: Text(
                              med,
                              style: TextStyle(
                                fontSize: 12.0,
                                color: _medicationController.text == med
                                    ? HospitalTheme.primary
                                    : HospitalTheme.textMedium,
                                fontWeight: _medicationController.text == med
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),

            SizedBox(height: isDesktop ? 24.0 : 16.0),

            // Dosage Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _dosageController,
                  focusNode: _dosageFocusNode,
                  textInputAction: TextInputAction.next,
                  enabled: !formState.isLoading && !formState.isSubmitted,
                  onChanged: (value) => ref
                      .read(emergencyMedicationFormProvider.notifier)
                      .updateDosage(value),
                  onFieldSubmitted: (_) => _reasonFocusNode.requestFocus(),
                  decoration: const InputDecoration(
                    labelText: 'Dosage *',
                    hintText: 'Enter dosage (e.g., 0.3mg IM)',
                    prefixIcon: Icon(Icons.healing),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Dosage is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12.0),

                // Quick Selection for Dosages
                Text(
                  'Common Dosages:',
                  style: TextStyle(
                    color: HospitalTheme.textMedium,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _commonDosages
                      .map(
                        (dosage) => InkWell(
                          onTap: formState.isLoading || formState.isSubmitted
                              ? null
                              : () => _selectDosage(dosage),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 6.0),
                            decoration: BoxDecoration(
                              color: _dosageController.text == dosage
                                  ? HospitalTheme.secondary.withOpacity(0.1)
                                  : HospitalTheme.surfaceLight,
                              borderRadius: HospitalTheme.radiusSmall,
                              border: Border.all(
                                color: _dosageController.text == dosage
                                    ? HospitalTheme.secondary
                                    : HospitalTheme.border,
                              ),
                            ),
                            child: Text(
                              dosage,
                              style: TextStyle(
                                fontSize: 12.0,
                                color: _dosageController.text == dosage
                                    ? HospitalTheme.secondary
                                    : HospitalTheme.textMedium,
                                fontWeight: _dosageController.text == dosage
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),

            SizedBox(height: isDesktop ? 24.0 : 16.0),

            // Reason Field
            TextFormField(
              controller: _reasonController,
              focusNode: _reasonFocusNode,
              textInputAction: TextInputAction.done,
              enabled: !formState.isLoading && !formState.isSubmitted,
              maxLines: 4,
              onChanged: (value) => ref
                  .read(emergencyMedicationFormProvider.notifier)
                  .updateReason(value),
              onFieldSubmitted: (_) => _handleSubmit(),
              decoration: const InputDecoration(
                labelText: 'Emergency Reason *',
                hintText:
                    'Describe the emergency situation and reason for medication...',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Emergency reason is required';
                }
                if (value.trim().length < 10) {
                  return 'Please provide a detailed reason (at least 10 characters)';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context,
      EmergencyMedicationFormState formState, bool isDesktop) {
    return SizedBox(
      width: double.infinity,
      height: isDesktop ? 56.0 : 48.0,
      child: ElevatedButton.icon(
        onPressed: (formState.isLoading ||
                formState.isSubmitted ||
                !formState.isFormValid)
            ? null
            : _handleSubmit,
        icon: formState.isLoading
            ? SizedBox(
                width: 20.0,
                height: 20.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: Colors.white,
                ),
              )
            : formState.isSubmitted
                ? Icon(Icons.check_circle)
                : Icon(Icons.emergency),
        label: Text(
          formState.isLoading
              ? 'Recording Emergency Medication...'
              : formState.isSubmitted
                  ? 'Emergency Medication Recorded'
                  : 'Record Emergency Medication',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: formState.isSubmitted
              ? HospitalTheme.success
              : HospitalTheme.emergency,
          foregroundColor: Colors.white,
          textStyle: TextStyle(
            fontSize: isDesktop ? 16.0 : 14.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboardShortcuts(BuildContext context) {
    return HospitalTheme.buildCard(
      padding: const EdgeInsets.all(16.0),
      backgroundColor: HospitalTheme.surfaceLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keyboard Shortcuts',
            style: TextStyle(
              color: HospitalTheme.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 14.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            '• Ctrl+Enter: Submit form • Esc: Go back',
            style: TextStyle(
              color: HospitalTheme.textMedium,
              fontSize: 12.0,
            ),
          ),
        ],
      ),
    );
  }
}
