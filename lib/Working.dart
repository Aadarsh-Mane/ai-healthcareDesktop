import 'package:doctordesktop/Doctor/DoctorMainScreen.dart';
import 'package:doctordesktop/authProvider/auth_provider.dart';
import 'package:doctordesktop/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Doct extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the authController to determine login state
    final isLoggedIn = ref.watch(authControllerProvider);

    return MaterialApp(
      title: 'Your App Title',
      home: isLoggedIn
          ? AuthenticatedNavigation(ref) // Navigate based on user type
          : LoginScreen(), // Navigate to login if not authenticated
    );
  }
}

Widget AuthenticatedNavigation(WidgetRef ref) {
  return FutureBuilder<String?>(
    future: getUserType(), // Fetch user type directly from SharedPreferences
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(
            child: CircularProgressIndicator()); // Show loading indicator
      }

      final userType = snapshot.data; // Get the userType
      print("User type: $userType");

      if (userType == 'doctor') {
        return DoctorMainScreen(); // Navigate to Doctor's main screen
      } else if (userType == 'nurse') {
        // return NurseMainScreen(); // Navigate to Nurse's main screen
      }

      return LoginScreen(); // Fallback to LoginScreen if no userType found
    },
  );
}

Future<String?> getUserType() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('usertype'); // Fetch userType from SharedPreferences
}
