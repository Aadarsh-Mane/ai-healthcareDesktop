// login_screen.dart
import 'package:doctordesktop/Nurse/NurseDashBoardScreen.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Models
class User {
  final String id;
  final String email;
  final String nurseName;
  final String usertype;

  const User({
    required this.id,
    required this.email,
    required this.nurseName,
    required this.usertype,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      nurseName: json['nurseName'] ?? '',
      usertype: json['usertype'] ?? '',
    );
  }
}

class LoginResponse {
  final User user;
  final String token;

  const LoginResponse({
    required this.user,
    required this.token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: User.fromJson(json['user'] ?? {}),
      token: json['token'] ?? '',
    );
  }
}

// Providers
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.read(httpClientProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final http.Client _httpClient;

  AuthNotifier(this._httpClient) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();

    try {
      final url = Uri.parse('$KVM_URL/nurse/signin');
      final response = await _httpClient
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final loginResponse = LoginResponse.fromJson(responseData);

        // Store token in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('nurse_token', loginResponse.token);
        await prefs.setString('user_id', loginResponse.user.id);
        await prefs.setString('user_email', loginResponse.user.email);
        await prefs.setString('user_name', loginResponse.user.nurseName);
        await prefs.setString('user_type', loginResponse.user.usertype);

        state = AsyncValue.data(loginResponse.user);
      } else {
        String errorMessage = 'Login failed';

        if (response.statusCode == 401) {
          errorMessage = 'Invalid email or password';
        } else if (response.statusCode == 404) {
          errorMessage = 'Service not found';
        } else {
          try {
            final errorData = json.decode(response.body);
            if (errorData['message'] != null) {
              errorMessage = errorData['message'];
            }
          } catch (e) {
            // Use default error message if JSON parsing fails
          }
        }

        state = AsyncValue.error(errorMessage, StackTrace.current);
      }
    } catch (e, stackTrace) {
      String errorMessage = 'An unexpected error occurred';

      if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Connection timeout. Please check your network';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Network error. Please check your connection';
      }

      state = AsyncValue.error(errorMessage, stackTrace);
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      state = const AsyncValue.data(null);
    } catch (e) {
      // Handle logout error gracefully
      state = const AsyncValue.data(null);
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('nurse_token');

      if (token != null) {
        final userId = prefs.getString('user_id') ?? '';
        final userEmail = prefs.getString('user_email') ?? '';
        final userName = prefs.getString('user_name') ?? '';
        final userType = prefs.getString('user_type') ?? '';

        final user = User(
          id: userId,
          email: userEmail,
          nurseName: userName,
          usertype: userType,
        );

        state = AsyncValue.data(user);
      }
    } catch (e) {
      state = const AsyncValue.data(null);
    }
  }
}

// Login Form Controller
final loginFormProvider =
    StateNotifierProvider<LoginFormNotifier, LoginFormState>((ref) {
  return LoginFormNotifier();
});

class LoginFormState {
  final String email;
  final String password;
  final bool isPasswordVisible;
  final bool isLoading;

  const LoginFormState({
    this.email = '',
    this.password = '',
    this.isPasswordVisible = false,
    this.isLoading = false,
  });

  LoginFormState copyWith({
    String? email,
    String? password,
    bool? isPasswordVisible,
    bool? isLoading,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LoginFormNotifier extends StateNotifier<LoginFormState> {
  LoginFormNotifier() : super(const LoginFormState());

  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }

  void updatePassword(String password) {
    state = state.copyWith(password: password);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }
}

// Login Screen Widget
class NurseLoginScreen extends ConsumerStatefulWidget {
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const NurseLoginScreen({
    super.key,
    this.showBackButton = true,
    this.onBackPressed,
  });

  @override
  ConsumerState<NurseLoginScreen> createState() => _NurseLoginScreenState();
}

class _NurseLoginScreenState extends ConsumerState<NurseLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Pre-fill for testing
    _emailController.text = 'nurse1@gmail.com';
    _passwordController.text = 'nurse1';

    // Check auth status on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authStateProvider.notifier).checkAuthStatus();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyboardShortcuts(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Ctrl/Cmd + Enter to submit form
      if ((HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed) &&
          event.logicalKey == LogicalKeyboardKey.enter) {
        _handleLogin();
      }
      // Escape key to go back
      else if (event.logicalKey == LogicalKeyboardKey.escape &&
          widget.showBackButton) {
        _handleBackAction();
      }
    }
  }

  void _handleBackAction() {
    if (widget.onBackPressed != null) {
      widget.onBackPressed!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    ref.read(loginFormProvider.notifier).setLoading(true);

    try {
      await ref.read(authStateProvider.notifier).login(email, password);
    } finally {
      if (mounted) {
        ref.read(loginFormProvider.notifier).setLoading(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 768;
    final isTablet = screenSize.width > 600 && screenSize.width <= 768;
    final formWidth =
        isDesktop ? 400.0 : (isTablet ? 350.0 : screenSize.width * 0.9);

    ref.listen(authStateProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const NurseDashBoardScreen()),
            );
          }
        },
        loading: () {},
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: HospitalTheme.error,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32.0 : 16.0,
                vertical: 16.0,
              ),
            ),
          );
        },
      );
    });

    final authState = ref.watch(authStateProvider);
    final formState = ref.watch(loginFormProvider);

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyboardShortcuts,
      child: Scaffold(
        backgroundColor: HospitalTheme.background,
        appBar: widget.showBackButton
            ? HospitalTheme.buildAppBar(
                context: context,
                title: 'Nurse Login',
                showBackButton: true,
                onBackPressed: _handleBackAction,
              )
            : null,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32.0 : 16.0,
                vertical: 24.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: formWidth,
                  minHeight:
                      screenSize.height - (widget.showBackButton ? 104 : 48),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hospital Logo/Header
                    _buildHeader(context, isDesktop),

                    SizedBox(height: isDesktop ? 48.0 : 32.0),

                    // Login Form
                    _buildLoginForm(context, formState, authState),

                    SizedBox(height: isDesktop ? 32.0 : 24.0),

                    // Footer
                    _buildFooter(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    return Column(
      children: [
        Container(
          width: isDesktop ? 120.0 : 100.0,
          height: isDesktop ? 120.0 : 100.0,
          decoration: BoxDecoration(
            color: HospitalTheme.primary,
            shape: BoxShape.circle,
            boxShadow: HospitalTheme.shadow,
          ),
          child: Icon(
            Icons.local_hospital,
            color: HospitalTheme.textOnPrimary,
            size: isDesktop ? 60.0 : 50.0,
          ),
        ),
        SizedBox(height: isDesktop ? 24.0 : 16.0),
        Text(
          'Hospital Management',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: HospitalTheme.primary,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8.0),
        Text(
          'Nurse Portal',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HospitalTheme.textMedium,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context, LoginFormState formState,
      AsyncValue<User?> authState) {
    final isLoading = authState.isLoading || formState.isLoading;

    return HospitalTheme.buildCard(
      padding: const EdgeInsets.all(32.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sign In',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: HospitalTheme.textDark,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32.0),

            // Email Field
            TextFormField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !isLoading,
              onChanged: (value) =>
                  ref.read(loginFormProvider.notifier).updateEmail(value),
              onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter your email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value.trim())) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),

            const SizedBox(height: 24.0),

            // Password Field
            TextFormField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              obscureText: !formState.isPasswordVisible,
              textInputAction: TextInputAction.done,
              enabled: !isLoading,
              onChanged: (value) =>
                  ref.read(loginFormProvider.notifier).updatePassword(value),
              onFieldSubmitted: (_) => _handleLogin(),
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    formState.isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: isLoading
                      ? null
                      : () => ref
                          .read(loginFormProvider.notifier)
                          .togglePasswordVisibility(),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 32.0),

            // Login Button
            SizedBox(
              height: 48.0,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleLogin,
                child: isLoading
                    ? const SizedBox(
                        height: 20.0,
                        width: 20.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Sign In'),
              ),
            ),

            const SizedBox(height: 16.0),

            // Keyboard Shortcut Hints
            _buildKeyboardHints(context),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardHints(BuildContext context) {
    return Column(
      children: [
        Text(
          'Keyboard Shortcuts:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: HospitalTheme.textMedium,
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4.0),
        Text(
          'Ctrl+Enter: Sign in • Escape: Go back',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: HospitalTheme.textLight,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Text(
          '© 2025 Hospital Management System',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: HospitalTheme.textLight,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8.0),
        Text(
          'Secure • Reliable • Professional',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: HospitalTheme.textLight,
                fontSize: 12.0,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
