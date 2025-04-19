import 'package:doctordesktop/Doctor/DoctorMainScreen.dart';
import 'package:doctordesktop/authProvider/auth_provider.dart';
import 'package:doctordesktop/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Doct extends ConsumerStatefulWidget {
  @override
  _DoctState createState() => _DoctState();
}

class _DoctState extends ConsumerState<Doct> {
  @override
  void initState() {
    super.initState();
    // Check authentication status on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).checkLoginStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the authController to determine login state
    final isLoggedIn = ref.watch(authControllerProvider);

    return isLoggedIn ? AuthenticatedNavigation(ref) : LoginScreen1();
  }
}

Widget AuthenticatedNavigation(WidgetRef ref) {
  return FutureBuilder<String?>(
    future: ref.read(authControllerProvider.notifier).getUsertype(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final userType = snapshot.data;
      print("User type from provider: $userType");

      if (userType == 'doctor') {
        return DoctorMainScreen();
      } else if (userType == 'nurse') {
        // return NurseMainScreen();
        return Scaffold(
          body: Center(
            child: Text("Nurse Dashboard - Not Implemented"),
          ),
        );
      }

      // If we get here, something is wrong with the user type
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Invalid user type: $userType"),
              ElevatedButton(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).logout();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen1()),
                  );
                },
                child: Text("Go to Login"),
              ),
            ],
          ),
        ),
      );
    },
  );
}
