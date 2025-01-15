import 'package:doctordesktop/Provider.dart';
import 'package:doctordesktop/StateProvider.dart';
import 'package:doctordesktop/repositories/auth_repository.dart';
import 'package:doctordesktop/model/getDoctorProfile.dart';
import 'package:doctordesktop/model/getLabModel.dart';
import 'package:doctordesktop/model/getNewPatientModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

class AuthController extends StateNotifier<bool> {
  AuthController(this.ref) : super(false) {
    print("AuthController initialized");

    _loadToken();
  }

  final Ref ref;
  Future<void> _loadToken() async {
    final authRepository = ref.read(authRepositoryProvider);
    final token = await authRepository
        .getToken(); // Retrieve token from SharedPreferences
    print(
        "Retrieved token from SharedPreferences: $token"); // Debugging token retrieval
    if (token != null) {
      ref.read(userTokenProvider.notifier).state =
          token; // Update the provider state
      state = true;
      print("Token loaded from SharedPreferences: $token");
    } else {
      print("No token found in SharedPreferences.");
    }
  }

  Future<void> login(String email, String password, String usertype) async {
    final authRepository = ref.read(authRepositoryProvider);
    String? token;

    if (usertype == 'nurse') {
      token = await authRepository.loginNurse(email, password);
    } else {
      token = await authRepository.login(email, password);
    }

    if (token != null) {
      print("hello");
      ref.read(userTokenProvider.notifier).state = token;
      ref.read(userTypeProvider.notifier).state = usertype;
      // Debug logs
      print("Login successful");
      print("Token: $token");
      print("User type: $usertype");
      state = true;
    }
  }

  Future<void> logout() async {
    final authRepository = ref.read(authRepositoryProvider);
    await authRepository.clearAllData();
    await authRepository.clearToken();
    await authRepository.clearUsertype();
    ref.read(userTokenProvider.notifier).state = null;
    ref.read(userTypeProvider.notifier).state = null;
    state = false;
  }

  Future<String?> checkLoginStatus() async {
    final authRepository = ref.read(authRepositoryProvider);
    final token = await authRepository.getToken();
    if (token != null) {
      state = true;
    }
    return token;
  }

  final authControllerProvider =
      StateNotifierProvider<AuthController, bool>((ref) {
    return AuthController(ref);
  });

  Future<String?> getUsertype() async {
    final authRepository = ref.read(authRepositoryProvider);
    return await authRepository.getUsertype();
  }
}

final patientListProvider = FutureProvider<List<Patient1>>((ref) async {
  final authRepository = ref.read(authRepositoryProvider);
  return authRepository.fetchPatients();
});

final authControllerProvider = StateNotifierProvider<AuthController, bool>(
  (ref) => AuthController(ref),
);

// final fetchDoctorProfile = FutureProvider<DoctorProfile>((ref) async {
//   final authRepository = ref.read(authRepositoryProvider);
//   return await authRepository.fetchDoctorProfile();
// });
final doctorProfileProvider =
    StateNotifierProvider<DoctorProfileNotifier, DoctorProfile?>((ref) {
  final authRepository = ref.read(
      authRepositoryProvider); // Assuming you have a provider for AuthRepository
  return DoctorProfileNotifier(authRepository);
});

final assignedPatientsProvider = FutureProvider<List<Patient1>>((ref) async {
  final token = ref.watch(userTokenProvider);
  // print('token is  $token');
  if (token == null) {
    // Return empty list or handle unauthenticated state
    return [];
  }

  final authRepository = ref.read(authRepositoryProvider);
  return await authRepository.getAssignedPatients();
});
final labPatientsProvider =
    StateNotifierProvider<LabPatientsNotifier, List<LabPatient>>((ref) {
  return LabPatientsNotifier();
});
// final assignedLabsProvider = FutureProvider<List<AssignedLab>>((ref) async {
//   final authRepository = ref.read(authRepositoryProvider);
//   return await authRepository.getAssignedLabs();
// });
