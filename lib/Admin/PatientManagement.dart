import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Models
class Patient {
  final String id;
  final String patientId;
  final String name;
  final int age;
  final String gender;
  final String contact;
  final String address;
  final String imageUrl;
  final bool discharged;
  final double pendingAmount;
  final List<AdmissionRecord> admissionRecords;
  final int admissionCount;
  final AdmissionRecord? latestAdmission;
  final bool hasActiveAdmissions;

  const Patient({
    required this.id,
    required this.patientId,
    required this.name,
    required this.age,
    required this.gender,
    required this.contact,
    required this.address,
    required this.imageUrl,
    required this.discharged,
    required this.pendingAmount,
    required this.admissionRecords,
    required this.admissionCount,
    this.latestAdmission,
    required this.hasActiveAdmissions,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['_id'] ?? '',
      patientId: json['patientId'] ?? '',
      name: json['name'] ?? 'Unknown',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? 'Not specified',
      contact: json['contact'] ?? '',
      address: json['address'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      discharged: json['discharged'] ?? false,
      pendingAmount: (json['pendingAmount'] ?? 0).toDouble(),
      admissionRecords: (json['admissionRecords'] as List?)
              ?.map((e) => AdmissionRecord.fromJson(e))
              .toList() ??
          [],
      admissionCount: json['admissionCount'] ?? 0,
      latestAdmission: json['latestAdmission'] != null
          ? AdmissionRecord.fromJson(json['latestAdmission'])
          : null,
      hasActiveAdmissions: json['hasActiveAdmissions'] ?? false,
    );
  }

  Patient copyWith({
    String? name,
    int? age,
    String? gender,
    String? contact,
    String? address,
    String? imageUrl,
    double? pendingAmount,
  }) {
    return Patient(
      id: id,
      patientId: patientId,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      contact: contact ?? this.contact,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      discharged: discharged,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      admissionRecords: admissionRecords,
      admissionCount: admissionCount,
      latestAdmission: latestAdmission,
      hasActiveAdmissions: hasActiveAdmissions,
    );
  }
}

class AdmissionRecord {
  final String id;
  final DateTime admissionDate;
  final String status;
  final String patientType;
  final double weight;
  final bool ipdDetailsUpdated;
  final Doctor? doctor;
  final String admitNotes;

  const AdmissionRecord({
    required this.id,
    required this.admissionDate,
    required this.status,
    required this.patientType,
    required this.weight,
    required this.ipdDetailsUpdated,
    this.doctor,
    required this.admitNotes,
  });

  factory AdmissionRecord.fromJson(Map<String, dynamic> json) {
    return AdmissionRecord(
      id: json['_id'] ?? '',
      admissionDate:
          DateTime.tryParse(json['admissionDate'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'Unknown',
      patientType: json['patientType'] ?? 'Unknown',
      weight: (json['weight'] ?? 0).toDouble(),
      ipdDetailsUpdated: json['ipdDetailsUpdated'] ?? false,
      doctor: json['doctor'] != null ? Doctor.fromJson(json['doctor']) : null,
      admitNotes: json['admitNotes'] ?? '',
    );
  }
}

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
      id: json['id']?['_id'] ?? json['_id'] ?? '',
      name: json['name'] ?? 'Unknown Doctor',
      usertype: json['usertype'] ?? 'doctor',
    );
  }
}

class PatientResponse {
  final List<Patient> patients;
  final Pagination pagination;

  const PatientResponse({
    required this.patients,
    required this.pagination,
  });

  factory PatientResponse.fromJson(Map<String, dynamic> json) {
    return PatientResponse(
      patients: (json['data']?['patients'] as List?)
              ?.map((e) => Patient.fromJson(e))
              .toList() ??
          [],
      pagination: Pagination.fromJson(json['data']?['pagination'] ?? {}),
    );
  }
}

class Pagination {
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final int limit;
  final bool hasNextPage;
  final bool hasPrevPage;

  const Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.limit,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalCount: json['totalCount'] ?? 0,
      limit: json['limit'] ?? 10,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPrevPage: json['hasPrevPage'] ?? false,
    );
  }
}

// API Service
class AdmissionApiService {
  static Future<PatientResponse> getPatients(
      {int page = 1, int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$KVM_URL/reception/getPatientsWithAdmissions?page=$page&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );
      print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PatientResponse.fromJson(data);
      } else {
        throw Exception('Failed to load patients: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Patient> updatePatientInfo(
      String patientId, Map<String, dynamic> updates) async {
    try {
      final response = await http.patch(
        Uri.parse('$KVM_URL/reception/updatePatientInfo/$patientId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updates),
      );
      print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Patient.fromJson(data['data']);
      } else {
        throw Exception('Failed to update patient: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<void> deleteAdmissionRecord(
      String patientId, String admissionId) async {
    print('$KVM_URL/reception/deleteAdmissionRecord/$patientId/$admissionId');
    try {
      final response = await http.delete(
        Uri.parse('$KVM_URL/deleteAdmissionRecord/$patientId/$admissionId'),
        headers: {'Content-Type': 'application/json'},
      );
      print(response.body);

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to delete admission record: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

// Providers
final patientsProvider =
    FutureProvider.autoDispose.family<PatientResponse, int>((ref, page) async {
  return AdmissionApiService.getPatients(page: page);
});

final selectedPatientProvider = StateProvider<Patient?>((ref) => null);

final searchQueryProvider = StateProvider<String>((ref) => '');

final currentPageProvider = StateProvider<int>((ref) => 1);

final filteredPatientsProvider = Provider<List<Patient>>((ref) {
  final patientsAsync =
      ref.watch(patientsProvider(ref.watch(currentPageProvider)));
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

  return patientsAsync.when(
    data: (patientResponse) {
      if (searchQuery.isEmpty) {
        return patientResponse.patients;
      }
      return patientResponse.patients.where((patient) {
        return patient.name.toLowerCase().contains(searchQuery) ||
            patient.patientId.toLowerCase().contains(searchQuery) ||
            patient.contact.contains(searchQuery);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Main Screen
class AdmissionManagementScreen extends ConsumerStatefulWidget {
  const AdmissionManagementScreen({super.key});

  @override
  ConsumerState<AdmissionManagementScreen> createState() =>
      _AdmissionManagementScreenState();
}

class _AdmissionManagementScreenState
    extends ConsumerState<AdmissionManagementScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(searchQueryProvider.notifier).state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: HospitalTheme.buildAppBar(
        context: context,
        title: 'Admission Management',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _refreshData(),
            tooltip: 'Refresh (Ctrl+R)',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: KeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: screenWidth > 1024
            ? _buildDesktopLayout(screenWidth, screenHeight)
            : _buildMobileLayout(screenWidth, screenHeight),
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrlPressed = HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;

      if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyR) {
        _refreshData();
      } else if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyF) {
        // Focus search field
        FocusScope.of(context).requestFocus();
      }
    }
  }

  void _refreshData() {
    ref.invalidate(patientsProvider);
  }

  Widget _buildDesktopLayout(double screenWidth, double screenHeight) {
    return Row(
      children: [
        // Master Panel - Patient List
        SizedBox(
          width: screenWidth * 0.4,
          child: _buildMasterPanel(),
        ),
        // Divider
        const VerticalDivider(width: 1),
        // Detail Panel - Patient Details
        Expanded(
          child: _buildDetailPanel(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(double screenWidth, double screenHeight) {
    final selectedPatient = ref.watch(selectedPatientProvider);

    return selectedPatient == null ? _buildMasterPanel() : _buildDetailPanel();
  }

  Widget _buildMasterPanel() {
    final filteredPatients = ref.watch(filteredPatientsProvider);
    final patientsAsync =
        ref.watch(patientsProvider(ref.watch(currentPageProvider)));

    return Column(
      children: [
        // Search and Filters
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: HospitalTheme.border),
            ),
          ),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search patients...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              // Stats Row
              patientsAsync.when(
                data: (patientResponse) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatChip(
                      'Total: ${patientResponse.pagination.totalCount}',
                      Icons.people,
                      HospitalTheme.primary,
                    ),
                    _buildStatChip(
                      'Admitted: ${filteredPatients.where((p) => p.hasActiveAdmissions).length}',
                      Icons.local_hospital,
                      HospitalTheme.success,
                    ),
                    _buildStatChip(
                      'Discharged: ${filteredPatients.where((p) => p.discharged).length}',
                      Icons.exit_to_app,
                      HospitalTheme.info,
                    ),
                  ],
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        // Patient List
        Expanded(
          child: patientsAsync.when(
            data: (patientResponse) => filteredPatients.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: filteredPatients.length,
                    itemBuilder: (context, index) {
                      final patient = filteredPatients[index];
                      return _buildPatientListTile(patient);
                    },
                  ),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => _buildErrorState(error.toString()),
          ),
        ),
        // Pagination
        patientsAsync.when(
          data: (patientResponse) =>
              _buildPagination(patientResponse.pagination),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildDetailPanel() {
    final selectedPatient = ref.watch(selectedPatientProvider);

    if (selectedPatient == null) {
      return _buildSelectPatientState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Header
          _buildPatientHeader(selectedPatient),
          const SizedBox(height: 24),
          // Patient Details
          _buildPatientDetails(selectedPatient),
          const SizedBox(height: 24),
          // Admission Records
          _buildAdmissionRecords(selectedPatient),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientListTile(Patient patient) {
    final selectedPatient = ref.watch(selectedPatientProvider);
    final isSelected = selectedPatient?.id == patient.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? HospitalTheme.surfaceLight : null,
        borderRadius: HospitalTheme.radiusSmall,
        border: isSelected ? Border.all(color: HospitalTheme.primary) : null,
      ),
      child: ListTile(
        onTap: () {
          ref.read(selectedPatientProvider.notifier).state = patient;
        },
        leading: CircleAvatar(
          backgroundColor: patient.hasActiveAdmissions
              ? HospitalTheme.success.withOpacity(0.1)
              : HospitalTheme.textLight.withOpacity(0.1),
          child: Icon(
            patient.hasActiveAdmissions ? Icons.local_hospital : Icons.person,
            color: patient.hasActiveAdmissions
                ? HospitalTheme.success
                : HospitalTheme.textMedium,
          ),
        ),
        title: Text(
          patient.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: HospitalTheme.textDark,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID: ${patient.patientId} • ${patient.age}y ${patient.gender}',
              style: const TextStyle(fontSize: 12),
            ),
            if (patient.pendingAmount > 0) ...[
              const SizedBox(height: 2),
              Text(
                'Pending: ₹${patient.pendingAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  color: HospitalTheme.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HospitalTheme.buildStatusBadge(
              patient.hasActiveAdmissions ? 'Admitted' : 'Discharged',
              color: patient.hasActiveAdmissions
                  ? HospitalTheme.success
                  : HospitalTheme.info,
            ),
            if (patient.admissionCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${patient.admissionCount} visits',
                style: TextStyle(
                  fontSize: 10,
                  color: HospitalTheme.textLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHeader(Patient patient) {
    return HospitalTheme.buildCard(
      child: Row(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: HospitalTheme.surfaceLight,
              image: patient.imageUrl.trim().isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(patient.imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: patient.imageUrl.trim().isEmpty
                ? Icon(
                    Icons.person,
                    size: 40,
                    color: HospitalTheme.primary,
                  )
                : null,
          ),
          const SizedBox(width: 20),
          // Patient Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    HospitalTheme.buildStatusBadge(
                      patient.hasActiveAdmissions ? 'Admitted' : 'Discharged',
                      color: patient.hasActiveAdmissions
                          ? HospitalTheme.success
                          : HospitalTheme.info,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Patient ID: ${patient.patientId}',
                  style: TextStyle(
                    fontSize: 16,
                    color: HospitalTheme.textMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${patient.age} years • ${patient.gender}',
                  style: TextStyle(
                    fontSize: 14,
                    color: HospitalTheme.textMedium,
                  ),
                ),
                if (patient.pendingAmount > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: HospitalTheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: HospitalTheme.warning),
                    ),
                    child: Text(
                      'Pending Amount: ₹${patient.pendingAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: HospitalTheme.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Actions
          Column(
            children: [
              ElevatedButton.icon(
                onPressed: () => _showEditPatientDialog(patient),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HospitalTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _refreshData(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientDetails(Patient patient) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader('Patient Details'),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Contact', patient.contact),
                    const SizedBox(height: 12),
                    _buildDetailRow('Address', patient.address),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                        'Total Admissions', '${patient.admissionCount}'),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Gender', patient.gender),
                    const SizedBox(height: 12),
                    _buildDetailRow('Age', '${patient.age} years'),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Status',
                      patient.hasActiveAdmissions
                          ? 'Currently Admitted'
                          : 'Discharged',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: HospitalTheme.textMedium,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAdmissionRecords(Patient patient) {
    return HospitalTheme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HospitalTheme.buildSectionHeader(
            'Admission Records (${patient.admissionRecords.length})',
          ),
          if (patient.admissionRecords.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.medical_information_outlined,
                      size: 64,
                      color: HospitalTheme.textLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No admission records found',
                      style: TextStyle(
                        fontSize: 16,
                        color: HospitalTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...patient.admissionRecords
                .map((admission) => _buildAdmissionCard(patient, admission)),
        ],
      ),
    );
  }

  Widget _buildAdmissionCard(Patient patient, AdmissionRecord admission) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HospitalTheme.surfaceLight,
        borderRadius: HospitalTheme.radiusSmall,
        border: Border.all(color: HospitalTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Admission Date: ${_formatDateTime(admission.admissionDate)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              HospitalTheme.buildStatusBadge(
                admission.status.toUpperCase(),
                color: _getStatusColor(admission.status),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.delete_outline, color: HospitalTheme.error),
                onPressed: () => _showDeleteConfirmation(patient, admission),
                tooltip: 'Delete Admission Record',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAdmissionDetailRow(
                        'Patient Type', admission.patientType),
                    const SizedBox(height: 8),
                    _buildAdmissionDetailRow(
                        'Weight', '${admission.weight} kg'),
                    const SizedBox(height: 8),
                    _buildAdmissionDetailRow(
                      'Doctor',
                      admission.doctor?.name ?? 'Not assigned',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAdmissionDetailRow(
                        'Admit Notes', admission.admitNotes),
                    const SizedBox(height: 8),
                    _buildAdmissionDetailRow(
                      'IPD Details',
                      admission.ipdDetailsUpdated ? 'Updated' : 'Pending',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdmissionDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              color: HospitalTheme.textMedium,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'admitted':
        return HospitalTheme.success;
      case 'discharged':
        return HospitalTheme.info;
      case 'cancelled':
        return HospitalTheme.error;
      default:
        return HospitalTheme.warning;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: HospitalTheme.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No patients found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: HospitalTheme.textMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria',
              style: TextStyle(
                fontSize: 14,
                color: HospitalTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: HospitalTheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading patients',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: HospitalTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: HospitalTheme.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectPatientState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 80,
              color: HospitalTheme.textLight,
            ),
            const SizedBox(height: 24),
            Text(
              'Select a patient to view details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: HospitalTheme.textMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a patient from the list to see their admission records and details',
              style: TextStyle(
                fontSize: 14,
                color: HospitalTheme.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(Pagination pagination) {
    if (pagination.totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: HospitalTheme.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${pagination.currentPage} of ${pagination.totalPages}',
            style: TextStyle(
              color: HospitalTheme.textMedium,
              fontSize: 14,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: pagination.hasPrevPage
                    ? () {
                        ref.read(currentPageProvider.notifier).state =
                            pagination.currentPage - 1;
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous page',
              ),
              IconButton(
                onPressed: pagination.hasNextPage
                    ? () {
                        ref.read(currentPageProvider.notifier).state =
                            pagination.currentPage + 1;
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next page',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditPatientDialog(Patient patient) {
    showDialog(
      context: context,
      builder: (context) => EditPatientDialog(patient: patient),
    );
  }

  void _showDeleteConfirmation(Patient patient, AdmissionRecord admission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Admission Record'),
        content: Text(
          'Are you sure you want to delete this admission record from ${_formatDateTime(admission.admissionDate)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteAdmissionRecord(patient, admission);
            },
            style: TextButton.styleFrom(
              foregroundColor: HospitalTheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAdmissionRecord(
      Patient patient, AdmissionRecord admission) async {
    try {
      await AdmissionApiService.deleteAdmissionRecord(
          patient.patientId, admission.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Admission record deleted successfully'),
            backgroundColor: HospitalTheme.success,
          ),
        );
        _refreshData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete admission record: $e'),
            backgroundColor: HospitalTheme.error,
          ),
        );
      }
    }
  }
}

// Edit Patient Dialog
class EditPatientDialog extends ConsumerStatefulWidget {
  final Patient patient;

  const EditPatientDialog({super.key, required this.patient});

  @override
  ConsumerState<EditPatientDialog> createState() => _EditPatientDialogState();
}

class _EditPatientDialogState extends ConsumerState<EditPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _contactController;
  late final TextEditingController _addressController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _pendingAmountController;
  String _selectedGender = 'Male';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient.name);
    _ageController = TextEditingController(text: widget.patient.age.toString());
    _contactController = TextEditingController(text: widget.patient.contact);
    _addressController = TextEditingController(text: widget.patient.address);
    _imageUrlController = TextEditingController(text: widget.patient.imageUrl);
    _pendingAmountController = TextEditingController(
      text: widget.patient.pendingAmount.toString(),
    );
    _selectedGender = widget.patient.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _imageUrlController.dispose();
    _pendingAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      child: Container(
        width: screenWidth > 600 ? 600 : screenWidth * 0.9,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.edit,
                  color: HospitalTheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Edit Patient Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'Enter patient full name',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Age and Gender
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ageController,
                              decoration: const InputDecoration(
                                labelText: 'Age',
                                hintText: 'Enter age',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Age is required';
                                }
                                final age = int.tryParse(value);
                                if (age == null || age <= 0 || age > 150) {
                                  return 'Enter valid age';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedGender,
                              decoration: const InputDecoration(
                                labelText: 'Gender',
                              ),
                              items: ['Male', 'Female', 'Other']
                                  .map((gender) => DropdownMenuItem(
                                        value: gender,
                                        child: Text(gender),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedGender = value ?? 'Male';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Contact
                      TextFormField(
                        controller: _contactController,
                        decoration: const InputDecoration(
                          labelText: 'Contact Number',
                          hintText: 'Enter contact number',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Contact number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Address
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          hintText: 'Enter address',
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Address is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Image URL
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Image URL (Optional)',
                          hintText: 'Enter image URL',
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Pending Amount
                      TextFormField(
                        controller: _pendingAmountController,
                        decoration: const InputDecoration(
                          labelText: 'Pending Amount',
                          hintText: 'Enter pending amount',
                          prefixText: '₹ ',
                        ),
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Pending amount is required';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount < 0) {
                            return 'Enter valid amount';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _updatePatient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HospitalTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Update Patient'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updateData = {
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'gender': _selectedGender,
        'contact': _contactController.text.trim(),
        'address': _addressController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'pendingAmount': double.parse(_pendingAmountController.text.trim()),
      };

      final updatedPatient = await AdmissionApiService.updatePatientInfo(
        widget.patient.id,
        updateData,
      );

      if (mounted) {
        // Update the selected patient in the provider
        ref.read(selectedPatientProvider.notifier).state = updatedPatient;

        // Refresh the patients list
        ref.invalidate(patientsProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Patient information updated successfully'),
            backgroundColor: HospitalTheme.success,
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update patient: $e'),
            backgroundColor: HospitalTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
