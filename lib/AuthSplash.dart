// auth_splash_screen.dart
import 'package:doctordesktop/Check.dart';
import 'package:doctordesktop/Doctor/DoctorMainScreen.dart';
import 'package:doctordesktop/authProvider/auth_provider.dart';
import 'package:doctordesktop/constants/Assets.dart';
import 'package:doctordesktop/main.dart';
import 'package:doctordesktop/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthSplashScreen extends ConsumerStatefulWidget {
  const AuthSplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthSplashScreen> createState() => _AuthSplashScreenState();
}

class _AuthSplashScreenState extends ConsumerState<AuthSplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
    // Check authentication status on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).checkLoginStatus();
    });
  }

  Future<void> _initializeApp() async {
    // Delay to show splash screen for at least 1.5 seconds
    await Future.delayed(const Duration(milliseconds: 1500));

    // Initialize auth state
    final authRepository = ref.read(authRepositoryProvider);
    final token = await authRepository.getToken();
    final userType = await authRepository.getUsertype();

    print(
        "App Initializing - Token: ${token != null ? 'exists' : 'null'}, UserType: $userType");

    if (!mounted) return;

    if (token != null && (userType == 'doctor' || userType == 'external')) {
      // User is already logged in as a doctor, navigate directly to doctor screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => DoctorMainScreen()),
      );
    } else {
      // Navigate to home page where user can choose which module to access
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen1()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with pulse animation
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Image.asset(
                    '${AppImages.logo}',
                    width: 180,
                    height: 180,
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // App name
            const Text(
              'DocneX Care',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF005F9E),
              ),
            ),

            const SizedBox(height: 8),

            // Tagline
            Text(
              'Healthcare Management System',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 40),

            // Loading indicator
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF005F9E)),
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
