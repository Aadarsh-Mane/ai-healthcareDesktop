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

class DoctorMainScreen extends StatelessWidget {
  const DoctorMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DoctorHomeScreen(),
    );
  }
}

class DoctorHomeScreen extends ConsumerStatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  ConsumerState<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends ConsumerState<DoctorHomeScreen>
    with TickerProviderStateMixin {
  static const List<Map<String, dynamic>> doctorCards = [
    {
      'title': 'Assigned Patients',
      'subtitle': 'Manage patients',
      'description':
          'View and manage your assigned patients, track their progress',
      'count': '24',
      'imagePath': 'assets/images/assigned.png',
      'screen': AssignedPatientsScreen(),
      'color': HospitalTheme.medical,
      'icon': Icons.person_pin_circle_outlined,
      'gradient': [Color(0xFF2196F3), Color(0xFF1976D2)],
      'category': 'patient_care',
      'priority': 'high',
      'status': 'active',
      'isNew': true,
    },
    {
      'title': 'Laboratory Results',
      'subtitle': 'Review labs',
      'description': 'Check pending lab results, approve reports',
      'count': '8',
      'imagePath': 'assets/images/labs1.png',
      'screen': LaboratoryAssignmentsScreen(),
      'color': HospitalTheme.laboratory,
      'icon': Icons.science_outlined,
      'gradient': [const Color(0xFF667eea), const Color(0xFF764ba2)],
      'category': 'diagnostics',
      'priority': 'medium',
      'status': 'pending',
      'isNew': false,
    },
    {
      'title': 'Patient Database',
      'subtitle': 'Browse records',
      'description': 'Access complete patient database, search records',
      'count': '150+',
      'imagePath': 'assets/images/ask.png',
      'screen': PatientListScreen(),
      'color': HospitalTheme.pharmacy,
      'icon': Icons.people_alt_outlined,
      'gradient': [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      'category': 'records',
      'priority': 'low',
      'status': 'active',
      'isNew': false,
    },
    {
      'title': 'Main Dashboard',
      'subtitle': 'System overview',
      'description': 'Access main hospital dashboard with statistics',
      'count': '∞',
      'imagePath': 'assets/images/lists.png',
      'screen': HomePage(),
      'color': HospitalTheme.primary,
      'icon': Icons.dashboard_outlined,
      'gradient': [const Color(0xFFfb2b69), const Color(0xFFff5858)],
      'category': 'overview',
      'priority': 'medium',
      'status': 'active',
      'isNew': true,
    },
  ];

  // Animation controllers
  late AnimationController _floatingController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _refreshController;
  late AnimationController _particleController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _floatingAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _refreshAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // Fetch doctor profile
    Future.microtask(() {
      ref.read(doctorProfileProvider.notifier).getDoctorProfile();
    });
  }

  void _initializeAnimations() {
    // Floating animation for background elements
    _floatingController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    // Slide animation for entrance
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Refresh animation
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // Pulse animation for status indicators
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Initialize animation values
    _floatingAnimation = Tween<double>(
      begin: -8,
      end: 8,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
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
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _refreshController,
      curve: Curves.elasticOut,
    ));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_particleController);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _refreshController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _refreshProfile() async {
    try {
      HapticFeedback.lightImpact();
      await ref.read(doctorProfileProvider.notifier).getDoctorProfile();

      _refreshController.forward().then((_) {
        _refreshController.reverse();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.check_circle,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                const Text('Profile refreshed successfully'),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: HospitalTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.error_outline,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Text('Failed to refresh: ${e.toString()}'),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: HospitalTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorProfile = ref.watch(doctorProfileProvider);
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 1200;
    final isTablet = screenSize.width > 768 && screenSize.width <= 1200;
    final isMobile = screenSize.width <= 768;

    // Listen for profile updates
    ref.listen(doctorProfileProvider, (previous, next) {
      if (previous != null && next != null && previous != next) {
        _refreshController.forward().then((_) {
          _refreshController.reverse();
        });
      }
    });

    return Scaffold(
      backgroundColor: HospitalTheme.background,
      body: Stack(
        children: [
          // Animated background with particles
          _buildEnhancedBackground(),

          // Main content with responsive layout
          _buildMainContent(
              doctorProfile, screenSize, isWideScreen, isTablet, isMobile),
        ],
      ),
      floatingActionButton: _buildEnhancedFAB(),
    );
  }

  Widget _buildEnhancedBackground() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              HospitalTheme.background,
              HospitalTheme.surfaceLight.withOpacity(0.3),
              HospitalTheme.primaryLight.withOpacity(0.1),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: AnimatedBuilder(
          animation: _particleAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: _EnhancedParticlesPainter(_particleAnimation.value),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(doctorProfile, Size screenSize, bool isWideScreen,
      bool isTablet, bool isMobile) {
    return Column(
      children: [
        _buildEnhancedAppBar(isWideScreen),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWideScreen
                  ? 32
                  : isTablet
                      ? 24
                      : 16,
              vertical: 16,
            ),
            child: Column(
              children: [
                // Compact Profile section with animation
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
                              ? _buildCompactNotLoggedInUI(isWideScreen)
                              : _buildCompactDoctorProfileCard(
                                  doctorProfile, isWideScreen),
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: isWideScreen ? 20 : 16),

                // Enhanced section header
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildEnhancedSectionHeader('Quick Access Dashboard'),
                ),

                const SizedBox(height: 16),

                // Navigation grid with enhanced promotional cards
                Expanded(
                  child: _buildColorfulPromoSection(
                      isWideScreen, isTablet, isMobile),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorfulPromoSection(
      bool isWideScreen, bool isTablet, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section with enhanced gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF005F9E),
                  Color(0xFF0288D1),
                  Color(0xFF00B8D4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF005F9E).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Discover Doctor Portal Features',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'We Provide You With The Best Medical Tools',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEABF56),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'DOCTOR',
                    style: TextStyle(
                      color: Color(0xFF5D4037),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Promotional cards grid
          Expanded(
            child: _buildPromoCardsGrid(isWideScreen, isTablet, isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCardsGrid(bool isWideScreen, bool isTablet, bool isMobile) {
    final crossAxisCount = isWideScreen
        ? 4
        : isTablet
            ? 3
            : 2;
    final aspectRatio = isWideScreen
        ? 1.1
        : isTablet
            ? 1.0
            : 0.95;

    return GridView.builder(
      shrinkWrap: true,
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
                child: _buildColorfulPromoCard(
                  card['title'],
                  card['subtitle'],
                  card['description'],
                  card['icon'],
                  card['gradient'],
                  card['isNew'],
                  card['count'],
                  () {
                    HapticFeedback.selectionClick();
                    // Always navigate directly to the intended screen
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            card['screen'],
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1.0, 0.0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            )),
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 400),
                      ),
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

  Widget _buildColorfulPromoCard(
    String title,
    String subtitle,
    String description,
    IconData icon,
    List<Color> gradientColors,
    bool isNew,
    String count,
    VoidCallback onTap,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Background decorative elements
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -5,
                    top: -5,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),

                  // Main content
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top row with icon and badges
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  icon,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              Column(
                                children: [
                                  if (isNew)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEABF56),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        'NEW',
                                        style: TextStyle(
                                          color: Color(0xFF5D4037),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      count,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Content area with overflow protection
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Title
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),

                                // Subtitle
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w600,
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 8),

                                // Description
                                Flexible(
                                  child: Text(
                                    description,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.8),
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Bottom action area
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.touch_app_rounded,
                                  size: 12,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Tap to explore',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w600,
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
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedAppBar(bool isWideScreen) {
    return Container(
      height: isWideScreen ? 120 : 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HospitalTheme.primary,
            HospitalTheme.primaryDark,
            HospitalTheme.secondary,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: HospitalTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Glassmorphic overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ),

          // Floating particles overlay
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _AppBarParticlesPainter(_particleAnimation.value),
                );
              },
            ),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWideScreen ? 32 : 24,
                vertical: 12,
              ),
              child: Row(
                children: [
                  // Back button with enhanced styling
                  _buildEnhancedBackButton(),
                  const SizedBox(width: 16),

                  // Hospital icon with rotation animation
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1500),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.rotate(
                        angle: value * 2 * math.pi,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
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

                  // Title section with enhanced styling
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              AppStrings.hospitalName,
                              style: TextStyle(
                                fontSize: isWideScreen ? 20 : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: HospitalTheme.success
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: HospitalTheme.success
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 5,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            color: HospitalTheme.success,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Online',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              "Doctor Portal",
                              style: TextStyle(
                                fontSize: isWideScreen ? 14 : 12,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'v2.0',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Enhanced inspirational badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Icon(
                                Icons.favorite,
                                size: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Healing with compassion",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.95),
                            fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildEnhancedBackButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  HomePage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
            (route) => false,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactNotLoggedInUI(bool isWideScreen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            HospitalTheme.surfaceLight.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: HospitalTheme.border.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: HospitalTheme.warning.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  HospitalTheme.warning.withOpacity(0.15),
                  HospitalTheme.warning.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_outlined,
              size: 32,
              color: HospitalTheme.warning,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Authentication Required",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Please login to access the doctor portal",
                  style: TextStyle(
                    fontSize: 13,
                    color: HospitalTheme.textMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _EnhancedHoverButton(
            label: "Login",
            icon: Icons.login_rounded,
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      LoginScreen1(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDoctorProfileCard(doctorProfile, bool isWideScreen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            HospitalTheme.surfaceLight.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: HospitalTheme.border.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: HospitalTheme.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Compact Profile Avatar
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1200),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        HospitalTheme.primary.withOpacity(0.2),
                        HospitalTheme.secondary.withOpacity(0.2),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: HospitalTheme.primary.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(3),
                  child: const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 25,
                      backgroundImage: AssetImage('assets/images/doctor14.png'),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 16),

          // Compact Profile Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Welcome back,",
                      style: TextStyle(
                        fontSize: 12,
                        color: HospitalTheme.textMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            HospitalTheme.success.withOpacity(0.2),
                            HospitalTheme.success.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: HospitalTheme.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "Dr. ${doctorProfile.doctorName ?? 'Doctor'}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),

          // Compact Action Buttons
          Wrap(
            spacing: 8,
            children: [
              _EnhancedHoverButton(
                icon: Icons.refresh_rounded,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _refreshProfile();
                },
                isCompact: true,
                color: HospitalTheme.secondary,
              ),
              _EnhancedHoverButton(
                icon: Icons.edit_outlined,
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          DoctorProfileScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          )),
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 400),
                    ),
                  );
                  _refreshProfile();
                },
                isCompact: true,
                color: HospitalTheme.primary,
              ),
              _EnhancedHoverButton(
                icon: Icons.logout_rounded,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showEnhancedLogoutDialog();
                },
                isCompact: true,
                color: HospitalTheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEnhancedLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  HospitalTheme.surfaceLight.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        HospitalTheme.error.withOpacity(0.15),
                        HospitalTheme.error.withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: HospitalTheme.error,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Confirm Logout",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Are you sure you want to logout from the doctor portal?",
                  style: TextStyle(
                    fontSize: 14,
                    color: HospitalTheme.textMedium,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: HospitalTheme.textMedium,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ref
                              .read(doctorProfileProvider.notifier)
                              .clearProfile();
                          final authController =
                              ref.read(authControllerProvider.notifier);
                          authController.logout();
                          HapticFeedback.lightImpact();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginScreen1()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HospitalTheme.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          "Logout",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedSectionHeader(String title) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset((1 - value) * 50, 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    HospitalTheme.primary.withOpacity(0.08),
                    HospitalTheme.secondary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: HospitalTheme.primary.withOpacity(0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          HospitalTheme.primary,
                          HospitalTheme.secondary
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.dashboard_customize_outlined,
                    color: HospitalTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: HospitalTheme.textDark,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          HospitalTheme.success.withOpacity(0.2),
                          HospitalTheme.success.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${doctorCards.length} modules',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: HospitalTheme.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedFAB() {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value * 0.5),
          child: FloatingActionButton.extended(
            onPressed: () {
              HapticFeedback.lightImpact();
              _refreshProfile();
            },
            backgroundColor: HospitalTheme.secondary,
            foregroundColor: Colors.white,
            elevation: 8,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'Refresh',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            tooltip: 'Refresh doctor profile and data',
          ),
        );
      },
    );
  }
}

// Enhanced Hover Button Widget with hover effects
class _EnhancedHoverButton extends StatefulWidget {
  final String? label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isCompact;
  final Color? color;

  const _EnhancedHoverButton({
    this.label,
    required this.icon,
    required this.onPressed,
    this.isCompact = false,
    this.color,
  });

  @override
  State<_EnhancedHoverButton> createState() => _EnhancedHoverButtonState();
}

class _EnhancedHoverButtonState extends State<_EnhancedHoverButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

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
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 6.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? HospitalTheme.primary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        if (!_isPressed) {
          _animationController.reverse();
        }
      },
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _animationController.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          if (!_isHovered) {
            _animationController.reverse();
          }
          widget.onPressed();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          if (!_isHovered) {
            _animationController.reverse();
          }
        },
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: widget.isCompact
                    ? const EdgeInsets.all(8)
                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      buttonColor,
                      buttonColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(widget.isCompact ? 8 : 12),
                  boxShadow: [
                    BoxShadow(
                      color: buttonColor.withOpacity(0.3),
                      blurRadius: _elevationAnimation.value * 2,
                      offset: Offset(0, _elevationAnimation.value),
                    ),
                  ],
                ),
                child: widget.isCompact
                    ? Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 16,
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 16,
                          ),
                          if (widget.label != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              widget.label!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Enhanced Particles Painter
class _EnhancedParticlesPainter extends CustomPainter {
  final double animationValue;

  _EnhancedParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Create multiple layers of particles with different colors and sizes
    final colors = [
      HospitalTheme.primary.withOpacity(0.03),
      HospitalTheme.secondary.withOpacity(0.02),
      HospitalTheme.medical.withOpacity(0.025),
      HospitalTheme.pharmacy.withOpacity(0.02),
    ];

    for (int layer = 0; layer < colors.length; layer++) {
      paint.color = colors[layer];

      for (int i = 0; i < 20; i++) {
        final dx = (size.width / 20) * i +
            (animationValue * (30 + layer * 10)) % size.width;
        final dy = (size.height / 10) * (i % 10) +
            (math.sin(animationValue * (1.2 + layer * 0.3) + i) * 20);

        final radius =
            (2 + layer) + (math.sin(animationValue + i + layer) * 1.5);
        canvas.drawCircle(Offset(dx, dy), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// App Bar Particles Painter
class _AppBarParticlesPainter extends CustomPainter {
  final double animationValue;

  _AppBarParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 12; i++) {
      final dx = (size.width / 12) * i + (animationValue * 25) % size.width;
      final dy = size.height * 0.3 +
          (math.sin(animationValue * 1.5 + i) * size.height * 0.4);

      final radius = 1 + (math.sin(animationValue + i) * 1);
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
