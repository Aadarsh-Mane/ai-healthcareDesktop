import 'package:doctordesktop/Admin/BedManagement.dart';
import 'package:doctordesktop/Check.dart';
import 'package:doctordesktop/Doctor/Dashboard/HomeScreen.dart';
import 'package:doctordesktop/Doctor/SeeNurseAttendace.dart';
import 'package:doctordesktop/Doctor/fetchDoctor.dart';
import 'package:doctordesktop/External/ExternalSidebar.dart';
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

class PharmacyDashBoard extends StatelessWidget {
  const PharmacyDashBoard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hospital Management System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFF8FBFD),
      ),
      home: MainLayout(key: MainLayout.globalKey),
    );
  }
}

class MainLayout extends StatefulWidget {
  static final GlobalKey<_MainLayoutState> globalKey =
      GlobalKey<_MainLayoutState>();

  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;

  // For keyboard shortcut handling
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};

  final List<Widget> _screens = [
    const CreateSaleScreen(),
    const PrescriptionToSaleScreen(),
    CreateReturnScreen(),
    AllReturnsScreen(),
    SalesHistoryScreen(),
    InventoryListScreen(),
    DistributorScreen(),
    const MedicineScreen(),
    AllMedicineScreen(),
    CreateCustomerScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _setupKeyboardShortcuts();
  }

  // Improved keyboard shortcut setup
  void _setupKeyboardShortcuts() {
    // Add keyboard listeners for global shortcuts
    ServicesBinding.instance.keyboard.addHandler((KeyEvent event) {
      // Handle key down events
      if (event is KeyDownEvent) {
        // Avoid duplicate KeyDown events for the same key
        if (_pressedKeys.contains(event.logicalKey)) {
          return false;
        }

        // Add key to pressed keys set
        _pressedKeys.add(event.logicalKey);

        // Toggle sidebar with Cmd/Ctrl + B
        if (event.logicalKey == LogicalKeyboardKey.keyB &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          _toggleSidebar();
          return true;
        }

        // Navigation shortcuts with Cmd/Ctrl + [1-9]
        if (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed) {
          // Define digit keys
          final digitKeys = [
            LogicalKeyboardKey.digit1,
            LogicalKeyboardKey.digit2,
            LogicalKeyboardKey.digit3,
            LogicalKeyboardKey.digit4,
            LogicalKeyboardKey.digit5,
            LogicalKeyboardKey.digit6,
            LogicalKeyboardKey.digit7,
            LogicalKeyboardKey.digit8,
            LogicalKeyboardKey.digit9,
          ];

          // Check for digit key presses
          for (int i = 0; i < digitKeys.length; i++) {
            if (event.logicalKey == digitKeys[i] && i < _screens.length) {
              navigateTo(i);
              return true;
            }
          }
        }
      }

      // Handle key up events to properly track key states
      else if (event is KeyUpEvent) {
        // Remove the key from pressed keys set
        _pressedKeys.remove(event.logicalKey);
      }

      // Let other handlers process the event
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

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // For very small screens, automatically collapse the sidebar
    if (isSmallScreen && !_isSidebarCollapsed) {
      // Use Future.microtask to avoid changing state during build
      Future.microtask(() => setState(() => _isSidebarCollapsed = true));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFD),
      drawer: isSmallScreen ? _buildDrawer() : null,
      body: Row(
        children: [
          // Sidebar - invisible on small screens (handled by drawer)
          if (!isSmallScreen)
            SidebarWidget(
              selectedIndex: _selectedIndex,
              isCollapsed: _isSidebarCollapsed,
              onItemSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              onToggle: _toggleSidebar,
            ),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Navbar with menu toggle
                NavbarWidget(
                  onMenuTap: isSmallScreen
                      ? () => Scaffold.of(context).openDrawer()
                      : _toggleSidebar,
                ),

                // Screen Content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
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

  // Build drawer for small screens
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: PharmaTheme.primaryDark,
      child: SidebarWidget(
        selectedIndex: _selectedIndex,
        isCollapsed: false, // Always expanded in drawer mode
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          // Auto-close drawer when item is selected on small screens
          Navigator.pop(context);
        },
        onToggle: () => Navigator.pop(context), // Close drawer on toggle
      ),
    );
  }
}

// Enhanced Sidebar Widget
class SidebarWidget extends StatelessWidget {
  final int selectedIndex;
  final bool isCollapsed;
  final Function(int) onItemSelected;
  final VoidCallback onToggle;

  const SidebarWidget({
    Key? key,
    required this.selectedIndex,
    required this.isCollapsed,
    required this.onItemSelected,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Improved widths for better visibility and usability
    final double collapsedWidth = 80; // Increased for better visibility
    final double expandedWidth = 260;

    // Using AnimatedContainer for smooth transitions
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isCollapsed ? collapsedWidth : expandedWidth,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF003366), Color(0xFF1E5799)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // App Logo and toggle button - better proportions
          _buildSidebarHeader(context),

          // Minimal divider
          Container(
            height: 1,
            color: Colors.white24,
            margin: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 8 : 16,
              vertical: 8,
            ),
          ),

          // User Profile Section - only when expanded
          if (!isCollapsed) _buildUserProfile(),

          // Minimal divider when profile is shown
          if (!isCollapsed)
            Container(
              height: 1,
              color: Colors.white24,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),

          // Navigation Items - main content with improved visibility
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItemWithLabel(
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  label: 'Create Sale',
                  isSelected: selectedIndex == 0,
                  onTap: () => onItemSelected(0),
                ),
                _buildNavItemWithLabel(
                  index: 1,
                  icon: Icons.people_outline,
                  label: 'Hospital Sale',
                  isSelected: selectedIndex == 1,
                  onTap: () => onItemSelected(1),
                ),
                _buildNavItemWithLabel(
                  index: 2,
                  icon: Icons.calendar_today_outlined,
                  label: 'Return Sale',
                  isSelected: selectedIndex == 2,
                  onTap: () => onItemSelected(2),
                ),
                _buildNavItemWithLabel(
                  index: 3,
                  icon: Icons.medical_services_outlined,
                  label: 'All Returns',
                  isSelected: selectedIndex == 3,
                  onTap: () => onItemSelected(3),
                ),

                // System section header - only when expanded
                if (!isCollapsed) ...[
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'SYSTEM',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],

                _buildNavItemWithLabel(
                  index: 4,
                  icon: Icons.settings_outlined,
                  label: 'History',
                  isSelected: selectedIndex == 4,
                  onTap: () => onItemSelected(4),
                ),
                _buildNavItemWithLabel(
                  index: 5,
                  icon: Icons.inventory_2_outlined,
                  label: 'Inventory',
                  isSelected: selectedIndex == 5,
                  onTap: () => onItemSelected(5),
                ),
                _buildNavItemWithLabel(
                  index: 6,
                  icon: Icons.local_shipping_outlined,
                  label: 'Distributors',
                  isSelected: selectedIndex == 6,
                  onTap: () => onItemSelected(6),
                ),
                _buildNavItemWithLabel(
                  index: 7,
                  icon: Icons.medical_services,
                  label: 'Batch Medicine',
                  isSelected: selectedIndex == 7,
                  onTap: () => onItemSelected(7),
                ),
                _buildNavItemWithLabel(
                  index: 8,
                  icon: Icons.medication_outlined,
                  label: 'All Medicines',
                  isSelected: selectedIndex == 8,
                  onTap: () => onItemSelected(8),
                ),
                _buildNavItemWithLabel(
                  index: 9,
                  icon: Icons.medication_outlined,
                  label: 'Customer',
                  isSelected: selectedIndex == 9,
                  onTap: () => onItemSelected(9),
                ),
              ],
            ),
          ),

          // Optimized logout button
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  // Enhanced sidebar header with larger toggle button target area
  Widget _buildSidebarHeader(BuildContext context) {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 8 : 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HospitalTheme.primary,
            PharmaTheme.accent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: PharmaTheme.shadowSmall,
      ),
      child: isCollapsed
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo with good visibility
                  // const Icon(
                  //   Icons.local_hospital_outlined,
                  //   color: Colors.white,
                  //   size: 26,
                  // ),
                  const SizedBox(height: 8),
                  // Toggle button with larger tap target
                  GestureDetector(
                    onTap: onToggle,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(PharmaTheme.radiusXs),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(PharmaTheme.radiusS),
                      ),
                      child: const Icon(
                        Icons.local_hospital_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'HMS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                // Toggle button with improved tap area
                GestureDetector(
                  onTap: onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(PharmaTheme.radiusXs),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // User profile section - unchanged
  Widget _buildUserProfile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Container(
              width: 42,
              height: 42,
              color: PharmaTheme.primary.withOpacity(0.2),
              child: const Center(
                child: Image(image: AssetImage('${AppImages.logo}')),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${AppStrings.hospitalName}",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Pharmacy',
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

  // Improved navigation item with small label in collapsed mode for better usability
  Widget _buildNavItemWithLabel({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color activeColor = HospitalTheme.primary;
    final Color inactiveColor = Colors.white;

    if (isCollapsed) {
      // Enhanced collapsed view WITH mini labels for better usability
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
          child: Container(
            height: 70, // Taller to accommodate both icon and text
            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? PharmaTheme.primary.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
              border: isSelected
                  ? Border.all(
                      color: PharmaTheme.primary.withOpacity(0.5), width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Icon(
                  icon,
                  color: isSelected ? Colors.white : inactiveColor,
                  size: 24,
                ),
                const SizedBox(height: 4),
                // Mini label - truncated if needed
                Text(
                  // Show abbreviated version of label
                  label.length > 10 ? label.substring(0, 7) + '...' : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : inactiveColor,
                    fontSize: 10,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Normal expanded view - no longer using Focus widget
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [PharmaTheme.primary, PharmaTheme.primaryLight],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : inactiveColor,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.white : inactiveColor,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
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

                // Show keyboard shortcut hint
                if (isSelected && index < 9)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Opacity(
                      opacity: 0.7,
                      child: Text(
                        '⌘${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Improved logout button
  Widget _buildLogoutButton(BuildContext context) {
    if (isCollapsed) {
      // Better logout button with text label
      return Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(),
              ),
            );
          },
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(),
            ),
          );
        },
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text(
          'Back',
          style: TextStyle(color: Colors.white),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withOpacity(0.3)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
          ),
        ),
      ),
    );
  }
}

// Updated Navbar Widget with improved menu toggle
class NavbarWidget extends StatelessWidget {
  final VoidCallback onMenuTap;

  const NavbarWidget({
    Key? key,
    required this.onMenuTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Menu toggle button
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: onMenuTap,
            tooltip: isSmallScreen ? 'Open menu' : 'Toggle sidebar',
            color: const Color(0xFF1E2843),
          ),

          // Search Bar with responsive width
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.gesture_outlined,
                      color: Colors.grey.shade500, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Welcome to HMS Pharmacy',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Notification button
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Stack(
              children: [
                const Icon(Icons.notifications_outlined,
                    color: Color(0xFF1E2843)),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Email button - hide on small screens
          if (!isSmallScreen) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(Icons.email_outlined, color: Color(0xFF1E2843)),
            ),
          ],

          // Profile button
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    width: 30,
                    height: 30,
                    color: Colors.blue.shade100,
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        color: Color(0xFF1E2843),
                        size: 18,
                      ),
                    ),
                  ),
                ),
                if (!isSmallScreen) ...[
                  const SizedBox(width: 8),
                  const Text(
                    'Admin',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E2843),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Color(0xFF1E2843),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
