import 'package:doctordesktop/constants/Assets.dart';
import 'package:doctordesktop/pharmacy/pharmaTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BookOpenAnimation extends StatefulWidget {
  final Widget frontPage;
  final Widget contentPage;

  const BookOpenAnimation({
    Key? key,
    required this.frontPage,
    required this.contentPage,
  }) : super(key: key);

  @override
  State<BookOpenAnimation> createState() => _BookOpenAnimationState();
}

class _BookOpenAnimationState extends State<BookOpenAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pageRotation;
  late Animation<double> _openingAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: PharmaTheme.transitionMedium,
      vsync: this,
    );

    _pageRotation = Tween<double>(
      begin: 0.0,
      end: 180.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _openingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.addStatusListener(_updateStatus);

    // Add keyboard shortcut for toggling the card
    ServicesBinding.instance.keyboard.addHandler(_handleKeyPress);
  }

  @override
  void dispose() {
    _animationController.removeStatusListener(_updateStatus);
    _animationController.dispose();
    ServicesBinding.instance.keyboard.removeHandler(_handleKeyPress);
    super.dispose();
  }

  bool _handleKeyPress(KeyEvent event) {
    // Toggle card on Ctrl+Space or Cmd+Space
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space &&
          (HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed)) {
        _toggleCard();
        return true;
      }
    }
    return false;
  }

  void _updateStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      setState(() {
        _isOpen = _animationController.value > 0.5;
      });
    }
  }

  void _toggleCard() {
    if (_animationController.isDismissed) {
      _animationController.forward();
    } else if (_animationController.isCompleted) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return GestureDetector(
          onTap: _toggleCard,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Stack(
              children: [
                // Back page (shows when opened)
                if (_openingAnimation.value > 0.5)
                  Opacity(
                    opacity: (_openingAnimation.value - 0.5) / 0.5,
                    child: widget.contentPage,
                  ),

                // Front page with logo (rotates to reveal content)
                Transform(
                  alignment: Alignment.centerRight,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // Perspective
                    ..rotateY(_pageRotation.value * (3.14159 / 180)),
                  child: _pageRotation.value <= 90
                      ? widget.frontPage
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget buildLogoFrontPage(
    Color cardColor, Color primaryColor, Color textColor, Color shadowColor) {
  // Determine system status
  bool isSystemOnline = true;
  String statusText = isSystemOnline ? "Online" : "Offline";
  Color statusColor =
      isSystemOnline ? const Color(0xFF4CAF50) : const Color(0xFFF44336);

  // Premium gold gradient colors
  final List<Color> goldGradientColors = const [
    Color(0xFFF9DB9D), // Lighter gold
    Color(0xFFEABF56), // Medium gold
    Color(0xFFEACF5E), // Rich gold
    Color(0xFFD3A73B), // Deep gold
  ];

  // Background gradient with subtle gold accent
  final List<Color> backgroundGradientColors = [
    Colors.white,
    Colors.white,
  ];

  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: backgroundGradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        // Gold border
        color: const Color(0xFFEABF56).withOpacity(0.3),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFFEABF56).withOpacity(0.15),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        // Adjust sizes based on available space
        final bool isSmallSpace = constraints.maxHeight < 450;
        final double logoSize = isSmallSpace ? 100 : 130;
        final double titleFontSize = isSmallSpace ? 24 : 28;
        final double spacerHeight = isSmallSpace ? 8.0 : 16.0;

        final List<Widget> children = [
          // Premium golden banner at the top
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: goldGradientColors,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEABF56).withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.workspace_premium,
                    color: Color(0xFF5D4037), // Dark brown
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'PREMIUM',
                    style: TextStyle(
                      color: Color(0xFF5D4037), // Dark brown
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Logo with enhanced gold glow effect
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.97, end: 1.0),
            duration: const Duration(seconds: 3),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  height: logoSize,
                  width: logoSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      // Inner gold glow
                      BoxShadow(
                        color: const Color(0xFFEABF56).withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                      // Outer gold glow
                      BoxShadow(
                        color: const Color(0xFFEABF56).withOpacity(0.2 * value),
                        blurRadius: 25 * value,
                        spreadRadius: 2 * value,
                      ),
                      // Extra accent glow
                      BoxShadow(
                        color: PharmaTheme.primary.withOpacity(0.2),
                        blurRadius: 20 * value,
                        spreadRadius: 1 * value,
                      ),
                    ],
                    // Gold border around logo
                    border: Border.all(
                      color: const Color(0xFFEABF56).withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: child,
                ),
              );
            },
            child: Image.asset(
              '${AppImages.logo}',
              fit: BoxFit.contain,
            ),
          ),

          SizedBox(height: spacerHeight),

          // DocNeX.care text with gold gradient
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: const [
                Colors.black,
                Colors.black,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              'DocNex.care',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Overridden by shader
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    color:
                        const Color(0xFF5D4037).withOpacity(0.3), // Dark shadow
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: spacerHeight - 4),
        ];

        // Premium badge with gold gradient
        if (!isSmallSpace) {
          children.add(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    primaryColor.withOpacity(0.9),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFFEABF56).withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified,
                    color: const Color(0xFFEABF56), // Gold icon
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Trusted Healthcare Partner',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
          children.add(SizedBox(height: spacerHeight - 4));
        }

        // Enhanced tagline with gold underline
        children.add(
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'A system that never sleeps, 24x7 available',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallSpace ? 14 : 16,
                    fontStyle: FontStyle.italic,
                    color: textColor.withOpacity(0.9),
                    height: 1.2,
                    letterSpacing: 0.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Gold underline
              Container(
                width: isSmallSpace ? 120 : 160,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFFEABF56).withOpacity(0.5),
                      const Color(0xFFEABF56).withOpacity(0.8),
                      const Color(0xFFEABF56).withOpacity(0.5),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ],
          ),
        );

        children.add(SizedBox(height: spacerHeight));

        // Enhanced system status indicator with gold accents
        children.add(
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: 15, vertical: isSmallSpace ? 6 : 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusColor.withOpacity(0.7),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Improved pulsating dot animation
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSystemOnline
                              ? const Color(0xFFEABF56).withOpacity(0.5)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                    ),
                    if (isSystemOnline)
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(seconds: 1),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return Container(
                            width: 12 + (8 * value),
                            height: 12 + (8 * value),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: statusColor.withOpacity(1 - value),
                                width: 1.5,
                              ),
                            ),
                          );
                        },
                        child: Container(),
                      ),
                    if (isSystemOnline)
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(seconds: 1),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return Container(
                            width: 12 + (16 * value),
                            height: 12 + (16 * value),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: statusColor
                                    .withOpacity(0.7 - (0.7 * value)),
                                width: 1.5,
                              ),
                            ),
                          );
                        },
                        child: Container(),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'System $statusText',
                      style: TextStyle(
                        fontSize: isSmallSpace ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      isSystemOnline
                          ? 'All services operational'
                          : 'Service disruption',
                      style: TextStyle(
                        fontSize: isSmallSpace ? 10 : 11,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

        // Stats row with gold accents
        if (!isSmallSpace) {
          children.add(SizedBox(height: spacerHeight));
          children.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildGoldStatItem(Icons.schedule, '99.9%', 'Uptime',
                    primaryColor, textColor, isSmallSpace),
                _buildGoldStatItem(Icons.security, '256-bit', 'Encryption',
                    primaryColor, textColor, isSmallSpace),
                _buildGoldStatItem(Icons.cloud_done, 'Real-time', 'Backup',
                    primaryColor, textColor, isSmallSpace),
              ],
            ),
          );
        }

        // Flexible spacer
        children.add(
          Flexible(
            child: SizedBox(
              height: isSmallSpace ? 8 : 16,
            ),
          ),
        );

        // Version information with gold accent
        children.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user,
                size: isSmallSpace ? 12 : 14,
                color: const Color(0xFFEABF56).withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Text(
                isSmallSpace
                    ? 'v2.4.1 | HIPAA Compliant'
                    : 'Version 2.4.1 | HIPAA Compliant',
                style: TextStyle(
                  fontSize: isSmallSpace ? 10 : 12,
                  fontWeight: FontWeight.w500,
                  color: textColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
        );

        // Click hint
        children.add(const SizedBox(height: 8));
        children.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.touch_app,
                size: 14,
                color: Color(0xFFEABF56),
              ),
              const SizedBox(width: 4),
              Text(
                'Click to explore',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: textColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        );
      },
    ),
  );
}

Widget buildContentPage(
    Color cardColor, Color primaryColor, Color textColor, Color shadowColor) {
  return SingleChildScrollView(
    scrollDirection: Axis.vertical,
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: PharmaTheme.shadowMedium,
        border: Border.all(
          color: const Color(0xFFEABF56).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Adjust sizes based on available space
          final bool isSmallSpace = constraints.maxHeight < 450;
          final double titleFontSize = isSmallSpace ? 22 : 26;
          final double bodyFontSize = isSmallSpace ? 14 : 16;
          final double spacerHeight = isSmallSpace ? 8.0 : 16.0;

          // Calculate optimal panel size based on available width
          final double availableWidth =
              constraints.maxWidth - 48; // accounting for padding
          final double panelWidth =
              (availableWidth / 2) - 10; // 2 panels per row with spacing
          final double panelHeight = isSmallSpace ? 120 : 150;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book title with gold gradient
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: const [
                      Color(0xFF5D4037),
                      Color(0xFF8D6E63),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'DocNeX.care Premium',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Overridden by shader
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                SizedBox(height: spacerHeight),

                // Content
                // Content
                Text(
                  'Welcome to India\'s Premier Healthcare System',
                  style: TextStyle(
                    fontSize: bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: PharmaTheme.textPrimary,
                  ),
                ),

                SizedBox(height: spacerHeight / 2),

                Text(
                  'DocNeX.care is the first in India to provide 12 panels in HIMS healthcare. Our comprehensive solution streamlines patient management, prescription handling, and appointment scheduling with unmatched features.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: bodyFontSize - 2,
                    color: Color(0xFF8D6E63),
                    height: 1.5,
                  ),
                ),

                SizedBox(height: spacerHeight),

                // Panel grid section title
                Row(
                  children: [
                    Icon(
                      Icons.dashboard_customize,
                      color: primaryColor,
                      size: isSmallSpace ? 18 : 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Modules',
                      style: TextStyle(
                        fontSize: isSmallSpace ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: spacerHeight),

                // 12 panels in a grid (6 rows of 2 panels each)
                // First row
                _buildPanelRow(
                  context: context,
                  panelWidth: panelWidth,
                  panelHeight: panelHeight,
                  primaryColor: primaryColor,
                  textColor: textColor,
                  panel1: _PanelInfo(
                    icon: Icons.person_add,
                    title: 'Registration',
                    description: '',
                    isPremium: true,
                  ),
                  panel2: _PanelInfo(
                    icon: Icons.event_note,
                    title: 'Appointments',
                    description: '',
                    isPremium: true,
                  ),
                ),

                const SizedBox(height: 16),

                // Second row
                _buildPanelRow(
                  context: context,
                  panelWidth: panelWidth,
                  panelHeight: panelHeight,
                  primaryColor: primaryColor,
                  textColor: textColor,
                  panel1: _PanelInfo(
                    icon: Icons.medical_services,
                    title: 'Electronic Health Records',
                    description: '',
                    isPremium: true,
                  ),
                  panel2: _PanelInfo(
                    icon: Icons.healing,
                    title: 'Treatment Plans',
                    description: '',
                    isPremium: false,
                  ),
                ),

                const SizedBox(height: 16),

                // Third row
                _buildPanelRow(
                  context: context,
                  panelWidth: panelWidth,
                  panelHeight: panelHeight,
                  primaryColor: primaryColor,
                  textColor: textColor,
                  panel1: _PanelInfo(
                    icon: Icons.medication,
                    title: 'E-Prescriptions',
                    description: '',
                    isPremium: true,
                  ),
                  panel2: _PanelInfo(
                    icon: Icons.receipt_long,
                    title: 'Billing',
                    description: '',
                    isPremium: true,
                  ),
                ),

                const SizedBox(height: 16),

                // Fourth row
                _buildPanelRow(
                  context: context,
                  panelWidth: panelWidth,
                  panelHeight: panelHeight,
                  primaryColor: primaryColor,
                  textColor: textColor,
                  panel1: _PanelInfo(
                    icon: Icons.analytics,
                    title: 'Analytics',
                    description: '',
                    isPremium: true,
                  ),
                  panel2: _PanelInfo(
                    icon: Icons.inventory,
                    title: 'Inventory',
                    description: '',
                    isPremium: true,
                  ),
                ),

                const SizedBox(height: 16),

                // Fifth row
                _buildPanelRow(
                  context: context,
                  panelWidth: panelWidth,
                  panelHeight: panelHeight,
                  primaryColor: primaryColor,
                  textColor: textColor,
                  panel1: _PanelInfo(
                    icon: Icons.message,
                    title: 'Patient Portal',
                    description: '',
                    isPremium: true,
                  ),
                  panel2: _PanelInfo(
                    icon: Icons.description,
                    title: 'Documentation',
                    description: '',
                    isPremium: true,
                  ),
                ),

                const SizedBox(height: 16),

                // Sixth row
                _buildPanelRow(
                  context: context,
                  panelWidth: panelWidth,
                  panelHeight: panelHeight,
                  primaryColor: primaryColor,
                  textColor: textColor,
                  panel1: _PanelInfo(
                    icon: Icons.biotech,
                    title: 'Lab Integration',
                    description: 'Connect with laboratories',
                    isPremium: true,
                  ),
                  panel2: _PanelInfo(
                    icon: Icons.notifications,
                    title: 'Reminders',
                    description: 'Appointment and medication alerts',
                    isPremium: false,
                  ),
                ),

                SizedBox(height: spacerHeight * 1.5),

                // Call to action button
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle button press
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PharmaTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          PharmaTheme.radiusS,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Explore Premium Features',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

// Helper class to store panel information
class _PanelInfo {
  final IconData icon;
  final String title;
  final String description;
  final bool isPremium;

  const _PanelInfo({
    required this.icon,
    required this.title,
    required this.description,
    required this.isPremium,
  });
}

// Helper method to build a row with two panels
Widget _buildPanelRow({
  required BuildContext context,
  required double panelWidth,
  required double panelHeight,
  required Color primaryColor,
  required Color textColor,
  required _PanelInfo panel1,
  required _PanelInfo panel2,
}) {
  return Row(
    children: [
      _buildPanel(
        context: context,
        width: panelWidth,
        height: panelHeight,
        icon: panel1.icon,
        title: panel1.title,
        description: panel1.description,
        isPremium: panel1.isPremium,
        primaryColor: primaryColor,
        textColor: textColor,
      ),
      const SizedBox(width: 16),
      _buildPanel(
        context: context,
        width: panelWidth,
        height: panelHeight,
        icon: panel2.icon,
        title: panel2.title,
        description: panel2.description,
        isPremium: panel2.isPremium,
        primaryColor: primaryColor,
        textColor: textColor,
      ),
    ],
  );
}

// Helper method to build an individual panel
Widget _buildPanel({
  required BuildContext context,
  required double width,
  required double height,
  required IconData icon,
  required String title,
  required String description,
  required bool isPremium,
  required Color primaryColor,
  required Color textColor,
}) {
  // Premium gold gradient colors
  final List<Color> goldGradientColors = const [
    Color(0xFFF9DB9D), // Lighter gold
    Color(0xFFEABF56), // Medium gold
    Color(0xFFEACF5E), // Rich gold
    Color(0xFFD3A73B), // Deep gold
  ];

  return Stack(
    children: [
      // Main panel
      SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPremium
                  ? const Color(0xFFEABF56).withOpacity(0.5)
                  : PharmaTheme.border,
              width: isPremium ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isPremium
                    ? const Color(0xFFEABF56).withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPremium ? const Color(0xFFEABF56) : primaryColor,
                size: 24,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),

      // Premium tag
      if (isPremium)
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: goldGradientColors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEABF56).withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: Color(0xFF5D4037), // Dark brown
                  size: 10,
                ),
                SizedBox(width: 2),
                Text(
                  'PREMIUM',
                  style: TextStyle(
                    color: Color(0xFF5D4037), // Dark brown
                    fontWeight: FontWeight.w800,
                    fontSize: 8,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

// Helper method for the gold-accented stats items
Widget _buildGoldStatItem(IconData icon, String value, String label,
    Color primaryColor, Color textColor, bool isSmallSpace) {
  return Column(
    children: [
      Icon(
        icon,
        color: const Color(0xFFEABF56).withOpacity(0.8), // Gold icon
        size: isSmallSpace ? 16 : 18,
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(
          fontSize: isSmallSpace ? 12 : 14,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: isSmallSpace ? 10 : 12,
          color: textColor.withOpacity(0.7),
        ),
      ),
    ],
  );
}

// Helper method for the feature items
Widget _buildFeatureItem(
    IconData icon, String text, bool isSmallSpace, Color textColor) {
  return Row(
    children: [
      Icon(
        icon,
        color: PharmaTheme.primary,
        size: isSmallSpace ? 16 : 20,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            fontSize: isSmallSpace ? 12 : 14,
            color: textColor,
          ),
        ),
      ),
    ],
  );
}
