import 'package:doctordesktop/Admin/AdminDashboard.dart';
import 'package:doctordesktop/Doctor/SeeNurseAttendace.dart';
import 'package:doctordesktop/Doctor/fetchDoctor.dart';
import 'package:doctordesktop/Patient/fetchPatient.dart';
import 'package:doctordesktop/constants/Assets.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/reception/PatientAllDischargedScreen.dart';
import 'package:doctordesktop/reception/PatientDischarge.dart';
import 'package:doctordesktop/reception/PatientRegister.dart';
import 'package:doctordesktop/screens/DoctorRegister.dart';
import 'package:doctordesktop/screens/ListPatienAssignToDoctor.dart';
import 'package:doctordesktop/screens/NurseRegister.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdminAuthDialog extends StatefulWidget {
  const AdminAuthDialog({Key? key}) : super(key: key);

  @override
  State<AdminAuthDialog> createState() => _AdminAuthDialogState();
}

class _AdminAuthDialogState extends State<AdminAuthDialog> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _userIdFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _dialogFocusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;

  static const String correctUserId = "${AllUserPassword.adminUser}";
  static const String correctPassword = "${AllUserPassword.adminPassword}";

  @override
  void initState() {
    super.initState();
    // Auto-focus on first field when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userIdFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    _userIdFocusNode.dispose();
    _passwordFocusNode.dispose();
    _dialogFocusNode.dispose();
    super.dispose();
  }

  void _authenticate() async {
    if (_isLoading) return;

    final userId = _userIdController.text.trim();
    final password = _passwordController.text;

    // Validation
    if (userId.isEmpty) {
      _showError('Please enter User ID');
      _userIdFocusNode.requestFocus();
      return;
    }

    if (password.isEmpty) {
      _showError('Please enter Password');
      _passwordFocusNode.requestFocus();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulate authentication delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));

      if (userId == correctUserId && password == correctPassword) {
        if (mounted) {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AdminDashBoardScreen(),
            ),
          );
        }
      } else {
        _showError(
            'Invalid credentials. Please check your User ID and Password.');
        _passwordController.clear();
        _passwordFocusNode.requestFocus();
      }
    } catch (e) {
      _showError('Authentication failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        _authenticate();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;

    return KeyboardListener(
      focusNode: _dialogFocusNode,
      onKeyEvent: _handleKeyEvent,
      autofocus: true,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: HospitalTheme.radiusMedium,
        ),
        backgroundColor: HospitalTheme.cardBackground,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: HospitalTheme.primary.withOpacity(0.1),
                borderRadius: HospitalTheme.radiusSmall,
              ),
              child: Icon(
                Icons.admin_panel_settings,
                color: HospitalTheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Admin Authentication',
              style: TextStyle(
                fontSize: isLargeScreen ? 22 : 20,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: isLargeScreen ? 400 : size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: HospitalTheme.error.withOpacity(0.1),
                    borderRadius: HospitalTheme.radiusSmall,
                    border: Border.all(
                      color: HospitalTheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: HospitalTheme.error,
                        size: 20,
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
              _buildTextField(
                controller: _userIdController,
                focusNode: _userIdFocusNode,
                labelText: 'User ID',
                prefixIcon: Icons.person_outline,
                onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                labelText: 'Password',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                onSubmitted: (_) => _authenticate(),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 8),
              Text(
                'Press Enter to login or Escape to cancel',
                style: TextStyle(
                  fontSize: 12,
                  color: HospitalTheme.textLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color:
                    _isLoading ? HospitalTheme.textLight : HospitalTheme.error,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isLoading ? null : _authenticate,
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.primary,
              foregroundColor: HospitalTheme.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: HospitalTheme.radiusSmall,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: HospitalTheme.textOnPrimary,
                    ),
                  )
                : const Text(
                    'Login',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String labelText,
    required IconData prefixIcon,
    bool obscureText = false,
    Function(String)? onSubmitted,
    bool enabled = true,
  }) {
    return TextFormField(
      cursorColor: Colors.black,
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      enabled: enabled,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: enabled ? HospitalTheme.textDark : HospitalTheme.textLight,
        ),
        prefixIcon: Icon(prefixIcon),
        border: OutlineInputBorder(
          borderRadius: HospitalTheme.radiusSmall,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: HospitalTheme.radiusSmall,
          borderSide: BorderSide(color: HospitalTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: HospitalTheme.radiusSmall,
          borderSide: BorderSide(color: HospitalTheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: HospitalTheme.radiusSmall,
          borderSide: BorderSide(color: HospitalTheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      style: TextStyle(
        color: enabled ? HospitalTheme.textDark : HospitalTheme.textLight,
      ),
    );
  }
}

class DesktopButtonScreen extends StatelessWidget {
  const DesktopButtonScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 1200;
    final isMediumScreen = size.width > 800;

    return Scaffold(
      backgroundColor: HospitalTheme.background,
      appBar: HospitalTheme.buildAppBar(
        context: context,
        title: 'Admin Panel',
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppImages.admin),
                fit: BoxFit.contain,
                alignment: Alignment.centerRight,
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isLargeScreen ? 40 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: constraints.maxHeight * 0.1),
                  _buildButtonGrid(
                    context,
                    isLargeScreen: isLargeScreen,
                    isMediumScreen: isMediumScreen,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildButtonGrid(
    BuildContext context, {
    required bool isLargeScreen,
    required bool isMediumScreen,
  }) {
    final buttonsPerRow = isLargeScreen ? 3 : (isMediumScreen ? 2 : 1);
    final buttonWidth =
        isLargeScreen ? 200.0 : (isMediumScreen ? 180.0 : 160.0);
    final buttonHeight = 60.0;

    final buttons = [
      _AdminButton(
        title: 'All Doctors',
        icon: Icons.medical_services_outlined,
        onPressed: () => _navigateToScreen(context, const DoctorListScreen()),
        width: buttonWidth,
        height: buttonHeight,
      ),
      _AdminButton(
        title: 'Doctor Assignments',
        icon: Icons.assignment_outlined,
        onPressed: () => _navigateToScreen(context, PatientAssignmentScreen()),
        width: buttonWidth,
        height: buttonHeight,
      ),
      _AdminButton(
        title: 'All Patients',
        icon: Icons.people_outline,
        onPressed: () => _navigateToScreen(context, const PatientListScreen()),
        width: buttonWidth,
        height: buttonHeight,
      ),
      _AdminButton(
        title: 'Register Doctor',
        icon: Icons.person_add_outlined,
        onPressed: () =>
            _navigateToScreen(context, const DoctorRegisterScreen()),
        width: buttonWidth,
        height: buttonHeight,
      ),
      _AdminButton(
        title: 'Register Nurse',
        icon: Icons.local_hospital_outlined,
        onPressed: () => _navigateToScreen(context, NurseRegisterScreen()),
        width: buttonWidth,
        height: buttonHeight,
      ),
      _AdminButton(
        title: 'Nurse Attendance',
        icon: Icons.schedule_outlined,
        onPressed: () => _navigateToScreen(context, GetAllAttendance()),
        width: buttonWidth,
        height: buttonHeight,
      ),
    ];

    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: buttons,
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}

class _AdminButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onPressed;
  final double width;
  final double height;

  const _AdminButton({
    Key? key,
    required this.title,
    required this.icon,
    required this.onPressed,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: HospitalTheme.primaryLight,
          foregroundColor: HospitalTheme.textOnPrimary,
          elevation: 2,
          shadowColor: HospitalTheme.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: HospitalTheme.radiusSmall,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ).copyWith(
          overlayColor: MaterialStateProperty.all(
            HospitalTheme.primary.withOpacity(0.1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: HospitalTheme.textOnPrimary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
