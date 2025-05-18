// lib/screens/login_screen.dart - Fixed responsive handling
import 'package:doctordesktop/Check.dart';
import 'package:doctordesktop/Doctor/DoctorMainScreen.dart';
import 'package:doctordesktop/constants/Assets.dart';
import 'package:doctordesktop/main.dart';
import 'package:doctordesktop/repositories/auth_repository.dart';
import 'package:doctordesktop/services/animation_helper.dart';
import 'package:doctordesktop/services/design_helper.dart';
import 'package:doctordesktop/services/network_service.dart';
import 'package:doctordesktop/services/responsive_service.dart';
import 'package:doctordesktop/services/snackbar_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen1 extends ConsumerStatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen1>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final authController = AuthRepository();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  bool _isDesktopView = false; // Track current view

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
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

    final isTablet = ResponsiveHelper.isTablet(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter) {
          _login();
        }
      },
      child: Scaffold(
        backgroundColor:
            isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: _isDesktopView
            ? null
            : AppBar(
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomePage()),
                    );
                  },
                ),
                title: Text(
                  "Login",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: AppColors.primary,
              ),
        body: Stack(
          children: [
            // Background design
            if (!_isDesktopView)
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
              ),

            // Desktop background decoration
            if (_isDesktopView) ...[
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
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
                    color: AppColors.primary.withOpacity(0.1),
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
                    color: AppColors.secondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],

            // Back button for desktop view
            if (_isDesktopView)
              Positioned(
                top: 20,
                left: 20,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDarkMode ? Colors.white : AppColors.primary,
                    size: 28,
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomePage()),
                    );
                  },
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
                      shadowColor: AppColors.shadowColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color:
                          isDarkMode ? AppColors.cardDark : AppColors.cardLight,
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

  // Desktop layout with side image
  Widget _buildDesktopLayout(bool isDarkMode) {
    return Row(
      children: [
        // Left side - Image
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.primary,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeSlideTransition(
                  animation: _animationController,
                  beginOffset: Offset(-0.35, 0),
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Image.asset(
                      '${AppImages.logo}',
                      width: 180,
                      height: 180,
                    ),
                  ),
                ),
                SizedBox(height: 24),
                FadeSlideTransition(
                  animation: _animationController,
                  beginOffset: Offset(-0.35, 0),
                  curve: Curves.easeOutQuart,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Welcome to ${AppStrings.hospitalName}",
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
                SizedBox(height: 16),
                FadeSlideTransition(
                  animation: _animationController,
                  beginOffset: Offset(-0.35, 0),
                  curve: Curves.easeOutQuart,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "Your trusted healthcare management system",
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
              padding: EdgeInsets.all(40),
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
    final spacing = ResponsiveHelper.getSpacing(
      context,
      small: 16,
      medium: 20,
      large: 24,
    );

    // Create widgets list based on the current layout
    final List<Widget> formWidgets = [];

    // Add logo for mobile/tablet only
    if (!isDesktop) {
      formWidgets.add(Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDarkMode ? AppColors.backgroundDark : Colors.grey[100],
        ),
        child: Image.asset(
          '${AppImages.logo}',
          fit: BoxFit.contain,
          width: ResponsiveHelper.getAdaptiveLogoSize(context),
          height: ResponsiveHelper.getAdaptiveLogoSize(context),
        ),
      ));

      formWidgets.add(SizedBox(height: spacing));

      // Welcome text for mobile/tablet
      formWidgets.add(Text(
        "Welcome to ${AppStrings.hospitalName}",
        textAlign: TextAlign.center,
        style: AppStyles.headingStyle(context, isDarkMode: isDarkMode),
      ));

      formWidgets.add(SizedBox(height: spacing * 0.4));

      formWidgets.add(Text(
        "Please login to continue",
        textAlign: TextAlign.center,
        style: AppStyles.subheadingStyle(context, isDarkMode: isDarkMode),
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
          color: isDarkMode ? Colors.white : AppColors.primary,
          letterSpacing: 0.5,
        ),
      ));

      formWidgets.add(SizedBox(height: spacing));
    }

    // Common fields for both layouts
    // Email field
    formWidgets.add(TextFormField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: AppStyles.inputDecoration(
        labelText: "Email",
        hintText: "Enter your email",
        prefixIcon: Icons.email_outlined,
        isDarkMode: isDarkMode,
      ),
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black,
        fontSize: 16.0,
      ),
      cursorColor: AppColors.primary,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    ));

    formWidgets.add(SizedBox(height: spacing));

    // Password field
    formWidgets.add(TextFormField(
      controller: passwordController,
      decoration: AppStyles.inputDecoration(
        labelText: "Password",
        hintText: "Enter your password",
        prefixIcon: Icons.lock_outline,
        isDarkMode: isDarkMode,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black,
        fontSize: 16.0,
      ),
      cursorColor: AppColors.primary,
      obscureText: _obscurePassword,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
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
          // Handle forgot password
          SnackbarService.showErrorSnackbar(
              "Please contact administrator to reset your password");
        },
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        child: Text(
          "Forgot Password?",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ));

    formWidgets.add(SizedBox(height: spacing));

    // Login button
    formWidgets.add(SizedBox(
      width: double.infinity,
      height: ResponsiveHelper.getAdaptiveButtonHeight(context),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: AppStyles.primaryButtonStyle(),
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                "Log In",
                style: AppStyles.buttonTextStyle(context),
              ),
      ),
    ));

    formWidgets.add(SizedBox(height: spacing * 1.5));

    // Footer branding
    formWidgets.add(Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.backgroundDark : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_hospital,
            color: AppColors.primary,
            size: 22,
          ),
          SizedBox(width: 10),
          Text(
            "${AppStrings.hospitalName}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
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

  // Enhanced login function that properly checks for internet connectivity
  Future<void> _login() async {
    // Close the keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // First check for internet connectivity
        bool isConnected = await NetworkService.instance.checkConnectivity();

        if (!isConnected) {
          // No internet connection, the error message is already shown by NetworkService
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // If connected, proceed with login
        final token = await authController.login(
          emailController.text.trim(),
          passwordController.text.trim(),
        );

        // Login successful, check user type
        final usertype = await authController.getUsertype();
        print("User type: $usertype");

        if (usertype == 'doctor' || usertype == 'external') {
          // Show success message
          SnackbarService.showSuccessSnackbar("Login successful!");

          // Navigate to DoctorMainScreen after a short delay for better UX
          Future.delayed(Duration(milliseconds: 500), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DoctorMainScreen()),
            );
          });
        } else {
          // Handle invalid user type
          SnackbarService.showErrorSnackbar("Access denied: Invalid user type");
        }
      } catch (e) {
        print("Login error: $e");
        SnackbarService.showErrorSnackbar("Login failed: ${e.toString()}");
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
