import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';

// Models
class Doctor {
  final String id;
  final String name;
  final String usertype;

  const Doctor({
    required this.id,
    required this.name,
    required this.usertype,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      usertype: json['usertype'] ?? '',
    );
  }
}

class PatientRecord {
  final String id;
  final Doctor? doctor;
  final String admissionId;
  final int opdNumber;
  final int? ipdNumber;
  final DateTime? admissionDate;
  final DateTime? dischargeDate;
  final String status;
  final String patientType;
  final String conditionAtDischarge;
  final double amountToBePayed;
  final double previousRemainingAmount;
  final bool dischargedByReception;
  final double? weight;
  final String? admitNotes;
  final String? reasonForAdmission;
  final String? symptoms;
  final String? initialDiagnosis;
  final int? bedNumber;

  const PatientRecord({
    required this.id,
    this.doctor,
    required this.admissionId,
    required this.opdNumber,
    this.ipdNumber,
    this.admissionDate,
    this.dischargeDate,
    required this.status,
    required this.patientType,
    required this.conditionAtDischarge,
    required this.amountToBePayed,
    required this.previousRemainingAmount,
    required this.dischargedByReception,
    this.weight,
    this.admitNotes,
    this.reasonForAdmission,
    this.symptoms,
    this.initialDiagnosis,
    this.bedNumber,
  });

  factory PatientRecord.fromJson(Map<String, dynamic> json) {
    return PatientRecord(
      id: json['_id'] ?? '',
      doctor: json['doctor'] != null ? Doctor.fromJson(json['doctor']) : null,
      admissionId: json['admissionId'] ?? '',
      opdNumber: (json['opdNumber'] as num?)?.toInt() ?? 0,
      ipdNumber: (json['ipdNumber'] as num?)?.toInt(),
      admissionDate: json['admissionDate'] != null
          ? DateTime.tryParse(json['admissionDate'])
          : null,
      dischargeDate: json['dischargeDate'] != null
          ? DateTime.tryParse(json['dischargeDate'])
          : null,
      status: json['status'] ?? '',
      patientType: json['patientType'] ?? '',
      conditionAtDischarge: json['conditionAtDischarge'] ?? '',
      amountToBePayed: (json['amountToBePayed'] as num?)?.toDouble() ?? 0.0,
      previousRemainingAmount:
          (json['previousRemainingAmount'] as num?)?.toDouble() ?? 0.0,
      dischargedByReception: json['dischargedByReception'] ?? false,
      weight: (json['weight'] as num?)?.toDouble(),
      admitNotes: json['admitNotes'],
      reasonForAdmission: json['reasonForAdmission'],
      symptoms: json['symptoms'],
      initialDiagnosis: json['initialDiagnosis'],
      bedNumber: (json['bedNumber'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'opdNumber': opdNumber,
      'ipdNumber': ipdNumber,
      'admissionDate': admissionDate?.toIso8601String(),
      'dischargeDate': dischargeDate?.toIso8601String(),
      'status': status,
      'patientType': patientType,
      'admitNotes': admitNotes ?? '',
      'reasonForAdmission': reasonForAdmission ?? '',
      'conditionAtDischarge': conditionAtDischarge,
      'amountToBePayed': amountToBePayed,
      'previousRemainingAmount': previousRemainingAmount,
      'weight': weight ?? 0,
      'symptoms': symptoms ?? '',
      'initialDiagnosis': initialDiagnosis ?? '',
      'bedNumber': bedNumber,
    };
  }

  PatientRecord copyWith({
    String? id,
    Doctor? doctor,
    String? admissionId,
    int? opdNumber,
    int? ipdNumber,
    DateTime? admissionDate,
    DateTime? dischargeDate,
    String? status,
    String? patientType,
    String? conditionAtDischarge,
    double? amountToBePayed,
    double? previousRemainingAmount,
    bool? dischargedByReception,
    double? weight,
    String? admitNotes,
    String? reasonForAdmission,
    String? symptoms,
    String? initialDiagnosis,
    int? bedNumber,
  }) {
    return PatientRecord(
      id: id ?? this.id,
      doctor: doctor ?? this.doctor,
      admissionId: admissionId ?? this.admissionId,
      opdNumber: opdNumber ?? this.opdNumber,
      ipdNumber: ipdNumber ?? this.ipdNumber,
      admissionDate: admissionDate ?? this.admissionDate,
      dischargeDate: dischargeDate ?? this.dischargeDate,
      status: status ?? this.status,
      patientType: patientType ?? this.patientType,
      conditionAtDischarge: conditionAtDischarge ?? this.conditionAtDischarge,
      amountToBePayed: amountToBePayed ?? this.amountToBePayed,
      previousRemainingAmount:
          previousRemainingAmount ?? this.previousRemainingAmount,
      dischargedByReception:
          dischargedByReception ?? this.dischargedByReception,
      weight: weight ?? this.weight,
      admitNotes: admitNotes ?? this.admitNotes,
      reasonForAdmission: reasonForAdmission ?? this.reasonForAdmission,
      symptoms: symptoms ?? this.symptoms,
      initialDiagnosis: initialDiagnosis ?? this.initialDiagnosis,
      bedNumber: bedNumber ?? this.bedNumber,
    );
  }
}

class Patient {
  final String patientId;
  final String name;
  final String gender;
  final int age;
  final String contact;
  final String address;
  final PatientRecord? lastRecord;

  const Patient({
    required this.patientId,
    required this.name,
    required this.gender,
    required this.age,
    required this.contact,
    required this.address,
    this.lastRecord,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      patientId: json['patientId'] ?? '',
      name: json['name'] ?? '',
      gender: json['gender'] ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      contact: json['contact'] ?? '',
      address: json['address'] ?? '',
      lastRecord: json['lastRecord'] != null
          ? PatientRecord.fromJson(json['lastRecord'])
          : null,
    );
  }
}

// State classes
class PatientRecordsState {
  final List<Patient> patients;
  final Patient? selectedPatient;
  final PatientRecord? selectedRecord;
  final bool isLoading;
  final String? error;
  final bool isUpdating;
  final String? successMessage; // Add this

  const PatientRecordsState({
    this.patients = const [],
    this.selectedPatient,
    this.selectedRecord,
    this.isLoading = false,
    this.error,
    this.isUpdating = false,
    this.successMessage, // Add this
  });

  PatientRecordsState copyWith({
    List<Patient>? patients,
    Patient? selectedPatient,
    PatientRecord? selectedRecord,
    bool? isLoading,
    String? error,
    bool? isUpdating,
    String? successMessage, // Add this
  }) {
    return PatientRecordsState(
      patients: patients ?? this.patients,
      selectedPatient: selectedPatient ?? this.selectedPatient,
      selectedRecord: selectedRecord ?? this.selectedRecord,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isUpdating: isUpdating ?? this.isUpdating,
      successMessage: successMessage, // Add this
    );
  }
}

// API Service
class PatientRecordsService {
  static const String baseUrl = '${BASE_URL}';

  static Future<List<Patient>> getAllPatientsLastRecords() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/master/getAllPatientsLastRecords'),
        headers: {'Content-Type': 'application/json'},
      );
      print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> patientsJson = data['data'];
          return patientsJson.map((json) => Patient.fromJson(json)).toList();
        }
      }
      throw Exception('Failed to load patients: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<void> updatePatientRecord(
      String patientId, String recordId, PatientRecord record) async {
    try {
      final response = await http.put(
        Uri.parse(
            '$baseUrl/master/patient-history/$patientId/record/$recordId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(record.toJson()),
      );
      print("response.body: ${response.body}");
      if (response.statusCode != 200) {
        throw Exception('Failed to update record: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Update error: $e');
    }
  }
}

// Provider
class PatientRecordsNotifier extends StateNotifier<PatientRecordsState> {
  PatientRecordsNotifier() : super(const PatientRecordsState());

  Future<void> loadPatients() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final patients = await PatientRecordsService.getAllPatientsLastRecords();
      state = state.copyWith(
        patients: patients,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void selectPatient(Patient patient) {
    state = state.copyWith(
      selectedPatient: patient,
      selectedRecord: patient.lastRecord,
    );
  }

  void clearSelection() {
    state = state.copyWith(
      selectedPatient: null,
      selectedRecord: null,
    );
  }

  Future<void> updateRecord(PatientRecord updatedRecord) async {
    if (state.selectedPatient == null || state.selectedRecord == null) return;

    state = state.copyWith(isUpdating: true, error: null, successMessage: null);

    try {
      await PatientRecordsService.updatePatientRecord(
        state.selectedPatient!.patientId,
        state.selectedRecord!.id,
        updatedRecord,
      );

      // Update local state
      final updatedPatients = state.patients.map((patient) {
        if (patient.patientId == state.selectedPatient!.patientId) {
          return Patient(
            patientId: patient.patientId,
            name: patient.name,
            gender: patient.gender,
            age: patient.age,
            contact: patient.contact,
            address: patient.address,
            lastRecord: updatedRecord,
          );
        }
        return patient;
      }).toList();

      // Create updated patient with new record
      final updatedPatient = Patient(
        patientId: state.selectedPatient!.patientId,
        name: state.selectedPatient!.name,
        gender: state.selectedPatient!.gender,
        age: state.selectedPatient!.age,
        contact: state.selectedPatient!.contact,
        address: state.selectedPatient!.address,
        lastRecord: updatedRecord,
      );

      state = state.copyWith(
        patients: updatedPatients,
        selectedPatient: updatedPatient, // Update the selected patient too!
        selectedRecord: updatedRecord,
        isUpdating: false,
        successMessage: 'Patient record updated successfully!',
      );
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
    }
  }

  void clearMessages() {
    // Add this method
    state = state.copyWith(error: null, successMessage: null);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final patientRecordsProvider =
    StateNotifierProvider<PatientRecordsNotifier, PatientRecordsState>((ref) {
  return PatientRecordsNotifier();
});

// Utility function for Indian date/time formatting
class DateTimeUtils {
  static final _indianDateFormat = DateFormat('dd/MM/yyyy');
  static final _indianTimeFormat = DateFormat('hh:mm a');
  static final _indianDateTimeFormat = DateFormat('dd/MM/yyyy, hh:mm a');

  static String formatIndianDate(DateTime dateTime) {
    return _indianDateFormat.format(dateTime);
  }

  static String formatIndianTime(DateTime dateTime) {
    return _indianTimeFormat.format(dateTime);
  }

  static String formatIndianDateTime(DateTime dateTime) {
    // Convert to IST (UTC+5:30)
    final istDateTime = dateTime.toLocal();
    return _indianDateTimeFormat.format(istDateTime);
  }
}

// Main Screen
class PatientRecordsManagementScreen extends ConsumerStatefulWidget {
  const PatientRecordsManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PatientRecordsManagementScreen> createState() =>
      _PatientRecordsManagementScreenState();
}

class _PatientRecordsManagementScreenState
    extends ConsumerState<PatientRecordsManagementScreen> {
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(patientRecordsProvider.notifier).loadPatients();
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientRecordsProvider);
    final screenSize = MediaQuery.of(context).size;

    // Listen for success/error messages
    ref.listen<PatientRecordsState>(patientRecordsProvider,
        (previous, current) {
      if (current.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(current.successMessage!),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
        // Clear the message after showing
        Future.delayed(const Duration(milliseconds: 100), () {
          ref.read(patientRecordsProvider.notifier).clearMessages();
        });
      }

      if (current.error != null && previous?.error != current.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(current.error!)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    });

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // Ctrl+F or Cmd+F for search
          if ((event.logicalKey == LogicalKeyboardKey.keyF) &&
              (HardwareKeyboard.instance.isControlPressed ||
                  HardwareKeyboard.instance.isMetaPressed)) {
            // Focus search field
            return KeyEventResult.handled;
          }
          // F5 for refresh
          if (event.logicalKey == LogicalKeyboardKey.f5) {
            ref.read(patientRecordsProvider.notifier).loadPatients();
            return KeyEventResult.handled;
          }
          // ESC to clear selection
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            ref.read(patientRecordsProvider.notifier).clearSelection();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Patient Latest Discharge Record',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF00477A),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () =>
                  ref.read(patientRecordsProvider.notifier).loadPatients(),
              tooltip: 'Refresh (F5)',
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.error != null
                ? _buildErrorWidget(state.error!)
                : Row(
                    children: [
                      // Left Panel - Patients List
                      SizedBox(
                        width: screenSize.width * 0.30,
                        child: _PatientListPanel(
                          patients: state.patients,
                          selectedPatient: state.selectedPatient,
                          searchQuery: searchQuery,
                          onSearchChanged: (query) {
                            setState(() {
                              searchQuery = query;
                            });
                          },
                          onPatientSelected: (patient) {
                            ref
                                .read(patientRecordsProvider.notifier)
                                .selectPatient(patient);
                          },
                        ),
                      ),

                      // Divider
                      Container(
                        width: 1,
                        color: const Color(0xFF00477A).withOpacity(0.2),
                      ),

                      // Middle Panel - Patient Details
                      SizedBox(
                        width: screenSize.width * 0.30,
                        child: _PatientDetailsPanel(
                          patient: state.selectedPatient,
                        ),
                      ),

                      // Divider
                      Container(
                        width: 1,
                        color: const Color(0xFF00477A).withOpacity(0.2),
                      ),

                      // Right Panel - Record Editor
                      Expanded(
                        child: _RecordEditorPanel(
                          record: state.selectedRecord,
                          patient: state.selectedPatient,
                          isUpdating: state.isUpdating,
                          onRecordUpdate: (updatedRecord) {
                            ref
                                .read(patientRecordsProvider.notifier)
                                .updateRecord(updatedRecord);
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Data',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(patientRecordsProvider.notifier).loadPatients();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005F9E),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// Left Panel - Patients List
class _PatientListPanel extends StatelessWidget {
  final List<Patient> patients;
  final Patient? selectedPatient;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<Patient> onPatientSelected;

  const _PatientListPanel({
    required this.patients,
    required this.selectedPatient,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onPatientSelected,
  });

  @override
  Widget build(BuildContext context) {
    final filteredPatients = patients.where((patient) {
      final query = searchQuery.toLowerCase();
      return patient.name.toLowerCase().contains(query) ||
          patient.patientId.toLowerCase().contains(query) ||
          patient.contact.contains(query);
    }).toList();

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF00477A).withOpacity(0.05),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF00477A).withOpacity(0.2),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patients',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search patients...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFF005F9E), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${filteredPatients.length} patients found',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Patients List
          Expanded(
            child: filteredPatients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty
                              ? 'No patients available'
                              : 'No patients found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: filteredPatients.length,
                    itemBuilder: (context, index) {
                      final patient = filteredPatients[index];
                      final isSelected =
                          selectedPatient?.patientId == patient.patientId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: isSelected
                              ? const Color(0xFF005F9E).withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () => onPatientSelected(patient),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF005F9E)
                                      : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF005F9E)
                                              .withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          patient.gender.toLowerCase() == 'male'
                                              ? Icons.male
                                              : patient.gender.toLowerCase() ==
                                                      'female'
                                                  ? Icons.female
                                                  : Icons.person,
                                          color: const Color(0xFF005F9E),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              patient.name,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[800],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'ID: ${patient.patientId}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (patient.lastRecord != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(patient
                                                    .lastRecord!
                                                    .conditionAtDischarge)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            patient.lastRecord!
                                                .conditionAtDischarge,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: _getStatusColor(patient
                                                  .lastRecord!
                                                  .conditionAtDischarge),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.phone,
                                        size: 12,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          patient.contact,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.cake,
                                        size: 12,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${patient.age}y',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'discharged':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'admitted':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

// Middle Panel - Patient Details
class _PatientDetailsPanel extends StatelessWidget {
  final Patient? patient;

  const _PatientDetailsPanel({
    required this.patient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF00477A).withOpacity(0.05),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF00477A).withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Patient Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                if (patient != null)
                  Icon(
                    Icons.person,
                    color: Colors.grey[600],
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: patient == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a patient to view details',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Patient Info Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with avatar
                              Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF005F9E)
                                          .withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      patient!.gender.toLowerCase() == 'male'
                                          ? Icons.male
                                          : patient!.gender.toLowerCase() ==
                                                  'female'
                                              ? Icons.female
                                              : Icons.person,
                                      color: const Color(0xFF005F9E),
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          patient!.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'ID: ${patient!.patientId}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Patient details grid
                              _buildDetailRow(
                                  'Gender', patient!.gender, Icons.person),
                              _buildDetailRow(
                                  'Age', '${patient!.age} years', Icons.cake),
                              _buildDetailRow(
                                  'Contact', patient!.contact, Icons.phone),
                              _buildDetailRow('Address', patient!.address,
                                  Icons.location_on),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Last Record Info
                        if (patient!.lastRecord != null) ...[
                          // Debug information - removed from collection
                          Text(
                            'Last Medical Record',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Status badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(patient!
                                            .lastRecord!.conditionAtDischarge)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    patient!.lastRecord!.conditionAtDischarge,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(patient!
                                          .lastRecord!.conditionAtDischarge),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: patient!
                                            .lastRecord!.dischargedByReception
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    patient!.lastRecord!.dischargedByReception
                                        ? "Discharged by Reception"
                                        : "Not Discharged by Reception",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: patient!
                                              .lastRecord!.dischargedByReception
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Record details
                                _buildDetailRow(
                                    'Doctor',
                                    patient!.lastRecord!.doctor?.name ?? 'N/A',
                                    Icons.medical_services),
                                _buildDetailRow(
                                    'OPD Number',
                                    '${patient!.lastRecord!.opdNumber}',
                                    Icons.numbers),
                                if (patient!.lastRecord!.ipdNumber != null)
                                  _buildDetailRow(
                                      'IPD Number',
                                      '${patient!.lastRecord!.ipdNumber}',
                                      Icons.local_hospital),
                                if (patient!.lastRecord!.admissionDate != null)
                                  _buildDetailRow(
                                    'Admission Date',
                                    DateTimeUtils.formatIndianDateTime(
                                        patient!.lastRecord!.admissionDate!),
                                    Icons.event,
                                  ),
                                if (patient!.lastRecord!.dischargeDate != null)
                                  _buildDetailRow(
                                    'Discharge Date',
                                    DateTimeUtils.formatIndianDateTime(
                                        patient!.lastRecord!.dischargeDate!),
                                    Icons.event_available,
                                  ),
                                _buildDetailRow(
                                    'Patient Type',
                                    patient!.lastRecord!.patientType,
                                    Icons.category),
                                _buildDetailRow(
                                    'Amount to Pay',
                                    '₹${patient!.lastRecord!.amountToBePayed.toStringAsFixed(2)}',
                                    Icons.payment),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'discharged':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'admitted':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

// Right Panel - Record Editor
class _RecordEditorPanel extends StatefulWidget {
  final PatientRecord? record;
  final Patient? patient;
  final bool isUpdating;
  final ValueChanged<PatientRecord> onRecordUpdate;

  const _RecordEditorPanel({
    required this.record,
    required this.patient,
    required this.isUpdating,
    required this.onRecordUpdate,
  });

  @override
  State<_RecordEditorPanel> createState() => _RecordEditorPanelState();
}

class _RecordEditorPanelState extends State<_RecordEditorPanel> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _opdNumberController;
  late TextEditingController _ipdNumberController;
  late TextEditingController _statusController;
  late TextEditingController _patientTypeController;
  late TextEditingController _admitNotesController;
  late TextEditingController _reasonController;
  late TextEditingController _conditionController;
  late TextEditingController _amountController;
  late TextEditingController _previousAmountController;
  late TextEditingController _weightController;
  late TextEditingController _symptomsController;
  late TextEditingController _diagnosisController;
  late TextEditingController _bedNumberController;

  DateTime? _admissionDate;
  DateTime? _dischargeDate;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(_RecordEditorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.record != widget.record) {
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    final record = widget.record;

    _opdNumberController =
        TextEditingController(text: record?.opdNumber.toString() ?? '');
    _ipdNumberController =
        TextEditingController(text: record?.ipdNumber?.toString() ?? '');
    _statusController = TextEditingController(text: record?.status ?? '');
    _patientTypeController =
        TextEditingController(text: record?.patientType ?? '');
    _admitNotesController =
        TextEditingController(text: record?.admitNotes ?? '');
    _reasonController =
        TextEditingController(text: record?.reasonForAdmission ?? '');
    _conditionController =
        TextEditingController(text: record?.conditionAtDischarge ?? '');
    _amountController =
        TextEditingController(text: record?.amountToBePayed.toString() ?? '0');
    _previousAmountController = TextEditingController(
        text: record?.previousRemainingAmount.toString() ?? '0');
    _weightController =
        TextEditingController(text: record?.weight?.toString() ?? '');
    _symptomsController = TextEditingController(text: record?.symptoms ?? '');
    _diagnosisController =
        TextEditingController(text: record?.initialDiagnosis ?? '');
    _bedNumberController =
        TextEditingController(text: record?.bedNumber?.toString() ?? '');

    _admissionDate = record?.admissionDate;
    _dischargeDate = record?.dischargeDate;
  }

  @override
  void dispose() {
    _opdNumberController.dispose();
    _ipdNumberController.dispose();
    _statusController.dispose();
    _patientTypeController.dispose();
    _admitNotesController.dispose();
    _reasonController.dispose();
    _conditionController.dispose();
    _amountController.dispose();
    _previousAmountController.dispose();
    _weightController.dispose();
    _symptomsController.dispose();
    _diagnosisController.dispose();
    _bedNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF00477A).withOpacity(0.05),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF00477A).withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Record Editor',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                if (widget.record != null) ...[
                  ElevatedButton.icon(
                    onPressed: widget.isUpdating ? null : _saveRecord,
                    icon: widget.isUpdating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(widget.isUpdating ? 'Saving...' : 'Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005F9E),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: widget.isUpdating ? null : _resetForm,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF005F9E),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Content
          Expanded(
            child: widget.record == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_document,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a patient to edit their record',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Basic Information Section
                          _buildSectionHeader('Basic Information'),
                          _buildTextField(
                            controller: _opdNumberController,
                            label: 'OPD Number',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Required';
                              if (int.tryParse(value!) == null)
                                return 'Invalid number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _ipdNumberController,
                            label: 'IPD Number',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          // _buildDropdownField(
                          //   value: _statusController.text,
                          //   label: 'Status',
                          //   items: ['Pending', 'Admitted', 'Discharged'],
                          //   onChanged: (value) =>
                          //       _statusController.text = value ?? '',
                          // ),
                          const SizedBox(height: 12),
                          _buildDropdownField(
                            value: _patientTypeController.text,
                            label: 'Patient Type',
                            items: ['Internal', 'External', 'Emergency'],
                            onChanged: (value) =>
                                _patientTypeController.text = value ?? '',
                          ),

                          // Dates Section
                          const SizedBox(height: 20),
                          _buildSectionHeader('Dates'),
                          _buildDateField(
                            label: 'Admission Date',
                            value: _admissionDate,
                            onChanged: (date) =>
                                setState(() => _admissionDate = date),
                          ),
                          const SizedBox(height: 12),
                          _buildDateField(
                            label: 'Discharge Date',
                            value: _dischargeDate,
                            onChanged: (date) =>
                                setState(() => _dischargeDate = date),
                          ),

                          // Medical Information Section
                          const SizedBox(height: 20),
                          _buildSectionHeader('Medical Information'),
                          _buildTextField(
                            controller: _weightController,
                            label: 'Weight (kg)',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _bedNumberController,
                            label: 'Bed Number',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _symptomsController,
                            label: 'Symptoms',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _diagnosisController,
                            label: 'Initial Diagnosis',
                            maxLines: 3,
                          ),

                          // Notes Section
                          const SizedBox(height: 20),
                          _buildSectionHeader('Notes'),
                          _buildTextField(
                            controller: _admitNotesController,
                            label: 'Admission Notes',
                            maxLines: 4,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _reasonController,
                            label: 'Reason for Admission',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          // _buildTextField(
                          //   controller: _conditionController,
                          //   label: 'Condition at Discharge',
                          //   maxLines: 3,
                          // ),

                          // Financial Information Section
                          const SizedBox(height: 20),
                          _buildSectionHeader('Financial Information'),
                          _buildTextField(
                            controller: _amountController,
                            label: 'Amount to be Paid',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Required';
                              if (double.tryParse(value!) == null)
                                return 'Invalid amount';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          // _buildTextField(
                          //   controller: _previousAmountController,
                          //   label: 'Previous Remaining Amount',
                          //   keyboardType: TextInputType.number,
                          //   validator: (value) {
                          //     if (value?.isEmpty ?? true) return 'Required';
                          //     if (double.tryParse(value!) == null)
                          //       return 'Invalid amount';
                          //     return null;
                          //   },
                          // ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF005F9E), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value.isNotEmpty && items.contains(value) ? value : null,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF005F9E), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(value ?? DateTime.now()),
          );
          if (time != null) {
            onChanged(DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            ));
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value != null
                        ? DateTimeUtils.formatIndianDateTime(value)
                        : 'Select date & time',
                    style: TextStyle(
                      fontSize: 16,
                      color: value != null ? Colors.black : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.calendar_today,
              color: Colors.grey[600],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _saveRecord() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedRecord = widget.record!.copyWith(
        opdNumber: int.tryParse(_opdNumberController.text) ?? 0,
        ipdNumber: int.tryParse(_ipdNumberController.text),
        status: _statusController.text,
        patientType: _patientTypeController.text,
        admissionDate: _admissionDate,
        dischargeDate: _dischargeDate,
        admitNotes: _admitNotesController.text,
        reasonForAdmission: _reasonController.text,
        conditionAtDischarge: _conditionController.text,
        amountToBePayed: double.tryParse(_amountController.text) ?? 0.0,
        previousRemainingAmount:
            double.tryParse(_previousAmountController.text) ?? 0.0,
        weight: double.tryParse(_weightController.text),
        symptoms: _symptomsController.text,
        initialDiagnosis: _diagnosisController.text,
        bedNumber: int.tryParse(_bedNumberController.text),
      );

      widget.onRecordUpdate(updatedRecord);
    }
  }

  void _resetForm() {
    _initializeControllers();
    setState(() {});
  }
}
