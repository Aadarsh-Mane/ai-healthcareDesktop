import 'package:doctordesktop/Doctor/AdmitNoteDialog.dart';
import 'package:doctordesktop/Doctor/Animate.dart';
import 'package:doctordesktop/Doctor/DoctorAdmittedPatientScreen.dart';
import 'package:doctordesktop/Doctor/DoctorMainScreen.dart';
import 'package:doctordesktop/Doctor/DoctorPatientDetailScreen.dart';
import 'package:doctordesktop/StateProvider.dart';
import 'package:doctordesktop/authProvider/auth_provider.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:doctordesktop/repositories/doctor_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'dart:async';

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

class _AssignedPatientsScreenState
    extends ConsumerState<AssignedPatientsScreen> {
  Timer? _refreshTimer;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();

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
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _mounted = false;
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access the loading state
    final isRefreshing = ref.watch(refreshLoadingProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: isRefreshing
                    ? LoadingAnimationWidget.staggeredDotsWave(
                        color: Colors.black,
                        size: 20,
                      )
                    : const Icon(Icons.refresh, color: Colors.black),
                onPressed: isRefreshing ? null : _fetchData,
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(19),
            child: Container(
              color: Colors.black,
              child: const TabBar(
                indicatorColor: Colors.cyan,
                labelColor: Colors.cyan,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(
                    icon: Icon(Icons.people),
                    text: 'Assigned Patients',
                  ),
                  Tab(
                    icon: Icon(Icons.people_outline_rounded),
                    text: 'Admitted Patient',
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

class _AssignedPatientsViewState extends ConsumerState<AssignedPatientsView> {
  bool _mounted = true;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  // Refresh function with proper mounted checks
  Future<void> _refreshData() async {
    if (!_mounted) return;

    try {
      // Defer state updates to avoid build-time issues
      await Future.microtask(() => {});
      await ref.read(assignedPatientsProvider.notifier).fetchAssignedPatients();
    } catch (e) {
      print('Error refreshing: $e');
      // Show error only if mounted
      if (_mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignedPatients = ref.watch(assignedPatientsProvider);
    final isRefreshing = ref.watch(refreshLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: () {
            // Check if the context is still mounted before popping

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DoctorMainScreen(),
              ),
            );
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bb1.png'),
                opacity: 0.3,
                fit: BoxFit.cover,
              ),
            ),
            child: RefreshIndicator(
              key: _refreshKey,
              onRefresh: _refreshData,
              displacement: 50,
              color: Colors.cyan,
              backgroundColor: Colors.white,
              child: assignedPatients.when(
                data: (patients) => patients.isEmpty
                    ? ListView(
                        // Using ListView instead of Center to work with RefreshIndicator
                        children: [
                          Container(
                            height: MediaQuery.of(context).size.height * 0.7,
                            alignment: Alignment.center,
                            child: const Text(
                              'No assigned patients found',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: patients.length,
                        itemBuilder: (context, index) {
                          final patient = patients[index];
                          final admissionStatus =
                              patient.admissionRecords.isNotEmpty
                                  ? patient.admissionRecords.first.status
                                  : 'Pending';

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PatientDetailScreen4(
                                    patient: patient,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 8.0,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: const BorderSide(
                                    color: Color(0Xffeff7f8), width: 2.0),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF005F9E),
                                      Color(0xFF00B8D4),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.white,
                                      child: Text(
                                        patient.name.isNotEmpty
                                            ? patient.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            patient.name,
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'Age: ${patient.age}, Gender: ${patient.gender}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'Status: $admissionStatus',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: isRefreshing
                                          ? null
                                          : () async {
                                              if (patient.admissionRecords
                                                  .isNotEmpty) {
                                                final admissionId = patient
                                                    .admissionRecords.first.id;
                                                _showConditionDialog(context,
                                                    admissionId, patient, ref);
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        "No admission record found"),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                      ),
                                      child: const Text(
                                        "Discharge",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: isRefreshing
                                          ? null
                                          : () async {
                                              await _admitPatient(
                                                  patient, ref, context);
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                      ),
                                      child: const Text(
                                        "Admit",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                error: (error, stackTrace) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading patients: ${error.toString()}',
                        style: const TextStyle(color: Colors.red, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          if (_mounted) {
                            _refreshData();
                          }
                        },
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                ),
                loading: () => Container(), // Empty container for loading state
              ),
            ),
          ),
          // Single centralized loading overlay - show only when loading or refreshing
          if (isRefreshing || assignedPatients is AsyncLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const CustomLoadingAnimation(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isRefreshing
            ? null
            : () {
                // Trigger the pull-to-refresh animation programmatically
                _refreshKey.currentState?.show();
              },
        child: isRefreshing
            ? LoadingAnimationWidget.staggeredDotsWave(
                color: Colors.white,
                size: 20,
              )
            : const Icon(Icons.refresh),
        backgroundColor: Colors.cyan,
      ),
    );
  }
}

// This function needs to be updated to respect the mounted state
Future<void> _showDischargeDialog(
    BuildContext context,
    String admissionId,
    String selectedCondition,
    int amount,
    Patient1 patient,
    WidgetRef ref) async {
  bool? confirmDischarge = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Confirm Discharge',
            style: TextStyle(color: Colors.deepPurple)),
        content: const Text('Are you sure you want to discharge this patient?',
            style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              _showConditionDialog(context, admissionId, patient, ref);
            },
            child: const Text('Back', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Confirm Discharge',
                style: TextStyle(color: Colors.deepPurple)),
          ),
        ],
      );
    },
  );

  if (confirmDischarge == true) {
    try {
      // Show loading animation during discharge process - using Future to avoid build-time updates
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

      // Hide loading animation - using Future to avoid build-time updates
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(refreshLoadingProvider.notifier).state = false;
      });

      // Check if context is still valid before showing SnackBar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Discharge successful: ${response['message']}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Error during discharge: $e");

      // Hide loading animation even on error - using Future to avoid build-time updates
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(refreshLoadingProvider.notifier).state = false;
      });

      // Check if context is still valid before showing SnackBar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to discharge patient')),
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
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: const Text('Update Condition at Discharge'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCondition,
                  decoration: const InputDecoration(
                    labelText: 'Condition at Discharge',
                    border: OutlineInputBorder(),
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
                SizedBox(height: 15),
                TextField(
                  onChanged: (text) {
                    additionalInfo = text;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Additional Information (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 15),
                TextField(
                  onChanged: (text) {
                    amountToBePayed = text;
                  },
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount to be Paid',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  String amountText = amountToBePayed.trim();
                  if (amountText.isEmpty) {
                    amountText = '0'; // Set to zero if empty
                  }

                  // First parse as double to handle decimal inputs
                  final doubleAmount = double.tryParse(amountText);
                  if (doubleAmount == null || doubleAmount < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid numeric amount'),
                      ),
                    );
                    return;
                  }

                  // Convert to integer (truncates decimal values)
                  final intAmount = doubleAmount.toInt();

                  Navigator.of(context).pop();
                  await _showDischargeDialog(
                    context,
                    admissionId,
                    selectedCondition,
                    intAmount, // Pass integer value
                    patient,
                    ref,
                  );
                },
                child: const Text('Next'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _admitPatient(
    Patient1 patient, WidgetRef ref, BuildContext context) async {
  try {
    // Show loading animation - using Future to avoid build-time updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(refreshLoadingProvider.notifier).state = true;
    });

    // Wait for the next frame to ensure the loading state has updated
    await Future.microtask(() => {});

    // Ensure there are admission records
    if (patient.admissionRecords.isEmpty) {
      // Hide loading animation - using Future to avoid build-time updates
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(refreshLoadingProvider.notifier).state = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No admission records found for this patient'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final admissionId = patient.admissionRecords.first.id;

    // Hide loading during dialog - using Future to avoid build-time updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(refreshLoadingProvider.notifier).state = false;
    });

    // Wait for the next frame to ensure the loading state has updated
    await Future.microtask(() => {});

    // Show our new admission dialog and get the admit note
    final admitNote = await showDialog<String>(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (context) => AdmitPatientDialog(
        patientName: patient.name,
        onAdmit: (String location) {
          Navigator.of(context).pop(location);
        },
      ),
    );

    // If dialog was dismissed without selecting, return early
    if (admitNote == null) return;

    // Check if context is still valid
    if (!context.mounted) return;

    // Show loading animation again - using Future to avoid build-time updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(refreshLoadingProvider.notifier).state = true;
    });

    // Wait for the next frame to ensure the loading state has updated
    await Future.microtask(() => {});

    final authRepository = ref.read(authRepositoryProvider);
    final result = await authRepository.admitPatient1(
      admissionId: admissionId,
      admitNote: admitNote,
    );

    // Hide loading animation - using Future to avoid build-time updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(refreshLoadingProvider.notifier).state = false;
    });

    // Check if context is still valid after async operation
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Unknown error occurred'),
        backgroundColor:
            (result['success'] as bool? ?? false) ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );

    // Only refresh if needed, with delayed execution
    Future.microtask(() {
      ref.read(assignedPatientsProvider.notifier).fetchAssignedPatients();
    });
  } catch (e) {
    print('Error admitting patient: $e');

    // Hide loading animation on error - using Future to avoid build-time updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(refreshLoadingProvider.notifier).state = false;
    });

    // Check if context is still valid
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Patient already admitted: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Update dischargePatient function to check for mounted state
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

    // Refresh data only if needed, with delayed execution
    Future.microtask(() {
      ref.read(assignedPatientsProvider.notifier).fetchAssignedPatients();
    });
  } catch (e) {
    print('Error discharging patient: $e');
  }
}
