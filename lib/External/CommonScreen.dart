import 'dart:convert';
import 'package:doctordesktop/External/AppointMentScreen.dart';
import 'package:doctordesktop/External/DashBoard.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// We'll use the provided HospitalTheme
// import 'hospital_theme.dart';

// Splash screen to check for existing login
class SplashScreen1 extends StatefulWidget {
  const SplashScreen1({Key? key}) : super(key: key);

  @override
  State<SplashScreen1> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen1> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('doctor_token');
    final userType = prefs.getString('user_type');

    if (token != null && userType != null) {
      // User is logged in, navigate to the appropriate dashboard
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DoctorDashboard(),
          ),
        );
      });
    } else {
      // User is not logged in, navigate to login screen
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/hospital_logo.png',
              width: 180,
              height: 180,
              // If the asset doesn't exist, use a placeholder
              errorBuilder: (context, error, stackTrace) => Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: HospitalTheme.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_hospital,
                  size: 80,
                  color: HospitalTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Hospital Management System',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  final List<String> _loginTypes = [
    'Hospital Doctor',
    'External Doctor',
    'Admin',
    'Staff',
  ];

  void _changePage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: HospitalTheme.primary,
          ),
          onPressed: () {
            // Navigate back to home screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => HomeScreen(),
              ),
            );
          },
        ),
      ),
      body: Row(
        children: [
          // Left Panel: Navigation between login types
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: HospitalTheme.primary,
              boxShadow: HospitalTheme.shadow,
            ),
            child: Column(
              children: [
                const SizedBox(height: 60),
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_hospital,
                    size: 60,
                    color: HospitalTheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Hospital Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: ListView.builder(
                    itemCount: _loginTypes.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildLoginTypeButton(
                          title: _loginTypes[index],
                          icon: _getIconForLoginType(index),
                          isSelected: _currentPage == index,
                          onTap: () {
                            setState(() {
                              _currentPage = index;
                            });
                            _changePage(index);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Right Panel: Login Forms
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                // Hospital Doctor Login
                LoginForm(
                  title: 'Hospital Doctor Login',
                  apiEndpoint: '${KVM_URL}/users/signin',
                  userType: 'hospital_doctor',
                  fields: const ['email', 'password'],
                ),
                // External Doctor Login
                LoginForm(
                  title: 'External Doctor Login',
                  apiEndpoint: '${KVM_URL}/users/externalSigninDoctor',
                  userType: 'doctor',
                  fields: const ['email', 'password'],
                ),
                // Admin Login
                LoginForm(
                  title: 'Admin Login',
                  apiEndpoint: '${KVM_URL}/users/adminSignin',
                  userType: 'admin',
                  fields: const ['email', 'password'],
                ),
                // Staff Login
                LoginForm(
                  title: 'Staff Login',
                  apiEndpoint: '${KVM_URL}/users/staffSignin',
                  userType: 'staff',
                  fields: const ['email', 'password', 'hospitalId'],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForLoginType(int index) {
    switch (index) {
      case 0:
        return Icons.medical_services_outlined;
      case 1:
        return Icons.health_and_safety_outlined;
      case 2:
        return Icons.admin_panel_settings_outlined;
      case 3:
        return Icons.people_outlined;
      default:
        return Icons.person_outlined;
    }
  }

  Widget _buildLoginTypeButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? HospitalTheme.primary : Colors.white,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? HospitalTheme.primary : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  final String title;
  final String apiEndpoint;
  final String userType;
  final List<String> fields;

  const LoginForm({
    Key? key,
    required this.title,
    required this.apiEndpoint,
    required this.userType,
    required this.fields,
  }) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Initialize controllers for each field
    for (var field in widget.fields) {
      _controllers[field] = TextEditingController();
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _getFieldLabel(String field) {
    switch (field) {
      case 'email':
        return 'Email';
      case 'password':
        return 'Password';
      case 'hospitalId':
        return 'Hospital ID';
      default:
        return field.substring(0, 1).toUpperCase() + field.substring(1);
    }
  }

  IconData _getFieldIcon(String field) {
    switch (field) {
      case 'email':
        return Icons.email_outlined;
      case 'password':
        return Icons.lock_outlined;
      case 'hospitalId':
        return Icons.local_hospital_outlined;
      default:
        return Icons.person_outlined;
    }
  }

  bool _isPasswordField(String field) {
    return field == 'password';
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Prepare request body
        Map<String, dynamic> requestBody = {};
        for (var field in widget.fields) {
          requestBody[field] = _controllers[field]!.text;
        }

        // Make API call
        final response = await http.post(
          Uri.parse(widget.apiEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestBody),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          // Save credentials to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('doctor_token', data['token']);
          await prefs.setString('user_type', widget.userType);

          // Store user details
          await prefs.setString('user_id', data['user']['_id']);
          await prefs.setString('user_email', data['user']['email']);
          await prefs.setString(
              'user_name', data['user']['doctorName'] ?? 'User');

          if (data['user']['imageUrl'] != null) {
            await prefs.setString('user_image', data['user']['imageUrl']);
          }

          if (data['user']['speciality'] != null) {
            await prefs.setString(
                'doctor_speciality', data['user']['speciality']);
          }

          // Navigate to dashboard
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => DoctorDashboard(),
            ),
          );
        } else {
          final data = json.decode(response.body);
          setState(() {
            _errorMessage = data['message'] ??
                'Login failed. Please check your credentials.';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Connection error. Please try again.';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...widget.fields
                      .map((field) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getFieldLabel(field),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _controllers[field],
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    _getFieldIcon(field),
                                    color: HospitalTheme.textMedium,
                                  ),
                                  suffixIcon: _isPasswordField(field)
                                      ? IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: HospitalTheme.textMedium,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                        )
                                      : null,
                                  hintText:
                                      'Enter your ${_getFieldLabel(field).toLowerCase()}',
                                ),
                                obscureText:
                                    _isPasswordField(field) && _obscurePassword,
                                keyboardType: field == 'email'
                                    ? TextInputType.emailAddress
                                    : TextInputType.text,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '${_getFieldLabel(field)} is required';
                                  }
                                  if (field == 'email' &&
                                      !value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          ))
                      .toList(),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: HospitalTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: HospitalTheme.error,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: HospitalTheme.error,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Login'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Sample Doctor Dashboard
