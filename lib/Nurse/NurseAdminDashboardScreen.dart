import 'dart:async';

import 'package:doctordesktop/Admin/BedManagement.dart';
import 'package:doctordesktop/Check.dart';
import 'package:doctordesktop/Doctor/Dashboard/HomeScreen.dart';
import 'package:doctordesktop/Doctor/SeeNurseAttendace.dart';
import 'package:doctordesktop/Doctor/fetchDoctor.dart';
import 'package:doctordesktop/External/ExternalSidebar.dart';
import 'package:doctordesktop/Nurse/ActivePatientScreen.dart';
import 'package:doctordesktop/Nurse/AttendanceDashboardScreen.dart';
import 'package:doctordesktop/Nurse/MyMedicationScreen.dart';
import 'package:doctordesktop/Nurse/NurseWardAssignmentScreen.dart';
import 'package:doctordesktop/Nurse/WardTasksScreen.dart';
import 'package:doctordesktop/Patient/fetchPatient.dart';
import 'package:doctordesktop/constants/Assets.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/main.dart';
import 'package:doctordesktop/pharmacy/AllMedicineScreen.dart';
import 'package:doctordesktop/pharmacy/AllReturnScreen.dart';
import 'package:doctordesktop/pharmacy/CreateCustomerScreen.dart';
import 'package:doctordesktop/pharmacy/CreateMedicineScreen.dart';
import 'package:doctordesktop/pharmacy/CreateReturn.dart';
import 'package:doctordesktop/pharmacy/CreateSalesScreen.dart';
import 'package:doctordesktop/pharmacy/DistributorScreen.dart';
import 'package:doctordesktop/pharmacy/InventoryListScreen.dart';
import 'package:doctordesktop/pharmacy/PrescriptionScreen.dart';
import 'package:doctordesktop/pharmacy/SalesHistoryScreen.dart';
import 'package:doctordesktop/pharmacy/pharmaTheme.dart';
import 'package:doctordesktop/reception/CreateAppointment.dart';
import 'package:doctordesktop/reception/ExternalDoctorRegistration.dart';
import 'package:doctordesktop/reception/PatientAllDischargedScreen.dart';
import 'package:doctordesktop/reception/PatientRegister.dart';
import 'package:doctordesktop/reception/ReceptionAdmitted.dart';
import 'package:doctordesktop/reception/ReceptionMainScreen.dart';
import 'package:doctordesktop/reception/RegistrationDashboard.dart';
import 'package:doctordesktop/reception/RegistrationSideBar.dart';
import 'package:doctordesktop/screens/DoctorRegister.dart';
import 'package:doctordesktop/screens/ListPatienAssignToDoctor.dart';
import 'package:doctordesktop/screens/NurseRegister.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Logout Provider for state management
final logoutProvider =
    StateNotifierProvider<LogoutNotifier, AsyncValue<bool>>((ref) {
  return LogoutNotifier();
});

class LogoutNotifier extends StateNotifier<AsyncValue<bool>> {
  LogoutNotifier() : super(const AsyncValue.data(false));

  Future<void> logout() async {
    state = const AsyncValue.loading();

    try {
      // Clear all stored user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Add a small delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));

      state = const AsyncValue.data(true);
    } catch (e, stackTrace) {
      state = AsyncValue.error('Logout failed: ${e.toString()}', stackTrace);
    }
  }

  void resetState() {
    state = const AsyncValue.data(false);
  }
}

class NurseAdminDashBoardScreen extends ConsumerWidget {
  const NurseAdminDashBoardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to logout state changes
    ref.listen(logoutProvider, (previous, next) {
      next.when(
        data: (success) {
          if (success) {
            // Navigate back to login/home page
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => HomePage()),
              (route) => false,
            );
          }
        },
        loading: () {
          // Show loading indicator in snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 16),
                  Text('Logging out...'),
                ],
              ),
              backgroundColor: HospitalTheme.info,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        error: (error, _) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: HospitalTheme.error,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => ref.read(logoutProvider.notifier).logout(),
              ),
            ),
          );
        },
      );
    });

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hospital Management System',
      theme: HospitalTheme.themeData,
      home: MainLayout(key: MainLayout.globalKey),
    );
  }
}

class MainLayout extends ConsumerStatefulWidget {
  static final GlobalKey<_MainLayoutState> globalKey =
      GlobalKey<_MainLayoutState>();

  const MainLayout({Key? key}) : super(key: key);

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;

  // For keyboard shortcut handling
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};

  final List<Widget> _screens = const [
    NurseWardAssignmentScreen(),
    AttendanceDashboardLayout(),
  ];

  @override
  void initState() {
    super.initState();
    _setupKeyboardShortcuts();
  }

  @override
  void dispose() {
    // Clean up keyboard listener if needed
    super.dispose();
  }

  void _setupKeyboardShortcuts() {
    ServicesBinding.instance.keyboard.addHandler((KeyEvent event) {
      if (event is KeyDownEvent) {
        if (_pressedKeys.contains(event.logicalKey)) {
          return false;
        }

        _pressedKeys.add(event.logicalKey);

        // Toggle sidebar with Cmd/Ctrl + B
        if (event.logicalKey == LogicalKeyboardKey.keyB &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          _toggleSidebar();
          return true;
        }

        // Logout with Cmd/Ctrl + Q
        if (event.logicalKey == LogicalKeyboardKey.keyQ &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          _showLogoutDialog();
          return true;
        }

        // Back to Home with Cmd/Ctrl + H
        if (event.logicalKey == LogicalKeyboardKey.keyH &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          _navigateToHome();
          return true;
        }

        // Navigation shortcuts with Cmd/Ctrl + [1-9]
        if (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed) {
          final digitKeys = [
            LogicalKeyboardKey.digit1,
            LogicalKeyboardKey.digit2,
            LogicalKeyboardKey.digit3,
            LogicalKeyboardKey.digit4,
            LogicalKeyboardKey.digit5,
          ];

          for (int i = 0; i < digitKeys.length; i++) {
            if (event.logicalKey == digitKeys[i] && i < _screens.length) {
              navigateTo(i);
              return true;
            }
          }
        }
      } else if (event is KeyUpEvent) {
        _pressedKeys.remove(event.logicalKey);
      }

      return false;
    });
  }

  void navigateTo(int index) {
    if (index < 0 || index >= _screens.length) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LogoutDialog(
        onConfirm: () {
          Navigator.pop(context);
          ref.read(logoutProvider.notifier).logout();
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    // Auto-collapse sidebar on small screens
    if (isSmallScreen && !_isSidebarCollapsed) {
      Future.microtask(() => setState(() => _isSidebarCollapsed = true));
    }

    return Scaffold(
      backgroundColor: HospitalTheme.background,
      drawer: isSmallScreen ? _buildDrawer() : null,
      body: Row(
        children: [
          // Sidebar - invisible on small screens (handled by drawer)
          if (!isSmallScreen)
            SidebarWidget(
              selectedIndex: _selectedIndex,
              isCollapsed: _isSidebarCollapsed,
              onItemSelected: navigateTo,
              onToggle: _toggleSidebar,
              onLogout: _showLogoutDialog,
              onBackToHome: _navigateToHome,
            ),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Navbar with responsive design
                NavbarWidget(
                  onMenuTap: isSmallScreen
                      ? () => Scaffold.of(context).openDrawer()
                      : _toggleSidebar,
                  onLogout: _showLogoutDialog,
                  onBackToHome: _navigateToHome,
                ),

                // Screen Content with smooth transitions
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.1, 0.0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(_selectedIndex),
                      child: _screens[_selectedIndex],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: HospitalTheme.primaryDark,
      child: SidebarWidget(
        selectedIndex: _selectedIndex,
        isCollapsed: false,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          Navigator.pop(context);
        },
        onToggle: () => Navigator.pop(context),
        onLogout: () {
          Navigator.pop(context);
          _showLogoutDialog();
        },
        onBackToHome: () {
          Navigator.pop(context);
          _navigateToHome();
        },
      ),
    );
  }
}

// Enhanced Sidebar Widget with both back and logout functionality
class SidebarWidget extends StatelessWidget {
  final int selectedIndex;
  final bool isCollapsed;
  final Function(int) onItemSelected;
  final VoidCallback onToggle;
  final VoidCallback onLogout;
  final VoidCallback onBackToHome;

  const SidebarWidget({
    Key? key,
    required this.selectedIndex,
    required this.isCollapsed,
    required this.onItemSelected,
    required this.onToggle,
    required this.onLogout,
    required this.onBackToHome,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double collapsedWidth = 80;
    const double expandedWidth = 280;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isCollapsed ? collapsedWidth : expandedWidth,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [HospitalTheme.primaryDark, HospitalTheme.primary],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildSidebarHeader(),

          // Divider
          Container(
            height: 1,
            color: Colors.white24,
            margin: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 8 : 16,
              vertical: 8,
            ),
          ),

          // User Profile
          if (!isCollapsed) _buildUserProfile(),
          if (!isCollapsed)
            Container(
              height: 1,
              color: Colors.white24,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.domain_outlined,
                  label: 'Ward Assignment',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.domain_outlined,
                  label: 'Attendance Dashboard',
                ),
              ],
            ),
          ),

          // Action Buttons (Back and Logout)
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 8 : 16,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
      ),
      child: isCollapsed
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_hospital,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_hospital,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Nurse Portal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildUserProfile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nurse',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'HMS Portal',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = selectedIndex == index;

    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onItemSelected(index),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : null,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: Colors.white.withOpacity(0.3))
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label.split(' ')[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onItemSelected(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withOpacity(0.2) : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Back Button
          isCollapsed
              ? GestureDetector(
                  onTap: onBackToHome,
                  child: Container(
                    height: 48,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: HospitalTheme.primary.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home, color: Colors.white, size: 18),
                        SizedBox(height: 2),
                        Text(
                          'Home',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: onBackToHome,
                  icon: const Icon(Icons.home, size: 18),
                  label: const Text('Back to Home'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

          SizedBox(height: isCollapsed ? 0 : 8),

          // Logout Button
        ],
      ),
    );
  }
}

// Enhanced Navbar Widget with back and logout options
class NavbarWidget extends StatefulWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onLogout;
  final VoidCallback onBackToHome;

  const NavbarWidget({
    Key? key,
    required this.onMenuTap,
    required this.onLogout,
    required this.onBackToHome,
  }) : super(key: key);

  @override
  State<NavbarWidget> createState() => _NavbarWidgetState();
}

class _NavbarWidgetState extends State<NavbarWidget> {
  String _currentTime = '';
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(now);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 1200;

    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xFFF8FBFD),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: HospitalTheme.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Menu toggle button
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: widget.onMenuTap,
            tooltip: 'Toggle sidebar (Ctrl+B)',
            color: HospitalTheme.textDark,
          ),

          const SizedBox(width: 20),

          // Hospital Management System title
          if (!isCompact)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: HospitalTheme.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: HospitalTheme.border,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_hospital_outlined,
                    size: 16,
                    color: HospitalTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Hospital Management System',
                    style: TextStyle(
                      fontSize: 13,
                      color: HospitalTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const Spacer(),

          // System status
          if (!isCompact)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: HospitalTheme.border,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 12,
                      color: HospitalTheme.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(width: 16),

          // Action buttons (Back and Logout)
          Row(
            children: [
              // Back to Home button
              Container(
                decoration: BoxDecoration(
                  color: HospitalTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: HospitalTheme.primary.withOpacity(0.3)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.home_outlined),
                  onPressed: widget.onBackToHome,
                  color: HospitalTheme.primary,
                  iconSize: 20,
                  tooltip: 'Back to Home (Ctrl+H)',
                ),
              ),

              const SizedBox(width: 8),

              // Profile menu with logout
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') {
                    widget.onLogout();
                  } else if (value == 'back') {
                    widget.onBackToHome();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'back',
                    child: Row(
                      children: [
                        Icon(Icons.home_outlined,
                            size: 18, color: HospitalTheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Back to Home',
                          style: TextStyle(color: HospitalTheme.primary),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout,
                            size: 18, color: HospitalTheme.error),
                        const SizedBox(width: 8),
                        Text(
                          'Logout',
                          style: TextStyle(color: HospitalTheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: HospitalTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: HospitalTheme.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: HospitalTheme.primary.withOpacity(0.1),
                        ),
                        child: Icon(
                          Icons.person,
                          color: HospitalTheme.primary,
                          size: 18,
                        ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(width: 8),
                        const Text(
                          'Nurse',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // Live clock
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  HospitalTheme.primary,
                  HospitalTheme.primaryLight,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: HospitalTheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentTime,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                Text(
                  DateFormat('MMM dd').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.9),
                    height: 1,
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

// Logout Confirmation Dialog
class LogoutDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const LogoutDialog({
    Key? key,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.logout,
            color: HospitalTheme.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text('Confirm Logout'),
        ],
      ),
      content: const Text(
        'Are you sure you want to logout? You will need to sign in again to access the nurse portal.',
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(
            'Cancel',
            style: TextStyle(color: HospitalTheme.textMedium),
          ),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: HospitalTheme.error,
            foregroundColor: Colors.white,
          ),
          child: const Text('Logout'),
        ),
      ],
    );
  }
}
