import 'dart:convert';
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

  UIState({
    this.isLoadingPatients = false,
    this.isLoadingSections = false,
    this.isProcessing = false,
  });

  UIState copyWith({
    bool? isLoadingPatients,
    bool? isLoadingSections,
    bool? isProcessing,
  }) {
    return UIState(
      isLoadingPatients: isLoadingPatients ?? this.isLoadingPatients,
      isLoadingSections: isLoadingSections ?? this.isLoadingSections,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

class FormData {
  final String? reason;
  final String? symptoms;
  final String? diagnosis;
  final String? selectedSectionId;
  final int? selectedBedNumber;

  FormData({
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
      return FormData();
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
  UIStateNotifier() : super(UIState());

  void setLoadingPatients(bool isLoading) {
    state = state.copyWith(isLoadingPatients: isLoading);
  }

  void setLoadingSections(bool isLoading) {
    state = state.copyWith(isLoadingSections: isLoading);
  }

  void setProcessing(bool isProcessing) {
    state = state.copyWith(isProcessing: isProcessing);
  }
}

class FormDataNotifier extends StateNotifier<FormData> {
  FormDataNotifier() : super(FormData());

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

  // Focus node for keyboard shortcuts
  final FocusNode _shortcutFocusNode = FocusNode();

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
  }

  void clearForm() {
    reasonController.clear();
    symptomsController.clear();
    diagnosisController.clear();
    ref.read(formDataProvider.notifier).clearForm();
    ref.read(selectedPatientProvider.notifier).setPatient(null);
    ref.read(availableBedsProvider.notifier).setBeds([]);
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
              tooltip: 'Refresh data',
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
        final searchQuery = ref.watch(searchQueryProvider);

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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
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
            'to update IPD details and assign bed',
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
                Column(
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
                  ],
                ),

                const SizedBox(height: 24),

                // Bed Assignment Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bed Assignment',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: HospitalTheme.textDark,
                          ),
                        ),
                        if (hasBed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: HospitalTheme.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: HospitalTheme.success),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: HospitalTheme.success,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Bed Already Assigned',
                                  style: TextStyle(
                                    color: HospitalTheme.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    uiState.isLoadingSections
                        ? const Center(child: CircularProgressIndicator())
                        : sections.isEmpty
                            ? const Center(
                                child: Text(
                                  'No available sections found',
                                  style: TextStyle(
                                      color: HospitalTheme.textMedium),
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
                                        ? const Center(
                                            child: CircularProgressIndicator())
                                        : availableBeds.isEmpty
                                            ? const Center(
                                                child: Padding(
                                                  padding: EdgeInsets.all(16.0),
                                                  child: Text(
                                                    'No available beds in this section',
                                                    style: TextStyle(
                                                        color: HospitalTheme
                                                            .textMedium),
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color:
                                                          HospitalTheme.border),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Available Beds',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        color: HospitalTheme
                                                            .textDark,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Wrap(
                                                      spacing: 12,
                                                      runSpacing: 12,
                                                      children: availableBeds
                                                          .map((bedNumber) {
                                                        final isSelected = formData
                                                                .selectedBedNumber ==
                                                            bedNumber;
                                                        return InkWell(
                                                          onTap: () {
                                                            ref
                                                                .read(formDataProvider
                                                                    .notifier)
                                                                .setSelectedBed(
                                                                    bedNumber);
                                                          },
                                                          child: Container(
                                                            width: 80,
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(12),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: isSelected
                                                                  ? HospitalTheme
                                                                      .primary
                                                                      .withOpacity(
                                                                          0.2)
                                                                  : Colors
                                                                      .white,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                              border:
                                                                  Border.all(
                                                                color: isSelected
                                                                    ? HospitalTheme
                                                                        .primary
                                                                    : HospitalTheme
                                                                        .border,
                                                                width:
                                                                    isSelected
                                                                        ? 2
                                                                        : 1,
                                                              ),
                                                            ),
                                                            child: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
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
                                                                const SizedBox(
                                                                    height: 4),
                                                                Text(
                                                                  'Bed $bedNumber',
                                                                  style:
                                                                      TextStyle(
                                                                    fontWeight: isSelected
                                                                        ? FontWeight
                                                                            .bold
                                                                        : FontWeight
                                                                            .normal,
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

                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed:
                              uiState.isProcessing ? null : updateIpdDetails,
                          icon: uiState.isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                              hasBed && formData.selectedSectionId == null
                                  ? 'Update IPD Details'
                                  : 'Update & Assign Bed'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            backgroundColor: HospitalTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: uiState.isProcessing ? null : clearForm,
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Form'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            side:
                                const BorderSide(color: HospitalTheme.primary),
                          ),
                        ),
                      ],
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

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
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

  Patient({
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

  SectionInfo({
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

  AdmissionRecord({
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

  Section({
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
