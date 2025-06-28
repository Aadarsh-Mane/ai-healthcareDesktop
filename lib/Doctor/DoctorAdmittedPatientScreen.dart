import 'package:doctordesktop/Doctor/DoctorPatientDetailScreen.dart';
import 'package:doctordesktop/StateProvider.dart';
import 'package:doctordesktop/authProvider/auth_provider.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final assignedPatientsProvider =
    StateNotifierProvider<AdmittedPatientsNotifier, AsyncValue<List<Patient1>>>(
  (ref) {
    final authRepository = ref.read(authRepositoryProvider);
    final notifier = AdmittedPatientsNotifier(authRepository);
    notifier.fetchAdmittedPatients();
    return notifier;
  },
);

final assignedPatientsProvider1 =
    StateNotifierProvider<AssignedPatientsNotifier, AsyncValue<List<Patient1>>>(
  (ref) {
    final authRepository = ref.read(authRepositoryProvider);
    final notifier = AssignedPatientsNotifier(authRepository);
    notifier.fetchAssignedPatients();
    return notifier;
  },
);

class AdmittedPatientsScreen extends ConsumerStatefulWidget {
  const AdmittedPatientsScreen({Key? key}) : super(key: key);

  @override
  _AdmittedPatientsScreenState createState() => _AdmittedPatientsScreenState();
}

class _AdmittedPatientsScreenState
    extends ConsumerState<AdmittedPatientsScreen> {
  final doctor = DoctorRepository();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.refresh(assignedPatientsProvider.notifier).fetchAdmittedPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Patient1> _filterPatients(List<Patient1> patients) {
    if (_searchQuery.isEmpty) return patients;

    return patients.where((patient) {
      return patient.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          patient.patientId
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          patient.gender.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _refreshData() async {
    try {
      ref.refresh(assignedPatientsProvider.notifier).fetchAdmittedPatients();
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to refresh: $e')),
              ],
            ),
            backgroundColor: HospitalTheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignedPatients = ref.watch(assignedPatientsProvider);

    return Scaffold(
      backgroundColor: HospitalTheme.background,
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: HospitalTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: HospitalTheme.border),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search patients by name, ID, or gender...',
                        hintStyle: TextStyle(
                          color: HospitalTheme.textLight,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: HospitalTheme.textMedium,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: HospitalTheme.textMedium,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: HospitalTheme.success,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: HospitalTheme.success.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _refreshData,
                    icon: const Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 20),
                    tooltip: 'Refresh Data',
                  ),
                ),
              ],
            ),
          ),

          // Patient List
          Expanded(
            child: assignedPatients.when(
              data: (patients) {
                final filteredPatients = _filterPatients(patients);

                if (patients.isEmpty) {
                  return _buildEmptyState();
                }

                if (filteredPatients.isEmpty && _searchQuery.isNotEmpty) {
                  return _buildNoSearchResults();
                }

                return _buildPatientsTable(filteredPatients);
              },
              error: (error, stackTrace) => _buildErrorState(error),
              loading: () => _buildLoadingState(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsTable(List<Patient1> patients) {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: HospitalTheme.surfaceLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: HospitalTheme.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.local_hospital_outlined,
                    color: HospitalTheme.textDark, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Admitted Patients (${patients.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: HospitalTheme.textDark,
                  ),
                ),
              ],
            ),
          ),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              border: Border(
                bottom: BorderSide(color: HospitalTheme.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Patient Information',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: HospitalTheme.textMedium,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: HospitalTheme.textMedium,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: HospitalTheme.textMedium,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Actions',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: HospitalTheme.textMedium,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Patient Rows
          Expanded(
            child: ListView.builder(
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final patient = patients[index];
                final admissionStatus = patient.admissionRecords.isNotEmpty
                    ? patient.admissionRecords.first.status
                    : 'Pending';

                return _buildPatientRow(patient, admissionStatus, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientRow(Patient1 patient, String admissionStatus, int index) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                PatientDetailScreen4(patient: patient),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity:
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: index % 2 == 0 ? Colors.white : const Color(0xFFFAFAFA),
          border: Border(
            bottom: BorderSide(color: HospitalTheme.border, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Patient Information
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: HospitalTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        patient.name.isNotEmpty
                            ? patient.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: HospitalTheme.primary,
                        ),
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
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: HospitalTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${patient.patientId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: HospitalTheme.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Details
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cake_outlined,
                          size: 14, color: HospitalTheme.textMedium),
                      const SizedBox(width: 4),
                      Text(
                        '${patient.age} years',
                        style: TextStyle(
                          fontSize: 13,
                          color: HospitalTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        patient.gender.toLowerCase() == 'male'
                            ? Icons.male_rounded
                            : Icons.female_rounded,
                        size: 14,
                        color: HospitalTheme.textMedium,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        patient.gender,
                        style: TextStyle(
                          fontSize: 13,
                          color: HospitalTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(admissionStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _getStatusColor(admissionStatus).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  admissionStatus,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(admissionStatus),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Actions
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCompactActionButton(
                    label: 'Assign Lab',
                    icon: Icons.science_outlined,
                    color: HospitalTheme.secondary,
                    onPressed: () async {
                      await _handleAssignLab(context, patient, ref);
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildCompactActionButton(
                    label: 'Discharge',
                    icon: Icons.logout_rounded,
                    color: HospitalTheme.error,
                    onPressed: () async {
                      if (patient.admissionRecords.isNotEmpty) {
                        final admissionId = patient.admissionRecords.first.id;
                        _showConditionDialog(
                            context, admissionId, patient, ref);
                      } else {
                        _showErrorSnackBar(
                            context, "No admission record found");
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 32,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? color : HospitalTheme.textLight,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: HospitalTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_hospital_outlined,
                size: 48,
                color: HospitalTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Admitted Patients',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: HospitalTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are currently no admitted patients.',
              style: TextStyle(
                fontSize: 14,
                color: HospitalTheme.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HospitalTheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: HospitalTheme.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No patients found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: HospitalTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria',
              style: TextStyle(
                fontSize: 14,
                color: HospitalTheme.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: HospitalTheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading patients...',
            style: TextStyle(
              fontSize: 14,
              color: HospitalTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: HospitalTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: HospitalTheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: HospitalTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                fontSize: 14,
                color: HospitalTheme.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HospitalTheme.error,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'admitted':
        return HospitalTheme.success;
      case 'pending':
        return HospitalTheme.warning;
      case 'discharged':
        return HospitalTheme.info;
      default:
        return HospitalTheme.textMedium;
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: HospitalTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Keep all the existing dialog and business logic methods unchanged
  Future<void> _showConditionDialog(BuildContext context, String admissionId,
      Patient1 patient, WidgetRef ref) async {
    String selectedCondition = 'Discharged';
    String additionalInfo = '';
    String amountToBePayed = '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: HospitalTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.medical_information_rounded,
                        color: HospitalTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Update Condition at Discharge',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModernFormField(
                      child: DropdownButtonFormField<String>(
                        value: selectedCondition,
                        decoration: InputDecoration(
                          labelText: 'Condition at Discharge',
                          prefixIcon: Icon(Icons.assignment_turned_in_rounded,
                              color: HospitalTheme.primary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        items: [
                          'Discharged',
                          "Transferred",
                          "D.M.A.",
                          "Absconded",
                          "Expired"
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedCondition = newValue;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildModernFormField(
                      child: TextField(
                        onChanged: (text) {
                          additionalInfo = text;
                        },
                        decoration: InputDecoration(
                          labelText: 'Additional Information',
                          prefixIcon: Icon(Icons.notes_rounded,
                              color: HospitalTheme.primary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildModernFormField(
                      child: TextField(
                        onChanged: (text) {
                          amountToBePayed = text;
                        },
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount to be Paid',
                          prefixIcon: Icon(Icons.currency_rupee_rounded,
                              color: HospitalTheme.primary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: HospitalTheme.textMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String amountText = amountToBePayed.trim();
                    if (amountText.isEmpty) {
                      amountText = '0';
                    }

                    final doubleAmount = double.tryParse(amountText);
                    if (doubleAmount == null || doubleAmount < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  color: Colors.white),
                              SizedBox(width: 12),
                              Expanded(
                                  child: Text(
                                      'Please enter a valid numeric amount')),
                            ],
                          ),
                          backgroundColor: HospitalTheme.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                      return;
                    }

                    final intAmount = doubleAmount.toInt();

                    Navigator.of(context).pop();
                    await _showDischargeDialog(
                      context,
                      admissionId,
                      selectedCondition,
                      intAmount,
                      patient,
                      ref,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HospitalTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Next'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildModernFormField({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: HospitalTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: HospitalTheme.border,
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Future<void> _showDischargeDialog(
      BuildContext context,
      String admissionId,
      String selectedCondition,
      int amount,
      Patient1 patient,
      WidgetRef ref) async {
    bool? confirmDischarge = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: HospitalTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.logout_rounded,
                    color: HospitalTheme.error, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Confirm Discharge',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: HospitalTheme.textDark,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HospitalTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: HospitalTheme.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: HospitalTheme.warning, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Are you sure you want to discharge ${patient.name}?',
                        style: TextStyle(
                          fontSize: 14,
                          color: HospitalTheme.textDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Condition: $selectedCondition',
                style: TextStyle(
                  fontSize: 14,
                  color: HospitalTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Amount: ₹$amount',
                style: TextStyle(
                  fontSize: 14,
                  color: HospitalTheme.textDark,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: HospitalTheme.textMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: HospitalTheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Confirm Discharge'),
            ),
          ],
        );
      },
    );

    if (confirmDischarge == true) {
      try {
        final response = await doctor.updateConditionAtDischarge(
          admissionId: admissionId,
          conditionAtDischarge: selectedCondition,
          amountToBePayed: amount,
        );

        await _dischargePatient(patient, ref);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                      child:
                          Text('Discharge successful: ${response['message']}')),
                ],
              ),
              backgroundColor: HospitalTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('Failed to discharge patient')),
                ],
              ),
              backgroundColor: HospitalTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }

  Future<void> _dischargePatient(Patient1 patient, WidgetRef ref) async {
    try {
      final admissionId = patient.admissionRecords.isNotEmpty
          ? patient.admissionRecords.first.id
          : '';
      final authRepository = ref.read(authRepositoryProvider);
      final result = await authRepository.dischargePatient(
        patientId: patient.patientId,
        admissionId: admissionId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor:
                result['success'] ? HospitalTheme.success : HospitalTheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      ref.refresh(assignedPatientsProvider.notifier).fetchAdmittedPatients();
      ref.refresh(assignedPatientsProvider1.notifier).fetchAssignedPatients();
    } catch (e) {
      ref.refresh(assignedPatientsProvider.notifier).fetchAdmittedPatients();
      ref.refresh(assignedPatientsProvider1.notifier).fetchAssignedPatients();

      print('Error discharging patient: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Discharged patient: $e'),
            backgroundColor: HospitalTheme.success,
          ),
        );
      }
    }
  }

  Future<void> _handleAssignLab(
      BuildContext context, Patient1 patient, WidgetRef ref) async {
    final authRepository = ref.read(authRepositoryProvider);
    final admissionId = await showDialog<String>(
      context: context,
      builder: (context) => SelectAdmissionDialog(
        admissionRecords: patient.admissionRecords,
      ),
    );

    if (admissionId == null) return;

    final labTestNameGivenByDoctor = await showDialog<String>(
      context: context,
      builder: (context) => AssignLabDialog(),
    );

    if (labTestNameGivenByDoctor == null || labTestNameGivenByDoctor.isEmpty) {
      return;
    }

    try {
      final result = await authRepository.assignPatientToLab(
        patientId: patient.id,
        admissionId: admissionId,
        labTestNameGivenByDoctor: labTestNameGivenByDoctor,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor:
                result['success'] ? HospitalTheme.success : HospitalTheme.error,
          ),
        );
      }

      ref.refresh(assignedPatientsProvider.notifier).fetchAdmittedPatients();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign lab: $e'),
            backgroundColor: HospitalTheme.error,
          ),
        );
      }
    }
  }
}

class SelectAdmissionDialog extends StatelessWidget {
  final List<AdmissionRecord> admissionRecords;

  const SelectAdmissionDialog({
    Key? key,
    required this.admissionRecords,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: HospitalTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.assignment_rounded,
                color: HospitalTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'Select Admission Record',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: HospitalTheme.textDark,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            children: admissionRecords.map((admission) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: HospitalTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: HospitalTheme.border),
                ),
                child: ListTile(
                  title: Text(
                    'Admission Date: ${admission.admissionDate}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                  subtitle: Text(
                    'Reason: ${admission.reasonForAdmission}',
                    style: TextStyle(
                      color: HospitalTheme.textMedium,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop(admission.id);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: HospitalTheme.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class AssignLabDialog extends StatefulWidget {
  @override
  _AssignLabDialogState createState() => _AssignLabDialogState();
}

class _AssignLabDialogState extends State<AssignLabDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: HospitalTheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.science_rounded,
                color: HospitalTheme.secondary, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'Assign to Lab',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: HospitalTheme.textDark,
            ),
          ),
        ],
      ),
      content: Container(
        width: 300,
        decoration: BoxDecoration(
          color: HospitalTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HospitalTheme.border),
        ),
        child: TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Lab Test Name',
            prefixIcon:
                Icon(Icons.assignment_rounded, color: HospitalTheme.secondary),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: HospitalTheme.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final now = DateTime.now()
                .toUtc()
                .add(const Duration(hours: 5, minutes: 30));
            final formattedDate = DateFormat('yyyy-MM-dd h:mm a').format(now);
            final updatedTestName =
                '${_controller.text.trim()} - $formattedDate';
            Navigator.of(context).pop(updatedTestName);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: HospitalTheme.secondary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Assign'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
