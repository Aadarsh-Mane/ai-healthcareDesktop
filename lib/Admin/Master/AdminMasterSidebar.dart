import 'package:doctordesktop/Admin/Master/HospitalCounterScreen.dart';
import 'package:doctordesktop/Admin/Master/PatientHistoryRecordScreen.dart';
import 'package:doctordesktop/Admin/Master/PatientListPanel.dart';
import 'package:doctordesktop/Doctor/PatientListScreen.dart';
import 'package:doctordesktop/External/DoctorCalendarView.dart';
import 'package:doctordesktop/External/ExternalDoctorlist.dart';
import 'package:doctordesktop/Patient/fetchPatient.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/reception/ActivePatientScreen.dart';
import 'package:doctordesktop/reception/CreateAppointment.dart';
import 'package:doctordesktop/reception/ExternalDoctorRegistration.dart';
import 'package:doctordesktop/reception/IpdDetailScreen.dart';
import 'package:doctordesktop/reception/IpdRegistration.dart';
import 'package:doctordesktop/reception/OpdRegistration.dart';
import 'package:doctordesktop/reception/PatientRegister.dart';
import 'package:doctordesktop/reception/ReceptionAdmitted.dart';
import 'package:doctordesktop/reception/Sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdminRegistrationSideBar extends StatefulWidget {
  const AdminRegistrationSideBar({super.key});

  @override
  State<AdminRegistrationSideBar> createState() =>
      _AdminRegistrationSideBarState();
}

class _AdminRegistrationSideBarState extends State<AdminRegistrationSideBar>
    with TickerProviderStateMixin {
  int _selectedNavIndex = 0;
  bool _isSidebarExpanded = false;
  late AnimationController _sidebarAnimationController;
  late AnimationController _glowAnimationController;
  late Animation<double> _sidebarAnimation;
  late Animation<double> _glowAnimation;

  // Cache screens to avoid rebuilding
  static const Map<int, Widget> _screens = {
    0: PatientManagementScreen(),
    1: PatientRecordsManagementScreen(),
    2: PatientCounterScreen(),
  };

  // Enhanced navigation items with colors and gradients
  static const List<NavigationItem> _navigationItems = [
    NavigationItem(
      index: 0,
      icon: Icons.medical_information,
      label: 'Patient Management',
      shortLabel: 'Management',
      gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
      iconColor: Color(0xFF667eea),
      keyboardShortcut: 'Ctrl+1',
    ),
    NavigationItem(
      index: 1,
      icon: Icons.local_hospital,
      label: 'Patient Records',
      shortLabel: 'Records',
      gradientColors: [Color(0xFFf093fb), Color(0xFFf5576c)],
      iconColor: Color(0xFFf093fb),
      keyboardShortcut: 'Ctrl+2',
    ),
    NavigationItem(
      index: 2,
      icon: Icons.person_pin,
      label: 'Patient Count',
      shortLabel: 'Count',
      gradientColors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
      iconColor: Color(0xFF4facfe),
      keyboardShortcut: 'Ctrl+3',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _sidebarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _glowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _sidebarAnimation = CurvedAnimation(
      parent: _sidebarAnimationController,
      curve: Curves.easeInOutCubic,
    );

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _glowAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _sidebarAnimationController.dispose();
    _glowAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 1024;
    final isTablet = screenSize.width > 768 && screenSize.width <= 1024;

    return Scaffold(
      backgroundColor: HospitalTheme.background,
      body: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: _handleKeyEvent,
        child: Row(
          children: [
            // Enhanced Responsive Sidebar
            _EnhancedResponsiveSidebar(
              selectedIndex: _selectedNavIndex,
              isExpanded: _isSidebarExpanded,
              isDesktop: isDesktop,
              isTablet: isTablet,
              onDestinationSelected: _onNavigationItemSelected,
              onToggleExpansion: _toggleSidebarExpansion,
              navigationItems: _navigationItems,
              sidebarAnimation: _sidebarAnimation,
              glowAnimation: _glowAnimation,
            ),

            // Content area with enhanced styling
            Expanded(
              child: _EnhancedContentArea(
                selectedIndex: _selectedNavIndex,
                screens: _screens,
                isDesktop: isDesktop,
                isTablet: isTablet,
                navigationItems: _navigationItems,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onNavigationItemSelected(int index) {
    if (_selectedNavIndex != index) {
      setState(() {
        _selectedNavIndex = index;
      });
      // Add haptic feedback for better UX
      HapticFeedback.lightImpact();
    }
  }

  void _toggleSidebarExpansion() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });

    if (_isSidebarExpanded) {
      _sidebarAnimationController.forward();
    } else {
      _sidebarAnimationController.reverse();
    }

    HapticFeedback.mediumImpact();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isControlPressed = HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;

      if (isControlPressed) {
        switch (event.logicalKey) {
          case LogicalKeyboardKey.digit1:
            _onNavigationItemSelected(0);
            break;
          case LogicalKeyboardKey.digit2:
            _onNavigationItemSelected(1);
            break;
          case LogicalKeyboardKey.digit3:
            _onNavigationItemSelected(2);
            break;
          case LogicalKeyboardKey.digit4:
            _onNavigationItemSelected(3);
            break;
          case LogicalKeyboardKey.digit5:
            _onNavigationItemSelected(4);
            break;
          case LogicalKeyboardKey.keyB:
            _toggleSidebarExpansion();
            break;
        }
      }

      if (event.logicalKey == LogicalKeyboardKey.f9) {
        _toggleSidebarExpansion();
      }
    }
  }
}

class _EnhancedResponsiveSidebar extends StatelessWidget {
  final int selectedIndex;
  final bool isExpanded;
  final bool isDesktop;
  final bool isTablet;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onToggleExpansion;
  final List<NavigationItem> navigationItems;
  final Animation<double> sidebarAnimation;
  final Animation<double> glowAnimation;

  const _EnhancedResponsiveSidebar({
    required this.selectedIndex,
    required this.isExpanded,
    required this.isDesktop,
    required this.isTablet,
    required this.onDestinationSelected,
    required this.onToggleExpansion,
    required this.navigationItems,
    required this.sidebarAnimation,
    required this.glowAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = _calculateSidebarWidth();

    return AnimatedBuilder(
      animation: Listenable.merge([sidebarAnimation, glowAnimation]),
      builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          width: sidebarWidth,
          child: _PremiumSidebar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            navigationItems: navigationItems,
            isExpanded: isExpanded,
            onToggle: onToggleExpansion,
            showToggleButton: isDesktop,
            glowIntensity: glowAnimation.value,
          ),
        );
      },
    );
  }

  double _calculateSidebarWidth() {
    if (!isDesktop && !isTablet) {
      return 70.0; // Mobile: Always collapsed but slightly wider
    }

    if (isExpanded) {
      return isDesktop ? 320.0 : 280.0; // Wider expanded width
    } else {
      return isDesktop ? 80.0 : 70.0; // Collapsed width
    }
  }
}

class _EnhancedContentArea extends StatelessWidget {
  final int selectedIndex;
  final Map<int, Widget> screens;
  final bool isDesktop;
  final bool isTablet;
  final List<NavigationItem> navigationItems;

  const _EnhancedContentArea({
    required this.selectedIndex,
    required this.screens,
    required this.isDesktop,
    required this.isTablet,
    required this.navigationItems,
  });

  @override
  Widget build(BuildContext context) {
    final contentPadding = _calculateContentPadding();
    final selectedItem = navigationItems[selectedIndex];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: contentPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HospitalTheme.background,
            HospitalTheme.background,
          ],
        ),
      ),
      child: _EnhancedScreenContainer(
        selectedItem: selectedItem,
        child: screens[selectedIndex] ?? const _NotImplementedScreen(),
      ),
    );
  }

  EdgeInsets _calculateContentPadding() {
    if (isDesktop) {
      return const EdgeInsets.all(2.0);
    } else if (isTablet) {
      return const EdgeInsets.all(16.0);
    } else {
      return const EdgeInsets.all(12.0);
    }
  }
}

class _EnhancedScreenContainer extends StatelessWidget {
  final Widget child;
  final NavigationItem selectedItem;

  const _EnhancedScreenContainer({
    required this.child,
    required this.selectedItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HospitalTheme.cardBackground,
        borderRadius: HospitalTheme.radiusLarge,
        boxShadow: [
          BoxShadow(
            color: selectedItem.gradientColors.first.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          ...HospitalTheme.shadow,
        ],
        border: Border.all(
          color: selectedItem.gradientColors.first.withOpacity(0.1),
          width: 1.0,
        ),
      ),
      child: child,
    );
  }
}

class _NotImplementedScreen extends StatelessWidget {
  const _NotImplementedScreen();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HospitalTheme.primaryDark,
            HospitalTheme.primary,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.construction_outlined,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Screen Under Development',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: HospitalTheme.textDark,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'This feature will be available soon',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HospitalTheme.textMedium,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// Enhanced NavigationItem with gradient colors
class NavigationItem {
  final int index;
  final IconData icon;
  final String label;
  final String shortLabel;
  final List<Color> gradientColors;
  final Color iconColor;
  final String? keyboardShortcut;
  final String? tooltip;

  const NavigationItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.shortLabel,
    required this.gradientColors,
    required this.iconColor,
    this.keyboardShortcut,
    this.tooltip,
  });
}

// Premium sidebar with enhanced visuals
class _PremiumSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationItem> navigationItems;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final bool showToggleButton;
  final double glowIntensity;

  const _PremiumSidebar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.navigationItems,
    this.isExpanded = false,
    this.onToggle,
    this.showToggleButton = true,
    required this.glowIntensity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HospitalTheme.primaryDark,
            HospitalTheme.primary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(2, 0),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 0),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          // Enhanced Header
          _PremiumSidebarHeader(
            isExpanded: isExpanded,
            showToggleButton: showToggleButton,
            onToggle: onToggle,
            glowIntensity: glowIntensity,
          ),

          // Navigation Items
          Expanded(
            child: _PremiumNavigationItems(
              selectedIndex: selectedIndex,
              navigationItems: navigationItems,
              isExpanded: isExpanded,
              onDestinationSelected: onDestinationSelected,
              glowIntensity: glowIntensity,
            ),
          ),

          // Enhanced Footer
          if (isExpanded) _PremiumSidebarFooter(glowIntensity: glowIntensity),
        ],
      ),
    );
  }
}

class _PremiumSidebarHeader extends StatelessWidget {
  final bool isExpanded;
  final bool showToggleButton;
  final VoidCallback? onToggle;
  final double glowIntensity;

  const _PremiumSidebarHeader({
    required this.isExpanded,
    required this.showToggleButton,
    required this.onToggle,
    required this.glowIntensity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isExpanded ? 20 : 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isExpanded ? 48 : 40,
              height: isExpanded ? 48 : 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF667eea).withOpacity(glowIntensity),
                    const Color(0xFF764ba2).withOpacity(glowIntensity),
                  ],
                ),
                borderRadius: BorderRadius.circular(isExpanded ? 12 : 10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.local_hospital,
                color: Colors.white,
                size: isExpanded ? 28 : 24,
              ),
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFFe0e0e0)],
                    ).createShader(bounds),
                    child: Text(
                      'Reception',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Text(
                    'Management Hub',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
            if (showToggleButton && onToggle != null)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: onToggle,
                  icon: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                  ),
                  tooltip: 'Collapse sidebar (F9)',
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PremiumNavigationItems extends StatelessWidget {
  final int selectedIndex;
  final List<NavigationItem> navigationItems;
  final bool isExpanded;
  final ValueChanged<int> onDestinationSelected;
  final double glowIntensity;

  const _PremiumNavigationItems({
    required this.selectedIndex,
    required this.navigationItems,
    required this.isExpanded,
    required this.onDestinationSelected,
    required this.glowIntensity,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        vertical: 8,
        horizontal: isExpanded ? 12 : 8,
      ),
      itemCount: navigationItems.length,
      itemBuilder: (context, index) {
        final item = navigationItems[index];
        final isSelected = selectedIndex == item.index;

        return _PremiumNavigationTile(
          item: item,
          isSelected: isSelected,
          isExpanded: isExpanded,
          onTap: () => onDestinationSelected(item.index),
          glowIntensity: glowIntensity,
        );
      },
    );
  }
}

class _PremiumNavigationTile extends StatefulWidget {
  final NavigationItem item;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;
  final double glowIntensity;

  const _PremiumNavigationTile({
    required this.item,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
    required this.glowIntensity,
  });

  @override
  State<_PremiumNavigationTile> createState() => _PremiumNavigationTileState();
}

class _PremiumNavigationTileState extends State<_PremiumNavigationTile>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: EdgeInsets.symmetric(
              vertical: widget.isExpanded ? 6 : 4,
              horizontal: widget.isExpanded ? 0 : 2,
            ),
            child: MouseRegion(
              onEnter: (_) {
                setState(() => _isHovered = true);
                _hoverController.forward();
              },
              onExit: (_) {
                setState(() => _isHovered = false);
                _hoverController.reverse();
              },
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius:
                      BorderRadius.circular(widget.isExpanded ? 16 : 12),
                  splashColor:
                      widget.item.gradientColors.first.withOpacity(0.3),
                  highlightColor:
                      widget.item.gradientColors.first.withOpacity(0.1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    constraints: BoxConstraints(
                      minHeight: widget.isExpanded ? 56 : 48,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.isExpanded ? 16 : 8,
                      vertical: widget.isExpanded ? 16 : 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: widget.isSelected || _isHovered
                          ? LinearGradient(
                              colors: [
                                widget.item.gradientColors.first.withOpacity(
                                  widget.isSelected ? 0.8 : 0.4,
                                ),
                                widget.item.gradientColors.last.withOpacity(
                                  widget.isSelected ? 0.6 : 0.2,
                                ),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      borderRadius:
                          BorderRadius.circular(widget.isExpanded ? 16 : 12),
                      border: widget.isSelected
                          ? Border.all(
                              color: widget.item.gradientColors.first
                                  .withOpacity(0.6),
                              width: widget.isExpanded ? 2 : 1,
                            )
                          : null,
                      boxShadow: widget.isSelected
                          ? [
                              BoxShadow(
                                color: widget.item.gradientColors.first
                                    .withOpacity(0.4),
                                blurRadius: widget.isExpanded ? 15 : 10,
                                offset: const Offset(0, 4),
                                spreadRadius: widget.isExpanded ? 2 : 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: widget.isExpanded
                          ? MainAxisSize.max
                          : MainAxisSize.min,
                      mainAxisAlignment: widget.isExpanded
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: EdgeInsets.all(widget.isExpanded ? 8 : 6),
                          decoration: BoxDecoration(
                            color: widget.isSelected
                                ? Colors.white.withOpacity(0.2)
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                                widget.isExpanded ? 10 : 8),
                          ),
                          child: Icon(
                            widget.item.icon,
                            color: widget.isSelected || _isHovered
                                ? Colors.white
                                : Colors.white.withOpacity(0.8),
                            size: widget.isExpanded ? 24 : 20,
                          ),
                        ),
                        if (widget.isExpanded) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.item.label,
                                  style: TextStyle(
                                    color: widget.isSelected || _isHovered
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.9),
                                    fontWeight: widget.isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                if (widget.item.keyboardShortcut != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.item.keyboardShortcut!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.6),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (widget.isSelected)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PremiumSidebarFooter extends StatelessWidget {
  final double glowIntensity;

  const _PremiumSidebarFooter({required this.glowIntensity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1.0,
          ),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667eea).withOpacity(0.2),
                  const Color(0xFF764ba2).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.keyboard_outlined,
                  size: 18,
                  color: Colors.white.withOpacity(0.8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keyboard Shortcuts',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Press F9 to toggle sidebar',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
