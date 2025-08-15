// nurse_login_screen.dart - Enhanced UI matching doctor login
import 'package:doctordesktop/Nurse/NurseDashBoardScreen.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ==================== MODELS ====================
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

// ==================== PROVIDERS ====================
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

// ==================== RESPONSIVE HELPER ====================
class ResponsiveHelper {
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > 768;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > 600 && width <= 768;
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width <= 600;

  static double getLoginCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isDesktop(context)) {
      return screenWidth * 0.75; // 75% of screen width on desktop
    } else if (isTablet(context)) {
      return screenWidth * 0.85; // 85% of screen width on tablet
    } else {
      return screenWidth * 0.95; // 95% of screen width on mobile
    }
  }

  static EdgeInsets getAdaptivePadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.all(40);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(32);
    } else {
      return const EdgeInsets.all(24);
    }
  }

  static double getSpacing(BuildContext context,
      {required double small, required double medium, required double large}) {
    if (isDesktop(context)) {
      return large;
    } else if (isTablet(context)) {
      return medium;
    } else {
      return small;
    }
  }

  static double getAdaptiveLogoSize(BuildContext context) {
    if (isDesktop(context)) {
      return 120;
    } else if (isTablet(context)) {
      return 100;
    } else {
      return 80;
    }
  }

  static double getAdaptiveButtonHeight(BuildContext context) {
    if (isDesktop(context)) {
      return 56;
    } else if (isTablet(context)) {
      return 52;
    } else {
      return 48;
    }
  }
}

// ==================== ANIMATION HELPERS ====================
class FadeSlideTransition extends StatelessWidget {
  final Widget child;
  final AnimationController animation;
  final Offset beginOffset;
  final Curve curve;

  const FadeSlideTransition({
    Key? key,
    required this.child,
    required this.animation,
    this.beginOffset = const Offset(0, 0.3),
    this.curve = Curves.easeOut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            beginOffset.dx * (1 - animation.value),
            beginOffset.dy * (1 - animation.value),
          ),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class StaggeredAnimations extends StatelessWidget {
  final List<Widget> children;
  final Duration interval;

  const StaggeredAnimations({
    Key? key,
    required this.children,
    this.interval = const Duration(milliseconds: 100),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final widget = entry.value;

        return TweenAnimationBuilder<double>(
          duration:
              Duration(milliseconds: 600 + (index * interval.inMilliseconds)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutQuart,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: widget,
        );
      }).toList(),
    );
  }
}

// ==================== MAIN SCREEN ====================
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

class _NurseLoginScreenState extends ConsumerState<NurseLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  late AnimationController _animationController;
  bool _isDesktopView = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill for testing
    _emailController.text = 'nurse1@gmail.com';
    _passwordController.text = 'nurse1';

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animationController.forward();

    // Check auth status on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authStateProvider.notifier).checkAuthStatus();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Determine if we're in desktop view
    final newIsDesktopView = ResponsiveHelper.isDesktop(context);

    // If the view type changed, restart animations
    if (_isDesktopView != newIsDesktopView) {
      _isDesktopView = newIsDesktopView;
      _animationController.reset();
      _animationController.forward();
    }

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
                horizontal: _isDesktopView ? 32.0 : 16.0,
                vertical: 16.0,
              ),
            ),
          );
        },
      );
    });

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyboardShortcuts,
      child: Scaffold(
        backgroundColor: HospitalTheme.background,
        appBar: _isDesktopView
            ? null
            : (widget.showBackButton
                ? HospitalTheme.buildAppBar(
                    context: context,
                    title: 'Nurse Login',
                    showBackButton: true,
                    onBackPressed: _handleBackAction,
                  )
                : null),
        body: Stack(
          children: [
            // Background design for mobile/tablet
            if (!_isDesktopView && widget.showBackButton)
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: HospitalTheme.primary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
              ),

            // Desktop background decoration
            if (_isDesktopView) ..._buildDesktopBackground(screenSize),

            // Back button for desktop view
            if (_isDesktopView && widget.showBackButton)
              Positioned(
                top: 20,
                left: 20,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDarkMode ? Colors.white : HospitalTheme.primary,
                    size: 28,
                  ),
                  onPressed: _handleBackAction,
                ),
              ),

            // Main content
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _isDesktopView ? 0 : screenSize.width * 0.05,
                    vertical: 20,
                  ),
                  child: Container(
                    width: ResponsiveHelper.getLoginCardWidth(context),
                    constraints: BoxConstraints(
                      maxHeight: _isDesktopView
                          ? screenSize.height * 0.85
                          : double.infinity,
                    ),
                    child: Card(
                      elevation: 8,
                      shadowColor: HospitalTheme.primary.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: HospitalTheme.cardBackground,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _isDesktopView
                            ? _buildDesktopLayout(isDarkMode)
                            : _buildMobileTabletLayout(isDarkMode),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDesktopBackground(Size screenSize) {
    return [
      Positioned(
        top: -100,
        right: -100,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            color: HospitalTheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        bottom: -150,
        left: -150,
        child: Container(
          width: 400,
          height: 400,
          decoration: BoxDecoration(
            color: HospitalTheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        top: screenSize.height * 0.3,
        left: screenSize.width * 0.1,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: HospitalTheme.secondary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
        ),
      ),
    ];
  }

  // Desktop layout with side image
  Widget _buildDesktopLayout(bool isDarkMode) {
    return Row(
      children: [
        // Left side - Branding
        Expanded(
          flex: 5,
          child: Container(
            color: HospitalTheme.primary,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeSlideTransition(
                  animation: _animationController,
                  beginOffset: const Offset(-0.35, 0),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_hospital,
                      size: 120,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeSlideTransition(
                  animation: _animationController,
                  beginOffset: const Offset(-0.35, 0),
                  curve: Curves.easeOutQuart,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Welcome to Hospital Management",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideTransition(
                  animation: _animationController,
                  beginOffset: const Offset(-0.35, 0),
                  curve: Curves.easeOutQuart,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "Nurse Portal - Your trusted healthcare management system",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right side - Login form
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: _buildLoginForm(isDarkMode, true),
            ),
          ),
        ),
      ],
    );
  }

  // Mobile and tablet layout
  Widget _buildMobileTabletLayout(bool isDarkMode) {
    return SingleChildScrollView(
      child: Padding(
        padding: ResponsiveHelper.getAdaptivePadding(context),
        child: _buildLoginForm(isDarkMode, false),
      ),
    );
  }

  // Common login form for all layouts
  Widget _buildLoginForm(bool isDarkMode, bool isDesktop) {
    final authState = ref.watch(authStateProvider);
    final formState = ref.watch(loginFormProvider);
    final isLoading = authState.isLoading || formState.isLoading;

    final spacing = ResponsiveHelper.getSpacing(
      context,
      small: 16,
      medium: 20,
      large: 24,
    );

    final List<Widget> formWidgets = [];

    // Add logo for mobile/tablet only
    if (!isDesktop) {
      formWidgets.add(Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: HospitalTheme.surfaceLight,
        ),
        child: Icon(
          Icons.local_hospital,
          size: ResponsiveHelper.getAdaptiveLogoSize(context),
          color: HospitalTheme.primary,
        ),
      ));

      formWidgets.add(SizedBox(height: spacing));

      // Welcome text for mobile/tablet
      formWidgets.add(Text(
        "Welcome to Hospital Management",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: ResponsiveHelper.isTablet(context) ? 24 : 20,
          fontWeight: FontWeight.bold,
          color: HospitalTheme.textDark,
        ),
      ));

      formWidgets.add(SizedBox(height: spacing * 0.4));

      formWidgets.add(Text(
        "Nurse Portal - Please login to continue",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          color: HospitalTheme.textMedium,
        ),
      ));

      formWidgets.add(SizedBox(height: spacing * 1.5));
    }

    // Desktop heading
    if (isDesktop) {
      formWidgets.add(Text(
        "Login to your account",
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: HospitalTheme.primary,
          letterSpacing: 0.5,
        ),
      ));

      formWidgets.add(SizedBox(height: spacing));
    }

    // Email field
    formWidgets.add(TextFormField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      enabled: !isLoading,
      onChanged: (value) =>
          ref.read(loginFormProvider.notifier).updateEmail(value),
      onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
      decoration: InputDecoration(
        labelText: 'Email Address',
        hintText: 'Enter your email',
        prefixIcon: Icon(Icons.email_outlined, color: HospitalTheme.primary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: HospitalTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: HospitalTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: HospitalTheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: HospitalTheme.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      style: const TextStyle(fontSize: 16.0),
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
    ));

    formWidgets.add(SizedBox(height: spacing));

    // Password field
    formWidgets.add(TextFormField(
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
        prefixIcon: Icon(Icons.lock_outlined, color: HospitalTheme.primary),
        suffixIcon: IconButton(
          icon: Icon(
            formState.isPasswordVisible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: HospitalTheme.textMedium,
          ),
          onPressed: isLoading
              ? null
              : () => ref
                  .read(loginFormProvider.notifier)
                  .togglePasswordVisibility(),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: HospitalTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: HospitalTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: HospitalTheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: HospitalTheme.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      style: const TextStyle(fontSize: 16.0),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Password is required';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    ));

    formWidgets.add(SizedBox(height: spacing * 0.5));

    // Forgot password link
    formWidgets.add(Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  "Please contact administrator to reset your password"),
              backgroundColor: HospitalTheme.info,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        style: TextButton.styleFrom(
          foregroundColor: HospitalTheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        child: const Text(
          "Forgot Password?",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ));

    formWidgets.add(SizedBox(height: spacing));

    // Login button
    formWidgets.add(SizedBox(
      width: double.infinity,
      height: ResponsiveHelper.getAdaptiveButtonHeight(context),
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: HospitalTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                "Sign In",
                style: TextStyle(
                  fontSize: ResponsiveHelper.isDesktop(context) ? 18 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    ));

    formWidgets.add(SizedBox(height: spacing * 0.8));

    // Keyboard shortcuts hint
    formWidgets.add(_buildKeyboardHints());

    formWidgets.add(SizedBox(height: spacing));

    // Footer branding
    formWidgets.add(Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: HospitalTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: HospitalTheme.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_hospital,
            color: HospitalTheme.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            "Hospital Management System",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.primary,
            ),
          ),
        ],
      ),
    ));

    return Form(
      key: _formKey,
      child: StaggeredAnimations(
        children: formWidgets,
      ),
    );
  }

  Widget _buildKeyboardHints() {
    return Column(
      children: [
        Text(
          'Keyboard Shortcuts:',
          style: TextStyle(
            fontSize: 12,
            color: HospitalTheme.textMedium,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4.0),
        Text(
          'Ctrl+Enter: Sign in • Escape: Go back',
          style: TextStyle(
            fontSize: 11,
            color: HospitalTheme.textLight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
