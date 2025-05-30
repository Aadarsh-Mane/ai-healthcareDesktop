import 'package:doctordesktop/Doctor/AdmitNoteDialog.dart';
import 'package:doctordesktop/Doctor/Animate.dart';
import 'package:doctordesktop/Doctor/DoctorAdmittedPatientScreen.dart';
import 'package:doctordesktop/Doctor/DoctorMainScreen.dart';
import 'package:doctordesktop/Doctor/DoctorPatientDetailScreen.dart';
import 'package:doctordesktop/StateProvider.dart';
import 'package:doctordesktop/authProvider/auth_provider.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'dart:async';
import 'dart:ui';

import 'package:intl/intl.dart';

// Custom loading animation widget

// Create a provider to track loading state
final refreshLoadingProvider = StateProvider<bool>((ref) => false);

// Modify the provider to prevent state updates after dispose
final assignedPatientsProvider =
    StateNotifierProvider<AssignedPatientsNotifier, AsyncValue<List<Patient1>>>(
  (ref) {
    final authRepository = ref.read(authRepositoryProvider);
    final notifier = AssignedPatientsNotifier(authRepository);
    return notifier;
  },
);

class AssignedPatientsScreen extends ConsumerStatefulWidget {
  const AssignedPatientsScreen({Key? key}) : super(key: key);

  @override
  _AssignedPatientsScreenState createState() => _AssignedPatientsScreenState();
}

class _AssignedPatientsScreenState extends ConsumerState<AssignedPatientsScreen>
    with TickerProviderStateMixin {
  Timer? _refreshTimer;
  bool _mounted = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize pulse animation for refresh button
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Safe initial fetch with delayed execution to avoid build-time updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });

    // Set up the timer to refresh every 1 minute with animation
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_mounted) {
        _fetchData();
      }
    });
  }

  // Method to fetch data with loading animation
  Future<void> _fetchData() async {
    if (!_mounted) return;

    // Show loading animation after the current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mounted) {
        ref.read(refreshLoadingProvider.notifier).state = true;
        _pulseController.repeat(reverse: true);
      }
    });

    try {
      await ref.read(assignedPatientsProvider.notifier).fetchAssignedPatients();
    } finally {
      // Only hide the animation if we're still mounted (outside of build)
      if (_mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_mounted) {
            ref.read(refreshLoadingProvider.notifier).state = false;
            _pulseController.stop();
            _pulseController.reset();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _mounted = false;
    _refreshTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access the loading state
    final isRefreshing = ref.watch(refreshLoadingProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          shadowColor: Colors.black12,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: Color(0xFF374151), size: 20),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      DoctorMainScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-1.0, 0.0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOutCubic,
                      )),
                      child: child,
                    );
                  },
                ),
              );
            },
          ),
          title: const Text(
            'Patient Management',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          centerTitle: false,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isRefreshing ? _pulseAnimation.value : 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: isRefreshing
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded,
                                color: Colors.white, size: 20),
                        onPressed: isRefreshing ? null : _fetchData,
                        tooltip: 'Refresh Patients',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFF3B82F6),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline_rounded, size: 16),
                          const SizedBox(width: 8),
                          Text('Assigned Patients'),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_hospital_outlined, size: 16),
                          const SizedBox(width: 8),
                          Text('Admitted Patients'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            AssignedPatientsView(),
            AdmittedPatientsScreen(),
          ],
        ),
      ),
    );
  }
}

class AssignedPatientsView extends ConsumerStatefulWidget {
  const AssignedPatientsView({Key? key}) : super(key: key);

  @override
  ConsumerState<AssignedPatientsView> createState() =>
      _AssignedPatientsViewState();
}

class _AssignedPatientsViewState extends ConsumerState<AssignedPatientsView>
    with TickerProviderStateMixin {
  bool _mounted = true;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _mounted = false;
    _searchController.dispose();
    super.dispose();
  }

  // Refresh function with proper mounted checks
  Future<void> _refreshData() async {
    if (!_mounted) return;

    try {
      await Future.microtask(() => {});
      await ref.read(assignedPatientsProvider.notifier).fetchAssignedPatients();
    } catch (e) {
      print('Error refreshing: $e');
      if (_mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to refresh: $e')),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final assignedPatients = ref.watch(assignedPatientsProvider);
    final isRefreshing = ref.watch(refreshLoadingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
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
                          color: const Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: const Color(0xFF6B7280),
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: const Color(0xFF6B7280),
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
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: isRefreshing ? null : _refreshData,
                    icon: isRefreshing
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded,
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

                return _buildPatientsTable(filteredPatients, isRefreshing);
              },
              error: (error, stackTrace) => _buildErrorState(error),
              loading: () => _buildLoadingState(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsTable(List<Patient1> patients, bool isRefreshing) {
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
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.people_outline_rounded,
                    color: const Color(0xFF374151), size: 20),
                const SizedBox(width: 12),
                Text(
                  'Assigned Patients (${patients.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const Spacer(),
                if (isRefreshing)
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: const Color(0xFF3B82F6),
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Updating...',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
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
                bottom: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
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
                      color: const Color(0xFF6B7280),
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
                      color: const Color(0xFF6B7280),
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
                      color: const Color(0xFF6B7280),
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
                      color: const Color(0xFF6B7280),
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

                return _buildPatientRow(
                    patient, admissionStatus, isRefreshing, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientRow(
      Patient1 patient, String admissionStatus, bool isRefreshing, int index) {
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
            bottom: BorderSide(color: const Color(0xFFF3F4F6), width: 1),
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
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
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
                          color: const Color(0xFF3B82F6),
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
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${patient.patientId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
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
                          size: 14, color: const Color(0xFF6B7280)),
                      const SizedBox(width: 4),
                      Text(
                        '${patient.age} years',
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF374151),
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
                        color: const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        patient.gender,
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF374151),
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
                    label: 'Admit',
                    icon: Icons.login_rounded,
                    color: const Color(0xFF10B981),
                    isLoading: isRefreshing,
                    onPressed: isRefreshing
                        ? null
                        : () async {
                            await _admitPatient(patient, ref, context);
                          },
                  ),
                  const SizedBox(width: 8),
                  _buildCompactActionButton(
                    label: 'Discharge',
                    icon: Icons.logout_rounded,
                    color: const Color(0xFFEF4444),
                    isLoading: isRefreshing,
                    onPressed: isRefreshing
                        ? null
                        : () async {
                            if (patient.admissionRecords.isNotEmpty) {
                              final admissionId =
                                  patient.admissionRecords.first.id;
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
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    return Container(
      height: 32,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(icon, size: 14, color: Colors.white),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? color : const Color(0xFF9CA3AF),
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
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 48,
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Assigned Patients',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are currently no patients assigned to you.',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: Icon(Icons.refresh_rounded, size: 18),
              label: Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
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
              color: const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 16),
            Text(
              'No patients found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF6B7280),
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
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading patients...',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF6B7280),
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
                color: const Color(0xFFEF4444).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: Icon(Icons.refresh_rounded, size: 18),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
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
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'discharged':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'admitted':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.schedule_rounded;
      case 'discharged':
        return Icons.home_rounded;
      default:
        return Icons.info_rounded;
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
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// Enhanced modern dialog functions
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.logout_rounded,
                  color: const Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Confirm Discharge',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
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
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: const Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Are you sure you want to discharge ${patient.name}?',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF92400E),
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
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: ₹$amount',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF374151),
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
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Confirm Discharge'),
          ),
        ],
      );
    },
  );

  if (confirmDischarge == true) {
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(refreshLoadingProvider.notifier).state = true;
      });

      final doctor = DoctorRepository();
      final response = await doctor.updateConditionAtDischarge(
        admissionId: admissionId,
        conditionAtDischarge: selectedCondition,
        amountToBePayed: amount,
      );

      await _dischargePatient(patient, ref);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(refreshLoadingProvider.notifier).state = false;
      });

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
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      print("Error during discharge: $e");

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(refreshLoadingProvider.notifier).state = false;
      });

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
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}

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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.medical_information_rounded,
                      color: const Color(0xFF3B82F6), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Discharge Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
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
                            color: const Color(0xFF3B82F6)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                      items: [
                        'Discharged',
                        'Referred',
                        'LAMA',
                        'Expired',
                        'Absconded'
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
                        labelText: 'Additional Information (Optional)',
                        prefixIcon: Icon(Icons.notes_rounded,
                            color: const Color(0xFF3B82F6)),
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
                            color: const Color(0xFF3B82F6)),
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
                    color: const Color(0xFF6B7280),
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
                        backgroundColor: const Color(0xFFEF4444),
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
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Next'),
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
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFFE2E8F0),
        width: 1,
      ),
    ),
    child: child,
  );
}

Future<void> _admitPatient(
    Patient1 patient, WidgetRef ref, BuildContext context) async {
  try {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(refreshLoadingProvider.notifier).state = true;
    });

    await Future.microtask(() => {});

    if (patient.admissionRecords.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(refreshLoadingProvider.notifier).state = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                    child: Text('No admission records found for this patient')),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return;
    }

    final admissionId = patient.admissionRecords.first.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(refreshLoadingProvider.notifier).state = false;
    });

    await Future.microtask(() => {});

    final admitNote = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AdmitPatientDialog(
        patientName: patient.name,
        onAdmit: (String location) {
          Navigator.of(context).pop(location);
        },
      ),
    );

    if (admitNote == null) return;

    if (!context.mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(refreshLoadingProvider.notifier).state = true;
    });

    await Future.microtask(() => {});

    final authRepository = ref.read(authRepositoryProvider);
    final result = await authRepository.admitPatient1(
      admissionId: admissionId,
      admitNote: admitNote,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(refreshLoadingProvider.notifier).state = false;
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              (result['success'] as bool? ?? false)
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(result['message'] ?? 'Unknown error occurred')),
          ],
        ),
        backgroundColor: (result['success'] as bool? ?? false)
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );

    Future.microtask(() {
      ref.read(assignedPatientsProvider.notifier).fetchAssignedPatients();
    });
  } catch (e) {
    print('Error admitting patient: $e');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(refreshLoadingProvider.notifier).state = false;
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('Patient already admitted: ${e.toString()}')),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

Future<void> _dischargePatient(Patient1 patient, WidgetRef ref) async {
  try {
    final admissionId = patient.admissionRecords.isNotEmpty
        ? patient.admissionRecords.first.id
        : '';

    if (admissionId.isEmpty) {
      print("Cannot discharge: No admission ID found");
      return;
    }

    final authRepository = ref.read(authRepositoryProvider);
    final result = await authRepository.dischargePatient(
      patientId: patient.patientId,
      admissionId: admissionId,
    );

    print("Discharge result: ${result['message']}");

    Future.microtask(() {
      ref.read(assignedPatientsProvider.notifier).fetchAssignedPatients();
    });
  } catch (e) {
    print('Error discharging patient: $e');
  }
}
