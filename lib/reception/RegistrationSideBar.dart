import 'package:doctordesktop/Doctor/PatientListScreen.dart';
import 'package:doctordesktop/External/DoctorCalendarView.dart';
import 'package:doctordesktop/External/ExternalDoctorlist.dart';
import 'package:doctordesktop/Patient/fetchPatient.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
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

class RegistrationSideBar extends StatefulWidget {
  const RegistrationSideBar({super.key});

  @override
  State<RegistrationSideBar> createState() => _RegistrationSideBarState();
}

class _RegistrationSideBarState extends State<RegistrationSideBar> {
  int _selectedNavIndex = 0;
  bool _isSidebarExpanded = false; // Initially collapsed

  // Cache screens to avoid rebuilding
  static const Map<int, Widget> _screens = {
    0: OPDRegistrationScreen(),
    1: IpdDetailScreen(),
    2: PatientListScreen1(),
    3: ReceptionBedManagementScreen(),
  };

  // Navigation items configuration
  static const List<NavigationItem> _navigationItems = [
    NavigationItem(
      index: 0,
      icon: Icons.medical_information,
      label: 'OPD',
    ),
    NavigationItem(
      index: 1,
      icon: Icons.local_hospital,
      label: 'IPD',
    ),
    NavigationItem(
      index: 2,
      icon: Icons.person_pin,
      label: 'Patients',
    ),
    NavigationItem(
      index: 3,
      icon: Icons.meeting_room,
      label: 'Bed Assignment',
    ),
  ];

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
            // Responsive Sidebar
            _ResponsiveSidebar(
              selectedIndex: _selectedNavIndex,
              isExpanded: _isSidebarExpanded,
              isDesktop: isDesktop,
              isTablet: isTablet,
              onDestinationSelected: _onNavigationItemSelected,
              onToggleExpansion: _toggleSidebarExpansion,
              navigationItems: _navigationItems,
            ),

            // Content area with responsive padding
            Expanded(
              child: _ContentArea(
                selectedIndex: _selectedNavIndex,
                screens: _screens,
                isDesktop: isDesktop,
                isTablet: isTablet,
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
    }
  }

  void _toggleSidebarExpansion() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isControlPressed = HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;

      // Keyboard shortcuts
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
          case LogicalKeyboardKey.keyB:
            _toggleSidebarExpansion();
            break;
        }
      }

      // Standalone shortcuts
      if (event.logicalKey == LogicalKeyboardKey.f9) {
        _toggleSidebarExpansion();
      }
    }
  }
}

class _ResponsiveSidebar extends StatelessWidget {
  final int selectedIndex;
  final bool isExpanded;
  final bool isDesktop;
  final bool isTablet;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onToggleExpansion;
  final List<NavigationItem> navigationItems;

  const _ResponsiveSidebar({
    required this.selectedIndex,
    required this.isExpanded,
    required this.isDesktop,
    required this.isTablet,
    required this.onDestinationSelected,
    required this.onToggleExpansion,
    required this.navigationItems,
  });

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = _calculateSidebarWidth();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: sidebarWidth,
      child: ImprovedSidebar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        navigationItems: navigationItems,
        isExpanded: isExpanded,
        onToggle: onToggleExpansion,
        showToggleButton: isDesktop,
      ),
    );
  }

  double _calculateSidebarWidth() {
    if (!isDesktop && !isTablet) {
      return 60.0; // Mobile: Always collapsed
    }

    if (isExpanded) {
      return isDesktop ? 280.0 : 240.0; // Expanded width
    } else {
      return isDesktop ? 72.0 : 60.0; // Collapsed width
    }
  }
}

class _ContentArea extends StatelessWidget {
  final int selectedIndex;
  final Map<int, Widget> screens;
  final bool isDesktop;
  final bool isTablet;

  const _ContentArea({
    required this.selectedIndex,
    required this.screens,
    required this.isDesktop,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final contentPadding = _calculateContentPadding();

    return Container(
      padding: contentPadding,
      decoration: const BoxDecoration(
        color: HospitalTheme.background,
        border: Border(
          left: BorderSide(
            color: HospitalTheme.border,
            width: 1.0,
          ),
        ),
      ),
      child: _ScreenContainer(
        child: screens[selectedIndex] ?? const _NotImplementedScreen(),
      ),
    );
  }

  EdgeInsets _calculateContentPadding() {
    if (isDesktop) {
      return const EdgeInsets.all(24.0);
    } else if (isTablet) {
      return const EdgeInsets.all(16.0);
    } else {
      return const EdgeInsets.all(12.0);
    }
  }
}

class _ScreenContainer extends StatelessWidget {
  final Widget child;

  const _ScreenContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: HospitalTheme.radiusMedium,
      child: Container(
        decoration: BoxDecoration(
          color: HospitalTheme.cardBackground,
          borderRadius: HospitalTheme.radiusMedium,
          boxShadow: HospitalTheme.shadowSmall,
          border: Border.all(
            color: HospitalTheme.border,
            width: 1.0,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _NotImplementedScreen extends StatelessWidget {
  const _NotImplementedScreen();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_outlined,
            size: 64,
            color: HospitalTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'Screen Under Development',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: HospitalTheme.textMedium,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'This feature will be available soon',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: HospitalTheme.textLight,
                ),
          ),
        ],
      ),
    );
  }
}

// Enhanced NavigationItem with keyboard shortcut support
class NavigationItem {
  final int index;
  final IconData icon;
  final String label;
  final String? keyboardShortcut;
  final String? tooltip;

  const NavigationItem({
    required this.index,
    required this.icon,
    required this.label,
    this.keyboardShortcut,
    this.tooltip,
  });

  NavigationItem copyWith({
    int? index,
    IconData? icon,
    String? label,
    String? keyboardShortcut,
    String? tooltip,
  }) {
    return NavigationItem(
      index: index ?? this.index,
      icon: icon ?? this.icon,
      label: label ?? this.label,
      keyboardShortcut: keyboardShortcut ?? this.keyboardShortcut,
      tooltip: tooltip ?? this.tooltip,
    );
  }
}

// Performance-optimized sidebar with proper state management
class ImprovedSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationItem> navigationItems;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final bool showToggleButton;

  const ImprovedSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.navigationItems,
    this.isExpanded = false,
    this.onToggle,
    this.showToggleButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: HospitalTheme.cardBackground,
        border: Border(
          right: BorderSide(
            color: HospitalTheme.border,
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _SidebarHeader(
            isExpanded: isExpanded,
            showToggleButton: showToggleButton,
            onToggle: onToggle,
          ),

          // Navigation Items
          Expanded(
            child: _NavigationItems(
              selectedIndex: selectedIndex,
              navigationItems: navigationItems,
              isExpanded: isExpanded,
              onDestinationSelected: onDestinationSelected,
            ),
          ),

          // Footer
          if (isExpanded) const _SidebarFooter(),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  final bool isExpanded;
  final bool showToggleButton;
  final VoidCallback? onToggle;

  const _SidebarHeader({
    required this.isExpanded,
    required this.showToggleButton,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: HospitalTheme.border,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // Make the hospital icon clickable when collapsed
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: HospitalTheme.primary,
                borderRadius: HospitalTheme.radiusSmall,
              ),
              child: const Icon(
                Icons.local_hospital,
                color: HospitalTheme.textOnPrimary,
                size: 24,
              ),
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reception',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: HospitalTheme.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Management',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: HospitalTheme.textMedium,
                        ),
                  ),
                ],
              ),
            ),
            // Show chevron button only when expanded
            if (showToggleButton && onToggle != null)
              IconButton(
                onPressed: onToggle,
                icon: const Icon(
                  Icons.chevron_left,
                  color: HospitalTheme.textMedium,
                ),
                tooltip: 'Collapse sidebar',
              ),
          ],
        ],
      ),
    );
  }
}

class _NavigationItems extends StatelessWidget {
  final int selectedIndex;
  final List<NavigationItem> navigationItems;
  final bool isExpanded;
  final ValueChanged<int> onDestinationSelected;

  const _NavigationItems({
    required this.selectedIndex,
    required this.navigationItems,
    required this.isExpanded,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: navigationItems.length,
      itemBuilder: (context, index) {
        final item = navigationItems[index];
        final isSelected = selectedIndex == item.index;

        return _NavigationTile(
          item: item,
          isSelected: isSelected,
          isExpanded: isExpanded,
          onTap: () => onDestinationSelected(item.index),
        );
      },
    );
  }
}

class _NavigationTile extends StatelessWidget {
  final NavigationItem item;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  const _NavigationTile({
    required this.item,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: HospitalTheme.radiusSmall,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? HospitalTheme.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: HospitalTheme.radiusSmall,
              border: isSelected
                  ? Border.all(color: HospitalTheme.primary.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isSelected
                      ? HospitalTheme.primary
                      : HospitalTheme.textMedium,
                  size: 24,
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected
                            ? HospitalTheme.primary
                            : HospitalTheme.textDark,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (item.keyboardShortcut != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: HospitalTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: HospitalTheme.border,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        item.keyboardShortcut!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: HospitalTheme.textLight,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: HospitalTheme.border,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.keyboard_outlined,
                size: 16,
                color: HospitalTheme.textLight,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Press F9 to toggle',
                  style: TextStyle(
                    fontSize: 12,
                    color: HospitalTheme.textLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
