import 'package:doctordesktop/repositories/auth_repository.dart';
import 'package:doctordesktop/repositories/lab_repository.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/model/getDoctorProfile.dart';
import 'package:doctordesktop/model/getLabModel.dart';
import 'package:doctordesktop/model/getLabPatient.dart';
import 'package:doctordesktop/model/getNewLabPatientModel.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class AssignedLabsNotifier extends StateNotifier<List<AssignedLab>> {
  final AuthRepository authRepository;

  AssignedLabsNotifier(this.authRepository) : super([]);

  // Fetch the assigned labs from the API
  Future<void> fetchAssignedLabs() async {
    try {
      final labs = await authRepository.getAssignedLabs();
      state = labs; // Update the state with fetched data
    } catch (e) {
      throw Exception('Failed to fetch assigned labs: $e');
    }
  }
}

class DoctorProfileNotifier extends StateNotifier<DoctorProfile?> {
  final AuthRepository authRepository;

  DoctorProfileNotifier(this.authRepository) : super(null);

  // Fetch the doctor profile from the API
  Future<void> getDoctorProfile() async {
    print('Fetching doctor profile...');

    try {
      final doctorProfile = await authRepository.fetchDoctorProfile();
      print('Doctor profile fetched successfully: $doctorProfile');

      state = doctorProfile; // Update the state with fetched data
    } catch (e) {
      throw Exception('Failed to fetch doctor profile: $e');
    }
  }
}

class AssignedPatientsNotifier
    extends StateNotifier<AsyncValue<List<Patient1>>> {
  final AuthRepository authRepository;

  AssignedPatientsNotifier(this.authRepository)
      : super(const AsyncValue.loading());

  // Fetch assigned patients
  Future<void> fetchAssignedPatients() async {
    try {
      state = const AsyncValue.loading(); // Show loading state
      final patients = await authRepository.getAssignedPatients();
      state = AsyncValue.data(patients); // Set fetched data
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace); // Set error state
    }
  }

  // Refresh assigned patients (same as fetch but allows external trigger)
  Future<void> refreshPatients() async {
    await fetchAssignedPatients();
  }

  void removePatient(Patient1 patient) {
    state.whenData((patients) {
      final updatedPatients = List<Patient1>.from(patients)
        ..removeWhere((item) => item.id == patient.id); // Remove the patient
      state = AsyncValue.data(updatedPatients); // Update the state
    });
  }
}

class LabPatientsNotifier extends StateNotifier<List<LabPatient>> {
  LabPatientsNotifier() : super([]);

  Future<void> fetchLabPatients() async {
    final response =
        await http.get(Uri.parse('${KVM_URL}/labs/getlabPatients'));
    print(response.body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final labPatientsResponse = LabPatientsResponse.fromJson(data);
      state = labPatientsResponse.labReports; // Update the state
    } else {
      throw Exception('Failed to load lab patients');
    }
  }
}

class AdmittedPatientsNotifier
    extends StateNotifier<AsyncValue<List<Patient1>>> {
  final AuthRepository authRepository;

  AdmittedPatientsNotifier(this.authRepository)
      : super(const AsyncValue.loading());

  // Fetch assigned patients
  Future<void> fetchAdmittedPatients() async {
    try {
      state = const AsyncValue.loading(); // Show loading state
      final patients = await authRepository.getAdmittedPatients();
      state = AsyncValue.data(patients); // Set fetched data
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace); // Set error state
    }
  }

  // Refresh assigned patients (same as fetch but allows external trigger)
  Future<void> refreshPatients() async {
    await fetchAdmittedPatients();
  }

  void removePatient(Patient1 patient) {
    state.whenData((patients) {
      final updatedPatients = List<Patient1>.from(patients)
        ..removeWhere((item) => item.id == patient.id); // Remove the patient
      state = AsyncValue.data(updatedPatients); // Update the state
    });
  }
}

class LabReportNotifier extends StateNotifier<AsyncValue<List<LabReport1>>> {
  final LabReportRepository repository;

  LabReportNotifier(this.repository) : super(const AsyncValue.loading());

  Future<void> fetchLabPatients() async {
    try {
      state = const AsyncValue.loading();
      final response = await repository.fetchLabPatients();
      state = AsyncValue.data(response.labReports ?? []);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final labReportNotifierProvider =
    StateNotifierProvider<LabReportNotifier, AsyncValue<List<LabReport1>>>(
  (ref) {
    final repository = ref.read(labReportRepositoryProvider);
    return LabReportNotifier(repository);
  },
);
