import 'package:doctordesktop/Check.dart';
import 'package:doctordesktop/Doctor/AssignedLabScreen.dart';
import 'package:doctordesktop/Doctor/AssignedPatientScreen.dart';
import 'package:doctordesktop/Doctor/DoctorProfile.dart';
import 'package:doctordesktop/LogoutScreen.dart';
import 'package:doctordesktop/Patient/fetchPatient.dart';
import 'package:doctordesktop/authProvider/auth_provider.dart';
import 'package:doctordesktop/constants/Assets.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/main.dart';
import 'package:doctordesktop/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

class DoctorMainScreen extends StatefulWidget {
  @override
  _DoctorMainScreenState createState() => _DoctorMainScreenState();
}

class _DoctorMainScreenState extends State<DoctorMainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DoctorHomeScreen(),
    );
  }
}

class DoctorHomeScreen extends ConsumerStatefulWidget {
  @override
  _DoctorHomeScreenState createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends ConsumerState<DoctorHomeScreen>
    with TickerProviderStateMixin {
  static const List<Map<String, dynamic>> doctorCards = [
    {
      'title': 'Assigned Patients',
      'subtitle': 'Manage assignments',
      'imagePath': 'assets/images/assigned.png',
      'screen': AssignedPatientsScreen(),
      'color': HospitalTheme.medical,
      'icon': Icons.person_pin_circle_outlined,
      'gradient': [Color(0xFF2196F3), Color(0xFF1976D2)],
    },
    {
      'title': 'Assigned Labs',
      'subtitle': 'Review lab results',
      'imagePath': 'assets/images/labs1.png',
      'screen': LaboratoryAssignmentsScreen(),
      'color': HospitalTheme.laboratory,
      'icon': Icons.science_outlined,
      'gradient': [Color(0xFF7E57C2), Color(0xFF673AB7)],
    },
    {
      'title': 'Patients',
      'subtitle': 'Browse records',
      'imagePath': 'assets/images/ask.png',
      'screen': PatientListScreen(),
      'color': HospitalTheme.pharmacy,
      'icon': Icons.people_alt_outlined,
      'gradient': [Color(0xFF26A69A), Color(0xFF00796B)],
    },
    {
      'title': 'Dashboard',
      'subtitle': 'Main dashboard',
      'imagePath': 'assets/images/lists.png',
      'screen': HomePage(),
      'color': HospitalTheme.primary,
      'icon': Icons.dashboard_outlined,
      'gradient': [Color(0xFF005F9E), Color(0xFF00477A)],
    },
  ];

  late AnimationController _floatingController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _refreshController;
  late Animation<double> _floatingAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _refreshAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // Fetch doctor profile using Riverpod
    Future.microtask(() {
      ref.read(doctorProfileProvider.notifier).getDoctorProfile();
    });
  }

  void _initializeAnimations() {
    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _floatingAnimation = Tween<double>(
      begin: -6,
      end: 6,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _refreshAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _refreshController,
      curve: Curves.elasticOut,
    ));

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  // Method to refresh profile with visual feedback
  Future<void> _refreshProfile() async {
    try {
      await ref.read(doctorProfileProvider.notifier).getDoctorProfile();

      // Trigger refresh animation
      _refreshController.forward().then((_) {
        _refreshController.reverse();
      });

      // Show success feedback
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Row(
        //       children: [
        //         Icon(Icons.check_circle, color: Colors.white, size: 20),
        //         const SizedBox(width: 12),
        //         // const Text('Profile refreshed successfully'),
        //       ],
        //     ),
        //     duration: const Duration(seconds: 2),
        //     backgroundColor: HospitalTheme.success,
        //     behavior: SnackBarBehavior.floating,
        //     shape: RoundedRectangleBorder(
        //       borderRadius: BorderRadius.circular(10),
        //     ),
        //     margin: const EdgeInsets.all(16),
        //   ),
        // );
      }
    } catch (e) {
      // Show error feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('Failed to refresh profile: ${e.toString()}'),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: HospitalTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch doctor profile - automatically rebuilds when data changes
    final doctorProfile = ref.watch(doctorProfileProvider);
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 1200;
    final isTablet = screenSize.width > 768 && screenSize.width <= 1200;

    // Listen for profile updates and show subtle notification
    ref.listen(doctorProfileProvider, (previous, next) {
      if (previous != null && next != null && previous != next) {
        // Trigger refresh animation when profile updates
        _refreshController.forward().then((_) {
          _refreshController.reverse();
        });

        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Row(
        //       children: [
        //         Icon(Icons.refresh, color: Colors.white, size: 20),
        //         const SizedBox(width: 12),
        //         const Text('Profile updated successfully'),
        //       ],
        //     ),
        //     duration: const Duration(seconds: 2),
        //     backgroundColor: HospitalTheme.success,
        //     behavior: SnackBarBehavior.floating,
        //     shape: RoundedRectangleBorder(
        //       borderRadius: BorderRadius.circular(10),
        //     ),
        //     margin: const EdgeInsets.all(16),
        //   ),
        // );
      }
    });

    return Scaffold(
      backgroundColor: HospitalTheme.background,
      body: Stack(
        children: [
          // Subtle animated background
          _buildSubtleBackground(),

          // Main content
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  HospitalTheme.background,
                  HospitalTheme.surfaceLight,
                ],
                stops: [0.0, 1.0],
              ),
            ),
            child: CustomScrollView(
              slivers: [
                _buildCompactAppBar(context, isWideScreen),
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWideScreen
                        ? 32
                        : isTablet
                            ? 24
                            : 20,
                    vertical: 20,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Profile Section with Refresh Animation
                      AnimatedBuilder(
                        animation: _refreshAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _refreshAnimation.value,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: doctorProfile == null
                                    ? _buildCompactNotLoggedInUI(
                                        context, isWideScreen)
                                    : _buildCompactDoctorProfile(
                                        context, doctorProfile, isWideScreen),
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: isWideScreen ? 32 : 24),

                      // Section Header
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildSectionHeader('Quick Access'),
                      ),

                      const SizedBox(height: 20),

                      // Navigation Grid
                      _buildCompactNavigationGrid(isWideScreen, isTablet),

                      const SizedBox(height: 32),
                      _buildCompactFooter(),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtleBackground() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _floatingController,
        builder: (context, child) {
          return CustomPaint(
            painter: _SubtleParticlesPainter(_floatingController.value),
          );
        },
      ),
    );
  }

  Widget _buildCompactAppBar(BuildContext context, bool isWideScreen) {
    return SliverAppBar(
      expandedHeight: isWideScreen ? 120 : 100,
      floating: false,
      automaticallyImplyLeading: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: AnimatedBuilder(
          animation: _floatingAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatingAnimation.value * 0.2),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      HospitalTheme.primary,
                      HospitalTheme.primaryDark,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: HospitalTheme.primary.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Subtle glassmorphic overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.08),
                              Colors.white.withOpacity(0.03),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Content
                    SafeArea(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWideScreen ? 32 : 24,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            // Custom Back Navigation to HomePage
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                          HomePage(),
                                      transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) {
                                        return SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(-1.0, 0.0),
                                            end: Offset.zero,
                                          ).animate(CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOut,
                                          )),
                                          child: child,
                                        );
                                      },
                                      transitionDuration:
                                          const Duration(milliseconds: 300),
                                    ),
                                    (route) => false,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Hospital icon
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1200),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Transform.rotate(
                                  angle: value * 2 * math.pi,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.local_hospital_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(width: 16),

                            // Title section
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "${AppStrings.hospitalName}",
                                    style: TextStyle(
                                      fontSize: isWideScreen ? 20 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Doctor Portal",
                                    style: TextStyle(
                                      fontSize: isWideScreen ? 14 : 13,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Inspirational badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.favorite,
                                    size: 14,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Healing with compassion",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactNotLoggedInUI(BuildContext context, bool isWideScreen) {
    return Container(
      padding: EdgeInsets.all(isWideScreen ? 32 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: HospitalTheme.border.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: HospitalTheme.primary.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HospitalTheme.warning.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_outlined,
              size: isWideScreen ? 40 : 32,
              color: HospitalTheme.warning,
            ),
          ),
          SizedBox(height: isWideScreen ? 20 : 16),
          Text(
            "Authentication Required",
            style: TextStyle(
              fontSize: isWideScreen ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: HospitalTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Please login to access the doctor portal",
            style: TextStyle(
              fontSize: 14,
              color: HospitalTheme.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isWideScreen ? 24 : 20),
          _CompactGradientButton(
            label: "Login Now",
            icon: Icons.login_rounded,
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen1()),
              );
            },
            width: isWideScreen ? 160 : 140,
            height: 44,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDoctorProfile(
      BuildContext context, doctorProfile, bool isWideScreen) {
    return Container(
      padding: EdgeInsets.all(isWideScreen ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: HospitalTheme.border.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: HospitalTheme.primary.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isWideScreen
          ? Row(
              children: [
                _buildCompactProfileAvatar(isWideScreen),
                const SizedBox(width: 24),
                Expanded(
                    child:
                        _buildCompactProfileInfo(doctorProfile, isWideScreen)),
                const SizedBox(width: 20),
                _buildCompactActionButtons(),
              ],
            )
          : Column(
              children: [
                _buildCompactProfileAvatar(isWideScreen),
                const SizedBox(height: 20),
                _buildCompactProfileInfo(doctorProfile, isWideScreen),
                const SizedBox(height: 20),
                _buildCompactActionButtons(),
              ],
            ),
    );
  }

  Widget _buildCompactProfileAvatar(bool isWideScreen) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  HospitalTheme.primary.withOpacity(0.1),
                  HospitalTheme.secondary.withOpacity(0.1),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: HospitalTheme.primary.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: CircleAvatar(
              radius: isWideScreen ? 36 : 30,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: isWideScreen ? 33 : 27,
                backgroundImage: const AssetImage('assets/images/doctor14.png'),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactProfileInfo(doctorProfile, bool isWideScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome back,",
          style: TextStyle(
            fontSize: 14,
            color: HospitalTheme.textMedium,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "Dr. ${doctorProfile.doctorName ?? 'Doctor'}",
          style: TextStyle(
            fontSize: isWideScreen ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        const SizedBox(height: 16),
        ...[
          (
            Icons.email_outlined,
            "Email",
            doctorProfile.email ?? 'Not provided'
          ),
          // (
          //   Icons.medical_services_outlined,
          //   "Specialization",
          //   doctorProfile.specialization ?? 'General Medicine'
          // ),
          // (
          //   Icons.phone_outlined,
          //   "Phone",
          //   doctorProfile.phone ?? 'Not provided'
          // ),
        ]
            .map((info) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildCompactInfoRow(
                      info.$1, info.$2, info.$3, isWideScreen),
                ))
            .toList(),
      ],
    );
  }

  Widget _buildCompactInfoRow(
      IconData icon, String label, String? value, bool isWideScreen) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: HospitalTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 14,
            color: HospitalTheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: HospitalTheme.textMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value ?? 'Not available',
                style: TextStyle(
                  fontSize: 12,
                  color: HospitalTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Refresh Profile Button
        _CompactButton(
          icon: Icons.refresh_rounded,
          label: "Refresh",
          color: HospitalTheme.secondary,
          onPressed: () {
            HapticFeedback.lightImpact();
            _refreshProfile();
          },
        ),
        const SizedBox(width: 12),
        // Update Profile Button
        _CompactButton(
          icon: Icons.edit_outlined,
          label: "Update Profile",
          color: HospitalTheme.primary,
          onPressed: () async {
            HapticFeedback.lightImpact();

            // Navigate to profile screen and wait for return
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DoctorProfileScreen(),
              ),
            );

            // Automatically refresh profile when returning
            _refreshProfile();
          },
        ),
        const SizedBox(width: 12),
        // Logout Button
        _CompactButton(
          icon: Icons.logout_rounded,
          label: "Logout",
          color: HospitalTheme.error,
          onPressed: () {
            HapticFeedback.lightImpact();
            _showLogoutConfirmationDialog();
          },
        ),
      ],
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: HospitalTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: HospitalTheme.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Confirm Logout",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            "Are you sure you want to logout from the doctor portal?",
            style: TextStyle(
              fontSize: 14,
              color: HospitalTheme.textMedium,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: HospitalTheme.textMedium,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                "Cancel",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();

                // Clear profile data on logout using Riverpod
                ref.read(doctorProfileProvider.notifier).clearProfile();
                final authController =
                    ref.read(authControllerProvider.notifier);
                authController.logout();

                HapticFeedback.lightImpact();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen1()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: HospitalTheme.error,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Logout",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset((1 - value) * 30, 0),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: HospitalTheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactNavigationGrid(bool isWideScreen, bool isTablet) {
    final crossAxisCount = isWideScreen
        ? 4
        : isTablet
            ? 3
            : 2;
    final aspectRatio = 1.4;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: aspectRatio,
      ),
      itemCount: doctorCards.length,
      itemBuilder: (context, index) {
        final card = doctorCards[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 800 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, (1 - value) * 30),
              child: Opacity(
                opacity: value,
                child: _CompactNavCard(
                  title: card['title'],
                  subtitle: card['subtitle'],
                  color: card['color'],
                  icon: card['icon'],
                  gradient: card['gradient'],
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => card['screen']),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCompactFooter() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  HospitalTheme.primaryDark,
                  HospitalTheme.primary,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: HospitalTheme.primary.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.developer_mode_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Hospital Management System v2.0",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "${AppStrings.hospitalName} © 2025",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "For support: support@hospital.com | +1 (800) 123-4567",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Rest of the widget classes remain the same...
// (The _CompactNavCard, _CompactGradientButton, _CompactButton, and _SubtleParticlesPainter classes)

// Compact Navigation Card
class _CompactNavCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _CompactNavCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_CompactNavCard> createState() => _CompactNavCardState();
}

class _CompactNavCardState extends State<_CompactNavCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                decoration: BoxDecoration(
                  color:
                      _hovered ? widget.color.withOpacity(0.04) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _hovered
                        ? widget.color.withOpacity(0.2)
                        : HospitalTheme.border.withOpacity(0.3),
                    width: _hovered ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _hovered
                          ? widget.color.withOpacity(0.1)
                          : Colors.black.withOpacity(0.04),
                      blurRadius: _hovered ? 15 : 8,
                      offset: Offset(0, _hovered ? 6 : 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: _hovered
                              ? LinearGradient(colors: widget.gradient)
                              : LinearGradient(colors: [
                                  widget.color.withOpacity(0.1),
                                  widget.color.withOpacity(0.05),
                                ]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.icon,
                          size: 24,
                          color: _hovered ? Colors.white : widget.color,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color:
                              _hovered ? widget.color : HospitalTheme.textDark,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: HospitalTheme.textMedium,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        transform: Matrix4.translationValues(
                          _hovered ? 3 : 0,
                          0,
                          0,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: widget.color.withOpacity(_hovered ? 1.0 : 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Compact Gradient Button
class _CompactGradientButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final double width;
  final double height;

  const _CompactGradientButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.width,
    required this.height,
  });

  @override
  State<_CompactGradientButton> createState() => _CompactGradientButtonState();
}

class _CompactGradientButtonState extends State<_CompactGradientButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _animationController.forward();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        _animationController.reverse();
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [HospitalTheme.primary, HospitalTheme.primaryDark],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: HospitalTheme.primary.withOpacity(0.3),
                    blurRadius: _pressed ? 8 : 12,
                    offset: Offset(0, _pressed ? 2 : 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Compact Button
class _CompactButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _CompactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  State<_CompactButton> createState() => _CompactButtonState();
}

class _CompactButtonState extends State<_CompactButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: ElevatedButton.icon(
              icon: Icon(widget.icon, size: 16),
              label: Text(widget.label),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.color,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: _hovered ? 4 : 2,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              onPressed: widget.onPressed,
            ),
          );
        },
      ),
    );
  }
}

// Subtle Particles Painter
class _SubtleParticlesPainter extends CustomPainter {
  final double animationValue;

  _SubtleParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HospitalTheme.primary.withOpacity(0.02)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 15; i++) {
      final dx = (size.width / 15) * i + (animationValue * 20) % size.width;
      final dy = (size.height / 8) * (i % 8) +
          (math.sin(animationValue * 1.5 + i) * 15);

      final radius = 1.5 + (math.sin(animationValue + i) * 1);
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
